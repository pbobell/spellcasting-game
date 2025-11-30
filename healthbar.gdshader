shader_type spatial;

uniform float health = 1;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	if (UV.x < health) {
		ALBEDO = vec3(0, 1, 0);
	} else {
		ALBEDO = vec3(1, 0, 0);
	}
}
