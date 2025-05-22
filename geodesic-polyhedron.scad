//=== octsphere.scad ===
/**
 * @file octsphere.scad
 * @brief Geodesic sphere or hemisphere based on an octahedron with equatorial polygonal symmetry.
 *
 * This OpenSCAD module/function generates a geodesic sphere or hemisphere with flat equators 
 * aligned with the XY, YZ, and XZ planes. It uses an octahedron base to maintain regular polygon
 * equators, unlike icosahedron-based geodesic domes which lack flat symmetry at the equator.
 *
 * ## Usage
 * Add this file to your `.scad` project and use one of the following methods:
 *
 * Modular rendering (similar to built-in `sphere()`):
 * ```scad
 * octsphere(r=radius);              // or:
 * octsphere(d=diameter);
 * ```
 *
 * Functional call (returns polyhedron data):
 * ```scad
 * mesh = octsphere(r=radius);
 * polyhedron(points = mesh[0], faces = mesh[1]);
 * ```
 *
 * Optional parameters:
 * - `r` / `d`  : radius or diameter (default = 1)
 * - `hemisphere` : true to generate a hemisphere (default = false)
 *
 * The `$fn`, `$fa`, and `$fs` special variables control polygon resolution. The number of equator sides
 * will snap to the nearest of the form 4×2ⁿ (e.g., 4, 8, 16, 32, 64, 128).
 *
 * ## Background
 * Octahedron-based geodesic spheres offer equators that lie in all three principal planes, which can 
 * better interface with other regular polygon geometry. This structure enables easier alignment with 
 * cylinders, prisms, and other modular shapes in parametric designs.
 *
 * For more hemisphere flexibility, see: [Geodesic Hemisphere](https://www.printables.com/model/129119)
 *
 * ## References and Acknowledgements
 * - Printables: https://www.printables.com/model/762498
 * - Thingiverse (octsphere): https://www.thingiverse.com/thing:6481347
 * - Geodesic Hemisphere: https://www.printables.com/model/129119
 * - Original Geodesic Sphere (by Jamie Kawabata): https://www.thingiverse.com/thing:1484333
 */

//=== Demo ===

$fn = 64;
translate([20, 0, 0]) color("pink") sphere(20); // normal sphere for comparison
translate([-20, 0, 0]) color("lightgreen") octsphere(20); // geodesic sphere

//=== Module: octahedral sphere or hemisphere ===

/**
 * @module octsphere
 * @brief Renders a geodesic octahedral sphere or hemisphere as a polyhedron.
 * @param r Radius of the sphere (default = -1; must be > 0 if used)
 * @param d Diameter of the sphere (default = -1; must be > 0 if used)
 * @param hemisphere If true, generates only the upper hemisphere
 */
module octsphere(r = -1, d = -1, hemisphere = false) {
  mesh = octsphere(r, d, hemisphere);
  polyhedron(points=mesh[0], faces=mesh[1]);
}

//=== Function: octahedral geodesic sphere or hemisphere ===

/**
 * @function octsphere
 * @brief Returns a [vertices, faces] array representing an octahedral geodesic polyhedron.
 * @param r Radius (preferred, optional)
 * @param d Diameter (alternative to r, optional)
 * @param hemisphere Generate only upper hemisphere if true
 * @return Array: [vertex list, face list]
 */
function octsphere(r = -1, d = -1, hemisphere = false) =
  let (
    rad = r > 0 ? r : d > 0 ? d / 2 : 1, // Default radius = 1
    fn = $fn,
    log2 = log(2.0),
    pn = (log(fn) - log(4)) / log2,
    dpn = [abs(4 * 2 ^ floor(pn) - fn), abs(4 * 2 ^ ceil(pn) - fn)],
    minidx = floor(argmin(dpn) / 2),
    levels = floor(pn) + (argmin(dpn) % 2),
    nlv = 4 * 2 ^ levels,
    octahedron = [
      [
        [0, 0, 1],
        [0, 1, 0],
        [0, -1, 0],
        [1, 0, 0],
        [-1, 0, 0],
        if (!hemisphere) [0, 0, -1],
      ],
      hemisphere ? [[0, 1, 3], [0, 3, 2], [0, 2, 4], [0, 4, 1]]
      : [
        [0, 1, 3],
        [0, 3, 2],
        [0, 2, 4],
        [0, 4, 1],
        [5, 3, 1],
        [5, 2, 3],
        [5, 4, 2],
        [5, 1, 4],
      ],
    ],
    subdivided = multi_subdiv_pf(octahedron, levels),
    vertices = hemisphere ? concat(
        subdivided[0], [
          for (n = [0:nlv]) let (t = n * 360 / nlv) [cos(t), sin(t), 0],
        ]
      )
    : subdivided[0],
    faces = hemisphere ? let (pstart = len(vertices) - nlv) concat(subdivided[1], [[for (n = [0:nlv - 1]) pstart + n]])
    : subdivided[1]
  ) [rad * vertices, faces];

//=== Support Functions ===

/**
 * @function argmin
 * @brief Return index of minimum value in a list.
 * @param v Array of values
 * @return Integer index of smallest value
 */
function argmin(v, k = 0, mem = [-1, ceil(1 / 0)]) =
  (k == len(v)) ? mem[0]
  : v[k] < mem[1] ? argmin(v, k + 1, [k, v[k]])
  : argmin(v, k + 1, mem);

/**
 * @function midpt
 * @brief Compute unit-length midpoint of two 3D points on a sphere.
 * @param p1 First 3D point
 * @param p2 Second 3D point
 * @return Midpoint vector normalized to length 1
 */
function midpt(p1, p2) =
  let (mid = 0.5 * (p1 + p2)) mid / norm(mid);

/**
 * @function subdivpf
 * @brief Subdivide each triangle face into 4 smaller triangles on a unit sphere.
 * @param pf Array of [points, faces]
 * @return Subdivided [points, faces]
 */
function subdivpf(pf) =
  let (p = pf[0], faces = pf[1]) [
      [
        // new points
        for (f = faces) let (p0 = p[f[0]], p1 = p[f[1]], p2 = p[f[2]]) each [p0, p1, p2, midpt(p0, p1), midpt(p1, p2), midpt(p0, p2)],
      ],
      [
        // new faces
        for (i = [0:len(faces) - 1]) let (base = 6 * i) each [
          [base, base + 3, base + 5],
          [base + 3, base + 1, base + 4],
          [base + 5, base + 4, base + 2],
          [base + 3, base + 4, base + 5],
        ],
      ],
  ];

/**
 * @function multi_subdiv_pf
 * @brief Recursively subdivide a polyhedron into finer faces.
 * @param pf Array of [points, faces]
 * @param levels Number of recursive subdivision levels
 * @return Refined [points, faces]
 */
function multi_subdiv_pf(pf, levels) =
  (levels == 0) ? pf
  : multi_subdiv_pf(subdivpf(pf), levels - 1);
