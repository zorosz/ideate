param([string]$XmlFile, [int]$Top = 5)

$xml = [xml](Get-Content $XmlFile -Encoding UTF8)
$rows = $xml.Workbook.Worksheet.Table.Row

Write-Host "Total rows: $($rows.Count)"
if ($rows.Count -lt 2) { exit }

# Headers from first row
$headers = @()
foreach ($cell in $rows[0].Cell) {
    $headers += $cell.Data.'#text'
}
Write-Host "Headers: $($headers -join ' | ')"
Write-Host ""

# Build objects for each data row
$results = @()
for ($i = 1; $i -lt $rows.Count; $i++) {
    $obj = New-Object PSObject
    $cells = $rows[$i].Cell
    for ($j = 0; $j -lt $headers.Count -and $j -lt $cells.Count; $j++) {
        $val = $cells[$j].Data.'#text'
        if ($val -match '^-?\d+\.?\d*$') { $val = [double]$val }
        $obj | Add-Member -NotePropertyName $headers[$j] -NotePropertyValue $val
    }
    $results += $obj
}

# Sort by Profit descending, show top N
$sorted = $results | Sort-Object -Property "Profit" -Descending
Write-Host "Top $Top by Profit:"
$sorted | Select-Object -First $Top | Format-Table -AutoSize
