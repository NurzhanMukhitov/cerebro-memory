---
name: health-data
description: Answer questions about user's health status for recent days using Apple Health snapshot. When user asks "как дела по здоровью?", "оцени состояние", "есть данные с health" — read data file and reply from it.
metadata: { "openclaw": { "emoji": "❤️" } }
---

# Health Data (Apple Health snapshot)

This skill applies when the user asks about their **health status**, **recent days health**, or whether you have **data from Health** (Apple Health).

## Required steps

1. **First:** Call the `read` tool with path **`data/apple-health-snapshot.md`** (relative to workspace root). This file contains the user's Apple Health data for the last 7 days.
2. **Then:** Answer the user based **only** on the content of that file. Summarize sleep, steps, heart rate, activity, or whatever is in the snapshot.
3. **Do not** say "I don't have access to Health data" or "нет данных из Health" without having called `read` for `data/apple-health-snapshot.md` first. If the file is missing or empty after reading, then say so and suggest evening check-in or manual input.

## Optional

- If the user asked about several days and you need more detail, also read `health/log-YYYY-MM-DD.md` for the relevant dates (replace with actual dates, e.g. last 3–7 days).

## Short rule

**Read `data/apple-health-snapshot.md` with the read tool before any answer about health status or "есть данные с health".**
