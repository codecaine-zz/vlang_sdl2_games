# 🕹️ Adventures of Lolo: Cyberpunk Edition & Level Designer
### *A Modern Puzzle-Arcade Powerhouse, Mario Maker Sandbox & Speedrun Platform*

Built in [V](https://vlang.io/) using [vlang/sdl](https://github.com/vlang/sdl). Features **zero external asset dependencies** — with 100% procedural procedural synth audio, multi-pass neon bloom shaders, procedural particle emitters, and real-time AI pathfinding.

---

## ⚡ Quick Launch

```bash
# Run the game
v run lolo

# Run the automated verification test suite
v test lolo
```

---

## 🎮 Complete Key Controls Guide

| Key | Action | Description |
| :--- | :--- | :--- |
| **`W / A / S / D`** or **`Arrows`** | **Ion Drive Move** | 4-way grid movement and block pushing |
| **`Space`** or **`Enter`** | **Fire Plasma Shot** | Encases enemies in stasis eggs or rotates laser prisms |
| **`Q`** | **Quantum Phase Shift** | Switch active dimension between **Alpha** and **Beta** |
| **`C`** | **Cycle Cyber-Lolo Skins** | Switch mecha skins (*Neon Blue, Magenta, Gold, Lime, Dark Matter*) |
| **`H`** | **Toggle AI Hints** | Real-time holographic breadcrumb path to next objective |
| **`V`** | **Instant Ghost Replay** | Replay your previous successful room clear input sequence |
| **`K`** | **Cyber-Code Sharing** | Export/import level strings & open Community Challenge Packs |
| **`M`** | **Toggle Synth BGM** | Enable/disable procedural cyberpunk background music |
| **`S`** | **Toggle SFX Audio** | Quick toggle for all audio sound effects |
| **`Tab`** | **Level Designer Console** | Toggle between Play Mode and the Mario Maker Level Maker |
| **`U`** or **`Z`** | **Quantum Undo Step** | Instantly undo the last movement, push, or item pickup |
| **`P`** | **Sector Warp Directory** | Open the 65-sector Master Trilogy & Arcade Worlds directory |
| **`R`** | **Quick Retry Sector** | Restart current sector with fresh room telemetry |
| **`F5`** | **Test Play Custom Level** | 1-key instant playtest inside the Level Designer |
| **`F11`** | **Toggle Fullscreen** | Switch between windowed mode and fullscreen desktop |

---

## 🌌 6 Procedural Cyber Biomes

Each theme features unique color schemes, animated atmospheric particle engines, and custom synth music:

1. **Neo Cyber-Core (Castle)**: Deep obsidian matrix with pulsing cyan fiber-optic circuits, digital scanlines, and high-frequency data packets.
2. **Quantum Biosphere (Forest)**: Bioluminescent emerald matrix grid, rising quantum energy spores, and glowing data spires.
3. **Solar Outpost (Desert)**: Terraform solar-cell pavers, amber warning beacons, and solar radiation storm particles.
4. **Cryo-Stasis Lab (Ice)**: Sub-zero crystalline cyan glass with falling cryo-crystals, sub-zero coolant ducts, and frictionless ice sheets.
5. **Plasma Fusion Reactor (Volcanic)**: Superheated magma conduit plating with bubbling plasma channels and rising high-energy ion sparks.
6. **Void Singularity (Haunted)**: Astral dark-matter rift with twinkling cosmic starfields, spectral candle runes, and floating phantom wisps.

---

## 🧩 Interactive Tiles & Modern Puzzle Gizmos

- **Optical Laser Prisms (`/` and `\`)**: 45° angled reflective crystal blocks. When struck by a Medusa laser beam, they reflect the beam **90 degrees**! Walking into a prism or shooting it with plasma rotates its angle between `/` and `\`.
- **Quantum Phase Blocks (`Phase A` & `Phase B`)**: Holographic blocks that phase with your dimension (`Q` key). When in **Dimension Alpha**, Alpha blocks are solid while Beta blocks are ethereal walkthrough spaces (and vice-versa).
- **Conductive Pressure Plates & Toggle Laser Gates**: Stepping on a pressure plate (or pushing an Energy Block onto it) permanently drops the lethal red laser forcefield gate.
- **Directional Conveyor Belts (`^`, `v`, `<`, `>`)**: Kinetic conveyor tracks that push entities traveling across them.
- **Frictionless Cryo Ice**: Slide continuously in the direction of movement until colliding with an obstacle or reaching solid floor.
- **Molten Plasma Lava**: Fatal liquid hazard. Push an Emerald Block or Stasis Egg into lava to create a solid bridge!
- **Quantum Subspace Portals (`Warp A` ↔ `Warp B`)**: Teleport instantaneously between linked singularity pads.
- **Security Keycard & Locked Gate**: Collect the golden security key to unlock iron portcullises.
- **Disruption Wrench (Hammer)**: Shatter and clear obstacles on contact.
- **Overdrive Jet Boots**: Grants a golden speed and invulnerability energy shield for 10 seconds.

---

## 👾 Cybernetic Bestiary: 13 Enemies & Traps

| Entity | Icon / Name | Behavior & Tactical Notes |
| :--- | :--- | :--- |
| **Snakey-Bot** | `S` Snakey | Docile sentry drone. Harmless to touch, excellent for pushing into coolant streams or using as laser shields. |
| **Alma-Mech** | `A` Alma | Aggressive bipedal assault robot with siren beacon that actively pursues Lolo along the shortest path. |
| **Leeper-Droid** | `Z` Leeper | Agile green scout that hops towards Lolo. Upon touching Lolo, enters permanent standby sleep mode to become a stationary block. |
| **Plasma Skull** | `U` Skull | Dormant cyber-skull drone with twin plasma turbines that activates and dashes when all power cores are collected. |
| **Laser Sentinel** | `M` Medusa | Stationary turret with optical scanners that fires lethal laser beams on direct line-of-sight. |
| **Dreadnought H/V** | `Don Medusa` | Armored mobile hover dreadnought patrolling horizontally or vertically with laser scanners. |
| **Gol Dragon Tank** | `G` Gol | Heavy artillery dragon tank that awakens when all power cores are collected, firing homing plasma fireballs. |
| **Mecha King Egger** | `K` King Egger | Giant cyber boss with holographic gold crown, commanding high-security boss sectors. |
| **Aero Gobby** | `Y` Gobby | Stealth aero-scout with holographic energy wings that flies over water and swoops down rapidly when aligned. |
| **Titan Golem** | `Rocky` | Industrial crusher mech that locks line of sight and charges forward at high speed, smashing into walls. |
| **Turbine Moby** | `Moby` | Aquatic beast that periodically creates powerful draft suction and push currents. |
| **Phantom Wisp** | `Wisp` | Quantum phase-shifting Boo ghost. Freezes and covers its face when looked at directly, and stalks Lolo when Lolo looks away! |
| **Tesla Spike Trap** | `Spike Trap` | High-voltage floor hazard that periodically extends and retracts lethal electric arcs. |

---

## 🛠️ Mario Maker Level Designer Manual

Press **`Tab`** at any time to open the full Level Designer:

- **Categorized Tabs**:
  - `[TILES]`: Grass, Wall, Rock, Spire, Coolant, Scaffold, Plasma, Cryo Ice, Warps A/B, Gate, Prisms, Plates, Laser Gate, Conveyors, Phase A/B, Pulse Laser Gate, Multi-Channel Plates & Gates.
  - `[ITEMS]`: Lolo Spawn, Exit Gate, Data Vault, Antimatter Cores, Energy Blocks, Wrench, Keycard, Jet Boots, Hologram Info Beacons.
  - `[ENEMIES]`: Snakey, Alma, Leeper, Skull, Medusa, Don Medusa H/V, Gol, King Egger, Gobby, Rocky, Moby, Wisp, Tesla Trap.
  - `[SETTINGS]`: Biome Switcher, Dark Dungeon Vision Mode, Blueprint Templates, Share Codes, and 5 Save/Load Slots (`S1..S5`, `L1..L5`).
- **Precision Drawing Tools**:
  - `PEN`: Single-tile click or drag-painting.
  - `LINE`: Straight line drawing between two points with Bresenham line algorithm.
  - `RECT`: Box fill rectangular regions.
  - `FILL`: Flood-fill contiguous identical tile regions.
  - `ERASE`: Clear cells to empty grid.
  - `PREFAB`: 1-click drop-in modular puzzle templates (*Mirror Rig, Warp Hub, Conveyor Loop, Turret Bunker, Pressure Gate*).
- **1-Click Test-From-Here (`Right-Click`)**:
  - Right-click on any grid cell in the editor to immediately spawn Lolo on that exact cell and playtest that section without walking across the entire map!
- **Dark Dungeon Fog-of-War Mode**:
  - Toggle in Settings: Shrouds the room in total darkness with real-time radial torch beam illumination centered on Lolo.
- **Hologram Lore & Story Terminals**:
  - Place `.holo_terminal` beacons on the map to display cyberpunk hint dialogues and level storylines.
- **Speedrun Medals (Gold / Silver / Bronze)**:
  - Custom target clear times evaluated upon level victory with badge toast celebrations.

---

## 🌐 Level Sharing & 5 Community Challenge Packs

Press **`K`** to open the Level Sharing Console:
- **Export & Import Level Codes**: Export any custom level into a compact string (e.g. `CYBER-0...`) that can be pasted and played instantly.
- **Featured Community Packs**:
  1. 🕹️ **Kaizo Cyber**: High-intensity reflex and precision shielding trial.
  2. 🕹️ **Laser Optics**: Dual Sentinel turrets with rotatable prism reflection puzzles.
  3. 🕹️ **Quantum Shift**: Mind-bending dual-dimension phase puzzle.
  4. 🕹️ **Conveyor Rush**: High-speed kinetic accelerator maze.
  5. 🕹️ **Apex Fortress**: Grand volcanic boss battle with lava channels and King Egger.

---

## ⚡ Speedrun Telemetry & Ghost Replay

- **Live Millisecond Splits**: Real-time timer and step counter in the telemetry HUD.
- **Personal Best Tracking**: Automatically saves your fastest time and minimum steps per sector.
- **Ghost Input Replay (`V` Key)**: Replay your successful room clear solution in fast-forward.
- **Speedrun Medals**: Earn 🥇 Gold, 🥈 Silver, or 🥉 Bronze medals based on clear speed!

---

## 🏆 Cyber Skins & Achievement Badges

- **5 Mecha Skins (`C` Key)**:
  - 🔵 **Classic Neon Blue** (Cobalt chassis + cyan visor)
  - 🔴 **Cyberpunk Magenta** (Hot magenta chassis + ruby visor)
  - 🟡 **Obsidian Gold** (Stealth black chassis + gold visor)
  - 🟢 **Toxic Lime** (Radioactive lime chassis + yellow visor)
  - 🟣 **Dark Matter** (Violet void chassis + spectral purple visor)
- **Unlockable Badges**:
  - 🏅 *Minimalist*: Clear a room in 25 steps or less.
  - 🏅 *Speed Demon*: Clear a room under 15.00 seconds.
  - 🏅 *Pacifist*: Clear a room without firing shots.
  - 🏅 *Master Architect*: Build and test a valid custom level in the Designer.
  - 🏅 *Grand Master*: Clear all campaign and bonus sectors!

---

## 🧪 Architecture & Automated Testing

```bash
# Run unit tests
v test lolo
```

All 65 campaign rooms, 5 community challenge packs, line and prefab drawing tools, multi-channel gates, timed pulse lasers, hologram terminals, dark dungeon fog-of-war, laser reflection physics, dimension phase shifting, speedrun medals, and code serialization are 100% verified with automated unit tests.
