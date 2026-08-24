# Testing Guide for Godot-Crane-Nerves

## Testing Framework
This project uses **Gut (Godot Unit Test)** as the primary testing framework. Tests are separated into `tests/unit` and `tests/integration`.

## How to Run Tests Locally
You can run tests from the command line using the `run_tests.sh` script or Godot headless execution:

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

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
- **Core Game Logic**: The `GameLogic` script and scoring mechanisms. Goal is 80% coverage.
- **Player Movement**: Ensuring physics math and state transitions work as expected.
- **Enemy Behaviors**: Verifying health logic, damage taken, and state transitions.
