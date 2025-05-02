import esp32
import math
import encoding.hex

/**
 Returns the MAC address of the ESP.
 */
get-id -> string:
  return (hex.encode esp32.mac-address).stringify

/**
 Returns a default value if the provided one is equal to the comparison.
 */
or-else value/any compare/any default/any:
  if value == compare:
    return default

  return value

/**
 Constrains a value into a given range.
 */
clamp value/any min/any max/any:
  if value < min:
    return min

  if value > max:
    return max

  return value

/**
 Convert one range to another.
 */
map x/int in-min/int in-max/int out-min/int out-max/int -> int:
  return ((x.to-float - in-min) * (out-max - out-min) / (in-max - in-min) + out-min).to-int

/**
 Applique une courbe à une valeur.
 */
ease-in-out x/float -> float:
  if x < 0.5:
    return 2.0 * x * x

  return 1.0 - (2.0 * (1.0 - x) * (1.0 - x))

/**
 Allows you to check that the list is indeed made up of three colors.
 */
is-color color/List:
  if color.size == 3:
    for i := 0; i < 3; ++i:
      if color[i] < 0 and color[i] > 255:
        return false

    return true

  return false

/**
 Change from a range to a percentage.
 */
value-to-percent value/int min/int max/int -> int:
  return ((value - min).to-float / (max - min) * 100).to-int

/**
 Changes an unsigned 8-bit number to a percentage.
 */
uint8-to-percent uint8/int -> int:
  return (uint8 / 255.0 * 100).to-int

/**
 Gives a temperature value with a percentage.
 */
percent-to-kelvin percent/int --min/int=2500 --max/int=7000 -> int:
  percent = clamp percent 0 100
  return map percent 0 100 min max

/**
 Convert Kelvin to Mired (two temperature units).
 */
kelvin-to-mired kelvin/int -> int:
  return (kelvin * 0.05).to-int

/**
 Reverses units while converting to Mired.
 */
kelvin-to-temp kelvin/int -> int:
  tmin ::= 50
  tmax ::= 1000
  kmin ::= 1000
  kmax ::= 20000

  kelvin = clamp kelvin kmin kmax
  return tmin + (((tmax - tmin) * (kmax - kelvin)) / (kmax - kmin))

/**
 Reverses units while converting to Mired while smoothing out changes.
 */
kelvin-to-adjusted-temp kelvin/int -> int:
  tmin ::= 50
  tmid ::= 175
  tmax ::= 1000
  kmin ::= 1000
  kmid ::= 10000
  kmax ::= 20000

  kelvin = clamp kelvin kmin kmax

  // Partie froide: entre 5714K et 20000K
  if kelvin >= kmid: 
    normalized := (kelvin - kmid).to_float / (kmax - kmid)
    adjusted := ease-in-out normalized
    return (tmid + (tmin - tmid) * adjusted).to_int

  // Partie chaude: entre 1000K et 5714K
  normalized := (kelvin - kmin).to_float / (kmid - kmin)
  adjusted := ease-in-out normalized
  return (tmax + (tmid - tmax) * normalized).to_int

/**
 Switches from a color wheel to a list of three colors (i.e. RGB).
 */
hue-to-rgb hue/int -> Map:
  hue %= 360
  if hue < 0:
    hue += 360
    if hue < 0:
      hue = 0

  h/int := hue / 60
  f/float := (hue % 60) / 60.0

  p/int := 0
  q/int := ((1.0 - f) * 255).to-int
  t/int := (f * 255).to-int

  r/int := 255
  g/int := 255
  b/int := 255

  if h == 0:
    g = t
    b = p
  else if h == 1:
    r = q
    b = p
  else if h == 2:
    r = p
    b = t
  else if h == 3:
    r = p
    g = q
  else if h == 4:
    r = t
    g = p
  else:
    g = p
    b = q

  return {
    "hue": hue,
    "r": r,
    "g": g,
    "b": b
  }

/**
 Allows brightness values ​​to be adapted to the non-linear perception of the human eye, and/or to the physical characteristics of screens.
 */
gamma_correction v/float -> float:
  if v > 0.04045:
    return math.pow ((v + 0.055) / 1.055) 2.4
  return v / 12.92

/**
 Convert color values ​​to XY format.
 */
rgb_to_xy r/int g/int b/int -> List:
  // Normalisation RGB [0, 1]
  r_f/float := r / 255.0
  g_f/float := g / 255.0
  b_f/float := b / 255.0

  // Correction gamma (sRGB)
  r_lin/float := gamma_correction r_f
  g_lin/float := gamma_correction g_f
  b_lin/float := gamma_correction b_f

  // Conversion RGB ➜ XYZ
  X/float := r_lin * 0.4124 + g_lin * 0.3576 + b_lin * 0.1805
  Y/float := r_lin * 0.2126 + g_lin * 0.7152 + b_lin * 0.0722
  Z/float := r_lin * 0.0193 + g_lin * 0.1192 + b_lin * 0.9505

  // Conversion XYZ ➜ XY
  total := X + Y + Z
  if total == 0.0:
    return [0.0, 0.0]

  x/float := X / total
  y/float := Y / total

  return [x, y]

/**
 Converts color values ​​to digital format.
 */
rgb-to-int r/int g/int b/int -> int:
  return (r << 16) + (g << 8) + b