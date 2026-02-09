# Building and Deploying a LOVE2D Game to itch.io: A Complete Guide

> A practical, battle-tested tutorial based on the real development of **Slime Split** — a physics puzzle game built entirely with LOVE2D code (zero external assets). Every pitfall documented here was encountered firsthand.

## Table of Contents

1. [Prerequisites](#1-prerequisites) — LOVE2D, Node.js, butler
2. [Project Setup](#2-project-setup) — Directory structure, conf.lua, main.lua
3. [LOVE2D Architecture Patterns](#3-love2d-architecture-patterns) — State machine, modules, require paths
4. [Building the Game (Step by Step)](#4-building-the-game-step-by-step) — 6-phase development process
5. [Testing Locally](#5-testing-locally) — Running, screenshots, pixel rendering
6. [Building Distribution Packages](#6-building-distribution-packages) — .love, Windows .exe, zip
7. [Building the Web Version (love.js)](#7-building-the-web-version-lovejs) — Emscripten, virtual FS, memory config
8. [Deploying to itch.io](#8-deploying-to-itchio) — Manual upload, butler CLI, deploy.js, page config
9. [Pitfalls & Fixes (Lessons Learned)](#9-pitfalls--fixes-lessons-learned) — 12 pitfalls encountered
10. [Project Structure Reference](#10-project-structure-reference) — Complete file listing

---

## 1. Prerequisites

| Tool | Version Used | Purpose |
|------|-------------|---------|
| [LOVE2D](https://love2d.org/) | 11.4 | Game framework (includes Box2D physics, OpenGL rendering) |
| [Node.js](https://nodejs.org/) | 22.x | Web build script and deploy script |
| [butler](https://itchio.itch.io/butler) | latest | itch.io CLI for automated deployment |
| A text editor | Any | Writing Lua code |

### Install LOVE2D

Download from https://love2d.org/ and install. On Windows, the default path is:

```
C:\Program Files\LOVE\love.exe
```

Verify it works:

```bash
"C:\Program Files\LOVE\love.exe" --version
```

### Install butler (itch.io CLI)

butler is itch.io's official command-line tool for pushing game builds. It enables incremental uploads (only changed data is pushed), version tracking, and full automation — no browser needed after initial setup.

**Download and extract:**

```bash
# Windows — download from broth.itch.zone (stable, permanent URL):
curl -L -o butler-win.zip "https://broth.itch.zone/butler/windows-amd64/LATEST/archive/default"

# Extract to a permanent location (e.g. D:\tools\butler):
powershell Expand-Archive -Path butler-win.zip -DestinationPath D:\tools\butler
```

**Verify installation:**

```bash
D:\tools\butler\butler.exe version
# → head, built on ...
```

**Login (one-time):**

```bash
D:\tools\butler\butler.exe login
# Opens browser for itch.io OAuth → authenticate → done
# Credentials saved to ~/.config/itch/butler_creds
```

> You do NOT need to add butler to PATH. Our deploy script references it by absolute path.

### Key Concept: How LOVE2D Works

LOVE2D looks for a `main.lua` file in the directory you point it to. Your game is a folder of `.lua` files — no compilation step, no build tools for development. Just edit and run.

```bash
# Run your game during development:
"C:\Program Files\LOVE\love.exe" path/to/your/game/folder
```

---

## 2. Project Setup

### Directory Structure

```
my-game/
├── main.lua          -- Entry point (required)
├── conf.lua          -- Window/module configuration (optional but recommended)
├── run.bat           -- Quick launcher (Windows convenience)
├── build.bat         -- Build script for .love and .exe
├── build_web.js      -- Web build script (Node.js)
├── deploy.js         -- One-click build + deploy to itch.io (Node.js)
└── src/              -- Your game code (organized however you like)
```

### conf.lua — Configuration

```lua
function love.conf(t)
    t.identity = "my-game"        -- Save directory name (IMPORTANT for web builds)
    t.title = "My Game"
    t.version = "11.4"            -- Target LOVE2D version (see Pitfall #11 for web builds)
    t.window.width = 640
    t.window.height = 480
    t.window.resizable = false
    t.window.vsync = 1

    t.modules.physics = true      -- Enable Box2D if you need physics
    t.modules.audio = true
    t.modules.sound = true
end
```

> **PITFALL #1: Missing `t.identity`**
> Without `t.identity`, LOVE2D uses a default save directory name. This matters for web builds because the virtual filesystem uses this identity. Always set it explicitly.

### run.bat — Quick Launcher

```bat
@echo off
"C:\Program Files\LOVE\love.exe" "%~dp0"
```

### main.lua — Entry Point

```lua
function love.load()
    -- Initialize your game here
end

function love.update(dt)
    dt = math.min(dt, 1/30)  -- Cap delta time to prevent physics explosions
    -- Update game logic
end

function love.draw()
    -- Render your game
end

function love.keypressed(key)
    -- Handle key presses
end
```

---

## 3. LOVE2D Architecture Patterns

### State Machine Pattern

Most LOVE2D games use a state machine to manage screens (menu, gameplay, pause, etc.). Here's a minimal implementation:

```lua
-- src/states/state_manager.lua
local StateManager = {}
StateManager.__index = StateManager

function StateManager.new()
    local self = setmetatable({}, StateManager)
    self.states = {}
    self.current = nil
    return self
end

function StateManager:register(name, state)
    self.states[name] = state
end

function StateManager:switch(name, ...)
    if self.current and self.current.leave then
        self.current:leave()
    end
    self.current = self.states[name]
    if self.current and self.current.enter then
        self.current:enter(...)
    end
end

function StateManager:update(dt)
    if self.current and self.current.update then
        self.current:update(dt)
    end
end

function StateManager:draw()
    if self.current and self.current.draw then
        self.current:draw()
    end
end

function StateManager:keypressed(key)
    if self.current and self.current.keypressed then
        self.current:keypressed(key)
    end
end

return StateManager
```

Then in `main.lua`:

```lua
local StateManager = require("src.states.state_manager")
local Menu = require("src.states.menu")
local Gameplay = require("src.states.gameplay")

local sm

function love.load()
    sm = StateManager.new()
    sm:register("menu", Menu.new(sm))
    sm:register("gameplay", Gameplay.new(sm))
    sm:switch("menu")
end

function love.update(dt)
    sm:update(dt)
end

function love.draw()
    sm:draw()
end

function love.keypressed(key)
    sm:keypressed(key)
end
```

### Require Paths

LOVE2D uses dot-separated paths for `require`:

```lua
-- File: src/entities/player.lua
-- Require it as:
local Player = require("src.entities.player")
```

> The path is relative to your game's root directory (where `main.lua` is).

### Module Pattern

Each Lua file should return a table (class-like):

```lua
-- src/entities/player.lua
local Player = {}
Player.__index = Player

function Player.new(x, y)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    return self
end

function Player:update(dt)
    -- ...
end

function Player:draw()
    -- ...
end

return Player
```

---

## 4. Building the Game (Step by Step)

### Phase 1: Skeleton

Start with the minimal loop:

1. `conf.lua` — window settings
2. `main.lua` — love.load/update/draw callbacks
3. State manager + menu state + empty gameplay state
4. **Test**: Window opens, menu renders, pressing Enter switches to gameplay

### Phase 2: Core Mechanics

Add your core entity and physics:

1. Physics world: `love.physics.newWorld(0, 600, true)` — 600 is gravity
2. Player entity with Body + Shape + Fixture
3. Input handling
4. Static walls for testing
5. **Test**: Entity moves around and collides with walls

### Phase 3: Game-Specific Features

Add what makes your game unique. For Slime Split, this was:

1. Split/merge mechanic with deferred execution queue
2. Particle effects
3. **Test**: Core mechanic works correctly

> **PITFALL #2: Modifying physics bodies during collision callbacks**
> Box2D does NOT allow creating or destroying bodies inside `beginContact`/`endContact` callbacks. Always queue operations and execute them AFTER `world:update(dt)`.

```lua
-- WRONG: This will crash
function beginContact(a, b, contact)
    someBody:destroy()  -- CRASH!
end

-- RIGHT: Queue and process after physics step
function gameplay:update(dt)
    self.physics:update(dt)          -- physics step
    self.slime_mgr:processQueue()    -- NOW safe to create/destroy bodies
end
```

### Phase 4: Levels

1. Define levels as pure data tables (no code, just numbers)
2. Level loader reads data and creates entities
3. Camera system follows the active entity
4. **Test**: Multiple levels load and are playable

### Phase 5: Puzzle Elements

Add interactive objects (buttons, doors, etc.):

1. Each element = a physics body with collision callbacks
2. Use sensors (non-solid fixtures) for detection zones
3. Link elements together (pressure plate → door)
4. **Test**: All puzzle interactions work

> **PITFALL #3: Overlapping static and kinematic bodies**
> If a door (kinematic body) occupies the same space as a wall (static body), physics behaves unpredictably. Always leave a gap in the wall where the door goes:

```lua
-- WRONG: Wall covers y=20 to y=430, door is at y=350 to y=430
walls = { {420, 20, 20, 410} }    -- solid wall, no gap
doors = { {420, 350, 20, 80} }    -- overlaps with wall!

-- RIGHT: Wall stops where door begins
walls = { {420, 20, 20, 330} }    -- wall from y=20 to y=350
doors = { {420, 350, 20, 80} }    -- door from y=350 to y=430
```

### Phase 6: Polish

1. HUD (heads-up display)
2. Pause screen (draw gameplay underneath + overlay)
3. Level complete screen
4. Fade transitions between states
5. **Test**: Full game loop works end-to-end

---

## 5. Testing Locally

### Running the Game

```bash
# From the game directory:
"C:\Program Files\LOVE\love.exe" .

# Or from anywhere:
"C:\Program Files\LOVE\love.exe" "D:\path\to\your\game"
```

### Adding a Screenshot Feature

Useful for testing and creating itch.io assets:

```lua
function love.keypressed(key)
    if key == "f12" then
        love.graphics.captureScreenshot(function(imageData)
            local fileData = imageData:encode("png")
            love.filesystem.write("screenshot.png", fileData)
        end)
        return
    end
    -- ... rest of your key handling
end
```

Screenshots are saved to `%APPDATA%/LOVE/<identity>/` on Windows.

### Pixel-Perfect Rendering

For retro/pixel art style:

```lua
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")  -- no smoothing
    love.graphics.setLineStyle("rough")                    -- pixelated lines
end
```

### Delta Time Capping

Always cap delta time to prevent physics explosions after window dragging or lag spikes:

```lua
function love.update(dt)
    dt = math.min(dt, 1/30)  -- never simulate more than 1/30th of a second
    -- ...
end
```

---

## 6. Building Distribution Packages

### Step 1: Create the .love File

A `.love` file is just a `.zip` renamed, with `main.lua` at the root:

```bash
# PowerShell (Windows):
Compress-Archive -Path main.lua, conf.lua, src -DestinationPath build/my-game.zip
Rename-Item build/my-game.zip my-game.love

# Verify it works:
"C:\Program Files\LOVE\love.exe" build/my-game.love
```

> **PITFALL #4: main.lua not at zip root**
> The zip must contain `main.lua` at the top level — NOT inside a subfolder. If you zip the parent folder itself, main.lua will be at `my-game/main.lua` instead of `main.lua`, and LOVE2D won't find it.

### Step 2: Create Windows Executable

Fuse the `.love` file with `love.exe`:

```bash
# Windows cmd:
copy /b "C:\Program Files\LOVE\love.exe"+build\my-game.love build\my-game.exe

# Copy required DLLs alongside the exe:
copy "C:\Program Files\LOVE\*.dll" build\
copy "C:\Program Files\LOVE\license.txt" build\
```

The resulting `build/` folder with `.exe` + DLLs is your standalone Windows distribution.

### Step 3: Create Distribution Zips

```bash
# Web version zip (for itch.io browser play):
Compress-Archive -Path build/web/index.html, build/web/my-game.js -DestinationPath build/my-game-web.zip

# Windows version zip (for itch.io download):
Compress-Archive -Path build/my-game-win64/* -DestinationPath build/my-game-win64.zip
```

---

## 7. Building the Web Version (love.js)

This is the most complex and pitfall-prone part. The web version lets anyone play your game in a browser — no installation needed.

### How It Works

1. **love.js** is LOVE2D compiled to JavaScript via Emscripten (an older build based on LOVE 0.11.1)
2. Your game files are base64-encoded and embedded as Emscripten virtual filesystem operations
3. A small HTML page provides the canvas, loading UI, and bootstrapping code
4. When the player clicks "Play", the JS loads, creates the virtual FS, and runs LOVE

### The Build Script

We created `build_web.js` (Node.js) that automates this:

```bash
node build_web.js
```

It produces:
- `build/web/index.html` — the web page
- `build/web/my-game.js` — love.js runtime + embedded game data (~9 MB)

### Critical Technical Details

#### How Files Are Embedded

Each game file becomes a `FS.createDataFile` call with base64 data:

```javascript
// Virtual filesystem setup (generated by build script)
FS.mkdir('/l');
FS.mkdir('/l/src');
FS.mkdir('/l/src/states');
FS.createDataFile('/l', 'main.lua', FS.DEC('base64data...'), !0, !0, !0);
FS.createDataFile('/l', 'conf.lua', FS.DEC('base64data...'), !0, !0, !0);
FS.createDataFile('/l/src/states', 'menu.lua', FS.DEC('base64data...'), !0, !0, !0);
// ... every file individually
```

Then the game launches with:

```javascript
Module.run(['/l']);  // Tell LOVE to run from the /l directory
```

#### Memory Configuration

```javascript
Module = {
    TOTAL_MEMORY: 1024 * 1024 * 256,  // 256 MB heap
    TOTAL_STACK: 1024 * 1024 * 8,     // 8 MB stack
    currentScriptUrl: '-',
    preInit: DoExecute
};
```

> **PITFALL #5: TOTAL_MEMORY too small — "Cannot enlarge memory arrays" crash**
>
> The old Emscripten build used by love.js does NOT support dynamic memory growth. You must pre-allocate enough memory. LOVE2D + Box2D physics needs at least 128 MB. We use 256 MB to be safe.
>
> **Error message:**
> ```
> Uncaught abort("Cannot enlarge memory arrays. Either (1) compile
> with -s TOTAL_MEMORY=X with X higher than the current value 67108864...")
> ```
>
> **Fix:** Set `TOTAL_MEMORY` to at least `1024*1024*256` (256 MB).

> **PITFALL #6: TOTAL_STACK equal to TOTAL_MEMORY — silent memory exhaustion**
>
> The stack is carved FROM the heap (TOTAL_MEMORY). If both are 64 MB, the stack consumes the entire heap, leaving zero bytes for actual allocations.
>
> | Setting | Bad | Good |
> |---------|-----|------|
> | TOTAL_MEMORY | 64 MB | **256 MB** |
> | TOTAL_STACK | 64 MB | **8 MB** |
>
> **Rule of thumb:** TOTAL_STACK should be 2-8 MB. TOTAL_MEMORY should be 128-256 MB.

> **PITFALL #7: Embedding .love as a binary blob — "No code to run" error**
>
> **Error message:**
> ```
> boot.lua:436: No code to run
> Your game might be packaged incorrectly
> Make sure main.lua is at the top level of the zip
> ```
>
> **Cause:** We initially base64-encoded the entire `.love` file (which is a zip) and placed it as a single binary blob at `/p/game.love` in the virtual filesystem:
>
> ```javascript
> // WRONG: The old love.js can't open zip files from the virtual FS
> FS.mkdir('/p');
> FS.createDataFile('/p', 'game.love', FS.DEC('...entire zip as base64...'), !0, !0, !0);
> Module.run(['/p']);
> ```
>
> The Emscripten-compiled LOVE 0.11.1 cannot open `.love`/`.zip` files from the virtual filesystem. It can only read individual files.
>
> **Fix:** Walk the source directory, embed each file individually:
>
> ```javascript
> // RIGHT: Each file is a separate FS entry
> FS.mkdir('/l');
> FS.mkdir('/l/src');
> FS.mkdir('/l/src/states');
> FS.createDataFile('/l', 'main.lua', FS.DEC('...'), !0, !0, !0);
> FS.createDataFile('/l', 'conf.lua', FS.DEC('...'), !0, !0, !0);
> FS.createDataFile('/l/src/states', 'menu.lua', FS.DEC('...'), !0, !0, !0);
> // ... one call per file
> Module.run(['/l']);  // LOVE finds /l/main.lua and runs it
> ```
>
> This is exactly what the online LÖVE Web Builder tool does internally.

> **PITFALL #11: `conf.lua` version mismatch triggers browser warning dialog**
>
> If your `conf.lua` sets `t.version = "11.4"` (your native LOVE2D version) but the love.js runtime is based on LOVE 0.11.0, the player sees an intrusive popup every time they start the game:
>
> ```
> Compatibility Warning
> This game indicates it was made for version '11.4' of LOVE.
> It may not be compatible with the running version (0.11.0).
> ```
>
> **Cause:** LOVE2D checks `conf.lua`'s `t.version` against its own version at boot. The two-major-version gap (0.11 vs 11.4) triggers the warning even though the game works fine.
>
> **Fix:** Patch `conf.lua` during the web build to remove or comment out the `t.version` line. This way, native builds (LOVE 11.4) still get the correct version declaration, while web builds skip the check entirely.
>
> In `build_web.js`, add this when processing each file:
>
> ```javascript
> // Patch conf.lua: remove t.version line for web compatibility
> if (fileName === 'conf.lua') {
>     let src = data.toString('utf-8');
>     src = src.replace(
>         /^\s*t\.version\s*=\s*"[^"]*"\s*$/m,
>         '    -- t.version removed for web build compatibility'
>     );
>     data = Buffer.from(src, 'utf-8');
> }
> ```
>
> **Key insight:** Don't change your source `conf.lua` — you still want `t.version` for native LOVE2D builds. Only patch it in the web build pipeline.

### love.js Compatibility Notes

The love.js runtime from LÖVE Web Builder is based on **LOVE 0.11.1** (a pre-release of 11.0). While our game targets LOVE 11.4, most APIs are backward compatible. However:

- Some newer 11.x APIs may not exist
- Performance is lower than native (it's JavaScript, not native code)
- Audio may behave differently
- File I/O is limited to the Emscripten virtual filesystem
- SharedArrayBuffer may require specific HTTP headers on some hosts

If you need strict 11.4 compatibility, consider [2dengine/love.js](https://github.com/2dengine/love.js/) which supports 11.3/11.4/11.5, but requires a different setup process.

---

## 8. Deploying to itch.io

### Step 1: Create an Account

Register at https://itch.io/register

### Step 2: Create a New Project

Go to Dashboard → **Create new project** and fill in:

| Field | Value |
|-------|-------|
| Title | Your Game Name |
| Project URL | `your-username.itch.io/your-game` |
| Short description | One-line hook (shown in search results) |
| Classification | Games |
| Kind of project | HTML (if you have a web build) |
| Release status | Released |
| Pricing | Free / $0 or donate / Paid |

### Step 3: Upload Files — Two Methods

You have two options for uploading: **manual** (browser) or **butler CLI** (automated). We strongly recommend butler for ongoing development.

#### Method A: Manual Upload (Browser)

Upload files through the itch.io web interface:

**Web version** (browser play):
1. Upload `build/my-game-web.zip`
2. Check **"This file will be played in the browser"**
3. Set Viewport dimensions: **640 x 480** (match your game's resolution)

**Windows version** (downloadable):
1. Upload `build/my-game-win64.zip`
2. Mark platform as **Windows**

**Cross-platform .love** (optional):
1. Upload `build/my-game.love`
2. Mark as **Other** platform
3. Add a note: "Requires LOVE2D runtime — download from love2d.org"

#### Method B: butler CLI (Recommended)

butler pushes files directly from the command line. It handles compression, incremental updates, and version tagging automatically.

**Basic push commands:**

```bash
# Push web version
butler push build/web your-username/your-game:html5 --userversion 1.0.0

# Push Windows version
butler push build/my-game-win64 your-username/your-game:windows --userversion 1.0.0

# Push .love package
butler push build/my-game.love your-username/your-game:love --userversion 1.0.0
```

**Channel naming rules** — butler auto-detects platforms from channel names:

| Channel name contains | Auto-tagged as |
|----------------------|----------------|
| `win` or `windows` | Windows |
| `linux` | Linux |
| `mac` or `osx` | macOS |
| `android` | Android |
| (anything else) | No platform tag |

**Useful butler flags:**

| Flag | Purpose |
|------|---------|
| `--userversion 1.0.1` | Tag push with a version number |
| `--userversion-file version.txt` | Read version from a file |
| `--if-changed` | Skip push if contents haven't changed |
| `--dry-run` | Preview what would be pushed without uploading |

**Check deployment status:**

```bash
butler status your-username/your-game
# Shows all channels with upload IDs, build status, and versions
```

#### One-Click Deploy Script (deploy.js)

For maximum convenience, we created `deploy.js` — a single Node.js script that builds ALL packages (`.love`, Windows `.exe`, web) and pushes them ALL to itch.io in one command.

**Usage:**

```bash
# Full build + deploy (most common)
node deploy.js --version 1.0.1

# Preview what would happen (safe to run anytime)
node deploy.js --dry-run

# Build only, don't push to itch.io
node deploy.js --build-only

# Deploy existing build artifacts without rebuilding
node deploy.js --deploy-only --version 1.0.2

# Only build and deploy the web version
node deploy.js --web --version 1.0.1

# Only build and deploy the Windows version
node deploy.js --win --version 1.0.1
```

**What it does internally:**

```
Preflight Checks
  ├── Verify butler installed + logged in
  ├── Verify LOVE2D installation (for Windows build)
  ├── Verify Node.js (for web build)
  └── Verify source files exist

Build Phase
  ├── [1] Create .love file (zip main.lua + conf.lua + src/)
  ├── [2] Create Windows exe (fuse love.exe + .love, copy DLLs)
  └── [3] Create web version (run build_web.js, patches conf.lua)

Deploy Phase
  ├── butler push build/web → username/game:html5
  ├── butler push build/game-win64 → username/game:windows
  └── butler push build/game.love → username/game:love
```

**Configuration** — edit the `CONFIG` object at the top of `deploy.js`:

```javascript
const CONFIG = {
    ITCH_USER: 'your-username',    // Your itch.io username
    ITCH_GAME: 'your-game',        // Your game's URL slug
    CHANNELS: {
        web:  'html5',             // Channel name for web build
        win:  'windows',           // Channel name for Windows build
        love: 'love',              // Channel name for .love package
    },
    LOVE_DIR:    'C:\\Program Files\\LOVE',
    BUTLER_PATH: 'D:\\tools\\butler\\butler.exe',
    GAME_NAME:   'your-game',
    SRC_FILES:   ['main.lua', 'conf.lua', 'src'],
};
```

### Step 4: First-Time itch.io Page Configuration

After the first butler push, you must configure each upload **once** in the itch.io web interface:

1. Go to your game's Edit page → Uploads section
2. For the `html5` channel zip: check **"This file will be played in the browser"**
3. For the `windows` channel zip: set Executable → **Windows**
4. For the `love` channel zip: set to **Other**
5. Set Embed options: **Embed in page**, Viewport **640 x 480**

> After this one-time setup, all subsequent `butler push` / `node deploy.js` commands will update the files in-place — no page configuration needed.

> **PITFALL #12: Duplicate uploads from manual + butler**
>
> If you initially uploaded files manually through the browser and then switch to butler, you'll end up with **duplicate entries** — the old manual uploads and the new butler-managed uploads side by side. butler creates its own upload slots (named `<game>-<channel>.zip`), it does NOT replace manually uploaded files.
>
> **Fix:** After switching to butler, delete all the old manually-uploaded files from the itch.io Uploads page. Keep only the butler-managed entries. You can identify butler uploads by their naming pattern: `your-game-html5.zip`, `your-game-windows.zip`, etc.

### Step 5: Fill in Details

**Description:** Use Markdown. Include:
- What the game is (1-2 sentences)
- How to play (controls list)
- Features
- Credits

**Genre:** Pick the most relevant (Puzzle, Platformer, etc.)

**Tags:** Up to 10. Choose keywords players would search for:
```
physics, puzzle, retro, pixel-art, love2d, singleplayer, short, casual
```

**AI disclosure:** If you used AI tools during development, select "Yes".

**Cover image:** 630x500 pixels recommended. Take a screenshot of your most visually interesting level.

**Screenshots:** Upload 3-5 screenshots showing different parts of the game.

### Step 6: Publish

Set visibility to **Public** and save. Your game is now live!

### Step 7: Test the Live Version

**Always test the deployed web version.** Many issues only appear on itch.io's servers:
- Memory errors (see Pitfall #5 and #6)
- File loading errors (see Pitfall #7)
- Version compatibility warning dialog (see Pitfall #11)
- Duplicate upload confusion (see Pitfall #12)
- Audio issues
- Keyboard input focus issues

### Ongoing Updates

Once everything is configured, the update workflow is just one command:

```bash
# Make changes to your game code, then:
node deploy.js --version 1.0.2

# That's it. All three channels updated. Go to your game page and verify.
```

butler's incremental patching means only the changed bytes are uploaded. A typical code-only update pushes just a few KB instead of the full 9 MB.

---

## 9. Pitfalls & Fixes (Lessons Learned)

Here is every pitfall we encountered during development, in chronological order:

### Development Phase

| # | Pitfall | Symptom | Fix |
|---|---------|---------|-----|
| 1 | Missing `t.identity` in conf.lua | Save directory uses default name | Always set `t.identity = "your-game"` |
| 2 | Modifying physics bodies in collision callbacks | Crash or undefined behavior | Queue operations, execute after `world:update(dt)` |
| 3 | Overlapping static body and kinematic door | Door doesn't open or physics glitches | Leave a gap in the wall geometry for the door |
| 4 | Zipping the parent folder instead of contents | "No code to run" when opening .love file | Ensure main.lua is at the zip root, not in a subfolder |

### Web Build Phase

| # | Pitfall | Symptom | Fix |
|---|---------|---------|-----|
| 5 | `TOTAL_MEMORY` too small (64 MB) | "Cannot enlarge memory arrays" crash | Set to at least 256 MB: `1024*1024*256` |
| 6 | `TOTAL_STACK` equal to `TOTAL_MEMORY` | Same crash as above (stack eats all heap) | Set TOTAL_STACK to 8 MB, TOTAL_MEMORY to 256 MB |
| 7 | Embedding .love file as a single binary blob | "No code to run — Make sure main.lua is at the top level" | Embed each file individually with `FS.createDataFile` per file |

### Deployment Phase

| # | Pitfall | Symptom | Fix |
|---|---------|---------|-----|
| 8 | Not setting itch.io viewport dimensions | Game canvas is squished or wrong size | Set viewport to match your game resolution (e.g. 640x480) |
| 9 | Forgetting to check "played in browser" | Web zip appears as a download instead of embedded player | Check the checkbox on the upload |
| 10 | Not testing the live itch.io build | Works locally but crashes on itch.io | Always test the deployed version in browser after uploading |
| 11 | `conf.lua` declares LOVE 11.4, but love.js is 0.11.0 | Browser popup: "Compatibility Warning — version '11.4' ... running version (0.11.0)" | Patch `conf.lua` during web build to remove `t.version` line |
| 12 | Duplicate uploads after switching from manual to butler | Two copies of each file in itch.io Uploads page, confusion about which is active | Delete old manual uploads, keep only butler-managed entries |

---

## 10. Project Structure Reference

Here is the complete structure of Slime Split as a reference:

```
slime-split/                          # 23 Lua files, zero external dependencies
├── main.lua                          # Entry point: dispatches love callbacks to state manager
├── conf.lua                          # Window 640x480, physics enabled, identity set
├── run.bat                           # "C:\Program Files\LOVE\love.exe" .
├── build.bat                         # Creates .love and Windows .exe
├── build_web.js                      # Node.js script: builds web version (love.js)
├── deploy.js                         # One-click build + deploy to itch.io via butler
│
├── src/
│   ├── states/
│   │   ├── state_manager.lua         # Simple table-driven state machine
│   │   ├── menu.lua                  # Title screen + level select
│   │   ├── gameplay.lua              # Main loop: input → physics → deferred ops → camera → draw
│   │   ├── pause.lua                 # Pause overlay (Resume / Restart / Quit)
│   │   └── level_complete.lua        # Victory screen
│   │
│   ├── entities/
│   │   ├── slime.lua                 # Circle body + squash/stretch + vertex wobble + eyes
│   │   ├── slime_manager.lua         # Split/merge queue, selection cycling, mass conservation
│   │   ├── block.lua                 # Pushable crate (heavy dynamic body)
│   │   ├── pressure_plate.lua        # Sensor tracking cumulative mass, triggers linked door
│   │   ├── door.lua                  # Kinematic body that slides open/closed
│   │   └── exit.lua                  # Sensor with pulsing golden star animation
│   │
│   ├── systems/
│   │   ├── physics.lua               # Box2D world, collision callbacks
│   │   ├── camera.lua                # Smooth follow with bounds clamping + integer snapping
│   │   ├── particles.lua             # Split burst / merge gather / landing dust particles
│   │   └── input.lua                 # Keyboard abstraction (arrows + WASD)
│   │
│   ├── levels/
│   │   ├── level_defs.lua            # 5 levels as pure data tables
│   │   └── level_loader.lua          # Instantiates all entities from level data
│   │
│   ├── ui/
│   │   ├── hud.lua                   # Top bar (level name, slime count, mass)
│   │   └── transition.lua            # Fade in/out between states
│   │
│   └── lib/
│       ├── utils.lua                 # lerp, distance, clamp, sign, round
│       └── colors.lua                # PICO-8-inspired retro color palette
│
└── build/
    ├── slime-split.love              # Cross-platform LOVE package (21 KB)
    ├── slime-split-web.zip           # Web build for itch.io upload (2.3 MB)
    ├── slime-split-win64.zip         # Windows standalone for itch.io (4.3 MB)
    ├── love.js.cache                 # Cached love.js runtime (9 MB, not uploaded)
    ├── web/
    │   ├── index.html                # Web page with canvas + click-to-play + progress bar
    │   └── slime-split.js            # love.js runtime + all game files as base64 (9 MB)
    └── slime-split-win64/
        ├── slime-split.exe           # Fused executable (love.exe + .love)
        └── *.dll                     # Required runtime DLLs
```

### Build Sizes

| Artifact | Size | Contents |
|----------|------|----------|
| `.love` file | 21 KB | Just your Lua source code in a zip |
| Web zip | 2.3 MB | love.js runtime (compressed) + base64 game data |
| Windows zip | 4.3 MB | Fused .exe + DLLs |
| Web JS (uncompressed) | 9.0 MB | love.js is large because it's an entire game engine compiled to JS |

---

## Quick Reference: Build & Deploy Commands

```bash
# === Development ===
# Run your game locally:
"C:\Program Files\LOVE\love.exe" .

# === One-Click Build + Deploy (recommended) ===
node deploy.js --version 1.0.1            # Build all + push all to itch.io
node deploy.js --dry-run                   # Preview without pushing
node deploy.js --web --version 1.0.1       # Web only
node deploy.js --win --version 1.0.1       # Windows only
node deploy.js --build-only                # Build only, no deploy
node deploy.js --deploy-only --version 1.0.2  # Push existing builds

# === Manual Build (without deploy.js) ===
# Build .love:
powershell Compress-Archive -Path main.lua,conf.lua,src -DestinationPath build/my-game.zip -Force
mv build/my-game.zip build/my-game.love

# Build Windows exe:
copy /b "C:\Program Files\LOVE\love.exe"+build\my-game.love build\my-game-win64\my-game.exe
copy "C:\Program Files\LOVE\*.dll" build\my-game-win64\

# Build web version:
node build_web.js

# === Manual butler Push (without deploy.js) ===
butler push build/web              your-username/your-game:html5    --userversion 1.0.0
butler push build/my-game-win64    your-username/your-game:windows  --userversion 1.0.0
butler push build/my-game.love     your-username/your-game:love     --userversion 1.0.0

# === butler Utilities ===
butler login                               # One-time OAuth login
butler status your-username/your-game      # Check all channels
butler version                             # Print butler version
```

---

## Further Resources

- [LOVE2D Wiki](https://love2d.org/wiki/Main_Page) — Official documentation
- [LOVE2D Forums](https://love2d.org/forums/) — Community support
- [LÖVE Web Builder](https://schellingb.github.io/LoveWebBuilder/) — Online web build tool (alternative to our script)
- [2dengine/love.js](https://github.com/2dengine/love.js/) — love.js fork supporting LOVE 11.3/11.4/11.5
- [butler Manual](https://itch.io/docs/butler/) — itch.io CLI tool documentation
- [butler Source (GitHub)](https://github.com/itchio/butler) — Open-source, MIT license
- [itch.io Documentation](https://itch.io/docs/) — Publishing guides
- [Box2D Manual](https://box2d.org/documentation/) — Physics engine reference

---

*This tutorial was written based on the real development of [Slime Split](https://github.com/), a LOVE2D physics puzzle game. Every pitfall listed was encountered and resolved during actual development and deployment.*
