"""Run only hook-free tests with synthetic data. Requires AutoHotkey v1 Unicode.

Usage: python tests/run-tests.py PATH_TO_AUTOHOTKEY [EXISTING_OUTPUT_PARENT]
No dependency beyond Python's standard library. No installed KMCounter is used.
"""
import configparser
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import time

runtime = Path(sys.argv[1]).resolve(strict=True)
parent = Path(sys.argv[2] if len(sys.argv) > 2 else tempfile.gettempdir()).resolve(strict=True)
output = Path(tempfile.mkdtemp(prefix="KMCounter-validation-", dir=parent))
tests = Path(__file__).resolve().parent
flags = getattr(subprocess, "CREATE_NO_WINDOW", 0)
report = {}
for name in ["CounterStore.tests.ahk", "RuntimePersistence.tests.ahk"]:
    result = subprocess.run([str(runtime), "/ErrorStdOut=UTF-8", str(tests / name), str(output)],
                            cwd=output, capture_output=True, timeout=35, creationflags=flags)
    log = (result.stdout + result.stderr).decode("utf-8-sig", errors="replace")
    (output / (name + ".log")).write_text(log, encoding="utf-8")
    report[name] = {"exit_code": result.returncode, "summary": next((line for line in log.splitlines() if line.startswith("PASS ALL")), "")}
    if result.returncode or not report[name]["summary"]:
        raise RuntimeError(log)

probe_dir = output / "lifecycle"
probe_dir.mkdir()
probe = tests / "RuntimeLifecycle.probe.ahk"
args = [str(runtime), "/ErrorStdOut=UTF-8", str(probe), str(probe_dir)]
process = subprocess.Popen(args + ["abrupt"], cwd=probe_dir, stdout=subprocess.PIPE, stderr=subprocess.PIPE, creationflags=flags)
try:
    deadline = time.monotonic() + 15
    while not (probe_dir / "ready.txt").exists() and process.poll() is None and time.monotonic() < deadline:
        time.sleep(0.05)
    if not (probe_dir / "ready.txt").exists():
        raise RuntimeError("Disposable lifecycle probe did not become ready")
finally:
    # Only terminate the exact child launched here, never enumerate processes
    # by executable name or touch the user's running counter.
    if process.poll() is None:
        process.terminate()
    process.communicate(timeout=5)

normal = subprocess.run(args + ["normal"], cwd=probe_dir, capture_output=True, timeout=15, creationflags=flags)
if normal.returncode != 7:
    raise RuntimeError((normal.stdout + normal.stderr).decode("utf-8", errors="replace"))
cfg = configparser.ConfigParser(interpolation=None)
cfg.read(probe_dir / "history.ini", encoding="utf-16")
log = (probe_dir / "KMCounter-runtime.log").read_text(encoding="utf-8-sig")
state = (probe_dir / "KMCounter-runtime.state").read_text(encoding="utf-8-sig")
report["lifecycle"] = {
    "saved_counter_survives_abrupt_exit": cfg["total"].getint("sc30") == 1,
    "unsaved_counter_not_fabricated": cfg["total"].getint("sc31", fallback=0) == 0,
    "normal_exit_flushes_latest_counter": cfg["total"].getint("sc32") == 1,
    "unclean_exit_logged_on_restart": "event=previous_session_unclean" in log,
    "exit_reason_and_code_logged": "event=exit_complete reason=Exit code=7 saved=1" in log,
    "clean_exit_state": state.startswith("clean_exit"),
    "only_probe_processes_exited": process.poll() is not None and normal.returncode == 7,
}
if not all(report["lifecycle"].values()):
    raise RuntimeError(report["lifecycle"])
(output / "results.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print(json.dumps({"output": str(output), "results": report}, indent=2))
