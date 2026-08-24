# Contributing to Godot-Crane-Nerves

Thank you for your interest in contributing to the Godot-Crane-Nerves project! We welcome contributions to help migrate the game into a fully functional Godot game.

## Coding Standards

To maintain consistency across the codebase, we enforce standard formatting rules.

An `.editorconfig` file is provided in the root directory to help configure your editor automatically. If your editor does not support `.editorconfig` natively, please install the appropriate plugin.

The key formatting rules are:
- **Indentation**: Use **tabs** for indentation, especially in GDScript (this is Godot's default).
- **Line Endings**: Always use **LF** (Unix-style) line endings for all files.
- **File Endings**: Ensure all files end with a single empty newline.
- **Trailing Whitespace**: Remove trailing whitespace at the end of lines.

## Naming Conventions (GDScript)

For GDScript, please adhere to the following naming conventions:
- **snake_case** for variables, functions, and file names (e.g., `my_variable`, `do_something()`, `my_script.gd`).
- **PascalCase** for class names and node names in the scene tree (e.g., `PlayerCharacter`, `MainLevel`).
- **UPPER_SNAKE_CASE** for constants (e.g., `MAX_HEALTH`).

## Pull Request Process

When you're ready to submit your changes, follow this process:

1. **Fork the Repository**: Start by forking the repository and cloning it to your local machine.
2. **Create a Branch**: Create a new branch for your feature or bug fix. Use a descriptive name (e.g., `feature/add-level-5` or `fix/player-movement`).
3. **Make Your Changes**: Write your code, ensuring it follows the coding standards and naming conventions outlined above. Reference the Markdown documentation files for game logic.
4. **Commit Your Changes**: Write clear, descriptive commit messages.
5. **Push to Your Fork**: Push your branch to your forked repository on GitHub.
6. **Open a Pull Request (PR)**:
   - Navigate to the original repository and open a Pull Request.
   - Provide a clear title and description of your changes.
   - Link any relevant issues your PR addresses.
7. **Review Process**:
   - The project uses GitHub Actions for CI/CD. Ensure all automated status checks pass.
   - A maintainer will review your code. You may be asked to make changes before it can be merged.
8. **Merge**: Once approved and all checks pass, your PR will be merged into the `main` or `develop` branch! Head branches will be automatically deleted upon merging.

Thank you for contributing!
