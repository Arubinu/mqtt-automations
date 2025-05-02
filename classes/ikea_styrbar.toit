import system.storage show Bucket

import ..enums
import ..devices.debug as debug
import ..devices.elgato as elgato
import ..devices.wiz as wiz
import ..devices.z2m as z2m

import ..utils


/**
 Sends the command to the desired device taking into account its protocol.
  $state        turns the device on/off
  $brightness   [1-255]
  $temperature  [1000-20000]
  $rgb          [[0-255], [0-255], [0-255]]
 */
send-commands devices
    --state/bool=true
    --brightness/int=-1
    --temperature/int=-1
    --rgb/List=[]:

  if devices is not List:
    devices = [devices]
  if devices.size > 0 and devices[0] is not Object:
    print "ERROR: send-commands: the list of devices is abnormal"
    return

  for i := 0; i < devices.size; ++i:
    device/int := devices[i]["protocol"]
    addr/string := devices[i]["address"]

    name/string := "None"
    if device == DEVICE_PROTOCOL.Debug:
      name = debug.name
      debug.send addr --state=state --brightness=brightness --temperature=temperature --rgb=rgb
    else if device == DEVICE_PROTOCOL.Elgato:
      name = elgato.name
      elgato.send addr --state=state --brightness=brightness --temperature=temperature --rgb=rgb
    else if device == DEVICE_PROTOCOL.WiZ:
      name = wiz.name
      wiz.send addr --state=state --brightness=brightness --temperature=temperature --rgb=rgb
    else if device == DEVICE_PROTOCOL.Zigbee2MQTT:
      name = z2m.name
      z2m.send addr --state=state --brightness=brightness --temperature=temperature --rgb=rgb
    print "Send command: device-type=" + name + " address=" + addr

/**
 Class to use to define operating ranges.
 */
class Color:
  step/int ::= ?

  /**
    $step   increment/decrement step on a 360 degree wheel
   */
  constructor
      --step/int=8:

    this.step = (step > 0) ? step : 8

/**
 Class to use to define operating ranges.
 */
class Brightness:
  min/int ::= ?
  max/int ::= ?

  step/int ::= ?
  level-up/int ::= ?
  level-down/int ::= ?

  /**
    $min          minimum brightness value
    $max          maximum brightness value
    $step         increment/decrement step
    $level-up     high value when pressing the power button again
    $level-down   low value when pressing the power button again
   */
  constructor
      --min/int=1
      --max/int=255
      --step/int=5
      --level-up/int=-1
      --level-down/int=-1:

    this.min = (min > 0) ? min : 0
    this.max = (max > this.min and max <= 255) ? max : 255

    this.step = (step > 0) ? step : 10

    this.level-up = (level-up > 0 and level-up > level-down) ? level-up : this.max
    this.level-down = (level-down > 0) ? level-down : ((this.max - this.min) / 2) + this.min

/**
 Class to use to define operating ranges.
 */
class Temperature:
  min/int ::= ?
  max/int ::= ?

  step/int ::= ?

  /**
    $min            minimum brightness value
    $max            maximum brightness value
    $step-percent   increment/decrement step
   */
  constructor
      --min/int=2500
      --max/int=7000
      --step-percent/int=5:

    this.min = (min > 1000) ? min : 2500
    this.max = (max > this.min and max <= 10000) ? max : 7000

    this.step = (step-percent > 0) ? step-percent : 5

/**
 Main class receiving commands from a Zigbee switch.
 */
class Listen:
  lock_/bool := false
  index_/int := 0
  devices_/List := []
  devices-updated_/bool := false

  default-index/int := 0
  doubleclick-delay/int := 0

  last-action_/string := ""
  last-timestamp_/int := 0
  action-mode_/int := 0
  longpress-timestamp_/int := 0
  doubleclick-timestamp_/int := 0

  /**
    $device-topic       MQTT topic of the switch action (without "/action")
    $default-index      the main device number (starts with 0)
    $doubleclick-delay  the delay must be greater than the minimum time between each sending of the switch (here 500 milliseconds)
   */
  constructor device-topic/string
      --default-index/int=0
      --doubleclick-delay/int=750:

    this.default-index = default-index
    this.doubleclick-delay = doubleclick-delay

    // ajouter dans this.devices_
    z2m.get.subscribe device-topic + "/action":: | topic/string payload/ByteArray |
      if this.lock_:
        this.last-timestamp_ = this.doubleclick-timestamp_
        this.longpress-timestamp_ = 0
        this.doubleclick-timestamp_ = Time.now.ms-since-epoch + doubleclick-delay
        if this.doubleclick-timestamp_ <= 0 or (this.doubleclick-timestamp_ - this.last-timestamp_) > 250: // no flood
          print "Received value on '$topic': $payload.to-string"
          execute payload.to-string
        else:
          print "Received flood on '$topic'!"
          this.last-action_ = payload.to-string

    task::save-task_
    task::longpress-task_

  /**
   Saves the state of different devices.
   */
  save-task_:
    while true:
      if this.devices-updated_:
        this.devices-updated_ = false

        for i := 0; i < this.devices_.size; ++i:
          current-devices/List := get-devices_ i
          for d := 0; d < current-devices.size; ++d:
            current-device/Map := current-devices[d]

            address ::= current-device["address"]
            protocol ::= current-device["protocol"]
            store ::= Bucket.open --flash ("$protocol/$address".replace ":" "")

            store.close

        print "Devices saved"

      sleep --ms=300000

  /**
   Task launched in the background to manage long press actions.
   */
  longpress-task_:
    while true:
      now/int ::= Time.now.ms-since-epoch
      mode/int ::= this.action-mode_

      if (mode % 10) == DEVICE_ACTION.Longpress and this.longpress-timestamp_ <= now:
        current-devices/List := this.get-devices_ this.index_
        for d := 0; d < current-devices.size; ++d:
          current-device/Map := current-devices[d]

          this.longpress-timestamp_ = send-mode mode current-device --is-longpress
          if this.longpress-timestamp_ == 0:
            this.action-mode_ = 0

      sleep --ms=50

  /**
   Returns a number representing the button pressed and the type of press.
    $action     DEVICE_ACTION
    $direction  DEVICE_DIRECTION
   */
  get-mode_ action/int direction/int -> int:
    return (10 * direction) + action

  /**
   Returns the number of the currently targeted device.
   */
  get-index -> int:
    return this.index_

  /**
   Returns the list of devices to run concurrently.
   */
  get-devices_ index/int -> List:
    return (this.devices_[index] is List) ? this.devices_[index] : [this.devices_[index]]

  /**
   Sets the device to default, as the currently controlled device.
   */
  reset-index:
    this.index_ = min this.devices_.size (max 0 this.default-index)
    print "Reset index: " + this.index_.stringify

  /**
   Start listening for MQTT messages.
   */
  lock-subscribe lock/bool=true:
    this.index_ = min this.devices_.size (max 0 this.default-index)
    this.lock_ = lock

  /**
   Add a device to this switch.
    $address              IP address or name given to the device
    $protocol             DEVICE_PROTOCOL
    $color                Color
    $brightness           Brightness
    $temperature          Temperature
    $doubleclick-all-off  ignores turning off the device when double pressing the button to turn off
    $add-in-last          add the device in the same batch as the previous one (to operate them together)
   */
  add-device address/string protocol/int=DEVICE_PROTOCOL.Unknown
      --color/Color?=null
      --brightness/Brightness?=null
      --temperature/Temperature?=null
      --doubleclick-all-off/bool=true
      --add-in-last/bool=false -> int:

    if add-in-last and this.devices_.size == 0:
      print "ERROR: add-device: no devices present"
      return -1

    // Read saved data
    store ::= Bucket.open --flash ("$protocol/$address".replace ":" "")

    device/Map := {
      "address": address,
      "protocol": protocol,

      "state": false,
      "actions": Map,
      "doubleclick_all_off": doubleclick-all-off,

      "color_state": (or-else (store.get "color") null 0),
      "color_config": color,
      "brightness_state": (or-else (store.get "brightness") null ((brightness is Brightness) ? brightness.max : 0)),
      "brightness_config": brightness,
      "temperature_state": (or-else (store.get "temperature") null ((temperature is Temperature) ? temperature.max : 0)),
      "temperature_config": temperature
    }

    store.close

    if add-in-last:
      if this.devices_[this.devices_.size - 1] is not List:
        this.devices_[this.devices_.size - 1] = [this.devices_[this.devices_.size - 1]]

      this.devices_[this.devices_.size - 1].add device
    else:
      this.devices_.add device

    return (this.devices_.size - 1)

  /**
   Add an action to the device for one of the buttons.
    $device-id  number returned by add-device
    $direction  DEVICE_DIRECTION
    $action     DEVICE_ACTION
    $send       DEVICE_COMMAND
    $delay      time between each action for long press
   */
  add-action direction/int action/int send/int
      --device-id/int=-1
      --reset-index/bool=false
      --delay/int=-1 -> bool:

    if device-id < 0:
      device-id = this.devices_.size - 1

    if device-id >= 0 and this.devices_.size > device-id:
      device := this.devices_[device-id]
      if device is List:
        device = device[device.size - 1]

      mode/int ::= this.get-mode_ action direction
      if not device["actions"].contains mode:
        device["actions"][mode] = {
          "delay": delay,
          "reset": reset-index,
          "command": send
        }
        return true

    return false

  /**
   Processes the received message.
    $action   MQTT message from the switch
    $index    forces the batch of devices to operate
   */
  execute action/string
      --index/int=-1:

    doubleclick := this.last-action_ == action
    doubleclick = doubleclick and this.last-timestamp_ >= Time.now.ms-since-epoch

    mode_action/int := doubleclick ? DEVICE_ACTION.Doubleclick : DEVICE_ACTION.Simpleclick
    mode_direction/int := DEVICE_DIRECTION.None
    if action == "brightness_move_up" or action == "on":
      mode_direction = DEVICE_DIRECTION.Up
      if action == "brightness_move_up":
        mode_action = DEVICE_ACTION.Longpress
    else if action == "brightness_move_down" or action == "off":
      mode_direction = DEVICE_DIRECTION.Down
      if action == "brightness_move_down":
        mode_action = DEVICE_ACTION.Longpress
    else if action == "arrow_left_hold" or action == "arrow_left_click":
      mode_direction = DEVICE_DIRECTION.Left
      if action == "arrow_left_hold":
        mode_action = DEVICE_ACTION.Longpress
    else if action == "arrow_right_hold" or action == "arrow_right_click":
      mode_direction = DEVICE_DIRECTION.Right
      if action == "arrow_right_hold":
        mode_action = DEVICE_ACTION.Longpress

    this.last-action_ = action
    this.action-mode_ = this.get-mode_ mode_action mode_direction

    current-devices/List := get-devices_ ((index >= 0 and index < this.devices_.size) ? index : this.index_)
    for d := 0; d < current-devices.size; ++d:
      current-device/Map := current-devices[d]

      this.longpress-timestamp_ = send-mode this.action-mode_ current-device --is-longpress=(mode_action == DEVICE_ACTION.Longpress) --is-doubleclick=doubleclick
      if this.longpress-timestamp_ == 0:
        this.action-mode_ = 0

  /**
   Action to be performed based on switch instructions.
    $action     DEVICE_ACTION
    $direction  DEVICE_DIRECTION
    $device     only one of the devices to be operated
   */
  send action/int direction/int device/Map
      --is-longpress/bool=false
      --is-doubleclick/bool=false -> int:

    return send-mode (this.get-mode_ action direction) device --is-longpress=is-longpress --is-doubleclick=is-doubleclick

  /**
   Action to be performed based on switch instructions.
    $mode             value returned by get-mode_
    $device           only one of the devices to be operated
    $is-longpress     if the action involves a long press
    $is-doubleclick   if the action involves a double press
   */
  send-mode mode/int device/Map
      --is-longpress/bool=false
      --is-doubleclick/bool=false -> int:

    now/int ::= Time.now.ms-since-epoch
    delay/int := 0
    if device["actions"].contains mode:
      action/Map := device["actions"][mode]

      if action["command"] == DEVICE_COMMAND.ResetIndex:
        reset-index
      else if action["command"] == DEVICE_COMMAND.DeviceMinus or action["command"] == DEVICE_COMMAND.DevicePlus:
        add/int ::= (action["command"] == DEVICE_COMMAND.DevicePlus) ? 1 : -1
        this.index_ = min (this.devices_.size - 1) (max 0 (this.index_ + add))
        print "New position: " + this.index_.stringify
      else if action["command"] == DEVICE_COMMAND.TurnOn or action["command"] == DEVICE_COMMAND.TurnOff:
        on/bool ::= action["command"] == DEVICE_COMMAND.TurnOn

        if on and device["state"] and device["brightness_config"] is Brightness: // change the brightness
          device["brightness_state"] = (device["brightness_state"] == device["brightness_config"].level-up) ? device["brightness_config"].level-down : device["brightness_config"].level-up

          print "Set brightness: " + device["brightness_state"].stringify
          this.devices-updated_ = true
        else:
          print "Set " + (on ? "ON" : "OFF")

        device["state"] = on
        send-commands device --state=on --brightness=device["brightness_state"]
      else if action["command"] == DEVICE_COMMAND.TurnAllOn or action["command"] == DEVICE_COMMAND.TurnAllOff:
        if is-doubleclick:
          on/bool ::= action["command"] == DEVICE_COMMAND.TurnAllOn

          for i := 0; i < this.devices_.size; ++i:
            current-devices/List := get-devices_ i
            for d := 0; d < current-devices.size; ++d:
              current-device/Map := current-devices[d]

              if current-device["doubleclick_all_off"]:
                send-commands current-device --state=on
      else if action["command"] == DEVICE_COMMAND.ColorPlus or action["command"] == DEVICE_COMMAND.ColorMinus:
        add/int ::= ((action["command"] == DEVICE_COMMAND.ColorPlus) ? 1 : -1) * ((device["color_config"] is Color) ? device["color_config"].step : 1)
        values ::= hue-to-rgb device["color_state"] + add
        device["color_state"] = values["hue"]

        delay = action["delay"]
        print "Set color: " + values.stringify
        send-commands device --rgb=[values["r"], values["g"], values["b"]]
        this.devices-updated_ = true
      else if action["command"] == DEVICE_COMMAND.BrightnessPlus or action["command"] == DEVICE_COMMAND.BrightnessMinus and device["brightness_config"] is Brightness:
        if action["command"] == DEVICE_COMMAND.BrightnessPlus:
          device["brightness_state"] = min (device["brightness_state"] + device["brightness_config"].step) device["brightness_config"].max
        else:
          device["brightness_state"] = max (device["brightness_state"] - device["brightness_config"].step) device["brightness_config"].min

        delay = action["delay"]
        print "Set brightness: " + device["brightness_state"].stringify
        send-commands device --brightness=device["brightness_state"]
        this.devices-updated_ = true
      else if action["command"] == DEVICE_COMMAND.TemperaturePlus or action["command"] == DEVICE_COMMAND.TemperatureMinus and device["temperature_config"] is Temperature:
        percent/int := value-to-percent device["temperature_state"] device["temperature_config"].min device["temperature_config"].max
        percent += ((action["command"] == DEVICE_COMMAND.TemperaturePlus) ? -1 : 1) * device["temperature_config"].step
        device["temperature_state"] = percent-to-kelvin percent --min=device["temperature_config"].min --max=device["temperature_config"].max

        delay = action["delay"]
        print "Set temperature: " + device["temperature_state"].stringify
        send-commands device --temperature=device["temperature_state"]
        this.devices-updated_ = true

      if action["reset"]:
        reset-index

    return (is-longpress and delay > 0) ? delay + now : 0