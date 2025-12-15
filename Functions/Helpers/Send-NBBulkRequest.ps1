<#
.SYNOPSIS
    Sends bulk requests to the Netbox API.

.DESCRIPTION
    Helper function for bulk API operations. Handles batching, progress reporting,
    and partial failure handling for POST, PATCH, and DELETE operations.

.PARAMETER URI
    The base URI for the API endpoint.

.PARAMETER Items
    Array of items to process in bulk.

.PARAMETER Method
    HTTP method (POST, PATCH, DELETE).

.PARAMETER BatchSize
    Maximum number of items per API request. Default: 100, Max: 1000.

.PARAMETER ShowProgress
    Show progress bar during bulk operations.

.PARAMETER ActivityName
    Name to display in the progress bar.

.OUTPUTS
    [BulkOperationResult] Object containing succeeded and failed items.

.EXAMPLE
    $result = Send-NBBulkRequest -URI $uri -Items $devices -Method POST -BatchSize 50
#>

function Send-NBBulkRequest {
    [CmdletBinding()]
    [OutputType([BulkOperationResult])]
    param(
        [Parameter(Mandatory = $true)]
        [System.UriBuilder]$URI,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [array]$Items,

        [Parameter(Mandatory = $true)]
        [ValidateSet('POST', 'PATCH', 'DELETE')]
        [string]$Method,

        [ValidateRange(1, 1000)]
        [int]$BatchSize = 100,

        [switch]$ShowProgress,

        [string]$ActivityName = 'Bulk operation'
    )

    $result = [BulkOperationResult]::new()

    if ($Items.Count -eq 0) {
        $result.Complete()
        return $result
    }

    # Split items into batches
    $batches = [System.Collections.ArrayList]::new()
    for ($i = 0; $i -lt $Items.Count; $i += $BatchSize) {
        $batch = $Items[$i..([Math]::Min($i + $BatchSize - 1, $Items.Count - 1))]
        [void]$batches.Add($batch)
    }

    $totalBatches = $batches.Count
    $currentBatch = 0

    Write-Verbose "Processing $($Items.Count) items in $totalBatches batch(es) of max $BatchSize"

    foreach ($batch in $batches) {
        $currentBatch++

        if ($ShowProgress) {
            $percentComplete = [int](($currentBatch / $totalBatches) * 100)
            Write-Progress -Activity $ActivityName `
                -Status "Batch $currentBatch of $totalBatches ($($batch.Count) items)" `
                -PercentComplete $percentComplete `
                -CurrentOperation "$Method request"
        }

        try {
            Write-Verbose "[$currentBatch/$totalBatches] Sending batch of $($batch.Count) items"

            # For bulk operations, we send an array directly
            $response = InvokeNetboxRequest -URI $URI -Method $Method -Body $batch -Raw

            # Process response - Netbox returns an array of results for bulk operations
            if ($response -is [array]) {
                foreach ($item in $response) {
                    if ($item.id) {
                        $result.AddSuccess($item)
                    }
                    else {
                        # Item failed validation but request succeeded
                        $errorMsg = if ($item.error) { $item.error } else { "Unknown error" }
                        $result.AddFailure($item, $errorMsg)
                    }
                }
            }
            elseif ($response.id) {
                # Single item response (shouldn't happen in bulk, but handle it)
                $result.AddSuccess($response)
            }
            elseif ($null -eq $response -and $Method -eq 'DELETE') {
                # DELETE operations return null on success
                foreach ($item in $batch) {
                    $result.AddSuccess($item)
                }
            }
            else {
                # Unexpected response format
                Write-Warning "Unexpected response format from bulk $Method request"
                foreach ($item in $batch) {
                    $result.AddSuccess($item)
                }
            }
        }
        catch {
            # Entire batch failed - mark all items as failed
            $errorMessage = $_.Exception.Message
            Write-Warning "Batch $currentBatch failed: $errorMessage"

            foreach ($item in $batch) {
                $result.AddFailure($item, $errorMessage)
            }
        }
    }

    if ($ShowProgress) {
        Write-Progress -Activity $ActivityName -Completed
    }

    $result.Complete()
    Write-Verbose $result.GetSummary()

    return $result
}
