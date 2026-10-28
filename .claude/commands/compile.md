---
description: "MQL5 EA compilation and error checking"
---

# /compile — Compilation

Compile the EA and check for errors.

## Steps

1. Run MetaEditor compilation (MUST use PowerShell — bash forward slashes break paths):
   ```bat
   powershell -Command "Start-Process -FilePath 'C:\Program Files\MetaTrader 5\metaeditor64.exe' -ArgumentList '/compile:C:\Users\tesa2\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\claude\new_dawn.mq5','/log:C:\Users\tesa2\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\claude\compile.log','/inc:C:\Users\tesa2\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5' -Wait"
   ```

2. Read the `compile.log` file

3. If **0 errors** → proceed to the next step
4. If there are **errors**:
   - Read the error messages
   - Fix them in the source file
   - Recompile
   - Repeat until 0 errors

5. If there are **warnings**:
   - Evaluate: is it dangerous? (e.g. implicit type conversion, unused variable)
   - If yes: fix it
   - If not critical: note it, but don't get stuck on it

## Notes

- The MetaEditor compiler places the .ex5 file next to the source
- Without the `/log` flag we don't get detailed error messages
- The `/inc` flag specifies the Include folder path for shared headers
