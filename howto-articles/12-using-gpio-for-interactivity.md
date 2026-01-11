# Using GPIO for Interactivity

[← Back to How-To Articles](README.md) | [↑ Main](../README.md)

---

## Introduction

This guide covers using BrightSign's GPIO (General Purpose Input/Output) pins to create interactive digital signage. GPIO enables direct hardware interfacing with buttons, LEDs, switches, sensors, and other electronic components for creating engaging, responsive experiences.

### What You'll Learn

- Configuring GPIO pins for input and output
- Reading button presses and switch states
- Controlling LEDs and indicators
- Using PWM for LED brightness control
- Handling GPIO events in your applications
- Safety considerations for hardware interfacing

### Common GPIO Applications

| Use Case | Components | Description |
|----------|------------|-------------|
| **Interactive Kiosks** | Buttons, LEDs | Physical buttons trigger content changes |
| **Status Indicators** | LEDs, RGB strips | Visual feedback for system state |
| **Sensor Integration** | PIR, switches | Motion detection, door sensors |
| **Device Control** | Relays, MOSFETs | Control external equipment |
| **Game Interfaces** | Buttons, joysticks | Interactive games and experiences |

---

## Prerequisites

- BrightSign player with GPIO support (most models)
- Basic understanding of electronics (voltage, current, resistance)
- Development environment set up ([see setup guide](01-setting-up-development-environment.md))
- Optional: Breadboard, jumper wires, LEDs, resistors, buttons

---

## GPIO Hardware Specifications

### Electrical Characteristics

| Parameter | Value | Notes |
|-----------|-------|-------|
| **Logic Voltage** | 3.3V | Do not apply >3.6V to inputs |
| **Current per Pin** | 24mA max | Source or sink |
| **Total GPIO Current** | 500mA | All pins combined, polyfuse protected |
| **Input High Threshold** | 2.0V minimum | Logic high detection |
| **Input Low Threshold** | 0.8V maximum | Logic low detection |
| **Internal Pull-up** | 1kΩ to 3.3V | Built-in on most pins |
| **Output Resistance** | 100Ω series | Built-in protection |

### Pin Configuration

- **8 GPIO pins** numbered 0-7 (button IDs, not physical pin numbers)
- **Bidirectional operation** - each pin can be input or output
- **Accessed via roControlPort** object in BrightScript
- **Physical connector** varies by model (see player documentation)

**Important:** GPIO pins use 3.3V logic. Never connect 5V signals directly without level shifting.

---

## Part 1: Digital Output - Controlling LEDs

### Basic LED Control

**Circuit:**
```
BrightSign GPIO Pin -> 330Ω Resistor -> LED (+) -> LED (-) -> Ground
```

**BrightScript Example:**

```brightscript
Sub Main()
    ' Create GPIO control port
    gpio = CreateObject("roControlPort", "BrightSign")

    ' Configure pin 2 as output
    gpio.EnableOutput(2)

    ' Turn LED on (3.3V)
    print "LED ON"
    gpio.SetOutputState(2, true)
    sleep(2000)

    ' Turn LED off (0V)
    print "LED OFF"
    gpio.SetOutputState(2, false)
    sleep(2000)

    ' Blink LED 5 times
    for i = 1 to 5
        gpio.SetOutputState(2, true)
        sleep(500)
        gpio.SetOutputState(2, false)
        sleep(500)
    end for

    print "LED demo complete"
End Sub
```

**JavaScript Example:**

```javascript
const ControlPort = require('@brightsign/legacy/controlport');
const gpio = new ControlPort("BrightSign");

// Configure as output
gpio.ConfigureAsOutput(2);

// Turn on
console.log('LED ON');
gpio.SetPinValue(2, 1);

// Blink LED
let ledState = true;
setInterval(() => {
    ledState = !ledState;
    gpio.SetPinValue(2, ledState ? 1 : 0);
}, 500);
```

### Multiple GPIO Control

Control several GPIOs simultaneously:

```brightscript
Sub InitializeStatusLEDs()
    gpio = CreateObject("roControlPort", "BrightSign")

    ' Configure GPIO 0-3 as outputs for status LEDs
    gpio.EnableOutput(0)  ' Power LED
    gpio.EnableOutput(1)  ' Network LED
    gpio.EnableOutput(2)  ' Content LED
    gpio.EnableOutput(3)  ' Error LED

    ' Turn all LEDs off initially
    gpio.SetOutputState(0, false)
    gpio.SetOutputState(1, false)
    gpio.SetOutputState(2, false)
    gpio.SetOutputState(3, false)

    return gpio
End Sub

Sub ShowStatus(gpio as Object, status as String)
    ' Turn off all LEDs first
    for i = 0 to 3
        gpio.SetOutputState(i, false)
    end for

    ' Light appropriate LED
    if status = "booting" then
        gpio.SetOutputState(0, true)  ' Power only
    else if status = "connecting" then
        gpio.SetOutputState(0, true)
        gpio.SetOutputState(1, true)  ' Power + Network
    else if status = "ready" then
        gpio.SetOutputState(0, true)
        gpio.SetOutputState(1, true)
        gpio.SetOutputState(2, true)  ' All OK
    else if status = "error" then
        gpio.SetOutputState(3, true)  ' Error only
    end if
End Sub

' Usage
gpio = InitializeStatusLEDs()
ShowStatus(gpio, "booting")
sleep(2000)
ShowStatus(gpio, "connecting")
sleep(2000)
ShowStatus(gpio, "ready")
```

### Using SetWholeState for Bit Manipulation

Control multiple GPIOs with a single command using binary representation:

```brightscript
Sub BitPatternDemo()
    gpio = CreateObject("roControlPort", "BrightSign")

    ' Configure GPIO 0-7 as outputs
    for i = 0 to 7
        gpio.EnableOutput(i)
    end for

    ' Set specific GPIOs using binary (bit positions)
    ' GPIO 0 = 2^0 = 1
    ' GPIO 1 = 2^1 = 2
    ' GPIO 2 = 2^2 = 4
    ' GPIO 3 = 2^3 = 8
    ' GPIO 4 = 2^4 = 16
    ' GPIO 5 = 2^5 = 32
    ' GPIO 6 = 2^6 = 64
    ' GPIO 7 = 2^7 = 128

    ' Turn on GPIO 0, 2, 4, 6 (1 + 4 + 16 + 64 = 85)
    gpio.SetWholeState(85)
    print "Pattern 1: GPIO 0,2,4,6 ON"
    sleep(2000)

    ' Turn on GPIO 1, 3, 5, 7 (2 + 8 + 32 + 128 = 170)
    gpio.SetWholeState(170)
    print "Pattern 2: GPIO 1,3,5,7 ON"
    sleep(2000)

    ' All on (255 = 11111111 binary)
    gpio.SetWholeState(255)
    print "All ON"
    sleep(2000)

    ' All off
    gpio.SetWholeState(0)
    print "All OFF"
End Sub
```

---

## Part 2: Digital Input - Reading Buttons

### Basic Button Reading

**Circuit:**
```
3.3V -> Button -> GPIO Pin -> 10kΩ Pull-down Resistor -> Ground
(Button closes circuit when pressed)
```

**BrightScript Example:**

```brightscript
Sub Main()
    ' Create message port for events
    msgPort = CreateObject("roMessagePort")

    ' Create GPIO control port
    gpio = CreateObject("roControlPort", "BrightSign")
    gpio.SetPort(msgPort)

    ' Configure GPIO 0 as input
    gpio.EnableInput(0)

    print "Press button on GPIO 0..."

    ' Event loop
    while true
        msg = wait(0, msgPort)
        msgType = type(msg)

        if msgType = "roControlDown" then
            ' Button pressed
            buttonId = msg.GetInt()
            print "Button "; buttonId; " PRESSED"
            HandleButtonPress(buttonId)

        else if msgType = "roControlUp" then
            ' Button released
            buttonId = msg.GetInt()
            print "Button "; buttonId; " RELEASED"
            HandleButtonRelease(buttonId)
        end if
    end while
End Sub

Sub HandleButtonPress(id as Integer)
    ' Your button press logic here
    if id = 0 then
        print "Playing video..."
    end if
End Sub

Sub HandleButtonRelease(id as Integer)
    ' Your button release logic here
    print "Button released"
End Sub
```

### Multi-Button Interface

Create an interactive button panel:

```brightscript
Sub Main()
    msgPort = CreateObject("roMessagePort")

    ' Initialize GPIO
    gpio = CreateObject("roControlPort", "BrightSign")
    gpio.SetPort(msgPort)

    ' Configure GPIO 0-3 as button inputs
    gpio.EnableInput(0)  ' Button 1: Play Video 1
    gpio.EnableInput(1)  ' Button 2: Play Video 2
    gpio.EnableInput(2)  ' Button 3: Show Info
    gpio.EnableInput(3)  ' Button 4: Return to Menu

    ' Configure GPIO 4-5 as LED outputs
    gpio.EnableOutput(4)  ' Status LED
    gpio.EnableOutput(5)  ' Activity LED

    ' Create video player
    videoPlayer = CreateObject("roVideoPlayer")
    videoPlayer.SetPort(msgPort)

    ' Initialize status
    currentState = "menu"
    gpio.SetOutputState(4, true)  ' Status LED on

    print "Interactive kiosk ready"

    while true
        msg = wait(0, msgPort)
        msgType = type(msg)

        if msgType = "roControlDown" then
            buttonId = msg.GetInt()

            ' Flash activity LED
            gpio.SetOutputState(5, true)

            ' Handle button press
            if buttonId = 0 then
                print "Playing video 1"
                videoPlayer.PlayFile("video1.mp4")
                currentState = "playing"

            else if buttonId = 1 then
                print "Playing video 2"
                videoPlayer.PlayFile("video2.mp4")
                currentState = "playing"

            else if buttonId = 2 then
                print "Showing information"
                ShowInformation()
                currentState = "info"

            else if buttonId = 3 then
                print "Returning to menu"
                videoPlayer.Stop()
                ShowMenu()
                currentState = "menu"
            end if

        else if msgType = "roControlUp" then
            ' Turn off activity LED when button released
            gpio.SetOutputState(5, false)

        else if msgType = "roVideoEvent" then
            eventCode = msg.GetInt()
            if eventCode = 8 then  ' Video ended
                print "Video finished, returning to menu"
                ShowMenu()
                currentState = "menu"
            end if
        end if
    end while
End Sub

Sub ShowMenu()
    ' Display menu interface (implement with roImagePlayer or HTML widget)
    print "Menu displayed"
End Sub

Sub ShowInformation()
    ' Display information screen
    print "Information displayed"
End Sub
```

### JavaScript Button Events

```javascript
const ControlPort = require('@brightsign/legacy/controlport');
const gpio = new ControlPort("BrightSign");

// Configure inputs
gpio.ConfigureAsInput(0);
gpio.ConfigureAsInput(1);

// Listen for button events
gpio.addEventListener('controldown', (event) => {
    console.log(`Button ${event.button} pressed`);

    switch(event.button) {
        case 0:
            playVideo('video1.mp4');
            break;
        case 1:
            playVideo('video2.mp4');
            break;
    }
});

gpio.addEventListener('controlup', (event) => {
    console.log(`Button ${event.button} released`);
});

function playVideo(filename) {
    // Video playback logic
    console.log('Playing:', filename);
}
```

---

## Part 3: PWM for LED Dimming

PWM (Pulse Width Modulation) allows variable LED brightness by rapidly switching the output on and off.

### Basic PWM Control

```brightscript
Sub PWMDemo()
    gpio = CreateObject("roControlPort", "BrightSign")

    ' Configure GPIO 2 as output
    gpio.EnableOutput(2)
    gpio.SetOutputState(2, true)

    ' Set pulse parameters: 1000ms period, 10 slices (100ms each)
    gpio.SetPulseParams({milliseconds: 1000, slices: 10})

    ' 50% duty cycle: 5 of 10 slices ON
    ' Binary: 0000011111 = 0x1F
    gpio.SetPulse(2, &h1F)

    print "LED at 50% brightness"
    sleep(5000)

    ' Stop pulsing
    gpio.RemovePulse(2)
End Sub
```

### Variable Brightness Control

```brightscript
Sub LEDBrightnessControl()
    gpio = CreateObject("roControlPort", "BrightSign")
    gpio.EnableOutput(2)

    ' 8-bit PWM resolution (8 slices)
    gpio.SetPulseParams({milliseconds: 1000, slices: 8})

    ' Brightness levels (0-100%)
    brightness = [
        {level: 12.5, value: &h01},  ' 1 of 8 slices
        {level: 25.0, value: &h03},  ' 2 of 8 slices
        {level: 37.5, value: &h07},  ' 3 of 8 slices
        {level: 50.0, value: &h0F},  ' 4 of 8 slices
        {level: 62.5, value: &h1F},  ' 5 of 8 slices
        {level: 75.0, value: &h3F},  ' 6 of 8 slices
        {level: 87.5, value: &h7F},  ' 7 of 8 slices
        {level: 100.0, value: &hFF}  ' 8 of 8 slices (full)
    ]

    ' Fade up
    print "Fading up..."
    for each b in brightness
        print "Brightness: "; b.level; "%"
        gpio.SetPulse(2, b.value)
        sleep(500)
    end for

    ' Fade down
    print "Fading down..."
    for i = brightness.Count() - 1 to 0 step -1
        b = brightness[i]
        print "Brightness: "; b.level; "%"
        gpio.SetPulse(2, b.value)
        sleep(500)
    end for

    gpio.RemovePulse(2)
End Sub
```

### Smooth Breathing Effect

```brightscript
Function CalculatePWMValue(brightness as Integer) as Integer
    ' Convert 0-100 percentage to 8-bit PWM value
    slices = 8
    onSlices = int((brightness * slices) / 100)

    ' Build bit pattern (right-aligned 1s)
    value = 0
    for i = 0 to onSlices - 1
        value = value + (2^i)
    end for

    return value
End Function

Sub BreathingLED()
    gpio = CreateObject("roControlPort", "BrightSign")
    gpio.EnableOutput(2)
    gpio.SetPulseParams({milliseconds: 100, slices: 8})

    print "Breathing LED effect..."

    ' Breathe for 30 seconds
    duration = 30000
    startTime = CreateObject("roTimespan")

    while startTime.TotalMilliseconds() < duration
        ' Fade up
        for brightness = 0 to 100 step 5
            pwmValue = CalculatePWMValue(brightness)
            gpio.SetPulse(2, pwmValue)
            sleep(50)
        end for

        ' Fade down
        for brightness = 100 to 0 step -5
            pwmValue = CalculatePWMValue(brightness)
            gpio.SetPulse(2, pwmValue)
            sleep(50)
        end for
    end while

    gpio.RemovePulse(2)
    gpio.SetOutputState(2, false)
End Sub
```

---

## Part 4: Reading Input State

Sometimes you need to poll the current state instead of waiting for events:

```brightscript
Function IsButtonPressed(gpio as Object, buttonId as Integer) as Boolean
    ' Read current state of all GPIO pins
    state = gpio.GetWholeState()

    ' Check if specific button bit is set
    buttonMask = 2^buttonId
    return (state and buttonMask) <> 0
End Function

Sub PollButtonDemo()
    gpio = CreateObject("roControlPort", "BrightSign")
    gpio.EnableInput(0)
    gpio.EnableInput(1)

    print "Polling button states..."

    ' Poll for 30 seconds
    endTime = CreateObject("roTimespan")
    endTime.Mark()

    while endTime.TotalMilliseconds() < 30000
        ' Check button 0
        if IsButtonPressed(gpio, 0) then
            print "Button 0 is pressed"
        end if

        ' Check button 1
        if IsButtonPressed(gpio, 1) then
            print "Button 1 is pressed"
        end if

        sleep(100)  ' Poll every 100ms
    end while
End Sub
```

---

## Part 5: Complete Example - Interactive Kiosk

A production-ready interactive kiosk with buttons, LEDs, and video playback:

### autorun.brs

```brightscript
Sub Main()
    ' Set video mode
    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")

    ' Create message port
    msgPort = CreateObject("roMessagePort")

    ' Initialize GPIO
    gpio = InitializeGPIO(msgPort)

    ' Create video player
    videoPlayer = CreateObject("roVideoPlayer")
    videoPlayer.SetPort(msgPort)

    ' Create timer for timeout
    timeoutTimer = CreateObject("roTimer")
    timeoutTimer.SetPort(msgPort)

    ' State machine
    state = "idle"

    ' Show attract loop
    ShowAttractLoop(videoPlayer)

    print "Interactive kiosk ready"

    while true
        msg = wait(0, msgPort)
        msgType = type(msg)

        if msgType = "roControlDown" then
            buttonId = msg.GetInt()
            state = HandleButton(gpio, videoPlayer, timeoutTimer, buttonId)

        else if msgType = "roVideoEvent" then
            eventCode = msg.GetInt()
            if eventCode = 8 then  ' Video ended
                state = ReturnToIdle(gpio, videoPlayer, timeoutTimer)
            end if

        else if msgType = "roTimerEvent" then
            ' Timeout - return to attract loop
            print "Timeout, returning to idle"
            state = ReturnToIdle(gpio, videoPlayer, timeoutTimer)
        end if
    end while
End Sub

Function InitializeGPIO(msgPort as Object) as Object
    gpio = CreateObject("roControlPort", "BrightSign")
    gpio.SetPort(msgPort)

    ' Configure inputs (buttons)
    gpio.EnableInput(0)  ' Button 1
    gpio.EnableInput(1)  ' Button 2
    gpio.EnableInput(2)  ' Button 3

    ' Configure outputs (LEDs)
    gpio.EnableOutput(4)  ' Button 1 LED
    gpio.EnableOutput(5)  ' Button 2 LED
    gpio.EnableOutput(6)  ' Button 3 LED

    ' Light all button LEDs
    gpio.SetOutputState(4, true)
    gpio.SetOutputState(5, true)
    gpio.SetOutputState(6, true)

    return gpio
End Function

Sub ShowAttractLoop(player as Object)
    ' Play looping attract video
    player.SetLoopMode(true)
    player.PlayFile("attract-loop.mp4")
End Sub

Function HandleButton(gpio as Object, player as Object, timer as Object, buttonId as Integer) as String
    print "Button pressed: "; buttonId

    ' Flash corresponding LED
    ledPin = buttonId + 4
    gpio.SetOutputState(ledPin, false)
    sleep(200)
    gpio.SetOutputState(ledPin, true)

    ' Stop attract loop
    player.Stop()

    ' Play corresponding video
    if buttonId = 0 then
        player.PlayFile("video1.mp4")
    else if buttonId = 1 then
        player.PlayFile("video2.mp4")
    else if buttonId = 2 then
        player.PlayFile("video3.mp4")
    end if

    ' Start timeout timer (60 seconds)
    timer.SetElapsed(60, 0)
    timer.Start()

    return "playing"
End Function

Function ReturnToIdle(gpio as Object, player as Object, timer as Object) as String
    ' Stop timeout timer
    timer.Stop()

    ' Restore button LEDs
    gpio.SetOutputState(4, true)
    gpio.SetOutputState(5, true)
    gpio.SetOutputState(6, true)

    ' Return to attract loop
    ShowAttractLoop(player)

    return "idle"
End Function
```

---

## Safety Considerations

### Voltage Level Protection

**Never apply >3.6V to GPIO inputs - permanent damage can occur.**

For 5V devices, use a voltage divider:

```
5V Signal -> R1 (10kΩ) -> GPIO Input -> R2 (20kΩ) -> Ground
Output voltage = 5V × (20kΩ / 30kΩ) = 3.3V
```

Or use a bidirectional level shifter IC (e.g., TXB0108).

### Current Limiting

**Always use current-limiting resistors with LEDs:**

```
Resistor value = (3.3V - LED_Vf) / LED_current
For red LED: (3.3V - 2.0V) / 0.020A = 65Ω (use 100Ω or 330Ω)
```

**Never exceed 24mA per pin or 500mA total GPIO current.**

For loads >20mA, use a transistor or MOSFET:

```brightscript
' Drive 12V LED strip via MOSFET
' GPIO -> 1kΩ -> MOSFET Gate
' MOSFET Drain -> LED Strip (+)
' LED Strip (-) -> 12V Power Supply (-)
' MOSFET Source -> Ground

gpio = CreateObject("roControlPort", "BrightSign")
gpio.EnableOutput(2)
gpio.SetOutputState(2, true)  ' Turn on LED strip
```

### ESD Protection

**Electrostatic discharge can damage GPIO pins:**

- Use ESD wrist straps during prototyping
- Add 100Ω series resistors on outputs
- Consider TVS diodes for external connections
- Don't hot-plug GPIO connections

### Proper Grounding

**Always connect ground between BrightSign and external devices:**

```
BrightSign GND ──┬── Device 1 GND
                 ├── Device 2 GND
                 └── Device 3 GND
```

Poor grounding causes:
- Erratic input readings
- Signal noise
- Potential damage to equipment

---

## Best Practices

### Do

- **Use current-limiting resistors** with all LEDs
- **Add pull-down resistors** (10kΩ) on button inputs
- **Debounce buttons in software** (ignore events <50ms apart)
- **Check EnableOutput/EnableInput** returns before use
- **Document pin assignments** clearly
- **Test with multimeter** before connecting
- **Use proper wire gauge** for current requirements
- **Label all connections** during prototyping

### Don't

- **Don't connect 5V signals** without level shifting
- **Don't exceed current limits** (24mA per pin, 500mA total)
- **Don't share power supplies** with noisy devices
- **Don't hot-plug GPIO** connections
- **Don't skip current limiting** on LEDs
- **Don't forget ground connections**
- **Don't use GPIO and alternate functions** simultaneously

---

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| GPIO output doesn't work | Not configured as output | Call `EnableOutput(pin)` first |
| LED very dim | Insufficient current | Use lower value resistor (check limits) |
| LED doesn't light | Wrong polarity or connection | Check LED orientation, connections |
| Input always reads same value | Floating input | Add pull-down resistor |
| Erratic button readings | Switch bounce | Add software debounce (50-100ms) |
| Multiple inputs triggered | Ground issue | Verify ground connections |
| GPIO stopped working | Overcurrent | Check for short circuit, power cycle |

### Debugging GPIO Issues

```brightscript
Sub DiagnosticGPIO()
    gpio = CreateObject("roControlPort", "BrightSign")

    ' Test all GPIO pins
    for pin = 0 to 7
        print "Testing GPIO "; pin

        ' Configure as output
        gpio.EnableOutput(pin)

        ' Test on/off
        gpio.SetOutputState(pin, true)
        sleep(500)
        gpio.SetOutputState(pin, false)
        sleep(500)
    end for

    ' Read all input states
    state = gpio.GetWholeState()
    print "GPIO state (binary): "; state
End Sub
```

---

## Exercises

1. **Blinking LED**: Connect an LED to GPIO 2 and make it blink at 1Hz

2. **Button Counter**: Create a button press counter that displays the count via serial output

3. **Traffic Light**: Build a 3-LED traffic light sequence (red, yellow, green)

4. **PWM Fader**: Implement smooth LED fading using PWM with user-adjustable speed

5. **Interactive Slideshow**: Build a 3-button interface that switches between images

6. **Status Panel**: Create a 4-LED status indicator showing boot, network, content, and error states

---

## Next Steps

- [Serial Communication](13-serial-communication.md) - Interface with external devices via RS-232
- [Touch Screen Configuration](15-touch-screen-configuration.md) - Enable touch input
- [USB Device Integration](14-usb-device-integration.md) - Work with USB peripherals

---

## Additional Resources

- [BrightSign roControlPort Documentation](https://brightsign.atlassian.net/wiki/spaces/DOC/pages/370672359/BSControlPort)
- [GPIO User Guide](https://docs.brightsign.biz/user-guides/gpio)
- Electronics tutorials: learn.sparkfun.com, adafruit.com/learn

---

<div align="center">

<img src="../documentation/part-7-assets/brand/brightsign-logo-square.png" alt="BrightSign" width="60">

**Brought to Life by BrightSign**

</div>
