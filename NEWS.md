# gloss 0.0.0.9000

## M0: the substrate (2026-11-09)

- `gloss()` captures a ggplot, patchwork, ComplexHeatmap, base (through gridGraphics) or grid figure into a read-only substrate. Each leaf grob is drawn once inside its own graphics group with a zero-output probe, so every drawn element is attributed by the device to its leaf, viewport and panel. A leaf whose expected and drawn element counts differ is marked `count_mismatch` and is not bindable. Masked figures are refused.
- Geometry queries: `gl_elements()`, `gl_leaf()`, `gl_panels()`, `gl_hit()`, `gl_near()`, `gl_overlap()`, `gl_to_pixel()`, `gl_to_data()`.
- Tables (raw, built and engine-specific) with inferred row keys (`gl_infer_key()`, five rules in order, each recorded with its basis), `gl_tables()`, `gl_table()`, `gl_key_values()`, and `gl_key()` to change a key.
- Leaves with 10,000 or more elements are kept as a raster drawn from the same grob plus a binary geometry index.
- Context is sniffed at capture time (code, data, engine, environment, document, git) and listed by `gl_context()`; items that cannot be found carry a reason.
- `gl_write()` writes a bundle directory or a single HTML or SVG file with the bundle embedded; `gl_read()` restores either, as well as bundles without data, bundles naming a missing plugin, and plain SVG (geometry only). `embed =` chooses which data travel.
- Plugins: `gl_register()`, `gl_unregister()`, `gl_plugin()`, `gl_plugins()`, `gl_plugin_kinds()`, `gl_test_plugin()`, `gl_schema_check()`, `gl_schema_validate()`. The built-in engines, context sniffers and projections register through `gl_register()`.
