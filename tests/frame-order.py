#!/data/data/com.termux/files/usr/bin/python
# Typing smoothness check: types into the kitty window titled TITLE, grabs its first lines as fast as possible
# and counts frames identical to an earlier, non-adjacent frame (= the screen jumped back). Expect backwards=0.
# Run with DISPLAY=:0:  kitty --title t -o cursor_blink_interval=0 cat &   then   python tests/frame-order.py t
import json, subprocess, sys, time, threading, hashlib
from PIL import ImageGrab
title = sys.argv[1]
def rect():
    def walk(n):
        if n.get("name") == title: return n["rect"]
        for c in n.get("nodes", []) + n.get("floating_nodes", []):
            r = walk(c)
            if r: return r
    return walk(json.loads(subprocess.check_output(["i3-msg", "-t", "get_tree"])))
r = rect()
subprocess.run(["i3-msg", "-q", f"[title=\"^{title}$\"] focus"])
box = (r["x"], r["y"], r["x"] + 1200, r["y"] + 120)
text = "the quick brown fox jumps over the lazy dog 0123456789 " * 2
done = False
def typer():
    global done
    time.sleep(0.3)
    subprocess.run(["xdotool", "type", "--delay", "45", text]); time.sleep(0.5); done = True
threading.Thread(target=typer).start()
seen, order, back = {}, [], 0
while not done:
    h = hashlib.md5(ImageGrab.grab(bbox=box, xdisplay=":0").tobytes()).hexdigest()
    if order and h == order[-1]: continue
    if h in seen: back += 1
    seen[h] = len(order); order.append(h)
print(f"{title}: frames={len(order)} backwards={back}")
