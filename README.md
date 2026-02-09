# Slime Split

![LOVE2D](https://img.shields.io/badge/LOVE2D-11.4-E74A99?style=flat-square&logo=love)
![Lua](https://img.shields.io/badge/Lua-5.1-2C2D72?style=flat-square&logo=lua)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Web%20%7C%20Cross--platform-blue?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)

A physics-based puzzle platformer where you **split** and **merge** slimes to solve environmental puzzles. Navigate through increasingly complex levels by strategically dividing your slime to fit through narrow gaps, then recombining to gain the mass needed to push heavy blocks and activate pressure plates.

## Features

- **Split & Merge Mechanic** — Divide your slime into smaller pieces or combine them back into a larger blob, each with different physics properties
- **Physics-Driven Puzzles** — Mass matters: heavier slimes push blocks and trigger plates, lighter slimes fit through tight gaps
- **5 Handcrafted Levels** — Progressive difficulty from basic movement to multi-step strategic puzzles
- **Particle Effects** — Burst particles on split, gather particles on merge, dust on landing
- **Retro Pixel Aesthetic** — PICO-8 inspired color palette with procedurally generated visuals
- **Zero External Dependencies** — Built entirely from LOVE2D standard APIs

## Gameplay

Control a wobbly, physics-driven slime blob through puzzle rooms. The core mechanic revolves around splitting your slime in half (each piece gets half the mass) and merging nearby slimes back together. Smaller slimes are nimble and fit through narrow passages, while larger slimes have the weight to push crates and activate pressure plates that open doors.

Each level introduces new puzzle elements:

| Level | Name | Concept |
|-------|------|---------|
| 1 | First Steps | Movement and jumping basics |
| 2 | Narrow Gap | Split to fit through a tight passage |
| 3 | Heavy Duty | Split, pass through, merge to push a block |
| 4 | Weight Bearing | Pressure plate and door puzzles |
| 5 | Divide and Conquer | Multi-room strategic puzzle with multiple splits |

## Getting Started

### Prerequisites

- [LOVE2D](https://love2d.org/) 11.4 or later

### Running the Game

```bash
# Clone the repository
git clone https://github.com/ChanMeng666/slime-split.git
cd slime-split

# Run with LOVE2D
love .
```

On Windows, you can also use the included batch file:

```bash
run.bat
```

## Controls

| Action | Keys |
|--------|------|
| Move Left | `Left Arrow` / `A` |
| Move Right | `Right Arrow` / `D` |
| Jump | `Space` |
| Split Slime | `Left Shift` / `Right Shift` |
| Merge Slimes | `M` |
| Switch Slime | `Tab` |
| Restart Level | `R` |
| Pause | `Esc` |
| Screenshot | `F12` |

## Game Mechanics

### Split
Divides the selected slime into two equal halves. Each new slime has half the original mass and a smaller radius (`radius = 16 × √mass`). A minimum mass of 1.0 is required to split. The two halves are launched apart with a separation impulse.

### Merge
Combines the selected slime with the nearest slime within range. The merged slime appears at the midpoint with combined mass and averaged velocity. Requires at least 2 slimes on screen.

### Pressure Plates
Sensor zones that track the total mass of all objects resting on them. When cumulative mass meets the threshold, the connected door opens. Both slimes and pushable blocks contribute weight.

### Doors
Kinematic bodies that smoothly slide open when their linked pressure plate is activated. They close again if the plate is unloaded.

### Blocks
Heavy pushable crates (mass = 8) that only larger slimes can move. Used to hold down pressure plates or create stepping stones.

## Building

### .love Package
```bash
build.bat
# Output: build/slime-split.love (~21 KB)
```

### Windows Executable
```bash
build.bat
# Output: build/slime-split-win64/ (standalone folder with .exe and DLLs)
```

### Web Version
```bash
node build_web.js
# Output: build/web/ (index.html + slime-split.js)
```

## Deployment

Deploy to [itch.io](https://itch.io/) using the all-in-one deploy script:

```bash
# Build and deploy all platforms
node deploy.js --version 1.0.0

# Web only
node deploy.js --web --version 1.0.0

# Windows only
node deploy.js --win --version 1.0.0

# Dry run (preview without uploading)
node deploy.js --dry-run
```

Requires [butler](https://itch.io/docs/butler/) CLI to be installed and authenticated.

## Project Structure

```
slime-split/
├── main.lua                 # Entry point
├── conf.lua                 # LOVE2D configuration (640×480, physics enabled)
├── src/
│   ├── entities/
│   │   ├── slime.lua        # Player slime (physics body, split/merge, animation)
│   │   ├── slime_manager.lua# Multi-slime management and action queue
│   │   ├── block.lua        # Pushable crate
│   │   ├── door.lua         # Sliding door
│   │   ├── exit.lua         # Level goal
│   │   └── pressure_plate.lua# Weight-activated sensor
│   ├── levels/
│   │   ├── level_defs.lua   # Level data tables (5 levels)
│   │   └── level_loader.lua # Instantiates entities from level data
│   ├── states/
│   │   ├── state_manager.lua# Game state machine
│   │   ├── menu.lua         # Title screen and level select
│   │   ├── gameplay.lua     # Main game loop
│   │   ├── pause.lua        # Pause overlay
│   │   └── level_complete.lua# Victory screen
│   ├── systems/
│   │   ├── physics.lua      # Box2D world setup
│   │   ├── camera.lua       # Smooth-follow camera with bounds
│   │   ├── particles.lua    # Split/merge/landing particle emitters
│   │   └── input.lua        # Keyboard input abstraction
│   ├── ui/
│   │   ├── hud.lua          # In-game HUD
│   │   └── transition.lua   # Fade transitions
│   └── lib/
│       ├── colors.lua       # PICO-8 inspired color palette
│       └── utils.lua        # Math helpers (lerp, clamp, distance)
├── build.bat                # Build script (.love + Windows exe)
├── build_web.js             # Web build via love.js
├── deploy.js                # itch.io deployment automation
└── run.bat                  # Quick-launch script
```

## Tech Stack

| Technology | Purpose |
|------------|---------|
| [LOVE2D](https://love2d.org/) 11.4 | Game framework |
| Lua 5.1 | Programming language |
| Box2D | Physics engine (via love.physics) |
| [love.js](https://github.com/Davidobot/love.js) | Web build (Emscripten port) |
| [butler](https://itch.io/docs/butler/) | itch.io deployment |

## License

This project is licensed under the MIT License.
