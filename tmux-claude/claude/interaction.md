# How we work together (every Claude Code session)

Imported from `~/.claude/CLAUDE.md` via `@~/.claude/interaction.md` (symlinked by tmux-claude/install.sh).

## ❓ when you need something from me

- Any reply that needs something from me (an answer, a decision, an approval, an action only I can take)
  must end with those asks, each on its own line starting with `❓`. Example: `❓ Merge PR #5?`
- The ❓ lines go **last** in the reply, so they are the final thing on screen.
- Use ❓ only for real asks. Never on rhetorical questions, FYIs, or things you will just do.
- No ❓ in a reply means "nothing needed from you, I'm done or still working".

## Session checklist

Keep a running checklist for every session that involves more than a one-off question. It is the shared
record of what is left to do and **who** has to do it.

**Where it lives:** `~/.claude/session-checklists/<session-id>.md`. The session ID is the last part of the
scratchpad path (or the transcript filename). Create the file when the first real task shows up (or at
`/my-session start`), and rewrite it every time the list changes. The file is the source of truth: after a
context compaction, re-read it instead of rebuilding the list from memory.

**Format** (markdown, as it prints in the terminal):

```
**Checklist** (2026-01-15, 10:00 PT)
**Now:** <the one thing in progress right now>

**Before release**
- [ ] **You:** approve and merge PR #12 (config loader): https://github.com/example/app/pull/12
- [ ] **Me:** re-run the integration tests against the new config
- [ ] **Alex (infra):** grant the deploy key write access (#34)
- [x] **Me:** write up the retry-policy decision

**Done this session**
- [x] v3 → v5 of the parser tested; PRs #9 and #10 merged

**Blocking:** Alex (#34) and your approval on PR #12.
```

Rules:
- **Every open item names an owner**: `**You:**`, `**Me:**`, or `**<Name> (<team>):**` for anyone else.
- **Phase headings depend on the session.** Pick ones that fit the work, e.g. "Before go-live",
  "Cutover day", "After release", "Wrap-up", "Testing". A small session can have a single "To do" heading.
- **Tick items off in place** (`[ ]` → `[x]`) as soon as they're done. Don't delete them.
  "Done this session" is for finished work that was never a planned item.
- Dropped items become `- [-] … (dropped)` and stay in the list.
- Add new items the moment they come up: follow-ups, things waiting on other people, deferred ideas.
- Include issue/ticket keys, PR numbers, and full raw URLs (never markdown link syntax).
- A table is fine for a test matrix or anything with several columns (#, case, who, status).
- End with a one-line **Blocking:** summary when something is waiting on someone. Omit it when nothing is.
- Keep items short, one line each.

**When to print it:** only when I ask (`/my-session checklist`) and one last time at `/my-session end`
(which first asks me what to do with every unchecked item).
Otherwise keep the file up to date silently and don't print it in replies.

**Reply order:** answer/work → ❓ asks (if any).
