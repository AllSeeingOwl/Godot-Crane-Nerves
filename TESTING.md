# Testing Guide for Godot-Crane-Nerves

## Testing Framework
This project uses **Gut (Godot Unit Test)** as the primary testing framework. Tests are separated into `tests/unit` and `tests/integration`.

## How to Run Tests Locally
The GUT addon is not committed (`addons/gut` is gitignored). `run_tests.sh` downloads it on first run via `tools/install_gut.sh`, imports the project, then runs the whole suite headlessly using `.gutconfig.json`:

```bash
GODOT=/path/to/Godot_v4.1.3 ./run_tests.sh
```

To use the GUT panel in the editor, run `tools/install_gut.sh` once, then reopen the project.

The suite also runs in CI (the `Run GUT Tests` job in `.github/workflows/ci.yml`) on every push and pull request. `tests/pre_run_hook.gd` turns off `LevelManager` scene changes for the run, so a test that wins or loses a level doesn't replace the test scene.

Alternatively, if you open the project in the Godot Editor, you can use the Gut panel to run specific tests.

## How to Write New Tests
New tests should be placed in either `tests/unit/` or `tests/integration/` depending on scope, and their filename must start with `test_`.

Example of a basic test file (`tests/unit/test_example.gd`):

```gdscript
extends GutTest

func before_each():
    # Setup runs before each test
    pass

func after_each():
    # Teardown runs after each test
    pass

func test_basic_math():
    var result = 2 + 2
    assert_eq(result, 4, "Two plus two should equal four")
```

## Testing Best Practices
1. **Isolation**: Tests should not depend on the state of other tests.
2. **Descriptive Names**: Function names should clearly indicate what is being tested.
3. **Clean Up**: Always free instantiated nodes in `after_each()`.
4. **Assert Messages**: Include a clear failure message in asserts.

## Systems That Require Test Coverage
- **Core Game Logic**: `GameState` stress tracking and `LevelManager` routing. Goal is 80% coverage.
- **Player Movement**: Ensuring physics math and state transitions work as expected.
- **Level Mechanics**: Each `LevelN_*.gd` script's win/lose conditions and stress triggers.
