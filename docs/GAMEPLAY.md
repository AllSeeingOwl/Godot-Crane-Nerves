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
    *   **Mechanic:** Likely involves showing an eye chart and managing the patient's focus or lighting.

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

*   **Level 8: Accessory (Neck/Shoulder Strength)**
    *   **Objective:** Test resistance.
    *   **Mechanic:** Applying opposing force to the patient's movements. Applying unbalanced force fails the test.

*   **Level 9: Hypoglossal (Tongue Movement)**
    *   **Objective:** Examine the tongue.
    *   **Mechanic:** Similar precision mechanics to Level 7, requiring steady hands.

*   **Levels 10-12: The Crisis and Debrief**
    *   These levels represent narrative escalations, total systemic failures ("The Crisis"), and the aftermath ("Night Shift", "The Debrief"). Mechanics here become more chaotic or narrative-focused.
