# Sci-Fi Holo Interface: FREE sample

A small taste of the full pack, in the cyan theme: **one wide button in all five states** (normal, hover, pressed, disabled, focused), **one smooth bar** (frame, track, fill and a finished 50 % composite on one shared canvas), **one radial gauge ring** (frame, track, full fill and a finished 70 % step) and **two reticles**.

Contents: 15 SVG and 45 PNG (1x, 2x, 3x), `nine_slice.json` for the button and the bar, a preview sheet and the license.
- Button `btn_wide_192x48_<state>` (192 x 48): 3-slice with a 56 px left margin and a 24 px right margin (the left pip and the tick strip sit inside the left margin).
- Bar (256 x 32, fixed size, not 9-slice): `bar_smooth_frame`, `bar_smooth_track`, `bar_smooth_fill_health`, `bar_smooth_health_pct_50`. In Godot use a `TextureProgressBar` (Left to Right) with min_value -11.538 and max_value 111.538; then value 0 to 100 is the fill.
- Gauge (128 x 128): `gauge_ring_frame`, `gauge_ring_track`, `gauge_ring_fill` (a full 270 degree arc) and `gauge_ring_pct_70`. In Godot use a `TextureProgressBar` with Fill Mode Clockwise, initial angle 225 and fill degrees 270.
- Reticles `reticle_cross_gap_96x96` and `reticle_ring_ticks_96x96`.

**Get the full pack** (278 elements per theme in 4 themes, 7 categories, a Godot demo, a recolour tool): https://stationsupply.itch.io/sci-fi-holo-interface

All graphics are hand-coded SVG vectors; no AI image generation was used. The SVG code was written with an AI assistant. License: see LICENSE (commercial use in your games is fine, no resale or redistribution).
