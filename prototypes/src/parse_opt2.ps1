param([string]$XmlFile, [int]$MinTrades = 50, [int]$Top = 10)

$xml = [xml](Get-Content $XmlFile -Encoding UTF8)
$rows = $xml.Workbook.Worksheet.Table.Row

$headers = @()
foreach ($cell in $rows[0].Cell) {
    $headers += $cell.Data.'#text'
}

$results = @()
for ($i = 1; $i -lt $rows.Count; $i++) {
    $obj = New-Object PSObject
    $cells = $rows[$i].Cell
    for ($j = 0; $j -lt $headers.Count -and $j -lt $cells.Count; $j++) {
        $val = $cells[$j].Data.'#text'
        # Try to parse as number (handle European decimal comma)
        $clean = $val -replace ',', '.'
        if ($clean -match '^-?\d+\.?\d*$') { $val = [double]$clean }
        $obj | Add-Member -NotePropertyName $headers[$j] -NotePropertyValue $val
    }
    $results += $obj
}

# Filter: minimum trades
$filtered = $results | Where-Object { [double]$_.Trades -ge $MinTrades }
Write-Host "Total passes: $($results.Count)"
Write-Host "Passes with >= $MinTrades trades: $($filtered.Count)"
Write-Host ""

$sorted = $filtered | Sort-Object -Property "Profit" -Descending
Write-Host "Top $Top by Profit (min $MinTrades trades):"
$sorted | Select-Object -First $Top Profit, "Profit Factor", "Sharpe Ratio", "Equity DD %", Trades, SwingLength, MaxSwingAge, MinPierceMult, MaxBarsInTrade, StopBufferPips | Format-Table -AutoSize
