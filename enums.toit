class DEVICE_TYPE:
  static Unknown ::= 0
  static Light ::= 1
  static Switch ::= 2

class DEVICE_PROTOCOL:
  static Unknown ::= 0
  static Debug ::= 1
  static Elgato ::= 2
  static WiZ ::= 3
  static Yeelight ::= 4
  static Zigbee2MQTT ::= 5

class DEVICE_ACTION:
  static Simpleclick ::= 0
  static Doubleclick ::= 1
  static Longpress ::= 2

class DEVICE_DIRECTION:
  static None ::= 0
  static Up ::= 1
  static Down ::= 2
  static Left ::= 3
  static Right ::= 4

class DEVICE_COMMAND:
  static ResetIndex ::= 1
  static DevicePlus ::= 2
  static DeviceMinus ::= 3
  static TurnOn ::= 4
  static TurnOff ::= 5
  static TurnAllOn ::= 6
  static TurnAllOff ::= 7
  static ColorPlus ::= 8
  static ColorMinus ::= 9
  static BrightnessPlus ::= 10
  static BrightnessMinus ::= 11
  static TemperaturePlus ::= 12
  static TemperatureMinus ::= 13

class SENSOR_TYPE:
  static Unknown ::= 0
  static Button ::= 1
  static Light ::= 2
  static Number ::= 3
  static Sensor ::= 4