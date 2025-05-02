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
  data := { "state": state ? "ON" : "OFF", "transition": .5 }

  if brightness > 0 and brightness <= 255:
    data["brightness"] = brightness

  if temperature >= 1000 and temperature <= 20000:
    data["color_temp"] = kelvin-to-adjusted-temp temperature

  if is-color rgb:
    xy := rgb_to_xy rgb[0] rgb[1] rgb[2]
    data["color_xy"] = xy

  if _client != null:
    _client.publish ("zigbee2mqtt/" + addr + "/set") (json.encode data)