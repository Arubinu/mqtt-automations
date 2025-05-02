import encoding.json

import ..utils

name ::= "DEBUG"


/**
 Builds the object and sends it to the desired device.
  $addr         name to display in the debug console
  $state        turns the device on/off
  $brightness   [1-255]
  $temperature  [1000-20000]
  $rgb          [[0-255], [0-255], [0-255]]
 */
send addr/string --state/bool=true --brightness/int=-1 --temperature/int=-1 --rgb/List=[]:
  data := { "state": state ? "ON" : "OFF" }

  if brightness > 0 and brightness <= 255:
    data["brightness"] = uint8-to-percent brightness

  if temperature >= 1000 and temperature <= 20000:
    data["temperature"] = kelvin-to-mired temperature

  if is-color rgb:
    data["color"] = { "r": rgb[0], "g": rgb[1], "b": rgb[2] }

  print "JSON[$addr]: " + (json.encode data).to-string