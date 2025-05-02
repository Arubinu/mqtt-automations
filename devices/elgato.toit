import io
import net
import http
import encoding.json

import ..utils

name ::= "Elgato"


/**
 Builds the object and sends it to the desired device.
  $addr         IP address of the desired device
  $state        turns the device on/off
  $brightness   [1-255]
  $temperature  [2900-7000]
  $rgb          not supported
 */
send addr/string --state/bool=true --color/List=[] --brightness/int=-1 --temperature/int=-1 --rgb/List=[]:
  data := {
    "lights": [{
      "on": state ? 1 : 0
    }],
    "numberOfLights": 1
  }

  if brightness > 0 and brightness <= 255:
    data["lights"][0]["brightness"] = uint8-to-percent brightness

  if temperature >= 2900 and temperature <= 7000:
    data["lights"][0]["temperature"] = kelvin-to-mired temperature

  print "JSON: " + (json.encode data).to-string

  network := net.open
  client := http.Client network
  request := client.new-request "PUT"
    --host=addr
    --port=9123
    --path="/elgato/lights"
    --headers=(http.Headers.from-map {
      "Content-Type": "application/json"
    })

  request.body=io.Reader (json.encode data)
  request.send
  client.close