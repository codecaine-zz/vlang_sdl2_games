# Vampire Survivors (V Lang + SDL2)

A gothic bullet-hell survival roguelike built in V with SDL2, featuring 10 weapon evolutions, 6 playable characters, 3 stages, active Shadow Dash, top Boss HP bars, 6-slot inventory limits, and permanent metaprogression.

## Save State & Metaprogression Directories

Save states and account progress (`save.json`) are stored in standard OS-compliant application directories so no root or elevated permissions are required:

- **macOS**: `~/Library/Application Support/vampiresurvivors/save.json`
- **Linux / Unix**: `~/.config/vampiresurvivors/save.json` (or `$XDG_CONFIG_HOME/vampiresurvivors/save.json`)
- **Windows**: `%APPDATA%\vampiresurvivors\save.json`

*Note: If a legacy `./save.json` file is present in the game directory from older builds, it is automatically migrated to your platform's application folder.*

## Controls

| Key | Action |
| :--- | :--- |
| `WASD` / `Arrows` | Move character (weapons autofire) |
| `Shift` / `LShift` | **Shadow Dash** (0.4s invulnerability burst, 3.0s cooldown) |
| `1` - `6` | Select Character on main menu (Antonio, Imelda, Pasqualina, Gennaro, Mortaccio, Eleanor) |
| `U` | Open **Power-Up Metaprogression Shop** |
| `M` | Cycle **Stage / Map** (Mad Forest, Inlaid Library, Castle Grounds) |
| `1` / `2` / `3` or `Space` | Select upgrade card on Level-Up screen |
| `R` / `S` / `B` | **Reroll**, **Skip**, or **Banish** upgrade choices |
| `C` | Toggle 2-Player Local Co-op |
| `D` | Toggle Difficulty (Normal, Hard, Inferno) |
| `P` / `Esc` | Pause game & view Evolution Grimoire & real-time DPS |

## Quick Start

```bash
# Run game
v run .

# Run unit test suite
v test .
```
