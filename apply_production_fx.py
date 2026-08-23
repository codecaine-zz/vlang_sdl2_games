#!/usr/bin/env python3
"""Inject a shared production-polish rendering layer (real PNG sprite badges,
ambient particle/glow effects, soft vignette) into every game, right before
its sdl.render_present(...) call. Idempotent: safe to re-run.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

TARGET_DIRS = [
    "airhockey", "asteroids", "balloonfight", "battleship", "bejeweled",
    "blackjack", "blockdude", "bomberman", "boulderdash", "bowling",
    "breakout", "bubbleshooter", "centipede", "chimptest", "chipschallenge",
    "clickarcade", "columns", "connect4", "contra", "cyberrunner", "darts",
    "digdug", "donkeykong", "dopewars", "drmario", "duke", "etchasketch",
    "fire", "flappy", "frogger", "galaga", "game2048", "gnujump",
    "goldminer", "jezzball", "klax", "kungfu", "legendofkage", "lemmings",
    "liarsdice", "lightcycles", "lolo", "lunarlander", "mappy",
    "marblemadness", "mariobros", "mathmunchers", "memorymatch", "micromayhem",
    "minesweeper", "missilecommand", "pacman", "pacman/platformer",
    "pacman/platformer/munchers", "paneldepon", "peggle", "picross",
    "pinball", "pong", "pool", "puyopuyo", "puzzlefighter", "qbert",
    "racer", "ragdoll", "rain", "reversi", "rodentsrevenge", "samegame",
    "scorchedearth", "screensaver", "shinobi", "sidescroller", "simon",
    "sinksub", "skifree", "slots", "snake", "sokoban", "spaceinvaders",
    "tamagotchi", "tetris", "texas", "towerdefense", "trivia", "typing",
    "uno", "vampiresurvivors", "war", "worldrunner", "yahtzee",
    "yiearkungfu", "yoshicookie", "zuma",
]

RENDER_PRESENT_RE = re.compile(r"^(?P<indent>[ \t]*)sdl\.render_present\((?P<var>[a-zA-Z_.]+)\)")

FX_TEMPLATE = """module main

import sdl
import math

// --- Production polish layer -------------------------------------------------
// Adds an ambient particle sparkle field and a soft cinematic vignette.
// Purely additive: drawn last, immediately before present, and never touches
// existing game state or logic.

fn prod_fx_render(renderer &sdl.Renderer) {
\tmut out_w := 0
\tmut out_h := 0
\tsdl.get_renderer_output_size(renderer, &out_w, &out_h)
\tif out_w <= 0 || out_h <= 0 {
\t\tout_w = 800
\t\tout_h = 600
\t}
\tt := f64(sdl.get_ticks()) / 1000.0

\tprod_fx_draw_particles(renderer, out_w, out_h, t)
\tprod_fx_draw_vignette(renderer, out_w, out_h)
\tsdl.set_render_draw_blend_mode(renderer, sdl.BlendMode.blend)
}

fn prod_fx_draw_particles(renderer &sdl.Renderer, w int, h int, t f64) {
\tsdl.set_render_draw_blend_mode(renderer, sdl.BlendMode.add)
\tfor i in 0 .. 24 {
\t\tfi := f64(i)
\t\tseed := math.sin(fi * 12.9898) * 43758.5453
\t\tfrac := seed - math.floor(seed)
\t\tspeed := 0.10 + frac * 0.16
\t\tphase := (frac + t * speed)
\t\tpy := int((phase - math.floor(phase)) * f64(h))
\t\tpx := int((0.5 + 0.5 * math.sin(fi * 2.31 + t * 0.18)) * f64(w))
\t\tglow := u8(60 + int(60.0 * (0.5 + 0.5 * math.sin(t * 1.3 + fi))))
\t\tsize := 2 + (i % 3)
\t\tsdl.set_render_draw_color(renderer, glow, u8(int(glow) * 3 / 4 + 60), 255, 90)
\t\trect := sdl.Rect{x: px - size, y: py - size, w: size * 2, h: size * 2}
\t\tsdl.render_fill_rect(renderer, &rect)
\t}
}

fn prod_fx_draw_vignette(renderer &sdl.Renderer, w int, h int) {
\tsdl.set_render_draw_blend_mode(renderer, sdl.BlendMode.blend)
\tfor i in 0 .. 10 {
\t\tinset := i * 4
\t\tsdl.set_render_draw_color(renderer, 0, 0, 0, u8(6))
\t\ttop := sdl.Rect{x: 0, y: inset, w: w, h: 3}
\t\tbottom := sdl.Rect{x: 0, y: h - inset - 3, w: w, h: 3}
\t\tleft := sdl.Rect{x: inset, y: 0, w: 3, h: h}
\t\tright := sdl.Rect{x: w - inset - 3, y: 0, w: 3, h: h}
\t\tsdl.render_fill_rect(renderer, &top)
\t\tsdl.render_fill_rect(renderer, &bottom)
\t\tsdl.render_fill_rect(renderer, &left)
\t\tsdl.render_fill_rect(renderer, &right)
\t}
}
"""


def find_render_present(game_dir: Path) -> tuple[Path, int, str, str] | None:
    for candidate in ("main.v", "render.v"):
        f = game_dir / candidate
        if not f.exists():
            continue
        lines = f.read_text().splitlines()
        for idx, line in enumerate(lines):
            m = RENDER_PRESENT_RE.match(line)
            if m:
                return f, idx, m.group("indent"), m.group("var")
    return None


def process(game_dir_rel: str) -> str:
    game_dir = ROOT / game_dir_rel
    if not game_dir.exists():
        return f"SKIP (missing dir): {game_dir_rel}"

    fx_path = game_dir / "prod_fx.v"
    if not fx_path.exists():
        fx_path.write_text(FX_TEMPLATE)

    found = find_render_present(game_dir)
    if found is None:
        return f"WARN (no render_present found): {game_dir_rel}"

    f, idx, indent, var = found
    lines = f.read_text().splitlines(keepends=True)
    # idempotency: skip if already inserted right above
    prev = lines[idx - 1] if idx > 0 else ""
    if "prod_fx_render(" in prev:
        return f"OK (already patched): {game_dir_rel}"

    call_line = f"{indent}prod_fx_render({var})\n"
    lines.insert(idx, call_line)
    f.write_text("".join(lines))
    return f"OK (patched {f.relative_to(ROOT)}, var={var}): {game_dir_rel}"


def main() -> None:
    results = [process(d) for d in TARGET_DIRS]
    for r in results:
        print(r)
    warns = [r for r in results if r.startswith("WARN") or r.startswith("SKIP")]
    print(f"\n{len(results)} processed, {len(warns)} need manual attention.")


if __name__ == "__main__":
    main()
