---
name: health-data
description: Get Health data — read data/apple-health-snapshot.md (synced from Apple Health). Use when user asks "есть данные с health?", "получи через skills", "как дела по здоровью?", "оцени состояние". This skill gives you access to the file; call read tool first.
metadata: { "openclaw": { "emoji": "❤️" } }
---

# Health Data (Apple Health snapshot)

**This skill is how you get data from Health.** The file `data/apple-health-snapshot.md` in workspace already contains the user's Apple Health data (synced from iPhone). You do NOT need a "connection" to Apple Health — just read this file.

Use this skill when the user asks: "есть данные с health?", "получи их через skills", "как дела по здоровью?", "оцени состояние", or any question about health for recent days.

## Required steps

1. **First:** Call the `read` tool with path **`data/apple-health-snapshot.md`** (relative to workspace root). This file contains the user's Apple Health data for the last 7 days.
2. **Then:** Answer the user based **only** on the content of that file. Summarize sleep, steps, heart rate, activity, or whatever is in the snapshot.
3. **Do not** say "I don't have access to Health data" or "нет данных из Health" without having called `read` for `data/apple-health-snapshot.md` first. If the file is missing or empty after reading, then say so and suggest evening check-in or manual input.

## Optional

- If the user asked about several days and you need more detail, also read `health/log-YYYY-MM-DD.md` for the relevant dates (replace with actual dates, e.g. last 3–7 days).

## If user said "получи через skills" / "get them via skills"

They mean: use **this** skill. The data is already in the workspace — call `read` with path `data/apple-health-snapshot.md`, then answer from the file content. You do not need any other skill or "connection" to Apple Health.

## Relation to OpenClaw healthkit-sync / healthsync

The file `data/apple-health-snapshot.md` is **filled by the healthsync pipeline** (iOS app + healthsync CLI on a Mac; see OpenClaw skill **healthkit-sync** for pairing, `healthsync fetch`, and data types). The snapshot is then copied to this workspace (e.g. via `apple-health-push-snapshot.sh`). **This skill (health-data)** is for the agent on **this** machine: read that file and answer from it. You do not run healthsync here — the file is already here.

## Short rule

**Read `data/apple-health-snapshot.md` with the read tool before any answer about health status, "есть данные с health", or "получи через skills".**
