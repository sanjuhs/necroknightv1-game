-- Configuration file for game constants and enemy types
local Config = {}

-- Asset paths
Config.ASSETS_PATH_FREE = "assets/Tiny_Swords_Free_Pack/"
Config.ASSETS_PATH_ENEMY = "assets/Tiny_Swords_Enemy_Pack/Enemy Pack/"

-- Unit asset paths (Blue = Player/Allies, Red = Enemies)
Config.UNITS_BLUE_PATH = Config.ASSETS_PATH_FREE .. "Units/Blue Units/"
Config.UNITS_RED_PATH = Config.ASSETS_PATH_FREE .. "Units/Red Units/"

-- Specific unit paths
Config.WARRIOR_BLUE_PATH = Config.UNITS_BLUE_PATH .. "Warrior/"
Config.WARRIOR_RED_PATH = Config.UNITS_RED_PATH .. "Warrior/"
Config.ARCHER_BLUE_PATH = Config.UNITS_BLUE_PATH .. "Archer/"
Config.ARCHER_RED_PATH = Config.UNITS_RED_PATH .. "Archer/"
Config.LANCER_BLUE_PATH = Config.UNITS_BLUE_PATH .. "Lancer/"
Config.LANCER_RED_PATH = Config.UNITS_RED_PATH .. "Lancer/"
Config.MONK_BLUE_PATH = Config.UNITS_BLUE_PATH .. "Monk/"
Config.MONK_RED_PATH = Config.UNITS_RED_PATH .. "Monk/"
Config.PAWN_BLUE_PATH = Config.UNITS_BLUE_PATH .. "Pawn/"
Config.PAWN_RED_PATH = Config.UNITS_RED_PATH .. "Pawn/"

-- Building asset paths
Config.BUILDINGS_BLUE_PATH = Config.ASSETS_PATH_FREE .. "Buildings/Blue Buildings/"
Config.BUILDINGS_RED_PATH = Config.ASSETS_PATH_FREE .. "Buildings/Red Buildings/"

-- Terrain asset paths
Config.TERRAIN_PATH = Config.ASSETS_PATH_FREE .. "Terrain/"
Config.TILESET_PATH = Config.TERRAIN_PATH .. "Tileset/"
Config.TREES_PATH = Config.TERRAIN_PATH .. "Resources/Wood/Trees/"
Config.GOLD_PATH = Config.TERRAIN_PATH .. "Resources/Gold/Gold Stones/"

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
    maxHealth = 2000,
    attack = 150,
    speed = 200,
    attackRange = 80,
    attackCooldown = 0.8,
    collisionRadius = 32,
    maxRP = 10000,
    reviveCost = 30
}

-- ============================================================================
-- UNIT CLASS TYPES (Different unit classes with different abilities)
-- ============================================================================
Config.UNIT_CLASSES = {
    warrior = {
        name = "Warrior",
        frameWidth = 192,
        frameHeight = 192,
        offsetX = 96,
        offsetY = 144,
        maxHealth = 100,
        attack = 15,
        speed = 120,
        attackRange = 70,
        attackCooldown = 1.0,
        collisionRadius = 32,
        attackType = "melee",
        animations = {
            idle = { frames = 8 },
            run = { frames = 6 },
            attack1 = { frames = 4 },
            attack2 = { frames = 4 },
            guard = { frames = 6 }
        }
    },
    
    archer = {
        name = "Archer",
        frameWidth = 192,
        frameHeight = 192,
        offsetX = 96,
        offsetY = 160,  -- Adjusted: archer sprite is smaller, positioned lower in frame
        maxHealth = 60,
        attack = 12,
        speed = 130,
        attackRange = 250,  -- Ranged!
        attackCooldown = 1.8,
        collisionRadius = 24,
        attackType = "ranged",
        projectileSpeed = 500,
        animations = {
            idle = { frames = 6 },
            run = { frames = 4 },
            attack1 = { frames = 8 }  -- Shoot animation
        }
    },
    
    lancer = {
        name = "Lancer",
        frameWidth = 192,  -- Use 192 not 320 for consistency
        frameHeight = 192,
        offsetX = 96,
        offsetY = 144,
        maxHealth = 120,
        attack = 20,
        speed = 100,
        attackRange = 100,  -- Longer melee range (lance)
        attackCooldown = 1.3,
        collisionRadius = 30,
        attackType = "melee",
        animations = {
            idle = { frames = 6 },
            run = { frames = 4 },
            attack1 = { frames = 4 }
        }
    },
    
    monk = {
        name = "Monk",
        frameWidth = 192,
        frameHeight = 192,
        offsetX = 96,
        offsetY = 160,  -- Adjusted: monk sprite is smaller, positioned lower in frame
        maxHealth = 70,
        attack = 5,
        speed = 110,
        attackRange = 60,
        attackCooldown = 2.0,
        collisionRadius = 24,
        attackType = "heal",  -- Special: heals allies
        healAmount = 30,
        healRange = 180,
        healCooldown = 4.0,
        animations = {
            idle = { frames = 6 },
            run = { frames = 4 },
            attack1 = { frames = 11 }  -- Heal animation
        }
    },
    
    pawn = {
        name = "Pawn",
        frameWidth = 192,
        frameHeight = 192,
        offsetX = 96,
        offsetY = 160,  -- Adjusted: pawn sprite is smaller
        maxHealth = 40,
        attack = 5,
        speed = 100,
        attackRange = 50,
        attackCooldown = 1.5,
        collisionRadius = 20,
        attackType = "worker",  -- Can collect resources
        gatherSpeed = 1.0,  -- Resources per second
        carryCapacity = 10,
        animations = {
            idle = { frames = 8 },
            run = { frames = 6 },
            attack1 = { frames = 6 }  -- Work/interact animation
        }
    }
}

-- ============================================================================
-- UNIT TYPE VARIANTS (Special versions of each class)
-- ============================================================================
Config.UNIT_VARIANTS = {
    -- Archer variants
    archer_normal = {
        name = "Archer",
        baseClass = "archer",
        maxHealth = 60,
        attack = 12,
        speed = 130,
        outline = nil,
        scale = 1.0
    },
    archer_sniper = {
        name = "Sniper",
        baseClass = "archer",
        maxHealth = 50,
        attack = 20,
        speed = 100,
        attackRange = 350,
        attackCooldown = 2.5,
        projectileSpeed = 700,
        outline = {0.2, 0.8, 0.2, 0.8},  -- Green
        scale = 1.0
    },
    archer_rapid = {
        name = "Rapid Archer",
        baseClass = "archer",
        maxHealth = 45,
        attack = 8,
        speed = 150,
        attackCooldown = 0.8,
        outline = {1, 0.9, 0.2, 0.8},  -- Yellow
        scale = 0.9
    },
    
    -- Lancer variants
    lancer_normal = {
        name = "Lancer",
        baseClass = "lancer",
        maxHealth = 120,
        attack = 20,
        speed = 100,
        outline = nil,
        scale = 1.0
    },
    lancer_knight = {
        name = "Knight",
        baseClass = "lancer",
        maxHealth = 180,
        attack = 25,
        speed = 80,
        outline = {0.7, 0.2, 0.9, 0.8},  -- Purple
        scale = 1.15
    },
    lancer_cavalry = {
        name = "Cavalry",
        baseClass = "lancer",
        maxHealth = 100,
        attack = 18,
        speed = 160,
        outline = {1, 0.5, 0.2, 0.8},  -- Orange
        scale = 1.1
    },
    
    -- Monk variants
    monk_normal = {
        name = "Monk",
        baseClass = "monk",
        maxHealth = 70,
        healAmount = 30,
        healRange = 180,
        healCooldown = 4.0,
        outline = nil,
        scale = 1.0
    },
    monk_priest = {
        name = "Priest",
        baseClass = "monk",
        maxHealth = 90,
        healAmount = 50,
        healRange = 200,
        healCooldown = 3.0,
        outline = {0.9, 0.9, 0.3, 0.8},  -- Light yellow
        scale = 1.1
    },
    monk_battle = {
        name = "Battle Monk",
        baseClass = "monk",
        maxHealth = 100,
        attack = 15,
        healAmount = 20,
        healRange = 120,
        healCooldown = 5.0,
        outline = {0.8, 0.4, 0.2, 0.8},  -- Brown
        scale = 1.05
    }
}

-- Ally stats (revived enemies - base stats, modified by original type)
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

-- ============================================================================
-- BUILDING TYPES (Can be captured to recruit units)
-- ============================================================================
Config.BUILDING_TYPES = {
    barracks = {
        name = "Barracks",
        asset = "Barracks.png",
        width = 128,
        height = 160,
        captureTime = 5.0,  -- Seconds to capture
        unitType = "warrior",
        spawnCooldown = 30.0,  -- Seconds between spawns
        maxUnits = 3,  -- Max units this building can provide
        captureRadius = 80
    },
    
    archery = {
        name = "Archery Range",
        asset = "Archery.png",
        width = 160,
        height = 176,
        captureTime = 5.0,
        unitType = "archer",
        spawnCooldown = 35.0,
        maxUnits = 2,
        captureRadius = 90
    },
    
    monastery = {
        name = "Monastery",
        asset = "Monastery.png",
        width = 160,
        height = 192,
        captureTime = 6.0,
        unitType = "monk",
        spawnCooldown = 45.0,
        maxUnits = 1,
        captureRadius = 85
    },
    
    house = {
        name = "House",
        asset = "House1.png",
        width = 96,
        height = 112,
        captureTime = 3.0,
        unitType = "pawn",
        spawnCooldown = 20.0,
        maxUnits = 4,
        captureRadius = 60
    }
}

-- ============================================================================
-- RESOURCE TYPES (For Pawns to collect)
-- ============================================================================
Config.RESOURCE_TYPES = {
    gold = {
        name = "Gold",
        gatherTime = 2.0,  -- Seconds to gather 1 unit
        value = 10,  -- Gold value per unit
        color = {1, 0.85, 0.2}
    },
    wood = {
        name = "Wood",
        gatherTime = 1.5,
        value = 5,
        color = {0.6, 0.4, 0.2}
    }
}

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
    buildingColor = {0.8, 0.6, 0.2},
    backgroundColor = {0.1, 0.1, 0.1, 0.8},
    borderColor = {0.6, 0.5, 0.3}
}

return Config
