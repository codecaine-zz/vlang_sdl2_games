#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import math
import os
import struct
import wave
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent
IGNORED = {"assets", "screenshots", ".git", ".vscode", "__pycache__"}


def stable_index(name: str, offset: int = 0) -> int:
    digest = hashlib.sha1(name.lower().encode("utf-8")).hexdigest()
    return int(digest[offset:offset + 8], 16) % 1000


def palette_for(name: str):
    idx = stable_index(name, 0)
    base = [
        (32, 48, 96),
        (160, 36, 72),
        (18, 136, 110),
        (204, 118, 28),
        (92, 77, 179),
        (20, 142, 197),
        (126, 58, 35),
        (75, 124, 49),
        (216, 84, 82),
        (61, 35, 86),
    ]
    accent = [
        (255, 210, 94),
        (140, 238, 255),
        (185, 255, 168),
        (255, 174, 204),
        (196, 180, 255),
        (225, 255, 240),
    ]
    return base[idx % len(base)], accent[idx % len(accent)]


def draw_game_badge(draw: ImageDraw.ImageDraw, width: int, height: int, title: str, primary: tuple[int, int, int], accent: tuple[int, int, int]) -> None:
    cx, cy = width // 2, height // 2
    pad = 20
    draw.rounded_rectangle((pad, pad, width - pad, height - pad), radius=32, fill=(primary[0], primary[1], primary[2], 195), outline=(accent[0], accent[1], accent[2], 255), width=6)
    draw.ellipse((40, 40, width - 40, height - 40), outline=(accent[0], accent[1], accent[2], 170), width=4)
    draw.rectangle((70, 90, width - 70, height - 90), fill=(0, 0, 0, 30), outline=(255, 255, 255, 80), width=2)

    left = 112
    right = width - 112
    top = 95
    bottom = height - 100
    draw.rounded_rectangle((left, top, right, bottom), radius=18, fill=(0, 0, 0, 40), outline=(255, 255, 255, 110), width=2)

    # central glyph / emblem
    for offset in range(0, 20, 4):
        alpha = int(100 + offset * 4)
        draw.ellipse((cx - 120 + offset, cy - 84 + offset, cx + 120 - offset, cy + 84 - offset), outline=(accent[0], accent[1], accent[2], alpha), width=3)

    draw.polygon([
        (cx, cy - 84),
        (cx + 96, cy),
        (cx, cy + 84),
        (cx - 96, cy),
    ], fill=(255, 255, 255, 175), outline=(accent[0], accent[1], accent[2], 255), width=4)

    # decorative motion bars
    for i in range(5):
        x = 90 + i * 60
        y = 116 + (i % 2) * 10
        draw.rounded_rectangle((x, y, x + 36, y + 8), radius=4, fill=(accent[0], accent[1], accent[2], 160))

    # title text is intentionally light/large and alpha-friendly
    title_text = title[:18]
    margin = 24
    txt = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    tdraw = ImageDraw.Draw(txt)
    font_size = 22 if len(title_text) < 12 else 16
    try:
        font = ImageFont.truetype('/System/Library/Fonts/Arial.ttc', font_size)
    except Exception:
        font = None
    if font is not None:
        tw, th = tdraw.textbbox((0, 0), title_text, font=font)[2:4]
        tdraw.text(((width - tw) / 2, height - 70), title_text, fill=(255, 255, 255, 220), font=font)
    else:
        tdraw.text((margin, height - 72), title_text, fill=(255, 255, 255, 220))
    draw.bitmap((0, 0), txt)


def generate_sprite_png(path: Path, title: str) -> None:
    primary, accent = palette_for(title)
    width, height = 512, 512
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # base glow / bevel
    glow = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse((26, 26, width - 26, height - 26), fill=(*primary, 120), outline=(accent[0], accent[1], accent[2], 210), width=10)
    img = Image.alpha_composite(img, glow)
    draw = ImageDraw.Draw(img)

    # central sprite motif based on title hash
    shape_seed = stable_index(title, 4)
    if shape_seed % 4 == 0:
        draw.rounded_rectangle((130, 150, 382, 360), radius=42, fill=(accent[0], accent[1], accent[2], 210), outline=(255, 255, 255, 255), width=6)
        draw.rectangle((190, 112, 322, 172), fill=(255, 255, 255, 180), outline=(255, 255, 255, 255), width=3)
        draw.polygon([(256, 105), (356, 256), (256, 407), (156, 256)], fill=(primary[0], primary[1], primary[2], 200), outline=(255, 255, 255, 220), width=5)
    elif shape_seed % 4 == 1:
        draw.ellipse((120, 110, 392, 390), fill=(accent[0], accent[1], accent[2], 210), outline=(255, 255, 255, 255), width=6)
        draw.line((120, 256, 392, 256), fill=(255, 255, 255, 255), width=6)
        draw.line((256, 110, 256, 390), fill=(255, 255, 255, 255), width=6)
        draw.arc((166, 156, 346, 336), 0, 360, fill=(primary[0], primary[1], primary[2], 220), width=12)
    elif shape_seed % 4 == 2:
        draw.rounded_rectangle((120, 120, 392, 390), radius=34, fill=(primary[0], primary[1], primary[2], 210), outline=(255, 255, 255, 255), width=6)
        draw.rectangle((172, 172, 340, 340), fill=(accent[0], accent[1], accent[2], 200), outline=(255, 255, 255, 220), width=5)
        draw.line((120, 120, 392, 390), fill=(255, 255, 255, 220), width=6)
        draw.line((392, 120, 120, 390), fill=(255, 255, 255, 220), width=6)
    else:
        draw.polygon([(116, 330), (210, 120), (300, 120), (396, 330), (256, 410)], fill=(primary[0], primary[1], primary[2], 220), outline=(255, 255, 255, 240), width=6)
        draw.rectangle((180, 160, 332, 270), fill=(accent[0], accent[1], accent[2], 210), outline=(255, 255, 255, 240), width=5)
        draw.arc((168, 180, 344, 356), 0, 180, fill=(255, 255, 255, 230), width=8)

    # add subtle particle details
    for i in range(20):
        px = int((i * 37 + stable_index(title, 2)) % (width - 90)) + 42
        py = int((i * 47 + stable_index(title, 6)) % (height - 90)) + 42
        r = 4 + (i % 5)
        draw.ellipse((px - r, py - r, px + r, py + r), fill=(255, 255, 255, 90))

    draw_game_badge(draw, width, height, title, primary, accent)

    # Apply slight alpha blur to mimic a transparent sprite sheet overlay.
    img = img.filter(ImageFilter.GaussianBlur(0.5))
    img.save(path, format='PNG')


def wav_write(path: Path, samples: list[int]) -> None:
    with wave.open(str(path), 'wb') as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(22050)
        raw = b''.join(struct.pack('<h', s) for s in samples)
        wav.writeframes(raw)


def synth_tone(freq: float, duration: float, volume: float = 0.4, sweep: float = 0.0) -> list[int]:
    sr = 22050
    samples = []
    total = int(sr * duration)
    for i in range(total):
        t = i / sr
        f = freq * (1.0 + sweep * t)
        envelope = min(1.0, t / 0.04) * max(0.0, 1.0 - (t / duration))
        signal = math.sin(2.0 * math.pi * f * t)
        amp = int(max(-32767, min(32767, signal * volume * 32767 * envelope)))
        samples.append(amp)
    return samples


def generate_sound_fx(folder: Path, title: str) -> None:
    base = stable_index(title, 8) % 200 + 200
    impact = synth_tone(90 + base * 0.15, 0.26, 0.52, sweep=0.4) + synth_tone(110 + base * 0.12, 0.18, 0.36, sweep=0.25)
    laser = synth_tone(520 + (base % 180), 0.12, 0.35, sweep=0.9)
    powerup = synth_tone(220 + (base % 90), 0.18, 0.45, sweep=0.25) + synth_tone(420 + (base % 150), 0.22, 0.38, sweep=0.35)

    wav_write(folder / 'impact.wav', impact)
    wav_write(folder / 'laser.wav', laser)
    wav_write(folder / 'powerup.wav', powerup)


def process_game_dir(game_dir: Path) -> bool:
    if not game_dir.is_dir() or game_dir.name in IGNORED:
        return False
    if game_dir.name.startswith('.'):
        return False

    assets_dir = game_dir / 'assets'
    assets_dir.mkdir(exist_ok=True)
    sprites_dir = assets_dir / 'sprites'
    sounds_dir = assets_dir / 'sounds'
    sprites_dir.mkdir(exist_ok=True)
    sounds_dir.mkdir(exist_ok=True)

    png_path = sprites_dir / 'sprite_sheet.png'
    if not png_path.exists():
        generate_sprite_png(png_path, game_dir.name)

    char_png = sprites_dir / 'character.png'
    if not char_png.exists():
        generate_sprite_png(char_png, f"{game_dir.name}_hero")

    for name in ('impact.wav', 'laser.wav', 'powerup.wav'):
        p = sounds_dir / name
        if not p.exists():
            # equalize a lighter synthetic effect for missing FX files
            freq = 240 + stable_index(game_dir.name, 4) % 220
            if 'impact' in name:
                tone = synth_tone(freq, 0.15, 0.6, sweep=0.35)
            elif 'laser' in name:
                tone = synth_tone(freq * 2.5, 0.1, 0.5, sweep=1.0)
            else:
                tone = synth_tone(freq, 0.2, 0.4, sweep=0.2) + synth_tone(freq * 1.5, 0.18, 0.35, sweep=0.35)
            wav_write(p, tone)

    return True


def main() -> None:
    created = 0
    for item in sorted(ROOT.iterdir()):
        if item.is_dir() and item.name not in IGNORED:
            if process_game_dir(item):
                created += 1
    print(f'Generated per-game asset folders for {created} games.')


if __name__ == '__main__':
    try:
        from PIL import ImageFont
    except Exception:
        ImageFont = None
    main()
