class_name PatientKit
extends RefCounted

## Shared, code-drawn art for every exam level: the exam-room backdrop and a front-view patient.
## Blocky, slightly stiff mid-2000s look (see docs/GAME_DESIGN.md, "Art Direction").
##
## All patient geometry is in "head units": the head is an ellipse 1.0 wide and 1.25 tall
## (half-sizes) around `center`, and `scale` is pixels per unit. Use feature_point() to find
## where an anatomical landmark is drawn, so gameplay targets sit on the actual face.

# --- Palette ---
const WALL := Color(0.70, 0.77, 0.70)
const WALL_LOW := Color(0.60, 0.67, 0.61)
const RAIL := Color(0.50, 0.56, 0.52)
const WINDOW_SKY := Color(0.62, 0.74, 0.86)
const BLINDS := Color(0.88, 0.88, 0.82)
const FRAME := Color(0.35, 0.33, 0.30)
const SKIN := Color(0.93, 0.76, 0.62)
const SKIN_SHADE := Color(0.80, 0.62, 0.50)
const FLUSH := Color(0.95, 0.45, 0.42)
const HAIR := Color(0.32, 0.22, 0.15)
const LIP := Color(0.78, 0.40, 0.42)
const MOUTH_DARK := Color(0.30, 0.06, 0.10)
const TEETH := Color(0.96, 0.95, 0.88)
const EYE_WHITE := Color(0.97, 0.97, 0.95)
const IRIS := Color(0.30, 0.48, 0.62)
const PUPIL := Color(0.05, 0.05, 0.08)
const GOWN := Color(0.62, 0.78, 0.84)
const GOWN_DOTS := Color(0.48, 0.64, 0.72)
const OUTLINE := Color(0.22, 0.16, 0.14)
const SWEAT := Color(0.70, 0.88, 1.0, 0.85)

const HEAD_HALF := Vector2(1.0, 1.25)

## Anatomical landmarks in head units (x right, y down).
const FEATURES: Dictionary = {
	"top_of_head": Vector2(0, -1.25),
	"forehead_l": Vector2(-0.42, -0.55),
	"forehead_r": Vector2(0.42, -0.55),
	"brow_l": Vector2(-0.38, -0.36),
	"brow_r": Vector2(0.38, -0.36),
	"eye_l": Vector2(-0.38, -0.12),
	"eye_r": Vector2(0.38, -0.12),
	"nose": Vector2(0, 0.22),
	"cheek_l": Vector2(-0.58, 0.22),
	"cheek_r": Vector2(0.58, 0.22),
	"mouth": Vector2(0, 0.58),
	"jaw_l": Vector2(-0.45, 0.85),
	"jaw_r": Vector2(0.45, 0.85),
	"chin": Vector2(0, 1.12),
	"ear_l": Vector2(-1.04, 0.0),
	"ear_r": Vector2(1.04, 0.0),
}


## Screen position of a named landmark (see FEATURES).
static func feature_point(center: Vector2, scale: float, feature: String) -> Vector2:
	return center + FEATURES[feature] * scale


## Points of an ellipse, for draw_colored_polygon / draw_polyline.
static func ellipse_points(
	center: Vector2, radii: Vector2, segments: int = 32
) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	return pts


static func draw_ellipse(
	ci: CanvasItem, center: Vector2, radii: Vector2, color: Color, outline: float = 0.0
) -> void:
	var pts := ellipse_points(center, radii)
	ci.draw_colored_polygon(pts, color)
	if outline > 0.0:
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, OUTLINE, outline)


## The exam room: institutional green wall, chair rail, a window with blinds and a wall clock.
static func draw_room(ci: CanvasItem, size: Vector2) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, size), WALL)
	var rail_y := size.y * 0.68
	ci.draw_rect(Rect2(Vector2(0, rail_y), Vector2(size.x, size.y - rail_y)), WALL_LOW)
	ci.draw_rect(Rect2(Vector2(0, rail_y - 4), Vector2(size.x, 8)), RAIL)

	# Window with half-drawn blinds (the "Window of Distraction")
	var win := Rect2(Vector2(size.x * 0.76, size.y * 0.2), Vector2(size.x * 0.17, size.y * 0.36))
	ci.draw_rect(win.grow(6), FRAME)
	ci.draw_rect(win, WINDOW_SKY)
	var slat_count := 6
	for i in range(slat_count):
		var y := win.position.y + i * 9.0
		ci.draw_rect(Rect2(Vector2(win.position.x, y), Vector2(win.size.x, 6)), BLINDS)
	ci.draw_line(
		win.position + Vector2(win.size.x * 0.5, 0),
		win.end - Vector2(win.size.x * 0.5, 0),
		FRAME,
		3
	)

	# Wall clock, stuck at an ominous time
	var clock := Vector2(size.x * 0.12, size.y * 0.24)
	var r := size.y * 0.06
	draw_ellipse(ci, clock, Vector2(r, r), Color(0.95, 0.95, 0.92), 3.0)
	ci.draw_line(clock, clock + Vector2(0, -r * 0.75), OUTLINE, 3)
	ci.draw_line(clock, clock + Vector2(r * 0.5, r * 0.15), OUTLINE, 4)


## Translucent bands behind the HUD text so white labels stay readable over the room.
static func draw_hud_bands(ci: CanvasItem, size: Vector2, top_h: float, bottom_h: float) -> void:
	var band := Color(0.06, 0.08, 0.07, 0.72)
	var edge := Color(0.55, 0.85, 0.6, 0.5)
	if top_h > 0.0:
		ci.draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, top_h)), band)
		ci.draw_line(Vector2(0, top_h), Vector2(size.x, top_h), edge, 2.0)
	if bottom_h > 0.0:
		var y := size.y - bottom_h
		ci.draw_rect(Rect2(Vector2(0, y), Vector2(size.x, bottom_h)), band)
		ci.draw_line(Vector2(0, y), Vector2(size.x, y), edge, 2.0)


## Front-view patient. `face` keys (all optional):
##   look_l, look_r: Vector2 pupil offset (-1..1 each axis)
##   eye_closed_l, eye_closed_r: 0..1
##   brow_raise: -1 (furrowed) .. 1 (raised)
##   nose_wrinkle: 0..1
##   cheek_puff_l, cheek_puff_r: 0..1
##   smile_l, smile_r: -1 (down) .. 1 (up)
##   pucker: 0..1        jaw_open: 0..1
##   stress: 0..100 (flushes the skin and adds sweat)
##   body: bool (draw neck, shoulders and gown; default true)
static func draw_patient(
	ci: CanvasItem, center: Vector2, scale: float, face: Dictionary = {}
) -> void:
	var stress: float = face.get("stress", 0.0)
	var skin := SKIN.lerp(FLUSH, clampf(stress / 100.0, 0.0, 1.0) * 0.35)

	if face.get("body", true):
		_draw_body(ci, center, scale, skin)

	# Ears behind the head
	for side in [-1.0, 1.0]:
		var ear := center + Vector2(side * 1.0, 0.0) * scale
		draw_ellipse(ci, ear, Vector2(0.16, 0.28) * scale, skin, 2.0)
		draw_ellipse(
			ci, ear + Vector2(side * 0.03, 0) * scale, Vector2(0.07, 0.15) * scale, SKIN_SHADE
		)

	# Head and hair
	draw_ellipse(ci, center, HEAD_HALF * scale, skin, 3.0)
	var hair := PackedVector2Array()
	for i in range(17):
		var a := PI + PI * float(i) / 16.0
		hair.append(center + Vector2(cos(a) * 1.02, sin(a) * 1.28 + 0.02) * scale)
	for i in range(9):
		var t := float(i) / 8.0
		var x := lerpf(1.0, -1.0, t)
		var dip := -0.72 + 0.07 * sin(t * PI * 4.0)
		hair.append(center + Vector2(x, dip) * scale)
	ci.draw_colored_polygon(hair, HAIR)

	_draw_brows(ci, center, scale, face.get("brow_raise", 0.0))
	for side in ["l", "r"]:
		_draw_eye(
			ci,
			feature_point(center, scale, "eye_" + side),
			scale,
			face.get("look_" + side, Vector2.ZERO),
			face.get("eye_closed_" + side, 0.0),
			skin
		)
	_draw_cheeks(ci, center, scale, face, stress)
	_draw_nose(ci, center, scale, face.get("nose_wrinkle", 0.0))
	_draw_mouth(ci, center, scale, face)

	if stress > 40.0:
		var drops := int((stress - 40.0) / 20.0) + 1
		for i in range(drops):
			var p := center + Vector2(0.78 - i * 0.05, -0.5 + i * 0.2) * scale
			draw_ellipse(ci, p, Vector2(0.05, 0.08) * scale, SWEAT)


static func _draw_body(ci: CanvasItem, center: Vector2, scale: float, skin: Color) -> void:
	ci.draw_rect(Rect2(center + Vector2(-0.35, 0.9) * scale, Vector2(0.7, 0.8) * scale), skin)
	var gown := PackedVector2Array(
		[
			center + Vector2(-2.1, 3.2) * scale,
			center + Vector2(-1.9, 1.75) * scale,
			center + Vector2(-0.4, 1.45) * scale,
			center + Vector2(0.0, 1.7) * scale,
			center + Vector2(0.4, 1.45) * scale,
			center + Vector2(1.9, 1.75) * scale,
			center + Vector2(2.1, 3.2) * scale,
		]
	)
	ci.draw_colored_polygon(gown, GOWN)
	for i in range(8):
		var p := center + Vector2(-1.6 + i * 0.45, 2.1 + (i % 2) * 0.35) * scale
		draw_ellipse(ci, p, Vector2(0.06, 0.06) * scale, GOWN_DOTS)


static func _draw_brows(ci: CanvasItem, center: Vector2, scale: float, raise: float) -> void:
	for side in [-1.0, 1.0]:
		var base := center + Vector2(side * 0.38, -0.36 - raise * 0.1) * scale
		var inner := base + Vector2(-side * 0.17, 0.05 * maxf(-raise, 0.0) * 2.0) * scale
		var outer := base + Vector2(side * 0.17, -0.02) * scale
		ci.draw_line(inner, outer, HAIR, 0.08 * scale)
	if raise > 0.3:
		for i in range(2):
			var y := -0.55 - i * 0.07
			ci.draw_line(
				center + Vector2(-0.3, y) * scale, center + Vector2(0.3, y) * scale, SKIN_SHADE, 2.0
			)


static func _draw_eye(
	ci: CanvasItem, pos: Vector2, scale: float, look: Vector2, closed: float, skin: Color
) -> void:
	var radii := Vector2(0.17, 0.11) * scale
	draw_ellipse(ci, pos, radii, EYE_WHITE, 2.0)
	var pupil_pos := pos + Vector2(look.x * 0.08, look.y * 0.04) * scale
	draw_ellipse(ci, pupil_pos, Vector2(0.075, 0.075) * scale, IRIS)
	draw_ellipse(ci, pupil_pos, Vector2(0.035, 0.035) * scale, PUPIL)
	if closed > 0.0:
		var lid_h := radii.y * 2.0 * clampf(closed, 0.0, 1.0)
		ci.draw_rect(Rect2(pos - radii - Vector2(2, 2), Vector2(radii.x * 2 + 4, lid_h + 2)), skin)
		ci.draw_line(
			pos + Vector2(-radii.x, -radii.y + lid_h),
			pos + Vector2(radii.x, -radii.y + lid_h),
			OUTLINE,
			2
		)


static func _draw_cheeks(
	ci: CanvasItem, center: Vector2, scale: float, face: Dictionary, stress: float
) -> void:
	for side in ["l", "r"]:
		var puff: float = face.get("cheek_puff_" + side, 0.0)
		var blush := Color(FLUSH.r, FLUSH.g, FLUSH.b, 0.15 + 0.25 * puff + stress / 400.0)
		var radius := (0.16 + 0.08 * puff) * scale
		draw_ellipse(
			ci, feature_point(center, scale, "cheek_" + side), Vector2(radius, radius * 0.7), blush
		)


static func _draw_nose(ci: CanvasItem, center: Vector2, scale: float, wrinkle: float) -> void:
	var tip := feature_point(center, scale, "nose")
	var bridge := PackedVector2Array(
		[
			tip + Vector2(-0.04, -0.32) * scale,
			tip + Vector2(-0.14, 0.04) * scale,
			tip + Vector2(0.0, 0.1) * scale,
			tip + Vector2(0.14, 0.04) * scale,
			tip + Vector2(0.04, -0.32) * scale,
		]
	)
	ci.draw_colored_polygon(bridge, SKIN_SHADE)
	if wrinkle > 0.3:
		for i in range(3):
			var y := -0.24 + i * 0.06
			ci.draw_line(
				tip + Vector2(-0.07, y) * scale, tip + Vector2(0.07, y) * scale, OUTLINE, 1.5
			)


static func _draw_mouth(ci: CanvasItem, center: Vector2, scale: float, face: Dictionary) -> void:
	var m := feature_point(center, scale, "mouth")
	var smile_l: float = face.get("smile_l", 0.0)
	var smile_r: float = face.get("smile_r", 0.0)
	var pucker: float = face.get("pucker", 0.0)
	var jaw: float = face.get("jaw_open", 0.0)

	var half_w := lerpf(0.3, 0.12, pucker)
	var left := m + Vector2(-half_w, -smile_l * 0.12) * scale
	var right := m + Vector2(half_w, -smile_r * 0.12) * scale
	var open_h := (0.04 + jaw * 0.3 + pucker * 0.06) * scale

	var mouth := PackedVector2Array()
	for i in range(9):
		var t := float(i) / 8.0
		var p := left.lerp(right, t)
		p.y -= sin(t * PI) * open_h * 0.4 - (smile_l + smile_r) * 0.04 * scale * sin(t * PI)
		mouth.append(p)
	for i in range(9):
		var t := 1.0 - float(i) / 8.0
		var p := left.lerp(right, t)
		p.y += sin(t * PI) * open_h + (smile_l + smile_r) * 0.05 * scale * sin(t * PI)
		mouth.append(p)
	ci.draw_colored_polygon(mouth, MOUTH_DARK)
	if jaw > 0.2:
		ci.draw_rect(
			Rect2(m + Vector2(-half_w * 0.6, -0.04) * scale, Vector2(half_w * 1.2, 0.07) * scale),
			TEETH
		)
	var outline := mouth.duplicate()
	outline.append(mouth[0])
	ci.draw_polyline(outline, LIP, 0.05 * scale)
