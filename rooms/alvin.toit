import ..enums
import ..classes.ikea-styrbar as switch


device/int := 0
room_/switch.Listen? := null
default_color_/switch.Color? := null
default_brightness_/switch.Brightness? := null
default-temperature_/switch.Temperature? := null


/**
 Specify the switch to use.
  $default-color        instance to be used for different devices (working the same way)
  $default-brightness   instance to be used for different devices (working the same way)
  $default-temperature  instance to be used for different devices (working the same way)
 */
init
    --default-color/switch.Color
    --default-brightness/switch.Brightness
    --default-temperature/switch.Temperature:

  default_color_ = default_color
  default_brightness_ = default_brightness
  default-temperature_ = default-temperature

  room_ = switch.Listen "zigbee2mqtt/Alvin: Interrupteur" --default-index=2

/**
 Add all devices to control.
 */
add:
  plafonnier-temperature_/switch.Temperature := switch.Temperature --min=2000 --max=10000

  device = room_.add-device "192.168.200.94" DEVICE_PROTOCOL.Elgato --brightness=default-brightness_ --temperature=default-temperature_ // Elgato: Key Light Droite
  room_.add-action DEVICE_DIRECTION.Right DEVICE_ACTION.Simpleclick DEVICE_COMMAND.DevicePlus
  room_.add-action DEVICE_DIRECTION.Left DEVICE_ACTION.Simpleclick DEVICE_COMMAND.DeviceMinus
  room_.add-action DEVICE_DIRECTION.Up DEVICE_ACTION.Simpleclick DEVICE_COMMAND.TurnOn
  room_.add-action DEVICE_DIRECTION.Down DEVICE_ACTION.Simpleclick DEVICE_COMMAND.TurnOff
  room_.add-action DEVICE_DIRECTION.Up DEVICE_ACTION.Longpress DEVICE_COMMAND.BrightnessPlus --delay=500
  room_.add-action DEVICE_DIRECTION.Down DEVICE_ACTION.Longpress DEVICE_COMMAND.BrightnessMinus --delay=500
  room_.add-action DEVICE_DIRECTION.Right DEVICE_ACTION.Longpress DEVICE_COMMAND.TemperaturePlus --delay=500
  room_.add-action DEVICE_DIRECTION.Left DEVICE_ACTION.Longpress DEVICE_COMMAND.TemperatureMinus --delay=500
  room_.add-action DEVICE_DIRECTION.Down DEVICE_ACTION.Doubleclick DEVICE_COMMAND.TurnAllOff --reset-index

  device = room_.add-device "192.168.200.83" DEVICE_PROTOCOL.Elgato --brightness=default-brightness_ --temperature=default-temperature_ --add_in_last // Elgato: Key Light Gauche
  room_.add-action DEVICE_DIRECTION.Right DEVICE_ACTION.Simpleclick DEVICE_COMMAND.DevicePlus
  room_.add-action DEVICE_DIRECTION.Left DEVICE_ACTION.Simpleclick DEVICE_COMMAND.DeviceMinus
  room_.add-action DEVICE_DIRECTION.Up DEVICE_ACTION.Simpleclick DEVICE_COMMAND.TurnOn
  room_.add-action DEVICE_DIRECTION.Down DEVICE_ACTION.Simpleclick DEVICE_COMMAND.TurnOff
  room_.add-action DEVICE_DIRECTION.Up DEVICE_ACTION.Longpress DEVICE_COMMAND.BrightnessPlus --delay=500
  room_.add-action DEVICE_DIRECTION.Down DEVICE_ACTION.Longpress DEVICE_COMMAND.BrightnessMinus --delay=500
  room_.add-action DEVICE_DIRECTION.Right DEVICE_ACTION.Longpress DEVICE_COMMAND.TemperaturePlus --delay=500
  room_.add-action DEVICE_DIRECTION.Left DEVICE_ACTION.Longpress DEVICE_COMMAND.TemperatureMinus --delay=500
  room_.add-action DEVICE_DIRECTION.Down DEVICE_ACTION.Doubleclick DEVICE_COMMAND.TurnAllOff --reset-index

  device = room_.add-device "192.168.200.110" DEVICE_PROTOCOL.WiZ --brightness=default-brightness_ --color=default-color_ // WiZ: Spot
  room_.add-action DEVICE_DIRECTION.Right DEVICE_ACTION.Simpleclick DEVICE_COMMAND.DevicePlus
  room_.add-action DEVICE_DIRECTION.Left DEVICE_ACTION.Simpleclick DEVICE_COMMAND.DeviceMinus
  room_.add-action DEVICE_DIRECTION.Up DEVICE_ACTION.Simpleclick DEVICE_COMMAND.TurnOn
  room_.add-action DEVICE_DIRECTION.Down DEVICE_ACTION.Simpleclick DEVICE_COMMAND.TurnOff
  room_.add-action DEVICE_DIRECTION.Up DEVICE_ACTION.Longpress DEVICE_COMMAND.BrightnessPlus --delay=500
  room_.add-action DEVICE_DIRECTION.Down DEVICE_ACTION.Longpress DEVICE_COMMAND.BrightnessMinus --delay=500
  room_.add-action DEVICE_DIRECTION.Right DEVICE_ACTION.Longpress DEVICE_COMMAND.ColorPlus --delay=500
  room_.add-action DEVICE_DIRECTION.Left DEVICE_ACTION.Longpress DEVICE_COMMAND.ColorMinus --delay=500
  room_.add-action DEVICE_DIRECTION.Down DEVICE_ACTION.Doubleclick DEVICE_COMMAND.TurnAllOff --reset-index

  device = room_.add-device "Alvin: Plafonnier" DEVICE_PROTOCOL.Zigbee2MQTT --brightness=default-brightness_ --temperature=plafonnier-temperature_ // Zigbee2MQTT: Plafonnier
  room_.add-action DEVICE_DIRECTION.Right DEVICE_ACTION.Simpleclick DEVICE_COMMAND.DevicePlus
  room_.add-action DEVICE_DIRECTION.Left DEVICE_ACTION.Simpleclick DEVICE_COMMAND.DeviceMinus
  room_.add-action DEVICE_DIRECTION.Up DEVICE_ACTION.Simpleclick DEVICE_COMMAND.TurnOn
  room_.add-action DEVICE_DIRECTION.Down DEVICE_ACTION.Simpleclick DEVICE_COMMAND.TurnOff
  room_.add-action DEVICE_DIRECTION.Up DEVICE_ACTION.Longpress DEVICE_COMMAND.BrightnessPlus --delay=500
  room_.add-action DEVICE_DIRECTION.Down DEVICE_ACTION.Longpress DEVICE_COMMAND.BrightnessMinus --delay=500
  room_.add-action DEVICE_DIRECTION.Right DEVICE_ACTION.Longpress DEVICE_COMMAND.TemperaturePlus --delay=500
  room_.add-action DEVICE_DIRECTION.Left DEVICE_ACTION.Longpress DEVICE_COMMAND.TemperatureMinus --delay=500
  room_.add-action DEVICE_DIRECTION.Down DEVICE_ACTION.Doubleclick DEVICE_COMMAND.TurnAllOff --reset-index

  device = room_.add-device "192.168.200.66" DEVICE_PROTOCOL.WiZ --no-doubleclick-all-off // WiZ: Imprimante 3D
  room_.add-action DEVICE_DIRECTION.Right DEVICE_ACTION.Simpleclick DEVICE_COMMAND.DevicePlus
  room_.add-action DEVICE_DIRECTION.Left DEVICE_ACTION.Simpleclick DEVICE_COMMAND.DeviceMinus
  room_.add-action DEVICE_DIRECTION.Up DEVICE_ACTION.Simpleclick DEVICE_COMMAND.TurnOn
  room_.add-action DEVICE_DIRECTION.Down DEVICE_ACTION.Longpress DEVICE_COMMAND.TurnOff --delay=500
  room_.add-action DEVICE_DIRECTION.Down DEVICE_ACTION.Doubleclick DEVICE_COMMAND.TurnAllOff --reset-index

/**
 Returns the number of the currently targeted device.
 */
get-index -> int:
  return room_.get-index

/**
 Start listening for MQTT messages.
 */
lock-subscribe lock/bool=true:
  room_.lock-subscribe lock