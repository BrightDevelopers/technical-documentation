# Chapter 12: Hardware Integrations

[← Back to Part 4: Advanced Topics](README.md) | [↑ Main](../../README.md)

---

## Connecting External Devices & Sensors

BrightSign players provide extensive hardware integration capabilities through GPIO, serial ports, USB interfaces, and network connectivity. This chapter covers interfacing with external devices, sensors, and industrial equipment to create interactive and IoT-enabled digital signage solutions.

## GPIO Programming

BrightSign GPIO (General Purpose Input/Output) ports enable direct digital interfacing with LEDs, buttons, switches, and other electronic components.

### Hardware Specifications

**Electrical Characteristics:**
- GPIO voltage: 3.3V logic levels
- Current per pin: 24mA maximum (source or sink)
- Total GPIO power supply: 500mA at 3.3V (polyfuse protected)
- Input threshold: 2V high, 0.8V low
- Input pull-up: 1K resistors to 3.3V
- Output series resistance: 100Ω

**GPIO Pin Configuration:**
- 8 configurable GPIO pins (GPIO 0-7)
- Bidirectional operation (input or output)
- Pins numbered as buttons 0-7 (not same as physical pins)

### Digital Input/Output

**BrightScript Example - Basic GPIO Output:**

```brightscript
' Initialize GPIO control port
port = CreateObject("roControlPort", "BrightSign")
msgPort = CreateObject("roMessagePort")
port.SetPort(msgPort)

' Configure pin 2 as output and turn on LED
port.EnableOutput(2)
port.SetOutputState(2, true)  ' Turn on (3.3V)

' Wait 5 seconds
sleep(5000)

' Turn off LED
port.SetOutputState(2, false)  ' Turn off (0V)
```

**JavaScript Example - GPIO Control:**

```javascript
const control_port_class = require('@brightsign/legacy/controlport');
const gpio = new control_port_class("BrightSign");

// Configure GPIO 3 as output
gpio.ConfigureAsOutput(3);
gpio.SetPinValue(3, 1);  // Set high

// Toggle after delay
setTimeout(() => {
    gpio.SetPinValue(3, 0);  // Set low
}, 3000);
```

### Button and Switch Inputs

**BrightScript Example - Reading Button Input:**

```brightscript
port = CreateObject("roControlPort", "BrightSign")
msgPort = CreateObject("roMessagePort")
port.SetPort(msgPort)

' Configure button 0 as input
port.EnableInput(0)

' Event loop
while true
    msg = Wait(0, msgPort)
    msgType = type(msg)

    if msgType = "roControlDown" then
        buttonId = msg.GetInt()
        print "Button pressed: "; buttonId
    else if msgType = "roControlUp" then
        buttonId = msg.GetInt()
        print "Button released: "; buttonId
    endif
end while
```

**JavaScript Example - Button Events:**

```javascript
const control_port_class = require('@brightsign/legacy/controlport');
const gpio = new control_port_class("BrightSign");

// Configure as input
gpio.ConfigureAsInput(0);

// Listen for button events
gpio.addEventListener('controldown', (event) => {
    console.log('Button down:', event.button);
});

gpio.addEventListener('controlup', (event) => {
    console.log('Button up:', event.button);
});
```

### PWM Control for LED Dimming

BrightSign supports pulse-width modulation (PWM) for LED brightness control through timed GPIO pulsing.

**BrightScript Example - PWM LED Control:**

```brightscript
gpioPort = CreateObject("roControlPort", "BrightSign")

' Configure GPIO 2 and 3 as outputs
gpioPort.EnableOutput(2)
gpioPort.SetOutputState(2, true)
gpioPort.EnableOutput(3)
gpioPort.SetOutputState(3, true)

' Set up pulse with 500ms period, 2 slices (250ms each)
gpioPort.SetPulseParams({ milliseconds: 500, slices: 2 })

' GPIO 2: on during slice 1, off during slice 2 (50% duty cycle)
gpioPort.SetPulse(2, &h01)

' GPIO 3: opposite of GPIO 2 (50% duty cycle, inverted)
gpioPort.SetPulse(3, &h02)

' Run for 10 seconds
sleep(10000)

' Stop pulsing
gpioPort.RemovePulse(2)
gpioPort.RemovePulse(3)
```

**Advanced PWM - Variable Brightness:**

```brightscript
' Create 8-slice PWM for finer brightness control
gpioPort.SetPulseParams({ milliseconds: 1000, slices: 8 })

' 12.5% brightness (1 of 8 slices on)
gpioPort.SetPulse(2, &h01)

' 50% brightness (4 of 8 slices on)
gpioPort.SetPulse(3, &h0F)

' 87.5% brightness (7 of 8 slices on)
gpioPort.SetPulse(4, &h7F)
```

### Multi-State Control

**BrightScript Example - Controlling Multiple GPIOs:**

```brightscript
port = CreateObject("roControlPort", "BrightSign")

' Binary representation: Set GPIOs 1, 3, 5, and 7
gpio1 = 2     ' 2^1
gpio3 = 8     ' 2^3
gpio5 = 32    ' 2^5
gpio7 = 128   ' 2^7

' Set all at once
port.SetWholeState(gpio1 + gpio3 + gpio5 + gpio7)

' Read all inputs
state = port.GetWholeState()
print "GPIO state: "; state
```

## Serial Communication

BrightSign players support RS-232 serial communication for device control and data exchange.

### Serial Port Configuration

**Hardware Specifications:**
- Default baud rate: 115200
- Supported baud rates: 50, 75, 110, 134, 150, 200, 300, 600, 1200, 1800, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400
- Data format: 8N1 default (8 data bits, no parity, 1 stop bit)
- Voltage levels: RS-232 (+8V/-8V)
- Input tolerance: -30V to +30V
- Port types: 3.5mm jack or DB9 connector (model dependent)
- Pin configuration (3.5mm): Tip=RX, Ring=TX, Sleeve=Ground

**Port Enumeration:**
- Port 0: Onboard serial (DB9 or 3.5mm)
- Port 1: GPIO alternate function (some models) or OPS display
- Port 2+: USB-serial adapters (first=2, second=3, etc.)

### Basic Serial Communication

**BrightScript Example - Serial Port Setup:**

```brightscript
' Create serial port object
serial = CreateObject("roSerialPort", 0, 9600)
msgPort = CreateObject("roMessagePort")

' Configure line-based events
serial.SetLineEventPort(msgPort)
serial.SetReceiveEol(chr(13))  ' CR line terminator
serial.SetSendEol(chr(13))     ' CR for sending

' Send command
serial.SendLine("POWER ON")

' Wait for response
while true
    msg = Wait(5000, msgPort)
    if type(msg) = "roStreamLineEvent" then
        response = msg
        print "Received: "; response
        exit while
    else if msg = invalid then
        print "Timeout waiting for response"
        exit while
    endif
end while
```

**JavaScript Example - Serial Communication:**

```javascript
const SerialPort = require('@brightsign/serialport');
const { Binding } = require('@brightsign/serialport');

// Configure serial port
const port = new SerialPort({
    path: '/dev/ttyUSB0',
    baudRate: 9600,
    binding: Binding
});

// Send data
port.write('POWER ON\r');

// Receive data
port.on('data', (data) => {
    console.log('Received:', data.toString());
});

// Error handling
port.on('error', (err) => {
    console.error('Serial error:', err);
});
```

### Protocol Implementation

**RS-232 Device Control Example:**

```brightscript
' Control a display via RS-232
Function ControlDisplay(serial as Object, command as String)
    ' Build command with checksum
    cmdBytes = CreateObject("roByteArray")
    cmdBytes.FromAsciiString(command)

    ' Calculate checksum (simple XOR)
    checksum = 0
    for i = 0 to cmdBytes.Count() - 1
        checksum = checksum xor cmdBytes[i]
    end for

    ' Append checksum
    cmdBytes.Push(checksum)

    ' Send command
    serial.SendBlock(cmdBytes)

    ' Wait for ACK
    msgPort = CreateObject("roMessagePort")
    serial.SetByteEventPort(msgPort)

    msg = Wait(1000, msgPort)
    if msg <> invalid and type(msg) = "roStreamByteEvent" then
        ack = msg.GetInt()
        return (ack = &h06)  ' ACK byte
    endif

    return false
End Function

' Usage
serial = CreateObject("roSerialPort", 0, 9600)
success = ControlDisplay(serial, "PWR1")
print "Command success: "; success
```

### Data Parsing and Protocol Handling

**BrightScript Example - Binary Protocol:**

```brightscript
' Parse binary sensor data
Function ParseSensorData(data as Object) as Object
    result = {}

    ' Expect packet: [STX][ID][TYPE][DATA][ETX][CHK]
    if data.Count() >= 6 then
        if data[0] = &h02 and data[data.Count()-2] = &h03 then
            result.id = data[1]
            result.type = data[2]

            ' Extract data bytes
            dataBytes = CreateObject("roByteArray")
            for i = 3 to data.Count() - 3
                dataBytes.Push(data[i])
            end for
            result.data = dataBytes

            ' Verify checksum
            result.valid = VerifyChecksum(data)
        endif
    endif

    return result
End Function
```

### RS-485 Multi-Drop Communication

**BrightScript Example - RS-485 Network:**

```brightscript
' RS-485 requires external transceiver connected to serial port
' Use SetInverted() for some transceivers

Function InitRS485(port as Integer, baud as Integer) as Object
    serial = CreateObject("roSerialPort", port, baud)
    serial.SetMode("8N1")
    ' Some RS-485 transceivers need inverted signals
    ' serial.SetInverted(true)
    return serial
End Function

Function SendRS485Command(serial as Object, address as Integer, cmd as String)
    ' Build addressed packet
    packet = chr(address) + cmd + chr(13)
    serial.SendLine(packet)
End Function

' Address multiple devices on same bus
serial = InitRS485(0, 38400)
SendRS485Command(serial, 1, "STATUS")  ' Device 1
sleep(100)
SendRS485Command(serial, 2, "STATUS")  ' Device 2
```

## USB Devices

BrightSign players support various USB devices including HID devices, serial adapters, and mass storage.

### USB HID Device Support

**Supported HID Devices:**
- USB keyboards
- USB mice
- Touchscreens (standard HID drivers only)
- Barcode scanners
- RFID readers
- Game controllers/joysticks
- Button panels (BP200/BP900)

**JavaScript Example - USB Barcode Scanner:**

```javascript
// Barcode scanners typically emulate keyboards
// Listen for keyboard input events
const keyboard = require('@brightsign/keyboard');

keyboard.addEventListener('keydown', (event) => {
    // Barcode scanners send data as keystrokes
    // Terminated with Enter key
    if (event.key === 'Enter') {
        console.log('Barcode scanned:', barcodeBuffer);
        processBarcodeData(barcodeBuffer);
        barcodeBuffer = '';
    } else {
        barcodeBuffer += event.key;
    }
});

let barcodeBuffer = '';
```

### USB Serial Adapters

**BrightScript Example - USB Serial Device:**

```brightscript
' USB serial devices enumerate on port 2+
' First USB serial = port 2, second = port 3, etc.

Function GetUSBSerialPort() as Object
    deviceInfo = CreateObject("roDeviceInfo")
    usbDevices = deviceInfo.GetUSBTopology()

    ' Find USB serial device
    for each device in usbDevices
        if device.type = "serial" then
            ' Create port using friendly name
            portName = "USB:" + device.fid
            serial = CreateObject("roSerialPort", portName, 115200)
            return serial
        endif
    end for

    return invalid
End Function

' Use USB serial
usbSerial = GetUSBSerialPort()
if usbSerial <> invalid then
    usbSerial.SendLine("Hello from USB serial")
endif
```

### USB Mass Storage

**JavaScript Example - Reading USB Drive:**

```javascript
const usbFilesystem = require('@brightsign/usbfilesystem');
const usbHotplug = require('@brightsign/usbhotplug');

// Detect USB storage insertion
usbHotplug.addEventListener('usbattached', (event) => {
    console.log('USB device attached:', event.path);

    // Access files on USB drive
    const fs = require('fs');
    fs.readdir('/storage/usb1/', (err, files) => {
        if (!err) {
            console.log('Files on USB:', files);
        }
    });
});

usbHotplug.addEventListener('usbdetached', (event) => {
    console.log('USB device removed:', event.path);
});
```

### USB Power Management

**JavaScript Example - USB Power Control:**

```javascript
const usbPowerControl = require('@brightsign/usbpowercontrol');

// Control USB port power
function enableUSBPort(portNumber, enable) {
    usbPowerControl.setPortPower(portNumber, enable);
}

// Power cycle a USB device
enableUSBPort(1, false);  // Turn off
setTimeout(() => {
    enableUSBPort(1, true);  // Turn back on
}, 2000);
```

## Sensor Integration

Sensors connect to BrightSign players via GPIO, serial, or USB interfaces.

### Temperature Sensors

**BrightScript Example - Serial Temperature Sensor:**

```brightscript
' Read DS18B20 temperature via USB-serial adapter
Function ReadTemperature(serial as Object) as Float
    serial.SendLine("READ_TEMP")

    msgPort = CreateObject("roMessagePort")
    serial.SetLineEventPort(msgPort)

    msg = Wait(2000, msgPort)
    if type(msg) = "roStreamLineEvent" then
        tempStr = msg.GetString()
        temp = Val(tempStr)
        return temp
    endif

    return -999.0  ' Error value
End Function

' Monitor temperature
serial = CreateObject("roSerialPort", 2, 9600)
temp = ReadTemperature(serial)
print "Temperature: "; temp; "°C"

if temp > 30.0 then
    ' Activate cooling
    gpio = CreateObject("roControlPort", "BrightSign")
    gpio.EnableOutput(5)
    gpio.SetOutputState(5, true)
endif
```

### Motion Detectors

**BrightScript Example - PIR Motion Sensor:**

```brightscript
' PIR sensor connected to GPIO 0
port = CreateObject("roControlPort", "BrightSign")
msgPort = CreateObject("roMessagePort")
port.SetPort(msgPort)
port.EnableInput(0)

print "Waiting for motion..."

while true
    msg = Wait(0, msgPort)

    if type(msg) = "roControlDown" then
        if msg.GetInt() = 0 then
            print "Motion detected!"
            ' Trigger content playback
            TriggerMotionContent()
        endif
    endif
end while

Function TriggerMotionContent() as Void
    ' Switch to interactive zone
    ' Play welcome video, etc.
End Function
```

### Light Sensors

**BrightScript Example - Analog Light Sensor via ADC:**

```brightscript
' For analog sensors, use external ADC with serial/I2C output
Function ReadLightLevel(serial as Object) as Integer
    ' Send read command to ADC
    serial.SendByte(&hA0)  ' Read channel 0

    msgPort = CreateObject("roMessagePort")
    serial.SetByteEventPort(msgPort)

    ' Read 2-byte response
    high = Wait(100, msgPort)
    low = Wait(100, msgPort)

    if high <> invalid and low <> invalid then
        value = (high.GetInt() * 256) + low.GetInt()
        return value
    endif

    return 0
End Function

' Auto-adjust brightness based on ambient light
serial = CreateObject("roSerialPort", 2, 9600)
lightLevel = ReadLightLevel(serial)

if lightLevel < 100 then
    ' Low light - dim display
    SetDisplayBrightness(50)
else if lightLevel > 500 then
    ' Bright light - max brightness
    SetDisplayBrightness(100)
endif
```

### Proximity Sensors

**JavaScript Example - Ultrasonic Distance Sensor:**

```javascript
// HC-SR04 via USB-serial (Arduino bridge)
const SerialPort = require('@brightsign/serialport');
const { Binding } = require('@brightsign/serialport');

const sensor = new SerialPort({
    path: '/dev/ttyUSB0',
    baudRate: 9600,
    binding: Binding
});

function readDistance() {
    return new Promise((resolve) => {
        sensor.once('data', (data) => {
            const distance = parseInt(data.toString());
            resolve(distance);
        });

        sensor.write('PING\n');
    });
}

// Check proximity every second
setInterval(async () => {
    const distance = await readDistance();
    console.log('Distance:', distance, 'cm');

    if (distance < 50) {
        // Person nearby - show interactive content
        triggerInteractiveMode();
    }
}, 1000);
```

## Display & Touch Integration

BrightSign supports touchscreen integration for interactive displays.

### Touchscreen Setup

**BrightScript Example - Touch Regions:**

```brightscript
' Create touchscreen object
touch = CreateObject("roTouchScreen")
msgPort = CreateObject("roMessagePort")
touch.SetPort(msgPort)

' Set screen resolution
touch.SetResolution(1920, 1080)

' Define touch regions (buttons)
touch.AddRectangleRegion(100, 100, 300, 200, 1)   ' Button 1
touch.AddRectangleRegion(500, 100, 300, 200, 2)   ' Button 2
touch.AddCircleRegion(960, 540, 100, 3)           ' Center button

' Event loop
while true
    msg = Wait(0, msgPort)

    if type(msg) = "roTouchEvent" then
        x = msg.GetX()
        y = msg.GetY()
        region = msg.GetID()

        print "Touch at ("; x; ","; y; ") region:"; region

        ' Handle button presses
        if region = 1 then
            PlayVideo("video1.mp4")
        else if region = 2 then
            PlayVideo("video2.mp4")
        else if region = 3 then
            ShowMenu()
        endif
    endif
end while
```

### Multi-Touch Support

**JavaScript Example - Multi-Touch Gestures:**

```javascript
// Multi-touch gesture detection
let touchPoints = new Map();

touch.addEventListener('touchstart', (event) => {
    touchPoints.set(event.id, {
        x: event.x,
        y: event.y,
        startTime: Date.now()
    });
});

touch.addEventListener('touchend', (event) => {
    const start = touchPoints.get(event.id);
    if (start) {
        const duration = Date.now() - start.startTime;
        const dx = event.x - start.x;
        const dy = event.y - start.y;

        // Detect swipe gesture
        if (Math.abs(dx) > 100 && duration < 500) {
            if (dx > 0) {
                console.log('Swipe right');
                nextPage();
            } else {
                console.log('Swipe left');
                previousPage();
            }
        }
    }

    touchPoints.delete(event.id);
});
```

### Screen Calibration

**BrightScript Example - Touchscreen Calibration:**

```brightscript
touch = CreateObject("roTouchScreen")
msgPort = CreateObject("roMessagePort")
touch.SetPort(msgPort)

' Start calibration process
touch.StartCalibration()

while true
    msg = Wait(0, msgPort)

    if type(msg) = "roTouchCalibrationEvent" then
        status = touch.GetCalibrationStatus()

        if status = 0 then
            print "Calibration complete"
            exit while
        else if status < 0 then
            print "Calibration failed"
            exit while
        endif
    endif
end while
```

## Network Hardware

BrightSign players support various network interfaces and protocols.

### TCP/IP Communication

**BrightScript Example - TCP Server:**

```brightscript
' Create TCP server
server = CreateObject("roTCPServer")
msgPort = CreateObject("roMessagePort")
server.SetPort(msgPort)

' Bind to port 8080
server.SetBindAddress("0.0.0.0", 8080)

clients = []

while true
    msg = Wait(0, msgPort)

    if type(msg) = "roTCPConnectEvent" then
        ' New client connected
        client = server.Accept()
        clients.Push(client)
        client.SetPort(msgPort)
        print "Client connected"

    else if type(msg) = "roStreamLineEvent" then
        ' Received data from client
        data = msg.GetString()
        print "Received: "; data

        ' Process command
        response = ProcessCommand(data)

        ' Send response to client
        for each client in clients
            client.SendLine(response)
        end for
    endif
end while
```

### UDP Communication

**BrightScript Example - UDP Socket:**

```brightscript
' Create UDP socket for sensor network
udp = CreateObject("roDatagramSocket")
msgPort = CreateObject("roMessagePort")
udp.SetPort(msgPort)

' Bind to local port
udp.SetSendToAddress("255.255.255.255", 5000)  ' Broadcast
udp.Bind(5000)

' Send discovery message
udp.SendStr("DISCOVER")

' Listen for responses
while true
    msg = Wait(2000, msgPort)

    if type(msg) = "roDatagramEvent" then
        data = msg.GetString()
        address = msg.GetSourceAddress()
        port = msg.GetSourcePort()

        print "Received from "; address; ":"; port; " - "; data
    endif
end while
```

## Industrial Protocols

Industrial protocols typically require external gateways or custom implementations over serial/Ethernet.

### Modbus RTU over Serial

**BrightScript Example - Modbus RTU Client:**

```brightscript
' Modbus RTU implementation
Function ModbusReadHoldingRegisters(serial as Object, slaveAddr as Integer, startAddr as Integer, count as Integer) as Object
    ' Build Modbus RTU request
    request = CreateObject("roByteArray")
    request.Push(slaveAddr)       ' Slave address
    request.Push(&h03)            ' Function code: Read Holding Registers
    request.Push(startAddr >> 8)  ' Start address high byte
    request.Push(startAddr and &hFF)  ' Start address low byte
    request.Push(count >> 8)      ' Quantity high byte
    request.Push(count and &hFF)  ' Quantity low byte

    ' Calculate CRC
    crc = CalculateModbusCRC(request)
    request.Push(crc and &hFF)
    request.Push(crc >> 8)

    ' Send request
    serial.SendBlock(request)

    ' Wait for response
    msgPort = CreateObject("roMessagePort")
    serial.SetByteArrayEventPort(msgPort)

    msg = Wait(1000, msgPort)
    if type(msg) = "roStreamByteArrayEvent" then
        response = msg.GetByteArray()
        return ParseModbusResponse(response)
    endif

    return invalid
End Function

Function CalculateModbusCRC(data as Object) as Integer
    crc = &hFFFF

    for i = 0 to data.Count() - 1
        crc = crc xor data[i]

        for j = 0 to 7
            if (crc and &h0001) <> 0 then
                crc = (crc >> 1) xor &hA001
            else
                crc = crc >> 1
            endif
        end for
    end for

    return crc
End Function
```

### Modbus TCP over Ethernet

**JavaScript Example - Modbus TCP:**

```javascript
// Modbus TCP client implementation
const net = require('net');

class ModbusTCPClient {
    constructor(host, port) {
        this.host = host;
        this.port = port || 502;
        this.transactionId = 0;
    }

    connect() {
        return new Promise((resolve, reject) => {
            this.socket = net.createConnection(this.port, this.host);
            this.socket.on('connect', resolve);
            this.socket.on('error', reject);
        });
    }

    readHoldingRegisters(slaveId, startAddr, count) {
        return new Promise((resolve) => {
            this.transactionId++;

            const request = Buffer.alloc(12);
            request.writeUInt16BE(this.transactionId, 0);
            request.writeUInt16BE(0, 2);  // Protocol ID
            request.writeUInt16BE(6, 4);  // Length
            request.writeUInt8(slaveId, 6);
            request.writeUInt8(0x03, 7);  // Function code
            request.writeUInt16BE(startAddr, 8);
            request.writeUInt16BE(count, 10);

            this.socket.once('data', (data) => {
                const values = [];
                for (let i = 0; i < count; i++) {
                    values.push(data.readUInt16BE(9 + i * 2));
                }
                resolve(values);
            });

            this.socket.write(request);
        });
    }
}

// Usage
const modbus = new ModbusTCPClient('192.168.1.100');
await modbus.connect();
const registers = await modbus.readHoldingRegisters(1, 0, 10);
console.log('Register values:', registers);
```

### BACnet Integration

BACnet typically requires a BACnet/IP to Modbus or serial gateway. Direct BACnet implementation is complex and usually handled by external devices.

**Example Architecture:**
```
BrightSign Player (Ethernet) <-> BACnet/IP Gateway <-> BACnet MS/TP Network
```

### DMX512 Lighting Control

**BrightScript Example - DMX via USB-DMX Adapter:**

```brightscript
' DMX512 requires USB-DMX interface
' Connect to USB serial port
dmx = CreateObject("roSerialPort", 2, 250000)  ' DMX baud rate
dmx.SetMode("8N2")  ' DMX format: 8 data bits, no parity, 2 stop bits

Function SendDMXFrame(serial as Object, channels as Object) as Void
    ' DMX frame structure: BREAK + MARK + START + channels

    ' Send BREAK (>88μs low)
    serial.SendBreak(1)

    ' Send START code
    serial.SendByte(0)

    ' Send channel data (up to 512 channels)
    for i = 0 to channels.Count() - 1
        serial.SendByte(channels[i])
    end for
End Function

' Set DMX channels
channels = CreateObject("roArray", 512, false)
for i = 0 to 511
    channels[i] = 0
end for

' Control RGB LED: Channels 1-3
channels[0] = 255  ' Red full
channels[1] = 128  ' Green half
channels[2] = 0    ' Blue off

SendDMXFrame(dmx, channels)
```

## Power & Control Systems

### Relay Control

**BrightScript Example - Relay Switching:**

```brightscript
' Control external relays via GPIO
Function InitializeRelays() as Object
    gpio = CreateObject("roControlPort", "BrightSign")

    ' Configure GPIO 0-3 as relay outputs
    for i = 0 to 3
        gpio.EnableOutput(i)
        gpio.SetOutputState(i, false)
    end for

    return gpio
End Function

Function SetRelay(gpio as Object, relay as Integer, state as Boolean) as Void
    ' Safety check
    if relay >= 0 and relay <= 3 then
        gpio.SetOutputState(relay, state)
        print "Relay "; relay; " = "; state
    endif
End Function

' Usage
relays = InitializeRelays()

' Turn on relay 0 (activate lights)
SetRelay(relays, 0, true)

' Timed relay operation
SetRelay(relays, 1, true)
sleep(5000)
SetRelay(relays, 1, false)
```

### Motor Control

**BrightScript Example - DC Motor via H-Bridge:**

```brightscript
' Control DC motor with H-bridge driver
' GPIO 0,1 = motor A, GPIO 2,3 = motor B

Function MotorForward(gpio as Object, speed as Integer) as Void
    ' Set direction pins
    gpio.SetOutputState(0, true)
    gpio.SetOutputState(1, false)

    ' PWM for speed control (0-100%)
    if speed > 0 and speed <= 100 then
        slices = 10
        onSlices = int(speed / 10)
        bitField = (2^onSlices) - 1

        gpio.SetPulseParams({ milliseconds: 100, slices: slices })
        gpio.SetPulse(0, bitField)
    endif
End Function

Function MotorReverse(gpio as Object, speed as Integer) as Void
    gpio.SetOutputState(0, false)
    gpio.SetOutputState(1, true)

    if speed > 0 and speed <= 100 then
        slices = 10
        onSlices = int(speed / 10)
        bitField = (2^onSlices) - 1

        gpio.SetPulseParams({ milliseconds: 100, slices: slices })
        gpio.SetPulse(1, bitField)
    endif
End Function

Function MotorStop(gpio as Object) as Void
    gpio.RemovePulse(0)
    gpio.RemovePulse(1)
    gpio.SetOutputState(0, false)
    gpio.SetOutputState(1, false)
End Function

' Usage
motor = CreateObject("roControlPort", "BrightSign")
motor.EnableOutput(0)
motor.EnableOutput(1)

MotorForward(motor, 75)  ' 75% speed forward
sleep(3000)
MotorStop(motor)
```

### Lighting System Integration

**JavaScript Example - Smart Lighting Control:**

```javascript
// Control networked lighting via TCP
const net = require('net');

class LightingController {
    constructor(host, port) {
        this.client = net.createConnection(port, host);
    }

    setLight(lightId, brightness, color) {
        const cmd = {
            type: 'set_light',
            id: lightId,
            brightness: brightness,  // 0-100
            color: color  // RGB hex
        };

        this.client.write(JSON.stringify(cmd) + '\n');
    }

    setScene(sceneId) {
        const cmd = {
            type: 'set_scene',
            scene: sceneId
        };

        this.client.write(JSON.stringify(cmd) + '\n');
    }
}

// Usage
const lights = new LightingController('192.168.1.50', 8000);

// Set individual light
lights.setLight(1, 80, '#FF6600');

// Activate scene
lights.setScene('welcome');
```

### HVAC Integration

**BrightScript Example - HVAC Control via Modbus:**

```brightscript
' Control HVAC via Modbus RTU
Function SetHVACTemperature(serial as Object, targetTemp as Float) as Boolean
    ' Write target temperature to register 40001
    ' Temperature in 0.1°C units
    tempValue = int(targetTemp * 10)

    ' Modbus function code 0x06: Write Single Register
    request = CreateObject("roByteArray")
    request.Push(1)              ' Slave address
    request.Push(&h06)           ' Function code
    request.Push(0)              ' Register high byte
    request.Push(1)              ' Register low byte (40001)
    request.Push(tempValue >> 8) ' Value high byte
    request.Push(tempValue and &hFF)  ' Value low byte

    ' Add CRC
    crc = CalculateModbusCRC(request)
    request.Push(crc and &hFF)
    request.Push(crc >> 8)

    serial.SendBlock(request)

    ' Wait for response
    msgPort = CreateObject("roMessagePort")
    serial.SetByteArrayEventPort(msgPort)
    msg = Wait(500, msgPort)

    return (msg <> invalid)
End Function

' Initialize HVAC control
hvacSerial = CreateObject("roSerialPort", 0, 9600)
hvacSerial.SetMode("8N1")

' Set temperature to 22.5°C
success = SetHVACTemperature(hvacSerial, 22.5)
if success then
    print "Temperature set successfully"
endif
```

## Safety Considerations

### Voltage Level Compatibility

**3.3V vs 5V Logic:**
- BrightSign GPIO operates at 3.3V logic levels
- 5V devices require level shifters or voltage dividers
- Input threshold: 2V minimum for logic high
- Never apply >3.6V to GPIO inputs (risk of damage)

**Level Shifter Example:**
```
5V Device Output -> Voltage Divider -> BrightSign GPIO Input
                    (10kΩ + 20kΩ)

BrightSign GPIO Output -> Level Shifter IC -> 5V Device Input
                          (e.g., 74LVC245)
```

### Current Limitations

**GPIO Current Ratings:**
- Maximum per pin: 24mA
- Total GPIO current: 500mA (all pins combined)
- Use transistors or MOSFETs for loads >20mA
- Never directly drive motors, solenoids, or high-power LEDs

**Load Switching Example:**
```brightscript
' Drive high-current LED strip via MOSFET
' GPIO -> 1kΩ resistor -> MOSFET gate -> LED strip (12V)

gpio = CreateObject("roControlPort", "BrightSign")
gpio.EnableOutput(2)
gpio.SetOutputState(2, true)  ' Turn on LED strip via MOSFET
```

### Proper Grounding

**Grounding Best Practices:**
- Always connect ground between BrightSign and external devices
- Use star grounding for multiple devices
- Avoid ground loops in audio/video systems
- Ensure ground continuity for RS-232 communication
- Use isolated power supplies for noisy equipment

**Ground Loop Prevention:**
```
BrightSign GND ──┬── Device 1 GND
                 ├── Device 2 GND
                 └── Device 3 GND
(Star topology, single point ground)
```

### ESD Protection

**Electrostatic Discharge Protection:**
- Handle GPIO pins with ESD precautions
- Use ESD wrist straps during prototyping
- Add series resistors (100Ω) on GPIO outputs
- Consider TVS diodes for external connections
- Avoid hot-plugging GPIO connections

**Protection Circuit:**
```
External Signal -> TVS Diode to GND -> 100Ω resistor -> GPIO Input
```

### Thermal Management

**Heat Dissipation:**
- BrightSign players have passive cooling (most models)
- Ensure adequate ventilation around player
- Maximum ambient temperature: typically 0-50°C (check datasheet)
- Avoid enclosing player without ventilation
- Monitor system temperature in critical applications

**Temperature Monitoring:**
```brightscript
deviceInfo = CreateObject("roDeviceInfo")
temp = deviceInfo.GetTemperature()
print "System temperature: "; temp; "°C"

if temp > 70 then
    print "WARNING: High temperature!"
    ' Reduce processing load or activate cooling
endif
```

### Electrical Isolation

**When to Use Isolation:**
- Industrial environments with electrical noise
- Long cable runs
- High-voltage equipment nearby
- Medical or safety-critical applications

**Isolation Methods:**
- Optocouplers for digital signals
- Isolated DC-DC converters for power
- Isolated RS-232/RS-485 transceivers
- Isolation transformers for Ethernet (built into most interfaces)

## Best Practices

### Hardware Interface Design

1. **Use Current Limiting:** Always add series resistors to GPIO outputs
2. **Pull-up/Pull-down Resistors:** Use external pull-ups for reliable input readings
3. **Debouncing:** Implement software debouncing for mechanical switches
4. **Failsafe Design:** Design systems to fail safely on power loss or error
5. **Cable Shielding:** Use shielded cables for long runs or noisy environments

### Software Design

1. **Error Handling:** Always check for invalid returns and timeouts
2. **Timeout Management:** Use appropriate timeouts for serial/network operations
3. **State Machines:** Implement robust state machines for protocol handling
4. **Logging:** Log hardware events for debugging and maintenance
5. **Watchdog Timers:** Implement software watchdogs for critical applications

### Testing and Validation

1. **Bench Testing:** Test all hardware interfaces before deployment
2. **Stress Testing:** Test under extreme conditions (temperature, voltage fluctuations)
3. **EMC Testing:** Verify electromagnetic compatibility in final installation
4. **Documentation:** Document all pin assignments, protocols, and configurations
5. **Revision Control:** Track hardware and firmware versions

## Troubleshooting

### Common GPIO Issues

**Problem: GPIO output not working**
- Check pin configuration (EnableOutput called?)
- Verify current limits not exceeded
- Test with LED and resistor
- Check for GPIO conflicts with alternate functions

**Problem: GPIO input always reads same value**
- Verify input configuration (EnableInput called?)
- Check external circuitry and connections
- Measure voltage at GPIO pin
- Test with known good signal source

### Serial Communication Issues

**Problem: No serial data received**
- Verify baud rate matches connected device
- Check TX/RX connections (TX to RX, RX to TX)
- Confirm ground connection
- Test with serial loopback (TX to RX)
- Check voltage levels (RS-232 vs TTL)

**Problem: Garbled serial data**
- Verify baud rate, data bits, parity, stop bits
- Check for electrical noise or interference
- Reduce cable length
- Add pull-up resistors on data lines

### USB Device Issues

**Problem: USB device not detected**
- Check USB cable and connections
- Verify device draws <500mA power
- Try different USB port
- Check roDeviceInfo.GetUSBTopology() output
- Some devices require powered USB hub

## Hardware Resources

### Expansion Options

**BrightSign Expansion Module:**
- Additional GPIO pins (DB-25 connector)
- DIP switches for configuration
- Compatible with select models

**USB-to-GPIO Adapters:**
- Multiple GPIO ports via USB
- Support for "Expander-n-GPIO" naming

**BP200/BP900 Button Boards:**
- 11-button USB interface
- Integrated LEDs with PWM control
- Multiple units can be daisy-chained

### Recommended External Hardware

**Level Shifters:**
- 74LVC245 (8-bit bidirectional)
- TXB0108 (8-bit auto-direction)

**Serial Adapters:**
- FTDI FT232 (USB to serial)
- MAX232 (RS-232 transceiver)
- MAX485 (RS-485 transceiver)

**Power Control:**
- Solid-state relays (SSR)
- MOSFET modules
- Relay boards with optocoupler isolation

## Next Steps

Continue to [Chapter 13: Integrating with BSN.cloud](../chapter13-integrating-with-bsn-cloud/) to learn about cloud-based content management and remote device control.

## Additional Resources

- BrightSign Hardware Manuals: Model-specific pinouts and specifications
- BrightSign API Documentation: Complete object reference
- Community Forums: Hardware integration examples and solutions
- Application Notes: Specific integration guides (Modbus, DMX, etc.)


---

[← Previous](03-writing-software-for-the-npu.md) | [↑ Part 4: Advanced Topics](README.md)
