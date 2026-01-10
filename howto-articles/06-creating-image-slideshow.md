# Creating an Image Slideshow

[← Back to How-To Articles](README.md) | [↑ Main](../README.md)

---

## Introduction

This guide covers building image slideshows on BrightSign players, from simple rotating displays to smooth transition effects with preloading.

### Image Display Options

| Approach | Best For | Key Object |
|----------|----------|------------|
| **roImagePlayer** | Simple slideshows, transitions | Basic image display |
| **roImageWidget** | Styled displays, backgrounds | Enhanced aesthetics |
| **HTML/CSS** | Complex animations, web developers | Full browser control |

### Supported Formats

| Format | Notes |
|--------|-------|
| JPEG | Most common, no transparency |
| PNG | Supports transparency (8/24/32-bit) |
| BMP | 8-bit, 24-bit, and 32-bit |

**Note:** JPEG files with CMYK color profiles are not supported.

---

## Basic Image Display

### Display a Single Image

```brightscript
Sub Main()
    ' Create image player
    imagePlayer = CreateObject("roImagePlayer")

    ' Display image
    imagePlayer.DisplayFile("image.jpg")

    ' Keep displaying (script must stay running)
    while true
        sleep(1000)
    end while
End Sub
```

### Display in a Specific Zone

```brightscript
Sub Main()
    imagePlayer = CreateObject("roImagePlayer")

    ' Define display area: x, y, width, height
    rect = CreateObject("roRectangle", 100, 100, 800, 600)
    imagePlayer.SetRectangle(rect)

    ' Display image in zone
    imagePlayer.DisplayFile("image.jpg")

    while true
        sleep(1000)
    end while
End Sub
```

---

## Display Modes

Control how images scale to fit the display area:

```brightscript
' Set display mode before showing images
imagePlayer.SetDefaultMode(mode)
```

| Mode | Behavior |
|------|----------|
| 0 | Center without scaling (crops if larger than zone) |
| 1 | Scale to fit maintaining aspect ratio (letterbox/pillarbox) |
| 2 | Scale to fill and crop excess (maintains aspect ratio) |
| 3 | Stretch to fill zone (may distort image) |

```brightscript
Sub Main()
    imagePlayer = CreateObject("roImagePlayer")

    ' Scale to fit, maintaining aspect ratio
    imagePlayer.SetDefaultMode(1)

    imagePlayer.DisplayFile("image.jpg")

    while true
        sleep(1000)
    end while
End Sub
```

---

## Transitions

Add visual transitions between images:

```brightscript
' Set transition type
imagePlayer.SetDefaultTransition(transitionCode)

' Set transition duration in milliseconds
imagePlayer.SetTransitionDuration(500)
```

### Transition Types

| Code | Effect |
|------|--------|
| 0 | No transition (immediate) |
| 1 | Wipe from left |
| 2 | Wipe from right |
| 3 | Wipe from top |
| 4 | Wipe from bottom |
| 5-8 | Explode from corners/center |
| 10-11 | Venetian blind (horizontal/vertical) |
| 12-13 | Comb (horizontal/vertical) |
| 14 | Fade to background color |
| 15 | **Cross-fade** (recommended) |
| 16-19 | Slide from edges |
| 20-23 | Full-screen slide |
| 24-25 | Pseudo-3D rotation |
| 26-29 | Expand from edges |

### Cross-Fade Example

```brightscript
Sub Main()
    imagePlayer = CreateObject("roImagePlayer")

    ' Enable cross-fade transition
    imagePlayer.SetDefaultTransition(15)
    imagePlayer.SetTransitionDuration(500)  ' 500ms fade

    ' Display images with transitions
    imagePlayer.DisplayFile("image1.jpg")
    sleep(3000)

    imagePlayer.DisplayFile("image2.jpg")  ' Cross-fades from image1
    sleep(3000)

    imagePlayer.DisplayFile("image3.jpg")  ' Cross-fades from image2

    while true
        sleep(1000)
    end while
End Sub
```

---

## Simple Slideshow

### Basic Loop

```brightscript
Sub Main()
    imagePlayer = CreateObject("roImagePlayer")

    ' Configure display
    imagePlayer.SetDefaultMode(1)  ' Scale to fit
    imagePlayer.SetDefaultTransition(15)  ' Cross-fade
    imagePlayer.SetTransitionDuration(500)

    ' Image list
    images = ["slide1.jpg", "slide2.jpg", "slide3.jpg", "slide4.jpg"]
    displayTime = 5  ' Seconds per image

    ' Slideshow loop
    currentIndex = 0
    while true
        imagePlayer.DisplayFile(images[currentIndex])
        sleep(displayTime * 1000)

        currentIndex = (currentIndex + 1) mod images.Count()
    end while
End Sub
```

### Event-Driven Slideshow with Timer

Better approach using events instead of `sleep()`:

```brightscript
Sub Main()
    imagePlayer = CreateObject("roImagePlayer")
    msgPort = CreateObject("roMessagePort")

    ' Configure display
    imagePlayer.SetDefaultMode(1)
    imagePlayer.SetDefaultTransition(15)
    imagePlayer.SetTransitionDuration(500)

    ' Create timer for image changes
    timer = CreateObject("roTimer")
    timer.SetPort(msgPort)
    timer.SetElapsed(5, 0)  ' 5 seconds

    ' Image list
    images = ["slide1.jpg", "slide2.jpg", "slide3.jpg", "slide4.jpg"]
    currentIndex = 0

    ' Display first image and start timer
    imagePlayer.DisplayFile(images[currentIndex])
    timer.Start()

    ' Event loop
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roTimerEvent" then
            ' Advance to next image
            currentIndex = (currentIndex + 1) mod images.Count()
            imagePlayer.DisplayFile(images[currentIndex])

            ' Restart timer
            timer.Start()
        end if
    end while
End Sub
```

---

## Preloading for Smooth Transitions

For professional results, preload the next image while the current one displays.

### How Preloading Works

The image player has two memory buffers:
1. **On-screen buffer**: Currently displayed image
2. **Off-screen buffer**: Preloaded image ready to display

```brightscript
Sub SmoothSlideshow()
    imagePlayer = CreateObject("roImagePlayer")
    msgPort = CreateObject("roMessagePort")

    imagePlayer.SetDefaultMode(1)
    imagePlayer.SetDefaultTransition(15)
    imagePlayer.SetTransitionDuration(500)

    timer = CreateObject("roTimer")
    timer.SetPort(msgPort)
    timer.SetElapsed(5, 0)

    images = ["slide1.jpg", "slide2.jpg", "slide3.jpg", "slide4.jpg"]
    currentIndex = 0

    ' Preload and display first image
    imagePlayer.PreloadFile(images[currentIndex])
    imagePlayer.DisplayPreload()

    ' Preload next image
    nextIndex = 1
    imagePlayer.PreloadFile(images[nextIndex])

    timer.Start()

    while true
        msg = wait(0, msgPort)

        if type(msg) = "roTimerEvent" then
            ' Display preloaded image (instant)
            imagePlayer.DisplayPreload()

            ' Update indices
            currentIndex = nextIndex
            nextIndex = (nextIndex + 1) mod images.Count()

            ' Preload next image while current displays
            imagePlayer.PreloadFile(images[nextIndex])

            timer.Start()
        end if
    end while
End Sub
```

---

## Image Transforms

Apply rotation or mirroring to images:

```brightscript
' Set transform before displaying
imagePlayer.SetTransform("rot90")    ' Rotate 90° clockwise
imagePlayer.SetTransform("rot180")   ' Rotate 180°
imagePlayer.SetTransform("rot270")   ' Rotate 270° (90° counter-clockwise)
imagePlayer.SetTransform("mirror")   ' Mirror horizontally
imagePlayer.SetTransform("mirror_rot90")  ' Mirror and rotate
imagePlayer.SetTransform("identity") ' No transform (default)

' Then display image
imagePlayer.DisplayFile("image.jpg")
```

---

## Dynamic Content Loading

### Scan Directory for Images

```brightscript
Function GetImageFiles(directory as String) as Object
    images = []

    files = ListDir(directory)
    for each file in files
        ext = LCase(Right(file, 4))
        if ext = ".jpg" or ext = ".png" or ext = ".bmp" then
            images.Push(directory + "/" + file)
        end if
    end for

    ' Sort alphabetically
    images.Sort()

    return images
End Function

Sub Main()
    imagePlayer = CreateObject("roImagePlayer")
    imagePlayer.SetDefaultTransition(15)
    imagePlayer.SetTransitionDuration(500)

    ' Load images from directory
    images = GetImageFiles("/images")

    if images.Count() = 0 then
        print "No images found"
        return
    end if

    print "Found "; images.Count(); " images"

    ' Run slideshow
    currentIndex = 0
    while true
        imagePlayer.DisplayFile(images[currentIndex])
        sleep(5000)
        currentIndex = (currentIndex + 1) mod images.Count()
    end while
End Sub
```

### Load Configuration from JSON

```brightscript
Function LoadSlideshowConfig() as Object
    ' Default configuration
    config = {
        displayTime: 5,
        transition: 15,
        transitionDuration: 500,
        mode: 1,
        images: []
    }

    ' Try to load from file
    jsonContent = ReadAsciiFile("slideshow.json")
    if jsonContent <> "" then
        parsed = ParseJson(jsonContent)
        if parsed <> invalid then
            if parsed.displayTime <> invalid then config.displayTime = parsed.displayTime
            if parsed.transition <> invalid then config.transition = parsed.transition
            if parsed.transitionDuration <> invalid then config.transitionDuration = parsed.transitionDuration
            if parsed.mode <> invalid then config.mode = parsed.mode
            if parsed.images <> invalid then config.images = parsed.images
        end if
    end if

    return config
End Function
```

Example `slideshow.json`:

```json
{
    "displayTime": 8,
    "transition": 15,
    "transitionDuration": 750,
    "mode": 2,
    "images": [
        "promo1.jpg",
        "promo2.jpg",
        "promo3.jpg",
        "special_offer.png"
    ]
}
```

---

## HTML/CSS Slideshow

For more complex animations, use HTML and CSS:

### Basic CSS Slideshow

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
        }

        .slideshow {
            position: relative;
            width: 100%;
            height: 100%;
        }

        .slide {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            opacity: 0;
            transition: opacity 0.5s ease-in-out;
        }

        .slide.active {
            opacity: 1;
        }

        .slide img {
            width: 100%;
            height: 100%;
            object-fit: contain;  /* or 'cover' to fill */
        }
    </style>
</head>
<body>
    <div class="slideshow" id="slideshow">
        <div class="slide active"><img src="slide1.jpg" alt=""></div>
        <div class="slide"><img src="slide2.jpg" alt=""></div>
        <div class="slide"><img src="slide3.jpg" alt=""></div>
        <div class="slide"><img src="slide4.jpg" alt=""></div>
    </div>

    <script>
        const slides = document.querySelectorAll('.slide');
        let currentIndex = 0;
        const displayTime = 5000;  // 5 seconds

        function nextSlide() {
            slides[currentIndex].classList.remove('active');
            currentIndex = (currentIndex + 1) % slides.length;
            slides[currentIndex].classList.add('active');
        }

        // Start slideshow
        setInterval(nextSlide, displayTime);
    </script>
</body>
</html>
```

### Ken Burns Effect (Pan and Zoom)

```html
<!DOCTYPE html>
<html>
<head>
    <style>
        body {
            width: 1920px;
            height: 1080px;
            margin: 0;
            overflow: hidden;
            background: #000;
        }

        .slideshow {
            position: relative;
            width: 100%;
            height: 100%;
        }

        .slide {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            opacity: 0;
            transition: opacity 1s ease-in-out;
        }

        .slide.active {
            opacity: 1;
        }

        .slide img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            animation: kenburns 8s ease-in-out;
        }

        @keyframes kenburns {
            0% {
                transform: scale(1) translate(0, 0);
            }
            100% {
                transform: scale(1.1) translate(-2%, -2%);
            }
        }

        /* Alternate animation direction for variety */
        .slide:nth-child(even) img {
            animation-name: kenburns-alt;
        }

        @keyframes kenburns-alt {
            0% {
                transform: scale(1.1) translate(-2%, -2%);
            }
            100% {
                transform: scale(1) translate(0, 0);
            }
        }
    </style>
</head>
<body>
    <div class="slideshow">
        <div class="slide active"><img src="slide1.jpg"></div>
        <div class="slide"><img src="slide2.jpg"></div>
        <div class="slide"><img src="slide3.jpg"></div>
    </div>

    <script>
        const slides = document.querySelectorAll('.slide');
        let current = 0;

        setInterval(() => {
            slides[current].classList.remove('active');
            current = (current + 1) % slides.length;
            slides[current].classList.add('active');
        }, 8000);
    </script>
</body>
</html>
```

### Dynamic Image Loading (JavaScript)

```html
<!DOCTYPE html>
<html>
<head>
    <style>
        body {
            width: 1920px;
            height: 1080px;
            margin: 0;
            background: #000;
        }
        .slide {
            position: absolute;
            width: 100%;
            height: 100%;
            opacity: 0;
            transition: opacity 0.5s;
        }
        .slide.active { opacity: 1; }
        .slide img {
            width: 100%;
            height: 100%;
            object-fit: contain;
        }
    </style>
</head>
<body>
    <div id="container"></div>

    <script>
        // Image list - could be loaded from JSON
        const images = [
            'slide1.jpg',
            'slide2.jpg',
            'slide3.jpg',
            'slide4.jpg'
        ];

        const container = document.getElementById('container');
        let currentIndex = 0;
        let slides = [];

        // Create slide elements
        images.forEach((src, index) => {
            const slide = document.createElement('div');
            slide.className = 'slide' + (index === 0 ? ' active' : '');

            const img = document.createElement('img');
            img.src = src;
            img.alt = '';

            slide.appendChild(img);
            container.appendChild(slide);
            slides.push(slide);
        });

        // Slideshow logic
        function nextSlide() {
            slides[currentIndex].classList.remove('active');
            currentIndex = (currentIndex + 1) % slides.length;
            slides[currentIndex].classList.add('active');
        }

        setInterval(nextSlide, 5000);
    </script>
</body>
</html>
```

---

## Complete Production Slideshow

```brightscript
' autorun.brs - Production Slideshow Application

Sub Main()
    app = CreateSlideshowApp()
    app.Run()
End Sub

Function CreateSlideshowApp() as Object
    return {
        imagePlayer: invalid,
        msgPort: invalid,
        timer: invalid,
        config: invalid,
        images: [],
        currentIndex: 0,

        Run: Sub()
            m.Initialize()
            m.LoadContent()

            if m.images.Count() > 0 then
                m.StartSlideshow()
                m.EventLoop()
            else
                print "No images to display"
            end if
        End Sub,

        Initialize: Sub()
            m.msgPort = CreateObject("roMessagePort")

            ' Load configuration
            m.config = m.LoadConfig()

            ' Create and configure image player
            m.imagePlayer = CreateObject("roImagePlayer")
            m.imagePlayer.SetDefaultMode(m.config.mode)
            m.imagePlayer.SetDefaultTransition(m.config.transition)
            m.imagePlayer.SetTransitionDuration(m.config.transitionDuration)

            ' Create timer
            m.timer = CreateObject("roTimer")
            m.timer.SetPort(m.msgPort)
            m.timer.SetElapsed(m.config.displayTime, 0)

            print "Slideshow initialized"
        End Sub,

        LoadConfig: Function() as Object
            config = {
                displayTime: 5,
                transition: 15,
                transitionDuration: 500,
                mode: 1,
                imageDirectory: "/images",
                shuffle: false
            }

            jsonContent = ReadAsciiFile("slideshow-config.json")
            if jsonContent <> "" then
                parsed = ParseJson(jsonContent)
                if parsed <> invalid then
                    for each key in parsed
                        config[key] = parsed[key]
                    end for
                end if
            end if

            return config
        End Function,

        LoadContent: Sub()
            ' Scan directory for images
            files = ListDir(m.config.imageDirectory)

            for each file in files
                ext = LCase(Right(file, 4))
                if ext = ".jpg" or ext = ".png" or ext = ".bmp" then
                    m.images.Push(m.config.imageDirectory + "/" + file)
                end if
            end for

            ' Sort or shuffle
            if m.config.shuffle then
                m.ShuffleArray(m.images)
            else
                m.images.Sort()
            end if

            print "Loaded "; m.images.Count(); " images"
        End Sub,

        ShuffleArray: Sub(arr as Object)
            n = arr.Count()
            for i = n - 1 to 1 step -1
                j = Rnd(i + 1) - 1
                temp = arr[i]
                arr[i] = arr[j]
                arr[j] = temp
            end for
        End Sub,

        StartSlideshow: Sub()
            ' Preload first image
            m.imagePlayer.PreloadFile(m.images[m.currentIndex])
            m.imagePlayer.DisplayPreload()

            ' Preload next
            nextIndex = (m.currentIndex + 1) mod m.images.Count()
            m.imagePlayer.PreloadFile(m.images[nextIndex])

            ' Start timer
            m.timer.Start()

            print "Slideshow started"
        End Sub,

        EventLoop: Sub()
            while true
                msg = wait(0, m.msgPort)

                if type(msg) = "roTimerEvent" then
                    m.AdvanceSlide()

                else if type(msg) = "roKeyboardPress" then
                    m.HandleKeyPress(msg.GetInt())
                end if
            end while
        End Sub,

        AdvanceSlide: Sub()
            ' Display preloaded image
            m.imagePlayer.DisplayPreload()

            ' Update index
            m.currentIndex = (m.currentIndex + 1) mod m.images.Count()

            ' Preload next image
            nextIndex = (m.currentIndex + 1) mod m.images.Count()
            m.imagePlayer.PreloadFile(m.images[nextIndex])

            ' Restart timer
            m.timer.Start()
        End Sub,

        HandleKeyPress: Sub(key as Integer)
            if key = 110 or key = 78 then  ' N - next
                m.timer.Stop()
                m.AdvanceSlide()

            else if key = 112 or key = 80 then  ' P - previous
                m.timer.Stop()
                m.currentIndex = m.currentIndex - 2
                if m.currentIndex < 0 then
                    m.currentIndex = m.images.Count() + m.currentIndex
                end if
                m.AdvanceSlide()

            else if key = 115 or key = 83 then  ' S - shuffle
                m.ShuffleArray(m.images)
                m.currentIndex = 0
                m.timer.Stop()
                m.StartSlideshow()
            end if
        End Sub
    }
End Function
```

---

## Memory Considerations

### Image Size Limits

| Player Series | Maximum Image Size |
|---------------|-------------------|
| Series 5 | Dynamic (based on available memory) |
| XT4/XD4 | 3840 x 2160 @ 32bpp |
| HD4/LS4 | 2048 x 1280 @ 32bpp |

### Best Practices

1. **Resize images** to match display resolution before deployment
2. **Use JPEG** for photographs (smaller file size)
3. **Use PNG** only when transparency is needed
4. **Preload images** to avoid loading delays
5. **Limit slideshow size** to available memory

---

## Troubleshooting

### Image Not Displaying

1. **Check file path**: Use correct path format
2. **Check format**: Ensure JPEG/PNG/BMP format
3. **Check file**: Verify file is not corrupted
4. **Check CMYK**: Convert CMYK JPEGs to RGB

### Transition Not Working

1. **Set transition before displaying**: Call `SetDefaultTransition()` first
2. **Check duration**: Ensure `SetTransitionDuration()` is called
3. **Preloading bypasses transitions**: `DisplayPreload()` may skip some effects

### Memory Issues

1. **Reduce image sizes**: Match to display resolution
2. **Limit concurrent images**: Don't preload too many
3. **Use JPEG over PNG**: Smaller decoded size

---

## Next Steps

- [Audio Playback and Control](07-audio-playback-control.md) - Add background music
- [Multi-Zone Layouts](08-multi-zone-layouts.md) - Combine images with other content
- [roImagePlayer Reference](https://docs.brightsign.biz/developers/roimageplayer) - Complete API documentation

---

[← Previous: Playing Video Content](05-playing-video-content.md) | [Next: Audio Playback and Control →](07-audio-playback-control.md)
