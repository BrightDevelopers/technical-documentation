# Serial Communication

[← Back to How-To Articles](README.md) | [↑ Main](../README.md)

---

## Introduction

This guide covers RS-232 serial communication on BrightSign players for interfacing with external devices like displays, projectors, industrial equipment, and custom hardware. Serial communication is essential for device control and data exchange in professional digital signage installations.

### What You'll Learn

- Configuring serial ports and communication parameters
- Sending and receiving serial data
- Implementing communication protocols
- Line-based and byte-based communication
- Error handling and timeouts
- Using USB-to-serial adapters
- RS-485 multi-drop networks

### Common Serial Applications

| Use Case | Device Type | Protocol |
|----------|-------------|----------|
| **Display Control** | Commercial displays, projectors | RS-232 commands |
| **Industrial Equipment** | PLCs, sensors, controllers | Modbus RTU |
| **Custom Hardware** | Arduino, microcontrollers | Custom protocols |
| **Building Automation** | HVAC, lighting controllers | BACnet MS/TP |
| **Point of Sale** | Receipt printers, card readers | ESC/POS, various |

---

## Prerequisites

- BrightSign player with serial port (most models have DB9 or 3.5mm)
- Understanding of serial communication basics
- Development environment set up ([see setup guide](01-setting-up-development-environment.md))
- Optional: Serial cable, USB-to-serial adapter, terminal software

---

## Serial Port Hardware Specifications

### Electrical Characteristics

| Parameter | Value | Notes |
|-----------|-------|-------|
| **Standard** | RS-232 | EIA/TIA-232-F compliant |
| **Voltage Levels** | ±8V (typical) | Tolerates -30V to +30V |
| **Logic High** | -3V to -15V | Mark state |
| **Logic Low** | +3V to +15V | Space state |
| **Connector** | DB9 or 3.5mm | Model dependent |

### 3.5mm Serial Connector Pinout

```
Tip:    RX (Receive)
Ring:   TX (Transmit)
Sleeve: Ground
```

### Supported Configuration

**Baud Rates:** 50, 75, 110, 134, 150, 200, 300, 600, 1200, 1800, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400

**Data Format (8N1 default):**
- Data bits: 5, 6, 7, or 8
- Parity: None, Even, Odd
- Stop bits: 1 or 2

**Flow Control:**
- Hardware (RTS/CTS): Supported
- Software (XON/XOFF): Not supported

### Port Enumeration

| Port Number | Device |
|-------------|--------|
| 0 | Onboard serial (DB9 or 3.5mm) |
| 1 | GPIO alternate function or OPS display |
| 2+ | USB-serial adapters (first=2, second=3, etc.) |

---

## Part 1: Basic Serial Communication

### Creating a Serial Port

```brightscript
Sub Main()
    ' Create serial port object
    ' Port 0, 9600 baud
    serial = CreateObject("roSerialPort", 0, 9600)

    ' Check if port created successfully
    if serial = invalid then
        print "Failed to create serial port"
        return
    end if

    ' Send a simple command
    serial.SendByte(13)  ' Send carriage return

    print "Serial port initialized"
End Sub
```

### Sending Data

**Send Individual Bytes:**

```brightscript
serial = CreateObject("roSerialPort", 0, 9600)

' Send single byte
serial.SendByte(&h41)  ' ASCII 'A'

' Send multiple bytes
serial.SendByte(&h50)  ' 'P'
serial.SendByte(&h4F)  ' 'O'
serial.SendByte(&h57)  ' 'W'
serial.SendByte(&h45)  ' 'E'
serial.SendByte(&h52)  ' 'R'
serial.SendByte(13)    ' CR
```

**Send Byte Array:**

```brightscript
serial = CreateObject("roSerialPort", 0, 9600)

' Create byte array
cmd = CreateObject("roByteArray")
cmd.FromAsciiString("POWER ON")
cmd.Push(13)  ' Add CR

' Send block
serial.SendBlock(cmd)
```

### Configuring Serial Mode

```brightscript
serial = CreateObject("roSerialPort", 0, 115200)

' Set data format: "8N1" = 8 data bits, no parity, 1 stop bit
serial.SetMode("8N1")

' Other format examples:
' "7E1" = 7 data bits, even parity, 1 stop bit
' "8N2" = 8 data bits, no parity, 2 stop bits

' Enable hardware flow control (RTS/CTS)
serial.SetFlowControl(true)

' Set timeout
serial.SetTimeout(5000)  ' 5 second timeout
```

---

## Part 2: Line-Based Communication

For text-based protocols where commands are terminated by newline characters.

### Configuring Line Events

```brightscript
Sub Main()
    serial = CreateObject("roSerialPort", 0, 9600)
    msgPort = CreateObject("roMessagePort")

    ' Configure for line-based communication
    serial.SetLineEventPort(msgPort)

    ' Set line terminators
    serial.SetReceiveEol(chr(13))  ' Expect CR as line ending
    serial.SetSendEol(chr(13))     ' Send CR after each line

    ' Send command
    serial.SendLine("STATUS")

    ' Wait for response
    msg = wait(5000, msgPort)

    if type(msg) = "roStreamLineEvent" then
        response = msg.GetString()
        print "Response: "; response
    else
        print "Timeout waiting for response"
    end if
End Sub
```

### Complete Line-Based Protocol

```brightscript
Function SendSerialCommand(serial as Object, command as String, timeout as Integer) as String
    msgPort = CreateObject("roMessagePort")
    serial.SetLineEventPort(msgPort)

    ' Send command
    serial.SendLine(command)
    print "Sent: "; command

    ' Wait for response
    msg = wait(timeout, msgPort)

    if type(msg) = "roStreamLineEvent" then
        response = msg.GetString()
        print "Received: "; response
        return response
    else
        print "Timeout or error"
        return ""
    end if
End Function

Sub DisplayControl()
    ' Control a display via RS-232
    serial = CreateObject("roSerialPort", 0, 9600)
    serial.SetReceiveEol(chr(13))
    serial.SetSendEol(chr(13))

    ' Power on
    response = SendSerialCommand(serial, "PWR1", 1000)
    if response = "OK" then
        print "Display powered on"
    end if

    sleep(2000)

    ' Set input to HDMI 1
    SendSerialCommand(serial, "INP HDMI1", 1000)

    sleep(2000)

    ' Query status
    response = SendSerialCommand(serial, "PWR?", 1000)
    print "Power status: "; response

    ' Power off
    SendSerialCommand(serial, "PWR0", 1000)
End Sub
```

---

## Part 3: Byte-Based Communication

For binary protocols or when you need precise byte-level control.

### Byte Events

```brightscript
Sub Main()
    serial = CreateObject("roSerialPort", 0, 9600)
    msgPort = CreateObject("roMessagePort")

    ' Configure for byte events
    serial.SetByteEventPort(msgPort)

    ' Send command
    serial.SendByte(&h50)  ' Command byte

    ' Read response bytes
    responseBytes = []
    timeout = 1000

    while true
        msg = wait(timeout, msgPort)

        if type(msg) = "roStreamByteEvent" then
            byteValue = msg.GetInt()
            responseBytes.Push(byteValue)
            print "Received byte: 0x"; hex(byteValue)

            ' Check for terminator
            if byteValue = &h0D then
                exit while
            end if
        else
            print "Timeout"
            exit while
        end if
    end while

    print "Total bytes received: "; responseBytes.Count()
End Sub
```

### Byte Array Events (Block Mode)

```brightscript
Sub Main()
    serial = CreateObject("roSerialPort", 0, 9600)
    msgPort = CreateObject("roMessagePort")

    ' Configure for byte array events
    serial.SetByteArrayEventPort(msgPort)

    ' Send command packet
    cmd = CreateObject("roByteArray")
    cmd.Push(&hAA)  ' Header
    cmd.Push(&h55)  ' Command
    cmd.Push(&h00)  ' Data
    serial.SendBlock(cmd)

    ' Wait for response packet
    msg = wait(2000, msgPort)

    if type(msg) = "roStreamByteArrayEvent" then
        response = msg.GetByteArray()
        print "Received "; response.Count(); " bytes"

        ' Process response
        for i = 0 to response.Count() - 1
            print "Byte["; i; "] = 0x"; hex(response[i])
        end for
    end if
End Sub
```

---

## Part 4: Protocol Implementation

### Simple Command-Response Protocol

```brightscript
Function SendCommandWithRetry(serial as Object, cmd as Object, expectedResponse as Integer, maxRetries as Integer) as Boolean
    msgPort = CreateObject("roMessagePort")
    serial.SetByteEventPort(msgPort)

    for attempt = 1 to maxRetries
        print "Attempt "; attempt; " of "; maxRetries

        ' Send command
        serial.SendBlock(cmd)

        ' Wait for ACK
        msg = wait(1000, msgPort)

        if type(msg) = "roStreamByteEvent" then
            response = msg.GetInt()

            if response = expectedResponse then
                print "Command acknowledged"
                return true
            else
                print "Unexpected response: 0x"; hex(response)
            end if
        else
            print "Timeout"
        end if

        ' Wait before retry
        sleep(500)
    end for

    print "Command failed after "; maxRetries; " attempts"
    return false
End Function
```

### Checksum Calculation

```brightscript
Function CalculateXORChecksum(data as Object) as Integer
    checksum = 0

    for i = 0 to data.Count() - 1
        checksum = checksum xor data[i]
    end for

    return checksum
End Function

Function CalculateLRCChecksum(data as Object) as Integer
    ' Longitudinal Redundancy Check
    lrc = 0

    for i = 0 to data.Count() - 1
        lrc = (lrc + data[i]) and &hFF
    end for

    lrc = ((lrc xor &hFF) + 1) and &hFF
    return lrc
End Function

Sub SendPacketWithChecksum()
    serial = CreateObject("roSerialPort", 0, 9600)

    ' Build packet: [STX][DATA][ETX][CHK]
    packet = CreateObject("roByteArray")
    packet.Push(&h02)  ' STX
    packet.Push(&h50)  ' Command
    packet.Push(&h4F)  ' Data 1
    packet.Push(&h57)  ' Data 2
    packet.Push(&h03)  ' ETX

    ' Calculate and append checksum
    checksum = CalculateXORChecksum(packet)
    packet.Push(checksum)

    ' Send packet
    serial.SendBlock(packet)
    print "Sent packet with checksum"
End Sub
```

### Binary Protocol Parser

```brightscript
Function ParseBinaryPacket(data as Object) as Object
    result = {valid: false}

    ' Expect: [STX][LEN][CMD][DATA...][CHK]
    if data.Count() < 4 then
        print "Packet too short"
        return result
    end if

    ' Verify STX
    if data[0] <> &h02 then
        print "Invalid STX"
        return result
    end if

    ' Extract length
    length = data[1]

    if data.Count() <> length + 2 then
        print "Length mismatch"
        return result
    end if

    ' Extract command and data
    result.command = data[2]
    result.data = CreateObject("roByteArray")

    for i = 3 to data.Count() - 2
        result.data.Push(data[i])
    end for

    ' Verify checksum
    expectedChecksum = data[data.Count() - 1]
    actualChecksum = CalculateXORChecksum(data, 0, data.Count() - 1)

    if expectedChecksum = actualChecksum then
        result.valid = true
        print "Packet valid"
    else
        print "Checksum failed"
    end if

    return result
End Function
```

---

## Part 5: RS-485 Multi-Drop Communication

RS-485 extends serial communication to support multiple devices on a single bus.

### RS-485 Configuration

```brightscript
Function InitRS485(port as Integer, baud as Integer) as Object
    serial = CreateObject("roSerialPort", port, baud)

    ' RS-485 typically uses 8N1
    serial.SetMode("8N1")

    ' Some RS-485 adapters need inverted signals
    ' serial.SetInverted(true)

    return serial
End Function

Function SendRS485Command(serial as Object, deviceAddr as Integer, cmd as String) as String
    msgPort = CreateObject("roMessagePort")
    serial.SetLineEventPort(msgPort)

    ' Build addressed command
    packet = chr(deviceAddr) + cmd + chr(13)

    ' Send command
    serial.SendLine(packet)

    ' Wait for response
    msg = wait(2000, msgPort)

    if type(msg) = "roStreamLineEvent" then
        return msg.GetString()
    end if

    return ""
End Function

Sub RS485Demo()
    ' RS-485 network with 3 devices
    serial = InitRS485(0, 38400)

    ' Query device 1
    response1 = SendRS485Command(serial, 1, "STATUS")
    print "Device 1: "; response1

    sleep(100)

    ' Query device 2
    response2 = SendRS485Command(serial, 2, "STATUS")
    print "Device 2: "; response2

    sleep(100)

    ' Control device 3
    SendRS485Command(serial, 3, "OUTPUT ON")
End Sub
```

---

## Part 6: Complete Example - Display Controller

A robust display control system with error handling and status monitoring:

### autorun.brs

```brightscript
Sub Main()
    ' Initialize serial port for display
    serial = CreateObject("roSerialPort", 0, 9600)
    serial.SetMode("8N1")
    serial.SetReceiveEol(chr(13))
    serial.SetSendEol(chr(13))

    ' Create display controller
    display = CreateDisplayController(serial)

    ' Startup sequence
    if display.PowerOn() then
        print "Display powered on"

        sleep(3000)  ' Wait for display to warm up

        ' Configure display
        display.SetInput("HDMI1")
        display.SetVolume(50)
        display.SetBrightness(80)

        ' Monitor display status
        timer = CreateObject("roTimer")
        timer.SetElapsed(30, 0)  ' Check every 30 seconds
        timer.Start()

        msgPort = CreateObject("roMessagePort")
        timer.SetPort(msgPort)

        while true
            msg = wait(0, msgPort)

            if type(msg) = "roTimerEvent" then
                ' Check display status
                status = display.GetStatus()

                if status.power = "ON" then
                    print "Display OK - Temp: "; status.temperature; "C"
                else
                    print "Display error detected!"
                    display.PowerOn()  ' Try to recover
                end if

                timer.Start()
            end if
        end while
    else
        print "Failed to power on display"
    end if
End Sub

Function CreateDisplayController(serial as Object) as Object
    controller = {
        serial: serial,
        timeout: 2000
    }

    ' Power control
    controller.PowerOn = Function() as Boolean
        return m.SendCommand("PWR1", "OK")
    End Function

    controller.PowerOff = Function() as Boolean
        return m.SendCommand("PWR0", "OK")
    End Function

    ' Input selection
    controller.SetInput = Function(input as String) as Boolean
        cmd = "INP " + input
        return m.SendCommand(cmd, "OK")
    End Function

    ' Volume control
    controller.SetVolume = Function(level as Integer) as Boolean
        if level < 0 or level > 100 then
            return false
        end if
        cmd = "VOL " + Str(level)
        return m.SendCommand(cmd, "OK")
    End Function

    ' Brightness control
    controller.SetBrightness = Function(level as Integer) as Boolean
        if level < 0 or level > 100 then
            return false
        end if
        cmd = "BRT " + Str(level)
        return m.SendCommand(cmd, "OK")
    End Function

    ' Status query
    controller.GetStatus = Function() as Object
        status = {
            power: "UNKNOWN",
            input: "UNKNOWN",
            volume: 0,
            temperature: 0
        }

        ' Query power state
        response = m.SendQuery("PWR?")
        if response <> "" then
            status.power = response
        end if

        ' Query temperature
        response = m.SendQuery("TEMP?")
        if response <> "" then
            status.temperature = Val(response)
        end if

        return status
    End Function

    ' Send command with expected response
    controller.SendCommand = Function(cmd as String, expectedResponse as String) as Boolean
        msgPort = CreateObject("roMessagePort")
        m.serial.SetLineEventPort(msgPort)

        m.serial.SendLine(cmd)
        print "TX: "; cmd

        msg = wait(m.timeout, msgPort)

        if type(msg) = "roStreamLineEvent" then
            response = msg.GetString()
            print "RX: "; response
            return (response = expectedResponse)
        else
            print "Timeout"
            return false
        end if
    End Function

    ' Send query and return response
    controller.SendQuery = Function(query as String) as String
        msgPort = CreateObject("roMessagePort")
        m.serial.SetLineEventPort(msgPort)

        m.serial.SendLine(query)
        print "TX: "; query

        msg = wait(m.timeout, msgPort)

        if type(msg) = "roStreamLineEvent" then
            response = msg.GetString()
            print "RX: "; response
            return response
        else
            print "Timeout"
            return ""
        end if
    End Function

    return controller
End Function
```

---

## Part 7: JavaScript Serial Communication

### Using @brightsign/serialport

```javascript
const SerialPort = require('@brightsign/serialport');
const { Binding } = require('@brightsign/serialport');

// Create serial port
const port = new SerialPort({
    path: '/dev/ttyUSB0',
    baudRate: 9600,
    dataBits: 8,
    parity: 'none',
    stopBits: 1,
    binding: Binding
});

// Handle open event
port.on('open', () => {
    console.log('Serial port opened');

    // Send command
    port.write('POWER ON\r', (err) => {
        if (err) {
            console.error('Write error:', err);
        }
    });
});

// Receive data
port.on('data', (data) => {
    console.log('Received:', data.toString());
});

// Handle errors
port.on('error', (err) => {
    console.error('Serial error:', err);
});
```

### Line-Based Protocol in JavaScript

```javascript
const SerialPort = require('@brightsign/serialport');
const Readline = require('@serialport/parser-readline');

const port = new SerialPort({
    path: '/dev/ttyUSB0',
    baudRate: 9600
});

// Use readline parser
const parser = port.pipe(new Readline({ delimiter: '\r' }));

// Send command and wait for response
function sendCommand(cmd, timeout = 2000) {
    return new Promise((resolve, reject) => {
        const timer = setTimeout(() => {
            reject(new Error('Timeout'));
        }, timeout);

        parser.once('data', (line) => {
            clearTimeout(timer);
            resolve(line);
        });

        port.write(cmd + '\r');
    });
}

// Usage
async function controlDisplay() {
    try {
        const response = await sendCommand('PWR1');
        console.log('Response:', response);

        if (response === 'OK') {
            console.log('Display powered on');
        }
    } catch (error) {
        console.error('Command failed:', error);
    }
}
```

---

## USB-to-Serial Adapters

### Detecting USB Serial Devices

```brightscript
Function FindUSBSerialPorts() as Object
    deviceInfo = CreateObject("roDeviceInfo")
    usbDevices = deviceInfo.GetUSBTopology()

    ports = []

    for each device in usbDevices
        if device.type = "serial" or device.type = "cdc-acm" then
            ports.Push({
                name: device.fid,
                manufacturer: device.mfr,
                product: device.prd
            })
        end if
    end for

    return ports
End Function

Sub USBSerialDemo()
    ' Find USB serial adapters
    ports = FindUSBSerialPorts()

    print "Found "; ports.Count(); " USB serial ports"

    for each port in ports
        print "Port: "; port.name
        print "  Manufacturer: "; port.manufacturer
        print "  Product: "; port.product

        ' Create serial port using USB port
        serial = CreateObject("roSerialPort", 2, 115200)  ' First USB port = 2
        if serial <> invalid then
            serial.SendLine("Hello from USB serial")
        end if
    end for
End Sub
```

---

## Best Practices

### Do

- **Set appropriate timeouts** (typically 1-5 seconds)
- **Implement retry logic** for critical commands
- **Use checksums** for data integrity
- **Log all communication** for debugging
- **Test with hardware loopback** (TX to RX)
- **Document protocol specifications** clearly
- **Add delays between commands** if device requires it
- **Handle partial data** in byte-based protocols
- **Validate responses** before acting on them

### Don't

- **Don't assume immediate response** - use timeouts
- **Don't ignore return values** from send operations
- **Don't send commands too rapidly** - devices need processing time
- **Don't forget ground connection** - causes communication failures
- **Don't mix line and byte events** simultaneously
- **Don't use blocking waits** in production without timeouts

---

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| No data received | Wrong TX/RX | Swap TX/RX connections |
| Garbled data | Baud rate mismatch | Verify baud rate on both devices |
| Intermittent communication | Loose connection | Check cable and connectors |
| Timeout errors | Device not responding | Check power, verify command format |
| Wrong data format | Parity/stop bits | Verify SetMode() parameters |
| Data corruption | No ground | Connect ground between devices |
| Partial messages | Buffer overflow | Add delays, increase timeout |

### Serial Loopback Test

```brightscript
Sub LoopbackTest()
    ' Connect TX to RX for testing
    serial = CreateObject("roSerialPort", 0, 9600)
    msgPort = CreateObject("roMessagePort")
    serial.SetLineEventPort(msgPort)
    serial.SetReceiveEol(chr(13))
    serial.SetSendEol(chr(13))

    ' Send test message
    testMsg = "LOOPBACK TEST"
    serial.SendLine(testMsg)

    ' Receive echo
    msg = wait(1000, msgPort)

    if type(msg) = "roStreamLineEvent" then
        received = msg.GetString()
        if received = testMsg then
            print "PASS: Loopback test successful"
        else
            print "FAIL: Received '"; received; "' expected '"; testMsg; "'"
        end if
    else
        print "FAIL: Timeout"
    end if
End Sub
```

---

## Exercises

1. **Echo Server**: Create a serial echo server that returns any data it receives

2. **Display Controller**: Build a complete display control interface with power, input, and volume

3. **Data Logger**: Log sensor data received via serial to a file

4. **Protocol Analyzer**: Create a tool that displays all serial traffic with timestamps

5. **Multi-Device Manager**: Control 3 RS-485 devices on a single bus

6. **Binary Protocol**: Implement a custom binary protocol with checksums and acknowledgments

---

## Next Steps

- [Using GPIO for Interactivity](12-using-gpio-for-interactivity.md) - Physical button and LED control
- [USB Device Integration](14-usb-device-integration.md) - USB peripherals and storage
- [Touch Screen Configuration](15-touch-screen-configuration.md) - Touch input

---

## Additional Resources

- [BrightSign roSerialPort Documentation](https://brightsign.atlassian.net/wiki/spaces/DOC/pages/370673299/roSerialPort)
- [Serial Port Configuration Guide](https://brightsign.atlassian.net/wiki/spaces/DOC/pages/388434643/Serial+Port+Configuration)
- RS-232 Standard: TIA/EIA-232-F specification

---

<div align="center">

<img src="../documentation/part-7-assets/brand/brightsign-logo-square.png" alt="BrightSign" width="60">

**Brought to Life by BrightSign**

</div>
