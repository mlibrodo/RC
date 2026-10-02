---
name: my-session
description: Manual session bookkeeping. `/my-session start <what this session is about>` marks a session's purpose and opens its checklist, `/my-session restart` restores the tmux labels after a resume, `/my-session checklist` prints the checklist, `/my-session end` marks it finished and prints the final checklist, `/my-session review [timeframe]` lists previous sessions with their status. Only run when the user types /my-session.
argument-hint: start <topic> | restart | checklist | end | review [timeframe]
disable-model-invocation: true
---

# /my-session

Arguments: `$ARGUMENTS`. The first word is the subcommand: `start`, `restart`, `checklist`, `end`, or `review`.
Anything else → reply with the five usages below and stop.

```
/my-session start <what this session is about>
/my-session restart                  (after resuming, e.g. post-reboot: put the tmux labels back)
/my-session checklist
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

## The checklist

The format and rules live in `~/.claude/interaction.md` (loaded globally from `~/.claude/CLAUDE.md`).
The file is `~/.claude/session-checklists/<session-id>.md`, where the session ID is the last part of the
scratchpad path or the transcript filename. `mkdir -p ~/.claude/session-checklists` before the first write.

## start

The command itself, as recorded in the transcript, is the marker.

1. Label the tmux window. Pull out an issue/ticket key (e.g. `ABC-123`) from the topic if one is there:
   ```bash
   ~/.claude/skills/my-session/scripts/tmux-label.sh "<bar label>" "<summary>" <session-id>
   ```
   - Passing the session ID saves the labels to `~/.claude/session-labels/<session-id>`, so
     `/my-session restart` can put them back after the session is resumed.
   - **bar label** (status bar): `<KEY> <1–3 words>`, e.g. `ABC-123 parser rewrite`. If there's no ticket,
     use 1–3 words only. Make it something the user can recognize at a glance, not generic ("work", "session").
   - **summary** (`Ctrl-a w` window list): one plain sentence of 20 words or fewer saying what the session is for.
   - The script caps these at 4 and 20 words, and does nothing outside tmux.
   - If the topic is empty, skip this until the user says what the session is about.
2. Create the checklist file if it doesn't exist yet (a restarted session keeps its old one). Seed it with the
   topic as **Now:** and any obvious first items, each with an owner.
3. Reply with one line: `Session started — <topic>` plus the pwd.
4. Then treat the topic as the user's first request and begin the work. If the topic is empty,
   ask what the session is about.

## restart

Use it after resuming a session (reboot, new tmux server). It only runs when the user types it. There is no hook.
The command is a marker. If the session had been ended, a `restart` after that `end` makes it live again
(`review` shows ↩️ Reopened after end) until the next `/my-session end`.
1. If `~/.claude/session-labels/<session-id>` exists, re-apply it:
   `~/.claude/skills/my-session/scripts/tmux-label.sh "$(sed -n 1p <file>)" "$(sed -n 2p <file>)"`
2. Otherwise build the labels from the most recent `/my-session start` topic in this conversation, with the
   same rules as `start` step 1, and run `tmux-label.sh` with the session ID so they're saved for next time.
   If there was never a `start`, ask what the session is about, then label it the same way.
3. If the checklist's **Now:** says `Session ended`, change it to `Resumed — <topic>` (or the next open item).
4. Reply with one line: `Session resumed — <topic>` plus the pwd, and the open-item count from the
   checklist file (e.g. `3 open (You 1, Me 2)`). If the session had been ended, add `(reopened)`.
   Don't print the checklist.

## checklist

Re-read the checklist file and print it in full. If there is no file yet, build one from the conversation so
far, write it, then print it. Nothing else.

## end

The command itself is the marker.
1. Bring the checklist file up to date: tick off everything that got done and add anything left open.
2. **Triage what's still open, before ending.** If any `[ ]` items remain, ask about them with
   `AskUserQuestion`. Don't use plain text: the answers come back as tool results, so the review script
   still sees the session as ended.
   - With 4 or fewer open items, ask one question per item (header = owner, question = the item). Options:
     - **Carry over:** leave it `[ ]`. It shows in `/my-session review` as an open item.
     - **Drop:** change it to `- [-] … (dropped)`.
     - **Already done:** tick it `[x]`.
     - **Do it now:** don't end. Say `Not ended — finish the work, then run /my-session end again.` and stop.
   - With more than 4, ask one question per owner (You / Me / each other person), multiSelect over that
     owner's items, "Which of these should carry over? Unselected ones get dropped." If you can't tell
     what to do with something, add one more question for it.
   - If the user dismisses the questions, treat everything as carried over.
3. Set **Now:** to `Session ended`, write the file, and print the full checklist one last time.
4. Under it, at most 2 lines on what's carried over and who it's waiting on.
5. Then `Session marked ended.` Take no other actions: no commits, no issue/ticket changes.

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

   | # | Last active | Session ID (full) | pwd | Topic | Open items | Status |

   - Topic = `start_topic` if present. Otherwise write a short summary from `first` and the last messages,
     including ticket keys and PR numbers.
   - pwd uses `~`.
   - Open items = the script's `checklist:` line (e.g. `3 open (You 1, Me 2)`), or `-` if there is none.
5. Above the table, put the resume command: `cd <pwd> && claude --resume <session-id>`.
   Below the table, name the ⚠️ sessions flagged `ACTIVE_<36H_BEFORE_BOOT` or `INTERRUPTED` as the ones a
   reboot or crash likely cut off.
