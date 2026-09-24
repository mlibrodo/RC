---
name: my-session
description: Manual session bookkeeping. `/my-session start <what this session is about>` marks a session's purpose, `/my-session end` marks it finished, `/my-session review [timeframe]` lists previous sessions with their status. Only run when the user types /my-session.
argument-hint: start <topic> | end | review [timeframe]
disable-model-invocation: true
---

# /my-session

Arguments: `$ARGUMENTS`. The first word is the subcommand: `start`, `end`, or `review`. Anything else →
reply with the three usages below and stop.

```
/my-session start <what this session is about>
/my-session end
/my-session review [timeframe]     e.g. "2 weeks", "60 days", "2 months" (default 4 weeks)
```

## Model gate (every subcommand)

The user never wants to work on a lower-tier model. Check your own model name (from your system prompt).
- **Blocked:** any Sonnet or Haiku model.
- **Allowed:** Opus or Fable.

If you're on a blocked model, do nothing else. Reply only:

> You're on **<model>**. Run `/model opus`, then re-run `/my-session <subcommand> …`.

A start/end typed on a blocked model does not count as a marker. The review script ignores it.

## start

The command itself, as recorded in the transcript, is the marker. Nothing needs to be written anywhere.

1. Label the tmux window. Pull out a ticket key (e.g. `PROJ-123`) from the topic if one is there:
   ```bash
   ~/.claude/skills/my-session/scripts/tmux-label.sh "<bar label>" "<summary>"
   ```
   - **bar label** (status bar): `<TICKET> <1–3 words>`, e.g. `PROJ-123 agent tuning`. If there's no ticket,
     use 1–3 words only. Make it something the user can recognize at a glance, not generic ("work", "session").
   - **summary** (`Ctrl-a w` window list): one plain sentence of 20 words or fewer saying what the session is for.
   - The script caps these at 4 and 20 words, and does nothing outside tmux.
   - If the topic is empty, skip this until the user says what the session is about.
2. Reply with one line: `Session started — <topic>` plus the pwd.
3. Then treat the topic as the user's first request and begin the work. If the topic is empty,
   ask what the session is about.

## end

The command itself is the marker. Reply with a short recap, 5 bullets at most:
- what got done (ticket keys, PR/doc links)
- anything left open or waiting on someone
Then `Session marked ended.` Take no other actions: no commits, no ticket changes.

## review

1. Convert the timeframe to days (`2 weeks`→14, `2 months`→60, default 28). Run:
   ```bash
   python3 ~/.claude/skills/my-session/scripts/digest.py --days <N> --exclude <current-session-id>
   ```
   The current session ID is in the scratchpad or transcript path. If you can't find it, skip `--exclude`
   and label this session "(this session)".
2. Drop sessions that are just session lookups or throwaway tests (e.g. "reply with exactly: canary").
   Say in one line how many were dropped.
3. Status comes **only** from the script's `STATUS`. Never infer it from wording like "ok thanks" or "done":
   | STATUS | Show |
   |---|---|
   | ENDED | ✅ Ended |
   | REOPENED_AFTER_END | ↩️ Reopened after end |
   | NOT_ENDED | ⚠️ Not ended |
4. Output one table, most recently active first:

   | # | Last active | Session ID (full) | pwd | Topic | Status |

   - Topic = `start_topic` if present. Otherwise write a short summary from `first` and the last messages,
     including ticket keys and PR numbers.
   - pwd uses `~`.
5. Above the table, put the resume command: `cd <pwd> && claude --resume <session-id>`.
   Below the table, name the ⚠️ sessions flagged `ACTIVE_<36H_BEFORE_BOOT` or `INTERRUPTED` as the ones a
   reboot or crash likely cut off.
