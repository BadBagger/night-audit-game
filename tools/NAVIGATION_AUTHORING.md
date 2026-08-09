# Navigation Authoring Tool

Open `res://tools/NavigationAuthoringTool.tscn` in Godot to draw Chapter 1 travel and depth zones over the generated Pier 9 plate.

Controls:
- `1`: draw walkable area polygons
- `2`: draw blocked/collision polygons
- `3`: draw foreground/3D occluder polygons for objects Dana should be able to walk behind
- Left click empty space: add a new point to the polygon currently being drawn
- Left click an existing point: select it
- Drag selected point: move it
- Shift+click an existing polygon edge: insert a new point on that edge
- Right click, `Enter`, or `Space`: close the current polygon
- `Backspace`: remove the last point
- `Backspace` or `Delete` with a point selected: remove the selected point
- `Z`: remove the last polygon in the current mode
- `Shift+Delete`: clear all polygons in the current mode
- `WASD`: pan
- Mouse wheel: zoom
- `F`: frame the background
- `Ctrl+S`: save

The tool writes `res://art/navigation/chapter1_navigation_authoring.json`.

Chapter 1 currently consumes `walkable` and `blocked` polygons at runtime. `occluder_foreground` is the production list for elements that need a separate foreground cutout, 3D prop, or depth layer so Dana can pass behind them.
