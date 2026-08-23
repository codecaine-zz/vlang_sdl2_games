#!/usr/bin/env python3
"""Batch generate screenshots for all 91 games in parallel."""
from __future__ import annotations

import concurrent.futures
import os
import subprocess
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent
SCREENSHOTS_DIR = ROOT / "screenshots"
SCREENSHOTS_DIR.mkdir(exist_ok=True)


def capture_game(game: str) -> tuple[str, bool, str]:
    game_dir = ROOT / game
    env = os.environ.copy()
    env["SNAPSHOT"] = "1"
    cmd = ["v", "run", str(game_dir), "--snap"]
    try:
        res = subprocess.run(
            cmd,
            cwd=str(ROOT),
            env=env,
            capture_output=True,
            text=True,
            timeout=30,
        )
        if res.returncode == 0:
            # Check for generated BMPs and convert to PNG
            for bmp_file in SCREENSHOTS_DIR.glob(f"{game}*.bmp"):
                png_file = bmp_file.with_suffix(".png")
                try:
                    with Image.open(bmp_file) as im:
                        im.save(png_file)
                except Exception as e:
                    pass
            return game, True, "OK"
        else:
            return game, False, res.stderr or res.stdout
    except Exception as e:
        return game, False, str(e)


def main() -> None:
    games = sorted([
        d.name for d in ROOT.iterdir()
        if d.is_dir() and (d / "main.v").exists() and not d.name.startswith(".")
    ])
    print(f"Starting batch snapshot generation for {len(games)} games...")

    success_count = 0
    fail_count = 0

    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as executor:
        futures = {executor.submit(capture_game, g): g for g in games}
        for future in concurrent.futures.as_completed(futures):
            game, success, msg = future.result()
            if success:
                success_count += 1
                print(f"[✓] {game}")
            else:
                fail_count += 1
                print(f"[✗] {game}: {msg[:120]}")

    all_pngs = list(SCREENSHOTS_DIR.glob("*.png"))
    all_bmps = list(SCREENSHOTS_DIR.glob("*.bmp"))
    print(f"\nCompleted! Generated {len(all_pngs)} PNGs and {len(all_bmps)} BMPs in screenshots/")


if __name__ == "__main__":
    main()
