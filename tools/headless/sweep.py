"""Run the balancing harness over several configurations at once and compare them (DECISIONS A56, STEP-14 task 5).

Each configuration is a set of overrides for the harness's `set=` argument (HarnessRunner.apply_overrides), so nothing in
the repo changes while you explore. The tool prepares one project copy per worker (the same copy logic as run_tests.sh),
runs the configurations in parallel across them and prints one table row each.

usage (from the repo root; `python` on Windows, `python3` on the Mac):
  python tools/headless/sweep.py --seeds 1000 --bot planner "base=" "slack=ticket_deadline_mult:1.3" "calm=low_runway_burnout:0.15"
  python tools/headless/sweep.py --seeds 2000 --bot planner --file configs.txt          (one "name=overrides" per line)
Options: --bot (default planner), --seeds, --first, --run (1 or 2), --bg, --handbook none|full, --workers (default 7),
--json FILE (write every report). A bare "name=" means no overrides (the shipped data).
"""
import argparse
import json
import os
import queue
import shutil
import subprocess
import sys
import tempfile
import threading
import time

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GODOT_CANDIDATES = [
    "C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe",
    "/Applications/Godot.app/Contents/MacOS/Godot",
]


def godot_path():
    if os.environ.get("GODOT"):
        return os.environ["GODOT"]
    for c in GODOT_CANDIDATES:
        if os.path.exists(c):
            return c
    return "godot"


COPY_DIRS = ["addons", "autoload", "core", "data", "features", "tests", "ui", "art", "audio"]


def prepare(copy_dir):
    """Copy the game folders into copy_dir (never into the repo) and build its import cache, like lib.sh does."""
    os.makedirs(copy_dir, exist_ok=True)
    for d in COPY_DIRS:
        dst = os.path.join(copy_dir, d)
        if os.path.exists(dst):
            shutil.rmtree(dst)
        src = os.path.join(REPO, d)
        if os.path.isdir(src):
            shutil.copytree(src, dst)
    shutil.copy(os.path.join(REPO, "project.godot"), os.path.join(copy_dir, "project.godot"))
    subprocess.run([godot_path(), "--headless", "--path", copy_dir, "--import"], capture_output=True, text=True, errors="replace")
    if not os.path.exists(os.path.join(copy_dir, ".godot")):
        raise SystemExit("importing %s did not build a .godot cache" % copy_dir)


def run_one(copy_dir, args, name, overrides):
    cmd = [godot_path(), "--headless", "--path", copy_dir, "--script", "res://tests/harness/run_harness.gd", "--",
           "bot=%s" % args.bot, "seeds=%d" % args.seeds, "first=%d" % args.first, "run=%d" % args.run, "bg=%s" % args.bg,
           "handbook=%s" % args.handbook]
    if overrides:
        cmd.append("set=%s" % overrides)
    started = time.time()
    r = subprocess.run(cmd, capture_output=True, text=True, errors="replace")
    report = None
    problems = []
    for line in r.stdout.splitlines():
        if line.startswith("REPORT "):
            report = json.loads(line[7:])
        elif line.startswith("OVERRIDE_PROBLEM"):
            problems.append(line)
    return {"name": name, "overrides": overrides, "report": report, "problems": problems, "seconds": time.time() - started,
            "raw_tail": r.stdout[-400:] if report is None else ""}


def row(res):
    r = res["report"]
    if r is None:
        return "%-22s NO REPORT %s" % (res["name"], res["raw_tail"].replace("\n", " | ")[:200])
    st = r["stats_per_run"]
    ends = r["endings"]
    n = max(1, r["runs"])
    mix = " ".join("%s:%d%%" % (k[:5], round(100.0 * v / n)) for k, v in sorted(ends.items(), key=lambda kv: -kv[1]))
    ivs = st.get("interviews", 0.0)
    pass_rate = 100.0 * (1.0 - st.get("interviews_failed", 0.0) / ivs) if ivs else 0.0
    return "%-22s win %5.1f%%  med %5d  medloss %5d  early %3.0f%%  jobs %.2f  mid1 %3.0f%%  promo %.2f  rev(b/m) %.1f/%.1f  intv %.1f pass %2.0f%%  ofr %.2f  %s%s" % (
        res["name"], 100.0 * r["win_rate"], r["median_day"], r["median_loss_day"], 100.0 * r.get("early_loss_share", 0.0), r["jobs_mean"], 100.0 * r["mid_in_job1_share"],
        st.get("promotions", 0.0), st.get("rating_below", 0.0), st.get("rating_meets", 0.0) + st.get("rating_exceeds", 0.0),
        ivs, pass_rate, st.get("offers", 0.0), mix, "  PROBLEMS " + "; ".join(res["problems"]) if res["problems"] else "")


def run_jobs(args, jobs, quiet=False):
    """Run [(name, overrides), ...] across worker copies; returns the result dicts (also printed unless quiet)."""
    workers = max(1, min(args.workers, len(jobs)))
    base = os.path.join(tempfile.gettempdir(), "swe-sweep").replace("\\", "/")
    copies = ["%s-w%d" % (base, i) for i in range(workers)]
    if not getattr(args, "_prepared", False) or getattr(args, "_prepared_n", 0) < workers:
        if not quiet:
            print("preparing %d project copies..." % workers, flush=True)
        threads = [threading.Thread(target=prepare, args=(c,)) for c in copies]
        for t in threads:
            t.start()
        for t in threads:
            t.join()
        args._prepared = True
        args._prepared_n = workers
    q = queue.Queue()
    for j in jobs:
        q.put(j)
    results = []
    lock = threading.Lock()

    def worker(copy_dir):
        while True:
            try:
                name, overrides = q.get_nowait()
            except queue.Empty:
                return
            res = run_one(copy_dir, args, name, overrides)
            with lock:
                results.append(res)
                if not quiet:
                    print(row(res), flush=True)

    threads = [threading.Thread(target=worker, args=(c,)) for c in copies]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    return results


def make_parser():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("configs", nargs="*", help='"name=overrides" (a bare "name=" is the shipped data)')
    ap.add_argument("--file")
    ap.add_argument("--bot", default="planner")
    ap.add_argument("--seeds", type=int, default=1000)
    ap.add_argument("--first", type=int, default=1)
    ap.add_argument("--run", type=int, default=1)
    ap.add_argument("--bg", default="intern")
    ap.add_argument("--handbook", default="none")
    ap.add_argument("--workers", type=int, default=7)
    ap.add_argument("--json")
    return ap


def main():
    args = make_parser().parse_args()
    lines = list(args.configs)
    if args.file:
        lines += [l.strip() for l in open(args.file, encoding="utf-8") if l.strip() and not l.startswith("#")]
    jobs = []
    for line in lines:
        name, _, overrides = line.partition("=")
        jobs.append((name.strip() or "base", overrides.strip()))
    if not jobs:
        raise SystemExit("no configurations given")
    t0 = time.time()
    results = run_jobs(args, jobs)
    print("done in %.0f s (%d configs, %d seeds each)" % (time.time() - t0, len(jobs), args.seeds))
    if args.json:
        with open(args.json, "w", encoding="utf-8") as f:
            json.dump(results, f, indent=1)


if __name__ == "__main__":
    main()
