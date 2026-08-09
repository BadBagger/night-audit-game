# Night Audit Reusable Asset Catalog

Use this as the shared generation list for modular assets that should be created once, styled consistently, and reused across chapters. Prefer clean isolated assets on transparent or neutral backgrounds, with enough angle consistency for isometric/top-down placement.

## Style Rules

- Painterly noir adventure-game assets, not photoreal props.
- Camera target: isometric/top-down 3/4, compatible with the Chapter I Pier 9 plate.
- Materials: wet metal, worn wood, damp paper, black rubber, brass, sodium-vapor amber, cold blue harbor light.
- Surfaces should have visible wear, edge highlights, grime, rain sheen, and dark readable outlines.
- Avoid text baked into props unless the prop specifically needs legible writing.
- Generate each reusable prop as an isolated asset first; placement, scale, tint, and repetition happen in Godot.

## Priority 1 - Universal Dock / Noir Props

These can be reused in Chapters I, II, III, and exterior parts of V.

| Asset | Needed Variants | Reuse |
| --- | --- | --- |
| Shipping container module | closed, open doorway, side wall, stacked top | Chapter I container office, dock framing, Chapter III boat-adjacent cargo |
| Wet wooden crate | small, medium, stacked pair | Pier 9, dockmaster office, boat cargo/storage |
| Metal barrel | upright, tipped, cluster | Pier 9, strike line, boat service areas |
| Rope coil | neat coil, loose line, tiedown loop | Pier 9 clues, dock edge, boat deck |
| Police barrier | straight, angled, damaged | Pier 9, later police/case staging |
| Crime-scene tape | straight strip, sagging strip, tied-off corner | Chapter I, possible memory/case-board overlays |
| Puddle decals | small, long reflection, oil-slick | All rainy exteriors |
| Rain streak overlay | thin, heavy, foreground streaks | All exterior rain scenes |
| Evidence marker card | numbered blank, folded, wet | Chapter I clue zones, later evidence table |
| Work lamp / dock lamp | warm cone, hanging, tripod | Container office, pawn shop, dock office |
| Chain-link fence section | full panel, gate, broken edge | Pier 9, strike line, security barrier |
| Harbor bollard | clean, rusty, rope-wrapped | Dock edge, boat scenes |

## Priority 2 - Paper / Ledger / Investigation Props

These support the actual puzzle language across the whole game.

| Asset | Needed Variants | Reuse |
| --- | --- | --- |
| Ledger book | closed, open, water-stained, clipped pages | Sal, Dana apartment, finale evidence |
| Receipt slip | clean, soaked, torn, carbon copy | Chapter I clue, Sal ticket puzzle, finale board |
| Pawn ticket | blank, stamped, annotated | Sal puzzle, evidence chain |
| Shipping manifest | clipboard, loose sheet, pinned sheet | Priya puzzle, Chapter III audit |
| Donation ledger sheet | table page, highlighted lines | Priya strike fund, Chapter IV truth beat |
| Audit worksheet | two-column reconciliation, flagged rows | Chapter III skim audit, Chapter IV table |
| Legal bill stack | folded envelopes, paid-stamp bundle | Chapter IV emotional reveal |
| Evidence folder | manila, black binder, clipped packet | Dana apartment, finale table |
| Cracked phone | face-up, half-hidden, evidence bag | Chapter I phone choice, Chapter III backup route |
| Pocket watch | closed, open engraved back | Sal puzzle, safe-code payoff |

## Priority 3 - Location Kits

These are modular packs for building each chapter without one-off custom art every time.

### Pier 9 / Container Yard Kit

- Container office exterior shell
- Open container doorway/interior shadow
- Desk inside container
- Body tarp/body staging shadow
- Dock gate/security arm
- Police car light splash decal
- Harbor edge and water reflection strip
- Distant luxury ship silhouette

### Pawn Shop Kit

- Glass display counter
- Pawn shelf modules
- Ticket box
- Old cash register
- Security grate/window
- Desk lamp
- Back-room curtain

### Strike Line Kit

- Picket signs without text
- Barrel fire
- Pallet stack
- Folding table
- Rain poncho/coat rack shapes
- Dockworker barricade
- Flare light decal

### Dockmaster Office Kit

- Metal desk
- Wall map / berth board
- Coffee mug
- Radio handset
- File cabinet
- Key hook board
- Window blinds

### Calloway Star Kit

- Luxury dining table module
- Brass rail
- Carpet runner
- Service corridor panel
- Cargo hold crate stack
- Security camera
- Safe
- Glassware/table setting

### Dana Apartment Kit

- Evidence table
- Case board
- Legal bill stack
- Desk lamp
- Rainy window
- Takeout cup
- File boxes
- Old answering machine / recorder

## Priority 4 - Character-Adjacent Reusable Animation Props

These should be made as separate props so character sprites can interact with them later.

| Asset | Use |
| --- | --- |
| Brass rubber stamp | Calloway/Chairman-style bureaucratic beats, evidence stamping |
| Headset / security earpiece | Voss/security variants |
| Police notebook | Reyes talk/interact poses |
| Dana audit pen | deduction board and inspect animations |
| Umbrella silhouette | background passerby/harbor atmosphere |
| Coffee cup | red herring, Priya/Mick memory motif |
| Evidence bag | phone/pocket watch/receipt variants |

## Generation Batch Order

1. Universal dock/noir props: crate, barrel, rope, barrier, puddles, lamp, evidence marker.
2. Paper/evidence pack: ledger, receipt, pawn ticket, manifest, legal bills, phone, pocket watch.
3. Chapter I replacements: container office shell, dock gate, police light splash, harbor edge, distant ship silhouette.
4. Chapter II location kits: pawn shop, strike line, dockmaster office.
5. Chapter III/V boat kit.
6. Chapter IV apartment/case-table kit.

## Rendered Meshy Batches

### 2026-08-06 - Universal Dock Props Pass 1

Rendered from Meshy FBX exports through Blender fixed isometric camera into `art/reusable/props`.

| Asset ID | Status |
| --- | --- |
| `wet_wooden_crate` | Rendered and imported |
| `rusty_oil_drum` | Rendered and imported |
| `coiled_rope` | Rendered and imported |
| `portable_dock_lamp` | Rendered and imported |
| `straight_hazard_tape` | Rendered and imported |
| `evidence_marker_card` | Rendered and imported; usable but slightly shiny/raw, may get a later paintover |

### 2026-08-09 - Chapter I Structural Props Pass 1

Rendered from Meshy FBX exports through the same Blender fixed isometric camera. Four assets are now wired into Chapter I; two extras are kept as reusable dock/workshop clutter.

| Asset ID | Status |
| --- | --- |
| `open_container_office_clutter` | Rendered and wired into Chapter I |
| `dock_security_gate` | Rendered and wired into Chapter I |
| `portable_police_barricade` | Rendered and wired into Chapter I |
| `harbor_tiedown_ropeburn_fixture` | Rendered and wired into Chapter I rope-burn clue area |
| `ironbound_crate` | Rendered as extra reusable dock clutter |
| `rusty_hand_plane` | Rendered as extra reusable dock/workshop clutter |

### 2026-08-09 - Chapter I Dock Edge Pass 1

| Asset ID | Status |
| --- | --- |
| `long_pier_dock_edge_strip` | Rendered and wired into Chapter I; dark industrial strip, may get a brighter paintover later |

### 2026-08-09 - Whole-Game Fast Asset Pass 1

Direct-generated background plates now replace procedural environment rectangles
in Chapters II-V. Direct-generated clue props and deterministic reusable packs
cover the first paper/decal/simple-prop library pass.

| Asset ID | Status |
| --- | --- |
| `chapter2_debts_owed_plate` | Generated and wired into Chapter II |
| `chapter3_calloway_star_plate` | Generated and wired into Chapter III |
| `chapter4_apartment_plate` | Generated and wired into Chapter IV |
| `chapter5_settlement_plate` | Generated and wired into Chapter V |
| `chapter5_settlement_plate_v2` | Generated and wired into Chapter V; replaces the first plate with clearer foreground walkable floor |
| `cracked_phone_evidence` | Generated and wired into Chapter I |
| `receipt_wet_close_prop` | Generated and wired into Chapter I |
| paper/decal/simple-prop packs | Generated under `art/reusable/paper`, `art/reusable/decals`, and `art/reusable/props` |

## Suggested File Layout

```text
art/reusable/props/<asset_id>/<variant>.png
art/reusable/decals/<asset_id>/<variant>.png
art/reusable/location_kits/<kit_id>/<asset_id>.png
art/reusable/paper/<asset_id>/<variant>.png
```

## Asset Delivery Notes

- Ideal source: high-resolution PNG with transparent background.
- Also keep the Blender/Meshy source outside the Godot repo unless the asset is final and lightweight.
- Use consistent light direction: upper-left warm key plus cool ambient rim.
- Give each asset a clean silhouette; Godot will downscale them heavily.
- Avoid baking large shadows into the asset unless the shadow is part of the object. Scene lighting/shadow decals should stay separate.
