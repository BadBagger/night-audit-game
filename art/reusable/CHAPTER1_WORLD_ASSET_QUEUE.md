# Chapter 1 World Asset Queue

Goal: make Pier 9 feel authored, not decorated. Every asset below should support
one of five reads: police control, dock labor, Calloway money, Mick's presence,
or staged-crime contradiction.

## Priority A - Needed Before More Scene Dressing

| Asset ID | Story Function | Route | Target Placement | Acceptance Criteria |
| --- | --- | --- | --- | --- |
| `cracked_phone_evidence` | Supports Chapter 1 phone choice and Mick trace | Meshy/Blender for prop, manual screen glow overlay | Near Mick/body, around `Vector2(645, 456)` | Phone silhouette clear, cracked screen visible, no readable AI text |
| `receipt_wet_close_prop` | Supports timeline clue | deterministic 2D or Blender paper prop | Receipt clue, around `Vector2(690, 370)` | Small wet paper rectangle with legible visual contrast; any text must be manual or abstract |
| `low_wall_spatter_decal` | Supports “killed elsewhere / staged here” deduction | deterministic 2D decal | Wall/spatter clue, around `Vector2(520, 410)` | Low horizontal spatter, rain drag, transparent PNG/SVG, no random gore mass |
| `drag_scuff_wetness_decal` | Shows body was moved and recently placed | deterministic 2D decal | Between body and container threshold | Subtle wet scuff path; must not look like a road stripe |

## Priority B - Disco-Style Worldbuilding Reads

| Asset ID | Story Function | Route | Target Placement | Acceptance Criteria |
| --- | --- | --- | --- | --- |
| `vellmouth_pd_case_board` | Police control, temporary jurisdiction, Reyes holding line | Meshy/Blender or hand-authored 2D board | Police staging zone, around `Vector2(1430, 850)` | Clear police-board silhouette, no AI text, works behind dialogue UI |
| `police_radio_crate` | Explains radio bursts and active scene processing | Meshy/Blender | Near police barrier | Compact equipment crate with antenna/cables |
| `union_notice_cluster` | Labor history; connects to Priya before Chapter 2 | deterministic 2D poster cluster | Fence/container wall edge | Torn paper cluster, no readable AI text, manually add simple block marks if needed |
| `calloway_cargo_seal` | Corporate power trace inside public dock | deterministic 2D decal or Blender label on crate | Crate/gate zone | Clean corporate label feel without real text artifacts |
| `container_serial_grime_decals` | Material history and scale | deterministic 2D decal set | Container faces/background overlay | Weathered marks/stencils, abstract blocks only |

## Priority C - Atmosphere/Material Decals

| Asset ID | Story Function | Route | Target Placement | Acceptance Criteria |
| --- | --- | --- | --- | --- |
| `puddle_reflection_pack` | Wetness and light logic | deterministic 2D decal atlas | Walkable lanes and police light zone | Subtle, low-contrast, no cartoon outlines |
| `rust_runoff_pack` | Port age and container materiality | deterministic 2D decal atlas | Container walls, dock edges | Thin vertical streaks, transparent, tileable enough for reuse |
| `dock_drain_runoff` | Water has direction and sound source | Meshy/Blender if physical, deterministic if decal | Harbor/dock edge | Grate perspective matches scene; water runoff visible |
| `cable_chain_scatter` | Utility clutter without generic boxes | Meshy/Blender | Gate and container zones | Reads as cables/chains at gameplay scale |

## Current Reusable Assets Already Approved

- `evidence_marker_card`
- `wet_wooden_crate`
- `rusty_oil_drum`
- `coiled_rope`
- `portable_dock_lamp`
- `straight_hazard_tape`
- `harbor_tiedown_ropeburn_fixture`
- `open_container_office_clutter`
- `portable_police_barricade`
- `dock_security_gate`
- `ironbound_crate`
- `rusty_hand_plane`
- `long_pier_dock_edge_strip`
- `mick_tarp_body`
- `arterial_low_01.svg`
- `arterial_low_02.svg`

## Next Production Recommendation

Generate `cracked_phone_evidence` and `receipt_wet_close_prop` next. These are
case-critical and affect Chapter 1 more than broad background clutter.
