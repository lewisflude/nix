See <https://git.gnome.org/browse/gtk+/tree/gtk/gtkcssstylepropertyimpl.c?h=gtk-3-8#n878> and <https://git.gnome.org/browse/gtk+/tree/gtk/gtkcssstyleproperty.c?h=gtk-3-8#n272>

_Ani_ = Property can be animated
_Inh_ = Property inherits from parent widget

**Property name**           | **Type**  | **Default**    | Ani | Inh | **Notes**
--------------------------- | --------- | -------------- | --- | --- | ---------
`animation`                 |           |                |     |     | Sets all `animation-*` properties except `animation-play-state`; specify iteration count first, then duration, then delay
`animation-delay`           |array(time)| `0`            | N   | N
`animation-direction`       |array(direction)| `normal`  | N   | N
`animation-duration`        |array(time)| `0`            | N   | N
`animation-fill-mode`       |array(fill)| `none`         | N   | N
`animation-iteration-count` |array(iteration count)| `1` | N   | N
`animation-name`            |array(string)| `none`       | N   | N
`animation-play-state`      |play state | `running`      | N   | N
`animation-timing-function` |array(ease)| `ease`         | N   | N
`background`                |           |                |     |     | Sets all `background-*` properties; separate size and position with `"/"`; clip and origin are set to the same value
`background-clip`           |array(area)| `border-box`   | N   | N
`background-color`          | color     | `black`        | Y   | N
`background-image`          |array(image)| `none`        | Y   | N
`background-origin`         |array(area)| `padding-box`  | N   | N
`background-position`       |array(position)| `0 0`      | Y   | N
`background-repeat`         |array(repeat)|`repeat repeat`| N  | N
`background-size`       |array(background size)|`auto auto`| Y | N
`border`                    |           |                |     |     | Sets color, style, and width of all four sides at once; clears all `border-image-*` properties
`border-bottom`             |           |                |     |     | Sets color, style, and width in any order
`border-left`               |           |                |     |     | ditto
`border-right`              |           |                |     |     | ditto
`border-top`                |           |                |     |     | ditto
`border-color`              |           |                |     |     | Sets all `border-*-color` properties
`border-bottom-color`       | color     | `currentColor` | Y   | N
`border-left-color`         | color     | `currentColor` | Y   | N
`border-right-color`        | color     | `currentColor` | Y   | N
`border-top-color`          | color     | `currentColor` | Y   | N
`border-style`              |           |                |     |     | Sets all `border-*-style` properties
`border-bottom-style`       |border style| `none`        | N   | N
`border-left-style`         |border style| `none`        | N   | N
`border-right-style`        |border style| `none`        | N   | N
`border-top-style`          |border style| `none`        | N   | N
`border-width`              |           |                |     |     | Sets all `border-*-width` properties
`border-bottom-width`       | length    | `0`            | Y   | N
`border-left-width`         | length    | `0`            | Y   | N
`border-right-width`        | length    | `0`            | Y   | N
`border-top-width`          | length    | `0`            | Y   | N
`border-radius`             |           |                |     |     | Sets all `border-*-radius` properties (`x-values ("/" y-values)?`)
`border-bottom-left-radius` | corner    | `0 0`          | Y   | N
`border-bottom-right-radius`| corner    | `0 0`          | Y   | N
`border-top-left-radius`    | corner    | `0 0`          | Y   | N
`border-top-right-radius`   | corner    | `0 0`          | Y   | N
`border-image`              |           |                |     |     | Sets all `border-image-*` properties; separate slice and width by `"/"`
`border-image-repeat`       | repeat  | `stretch stretch` | N  | N
`border-image-slice`        | border |`100% 100% 100% 100%`| N | N   | `"auto"` not allowed
`border-image-source`       | image     | `none`         | Y   | N
`border-image-width`        | border    | `1 1 1 1`      | N   | N   | `"fill"` not allowed
`box-shadow`                | shadow    | `none`         | Y   | N   | Currently, only inset box shadows work
`color`                     | color     | `white`        | Y   | Y
`engine`                    | string    | `none`?        | N   | N   | Theming engine
`font`                      |           |                |     |     | Parsed by `pango_font_description_from_string()`; sets all `font-*` properties
`font-family`               | array     | `"Sans"`       | N   | Y
`font-size`                 | length    | `medium`       | Y   | Y
`font-style`                | style     | `normal`       | N   | Y
`font-variant`              | variant   | `normal`       | N   | Y
`font-weight`               | weight    | `normal`       | N   | Y
`gtk-key-bindings`          |array(string)| `none`       | N   | N
`icon-shadow`               | shadow    | `none`         | Y   | Y
`margin`                    |           |                |     |     | Sets all `margin-*` properties
`margin-bottom`             | length    | `0`            | Y   | N
`margin-left`               | length    | `0`            | Y   | N
`margin-right`              | length    | `0`            | Y   | N
`margin-top`                | length    | `0`            | Y   | N
`opacity`                   | number    | `1`            | Y   | N   | Note that it is applied cumulatively to the opacity set by `gtk_widget_set_opacity()`! Also, the "animatable" is a lie.
`outline-color`             | color     | `currentColor` | N   | N
`outline-style`             |border style| `none`        | N   | N
`outline-offset`            | length    | `0`            | N   | N
`outline-width`             | length    | `0`            | Y   | N
`padding`                   |           |                |     |     | Sets all `padding-*` properties
`padding-bottom`            | length    | `0`            | Y   | N
`padding-left`              | length    | `0`            | Y   | N
`padding-right`             | length    | `0`            | Y   | N
`padding-top`               | length    | `0`            | Y   | N
`text-shadow`               | shadow    | `none`         | Y   | Y
`transition`                |           |                |     |     | Sets all `transition-*` properties; specify duration before delay
`transition-delay`          |array(time)| `0`            | N   | N
`transition-duration`       |array(time)| `0`            | N   | N
`transition-property`       |array(string)| `"all"`      | N   | N
`transition-timing-function`|array(ease)| `ease`         | N   | N

For the shorthand properties that set values on four sides at once, you can give from one to four values. The order is **top, right, bottom, left**. If **right** or **bottom** are not given, they are equal to **top**. If **left** is not given, it is equal to **right** (and therefore **top** if **right** is not given.)

## Syntax of types of values

```
area:
  "border-box" | "padding-box" | "content-box"

array:
  value ("," value)*

background repeat:
  "none" | "repeat-x" | "repeat-y" | ("no-repeat" | "repeat" | "round" | "space"){1, 2}

background size:
  "cover" | "contain" | ("auto" | positive length or percentage){2}

border:
  "fill"? ("auto" | number){1,4} "fill"?

border repeat:
  ("stretch" | "repeat" | "round" | "space"){1, 2} | "none"

border style:
  "none" | "solid" | "inset" | "outset" | "hidden" | "dotted" | "dashed" | "double" | "groove" | "ridge"

color:
  "currentColor" | "transparent" | "@"defined-color | color-function | "#"(rgb | rrggbb) | named-color
color-function:
  rgba(0-255 or percentage, 0-255 or percentage, 0-255 or percentage, double)
  | rgb(0-255 or percentage, 0-255 or percentage, 0-255 or percentage)
  | lighter(color) => 1.3 * color
  | darker(color) => 0.7 * color
  | shade(color, double) => double * color
  | alpha(color, double)
  | mix(color, color, double)
  | -gtk-win32-color(name, int)
named-color:
  name understood by gdk_rgba_parse() (http://en.wikipedia.org/wiki/X11_color_names)

corner:
  (positive length or percentage){1,2}
  // refers to x and y; if only x given, then y = x

direction:
  "normal" | "reverse" | "alternate" | "alternate-reverse"

ease:
  "linear" | "ease-in-out" | "ease-in" | "ease-out" | "ease" | "step-start" | "step-end"
  | "steps" "(" unsigned-int ("," ("start" | "end"))? ")"
  | "cubic-bezier" "(" double 0-1 "," double 0-1 "," double 0-1 "," double 0-1 ")"

engine:
  "none" | string

fill:
  "none" | "forwards" | "backwards" | "both"

font size:
  "smaller" | "larger" | "xx-small" | "x-small" | "small" | "medium" | "large" | "x-large" | "xx-large"

font style:
  "normal" | "oblique" | "italic"

font variant:
  "normal" | "small-caps"

font weight:
  "100" | "200" | "300" | "normal" | "400" | "500" | "600" | "bold" | "700" | "800" | "900"
  // normal = 400, bold = 700

image:
  "none"
  | "url(" string ")"
  | "-gtk-gradient(" ("radial" ("," gradient-x gradient-y "," double){2} | "linear" ("," gradient-x gradient-y){2}) ("," ("from" "(" | "to" "(" | "color-stop" "(" double ",") string ")")+ ")"
  | "-gtk-win32-theme-part(" string "," int int ("," ("over" "(" int int "," double | "margins" "(" int{1,4} ) ")")+ ")"
  | ("linear-gradient(" | "repeating-linear-gradient(") (("to" any order(("top" | "bottom"), ("left" | "right")) | angle) ",")? (color (length | percentage)? ("," (color (length | percentage)?)*)? ")"
  | "cross-fade(" percentage? image ("," image)? ")"
  // if percentage is not given, then 50%. in future, should be able to specify colors as well
gradient-x:
  "left" | "right" | "center" | double
gradient-y:
  "top" | "bottom" | "center" | double

iteration count:
  "infinite" | number

play state:
  "running" | "paused"

position:
  ("left" | "right" | "top" | "bottom" | "center" | length | percentage){1, 2}
  // in such a combination that one horizontal and one vertical value are specified

shadows:
  "none" | array("inset"? number number positive-number? number? "inset"? color)
  // numbers: hoffset voffset radius=0.0 spread=0.0
```
