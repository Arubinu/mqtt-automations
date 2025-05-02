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