param([string]$XmlFile, [int]$MinTrades = 30, [int]$Top = 10)

$xml = [xml](Get-Content $XmlFile -Encoding UTF8)
$rows = $xml.Workbook.Worksheet.Table.Row

$headers = @()
foreach ($cell in $rows[0].Cell) {
    $headers += $cell.Data.'#text'
}

Write-Host "All headers: $($headers -join ' | ')"
Write-Host ""

$results = @()
for ($i = 1; $i -lt $rows.Count; $i++) {
    $obj = New-Object PSObject
    $cells = $rows[$i].Cell
    for ($j = 0; $j -lt $headers.Count -and $j -lt $cells.Count; $j++) {
        $val = $cells[$j].Data.'#text'
        $clean = $val -replace ',', '.'
        if ($clean -match '^-?\d+\.?\d*$') { $val = [double]$clean }
        $obj | Add-Member -NotePropertyName $headers[$j] -NotePropertyValue $val
    }
    $results += $obj
}

$filtered = $results | Where-Object { [double]$_.Trades -ge $MinTrades }
Write-Host "Total passes: $($results.Count)"
Write-Host "Passes with >= $MinTrades trades: $($filtered.Count)"
Write-Host ""

$sorted = $filtered | Sort-Object -Property "Profit" -Descending

# Show all columns for top N
Write-Host "Top $Top by Profit (min $MinTrades trades):"
$sorted | Select-Object -First $Top | Format-List Profit, "Profit Factor", "Sharpe Ratio", "Equity DD %", Trades, *Hour, *Length, *Age, *Mult, *Bars*, *Buffer*, *Zone*
