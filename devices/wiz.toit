import net
import net.udp
import encoding.json

import ..utils

name ::= "WiZ"


/**
 Builds the object and sends it to the desired device.
  $addr         IP address of the desired device
  $state        turns the device on/off
  $brightness   [1-255]
  $temperature  [2900-7000]
  $rgb          [[0-255], [0-255], [0-255]]
 */
send addr/string --state/bool=true --brightness/int=-1 --temperature/int=-1 --rgb/List=[]:
  port := 38899
  data := {
    "method": "setPilot",
    "params": {
      "state": state,
    }
  }

  if brightness > 0 and brightness <= 255:
    data["params"]["dimming"] = uint8-to-percent brightness

  if temperature >= 2900 and temperature <= 7000:
    data["params"]["temp"] = temperature

  if is-color rgb:
    data["params"]["r"] = rgb[0]
    data["params"]["g"] = rgb[1]
    data["params"]["b"] = rgb[2]

  network := net.open
  socket := network.udp-open
  socket_address := net.SocketAddress (net.IpAddress.parse addr) port
  socket.connect socket_address

  datagram := udp.Datagram (json.encode data) socket_address
  socket.send datagram
  socket.close