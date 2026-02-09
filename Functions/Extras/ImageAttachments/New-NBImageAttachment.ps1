<#
.SYNOPSIS
    Creates a new image attachment in Netbox.

.DESCRIPTION
    Uploads an image file and attaches it to a Netbox object. Supports any object type
    that allows image attachments (devices, sites, racks, rack types, etc.).

.PARAMETER Object_Type
    The content type of the object to attach the image to. Format: "app.model"
    Examples: dcim.device, dcim.site, dcim.rack, dcim.racktype, dcim.devicetype

.PARAMETER Object_Id
    The database ID of the object to attach the image to.

.PARAMETER ImagePath
    Path to the image file to upload. Supports common image formats (PNG, JPG, GIF, etc.).

.PARAMETER Name
    Optional name for the image attachment. Maximum 50 characters.

.PARAMETER Description
    Optional description for the image attachment. Maximum 200 characters.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBImageAttachment -Object_Type "dcim.racktype" -Object_Id 1 -ImagePath "./rack-front.png"

    Attaches rack-front.png to rack type with ID 1.

.EXAMPLE
    New-NBImageAttachment -Object_Type "dcim.device" -Object_Id 42 -ImagePath "/tmp/server.jpg" -Name "Front View" -Description "Server front panel"

    Attaches server.jpg to device 42 with a name and description.

.EXAMPLE
    Get-NBDCIMRackType -Name "42U Standard" | New-NBImageAttachment -Object_Type "dcim.racktype" -ImagePath "./elevation.png"

    Pipes a rack type and attaches an image to it.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBImageAttachment {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Object_Type,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [uint64]$Object_Id,

        [Parameter(Mandatory)]
        [ValidateScript({
            if (-not (Test-Path -Path $_ -PathType Leaf)) {
                throw "Image file not found: $_"
            }
            $true
        })]
        [string]$ImagePath,

        [ValidateLength(0, 50)]
        [string]$Name,

        [ValidateLength(0, 200)]
        [string]$Description,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Image Attachment for $Object_Type ID $Object_Id"

        # Build the URI
        $URI = BuildNewURI -Segments @('extras', 'image-attachments')

        # Resolve the full path
        $FullPath = Resolve-Path -Path $ImagePath
        $FileName = Split-Path -Path $FullPath -Leaf

        Write-Verbose "Uploading image: $FileName"

        if ($PSCmdlet.ShouldProcess("$Object_Type ID $Object_Id", "Upload image attachment '$FileName'")) {
            # Build multipart form data
            # PowerShell Core and Desktop handle this differently
            if ($PSVersionTable.PSEdition -eq 'Core') {
                # PowerShell Core: Use -Form parameter
                $Form = @{
                    object_type = $Object_Type
                    object_id   = $Object_Id
                    image       = Get-Item -Path $FullPath
                }

                if ($PSBoundParameters.ContainsKey('Name')) {
                    $Form['name'] = $Name
                }

                if ($PSBoundParameters.ContainsKey('Description')) {
                    $Form['description'] = $Description
                }

                # Get connection parameters
                $InvokeParams = Get-NBInvokeParams
                $Headers = Get-NBRequestHeaders

                try {
                    $Response = Invoke-RestMethod -Uri $URI -Method POST -Form $Form -Headers $Headers @InvokeParams
                    $Response
                }
                catch {
                    $ErrorBody = (GetNetboxAPIErrorBody -Response $_.Exception.Response).Body
                    $PSCmdlet.ThrowTerminatingError(
                        [System.Management.Automation.ErrorRecord]::new(
                            [System.Exception]::new("Failed to upload image attachment: $ErrorBody"),
                            'ImageUploadFailed',
                            [System.Management.Automation.ErrorCategory]::InvalidOperation,
                            $URI
                        )
                    )
                }
            }
            else {
                # PowerShell Desktop: Use .NET multipart form
                $FileStream = $null
                $FormContent = $null
                $HttpClient = $null

                try {
                    # Create multipart form content
                    $FormContent = New-Object System.Net.Http.MultipartFormDataContent

                    # Add text fields
                    $FormContent.Add([System.Net.Http.StringContent]::new($Object_Type), 'object_type')
                    $FormContent.Add([System.Net.Http.StringContent]::new([string]$Object_Id), 'object_id')

                    if ($PSBoundParameters.ContainsKey('Name')) {
                        $FormContent.Add([System.Net.Http.StringContent]::new($Name), 'name')
                    }

                    if ($PSBoundParameters.ContainsKey('Description')) {
                        $FormContent.Add([System.Net.Http.StringContent]::new($Description), 'description')
                    }

                    # Add file
                    $FileStream = [System.IO.File]::OpenRead($FullPath)
                    $FileContent = New-Object System.Net.Http.StreamContent($FileStream)

                    # Determine content type from extension
                    $Extension = [System.IO.Path]::GetExtension($FileName).ToLower()
                    $ContentType = switch ($Extension) {
                        '.png'  { 'image/png' }
                        '.jpg'  { 'image/jpeg' }
                        '.jpeg' { 'image/jpeg' }
                        '.gif'  { 'image/gif' }
                        '.webp' { 'image/webp' }
                        '.svg'  { 'image/svg+xml' }
                        default { 'application/octet-stream' }
                    }

                    $FileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse($ContentType)
                    $FormContent.Add($FileContent, 'image', $FileName)

                    # Create HTTP client
                    $Handler = New-Object System.Net.Http.HttpClientHandler

                    # Check if we need to skip certificate validation
                    $Config = $script:NetboxConfig
                    if ($Config.InvokeParams.ContainsKey('SkipCertificateCheck') -and $Config.InvokeParams.SkipCertificateCheck) {
                        $Handler.ServerCertificateCustomValidationCallback = { $true }
                    }

                    $HttpClient = New-Object System.Net.Http.HttpClient($Handler)
                    $HttpClient.DefaultRequestHeaders.Add('Authorization', (Get-NBRequestHeaders).Authorization)

                    # Send request
                    $ResponseTask = $HttpClient.PostAsync($URI, $FormContent)
                    $ResponseTask.Wait()
                    $HttpResponse = $ResponseTask.Result

                    $ContentTask = $HttpResponse.Content.ReadAsStringAsync()
                    $ContentTask.Wait()
                    $ResponseContent = $ContentTask.Result

                    if ($HttpResponse.IsSuccessStatusCode) {
                        $Result = $ResponseContent | ConvertFrom-Json
                        $Result
                    }
                    else {
                        throw "HTTP $([int]$HttpResponse.StatusCode): $ResponseContent"
                    }
                }
                catch {
                    $PSCmdlet.ThrowTerminatingError(
                        [System.Management.Automation.ErrorRecord]::new(
                            [System.Exception]::new("Failed to upload image attachment: $($_.Exception.Message)"),
                            'ImageUploadFailed',
                            [System.Management.Automation.ErrorCategory]::InvalidOperation,
                            $URI
                        )
                    )
                }
                finally {
                    if ($FileStream) { $FileStream.Dispose() }
                    if ($FormContent) { $FormContent.Dispose() }
                    if ($HttpClient) { $HttpClient.Dispose() }
                }
            }
        }
    }
}
