# Game feel for Last One Bouncing

Research notes and starting numbers for movement, bouncing and bumping. Units are
world units (1 unit ≈ 1 m; the bouncer capsule is 1.5 tall, the arena radius is 8)
and seconds. Everything here is a **starting point to playtest**, not a law. The
numbers map onto constants in `scripts/physics_tuning.gd`.

Sources are cited from memory of the talks and books; the Celeste figures come from
its published movement code and talks. Where a number is my own judgment for this
game, it says "ours".

## Principles

1. **Respond within a tenth of a second, and keep control.** Game feel is real-time
   control, a simulated space with believable physics, and polish on top; the
   most important part is that input produces a visible response fast
   (Steve Swink, *Game Feel*, 2008). So: reach top speed in about 0.1 s, stop in
   about the same, and never let a physics effect take steering away for long.
2. **Define the jump by height and time, not by velocity and gravity.** Pick the
   apex height `h` and the time to apex `t`, then derive `g = 2h / t²` and
   `v0 = 2h / t` (Kyle Pittman, "Building a Better Jump", GDC 2016). This makes
   the jump tunable in terms a designer can feel.
3. **Floaty up, snappy down.** Rise with lower gravity, fall with a multiplier
   (about 1.5–2×). Add reduced gravity near the apex while jump is held for a
   moment of hang time, and a terminal fall speed (Pittman; Celeste uses half
   gravity near the apex and a fast-fall cap, Maddy Thorson, Celeste source and
   talks).
4. **Forgiveness beats strictness.** Coyote time (a short window to jump after
   leaving a ledge) and jump buffering (a jump pressed just before landing still
   counts) are about 0.1 s each in Celeste. Here the buffer *is* the timed-bounce
   mechanic: pressing jump just before landing gives the bigger bounce.
5. **Variable jump height.** Releasing jump early cuts upward speed (Celeste holds
   jump for up to about 0.2 s; Mario-style games do the same). Gives players
   control over where they land, which matters on an arena with an edge.
6. **Strong air control.** Celeste's air acceleration is about 65% of its ground
   acceleration; party brawlers go higher. For us steering the landing is the
   core skill, so air accel is at least 80% of ground accel.
7. **Impulses must be fought with input, not locked out.** Knockback should be
   folded into the player's velocity so ordinary steering and friction handle it,
   with a brief reduced-control window after a hit. Long drag on a separate
   "knockback" vector feels like wind you cannot steer against (a bug we hit).
8. **Bouncy surfaces add speed only when the player does the timing.** A passive
   bounce returns a fraction of the fall speed (coefficient of restitution < 1);
   a well-timed press adds a fixed boost on top. Chained timed bounces then climb
   toward a fixed point, so a few good bounces launch high but it is capped.
   (Common in Mario-style trampolines: holding or timing jump gives extra height.)
9. **Juice sells the impact.** Squash-and-stretch, screen shake, particles,
   sound and a freeze at the moment of impact make identical physics feel far
   better ("Juice it or lose it", Martin Jonasson and Petri Purho, 2012; "The Art
   of Screenshake", Jan Willem Nijman / Vlambeer, 2013).
10. **Hitstop (hit freeze) makes bumps feel heavy.** Fighting games freeze the
    action for roughly 3–8 frames (50–130 ms) on impact; bigger hits freeze longer.
    Keep it short and never stack it.
11. **Knockback scales with how hard you hit.** Smash-style and party brawlers
    make launch distance depend on hit strength, so a fast slam is dramatic and a
    nudge is a nudge. Use closing speed, plus a bonus for coming down from height.
12. **Cushion, not springboard (current direction from Oron).** The floor sinks
    under a landing, then gives back *less* energy than it received. Small drops
    barely bounce, big drops pop gently, and only a timed jump gets a real launch.

## Starting numbers

| Thing | Value | Notes |
| --- | --- | --- |
| Move speed | 6.0 u/s | Current. Crossing the arena (16 u) takes about 2.7 s. |
| Time to full speed (ground) | 0.12 s | `GROUND_ACCEL` = 6 / 0.12 = **50** |
| Time to stop (ground) | 0.09 s | decel = 6 / 0.09 ≈ **65** (a bit snappier than accel) |
| Air accel | 40 | about 80% of ground; air top speed same as ground |
| Jump apex height / time | 2.0 u / 0.40 s | `RISE_GRAVITY` = 2·2/0.4² = **25**, `JUMP_VELOCITY` = 2·2/0.4 = **10** |
| Fall gravity multiplier | 1.6 (so 40) | Falling takes about 0.32 s from apex |
| Apex hang | gravity ×0.5 while \|vy\| < 2 and jump held | about 0.1 s extra float |
| Terminal fall speed | 25 u/s | |
| Variable jump | releasing jump cuts upward speed to 45% | |
| Coyote time | 0.10 s | |
| Jump buffer / timed-bounce window | 0.12 s | matches `JUMP_BUFFER_SECONDS` |
| Cushion sink depth | 0.03 × impact speed, clamp 0.12–0.40 u | visual and collision give |
| Cushion sink time / rebound time | 0.10 s / 0.12 s | spring with heavy damping |
| Passive rebound | `BOUNCE_RATIO` **0.5** of impact speed, none below impact 4 | height ≈ 25% of the drop |
| Timed-bounce boost | +4.5 u/s on top of the rebound, cap 15 | `TIMED_BOUNCE_BONUS`, `MAX_TIMED_BOUNCE_VELOCITY` |
| Timed chain ceiling | v → 0.5·v + 4.5 converges to 9 | about 1.6 u of apex at g=25; a good chain, not infinite |
| Bump knockback | `0.55 × closing speed + 0.2 × fall speed`, clamp 15 | `HIT_SPEED_SCALE`, `HIT_FALL_SCALE`, `HIT_MAX_IMPULSE` |
| Knockback decay | fold into velocity; drag so it fades in **≈0.5 s** | if kept separate, `KNOCKBACK_DRAG` ≈ 12 |
| Control after a hit | accel ×0.3 for 0.2 s, full control by 0.6 s | |
| Dash | impulse 8, cooldown 1.0 s | current values are fine |
| Ground-pound | slam down at 25 u/s, shock radius 3, impulse 10 | not built yet |
| Rim | reflect outward speed × 0.8 once, no big constant | high-speed hits (≥10 u/s) can clear it |
| Hitstop | 0.05 s normal bump, 0.09 s slam, max 0.12 s | `Fx.hitstop`, do not stack |
| Camera shake | 0.15 big landing, 0.35 bump, 0.6 slam; fades in 0.25 s | `camera.shake` (0–1) |
| Squash on landing | y-scale 1 − 0.35 × (impact/15), recover over 0.15 s | `_visual.land(impact)` |
| Stretch on launch | y-scale 1.25 for 0.12 s | `_visual.launch(strength)` |
| Landing thump | volume ∝ impact, short low sound | `Sfx.play(self, "land", …)` |

Check the cushion rule with a smoke test: a drop from jump height must never
rebound above 60% of the drop height without a timed jump.

## Playtest checklist

Play the real web build, keyboard first, then touch.

- [ ] Walking from rest reaches full speed almost instantly; releasing keys stops
  you in about a tenth of a second (no sliding, no "ice").
- [ ] You can hold toward the rim for 3 s and never feel pushed backward by an
  invisible force; letting go ends all motion within 0.5 s.
- [ ] Jump feels floaty on the way up and quicker on the way down; a short tap
  gives a short hop.
- [ ] You can steer your landing in the air by roughly 2–3 units.
- [ ] A plain landing sinks and gives a small, soft rebound; a drop from jump
  height never springs back higher than about 60%.
- [ ] Pressing jump just before landing clearly gives a bigger bounce; three timed
  bounces in a row reach noticeably higher, but not out of control.
- [ ] Mistimed presses do not feel punished (the buffer is forgiving).
- [ ] A bump from a slow walk is a small shove; a dash or a slam sends the other
  bouncer flying, and you can see why.
- [ ] After being hit you regain steering within about 0.6 s.
- [ ] The rim pushes you back softly but a hard hit can still clear it.
- [ ] Landing shows squash, a dent, puffs and a thump; big bumps add a short
  freeze and a small shake; nothing makes you queasy.
- [ ] A round against the bots reaches a winner in about 30–60 s.
- [ ] Restart (R, or the touch button) is instant; sound starts after the first
  tap or key press in a browser.
- [ ] Frame rate stays smooth in a browser on a laptop; note it if not.

## Sources

- Steve Swink, *Game Feel: A Game Designer's Guide to Virtual Sensation* (2008).
- Martin Jonasson and Petri Purho, "Juice it or lose it", Nordic Game 2012 (talk).
- Kyle Pittman, "Math for Game Programmers: Building a Better Jump", GDC 2016.
- Maddy Thorson / Extremely OK Games, Celeste (player movement source and talks):
  run accel, apex half gravity, coyote and jump-buffer windows, variable jump.
- Jan Willem Nijman (Vlambeer), "The Art of Screenshake" (2013, talk).
- Fighting-game hitstop practice and Smash-style knockback: community frame-data
  documentation; treat the frame counts above as approximate.
