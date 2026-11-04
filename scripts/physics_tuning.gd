extends RefCounted
## Gameplay tuning in world units and seconds. Starting values follow PR #10
## game-feel research, with a minimum rebound retained for automatic bouncing.

const ARENA_RADIUS := 8.0
const OUT_HEIGHT := -0.8
const MOVE_SPEED := 6.0
const GROUND_ACCEL := 50.0
const GROUND_DECEL := 65.0
const AIR_ACCEL := 40.0
const JUMP_VELOCITY := 10.0
const RISE_GRAVITY := 25.0
const FALL_GRAVITY_MULTIPLIER := 1.6
const TERMINAL_FALL_SPEED := 25.0
const BOUNCE_RATIO := 0.5
const MIN_BOUNCE_VELOCITY := 5.0
const TIMED_BOUNCE_BONUS := 7.0
const MAX_TIMED_BOUNCE_VELOCITY := 15.0
const JUMP_BUFFER_SECONDS := 0.12
const HIT_CONTROL_FACTOR := 0.3
const HIT_CONTROL_SECONDS := 0.2
const DASH_IMPULSE := 8.0
const DASH_COOLDOWN := 1.0
const HIT_SPEED_SCALE := 0.55
const HIT_FALL_SCALE := 0.2
const HIT_MAX_IMPULSE := 15.0
const RIM_INSET := 0.55
const RIM_HEIGHT := 1.4
const RIM_BREAK_SPEED := 10.0
const RIM_RESTITUTION := 0.8
const RIM_COOLDOWN := 0.35
const HIT_DISTANCE := 1.12
const HIT_COOLDOWN := 0.55
const HIT_IMPULSE := 2.0
const HIT_LIFT := 2.0
const HIT_VERTICAL_RANGE := 1.2
const BOT_THINK_SECONDS := 0.3
const BOT_EDGE_MARGIN := 2.0
const BOT_EDGE_STEER := 1.5
const BOT_JUMP_DISTANCE_SQUARED := 5.0
const BOT_JUMP_CHANCE := 0.2
const BOT_DASH_DISTANCE_SQUARED := 16.0
const BOT_DASH_CHANCE := 0.3
