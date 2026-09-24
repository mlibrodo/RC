#!/usr/bin/env python3
"""Digest recent Claude Code sessions for `/my-session review`.

Usage: digest.py [--days N] [--exclude SESSION_ID_PREFIX]

Status comes only from explicit `/my-session start|end` markers in each transcript.
A marker counts only if the assistant reply right after it came from an allowed model
(anything but Sonnet/Haiku, i.e. Opus or Fable).
"""
import argparse
import datetime as dt
import glob
import json
import os
import re
import subprocess
import time

ROOT = os.path.expanduser(os.environ.get("MY_SESSION_ROOT", "~/.claude/projects"))
HOME = os.path.expanduser("~")
CMD_RE = re.compile(r"<command-name>/?([^<]+)</command-name>")
ARGS_RE = re.compile(r"<command-args>(.*?)</command-args>", re.S)
BLOCKED_MODELS = ("sonnet", "haiku")


def boot_time():
    try:
        out = subprocess.run(["sysctl", "-n", "kern.boottime"], capture_output=True, text=True).stdout
        return int(re.search(r"^\{ sec = (\d+)", out).group(1))
    except Exception:
        return None


def text_of(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return " ".join(c.get("text", "") for c in content if isinstance(c, dict) and c.get("type") == "text")
    return ""


def local(ts):
    return dt.datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone().strftime("%m-%d %H:%M")


def epoch(ts):
    return dt.datetime.fromisoformat(ts.replace("Z", "+00:00")).timestamp()


def one_line(s, n):
    return re.sub(r"\s+", " ", s or "").strip()[:n]


def digest(path):
    s = dict(title=None, cwd=None, start=None, last=None, first=None, users=[], last_asst="",
             markers=[], last_model=None)
    pending = None  # marker waiting for the next assistant reply to learn its model
    for line in open(path, errors="ignore"):
        try:
            d = json.loads(line)
        except ValueError:
            continue
        t = d.get("type")
        if t in ("custom-title", "ai-title", "summary"):
            s["title"] = d.get("customTitle") or d.get("aiTitle") or d.get("title") or d.get("summary") or s["title"]
        ts = d.get("timestamp")
        if ts:
            s["start"] = s["start"] or ts
            s["last"] = ts
        s["cwd"] = s["cwd"] or d.get("cwd")
        if d.get("isSidechain"):
            continue
        if t == "user" and not d.get("isMeta"):
            m = text_of(d.get("message", {}).get("content"))
            if not m.strip():
                continue
            cm = CMD_RE.search(m)
            if cm:
                if cm.group(1).strip() == "my-session":
                    a = ARGS_RE.search(m)
                    args = (a.group(1) if a else "").strip()
                    sub, _, rest = args.partition(" ")
                    pending = dict(sub=sub.lower(), args=rest.strip(), ts=ts, model=None,
                                   users_before=len(s["users"]))
                    s["markers"].append(pending)
                continue
            if m.lstrip().startswith("<") or m.startswith("Another Claude session sent a message") \
                    or m.startswith("Base directory for this skill"):
                continue
            s["users"].append(m)
            s["first"] = s["first"] or m
        elif t == "assistant":
            model = d.get("message", {}).get("model")
            if model and model != "<synthetic>":
                s["last_model"] = model
                if pending and pending["model"] is None:
                    pending["model"] = model
                    pending = None
            a = text_of(d.get("message", {}).get("content"))
            if a.strip():
                s["last_asst"] = a
    return s


def status(s):
    valid = [m for m in s["markers"] if m["model"] and not any(b in m["model"].lower() for b in BLOCKED_MODELS)]
    starts = [m for m in valid if m["sub"] == "start"]
    ends = [m for m in valid if m["sub"] == "end"]
    topic = starts[-1]["args"] if starts else None
    if not ends:
        return "NOT_ENDED", topic
    if len(s["users"]) > ends[-1]["users_before"]:
        return "REOPENED_AFTER_END", topic
    return "ENDED", topic


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=28)
    ap.add_argument("--exclude", action="append", default=[])
    args = ap.parse_args()

    boot = boot_time()
    cutoff = time.time() - args.days * 86400
    rows, skipped = [], {"no_user_msgs": 0, "excluded": 0}
    for f in glob.glob(f"{ROOT}/*/*.jsonl"):
        if os.path.getmtime(f) < cutoff:
            continue
        sid = os.path.basename(f)[:-6]
        if any(sid.startswith(x) for x in args.exclude):
            skipped["excluded"] += 1
            continue
        s = digest(f)
        if not s["users"] or not s["last"]:
            skipped["no_user_msgs"] += 1
            continue
        s["sid"] = sid
        rows.append(s)
    rows.sort(key=lambda r: r["last"], reverse=True)

    if boot:
        print(f"LAST BOOT: {dt.datetime.fromtimestamp(boot).strftime('%Y-%m-%d %H:%M')}")
    print(f"WINDOW: {args.days} days   SESSIONS: {len(rows)}   SKIPPED: {skipped}\n")
    for r in rows:
        st, topic = status(r)
        flags = []
        if boot and 0 <= boot - epoch(r["last"]) < 36 * 3600 and st != "ENDED":
            flags.append("ACTIVE_<36H_BEFORE_BOOT")
        if r["last_asst"].startswith("API Error") or not r["last_asst"]:
            flags.append("INTERRUPTED")
        print(f"=== {r['sid']}")
        print(f"cwd: {(r['cwd'] or '?').replace(HOME, '~')}   active: {local(r['start'])} -> {local(r['last'])}   "
              f"user_msgs: {len(r['users'])}   model: {r['last_model'] or '?'}")
        print(f"STATUS: {st}   flags: {','.join(flags) or '-'}")
        print(f"start_topic: {one_line(topic, 200) if topic else '-'}   title: {r['title'] or '-'}")
        print(f"first: {one_line(r['first'], 200)}")
        for u in r["users"][-2:]:
            print(f"  user: {one_line(u, 150)}")
        print(f"  last_reply: {one_line(r['last_asst'], 180)}\n")


if __name__ == "__main__":
    main()
