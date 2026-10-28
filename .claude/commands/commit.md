---
description: "Commit changes with a short message"
---

# /commit — Git Commit

Commit the current changes with a concise message.

## Steps

1. Run: `git add -A` (from the project folder)
2. Generate a short, English commit message describing what changed
   - Format: `<type>: <description>`
   - Types: `feat`, `fix`, `refactor`, `test`, `docs`
   - Example: `feat: add trailing stop logic`
   - Example: `fix: normalize lot size to broker min`
3. Run: `git commit -m "<message>"`
4. Show the commit hash and message

## When to Commit

- After a successful compile (before backtesting)
- After a successful backtest (if results are good)
- At any working state you want to be able to return to

## Important

- Do not commit if there are compile errors
- One commit = one logical change
