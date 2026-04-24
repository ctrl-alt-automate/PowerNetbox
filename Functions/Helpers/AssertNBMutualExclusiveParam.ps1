function AssertNBMutualExclusiveParam {
    <#
    .SYNOPSIS
        Throws when two or more of the named parameters are present in a bound-parameters dictionary.

    .DESCRIPTION
        Internal helper used to enforce mutual exclusion between cmdlet parameters
        at runtime. Throws a terminating ParameterBindingException that names the
        conflicting parameters.

    .PARAMETER BoundParameters
        The $PSBoundParameters dictionary from the calling cmdlet, or any
        IDictionary that maps parameter names to values.

    .PARAMETER Parameters
        The list of parameter names that are mutually exclusive. At least two
        must be provided; typically 2-5 in practice.

    .PARAMETER HelpHint
        Optional text appended to the exception message (e.g. a pointer to docs).

    .EXAMPLE
        AssertNBMutualExclusiveParam -BoundParameters $PSBoundParameters -Parameters 'Brief','Fields','Omit'
.NOTES
    AddedInVersion: v4.5.8.0

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$BoundParameters,

        [Parameter(Mandatory)]
        [ValidateCount(2, 10)]
        [string[]]$Parameters,

        [string]$HelpHint
    )

    $supplied = $Parameters | Where-Object { $BoundParameters.ContainsKey($_) }
    if ($supplied.Count -gt 1) {
        $joined = '-' + ($supplied -join ', -')
        $message = "Parameters $joined are mutually exclusive. Specify only one."
        if ($HelpHint) { $message += " $HelpHint" }
        throw [System.Management.Automation.ParameterBindingException]::new($message)
    }
}
