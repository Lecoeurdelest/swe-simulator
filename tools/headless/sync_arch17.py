"""Keep ARCHITECTURE.md section 17 byte-exact with the code (AGENTS.md, DECISIONS A71).

Between the headings "## 17." and "## 18.", each ```gdscript block must equal its source file byte for byte: the
file's content without its single final newline. The file of a block is named in its section heading or in a
backticked "`path.gd`:" line above it (17.5 names bare files under data/types/, 17.13 bare files under tests/).

usage (from the repo root; use `python` on Windows, `python3` on the Mac):
  python tools/headless/sync_arch17.py .                           report every block, exit 1 if any differs
  python tools/headless/sync_arch17.py . --fix [path ...]          rewrite the differing blocks (only those files if listed)
  python tools/headless/sync_arch17.py . --add-types path ...      append blocks for new data/types/*.gd files to 17.5
  python tools/headless/sync_arch17.py . --add-section "17.NN Title" path ...
                                                                   add a new subsection at the end of section 17
"""
import re
import sys

FENCE_OPEN = b"```gdscript"
FENCE = b"```"


def parse_blocks(doc: bytes):
    """Return (blocks, span). Each block: heading, named, first_line, last_line, start, end, content, where start
    and end are the byte offsets of the content between the fence lines."""
    lines = doc.split(b"\n")
    offsets = []
    pos = 0
    for line in lines:
        offsets.append(pos)
        pos += len(line) + 1
    in_fence = False
    sec_start = sec_end = None
    heading = ""
    last_named = None
    blocks = []
    cur = None
    for i, line in enumerate(lines):
        if not in_fence:
            if line.startswith(b"## 17."):
                sec_start = i
            elif line.startswith(b"## 18.") and sec_start is not None and sec_end is None:
                sec_end = i
                break
            if sec_start is None:
                continue
            m = re.match(rb"^### (17\.\d+) (.*)$", line)
            if m:
                heading = m.group(1).decode()
                first_tick = re.search(rb"`([^`]+)`", m.group(2))
                last_named = first_tick.group(1).decode() if first_tick else None
                continue
            m = re.match(rb"^`([A-Za-z0-9_./]+\.gd)`", line)
            if m:
                last_named = m.group(1).decode()
                continue
            if line == FENCE_OPEN:
                in_fence = True
                cur = {"heading": heading, "named": last_named, "first_line": i + 1}
                continue
            if line.startswith(b"```"):
                in_fence = True
                cur = None
                print("NOTE: non-gdscript fence in section 17 at line %d: %r" % (i + 1, line))
                continue
        else:
            if line == FENCE:
                in_fence = False
                if cur is not None:
                    cur["last_line"] = i
                    cur["start"] = offsets[cur["first_line"]]
                    cur["end"] = offsets[i] - 1
                    cur["content"] = doc[cur["start"]:cur["end"]]
                    blocks.append(cur)
                    cur = None
    return blocks, (sec_start, sec_end)


def resolve_path(block):
    h = block["heading"]
    named = block["named"] or ""
    if h == "17.5":
        return "data/types/" + named
    if h == "17.13":
        return "tests/" + named
    return named


def expected_bytes(root, rel):
    with open(root + "/" + rel, "rb") as f:
        data = f.read()
    if not data.endswith(b"\n") or data.endswith(b"\n\n"):
        raise SystemExit("%s does not end with exactly one newline" % rel)
    return data[:-1]


def insert_after_last_block(doc, heading, text):
    blocks, _ = parse_blocks(doc)
    last = [b for b in blocks if b["heading"] == heading]
    if not last:
        raise SystemExit("no block under heading %s" % heading)
    at = last[-1]["end"] + len(b"\n```")
    return doc[:at] + text + doc[at:]


def main():
    args = sys.argv[1:]
    if not args:
        raise SystemExit(__doc__)
    root = args[0]
    rest = args[1:]
    doc_path = root + "/docs/ARCHITECTURE.md"
    with open(doc_path, "rb") as f:
        doc = f.read()
    if b"\r" in doc:
        print("WARNING: ARCHITECTURE.md contains CR bytes (%d)" % doc.count(b"\r"))

    if rest[:1] == ["--add-types"]:
        known = {resolve_path(b) for b in parse_blocks(doc)[0]}
        for rel in rest[1:]:
            if rel in known:
                print("already has a block:", rel)
                continue
            name = rel.rsplit("/", 1)[1]
            text = b"\n\n`" + name.encode() + b"`:\n\n```gdscript\n" + expected_bytes(root, rel) + b"\n```"
            doc = insert_after_last_block(doc, "17.5", text)
            print("added", rel, "to 17.5")
        with open(doc_path, "wb") as f:
            f.write(doc)
        return

    if rest[:1] == ["--add-section"]:
        title = rest[1]
        known = {resolve_path(b) for b in parse_blocks(doc)[0]}
        parts = [b"\n\n### " + title.encode()]
        for rel in rest[2:]:
            if rel in known:
                print("already has a block:", rel)
                continue
            parts.append(b"\n\n`" + rel.encode() + b"`:\n\n```gdscript\n" + expected_bytes(root, rel) + b"\n```")
            print("added", rel)
        blocks, _ = parse_blocks(doc)
        at = blocks[-1]["end"] + len(b"\n```")
        doc = doc[:at] + b"".join(parts) + doc[at:]
        with open(doc_path, "wb") as f:
            f.write(doc)
        return

    fix = None
    if rest[:1] == ["--fix"]:
        fix = rest[1:]
    blocks, span = parse_blocks(doc)
    print("section 17 spans lines %d..%d (1-based); %d gdscript blocks" % (span[0] + 1, span[1], len(blocks)))
    bad = 0
    out = doc
    for block in sorted(blocks, key=lambda b: -b["start"]):
        rel = resolve_path(block)
        want = expected_bytes(root, rel)
        same = want == block["content"]
        status = "OK  " if same else "DIFF"
        if not same:
            bad += 1
            if fix is not None and (not fix or rel in fix):
                out = out[:block["start"]] + want + out[block["end"]:]
                status = "FIXED"
                bad -= 1
        if status != "OK  " or "-v" in rest:
            print("%-5s %-6s %s" % (status, block["heading"], rel))
    if out != doc:
        with open(doc_path, "wb") as f:
            f.write(out)
        print("wrote ARCHITECTURE.md")
    print("RESULT blocks=%d differing=%d" % (len(blocks), bad))
    sys.exit(1 if bad else 0)


main()
