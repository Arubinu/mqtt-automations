import ..enums
import ..classes.ikea-styrbar as switch

device/int := 0
room_/switch.Listen? := null
default_color_/switch.Color? := null
default_brightness_/switch.Brightness? := null
default-temperature_/switch.Temperature? := null

init --default-color/switch.Color --default-brightness/switch.Brightness --default-temperature/switch.Temperature:
  default_color_ = default_color
  default_brightness_ = default_brightness
  default-temperature_ = default-temperature

  room_ = switch.Listen "zigbee2mqtt/MySwitch" --default-index=0

add:
  device = room_.add-device "Light: Temperature" DEVICE_PROTOCOL.Debug --brightness=default-brightness_ --temperature=default-temperature_
  room_.add-action DEVICE_DIRECTION.Right DEVICE_ACTION.Simpleclick DEVICE_COMMAND.DevicePlus
  room_.add-action DEVICE_DIRECTION.Left DEVICE_ACTION.Simpleclick DEVICE_COMMAND.DeviceMinus
  room_.add-action DEVICE_DIRECTION.Up DEVICE_ACTION.Simpleclick DEVICE_COMMAND.TurnOn
  room_.add-action DEVICE_DIRECTION.Down DEVICE_ACTION.Simpleclick DEVICE_COMMAND.TurnOff
  room_.add-action DEVICE_DIRECTION.Up DEVICE_ACTION.Longpress DEVICE_COMMAND.BrightnessPlus --delay=500
  room_.add-action DEVICE_DIRECTION.Down DEVICE_ACTION.Longpress DEVICE_COMMAND.BrightnessMinus --delay=500
  room_.add-action DEVICE_DIRECTION.Right DEVICE_ACTION.Longpress DEVICE_COMMAND.TemperaturePlus --delay=500
  room_.add-action DEVICE_DIRECTION.Left DEVICE_ACTION.Longpress DEVICE_COMMAND.TemperatureMinus --delay=500
  room_.add-action DEVICE_DIRECTION.Down DEVICE_ACTION.Doubleclick DEVICE_COMMAND.TurnAllOff --reset-index

  device = room_.add-device "Light: Color" DEVICE_PROTOCOL.Debug --brightness=default-brightness_ --color=default-color_
  room_.add-action DEVICE_DIRECTION.Right DEVICE_ACTION.Simpleclick DEVICE_COMMAND.DevicePlus
  room_.add-action DEVICE_DIRECTION.Left DEVICE_ACTION.Simpleclick DEVICE_COMMAND.DeviceMinus
  room_.add-action DEVICE_DIRECTION.Up DEVICE_ACTION.Simpleclick DEVICE_COMMAND.TurnOn
  room_.add-action DEVICE_DIRECTION.Down DEVICE_ACTION.Simpleclick DEVICE_COMMAND.TurnOff
  room_.add-action DEVICE_DIRECTION.Up DEVICE_ACTION.Longpress DEVICE_COMMAND.BrightnessPlus --delay=500
  room_.add-action DEVICE_DIRECTION.Down DEVICE_ACTION.Longpress DEVICE_COMMAND.BrightnessMinus --delay=500
  room_.add-action DEVICE_DIRECTION.Right DEVICE_ACTION.Longpress DEVICE_COMMAND.ColorPlus --delay=500
  room_.add-action DEVICE_DIRECTION.Left DEVICE_ACTION.Longpress DEVICE_COMMAND.ColorMinus --delay=500
  room_.add-action DEVICE_DIRECTION.Down DEVICE_ACTION.Doubleclick DEVICE_COMMAND.TurnAllOff --reset-index

get-index -> int:
  return room_.get-index

lock-subscribe lock/bool=true:
  room_.lock-subscribe lock