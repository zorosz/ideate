$log = 'C:\Users\tesa2\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\Tester\logs\20260411.log'
Get-Content $log -Tail 200 | Where-Object { $_ -match 'WT signal|CHoCH|breakCount|swingCount|final balance|warmed up' }
