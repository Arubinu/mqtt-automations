import math
import mqtt
import encoding.json

import ..utils

name ::= "Zigbee2MQTT"


_client/mqtt.Client? := null


/**
 Returns the initialized MQTT client
 */
get:
  return _client

/**
 Defines an already initialized client
 */
set client/mqtt.Client:
  _client = client

/**
 Connect and set the connection to the MQTT broker
  $client-id  allows you to identify the connected client
  $host       MQTT broker IP address
 */
connect client-id/string host/string username/string password/string:
  options := mqtt.SessionOptions
    --client-id=client-id
    --username=username
    --password=password

  _client = mqtt.Client --host=host
  _client.start --options=options

/**
 Closes and deletes the connection to the MQTT broker
 */
close:
  _client.close
  _client = null

/**
 Builds the object and sends it to the desired device.
  $addr         name given to the Zigbee device
  $state        turns the device on/off
  $brightness   [1-255]
  $temperature  [1000-20000]
  $rgb          [[0-255], [0-255], [0-255]]
 */
send addr/string --state/bool=true --brightness/int=-1 --temperature/int=-1 --rgb/List=[]:
  data := { "state": state ? "ON" : "OFF" }

  if brightness > 0 and brightness <= 255:
    data["brightness"] = brightness

  if temperature >= 1000 and temperature <= 20000:
    data["color_temp"] = kelvin-to-adjusted-temp temperature

  if is-color rgb:
    xy := rgb_to_xy rgb[0] rgb[1] rgb[2]
    data["color_xy"] = xy

  if _client != null:
    _client.publish ("zigbee2mqtt/" + addr + "/set") (json.encode data)


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