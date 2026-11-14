# Project Progress

## Completed Features
- Setup Godot 4.1.3 project structure and 3D environment ("Sterile Doctor's Office")
- Initialized project repositories, unit tests (GUT framework), and CI/CD workflows
- Defined game mechanics, math utilities, and level outlines
- Global Game State management (`GameState` singleton with stress tracking and signals)
- UI Manager (`UIManager`) and Game HUD (Stress bar, level indicator, win/lose overlays)
- Level Manager (`LevelManager`) for level routing and transitions
- Base Level template (`BaseLevel`)
- Base Enemy and Projectile templates
- "Skinny Guy" ragdoll physics model
- Level 1: Olfactory (Smell) - QWER/AD finger & arm controls with speed/proximity stress tracking
- Level 2: Optic (Vision) - Independently steered eyeballs (WASD / Arrows / gamepad sticks) read a shaky Snellen chart with double vision
- Level 3: Eye Movement - QWOP/OP arm controls tracing 'H' pattern
- Level 4: Trigeminal (Sensation) - Sharp/Soft facial sensation test with severe mouse lag
- Level 5: Facial Nerve (Expression) - Face muscle group controls (1-0 keys) to match facial expressions
- Level 6: Vestibulocochlear (Hearing) - Power meter timing & floaty tuning fork placement
- Level 7: Gag Reflex (IX & X) - WASD arm + mouse-angled tongue depressor in a randomly snapping mouth
- Level 8: Accessory (XI) - Mouse-button doctor pressure vs arrow-key patient resistance (shrug + head turns)
- Level 9: Hypoglossal (XII) - Mouse-guided spring-physics tongue that drifts to one side, five hold targets
- GUT test suite runs in CI
- Shared code-drawn art (PatientKit): exam-room backdrop and an expressive patient used by all 9 levels

## In-Progress Features
- Wiring the shared `UIManager` HUD, 3D doctor's office backdrop, and ragdoll characters into the levels (levels currently use the 2D PatientKit exam room)
- "The Thick Girl" physics model and jiggle physics
- ASMR audio soundscape, deadpan dialogue, and absurdist SFX
- "Window of Distraction" environmental vignettes

## Blockers
- None at this time.
