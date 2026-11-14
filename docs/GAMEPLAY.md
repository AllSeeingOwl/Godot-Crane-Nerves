# Gameplay and Mechanics

This document outlines the core game mechanics, rules, and player interactions for Godot-Crane-Nerves. It serves as a summary of the detailed logic found in the level-specific markdown files.

## Core Loop
1. The player acts as a doctor performing a 12-part cranial nerve exam on a patient.
2. The player must manipulate various medical tools using deliberately difficult, physics-based controls.
3. Every mistake, rough movement, or failure to perform tasks in time increases the patient's **Stress**.
4. **Win Condition:** Complete the specific objective for the current nerve exam before stress reaches 100.
5. **Lose Condition:** The patient's stress reaches 100, resulting in failure ("Patient got too stressed!").

## Global Mechanics

### Stress System
Stress is the primary resource the player must manage. It constantly fluctuates based on player actions.
- **Passive Stress:** Some levels may have a passive stress increase over time if the player is too slow.
- **Active Stress:** Bumping into the patient too hard with a tool, dropping items, or failing mini-games causes immediate spikes in stress.
- **Relief:** Successfully completing sub-tasks or using specific calming techniques (if available in a level) may reduce stress slightly.

### Physics-Based Controls
The game is heavily inspired by *QWOP* and *Surgeon Simulator*.
- Tools do not follow the mouse perfectly 1:1. They are manipulated using forces, torques, or joint constraints.
- Collisions with the patient's body (especially sensitive areas like the eyes or nose) have severe consequences.
- The environment (e.g., Doctor's Office) provides a 3D bounding box for interactions.

## Level Breakdown (The 12 Cranial Nerves)

*(Note: Detailed math and logic for these levels are found in their respective `0X_LevelX.md` files in the root directory).*

*   **Level 1: Olfactory (Smell)**
    *   **Objective:** Introduce scents to the patient's nose.
    *   **Mechanic:** Managing the distance and intensity of the smell. Too strong = high stress.

*   **Level 2: Optic (Vision)**
    *   **Objective:** Test visual acuity.
    *   **Mechanic:** You steer the patient's two eyeballs independently to read a shaky Snellen chart.
    *   **Controls:** Left eye W/A/S/D, right eye Arrow keys (or the two gamepad sticks). Each eye floats with momentum and slowly drifts outward.
    *   **Steps:** Hold both eyes on the highlighted letter for 0.8 seconds to read it, one letter per row from the top; letters get smaller and harder as you go down.
    *   **Double vision:** The "Patient's view" panel shows one copy of the chart per eye, shifted by that eye's aim error, so it only snaps sharp when both eyes converge.
    *   **Hazards:** The chart sways and jitters. Crossing the eyes too far or rolling them off the chart adds stress.

*   **Level 3: Oculomotor, Trochlear, Abducens (Eye Movement)**
    *   **Objective:** Test eye tracking.
    *   **Mechanic:** Moving an object (like a pen) smoothly. Jerky movements or moving out of the field of view increases stress.

*   **Level 4: Trigeminal (Facial Sensation)**
    *   **Objective:** Test facial sensitivity.
    *   **Mechanic:** Touching specific areas of the face with the correct tool (e.g., cotton swab vs. pin) without applying too much force.

*   **Level 5: Facial Nerve (Facial Expression)**
    *   **Objective:** Evaluate facial muscle strength.
    *   **Mechanic:** Observing and matching expressions or prompting the patient correctly.

*   **Level 6: Vestibulocochlear (Hearing/Tuning)**
    *   **Objective:** Test hearing using a tuning fork.
    *   **Mechanic:** Striking a tuning fork and placing it near the ear. Striking too hard or placing it poorly causes auditory distress.

*   **Level 7: Glossopharyngeal & Vagus (Gag Reflex)**
    *   **Objective:** Test the gag reflex.
    *   **Mechanic:** Highly volatile level. Inserting a tongue depressor. Precision is key; pushing too far causes massive stress and failure.
    *   **Controls:** W/A/S/D moves the doctor's floaty arm; the mouse steers the depressor angle (with lag).
    *   **Steps:** (1) Hold the tongue down gently for 1.5 seconds. (2) Gently touch the back of the throat to trigger the gag reflex.
    *   **Hazards:** The mouth twitches red and snaps shut at random intervals (being inside = *CHOMP*). Jabbing the lips, tickling the palate, squashing the tongue, or touching the throat too early or too hard all add stress. Pushing past the throat makes the patient vomit: instant Game Over.

*   **Level 8: Accessory (Neck/Shoulder Strength)**
    *   **Objective:** Test resistance.
    *   **Mechanic:** Applying opposing force to the patient's movements. Applying unbalanced force fails the test.
    *   **Controls:** You play both sides. Left/Right mouse button = the doctor presses on the patient's left/right side; Left/Right arrow = the patient pushes back on that side. Forces ramp up while held and fade when released.
    *   **Parts:** (1) Shoulder shrug, both sides at once. (2) Head turn left. (3) Head turn right. Each passes after holding steady (forces within 10 of each other, with the doctor pressing at least 40) for 2.5 seconds.
    *   **Hazards:** The patient's muscles twitch at random. Overpowering either way adds stress, as does pressing the shoulders unevenly. Overpowering the patient badly is an instant Game Over (*POP*, dislocated shoulder).

*   **Level 9: Hypoglossal (Tongue Movement)**
    *   **Objective:** Examine the tongue.
    *   **Mechanic:** Similar precision mechanics to Level 7, requiring steady hands.
    *   **Controls:** The mouse guides the tip of the patient's slimy, wobbly tongue, which follows on a soft spring and overshoots.
    *   **Steps:** Hold the tip still on five targets in order: stick it out, then left, right, left, right (0.6 seconds each).
    *   **Twist:** Like real XII nerve palsy, each patient's tongue drifts to one random side, so you have to aim against the drift.
    *   **Hazards:** Stretching past the tongue's reach or whipping it around (spit everywhere) adds stress. Curling it back into the throat makes the patient gurgle; too far and they swallow it: instant Game Over.

*   **Levels 10-12: The Crisis and Debrief**
    *   These levels represent narrative escalations, total systemic failures ("The Crisis"), and the aftermath ("Night Shift", "The Debrief"). Mechanics here become more chaotic or narrative-focused.
