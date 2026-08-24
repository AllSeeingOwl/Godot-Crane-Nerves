# Quick Start Guide

Welcome to the Godot-Crane-Nerves project! This guide will help you get the project up and running quickly.

## System Requirements
- **Godot Engine:** Version **4.1.3** is required (Forward+ rendering).
- **RAM:** 4GB Minimum, 8GB+ Recommended.
- **OS:** Windows 10/11, macOS (Intel/Apple Silicon), or Linux.
- **Git:** Installed and configured.

## 1. Cloning the Repository
Open your terminal or command prompt and run:
```bash
git clone https://github.com/your-username/Godot-Crane-Nerves.git
cd Godot-Crane-Nerves
```

## 2. Opening the Project
1. Download and extract [Godot 4.1.3](https://github.com/godotengine/godot/releases/tag/4.1.3-stable).
2. Open the Godot executable.
3. Click **Import** in the Project Manager.
4. Navigate to your cloned `Godot-Crane-Nerves` folder and select the `project.godot` file.
5. Click **Import & Edit**. Godot will take a moment to import assets.

## 3. Running the Game
1. In the Godot editor, locate the `FileSystem` panel (usually bottom left).
2. Navigate to `scenes/` and double-click `Main.tscn` (or any level scene like `Level1_Olfactory.tscn` if Main isn't setup yet).
3. Press **F5** (or click the Play icon in the top right) to run the main project.
4. Press **F6** to run only the currently open scene.

## 4. Documentation Links
To understand the architecture and mechanics, refer to the documentation:
- [Architecture](docs/ARCHITECTURE.md): System design and data flow.
- [Gameplay Mechanics](docs/GAMEPLAY.md): How to play and level rules.
- [API Reference](docs/API.md): Important scripts and singletons.
- [Debugging Guide](docs/DEBUGGING.md): How to troubleshoot issues.
- [Performance Optimization](docs/PERFORMANCE.md): Keeping the game running smoothly.
- [Deployment](docs/DEPLOYMENT.md): Exporting and building the game.
- [ADRs](adr/): Architecture Decision Records.

*(Note: The `0X_Level.md` files in the root folder contain the original prototype logic that needs to be implemented).*

## 5. Troubleshooting
- **Errors about `[ext_resource]` on import:** Godot 4 requires the `[gd_scene]` tag to be on the very first line of a `.tscn` file. Open the file in a text editor and ensure no empty lines or other tags precede it.
- **"Directory not empty" during GitHub Actions:** This is a known issue with the template cache. The CI pipeline is configured to run `rm -rf ~/.local/share/godot/export_templates/` to fix this.
- **Physics behaving wildly:** Ensure you are running at a stable framerate and that heavy logic is in `_physics_process(delta)` not `_process(delta)`.
