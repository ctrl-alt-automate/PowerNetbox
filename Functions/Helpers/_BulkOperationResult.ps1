<#
.SYNOPSIS
    Class for tracking bulk operation results.

.DESCRIPTION
    Provides a structured result object for bulk API operations that may
    have partial successes and failures. Used by Send-NBBulkRequest and
    bulk-enabled functions.

.EXAMPLE
    $result = [BulkOperationResult]::new()
    $result.AddSuccess($item)
    $result.AddFailure($item, "Validation error")
#>

class BulkOperationResult {
    [System.Collections.Generic.List[PSCustomObject]]$Succeeded
    [System.Collections.Generic.List[PSCustomObject]]$Failed
    [System.Collections.Generic.List[string]]$Errors
    [int]$TotalCount
    [int]$SuccessCount
    [int]$FailureCount
    [bool]$HasErrors
    [timespan]$Duration
    [datetime]$StartTime
    [datetime]$EndTime

    BulkOperationResult() {
        $this.Succeeded = [System.Collections.Generic.List[PSCustomObject]]::new()
        $this.Failed = [System.Collections.Generic.List[PSCustomObject]]::new()
        $this.Errors = [System.Collections.Generic.List[string]]::new()
        $this.TotalCount = 0
        $this.SuccessCount = 0
        $this.FailureCount = 0
        $this.HasErrors = $false
        $this.StartTime = [datetime]::UtcNow
    }

    [void] AddSuccess([PSCustomObject]$Item) {
        $this.Succeeded.Add($Item)
        $this.SuccessCount++
        $this.TotalCount++
    }

    [void] AddFailure([PSCustomObject]$Item, [string]$ErrorMessage) {
        $failedItem = [PSCustomObject]@{
            Item = $Item
            Error = $ErrorMessage
        }
        $this.Failed.Add($failedItem)
        $this.Errors.Add($ErrorMessage)
        $this.FailureCount++
        $this.TotalCount++
        $this.HasErrors = $true
    }

    [void] Complete() {
        $this.EndTime = [datetime]::UtcNow
        $this.Duration = $this.EndTime - $this.StartTime
    }

    [string] GetSummary() {
        return "Bulk operation completed: $($this.SuccessCount)/$($this.TotalCount) succeeded, $($this.FailureCount) failed in $($this.Duration.TotalSeconds.ToString('F2'))s"
    }
}
