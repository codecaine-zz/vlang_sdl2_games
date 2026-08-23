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

def midi_to_freq(midi_note: int) -> float:
    return 440.0 * (2.0 ** ((midi_note - 69) / 12.0))

def generate_bgm_track(melody_pattern: list[tuple[int, float]], bass_pattern: list[tuple[int, float]], bpm: float = 130.0) -> list[int]:
    sr = 44100
    beat_dur = 60.0 / bpm
    total_beats = sum(d for _, d in melody_pattern)
    total_samples = int(sr * total_beats * beat_dur)
    buffer = [0.0] * total_samples

    # Synthesize melody
    cur_sample = 0
    for note, beats in melody_pattern:
        n_samples = int(sr * beats * beat_dur)
        if note > 0 and n_samples > 0:
            freq = midi_to_freq(note)
            for i in range(n_samples):
                if cur_sample + i >= total_samples:
                    break
                t = i / sr
                env = min(1.0, t / 0.02) * max(0.0, 1.0 - (t / (beats * beat_dur)))
                # Mixed pulse & triangle wave
                val = (1.0 if math.sin(2.0 * math.pi * freq * t) > 0.1 else -1.0) * 0.6 + math.sin(2.0 * math.pi * freq * t) * 0.4
                buffer[cur_sample + i] += val * 0.22 * env
        cur_sample += n_samples

    # Synthesize bass
    cur_sample = 0
    for note, beats in bass_pattern:
        n_samples = int(sr * beats * beat_dur)
        if note > 0 and n_samples > 0:
            freq = midi_to_freq(note)
            for i in range(n_samples):
                if cur_sample + i >= total_samples:
                    break
                t = i / sr
                env = min(1.0, t / 0.01) * max(0.0, 1.0 - (t / (beats * beat_dur)))
                val = 1.0 if math.sin(2.0 * math.pi * freq * t) > 0 else -1.0
                buffer[cur_sample + i] += val * 0.28 * env
        cur_sample += n_samples

    # Convert to 16-bit signed PCM
    pcm_out = []
    for s in buffer:
        sample_int = int(max(-32767.0, min(32767.0, s * 32767.0)))
        pcm_out.append(sample_int)

    return pcm_out

def write_bmp(filepath: Path, width: int, height: int, pixels: list[tuple[int, int, int]]):
    filepath.parent.mkdir(parents=True, exist_ok=True)
    row_bytes = width * 3
    padding = (4 - (row_bytes % 4)) % 4
    image_size = (row_bytes + padding) * height
    file_size = 54 + image_size

    header = struct.pack('<2sIHHI', b'BM', file_size, 0, 0, 54)
    dib = struct.pack('<IIIHHIIIIII', 40, width, height, 1, 24, 0, image_size, 2835, 2835, 0, 0)

    data = bytearray()
    for y in range(height - 1, -1, -1):
        for x in range(width):
            r, g, b = pixels[y * width + x]
            data.extend([b, g, r])
        data.extend([0] * padding)

    with open(filepath, 'wb') as f:
        f.write(header)
        f.write(dib)
        f.write(data)

def generate_downwell_assets():
    dir_path = ROOT / 'downwell' / 'assets'
    sounds_dir = dir_path / 'sounds'
    sprites_dir = dir_path / 'sprites'

    # Sound FX
    write_wav(sounds_dir / 'downwell_shoot.wav', generate_square_wave(600, 0.12, 0.5, sweep=-0.6))
    write_wav(sounds_dir / 'downwell_jump.wav', generate_square_wave(300, 0.15, 0.4, sweep=0.8))
    write_wav(sounds_dir / 'downwell_stomp.wav', generate_square_wave(180, 0.20, 0.6, sweep=-0.4))
    write_wav(sounds_dir / 'downwell_gem.wav', generate_square_wave(900, 0.10, 0.4, sweep=0.5))
    write_wav(sounds_dir / 'downwell_hit.wav', generate_noise(0.25, 0.6))

    # Fast-paced vertical descent chiptune BGM loop (140 BPM, Minor key arpeggios)
    downwell_melody = [
        (60, 0.5), (63, 0.5), (67, 0.5), (72, 0.5), (70, 0.5), (67, 0.5), (63, 0.5), (60, 0.5),
        (58, 0.5), (62, 0.5), (65, 0.5), (70, 0.5), (68, 0.5), (65, 0.5), (62, 0.5), (58, 0.5),
        (56, 0.5), (60, 0.5), (63, 0.5), (68, 0.5), (67, 0.5), (63, 0.5), (60, 0.5), (56, 0.5),
        (55, 0.5), (59, 0.5), (62, 0.5), (67, 0.5), (65, 0.5), (62, 0.5), (59, 0.5), (55, 0.5),
    ]
    downwell_bass = [
        (36, 1.0), (36, 1.0), (36, 1.0), (36, 1.0),
        (34, 1.0), (34, 1.0), (34, 1.0), (34, 1.0),
        (32, 1.0), (32, 1.0), (32, 1.0), (32, 1.0),
        (31, 1.0), (31, 1.0), (31, 1.0), (31, 1.0),
    ]
    downwell_bgm = generate_bgm_track(downwell_melody, downwell_bass, bpm=140.0)
    write_wav(sounds_dir / 'downwell_bgm.wav', downwell_bgm)

    # Spritesheet BMP (128x128 24-bit bitmap)
    w, h = 128, 128
    pixels = [(15, 12, 20)] * (w * h)
    for y in range(8, 26):
        for x in range(8, 24):
            pixels[y * w + x] = (255, 255, 255)
    for y in range(22, 28):
        for x in range(8, 24):
            pixels[y * w + x] = (230, 40, 50)
    for y in range(8, 24):
        for x in range(40, 56):
            pixels[y * w + x] = (255, 215, 0)

    write_bmp(sprites_dir / 'downwell_sprites.bmp', w, h, pixels)
    print("Generated Downwell BGM and audio assets!")

def generate_nuclearthrone_assets():
    dir_path = ROOT / 'nuclearthrone' / 'assets'
    sounds_dir = dir_path / 'sounds'
    sprites_dir = dir_path / 'sprites'

    # Sound FX
    write_wav(sounds_dir / 'nuclearthrone_shoot.wav', generate_square_wave(450, 0.14, 0.5, sweep=-0.5))
    write_wav(sounds_dir / 'nuclearthrone_laser.wav', generate_square_wave(950, 0.20, 0.4, sweep=-0.8))
    write_wav(sounds_dir / 'nuclearthrone_explosion.wav', generate_noise(0.40, 0.7))
    write_wav(sounds_dir / 'nuclearthrone_rad.wav', generate_square_wave(800, 0.08, 0.35, sweep=0.6))
    write_wav(sounds_dir / 'nuclearthrone_hit.wav', generate_noise(0.20, 0.5))

    # Heavy wasteland driving synth BGM loop (125 BPM, Driving D minor riff)
    nuclearthrone_melody = [
        (50, 0.75), (50, 0.25), (53, 0.5), (55, 0.5), (53, 0.5), (50, 0.5), (48, 0.5), (50, 0.5),
        (50, 0.75), (50, 0.25), (53, 0.5), (57, 0.5), (55, 0.5), (53, 0.5), (50, 0.5), (53, 0.5),
        (50, 0.75), (50, 0.25), (53, 0.5), (55, 0.5), (58, 0.5), (57, 0.5), (55, 0.5), (53, 0.5),
        (50, 0.75), (50, 0.25), (48, 0.5), (46, 0.5), (45, 0.5), (48, 0.5), (50, 1.0),
    ]
    nuclearthrone_bass = [
        (38, 1.0), (38, 1.0), (38, 1.0), (38, 1.0),
        (38, 1.0), (38, 1.0), (41, 1.0), (43, 1.0),
        (38, 1.0), (38, 1.0), (38, 1.0), (38, 1.0),
        (36, 1.0), (34, 1.0), (33, 1.0), (38, 1.0),
    ]
    nuclearthrone_bgm = generate_bgm_track(nuclearthrone_melody, nuclearthrone_bass, bpm=125.0)
    write_wav(sounds_dir / 'nuclearthrone_bgm.wav', nuclearthrone_bgm)

    # Spritesheet BMP (128x128 24-bit bitmap)
    w, h = 128, 128
    pixels = [(28, 22, 18)] * (w * h)
    for y in range(6, 26):
        for x in range(6, 26):
            pixels[y * w + x] = (40, 200, 100)
    for y in range(6, 26):
        for x in range(40, 60):
            pixels[y * w + x] = (220, 100, 40)

    write_bmp(sprites_dir / 'nuclearthrone_sprites.bmp', w, h, pixels)
    print("Generated Nuclear Throne BGM and audio assets!")

if __name__ == '__main__':
    generate_downwell_assets()
    generate_nuclearthrone_assets()
