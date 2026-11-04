extends RefCounted
## Gameplay tuning in world units and seconds. Initial values are provisional;
## replace them with playtested research-based values when those are ready.

const ARENA_RADIUS := 8.0
const OUT_HEIGHT := -0.8
const MOVE_SPEED := 6.0
const MOVE_ACCEL := 30.0
const JUMP_VELOCITY := 9.0
const GRAVITY := 22.0
const BOUNCE_RATIO := 0.58
const MIN_BOUNCE_VELOCITY := 5.0
const TIMED_BOUNCE_BONUS := 3.0
const MAX_TIMED_BOUNCE_VELOCITY := 16.0
const JUMP_BUFFER_SECONDS := 0.12
const KNOCKBACK_DRAG := 2.0
const DASH_IMPULSE := 8.0
const DASH_COOLDOWN := 1.0
const HIT_SPEED_SCALE := 0.55
const HIT_FALL_SCALE := 0.2
const HIT_MAX_IMPULSE := 15.0
const RIM_INSET := 0.55
const RIM_HEIGHT := 1.4
const RIM_BREAK_SPEED := 10.0
const RIM_REBOUND_SPEED := 7.0
const RIM_COOLDOWN := 0.35
const HIT_DISTANCE := 1.12
const HIT_COOLDOWN := 0.55
const HIT_IMPULSE := 6.5
const HIT_LIFT := 2.0
const HIT_VERTICAL_RANGE := 1.2
const BOT_THINK_SECONDS := 0.3
const BOT_EDGE_MARGIN := 2.0
const BOT_EDGE_STEER := 1.5
const BOT_JUMP_DISTANCE_SQUARED := 5.0
const BOT_JUMP_CHANCE := 0.2
