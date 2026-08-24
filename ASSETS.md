# Asset Organization and Guidelines

This document details the asset organization, naming conventions, and guidelines for adding new assets to the Cranial Nerve Crisis project.

## Directory Structure
- `assets/sprites/`: 2D graphics, UI textures, character art, and 2D visual elements.
- `assets/audio/music/`: Background music tracks and ambient soundscapes.
- `assets/audio/sfx/`: Sound effects for interactions, UI, weapons, and impacts.
- `assets/fonts/`: Custom fonts for UI, HUD, and dialogue elements.
- `assets/shaders/`: Custom shader scripts and visual effects materials.

## Naming Conventions
To maintain a clean and searchable repository, use snake_case for all asset files. Ensure names are descriptive of their function or appearance.

### Sprites and Graphics
- Use the format: `[subject]_[action/state]_[modifier].[extension]`
- Examples:
  - `player_idle.png`
  - `player_walk_01.png`
  - `enemy_attack_melee.png`
  - `ui_button_hover.png`

### Audio (Music and SFX)
- Music format: `bgm_[level/mood/scene].[extension]`
  - Example: `bgm_level1_olfactory.ogg`
- SFX format: `sfx_[source]_[action].[extension]`
  - Example: `sfx_player_jump.wav`, `sfx_ui_click.wav`

### Fonts
- Format: `[FontName]_[Weight].[extension]` (can use PascalCase for the font name itself, but snake_case the overall file string if possible, or stick to consistent formatting like `robot_bold.ttf`)
- Example: `open_sans_regular.ttf`

### Shaders
- Format: `sh_[effect_name].[extension]`
- Example: `sh_water_ripple.gdshader`

## Guidelines for Adding New Assets
1. **Optimize Before Importing**: Compress images (e.g., via PNGQuant) and audio (e.g., OGG format for music, WAV for short SFX) before committing them to reduce repository size.
2. **Import Settings**: Godot automatically generates `.import` files for every asset. Make sure to commit these `.import` files alongside your original asset files to preserve import configurations (like filtering, mipmaps, or compression).
3. **Correct Folder Placement**: Place assets in their specific folders. Avoid dropping everything into the root `assets/` directory.
4. **No Unused Assets**: Do not commit assets unless they are going to be used in the game or are part of a very near-term feature to avoid bloating the project.