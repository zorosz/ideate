param([string]$XmlPath, [int]$Top = 10)

[xml]$doc = Get-Content $XmlPath
$ns = @{ ss = 'urn:schemas-microsoft-com:office:spreadsheet' }
$rows = $doc.Workbook.Worksheet.Table.Row

# Header row — find column indices
$headers = @()
foreach ($cell in $rows[0].Cell) {
    $headers += $cell.Data.'#text'
}

# Parse all data rows
$results = @()
for ($r = 1; $r -lt $rows.Count; $r++) {
    $values = @()
    foreach ($cell in $rows[$r].Cell) {
        $values += $cell.Data.'#text'
    }
    $obj = @{}
    for ($i = 0; $i -lt $headers.Count; $i++) {
        $obj[$headers[$i]] = $values[$i]
    }
    $results += [PSCustomObject]$obj
}

# Sort by Sharpe Ratio descending, take top N
$sorted = $results | Sort-Object { [double]$_.'Sharpe Ratio' } -Descending | Select-Object -First $Top

# Print header
Write-Output ("| # | Harvest | Batch | MaxLoss% | Profit   | PF   | EV      | Sharpe | RecFact | DD%    | Trades |")
Write-Output ("|---|---------|-------|----------|----------|------|---------|--------|---------|--------|--------|")

$rank = 1
foreach ($row in $sorted) {
    $line = "| {0} | {1,7} | {2,5} | {3,8} | {4,8} | {5,4} | {6,7} | {7,6} | {8,7} | {9,6} | {10,6} |" -f `
        $rank,
        $row.HarvestPips,
        $row.BatchClosePips,
        $row.MaxFloatingLossPct,
        $row.Profit,
        $row.'Profit Factor',
        $row.'Expected Payoff',
        $row.'Sharpe Ratio',
        $row.'Recovery Factor',
        $row.'Equity DD %',
        $row.Trades
    Write-Output $line
    $rank++
}
