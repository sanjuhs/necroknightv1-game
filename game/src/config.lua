-- Configuration file for game constants and enemy types
local Config = {}

-- Asset paths
Config.ASSETS_PATH = "assets/Tiny_Swords_update_010/"

-- Game constants
Config.TILE_SIZE = 64
Config.ANIMATION_FPS = 10
Config.ANIMATION_FRAME_TIME = 1 / Config.ANIMATION_FPS

-- World settings
Config.WORLD_WIDTH = 50   -- tiles
Config.WORLD_HEIGHT = 50  -- tiles

-- Regeneration rates (points per second)
Config.HEALTH_REGEN_RATE = 0.25  -- 1 HP per 4 seconds
Config.RP_REGEN_RATE = 0.2       -- 1 RP per 5 seconds

-- Player base stats
Config.PLAYER_STATS = {
    maxHealth = 200,
    attack = 15,
    speed = 200,
    attackRange = 80,
    attackCooldown = 0.8,
    collisionRadius = 32,
    maxRP = 100,
    reviveCost = 30
}

-- Ally stats (revived enemies)
Config.ALLY_STATS = {
    maxHealth = 80,
    attack = 12,
    speed = 150,
    attackRange = 75,
    attackCooldown = 1.0,
    collisionRadius = 32,
    followDistance = 150
}

-- Enemy types with different stats and outline colors
Config.ENEMY_TYPES = {
    -- Normal enemy (no outline)
    normal = {
        name = "Normal",
        maxHealth = 100,
        attack = 10,
        speed = 100,
        attackRange = 70,
        attackCooldown = 1.2,
        aggroRange = 300,
        collisionRadius = 32,
        outline = nil,  -- No outline
        spawnWeight = 10  -- Higher = more common
    },
    
    -- Berserker - High attack, red outline
    berserker = {
        name = "Berserker",
        maxHealth = 80,
        attack = 25,
        speed = 120,
        attackRange = 65,
        attackCooldown = 0.8,
        aggroRange = 350,
        collisionRadius = 32,
        outline = {1, 0.2, 0.2, 0.8},  -- Red outline
        spawnWeight = 2
    },
    
    -- Tank - High health, green outline
    tank = {
        name = "Tank",
        maxHealth = 200,
        attack = 8,
        speed = 70,
        attackRange = 60,
        attackCooldown = 1.5,
        aggroRange = 250,
        collisionRadius = 40,
        outline = {0.2, 0.8, 0.2, 0.8},  -- Green outline
        spawnWeight = 2
    },
    
    -- Speedster - Fast movement, yellow outline
    speedster = {
        name = "Speedster",
        maxHealth = 60,
        attack = 12,
        speed = 180,
        attackRange = 70,
        attackCooldown = 1.0,
        aggroRange = 400,
        collisionRadius = 28,
        outline = {1, 0.9, 0.2, 0.8},  -- Yellow outline
        spawnWeight = 2
    },
    
    -- Elite - All-round strong, purple outline
    elite = {
        name = "Elite",
        maxHealth = 150,
        attack = 18,
        speed = 110,
        attackRange = 75,
        attackCooldown = 1.0,
        aggroRange = 350,
        collisionRadius = 35,
        outline = {0.7, 0.2, 0.9, 0.8},  -- Purple outline
        spawnWeight = 1
    }
}

-- Player outline color (golden)
Config.PLAYER_OUTLINE = {1, 0.85, 0.3, 0.9}  -- Bright golden

-- Ally outline color (cyan/blue)
Config.ALLY_OUTLINE = {0.3, 0.8, 1, 0.7}  -- Cyan

-- Upgrade station types
Config.UPGRADE_TYPES = {
    health = {
        name = "Health Shrine",
        stat = "maxHealth",
        increase = 20,
        cost = 50,  -- Gold or points
        color = {0.2, 0.8, 0.2}
    },
    attack = {
        name = "Attack Shrine",
        stat = "attack",
        increase = 3,
        cost = 50,
        color = {0.8, 0.2, 0.2}
    },
    speed = {
        name = "Speed Shrine",
        stat = "speed",
        increase = 20,
        cost = 50,
        color = {0.2, 0.6, 0.9}
    },
    rp = {
        name = "Soul Shrine",
        stat = "maxRP",
        increase = 20,
        cost = 40,
        color = {0.6, 0.2, 0.8}
    }
}

-- Mini-map settings
Config.MINIMAP = {
    width = 180,
    height = 180,
    margin = 10,
    fogRadius = 200,  -- Tiles revealed around player
    playerColor = {0.2, 0.8, 0.2},
    enemyColor = {0.8, 0.2, 0.2},
    allyColor = {0.3, 0.7, 1},
    treeColor = {0.1, 0.4, 0.1},
    upgradeColor = {1, 0.8, 0.2},
    backgroundColor = {0.1, 0.1, 0.1, 0.8},
    borderColor = {0.6, 0.5, 0.3}
}

return Config

