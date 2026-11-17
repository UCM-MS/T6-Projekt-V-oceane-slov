extends RefCounted

const SURFACE_Y := 64.0
const SWIM_BOUNDS := Rect2(218.0, SURFACE_Y, 4542.0, 1028.0)


static func floor_y(profile: PackedVector2Array, x: float) -> float:
	for index in range(profile.size() - 1):
		var left := profile[index]
		var right := profile[index + 1]
		if right.x > left.x and x >= left.x and x <= right.x:
			return lerpf(left.y, right.y, (x - left.x) / (right.x - left.x))
	return SWIM_BOUNDS.end.y
