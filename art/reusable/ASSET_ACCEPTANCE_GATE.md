# Reusable Asset Acceptance Gate

This repo treats `art/reusable` as approved production art. Do not add exploratory
or low-confidence generated images here.

## Required Before Commit

Each new reusable asset must have:

- A clear story function: what it tells the player about Vellmouth, Mick, Reyes,
  labor, Calloway, police, or the crime staging.
- A target placement: chapter, scene zone, approximate Godot position, and
  expected scale range.
- A source route: Meshy/Blender render, deterministic 2D decal, hand-authored
  raster, or approved image-generation output with manual cleanup.
- A transparent placement sprite, unless it is a full background plate.
- No unreadable AI text artifacts. If the asset needs readable text, author the
  text manually after generation.
- No studio floor, cast shadow, background remnants, halo, watermark, signature,
  extra objects, or cropped edges.
- A quick contact-sheet review on a neutral gray background.

## Route By Asset Type

Use Meshy/Blender for:

- large physical props Dana walks around or behind
- reusable props that need consistent isometric depth
- barricades, lamps, bollards, crates, gates, furniture, security equipment

Use deterministic or hand-authored 2D for:

- decals
- signage
- paper props with text blocks
- puddles, rust streaks, blood, runoff, stains, serial numbers

Use ComfyUI only for:

- rough concept exploration
- texture inspiration
- props that can survive strict matte cleanup and manual inspection

ComfyUI output is not automatically approved reusable art.

## Minimum Visual Bar

The asset should still read correctly at its smallest intended in-game scale.
If the silhouette or story function only works when viewed full size, it is not
ready for Chapter 1 placement.
