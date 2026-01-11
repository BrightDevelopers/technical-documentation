# Touch Screen Configuration

[← Back to How-To Articles](README.md) | [↑ Main](../README.md)

---

## Introduction

This guide covers configuring and using touchscreen displays with BrightSign players to create interactive digital signage experiences. Touchscreen support enables intuitive user interaction through direct manipulation of on-screen content.

### What You'll Learn

- Setting up USB touchscreen hardware
- Configuring touch regions and buttons
- Handling touch events in BrightScript
- Touch integration with HTML5 applications
- Multi-touch gesture detection
- Touchscreen calibration
- Rollover and hover effects
- Best practices for touch UI design

### Common Touchscreen Applications

| Use Case | Interaction Type | Technology |
|----------|------------------|------------|
| **Wayfinding Kiosks** | Tap navigation, maps | Capacitive touch |
| **Product Catalogs** | Swipe, zoom, tap | Multi-touch |
| **Self-Service** | Button selection, forms | Single-touch |
| **Games & Demos** | Drag, pinch, gesture | Multi-touch |
| **Information Displays** | Menu navigation | Single/multi-touch |

---

## Prerequisites

- BrightSign player with USB support (all current models)
- USB touchscreen display (HID-compatible)
- Development environment set up ([see setup guide](01-setting-up-development-environment.md))
- Understanding of coordinate systems
- Basic knowledge of HTML5/JavaScript (for web-based touch)

---

## Touchscreen Hardware Compatibility

### Supported Touch Technologies

| Technology | Description | Support |
|------------|-------------|---------|
| **Capacitive** | Multi-touch, modern displays | Recommended |
| **Resistive** | Single-touch, pressure-based | Supported |
| **Infrared** | Optical touch, overlay | Supported |
| **SAW** | Surface Acoustic Wave | Supported |

### Driver Requirements

**BrightSign supports standard HID touchscreen drivers.**

- Touchscreens using Windows HID drivers: **Compatible**
- Touchscreens requiring custom drivers: **Not compatible**
- USB mice: **Compatible** (for testing)

**Check compatibility:** Test with a BrightSign player before deployment.

---

## Part 1: Basic Touch Setup (BrightScript)

### Creating Touch Regions

```brightscript
Sub Main()
    ' Set video mode
    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")

    ' Create message port
    msgPort = CreateObject("roMessagePort")

    ' Create touchscreen object
    touch = CreateObject("roTouchScreen")
    touch.SetPort(msgPort)

    ' Set screen resolution (must match video mode)
    touch.SetResolution(1920, 1080)

    ' Define rectangular touch regions
    touch.AddRectangleRegion(100, 100, 400, 300, 1)    ' Region 1: Top-left button
    touch.AddRectangleRegion(600, 100, 400, 300, 2)    ' Region 2: Top-center button
    touch.AddRectangleRegion(1100, 100, 400, 300, 3)   ' Region 3: Top-right button

    ' Define circular region
    touch.AddCircleRegion(960, 700, 150, 4)            ' Region 4: Center circle

    print "Touch regions configured"
    print "Touch the screen to test..."

    ' Event loop
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roTouchEvent" then
            x = msg.GetX()
            y = msg.GetY()
            regionId = msg.GetID()

            print "Touch at ("; x; ","; y; ") Region: "; regionId

            ' Handle touch events
            HandleTouch(regionId)
        end if
    end while
End Sub

Sub HandleTouch(regionId as Integer)
    if regionId = 1 then
        print "Button 1 touched"
    else if regionId = 2 then
        print "Button 2 touched"
    else if regionId = 3 then
        print "Button 3 touched"
    else if regionId = 4 then
        print "Center circle touched"
    else if regionId = 0 then
        print "Touch outside defined regions"
    end if
End Sub
```

### Touch Region Types

**Rectangular Regions:**

```brightscript
' AddRectangleRegion(x, y, width, height, id)
touch.AddRectangleRegion(100, 100, 300, 200, 1)
```

**Circular Regions:**

```brightscript
' AddCircleRegion(centerX, centerY, radius, id)
touch.AddCircleRegion(960, 540, 100, 2)
```

### Touch Region Management

```brightscript
Sub ManageTouchRegions()
    touch = CreateObject("roTouchScreen")
    msgPort = CreateObject("roMessagePort")
    touch.SetPort(msgPort)
    touch.SetResolution(1920, 1080)

    ' Add initial regions
    touch.AddRectangleRegion(0, 0, 960, 1080, 1)      ' Left half
    touch.AddRectangleRegion(960, 0, 960, 1080, 2)    ' Right half

    print "Touch left or right side..."
    sleep(5000)

    ' Clear all regions
    touch.ClearRegions()
    print "Regions cleared"

    ' Add new layout
    touch.AddCircleRegion(480, 540, 200, 10)   ' Left circle
    touch.AddCircleRegion(1440, 540, 200, 11)  ' Right circle

    print "Touch circles..."
    sleep(5000)
End Sub
```

---

## Part 2: HTML5 Touch Integration

### Basic HTML5 Touch Events

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=1920, height=1080">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            width: 1920px;
            height: 1080px;
            background: #1a1a1a;
            font-family: Arial, sans-serif;
            overflow: hidden;
        }

        .button {
            position: absolute;
            width: 400px;
            height: 300px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 20px;
            display: flex;
            justify-content: center;
            align-items: center;
            color: white;
            font-size: 48px;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.3s ease;
            user-select: none;
        }

        .button:active {
            transform: scale(0.95);
            box-shadow: 0 0 30px rgba(102, 126, 234, 0.8);
        }

        #button1 { top: 100px; left: 100px; }
        #button2 { top: 100px; left: 760px; }
        #button3 { top: 100px; left: 1420px; }

        .feedback {
            position: absolute;
            bottom: 100px;
            left: 0;
            width: 100%;
            text-align: center;
            color: white;
            font-size: 36px;
        }
    </style>
</head>
<body>
    <div class="button" id="button1">Button 1</div>
    <div class="button" id="button2">Button 2</div>
    <div class="button" id="button3">Button 3</div>
    <div class="feedback" id="feedback">Touch a button...</div>

    <script>
        // Touch event handling
        document.querySelectorAll('.button').forEach((button, index) => {
            button.addEventListener('touchstart', (event) => {
                event.preventDefault();
                console.log(`Button ${index + 1} touched`);
                document.getElementById('feedback').textContent =
                    `Button ${index + 1} Touched!`;

                // Send message to BrightScript (if using roHtmlWidget)
                if (window.bsMessage) {
                    window.bsMessage({
                        type: 'button_press',
                        button: index + 1
                    });
                }
            });

            button.addEventListener('touchend', (event) => {
                event.preventDefault();
                console.log(`Button ${index + 1} released`);
            });

            // Also handle mouse for development/testing
            button.addEventListener('click', (event) => {
                console.log(`Button ${index + 1} clicked`);
                document.getElementById('feedback').textContent =
                    `Button ${index + 1} Clicked!`;
            });
        });
    </script>
</body>
</html>
```

### Multi-Touch Gesture Detection

```html
<!DOCTYPE html>
<html>
<head>
    <style>
        body {
            width: 1920px;
            height: 1080px;
            background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);
            color: white;
            font-family: Arial, sans-serif;
            overflow: hidden;
        }

        .canvas-container {
            width: 100%;
            height: 100%;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        #gesture-feedback {
            position: absolute;
            top: 50px;
            left: 50%;
            transform: translateX(-50%);
            font-size: 48px;
            background: rgba(0,0,0,0.7);
            padding: 20px 40px;
            border-radius: 10px;
        }
    </style>
</head>
<body>
    <div class="canvas-container">
        <div id="gesture-feedback">Touch to begin</div>
    </div>

    <script>
        class GestureDetector {
            constructor() {
                this.touches = new Map();
                this.gestureThreshold = 50; // pixels
                this.swipeThreshold = 100;
                this.tapTimeout = 300; // ms

                this.setupListeners();
            }

            setupListeners() {
                document.addEventListener('touchstart', this.onTouchStart.bind(this));
                document.addEventListener('touchmove', this.onTouchMove.bind(this));
                document.addEventListener('touchend', this.onTouchEnd.bind(this));
            }

            onTouchStart(event) {
                event.preventDefault();

                for (let touch of event.changedTouches) {
                    this.touches.set(touch.identifier, {
                        startX: touch.clientX,
                        startY: touch.clientY,
                        currentX: touch.clientX,
                        currentY: touch.clientY,
                        startTime: Date.now()
                    });
                }

                // Detect multi-finger gestures
                if (this.touches.size === 2) {
                    this.showFeedback('Two-finger touch');
                    this.detectPinch();
                }
            }

            onTouchMove(event) {
                event.preventDefault();

                for (let touch of event.changedTouches) {
                    const data = this.touches.get(touch.identifier);
                    if (data) {
                        data.currentX = touch.clientX;
                        data.currentY = touch.clientY;
                    }
                }

                if (this.touches.size === 2) {
                    this.detectPinch();
                }
            }

            onTouchEnd(event) {
                event.preventDefault();

                for (let touch of event.changedTouches) {
                    const data = this.touches.get(touch.identifier);
                    if (data) {
                        this.detectGesture(data);
                        this.touches.delete(touch.identifier);
                    }
                }
            }

            detectGesture(data) {
                const dx = data.currentX - data.startX;
                const dy = data.currentY - data.startY;
                const distance = Math.sqrt(dx * dx + dy * dy);
                const duration = Date.now() - data.startTime;

                // Tap detection
                if (distance < this.gestureThreshold && duration < this.tapTimeout) {
                    this.showFeedback('Tap');
                    return;
                }

                // Swipe detection
                if (distance > this.swipeThreshold) {
                    const angle = Math.atan2(dy, dx) * 180 / Math.PI;

                    if (Math.abs(angle) < 45) {
                        this.showFeedback('Swipe Right');
                    } else if (Math.abs(angle) > 135) {
                        this.showFeedback('Swipe Left');
                    } else if (angle > 0) {
                        this.showFeedback('Swipe Down');
                    } else {
                        this.showFeedback('Swipe Up');
                    }
                }
            }

            detectPinch() {
                if (this.touches.size !== 2) return;

                const touchArray = Array.from(this.touches.values());
                const touch1 = touchArray[0];
                const touch2 = touchArray[1];

                const startDist = this.distance(
                    touch1.startX, touch1.startY,
                    touch2.startX, touch2.startY
                );

                const currentDist = this.distance(
                    touch1.currentX, touch1.currentY,
                    touch2.currentX, touch2.currentY
                );

                if (Math.abs(currentDist - startDist) > 20) {
                    if (currentDist > startDist) {
                        this.showFeedback('Pinch Out (Zoom)');
                    } else {
                        this.showFeedback('Pinch In (Zoom Out)');
                    }
                }
            }

            distance(x1, y1, x2, y2) {
                const dx = x2 - x1;
                const dy = y2 - y1;
                return Math.sqrt(dx * dx + dy * dy);
            }

            showFeedback(message) {
                const feedback = document.getElementById('gesture-feedback');
                feedback.textContent = message;
                console.log('Gesture:', message);
            }
        }

        // Initialize gesture detector
        const gestureDetector = new GestureDetector();
    </script>
</body>
</html>
```

---

## Part 3: Interactive Image Gallery

A complete touch-enabled image gallery:

### autorun.brs

```brightscript
Sub Main()
    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")

    rect = CreateObject("roRectangle", 0, 0, 1920, 1080)
    htmlWidget = CreateObject("roHtmlWidget", rect, {
        url: "file:///sd:/gallery/index.html",
        mouse_enabled: true
    })
    htmlWidget.Show()

    msgPort = CreateObject("roMessagePort")
    htmlWidget.SetPort(msgPort)

    print "Touch gallery ready"

    while true
        msg = wait(0, msgPort)

        if type(msg) = "roHtmlWidgetEvent" then
            eventData = msg.GetData()

            if eventData.reason = "message" then
                HandleGalleryMessage(eventData.message)
            end if
        end if
    end while
End Sub

Sub HandleGalleryMessage(message as Object)
    if message.type = "image_selected" then
        print "Image selected: "; message.index
    else if message.type = "swipe" then
        print "Swipe direction: "; message.direction
    end if
End Sub
```

### gallery/index.html

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            width: 1920px;
            height: 1080px;
            background: #000;
            overflow: hidden;
            font-family: Arial, sans-serif;
        }

        .gallery-container {
            width: 100%;
            height: 100%;
            position: relative;
        }

        .main-image {
            width: 100%;
            height: calc(100% - 200px);
            display: flex;
            justify-content: center;
            align-items: center;
        }

        .main-image img {
            max-width: 90%;
            max-height: 90%;
            object-fit: contain;
        }

        .thumbnail-strip {
            position: absolute;
            bottom: 0;
            width: 100%;
            height: 200px;
            background: rgba(0,0,0,0.8);
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 20px;
            padding: 20px;
        }

        .thumbnail {
            width: 240px;
            height: 160px;
            border: 3px solid transparent;
            border-radius: 10px;
            overflow: hidden;
            cursor: pointer;
            transition: all 0.3s ease;
        }

        .thumbnail.active {
            border-color: #4CAF50;
            transform: scale(1.1);
        }

        .thumbnail img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        .nav-button {
            position: absolute;
            top: 50%;
            transform: translateY(-50%);
            width: 100px;
            height: 100px;
            background: rgba(255,255,255,0.3);
            border-radius: 50%;
            display: flex;
            justify-content: center;
            align-items: center;
            font-size: 48px;
            color: white;
            cursor: pointer;
            transition: all 0.3s ease;
            user-select: none;
        }

        .nav-button:active {
            transform: translateY(-50%) scale(0.9);
        }

        .nav-button.prev { left: 50px; }
        .nav-button.next { right: 50px; }
    </style>
</head>
<body>
    <div class="gallery-container">
        <div class="main-image">
            <img id="main-img" src="" alt="Gallery Image">
        </div>

        <div class="nav-button prev" id="prev-btn">‹</div>
        <div class="nav-button next" id="next-btn">›</div>

        <div class="thumbnail-strip" id="thumbnails"></div>
    </div>

    <script>
        class TouchGallery {
            constructor(images) {
                this.images = images;
                this.currentIndex = 0;
                this.touchStartX = 0;
                this.touchStartY = 0;

                this.init();
            }

            init() {
                // Render thumbnails
                const strip = document.getElementById('thumbnails');
                this.images.forEach((img, index) => {
                    const thumb = document.createElement('div');
                    thumb.className = 'thumbnail';
                    if (index === 0) thumb.classList.add('active');

                    const thumbImg = document.createElement('img');
                    thumbImg.src = img;
                    thumb.appendChild(thumbImg);

                    thumb.addEventListener('touchstart', (e) => {
                        e.preventDefault();
                        this.showImage(index);
                    });

                    thumb.addEventListener('click', () => {
                        this.showImage(index);
                    });

                    strip.appendChild(thumb);
                });

                // Show first image
                this.showImage(0);

                // Setup navigation
                document.getElementById('prev-btn').addEventListener('touchstart', (e) => {
                    e.preventDefault();
                    this.previous();
                });

                document.getElementById('next-btn').addEventListener('touchstart', (e) => {
                    e.preventDefault();
                    this.next();
                });

                // Swipe gestures on main image
                const mainImage = document.querySelector('.main-image');
                mainImage.addEventListener('touchstart', this.onTouchStart.bind(this));
                mainImage.addEventListener('touchend', this.onTouchEnd.bind(this));
            }

            showImage(index) {
                this.currentIndex = index;
                document.getElementById('main-img').src = this.images[index];

                // Update active thumbnail
                document.querySelectorAll('.thumbnail').forEach((thumb, i) => {
                    if (i === index) {
                        thumb.classList.add('active');
                    } else {
                        thumb.classList.remove('active');
                    }
                });

                // Send to BrightScript
                if (window.bsMessage) {
                    window.bsMessage({
                        type: 'image_selected',
                        index: index
                    });
                }
            }

            next() {
                this.currentIndex = (this.currentIndex + 1) % this.images.length;
                this.showImage(this.currentIndex);
            }

            previous() {
                this.currentIndex = (this.currentIndex - 1 + this.images.length) % this.images.length;
                this.showImage(this.currentIndex);
            }

            onTouchStart(event) {
                this.touchStartX = event.touches[0].clientX;
                this.touchStartY = event.touches[0].clientY;
            }

            onTouchEnd(event) {
                const touchEndX = event.changedTouches[0].clientX;
                const touchEndY = event.changedTouches[0].clientY;

                const dx = touchEndX - this.touchStartX;
                const dy = touchEndY - this.touchStartY;

                // Detect swipe (minimum 100px)
                if (Math.abs(dx) > 100 && Math.abs(dx) > Math.abs(dy)) {
                    if (dx > 0) {
                        this.previous();
                        if (window.bsMessage) {
                            window.bsMessage({type: 'swipe', direction: 'right'});
                        }
                    } else {
                        this.next();
                        if (window.bsMessage) {
                            window.bsMessage({type: 'swipe', direction: 'left'});
                        }
                    }
                }
            }
        }

        // Initialize gallery
        const images = [
            'images/image1.jpg',
            'images/image2.jpg',
            'images/image3.jpg',
            'images/image4.jpg',
            'images/image5.jpg'
        ];

        const gallery = new TouchGallery(images);
    </script>
</body>
</html>
```

---

## Part 4: Touchscreen Calibration

### Manual Calibration

```brightscript
Sub CalibrateTouch()
    touch = CreateObject("roTouchScreen")
    msgPort = CreateObject("roMessagePort")
    touch.SetPort(msgPort)
    touch.SetResolution(1920, 1080)

    print "Starting touchscreen calibration..."

    ' Start calibration process
    success = touch.StartCalibration()

    if not success then
        print "Failed to start calibration"
        return
    end if

    print "Touch the calibration points as they appear..."

    while true
        msg = wait(0, msgPort)

        if type(msg) = "roTouchCalibrationEvent" then
            status = touch.GetCalibrationStatus()

            if status = 0 then
                print "Calibration complete!"
                exit while
            else if status < 0 then
                print "Calibration failed with error: "; status
                exit while
            else
                print "Calibration in progress... step "; status
            end if
        end if
    end while
End Sub
```

---

## Part 5: Rollover Effects (Hover)

```brightscript
Sub CreateRolloverButtons()
    touch = CreateObject("roTouchScreen")
    msgPort = CreateObject("roMessagePort")
    touch.SetPort(msgPort)
    touch.SetResolution(1920, 1080)

    ' Enable rollover detection
    touch.EnableRollover()

    ' Create button with rollover images
    buttonRegion = {
        x: 500,
        y: 400,
        w: 400,
        h: 200
    }

    ' Add rectangle region with rollover
    touch.AddRectangleRegion(
        buttonRegion.x,
        buttonRegion.y,
        buttonRegion.w,
        buttonRegion.h,
        1
    )

    ' Set rollover images
    touch.SetRolloverImage(1, "button-normal.png", "button-hover.png")

    print "Rollover button configured"

    while true
        msg = wait(0, msgPort)

        if type(msg) = "roTouchEvent" then
            eventType = msg.GetType()

            if eventType = "Enter" then
                print "Mouse entered region"
            else if eventType = "Exit" then
                print "Mouse exited region"
            else if eventType = "Down" then
                print "Touch down in region"
            else if eventType = "Up" then
                print "Touch up in region"
            end if
        end if
    end while
End Sub
```

---

## Touch UI Best Practices

### Design Guidelines

**Touch Target Sizes:**
- Minimum: 44x44 pixels (iOS guideline)
- Recommended: 60x60 pixels or larger
- Spacing: 8-16 pixels between targets

**Visual Feedback:**
- Provide immediate visual response
- Use animations and transitions
- Show pressed state clearly
- Indicate disabled states

**Touch Zones:**
```
Top 10%: Status, back button
Middle 80%: Main content, interactive elements
Bottom 10%: Navigation, primary actions
```

### Accessibility Considerations

- High contrast for visibility
- Large, clear typography
- Simple, obvious navigation
- Consistent interaction patterns
- Timeout warnings for inactive sessions

---

## Best Practices

### Do

- **Test with actual touchscreen** hardware before deployment
- **Use large touch targets** (60x60px minimum)
- **Provide visual feedback** for all interactions
- **Calibrate touchscreen** if accuracy issues occur
- **Disable mouse cursor** in production (mouse_enabled: false)
- **Handle both touch and mouse** during development
- **Use hardware acceleration** (CSS transforms, opacity)
- **Prevent default** browser touch behaviors

### Don't

- **Don't use hover-only interactions** - no mouse hovering on touch
- **Don't make targets too small** - frustrating for users
- **Don't forget touch feedback** - users need confirmation
- **Don't assume single touch** - support multi-touch if possible
- **Don't block UI** during processing
- **Don't use complex gestures** unless clearly indicated

---

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| Touch not working | Wrong USB port | Use USB 2.0 port (not 3.0 sometimes) |
| Inaccurate touch | Not calibrated | Run calibration routine |
| Touch offset | Wrong resolution | Set correct resolution in SetResolution() |
| No multi-touch | Hardware limitation | Verify touchscreen supports multi-touch |
| Laggy response | Too many calculations | Optimize event handlers |
| Wrong orientation | Display rotated | Recalibrate after rotation |

### Testing Touch Accuracy

```brightscript
Sub TestTouchAccuracy()
    touch = CreateObject("roTouchScreen")
    msgPort = CreateObject("roMessagePort")
    touch.SetPort(msgPort)
    touch.SetResolution(1920, 1080)

    ' Create grid of test points
    gridSize = 5
    for row = 0 to gridSize - 1
        for col = 0 to gridSize - 1
            x = 200 + (col * 300)
            y = 150 + (row * 150)

            ' Add small circular region
            touch.AddCircleRegion(x, y, 30, row * gridSize + col + 1)
        end for
    end for

    print "Touch test grid active - touch circles to test accuracy"

    while true
        msg = wait(0, msgPort)

        if type(msg) = "roTouchEvent" then
            x = msg.GetX()
            y = msg.GetY()
            regionId = msg.GetID()

            print "Touch at ("; x; ","; y; ") Region: "; regionId
        end if
    end while
End Sub
```

---

## Exercises

1. **Button Grid**: Create a 3x3 grid of touch buttons that change content when pressed

2. **Image Gallery**: Build a swipe-enabled image gallery with thumbnail navigation

3. **Interactive Map**: Create a wayfinding kiosk with zoomable touch map

4. **Drawing App**: Build a simple drawing application using touch coordinates

5. **Quiz Game**: Create a multiple-choice quiz with touch button selection

6. **Virtual Keyboard**: Implement an on-screen keyboard for text input

---

## Next Steps

- [Using GPIO for Interactivity](12-using-gpio-for-interactivity.md) - Physical button control
- [Serial Communication](13-serial-communication.md) - RS-232 device interfacing
- [USB Device Integration](14-usb-device-integration.md) - USB peripherals

---

## Additional Resources

- [BrightSign roTouchScreen Documentation](https://docs.brightsign.biz/developers/rotouchscreen)
- [Touchscreen Advanced Guide](https://docs.brightsign.biz/advanced/touchscreens)
- Touch Design Guidelines: Material Design, iOS HIG

---

<div align="center">

<img src="../documentation/part-7-assets/brand/brightsign-logo-square.png" alt="BrightSign" width="60">

**Brought to Life by BrightSign**

</div>
