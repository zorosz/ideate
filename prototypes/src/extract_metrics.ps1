param([string]$ReportPath)

$content = [System.IO.File]::ReadAllText($ReportPath, [System.Text.Encoding]::Unicode)
$flat = $content -replace '\r?\n',' ' -replace '\s+',' '

function Get-Metric($label) {
    if ($flat -match "$label</td>\s*<td[^>]*><b>(.*?)</b></td>") {
        return $Matches[1].Trim()
    }
    return "N/A"
}

Write-Output "Total Net Profit: $(Get-Metric 'Total Net Profit:')"
Write-Output "Gross Profit: $(Get-Metric 'Gross Profit:')"
Write-Output "Gross Loss: $(Get-Metric 'Gross Loss:')"
Write-Output "Profit Factor: $(Get-Metric 'Profit Factor:')"
Write-Output "Expected Payoff: $(Get-Metric 'Expected Payoff:')"
Write-Output "Recovery Factor: $(Get-Metric 'Recovery Factor:')"
Write-Output "Sharpe Ratio: $(Get-Metric 'Sharpe Ratio:')"
Write-Output "Balance DD Max: $(Get-Metric 'Balance Drawdown Maximal:')"
Write-Output "Equity DD Max: $(Get-Metric 'Equity Drawdown Maximal:')"
Write-Output "Total Trades: $(Get-Metric 'Total Trades:')"
Write-Output "Short Trades: $(Get-Metric 'Short Trades \(won %\):')"
Write-Output "Long Trades: $(Get-Metric 'Long Trades \(won %\):')"
Write-Output "Profit Trades: $(Get-Metric 'Profit Trades \(% of total\):')"
Write-Output "Loss Trades: $(Get-Metric 'Loss Trades \(% of total\):')"
Write-Output "Avg Profit Trade: $(Get-Metric 'Average profit trade:')"
Write-Output "Avg Loss Trade: $(Get-Metric 'Average loss trade:')"
Write-Output "Largest Profit: $(Get-Metric 'Largest profit trade:')"
Write-Output "Largest Loss: $(Get-Metric 'Largest loss trade:')"
