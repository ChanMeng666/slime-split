-- PICO-8 inspired retro palette
local Colors = {
    -- Background & environment
    bg          = {0.07, 0.07, 0.16, 1},    -- dark blue-black
    wall        = {0.33, 0.24, 0.18, 1},    -- brown
    wall_light  = {0.45, 0.34, 0.25, 1},    -- lighter brown
    ground      = {0.25, 0.20, 0.15, 1},    -- dark brown

    -- Slime
    slime       = {0.18, 0.80, 0.30, 1},    -- bright green
    slime_dark  = {0.10, 0.55, 0.20, 1},    -- dark green
    slime_light = {0.45, 0.95, 0.55, 1},    -- highlight green
    slime_eye   = {1.00, 1.00, 1.00, 1},    -- white
    slime_pupil = {0.10, 0.10, 0.15, 1},    -- near black

    -- UI & selection
    selected    = {1.00, 1.00, 0.40, 1},    -- yellow glow
    error_flash = {1.00, 0.20, 0.20, 1},    -- red flash

    -- Puzzle elements
    block       = {0.55, 0.40, 0.25, 1},    -- wood brown
    block_dark  = {0.40, 0.28, 0.18, 1},    -- dark wood
    plate       = {0.60, 0.60, 0.65, 1},    -- steel gray
    plate_on    = {0.40, 0.90, 0.40, 1},    -- green activated
    door        = {0.50, 0.35, 0.20, 1},    -- door brown
    door_frame  = {0.65, 0.50, 0.30, 1},    -- door frame
    exit_gold   = {1.00, 0.85, 0.20, 1},    -- golden
    exit_glow   = {1.00, 0.95, 0.50, 0.3},  -- golden glow

    -- Text
    text        = {0.90, 0.90, 0.95, 1},    -- off-white
    text_dim    = {0.50, 0.50, 0.55, 1},    -- dimmed
    text_title  = {0.18, 0.80, 0.30, 1},    -- green title

    -- Particles
    particle_split = {0.30, 1.00, 0.50, 1}, -- bright split
    particle_merge = {0.20, 0.70, 0.90, 1}, -- blue merge
    particle_land  = {0.60, 0.55, 0.45, 1}, -- dust
}

return Colors
