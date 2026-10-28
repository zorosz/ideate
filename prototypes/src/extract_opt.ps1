param([string]$XmlPath)

[xml]$doc = Get-Content $XmlPath
$ns = @{ ss = 'urn:schemas-microsoft-com:office:spreadsheet' }
$rows = $doc.Workbook.Worksheet.Table.Row

# Header row
$headers = @()
foreach ($cell in $rows[0].Cell) {
    $headers += $cell.Data.'#text'
}

# First data row = best result (sorted by optimizer)
if ($rows.Count -lt 2) {
    Write-Output "No optimization results found"
    return
}
$best = $rows[1]
$values = @()
foreach ($cell in $best.Cell) {
    $values += $cell.Data.'#text'
}

for ($i = 0; $i -lt $headers.Count; $i++) {
    Write-Output "$($headers[$i]): $($values[$i])"
}
