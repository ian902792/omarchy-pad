"""Claude Code status line: model · prompt count · context · rate limits · session cost.

Reads the JSON Claude Code pipes in. Prompt count scans only transcript bytes added since the last
refresh (offset cached in $TMPDIR), so each refresh stays a few ms however long the session gets.
"""
import json
import os
import sys
import time

d = json.load(sys.stdin)


def prompts(path, session):
    """Distinct prompts the person sent: user entries whose content is a plain string."""
    cache = os.path.join(os.environ.get("TMPDIR", "/tmp"), f"claude-statusline-{session}.json")
    try:
        state = json.load(open(cache))
    except (OSError, ValueError):
        state = {"offset": 0, "ids": []}
    ids = set(state["ids"])
    with open(path, "rb") as f:
        f.seek(state["offset"])
        for raw in f:
            if not raw.endswith(b"\n"):
                break  # half-written line; read it next time
            state["offset"] += len(raw)
            if b'"type":"user"' not in raw:
                continue
            try:
                e = json.loads(raw)
            except ValueError:
                continue
            if isinstance(e.get("message", {}).get("content"), str):
                ids.add(e.get("promptId") or e.get("uuid"))
    state["ids"] = sorted(i for i in ids if i)
    with open(cache, "w") as f:
        json.dump(state, f)
    return len(state["ids"])


parts = [d.get("model", {}).get("display_name", "?")]

try:
    turn = f"第 {prompts(d['transcript_path'], d['session_id'])} 輪"
except (KeyError, OSError):
    turn = "第 ? 輪"
calls = d.get("prompt_cache", {}).get("requests")
parts.append(turn + (f"（{calls} 次呼叫）" if calls else ""))

cw = d.get("context_window") or {}
pct = cw.get("used_percentage")
if pct is not None:
    used = sum((cw.get("current_usage") or {}).get(k, 0) for k in
               ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens"))
    # ponytail: fixed thresholds tuned for a 1M window (200k / 400k); adjust if the window size changes.
    color = "\033[31m" if pct >= 40 else "\033[33m" if pct >= 20 else ""
    parts.append(f"{color}上下文 {pct}% ({used / 1000:.0f}k)" + ("\033[0m" if color else ""))

for key, label in (("five_hour", "5h"), ("seven_day", "7d")):
    r = (d.get("rate_limits") or {}).get(key)
    if r and r.get("used_percentage") is not None:
        reset = time.strftime("%H:%M" if key == "five_hour" else "%m/%d", time.localtime(r["resets_at"])) if r.get("resets_at") else ""
        parts.append(f"{label} {r['used_percentage']}%" + (f"（{reset} 重置）" if reset else ""))

cost = (d.get("cost") or {}).get("total_cost_usd")
if cost is not None:
    parts.append(f"${cost:.2f}")

print(" · ".join(parts))
