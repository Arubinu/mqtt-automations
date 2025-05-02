# MQTT Automations
Allows control of lights and power outlets with Zigbee2MQTT _(using an IKEA switch)_.

This project assumes that you already have an MQTT broker.

Supported lights and power outlets:
 - Elgato _(Key Light)_
 - WiZ
 - Yeelight _(Screenbar)_
 - Zigbee2MQTT

## 🛒 Dependencies
Open a terminal in the project folder once it has been downloaded. Running this command will download all the dependencies required for it to work.

```shell
jag pkg install
```

## 🗲 Flash
Please connect an ESP before running the following command. It will be reset, and the __Toit.io__ engine will be installed in its place.

```shell
jag flash esp32-no-ble
```

## 🪛 Configuration

### 🔗 MQTT Connection
You must add the credentials and the connection address for the MQTT broker in the `index.toit` file.

Make sure `LED_BUILTIN` matches the one on your ESP, or set the value to `-1`.

### ⏻ Communication Type
The `devices` folder includes all types of connections _(not just MQTT)_.

For testing, you can use only `devices/debug.toit` by setting your device's `protocol` to `Debug` _(you’ll still need a switch as an actuator)_.

### 🚩 Switches
To register devices, everything is located in the `rooms` folder. Each file corresponds to a room, but you can organize them however you like _(only one file per switch)_.

The `init.toit` file gathers the initialization of all your rooms (debug is enabled by default, don’t forget to change the switch topic).

## 🧪 Test
Run the code on the ESP. Once reset, the code is no longer present and cannot be run again.

```shell
jag run index.toit
```

## ➕ Install
Install the code on the ESP. A reset will restart the code. To perform new tests, make sure to uninstall it first.

```shell
jag install mqtt-automations index.toit
```

## ➖ Uninstall

```shell
jag uninstall mqtt-automations
```

## Notes
This works with an IKEA switch, specifically the STYRBAR model.

If you want to use a different one, you will need to adjust the received terms in the source code. The switch you use may not support long press if it behaves differently.