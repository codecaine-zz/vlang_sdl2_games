# Math Munchers (V / SDL2)

A feature-complete retro arcade educational game built in V using SDL2, inspired by the classic Number/Math Munchers franchise.

## Features
- **Multiple Math Categories**: Multiples, Factors, Prime Numbers, Equations (Equals X), Greater/Less Than, and Perfect Squares.
- **Dynamic Solvable Grid**: 6x5 grid dynamically populated with solvable targets and distractor numbers/equations.
- **Troggle Enemy AI**:
  - **Reggie**: Horizontal/Vertical walker that re-writes cell numbers as it steps over them.
  - **Smartie**: Seeker enemy that tracks player cell position.
  - **Glutton**: Eater enemy that clears cell contents.
- **Rich Audio & Visual Effects**:
  - 8-bit retro arcade synth background music track loop.
  - Authentic sound effects for movement, munching, wrong answers, troggles, hits, and victory fanfares.
  - Particle bursts, floating score text, screen shake, and production FX vignette.
- **Persistence & High Score**: Automatic save state and high score persistence in OS-compliant directories.

## Controls
- **WASD / Arrow Keys**: Move Muncher across grid cells
- **Space / Enter / Z**: Munch / Eat current cell
- **P**: Pause / Unpause
- **R**: Restart Game
- **O**: Mute / Unmute Sound & BGM

## Running
```bash
v run mathmunchers
```

## Testing
```bash
v test mathmunchers/mathmunchers_test.v
```
