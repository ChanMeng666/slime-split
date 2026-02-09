-- All level definitions as pure data tables
-- Coordinates are in world pixels. (0,0) is top-left of level.
--
-- Wall format: {x, y, w, h}
-- Slime spawn: {x, y, mass}
-- Block: {x, y, w, h}
-- PressurePlate: {x, y, w, threshold, door_id}
-- Door: {x, y, w, h, id}
-- Exit: {x, y, w, h}
--
-- Slime radius = 16 * sqrt(mass)
--   mass=4 → radius=32, diameter=64
--   mass=2 → radius≈22.6, diameter≈45
--   mass=1 → radius=16, diameter=32

local levels = {
    -- Level 1: First Steps (movement + jump tutorial)
    {
        name = "First Steps",
        bounds = {0, 0, 640, 480},
        slimes = {
            {80, 380, 4},
        },
        walls = {
            -- Floor
            {0, 430, 640, 50},
            -- Left wall
            {0, 0, 20, 480},
            -- Right wall
            {620, 0, 20, 480},
            -- Ceiling
            {0, 0, 640, 20},
            -- Platforms for simple jumping
            {160, 370, 120, 16},
            {340, 320, 100, 16},
            {500, 370, 100, 16},
        },
        exit = {555, 320, 40, 50},
        blocks = {},
        doors = {},
        plates = {},
    },

    -- Level 2: Narrow Gap (learn to split)
    -- The wall has a narrow passage near the floor.
    -- Mass=4 slime (radius=32) can't fit, must split to mass=2 (radius≈23) to fit gap height ~50px
    {
        name = "Narrow Gap",
        bounds = {0, 0, 800, 480},
        slimes = {
            {100, 380, 4},
        },
        walls = {
            -- Floor
            {0, 430, 800, 50},
            -- Left wall
            {0, 0, 20, 480},
            -- Right wall
            {780, 0, 20, 480},
            -- Ceiling
            {0, 0, 800, 20},
            -- Dividing wall with narrow gap near floor
            -- Wall top: y=20, wall bottom: y=380 (height=360)
            -- Gap: y=380 to y=430 = 50px tall. Split slime diameter≈45 fits; full slime diameter=64 does not.
            {370, 20, 30, 360},
            -- Hint text platform on left side
            {100, 340, 100, 16},
        },
        exit = {680, 380, 40, 50},
        blocks = {},
        doors = {},
        plates = {},
    },

    -- Level 3: Heavy Duty (split through gap, merge on other side to push block)
    {
        name = "Heavy Duty",
        bounds = {0, 0, 960, 480},
        slimes = {
            {80, 380, 4},
        },
        walls = {
            -- Floor
            {0, 430, 960, 50},
            -- Left wall
            {0, 0, 20, 480},
            -- Right wall
            {940, 0, 20, 480},
            -- Ceiling
            {0, 0, 960, 20},
            -- Dividing wall with gap (same as level 2)
            {340, 20, 30, 360},
            -- Right side: raised platform with block on it, blocks the exit
            -- The block sits on this ledge and must be pushed right off it
            {600, 390, 160, 40},
            -- Small wall right of the ledge to stop the block (exit is beyond)
            {820, 390, 20, 40},
        },
        exit = {870, 380, 40, 50},
        blocks = {
            {640, 348, 40, 42}, -- on the raised platform
        },
        doors = {},
        plates = {},
    },

    -- Level 4: Weight Bearing (pressure plate + door puzzle)
    -- Split: one stays on pressure plate (mass >= 2), other goes through opened door
    {
        name = "Weight Bearing",
        bounds = {0, 0, 800, 480},
        slimes = {
            {80, 380, 4},
        },
        walls = {
            -- Floor
            {0, 430, 800, 50},
            -- Left wall
            {0, 0, 20, 480},
            -- Right wall
            {780, 0, 20, 480},
            -- Ceiling
            {0, 0, 800, 20},
            -- Left chamber floor raised section (for pressure plate)
            {200, 400, 140, 30},
            -- Middle wall divider (with gap for door)
            {420, 20, 20, 330},   -- wall above door (y=20 to y=350)
            -- Right chamber: the door is in the divider wall
            -- A platform in the right chamber leading to exit
            {500, 350, 120, 16},
            {660, 300, 100, 16},
        },
        exit = {700, 250, 40, 50},
        blocks = {},
        doors = {
            {420, 350, 20, 80, "door1"}, -- door in the divider wall near floor level
        },
        plates = {
            {220, 392, 80, 2, "door1"}, -- on raised floor, needs mass >= 2
        },
    },

    -- Level 5: Divide and Conquer (3 rooms, multi-step puzzle)
    -- Start with mass=6. Need to split strategically across 3 rooms.
    -- Room 1 → gap → Room 2 (has plate for door1 in Room 3) → gap → Room 3 (has plate for door2, exit behind door1)
    {
        name = "Divide and Conquer",
        bounds = {0, 0, 1200, 520},
        slimes = {
            {80, 440, 6},
        },
        walls = {
            -- Floor
            {0, 480, 1200, 40},
            -- Left wall
            {0, 0, 20, 520},
            -- Right wall
            {1180, 0, 20, 520},
            -- Ceiling
            {0, 0, 1200, 20},

            -- Wall 1-2 divider (gap near floor)
            -- Gap: y=420 to y=480 = 60px. Need to split (mass 3 → radius≈27.7, dia≈55 fits in 60)
            {360, 20, 30, 400},

            -- Wall 2-3 divider (gap near floor)
            {750, 20, 30, 400},

            -- Room 1: platforms
            {120, 400, 100, 16},

            -- Room 2: has a raised plate area + platforms
            {420, 380, 120, 16},
            {560, 430, 100, 50}, -- raised floor for plate area

            -- Room 3: platforms + door barrier
            {830, 370, 120, 16},
            {1000, 320, 100, 16},
            -- Barrier wall in room 3 (door goes here)
            {1050, 200, 20, 120},
        },
        exit = {1100, 270, 50, 50},
        blocks = {},
        doors = {
            {1050, 320, 20, 60, "door1"}, -- blocks path to exit in room 3
        },
        plates = {
            {570, 422, 80, 3, "door1"}, -- in room 2, needs mass >= 3 to open door in room 3
        },
    },
}

return levels
