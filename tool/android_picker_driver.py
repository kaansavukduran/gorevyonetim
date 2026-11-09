#!/usr/bin/env python3
"""Drive only Android DocumentsUI for the Flutter native backup acceptance test.

Standard library + SDK adb/UIAutomator; run on the disposable CI emulator.
The app publishes a run-scoped marker via its debuggable private files area.
XML and screenshots of each observed picker are retained as CI evidence.
"""
import argparse
import json
import re
import subprocess
import time
import xml.etree.ElementTree as ET
from pathlib import Path

APP = "com.gunlukgorevler.gunluk_gorevler"
PICKERS = {"com.android.documentsui", "com.google.android.documentsui"}


def center(bounds):
    match = re.fullmatch(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", bounds)
    if not match:
        return None
    left, top, right, bottom = map(int, match.groups())
    if right <= left or bottom <= top:
        return None
    return (left + right) // 2, (top + bottom) // 2


def picker_action(xml, step, name=None):
    """Return a safe observed target, never tap an app or keyboard control."""
    nodes = list(ET.fromstring(xml).iter("node"))
    nodes = [n for n in nodes if n.get("package") in PICKERS]
    if not nodes:
        return None
    if step.endswith("-cancel"):
        return "back"
    for node in nodes:
        if node.get("enabled") == "false":
            continue
        text = node.get("text", "")
        resource = node.get("resource-id", "")
        if step == "export":
            matches = (
                resource.endswith("/action_menu_save")
                or (resource == "android:id/button1" and text.upper() in {"SAVE", "KAYDET"})
            )
        else:
            matches = text == name and resource.endswith("/title")
        if matches:
            target = center(node.get("bounds", ""))
            if target:
                return target
    return None


def guarded_picker_action(xml, expected, latest, acted):
    # UIAutomator may take seconds. Flutter can advance to the next native
    # request while a dump is in flight, so never act on an old phase snapshot.
    if any(expected.get(k) != latest.get(k) for k in ("runId", "requestId", "step")):
        return None
    if expected["requestId"] in acted and not expected["step"].endswith("-cancel"):
        return None
    return picker_action(xml, expected["step"], expected.get("fileName"))


class Driver:
    def __init__(self, serial, out, run_id):
        self.serial, self.out, self.run_id = serial, out, run_id
        self.out.mkdir(parents=True, exist_ok=True)

    def adb(self, *args, check=True, binary=False):
        result = subprocess.run(
            ["adb", "-s", self.serial, *args], capture_output=True, timeout=25,
        )
        if check and result.returncode:
            raise RuntimeError(
                f"adb {args!r} exited {result.returncode}: "
                f"{result.stdout.decode('utf-8', errors='replace')} "
                f"{result.stderr.decode('utf-8', errors='replace')}"
            )
        return result.stdout if binary else result.stdout.decode("utf-8", errors="replace")

    def xml(self):
        self.adb("shell", "rm", "-f", "/sdcard/picker-e2e.xml")
        self.adb("shell", "uiautomator", "dump", "/sdcard/picker-e2e.xml", check=False)
        text = self.adb("exec-out", "cat", "/sdcard/picker-e2e.xml", check=False)
        if not text.startswith("<?xml"):
            return None
        try:
            ET.fromstring(text)
        except ET.ParseError:
            return None
        return text

    def evidence(self, label, xml):
        (self.out / f"{label}.xml").write_text(xml, encoding="utf-8")
        (self.out / f"{label}.png").write_bytes(self.adb("exec-out", "screencap", "-p", binary=True))

    def marker(self):
        raw = self.adb("shell", "run-as", APP, "cat", "files/picker-e2e-control.json", check=False)
        try:
            return json.loads(raw)
        except (json.JSONDecodeError, TypeError):
            return {}

    def prepare_fixtures(self):
        # The app marker proves installation/startup finished. A newly booted
        # emulator can report boot_complete before shared storage is writable.
        for name, content in {
            "gunluk-gorevler-gecersiz.json": b"{bozuk json",
            "gunluk-gorevler-bozuk-utf8.json": b"\xff\xfe\x80",
        }.items():
            fixture = self.out / name
            fixture.write_bytes(content)
            for attempt in range(15):
                try:
                    self.adb("shell", "mkdir", "-p", "/sdcard/Download")
                    self.adb("push", str(fixture), f"/sdcard/Download/{name}")
                    break
                except RuntimeError as error:
                    print(f"Downloads readiness attempt {attempt + 1}: {error}", flush=True)
                    if attempt == 14:
                        raise
                    time.sleep(2)

    def run(self):
        self.adb("wait-for-device")
        deadline, last_request, phase_start = time.monotonic() + 900, None, None
        saved_evidence, last_tap = set(), 0
        acted = set()
        exported, fixtures_ready = None, False
        while time.monotonic() < deadline:
            marker = self.marker()
            if marker.get("runId") != self.run_id:
                time.sleep(1)
                continue
            if not fixtures_ready:
                self.prepare_fixtures()
                fixtures_ready = True
            request_id, step = marker["requestId"], marker["step"]
            if request_id != last_request:
                print(f"Picker phase {request_id}: {step} {marker.get('fileName') or ''}", flush=True)
                last_request, phase_start = request_id, time.monotonic()
            if step == "done":
                if not marker.get("allPassed"):
                    raise RuntimeError("Flutter native picker assertions failed")
                if not exported:
                    raise RuntimeError("No native export was requested")
                data = json.loads(self.adb("exec-out", "cat", f"/sdcard/Download/{exported}"))
                assert data["tasks"][0]["title"] == "Türkçe görev: ışık, çiçek, öğün"
                assert data["tasks"][0]["time"] == "23:45"
                assert len(data["completions"]) == 1
                assert data["step_ticks"]
                (self.out / "result.json").write_text(json.dumps({
                    "allPassed": True, "phases": request_id - 1,
                    "turkishUtf8": True, "timeNotesStepsTicksRoundtrip": True,
                }, indent=2), encoding="utf-8")
                print("PASS: native export/import, two cancellations, invalid JSON and UTF-8; current data preserved", flush=True)
                return
            xml = self.xml()
            if xml:
                action = guarded_picker_action(xml, marker, self.marker(), acted)
                label = f"{request_id}-{step}"
                if action and label not in saved_evidence:
                    self.evidence(label, xml)
                    saved_evidence.add(label)
                if action and time.monotonic() - last_tap > 2:
                    action = guarded_picker_action(xml, marker, self.marker(), acted)
                    if action is None:
                        continue
                    if step == "export":
                        exported = marker["fileName"]
                    if action == "back":
                        self.adb("shell", "input", "keyevent", "4")
                    else:
                        self.adb("shell", "input", "tap", str(action[0]), str(action[1]))
                    acted.add(request_id)
                    last_tap = time.monotonic()
            if time.monotonic() - phase_start > 65:
                if xml:
                    self.evidence(f"{request_id}-{step}-timeout", xml)
                raise RuntimeError(f"Picker phase timed out: {step}")
            time.sleep(0.5)
        raise TimeoutError("Flutter did not finish the native picker acceptance run")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--serial", default="emulator-5554")
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--run-id", required=True)
    args = parser.parse_args()
    Driver(args.serial, args.out, args.run_id).run()
