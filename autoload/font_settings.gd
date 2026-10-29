extends Node

signal sizes_changed

## Global multiplier applied to every size returned by scaled(). 1.0 = default.
var scale: float = 1.0:
	set(value):
		scale = clampf(value, 0.5, 3.0)
		sizes_changed.emit()

# ── Base sizes per category ──────────────────────────────────────────────────

## Screen titles — pause menu header, level-select header, formulas title.
var ui_title: int = 62

## Section headings — level-select subtitle, options menu title.
var ui_subtitle: int = 39

## Regular content text — formula values, result text, descriptions.
var ui_body: int = 33

## Button labels — main menu, pause menu, options menu buttons.
var ui_button: int = 33

## Tutorial/info popup text.
var popup: int = 28

## Ball-attributes panel (values and labels).
var attributes: int = 28

## In-game HUD labels — angle, speed, launch-controls.
var hud: int = 16

## Small captions and secondary labels.
var caption: int = 16

# ── Helpers ──────────────────────────────────────────────────────────────────

## Returns [param base] × [member scale], clamped to at least 1.
func scaled(base: int) -> int:
	return maxi(roundi(base * scale), 1)


## Shortcut: applies a font_size theme override to [param node].
func apply(node: Control, size: int) -> void:
	if node is RichTextLabel:
		node.add_theme_font_size_override("normal_font_size", size)
	else:
		node.add_theme_font_size_override("font_size", size)
