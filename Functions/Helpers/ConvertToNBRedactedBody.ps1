<#
.SYNOPSIS
    Returns a copy of a request body that is safe to write to the verbose stream.

.DESCRIPTION
    Builds a deep copy of the body in which the value of every field whose name looks
    sensitive is replaced by '***REDACTED***'. The original body is never modified - it
    still has to be sent to NetBox.

    A field is sensitive when its name contains one of: secret, passw (password, passwd),
    passphrase, key, token, psk, credential, community (SNMP), header. 'header' is there
    for a webhook's additional_headers, which is a plain string field that routinely
    carries an 'Authorization: Bearer ...' line. Matching is by name only and errs on the
    side of masking too much: a masked field costs a little debugging comfort, a logged
    credential costs a rotation.

    Dictionaries are walked by their entries. That is the whole point of this helper:
    $hashtable.PSObject.Properties does NOT enumerate the entries of a hashtable, it
    enumerates the .NET members of the Hashtable type (Keys, Values, SyncRoot, Count, ...).
    Redacting "by property" therefore masked 'Keys' and then logged every value in clear
    text through 'Values' and 'SyncRoot'.

    Nested dictionaries, PSCustomObjects and arrays are handled recursively, so a secret
    inside e.g. a data source's 'parameters' or inside 'custom_fields' is masked as well.

.PARAMETER Body
    The request body: a hashtable / ordered dictionary, a PSCustomObject, an array of those,
    or a scalar.

.PARAMETER Depth
    Current recursion depth. Internal; callers leave it at 0.

.EXAMPLE
    ConvertToNBRedactedBody -Body @{ username = 'alice'; password = 'hunter2' } | ConvertTo-Json -Compress

    {"username":"alice","password":"***REDACTED***"}

.NOTES
    Internal helper, used by InvokeNetboxRequest for the "BODY:" verbose line.
#>
function ConvertToNBRedactedBody {
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary], [object[]], [string], [object])]
    param
    (
        [object]$Body,

        [int]$Depth = 0
    )

    $sensitivePattern = 'secret|passw|passphrase|key|token|psk|credential|community|header'
    $mask = '***REDACTED***'

    if ($null -eq $Body) { return $null }

    # The request itself is serialised with -Depth 10; nothing deeper can reach the wire.
    if ($Depth -gt 10) { return '...' }

    # Strings and numbers first: a string is IEnumerable and reports as a PSCustomObject too.
    if ($Body -is [string] -or $Body -is [System.ValueType]) { return $Body }

    if ($Body -is [System.Collections.IDictionary]) {
        $copy = [ordered]@{}
        foreach ($key in @($Body.Keys)) {
            $name = [string]$key
            if ($name -match $sensitivePattern) {
                $copy[$name] = $mask
            }
            else {
                $copy[$name] = ConvertToNBRedactedBody -Body $Body[$key] -Depth ($Depth + 1)
            }
        }
        return $copy
    }

    if ($Body -is [System.Collections.IEnumerable]) {
        $items = [System.Collections.Generic.List[object]]::new()
        foreach ($item in $Body) {
            $items.Add((ConvertToNBRedactedBody -Body $item -Depth ($Depth + 1)))
        }
        # The comma keeps an empty or single-item list an array for the caller.
        return , $items.ToArray()
    }

    if ($Body -is [System.Management.Automation.PSCustomObject]) {
        $copy = [ordered]@{}
        foreach ($property in $Body.PSObject.Properties) {
            if ($property.Name -match $sensitivePattern) {
                $copy[$property.Name] = $mask
            }
            else {
                $copy[$property.Name] = ConvertToNBRedactedBody -Body $property.Value -Depth ($Depth + 1)
            }
        }
        return $copy
    }

    return $Body
}
