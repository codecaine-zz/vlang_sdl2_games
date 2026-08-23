#!/usr/bin/env python3
import os
import math
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent

def write_wav(filepath: Path, samples: list[int], sample_rate: int = 44100):
    filepath.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(filepath), 'wb') as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2) # 16-bit
        wav.setframerate(sample_rate)
        raw = b''.join(struct.pack('<h', max(-32768, min(32767, s))) for s in samples)
        wav.writeframes(raw)

def generate_square_wave(freq: float, duration: float, volume: float = 0.4, sweep: float = 0.0) -> list[int]:
    sr = 44100
    samples = []
    total = int(sr * duration)
    for i in range(total):
        t = i / sr
        f = freq * (1.0 + sweep * t)
        env = max(0.0, 1.0 - (t / duration))
        val = 1.0 if (math.sin(2.0 * math.pi * f * t) > 0) else -1.0
        sample = int(val * volume * 32767 * env)
        samples.append(sample)
    return samples

def generate_noise(duration: float, volume: float = 0.5) -> list[int]:
    import random
    sr = 44100
    samples = []
    total = int(sr * duration)
    for i in range(total):
        t = i / sr
        env = max(0.0, 1.0 - (t / duration))
        sample = int((random.random() * 2.0 - 1.0) * volume * 32767 * env)
        samples.append(sample)
    return samples

def write_bmp(filepath: Path, width: int, height: int, pixels: list[tuple[int, int, int]]):
    filepath.parent.mkdir(parents=True, exist_ok=True)
    row_bytes = width * 3
    padding = (4 - (row_bytes % 4)) % 4
    image_size = (row_bytes + padding) * height
    file_size = 54 + image_size

    # BMP Header
    header = struct.pack(
        '<2sIHHI',
        b'BM', file_size, 0, 0, 54
    )
    # DIB Header (BITMAPINFOHEADER)
    dib = struct.pack(
        '<IIIHHIIIIII',
        40, width, height, 1, 24, 0, image_size, 2835, 2835, 0, 0
    )

    data = bytearray()
    for y in range(height - 1, -1, -1): # BMP is bottom-to-top
        for x in range(width):
            r, g, b = pixels[y * width + x]
            data.extend([b, g, r]) # BGR order
        data.extend([0] * padding)

    with open(filepath, 'wb') as f:
        f.write(header)
        f.write(dib)
        f.write(data)

def generate_downwell_assets():
    dir_path = ROOT / 'downwell' / 'assets'
    sounds_dir = dir_path / 'sounds'
    sprites_dir = dir_path / 'sprites'

    # Sounds
    write_wav(sounds_dir / 'downwell_shoot.wav', generate_square_wave(600, 0.12, 0.5, sweep=-0.6))
    write_wav(sounds_dir / 'downwell_jump.wav', generate_square_wave(300, 0.15, 0.4, sweep=0.8))
    write_wav(sounds_dir / 'downwell_stomp.wav', generate_square_wave(180, 0.20, 0.6, sweep=-0.4))
    write_wav(sounds_dir / 'downwell_gem.wav', generate_square_wave(900, 0.10, 0.4, sweep=0.5))
    write_wav(sounds_dir / 'downwell_hit.wav', generate_noise(0.25, 0.6))

    # Spritesheet BMP (128x128 24-bit bitmap)
    w, h = 128, 128
    pixels = [(15, 12, 20)] * (w * h)
    
    # Draw player sprite in 32x32 quadrant
    for y in range(8, 26):
        for x in range(8, 24):
            pixels[y * w + x] = (255, 255, 255) # body white
    for y in range(22, 28):
        for x in range(8, 24):
            pixels[y * w + x] = (230, 40, 50) # gunboots red

    # Draw Gem in second quadrant (40, 8)
    for y in range(8, 24):
        for x in range(40, 56):
            pixels[y * w + x] = (255, 215, 0) # gold gem

    write_bmp(sprites_dir / 'downwell_sprites.bmp', w, h, pixels)
    print("Generated Downwell audio and sprite BMP assets!")

def generate_nuclearthrone_assets():
    dir_path = ROOT / 'nuclearthrone' / 'assets'
    sounds_dir = dir_path / 'sounds'
    sprites_dir = dir_path / 'sprites'

    # Sounds
    write_wav(sounds_dir / 'nuclearthrone_shoot.wav', generate_square_wave(450, 0.14, 0.5, sweep=-0.5))
    write_wav(sounds_dir / 'nuclearthrone_laser.wav', generate_square_wave(950, 0.20, 0.4, sweep=-0.8))
    write_wav(sounds_dir / 'nuclearthrone_explosion.wav', generate_noise(0.40, 0.7))
    write_wav(sounds_dir / 'nuclearthrone_rad.wav', generate_square_wave(800, 0.08, 0.35, sweep=0.6))
    write_wav(sounds_dir / 'nuclearthrone_hit.wav', generate_noise(0.20, 0.5))

    # Spritesheet BMP (128x128 24-bit bitmap)
    w, h = 128, 128
    pixels = [(28, 22, 18)] * (w * h)
    
    # Draw mutant character in 32x32 quadrant
    for y in range(6, 26):
        for x in range(6, 26):
            pixels[y * w + x] = (40, 200, 100) # Mutant green

    # Draw Bandit Enemy in (40, 6)
    for y in range(6, 26):
        for x in range(40, 60):
            pixels[y * w + x] = (220, 100, 40) # Bandit orange

    write_bmp(sprites_dir / 'nuclearthrone_sprites.bmp', w, h, pixels)
    print("Generated Nuclear Throne audio and sprite BMP assets!")

if __name__ == '__main__':
    generate_downwell_assets()
    generate_nuclearthrone_assets()
