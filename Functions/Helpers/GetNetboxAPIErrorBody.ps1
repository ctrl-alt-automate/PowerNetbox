
function GetNetboxAPIErrorBody {
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Net.HttpWebResponse]$Response
    )

    # This takes the $Response stream and turns it into a useable object... generally a string.
    # If the body is JSON, you should be able to use ConvertFrom-Json

    # Explicitly specify UTF-8 encoding for cross-platform consistency
    $reader = [System.IO.StreamReader]::new($Response.GetResponseStream(), [System.Text.Encoding]::UTF8)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $reader.ReadToEnd()
}