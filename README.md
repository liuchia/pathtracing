![pathtracing](https://raw.githubusercontent.com/liuchia/pathtracing/media/pathtracebanner.png)

---

Path tracing is a Monte Carlo method to rendering introduced in James Kajiya's paper, *The Rendering Equation* (1986).

Here, I implement a simple pathtracer in a GLSL shader with Love2D providing an easy means of window instantiation and keyboard controls.
In each frame, each pixel fires several rays with random perturbations. The results of these samples are aggregated, resulting in a single colour.
Many samples are needed for a clear image to emerge so I combine the results of several frames over time. An alternative is to use a noise reduction filter.

---

Like raytracing, pathtracing can model effects such as reflected light, color bleeding and reflections. Here, I associate each object with a 'roughness' value to allow each sphere to have different BRDFs (glossy, matte, reflective). A reflective object (roughness of 0) will bounce light perfectly whereas a matte (roughness of 1) object's reflection will be fired in a random direction.
In between roughness values get their bounce direction by lerping between a perfect reflection and a random direction. Aggregating multiple samples is needed to obtain a smooth result.

---

There are several advantages of path tracing over conventional raytracing:

For one, taking multiple random rays within a pixel naturally gives us antialiasing. Soft shadows are also easy - lights can be treated as volumes and each sample chooses a random point within that volume as the position of the light.
Other effects (which I have not implemented) include depth of field and motion blur.

---

To run, run [love](https://love2d.org/) on the directory containing *main.lua*. Pressing *s* will toggle between small and large lights. Hold *r* to rotating the camera and tapping *m* will switch between the materials described above.

---

Resources

* https://wwwtyro.net/2018/02/25/caffeine.html
* https://iquilezles.org/www/articles/simplepathtracing/simplepathtracing.htm
* https://en.wikipedia.org/wiki/Path_tracing
