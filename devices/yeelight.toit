import net
import encoding.json

import ..utils

name ::= "Yeelight"


id := 1


/**
 Builds the object and sends it to the desired device.
  $addr         IP address of the desired device (add "bg:" in front of the address for the back light)
  $state        turns the device on/off
  $brightness   [1-255]
  $temperature  [2900-7000]
  $rgb          [[0-255], [0-255], [0-255]]
 */
send addr/string --state/bool=true --brightness/int=-1 --temperature/int=-1 --rgb/List=[]:
  port := 55443
  is-background := false

  // Set power
  split ::= addr.split ":"
  if split.size == 2:
    addr = split[1]
    if split[0] == "bg":
      is-background = true

  data := {
    "id": id++,
    "method": "set_power",
    "params": [(state ? "on" : "off"), "smooth", 500]
  }

  if temperature > -1:
    data["params"].add 1
  else if is-color rgb:
    data["params"].add 2

  if is-background:
    data["method"] = "bg_" + data["method"]

  network := net.open
  socket := network.tcp-connect addr port
  socket.out.write ((json.encode data).to-string + "\r\n")
  socket.close

  // Set mode
  data = {
    "id": id++,
    "method": null,
    "params": [null, "smooth", 500]
  }

  if brightness > 0 and brightness <= 255:
    data["method"] = "set_bright"
    data["params"][0] = uint8-to-percent brightness

  if temperature >= 2700 and temperature <= 6500:
    data["method"] = "set_ct_abx"
    data["params"][0] = temperature

  if is-color rgb:
    data["method"] = "set_rgb"
    data["params"][0] = rgb-to-int rgb[0] rgb[1] rgb[2]

  if data["method"] != null:
    if is-background:
      data["method"] = "bg_" + data["method"]

    socket = network.tcp-connect addr port
    socket.out.write ((json.encode data).to-string + "\r\n")
    socket.close