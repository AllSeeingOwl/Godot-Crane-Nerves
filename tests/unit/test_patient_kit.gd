extends GutTest


func test_feature_point_scales_from_center() -> void:
	var center := Vector2(100, 200)
	assert_eq(PatientKit.feature_point(center, 10.0, "nose"), center + Vector2(0, 2.2))
	assert_eq(PatientKit.feature_point(center, 10.0, "top_of_head"), center + Vector2(0, -12.5))


func test_features_are_mirrored_left_and_right() -> void:
	for pair in [
		["eye_l", "eye_r"], ["cheek_l", "cheek_r"], ["jaw_l", "jaw_r"], ["ear_l", "ear_r"]
	]:
		var left: Vector2 = PatientKit.FEATURES[pair[0]]
		var right: Vector2 = PatientKit.FEATURES[pair[1]]
		assert_eq(left, Vector2(-right.x, right.y), "%s mirrors %s" % pair)


func test_ellipse_points_lie_on_the_ellipse() -> void:
	for p in PatientKit.ellipse_points(Vector2.ZERO, Vector2(4, 2), 16):
		assert_almost_eq(pow(p.x / 4.0, 2) + pow(p.y / 2.0, 2), 1.0, 0.0001)
