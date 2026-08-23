#!/usr/bin/env python3
import os
from pathlib import Path

root = Path("/Users/codecaine/vlang_sdl2_games")
sprites_dir = root / "assets" / "sprites"
sounds_dir = root / "assets" / "sounds"
music_dir = root / "assets" / "music"

game_dirs = [d for d in root.iterdir() if d.is_dir() and not d.name.startswith(".") and d.name not in ["assets", "screenshots", "tools", "scratch"]]

print(f"Total game directories found: {len(game_dirs)}")

missing_sprites = []
missing_sounds = []
missing_music = []

for g in sorted(game_dirs, key=lambda x: x.name):
    gname = g.name
    sprite_file = sprites_dir / f"{gname}.png"
    has_sprite = sprite_file.exists()
    
    sound_files = list(sounds_dir.glob(f"{gname}*.wav"))
    has_sound = len(sound_files) > 0
    
    music_files = list(music_dir.glob(f"{gname}*.wav"))
    has_music = len(music_files) > 0
    
    status = []
    if not has_sprite:
        missing_sprites.append(gname)
        status.append("NO_SPRITE")
    if not has_sound:
        missing_sounds.append(gname)
        status.append("NO_SOUNDS")
    if not has_music:
        missing_music.append(gname)
        status.append("NO_MUSIC")
        
    print(f"{gname:<20}: {' | '.join(status) if status else 'COMPLETE'}")

print("\n--- Summary ---")
print(f"Missing Sprites ({len(missing_sprites)}): {missing_sprites}")
print(f"Missing Sounds ({len(missing_sounds)}): {missing_sounds}")
print(f"Missing Music ({len(missing_music)}): {missing_music}")
