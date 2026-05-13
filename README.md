# experiment-task-code

This repository contains the code used in a master's thesis experiment.

The project is built with Godot and includes:

* Game logic
* Stimulus presentation
* Data collection logic

Structure:

* landing_page.gd / .tscn: Includes the game settings panel
* main_scene.gd / .tscn: Main experiment logic
* main_scene_nogo.gd / .tscn: Go/No-Go version of the experiment
* animal.gd / .tscn: Stimulus object (diamond shape in the final version)
* ring_effect.gd / .tscn: Implementation of the expanding ring effect
* screen_flash_effect.gd / .tscn: Implementation of the border flash effect
* hover_ring.gd / .tscn: Hover state for the expanding ring effect
* hover_border_glow.gd / .tscn: Hover state for the border flash effect
* global.gd: Shared variables and data tracking
* grid_preview_scene.gd / .tscn: Utility scene for layout testing (not used in the experiment)

Note: No experimental data is included in this repository due to privacy and ethical considerations.

Note: Some file and variable names (e.g., "animal") originate from an earlier version of the project where stimuli were animal images. In the final version, these refer to abstract diamond-shaped stimuli, but the naming was retained for consistency.
