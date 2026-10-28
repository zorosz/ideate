param([string]$ReportPath)

# Read only the first 200KB (summary section is always at the top)
$bufSize = 400000
$bytes = New-Object byte[] $bufSize
$fs = New-Object System.IO.FileStream($ReportPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
$bytesRead = $fs.Read($bytes, 0, $bufSize)
$fs.Close()
$content = [System.Text.Encoding]::Unicode.GetString($bytes, 0, $bytesRead)
$content = $content -replace [char]0, ''

# Extract all td content - get the values between <b> tags inside <td>
$tdPattern = '<td[^>]*>\s*<b>(.*?)</b>\s*</td>'
$matches = [regex]::Matches($content, $tdPattern, 'Singleline')
$boldValues = @()
foreach ($m in $matches) {
    $text = $m.Groups[1].Value -replace '<[^>]+>', '' -replace '&nbsp;', ' ' -replace '\s+', ' '
    $text = $text.Trim()
    $boldValues += $text
}

# Also extract plain td content for labels
$allTdPattern = '<td[^>]*>(.*?)</td>'
$allMatches = [regex]::Matches($content, $allTdPattern, 'Singleline')
$allValues = @()
foreach ($m in $allMatches) {
    $text = $m.Groups[1].Value -replace '<[^>]+>', '' -replace '&nbsp;', ' ' -replace '\s+', ' '
    $text = $text.Trim()
    $allValues += $text
}

# Find key metrics by looking for labels and next value
$metrics = @(
    'Total Net Profit:', 'Gross Profit:', 'Gross Loss:',
    'Profit Factor:', 'Expected Payoff:', 'Recovery Factor:', 'Sharpe Ratio:',
    'Balance Drawdown Maximal:', 'Equity Drawdown Maximal:',
    'Balance Drawdown Relative:', 'Equity Drawdown Relative:',
    'Total Trades:', 'Total Deals:',
    'Short Trades (won %):', 'Long Trades (won %):'
)

for ($i = 0; $i -lt $allValues.Count; $i++) {
    foreach ($metric in $metrics) {
        $cleanMetric = $metric.TrimEnd(':')
        if ($allValues[$i] -eq $cleanMetric -or $allValues[$i] -eq $metric) {
            $val = if ($i+1 -lt $allValues.Count) { $allValues[$i+1] } else { "N/A" }
            Write-Output "${cleanMetric}: $val"
        }
    }
}
