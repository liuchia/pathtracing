extern highp vec3 pos;
extern highp vec3 dir;
extern highp float width;
extern highp float height;
extern highp float fov;
extern highp float time;
extern highp float lightRadiusMultiplier;
extern highp float mixRatio;
extern int materialStage;

const int NONE = -1;
const int PLANE = 0;
const int SPHERE = 1;
const int LIGHT = 2;

const highp vec3 AMBIENT = 0.1*vec3(135.0/255, 206.0/255, 235.0/255);

struct Sphere {
	highp vec3 pos;
	highp float radius;
	highp vec3 color;
	highp float roughness;
};

struct Plane {
	highp vec3 pos;
	highp vec3 normal;
	highp vec3 color;
	highp float roughness;
};

struct Ray {
	highp vec3 pos;
	highp vec3 dir;
};

struct Hit {
	int type;
	highp vec3 pos;
	highp vec3 normal;
	highp vec3 color;
	highp float shadow;
	highp float roughness;
	int id;
};

struct Light {
	highp vec3 pos;
	highp vec3 color;
	highp float radius;
};

Sphere spheres[] = Sphere[] (
	Sphere(vec3(6,0,3), 5, vec3(1), 0),
	Sphere(vec3(-6,0,4), 5, vec3(1), 1),
	Sphere(vec3(6,8,3), 3, vec3(0.75,0.25,0), 0.9),
	Sphere(vec3(3,-2,10), 3, vec3(0,0.75,0.5), 0.8),
	Sphere(vec3(-6,8,4), 3, vec3(0,0.5,0.75), 0.25)
);

Plane planes[] = Plane[] (
	//Plane(vec3(0,0,-35), vec3(0,0,1), vec3(1), 1),
	//Plane(vec3(0,0,35), vec3(0,0,-1), vec3(1), 1),
	Plane(vec3(0,-5,0), vec3(0,1,0), vec3(1), 1)
	//Plane(vec3(0,15,0), vec3(0,-1,0), vec3(1), 1),
	//Plane(vec3(-25,0,0), vec3(1,0,0), vec3(1), 1),
	//Plane(vec3(25,0,0), vec3(-1,0,0), vec3(1), 1)
);

Light lights[] = Light[] (
	Light(vec3(-19,15,28), vec3(.7, .3,.3), 1),
	Light(vec3(18,17,26), vec3(.3,.7,.7), 1)
	//Light(vec3(1,23,15), vec3(.5), 4)
);

//http://byteblacksmith.com/improvements-to-the-canonical-one-liner-glsl-rand-for-opengl-es-2-0/
highp vec2 randState = vec2(0);
highp float rand() {
    const highp float a = 12.9898;
    const highp float b = 78.233;
    const highp float c = 43758.5453;
    highp float dt = dot(randState.xy ,vec2(a,b));
    highp float sn = mod(dt,3.14159);
    highp float ans = fract(sin(sn) * c);
	randState += vec2(1);
	return ans;
}

highp vec2 rand2() {
	return vec2(rand() - 0.5, rand() - 0.5);
}

highp vec3 rand3() {
	return vec3(rand() - 0.5, rand() - 0.5, rand() - 0.5);
}

Hit raycast(Ray ray) {
	Hit data = Hit(-1, vec3(0), vec3(0), vec3(0), 0, NONE, 0);
	highp float dist = 1e6;
	for (int i = 0; i < spheres.length(); i++) {
		Sphere sphere = spheres[i];
		highp vec3 v = sphere.pos - ray.pos;
		highp float d = dot(ray.dir, v);
		if (d > 0) {
			highp vec3 perp = v - (ray.dir * d);
			highp float pmag = length(perp);
			if (pmag <= sphere.radius) {
				highp float xdist = d-sqrt(sphere.radius*sphere.radius - pmag*pmag);
				if (xdist < dist) {
					dist = xdist;
					data.type = SPHERE;
					data.pos = ray.pos + ray.dir * xdist;
					data.normal = normalize(data.pos - sphere.pos);
					data.color = sphere.color;
					data.id = i;
					data.roughness = sphere.roughness;
				}
			}
		}
	}

	for (int i = 0; i < lights.length(); i++) {
		Light light = lights[i];
		highp vec3 v = light.pos - ray.pos;
		highp float d = dot(ray.dir, v);
		if (d > 0) {
			highp vec3 perp = v - (ray.dir * d);
			highp float pmag = length(perp);
			highp float radius = light.radius;
			if (pmag <= light.radius) {
				highp float xdist = d - sqrt(radius*radius - pmag*pmag);
				if (xdist < dist) {
					dist = xdist;
					data.type = LIGHT;
					data.pos = ray.pos + ray.dir * xdist;
					data.normal = normalize(data.pos - light.pos);
					data.color = light.color;
					data.id = i;
				}
			}
		}
	}


	if (data.type != NONE) return data;

	for (int i = 0; i < planes.length(); i++) {
		Plane plane = planes[i];

		highp float denom = dot(ray.dir, plane.normal);
		highp vec3 normal = plane.normal * sign(denom);
		denom = dot(ray.dir, normal);
		if (denom > 1e-6) {
			highp float t = dot(plane.pos - ray.pos, normal) / denom;
			if (t > 0 && t < dist) {
				dist = t;
				vec3 pos = ray.pos + ray.dir * t;
				data.type = PLANE;
				data.pos = pos;
				data.normal = normalize(normal*-1);
				data.color = plane.color;
				data.id = i + spheres.length();
				data.roughness = plane.roughness;
			}
		}
	}

	return data;
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
	randState = screen_coords * time;

	if (materialStage != 0) {
		for (int i = 0; i < spheres.length(); i++) {
			if (materialStage == 1) spheres[i].roughness = 0;
			else if (materialStage == 2) spheres[i].roughness = 0.5;
			else spheres[i].roughness = 1;
		}
	}

	highp vec3 UP_VECTOR = normalize(vec3(0.0, 1.0, 0.0));
	highp vec3 FORE_VECTOR = normalize(dir);
	highp vec3 RIGHT_VECTOR = cross(FORE_VECTOR, UP_VECTOR);
	highp vec3 TOP_VECTOR = cross(RIGHT_VECTOR, FORE_VECTOR);

	highp float hfov = fov / height * width;
	highp float RIGHT_EXTENT = tan(hfov/2);
	highp float TOP_EXTENT = tan(fov/2);
	
	highp vec3 end_color = vec3(0);
	highp vec2 antialias = screen_coords + rand2();
	highp vec3 camera_dir = normalize(
		FORE_VECTOR
		+ RIGHT_VECTOR * (RIGHT_EXTENT * (antialias.x/width - 0.5) * 2)
		+ TOP_VECTOR * (TOP_EXTENT * (antialias.y/height - 0.5) * -2) 
	);

	for (int i = 0; i < lights.length(); i++) {
		lights[i].radius *= lightRadiusMultiplier;
	}

	// help from https://wwwtyro.net/2018/02/25/caffeine.html
	for (int times = 0; times < 15; times++) {
		for (int i = 0; i < lights.length(); i++) {
			Light light = lights[i];
			int depth = 0;
			highp vec3 mask = vec3(.2);
			Ray ray = Ray(pos, camera_dir);

			while (depth < 5) {
				Hit hit = raycast(ray);

				if (hit.type == LIGHT) {
					end_color += mask * hit.color;
					break;
				} else if (hit.type != NONE) {
					highp vec3 jitlight_pos = light.pos + rand3() * light.radius;
					highp vec3 jitlight_dir = normalize(jitlight_pos - hit.pos);

					Hit hit2 = raycast(Ray(hit.pos + jitlight_dir*0.001, jitlight_dir));
					mask *= hit.color;
					if (hit2.type == LIGHT && hit2.id == i) {
						highp float diffuse = clamp(dot(jitlight_dir, hit.normal), 0, 1);
						diffuse *= pow(asin(3 / distance(light.pos, ray.pos)), 1.3);
						end_color += mask * light.color * diffuse;
					}

					highp vec3 incoming = normalize(hit.pos - ray.pos);
					highp vec3 reflected = reflect(incoming, hit.normal);
					highp vec3 jitNormal = normalize(hit.normal + rand3());
					highp vec3 nextBounce = normalize(mix(reflected, jitNormal, hit.roughness));
					ray = Ray(hit.pos+nextBounce*0.001, nextBounce);
					depth += 1;
				} else {
					end_color += AMBIENT * mask;
					break;
				}
			}
		}
	}

	highp vec3 buffer_color = Texel(tex, texture_coords).xyz;
	return vec4(mix(buffer_color, end_color, mixRatio), 1.0);
}