---
description: "Save session state before exiting"
---

# /session-save — Save Session Summary

Create a concise session summary and save it to a file.

## What to Include

Write to the `sessions/` folder as a timestamped .md file (e.g. `sessions/2026-04-03_1430.md`):

1. **What I worked on**: one or two sentences about the session's goal
2. **What changed**: which files were modified and how
3. **What worked**: what compiled/tested successfully
4. **What didn't work**: if there were errors, what and why
5. **Next step**: exactly what to do in the next session
6. **Open questions**: anything that still needs to be clarified

## Format

```markdown
# Session — [date and time]

## Goal
[what was today's goal]

## Changes
- `new_dawn.mq5`: [what changed]

## Results
- Compile: OK / X errors
- Backtest: [profit factor, drawdown, trade count if it ran]

## Next Step
[specific action item]

## Open Questions
[if any]
```

## Important

- Create the `sessions/` folder if it doesn't exist
- The filename must always include date and time
- Be concise — this is not a diary, it's context for the next session
- Only write facts: what happened, what's the plan — don't over-explain
