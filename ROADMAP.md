# Godot-Crane-Nerves: Project Roadmap

## 1. Vision and High-Level Goals
**Vision:** To create a physics-based comedy game where players perform a delicate 12-part cranial nerve exam on a patient with deliberately convoluted controls and extreme physics reactions. The game aims to capture the essence of nostalgic mid-2000s PC games and combine it with "ambient dread" and absurdist comedy.

**High-Level Goals:**
- Migrate the original React prototype successfully into Godot Engine (v4.x).
- Implement robust, comedic physics for character models ("The Skinny Guy", "The Thick Girl").
- Complete all 12 cranial nerve test levels with their unique control schemes.
- Finalize the audio soundscape focusing on ASMR elements and deadpan reactions.
- Polish the "Window of Distraction" mechanic to reinforce the ambient dread.
- Ensure automated CI/CD pipelines successfully build and test the game for Windows, macOS, Linux, and Web.

---

## 2. Milestones and Major Features

### Milestone 1: MVP (Minimum Viable Product)
**Estimated Timeline:** Weeks 1 - 4
**Focus:** Core systems and basic playable loop.
- **Features:**
  - Setup Godot project and basic project structure.
  - Implement basic 3D environment ("Sterile Doctor's Office").
  - Create the base "Skinny Guy" physics model and ragdoll mechanics.
  - Implement Global Game State (Stress Meter, Level Transitions).
  - Develop Level 1: Olfactory (Smell) with QWER/AD controls.
  - Basic CI/CD pipeline setup for automated builds.
  - [x] Migration docs copied
- **Dependencies:** None.

### Milestone 2: Alpha
**Estimated Timeline:** Weeks 5 - 10
**Focus:** Expanding levels and introducing the second character model.
- **Features:**
  - Create "The Thick Girl" physics model and unique jiggle physics.
  - Develop Level 2: Optic (Vision) - Dual analog stick controls.
  - Develop Level 3: Eye Movement - QWOP/OP arm control.
  - Develop Level 4: Trigeminal (Sensation) - Mouse input lag mechanic.
  - Develop Level 5: Facial Nerve (Expression).
  - Initial pass on the ASMR audio soundscape and basic deadpan dialogue.
- **Dependencies:** MVP Core Systems, Basic 3D Environment.

### Milestone 3: Beta
**Estimated Timeline:** Weeks 11 - 16
**Focus:** Completing all levels, implementing advanced mechanics, and polish.
- **Features:**
  - Develop Level 6: Vestibulocochlear (Hearing).
  - Develop Level 7: Gag Reflex (The ultimate test - IX & X).
  - Develop Level 8: Accessory (Shoulder Strength).
  - Develop Level 9: Hypoglossal (Tongue).
  - Implement the "Window of Distraction" vignettes.
  - Finalize sound effects (rubber duck squeaks, OS startup sounds).
- **Dependencies:** Alpha Levels, Both Character Models integrated.

### Milestone 4: Release Candidate & Launch
**Estimated Timeline:** Weeks 17 - 20
**Focus:** Bug fixing, optimization, and final deployment.
- **Features:**
  - Extensive QA testing and physics tuning.
  - Fix any critical bugs causing unintended "Game Overs".
  - Finalize CI/CD pipelines for production-ready exports across all platforms.
  - Create promotional assets and documentation.
- **Dependencies:** Beta complete (All levels playable).

---

## 3. Dependencies Tracking

- **Physics Engine Tuning** -> *Required for all Levels*
- **Character Models** -> *Required for Level Development*
- **Global Game State** -> *Required for progression between Levels*
- **Audio Soundscape** -> *Required for Beta Polish*
- **CI/CD Export Setup** -> *Required for Milestone Deliverables and Final Release*
