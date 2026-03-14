# GeodesicDomeDesigner

## The Dome That Almost Wasn't

Maya had been staring at the same blank graph paper for forty minutes when her
colleague dropped a link in the team chat: *"You might like this."*

She was an architect by training, a tinkerer by temperament, and she had spent
the better part of a week trying to figure out how many triangular panels she
would need for the community greenhouse her neighborhood cooperative wanted to
build. Geodesic domes are elegant in theory — a hemisphere approximated by a
mesh of triangles derived from a subdivided icosahedron — but the geometry gets
complicated fast. The number of unique strut lengths, the angles, the sheer
count of faces: it all multiplied with every increase in *frequency*, the
parameter that controls how finely the icosahedron's faces are subdivided.

She clicked the link.

GeodesicDomeDesigner opened to a clean interface with two sliders and a
color picker. She typed in a diameter of **240 inches** — twenty feet, the
footprint she had in mind — and nudged the frequency slider to **3**. The app
responded immediately: a 3D dome rotated gently on screen, its triangular
panels shaded in the soft greens she had selected. She could see the geometry
working in real time, each face a product of the subdivision algorithm that
walks the icosahedron's twenty base triangles and recursively splits them until
the sphere approximation is smooth enough to be practical.

What surprised her was how *tactile* it felt. She rotated the dome with a
finger swipe, zoomed in to inspect individual panels, toggled the floor guide
on to see how the base ring would sit on level ground. She switched the
background from the default studio grey to an outdoor sky environment and
suddenly the dome looked like it was already standing in a field.

She changed the frequency to **4**. The panel count jumped — more triangles,
a rounder profile, a structure that would feel less angular from the inside.
She changed it back to **3**. For a greenhouse, the larger panels meant more
glazing area per seam, which was actually what she wanted.

The color picker let her assign multiple hues to the panels, cycling through
them as the geometry was built. She chose a palette of translucent greens and
warm ambers, imagining how the light would filter through in the morning. The
app rendered the result without hesitation.

By the time she looked up, an hour had passed. She had a panel count, a visual
she could share with the cooperative, and a much clearer sense of what she was
actually proposing to build. The dome that had been stuck on graph paper was
now a rotating 3D model on her screen, ready to be explained to people who had
never thought about icosahedra in their lives.

She exported the view, attached it to an email, and hit send.

---

## Get Started

GeodesicDomeDesigner is a native macOS and iOS application built with SwiftUI
and SceneKit. Clone the repository and open it in Xcode 15 or later.

```bash
git clone https://github.com/aaronrene/GeodesicDomeDesigner.git
cd GeodesicDomeDesigner
open "Geodesic Dome Designer.xcodeproj"
```

Select your target device (Mac, iPhone, or iPad) in the Xcode toolbar and
press **⌘R** to build and run.

**Inputs:**
- **Diameter** — the dome's outer diameter in inches
- **Frequency** — subdivision level (higher = more triangles, rounder dome)
- **Colors** — one or more panel colors, cycled across the generated faces

No external dependencies or package manager setup is required.
