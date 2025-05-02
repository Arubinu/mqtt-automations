import gpio
import encoding.json

import .enums
import .utils
import .classes.ikea-styrbar as switch
import .devices.z2m as z2m

import .rooms.init as rooms


LED_BUILTIN ::= 2 // -1 to disable

MQTT_ID ::= get-id
MQTT_NAME ::= "ESPAutomate"
MQTT_HOST ::= "192.168.1.2"
MQTT_USERNAME ::= ""
MQTT_PASSWORD ::= ""


main:
  // Turns on the ESP LED to signal that the program is running
  if LED_BUILTIN >= 0:
    pin/gpio.Pin ::= gpio.Pin LED_BUILTIN --output
    pin.set 1

  // Starts the connection to the MQTT broker
  z2m.connect MQTT_ID MQTT_HOST MQTT_USERNAME MQTT_PASSWORD

  // Initializes all switches and their devices
  rooms.init