# Cranial Nerve Crisis - Godot Migration

![Godot Engine](https://img.shields.io/badge/Godot-4.x-blue?logo=godot-engine&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)

## Project Description

**Cranial Nerve Crisis** is a physics-based comedy game where the player performs a delicate 12-part cranial nerve exam on a patient. It is heavily inspired by titles like *QWOP*, *Surgeon Simulator*, and *Getting Over It with Bennett Foddy*. The core mechanics involve deliberately convoluted controls and absurd, extreme physics reactions.

This repository represents the **Godot Engine migration** of the original game, which was initially prototyped in React. The current markdown files in this repository serve as the source of truth for game mechanics, variable names, math logic, and design parameters. The goal is to rebuild the game natively in Godot to leverage its physics and rendering engines while preserving the exact "ambient dread" and comedic frustration of the original prototype.

## Prerequisites

To run, test, and contribute to this project, you will need:
- **Godot Engine**: Version **4.x** or higher (Recommended: Latest Stable Godot 4 release). You can download it from [godotengine.org](https://godotengine.org/).
- **Git**: For version control and cloning the repository.

## Installation Instructions

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/Godot-Crane-Nerves.git
   cd Godot-Crane-Nerves
   ```

2. **Open the project in Godot:**
   - Launch the Godot Engine.
   - Click on the **Import** button in the Project Manager.
   - Navigate to the cloned `Godot-Crane-Nerves` folder.
   - Select the `project.godot` file (if available, or simply select the folder to create a new Godot project here).
   - Click **Import & Edit**.

## How to Run and Test Locally

1. Once the project is open in the Godot Editor, navigate to the `FileSystem` dock.
2. Open any available scene from the `scenes/` folder by double-clicking it (e.g., `scenes/Main.tscn` if it exists).
3. Click the **Play Project** button (`F5`) in the top right corner of the editor to run the main scene, or click **Play Current Scene** (`F6`) to test the specific scene you have open.
4. Use the editor's debugging tools to inspect physics, stress parameters, and variables as you interact with the game.

## Project Folder Structure

The project is organized to maintain a clear separation between migration documentation and actual game assets:

```
Godot-Crane-Nerves/
├── 00_Game_Design_Document.md    # Master plan and feel of the game
├── 01_GameEngine_State.md        # Global stress and level transitions
├── 02_Level1_Olfactory.md        # Logic for Level 1
├── 03_Level2_Optic.md            # Logic for Level 2
├── 04_Level3_EyeMovement.md      # Logic for Level 3
├── 05_Level4_Trigeminal.md       # Logic for Level 4
├── 06_DoctorsOffice3D_Layout.md  # 3D coordinates for the background room
├── 07_Math_Utils.md              # Math optimization tables
├── 08_AI_PROMPTS.md              # Prompts to assist AI agents in migrating code
├── assets/                       # 2D/3D sprites, models, audio, and raw assets
├── resources/                    # Custom Godot resources (.tres), materials, and themes
├── scenes/                       # Godot scene files (.tscn) for levels and prefabs
├── scripts/                      # GDScript source code files (.gd)
└── README.md                     # This file
```

*Note: The Markdown (`.md`) files in the root folder contain the extracted logic from the original React prototype. When implementing new features, refer to these documents as the primary source of truth for math and game logic.*

## Contribution Guidelines

We welcome contributions to help migrate the React prototype into a fully functional Godot game!

1. **Fork the repository** and create a new branch for your feature or bug fix (`git checkout -b feature/my-new-feature`).
2. **Read the Design Documents**: Before starting, review `00_Game_Design_Document.md` and the relevant level documentation to ensure your work aligns with the original vision.
3. **Use the AI Prompts**: If using an AI assistant to write code, leverage the instructions in `08_AI_PROMPTS.md` and the level-specific markdown files.
4. **Follow Godot Best Practices**: Use GDScript conventions, keep scenes modular, and avoid hardcoding values where possible.
5. **Commit your changes**: Write clear, descriptive commit messages.
6. **Push to the branch**: `git push origin feature/my-new-feature`.
7. **Open a Pull Request**: Describe your changes and link to any relevant issues.

## Licensing

This project is licensed under the MIT License. Feel free to use, modify, and distribute the code, but please provide appropriate attribution.
