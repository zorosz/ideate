---
description: "Plan a feature for the EA"
---

# /plan — Feature Planning

Plan the feature before writing any code.

## Steps

1. **Goal**: Describe in one sentence what you want to achieve
2. **Affected files**: List which files need to be modified/created
3. **Input parameters**: What new `input` variables are needed?
4. **Logic**: Describe the behavior in pseudo-code
5. **Testing plan**: Which symbol, period, date range to test on?
6. **Acceptance criteria**: When is it considered successful? (e.g. profit factor > 1.5, max drawdown < 20%)

## Output

Create a short plan using the structure above. Do not start coding until the plan is approved.

## Important

- One feature = one plan. Don't bundle multiple things together.
- If the plan touches more than 3 files, it's probably too big — break it down.
- Explicit values everywhere: not "some reasonable lot size", but "0.01 lot".
