---
description: "Run strategy tester with INI file"
---

# /backtest — Backtest Execution

Generate an INI file and run the strategy tester.

## Steps

1. Ask (if not specified):
   - Symbol (default: EURUSD)
   - Period (default: H1)
   - Date range (default: last 1 year)
   - Model (default: 1 = 1 minute OHLC)
   - Deposit (default: 10000)
   - Leverage (default: 1:100)

2. Generate the INI file at `scripts/backtest.ini`:

```ini
[Tester]
Expert=claude\new_dawn
Symbol=EURUSD
Period=H1
Model=1
Optimization=0
FromDate=2025.01.01
ToDate=2026.01.01
ForwardMode=0
Deposit=10000
Currency=USD
Leverage=100
ExecutionMode=0
Report=MQL5\Files\reports\backtest_YYYYMMDD_HHMMSS
ReplaceReport=1
ShutdownTerminal=1
UseLocal=1
UseRemote=0
UseCloud=0

[TesterInputs]
; Fill in the EA input parameters
; Format: ParamName=value||start||step||stop||Y/N
```

3. Run (MUST use PowerShell — bash forward slashes break MT5 /config: paths):
   ```bat
   powershell -Command "Start-Process -FilePath 'C:\Program Files\MetaTrader 5\terminal64.exe' -ArgumentList '/config:C:\Users\tesa2\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\claude\scripts\backtest.ini' -Wait"
   ```

4. Wait for the terminal to shut down (ShutdownTerminal=1)

5. Read the report from the `reports/` folder

## Report File Name

The report filename should include date-time to avoid overwriting previous ones:
`backtest_20260403_143000.htm`

## Important

- The `[TesterInputs]` section is REQUIRED, otherwise the test won't start
- The Expert path is relative to the Experts folder, not absolute
- If historical data doesn't load: open MT5 manually, navigate to the symbol, and download the data first
- Use PowerShell `Start-Process -Wait` to launch MT5 (bash forward slashes cause path issues)
