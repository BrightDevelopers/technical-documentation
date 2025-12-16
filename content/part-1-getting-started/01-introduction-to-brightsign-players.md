# Chapter 1: Introduction to BrightSign Players

[← Back to Part 1: Getting Started](README.md) | [↑ Main](../../README.md)

---

## Understanding BrightSign Hardware & Development

BrightSign manufactures purpose-built digital signage media players designed for commercial deployment. These Linux-based devices range from entry-level Full HD players to high-performance 8K-capable systems, offering developers a reliable platform for multimedia applications and interactive experiences. Founded in 2002 and headquartered in Los Gatos, California, BrightSign has deployed millions of players worldwide, making it one of the leading digital signage platform providers.

## What are BrightSign Players

BrightSign players are specialized embedded systems optimized for continuous operation in commercial environments. Unlike general-purpose computers or consumer media devices, BrightSign hardware emphasizes reliability, deterministic performance, and purpose-built media processing capabilities. The players run a custom Linux-based operating system (BrightSign OS) and support two primary development languages: BrightScript (a proprietary scripting language) and JavaScript/HTML5.

**Key Characteristics:**
- Commercial-grade components designed for 24/7 operation
- Fanless, solid-state design with no moving parts
- Hardware-accelerated video decoding up to 8K resolution
- Integrated Chromium engine (version 87-120 depending on OS version) for HTML5/JavaScript applications
- Network-managed deployment via BSN.cloud or third-party CMS
- Neural Processing Unit (NPU) support on premium models for AI/ML workloads

**Primary Use Cases:**
- Retail digital signage and promotional displays
- Corporate communication and wayfinding systems
- Quick-service restaurant (QSR) menu boards
- Trade show and event installations
- Transportation hubs and hospitality information systems
- Video walls and DVLED displays
- Interactive kiosks and touch-enabled experiences

## Player Models & Specifications

BrightSign organizes its product line into series. Series 5 (introduced 2020) represents the current mainstream generation, with Series 6 beginning rollout in 2025. Product names follow the pattern `[Family][Model Number]`, where the family code indicates the use case and the final digit indicates the series generation.

**Family Codes:**
| Code | Description |
|------|-------------|
| LS | Entry-level, essential signage |
| HD | Mainstream 4K |
| XD | Enhanced graphics/HTML5 |
| XT | Enterprise/premium |
| XC | High-output multi-display |

### Series 5 Models

**XC5 (Elite Multi-Output)**
- Models: XC2055 (dual HDMI), XC4055 (quad HDMI)
- 8K60p video decoding (H.265/VP9), dual 4K60p simultaneous
- Up to 10x graphics performance vs predecessors
- HDR10, HLG, and Rec.2020/BT.2020 support
- Ideal for DVLED and video wall applications
- Target use: Multi-display installations, large-format video walls

**XT5 (Premium Performance)**
- Models: XT245, XT1145, XT2145
- 8K60p single video or dual 4K60p decoding (10-bit)
- HDMI input for live broadcast integration
- Dual HDMI outputs, NPU support for AI workloads
- HDR10 and 4K video rotation
- PoE+ support, optional SSD storage
- Target use: High-end installations requiring maximum visual quality

**XD5 (Advanced Enterprise)**
- Models: XD235, XD1035
- 4K60p video with hardware-accelerated rotation
- Optimized 2D motion graphics at 60fps
- PoE+ support, thin form factor
- XD1035 adds serial interface and dual USB
- Target use: Professional signage requiring rich graphics and interactivity

**HD5 (Entry-Level 4K)**
- Models: HD225, HD1025
- 4K HDR video playback
- Expanded peripheral support
- External device controls
- Target use: Cost-effective 4K deployments

**LS5 (Essential Entry-Level)**
- Models: LS425 (1080p), LS445 (4K)
- LS425: Full HD 1080p60 decoding
- LS445: 4K60p 8-bit or 4K30p 10-bit decoding
- USB-C interactive peripherals
- Real-time clock with supercapacitor backup
- Target use: High-volume deployments with basic requirements

### Series 4 Models (Legacy)

Series 4 models remain supported but are being phased out:

**XT1144 (Legacy Premium)**
- 4K and Full HD video playback with Dolby Vision
- H.264 and H.265 decoding, HDR10 support
- End of production: March 1, 2025 (support until March 1, 2030)

**LS424 (Legacy Entry-Level)**
- Full HD 1080p60 video playback
- H.265 codec support
- Entry-level HTML5 rendering

### Warranty
All Series 5 and newer players purchased after January 1, 2025 include a **5-year standard warranty**.

## Operating System

BrightSign OS (BOS) is a customized Linux distribution built on the Yocto and OpenEmbedded projects. The architecture reflects a minimal-footprint philosophy: rather than starting with a full Linux distribution and removing components, BOS was constructed from a clean slate with only essential functionality.

**Current Versions:**
- **BOS 9.x**: Current release with Chromium 87 (default) or 120 (beta), Node.js 14.17.6 or 18.18.2
- **BOS 8.x**: Stable release with Chromium 69-87, Node.js 10.15.3-14.17.6
- Series 5 players support Chromium 110/120 upgrades for latest web standards

**Architecture Components:**
- Read-only root filesystem stored in flash memory
- Chromium rendering engine for HTML/JavaScript (version varies by OS)
- Custom audio/video processing pipeline with hardware acceleration
- Hardware abstraction layer for media decode and GPU operations
- dm-verity secure boot with signed firmware validation

**Design Philosophy:**
BOS is not a general-purpose operating system. It provides specialized capabilities for digital signage rather than attempting to function as a traditional Linux PC. This focused design enables:
- Deterministic boot times (typically under 15 seconds)
- Minimal attack surface with signed firmware and secure boot
- Optimized resource utilization for media playback
- Atomic over-the-air updates with rollback capability

## Development Environment Setup

BrightSign development requires both hardware and software components.

**Required Hardware:**
- BrightSign player with power supply
- MicroSD card (Class 10 or UHS-I recommended) or USB storage
- Development computer (Mac, Windows, or Linux)
- Display with HDMI input
- HDMI cable
- Network connection (Ethernet recommended for development)
- Optional: USB-to-serial adapter for console access

**Development Tools:**

**BrightSign Shell & BrightScript Debugger**
Command-line interface for BrightSign OS interaction via serial cable (115200 baud, 8N1) or telnet/SSH. The BrightScript debugger provides breakpoints, variable inspection, and step-through debugging.

**Diagnostic Web Server (DWS)**
Built-in web interface accessible at `http://<player-ip>` providing:
- Player settings configuration
- System diagnostic information and logs
- File management and upload
- Screenshot capture and performance metrics
- REST API for programmatic access

Available in both Local DWS (LDWS, on-network) and Remote DWS (RDWS, via BSN.cloud) variants.

> **Note:** As of recent firmware updates, the DWS is **disabled by default** due to EU Radio Equipment Directive (RED) compliance requirements. You must explicitly enable it by running a short BrightScript on the player:
> ```brightscript
> reg = CreateObject("roRegistrySection", "networking")
> reg.Write("dwse", "yes")
> reg.Flush()
> CreateObject("roNetworkConfiguration", 0).SetupDWS({port:"80", open:"none"})
> ```
> This enables the DWS on port 80 with authentication required. Detailed setup instructions are covered in later chapters.

**Node.js Environment**
Players ship with two Node.js instances:
- Embedded in Chromium (for HTML widget JavaScript)
- Standalone (for Node.js applications)

| OS Version | Node.js Version |
|------------|-----------------|
| BOS 9.1.x | 18.18.2 |
| BOS 8.5.x - 9.0.x | 14.17.6 |
| BOS 8.1.x - 8.3.x | 10.15.3 |

**Command-Line Interface**
The `@brightsign/bsc` CLI tool communicates with the Local DWS REST APIs:
```bash
npm install -g @brightsign/bsc
```
Provides file operations, registry management, screenshots, power control, and system diagnostics from your development machine.

**Development Resources:**
- GitHub: [brightsign/player-cli](https://github.com/brightsign/player-cli) - Alternative lightweight CLI
- GitHub: [brightsign/node.js-starter-project](https://github.com/brightsign/node.js-starter-project) - Node.js templates
- Official docs: [docs.brightsign.biz/developers](https://docs.brightsign.biz/developers)

## Content Types & Media Support

### Video Formats

**Supported Codecs by Series:**

| Series | 4K Codecs | 8K Codecs | Max Bitrate |
|--------|-----------|-----------|-------------|
| XC5, XT5 | H.265, H.264, VP9 | H.265, VP9 | Level 6.1 |
| XD5, HD5 | H.265, H.264 (30p max), VP9 | N/A | Level 5.1 |
| LS5 | H.265, H.264 (30p max) | N/A | Level 5.1 |
| Series 4 | H.265, H.264, VP9 | N/A | 50-95 Mbps |

**H.265 Profile Support:**
- Main Profile (8-bit color)
- Main 10 Profile (10-bit HDR)
- Version 1 profiles only (version 2 not supported)

**Container Formats:**
`.mp4`, `.mov`, `.mkv`, `.webm`, `.ts`, `.m2ts`, `.mpg`, `.mpeg`, `.avi`, `.vob`

**HDR Support:**
- XC5/XT5: HDR10, HLG, Rec.2020/BT.2020
- XTx44: HDR10 and Dolby Vision
- HD5/XD5: HDR10 (limited to 30fps)

### Audio Formats

**Recommended Codecs:**
- AAC: In H.264/H.265 video containers (CBR only)
- MP3: Stereo/mono at 44.1kHz or 48kHz
- WAV: PCM audio, stereo or mono
- Dolby Digital (AC3): 5.1 surround, decode or passthrough
- FLAC: Lossless audio (Series 5 and XTx44/XDx34)
- Opus: WebM containers (Series 5 and XTx44/XDx34)

### Image Formats

- JPEG, PNG, BMP, GIF for static graphics
- Hardware-accelerated image decode on all models
- Maximum image dimensions vary by model RAM

### HTML5 & JavaScript

The integrated Chromium engine enables:
- Modern JavaScript (ES6+ with ES2020 features on Chromium 87+)
- CSS3 animations, transforms, and responsive design
- Canvas 2D and WebGL for graphics
- Web APIs: localStorage, fetch, WebSocket, IndexedDB

**Chromium Versions:**
| OS Version | Chromium |
|------------|----------|
| BOS 9.1.x | 120 |
| BOS 8.5.x - 9.0.x | 87 (110/120 available as upgrade) |
| BOS 8.1.x - 8.4.x | 69 |

Performance scales with model tier—XC5/XT5 deliver up to 10x graphics performance over entry-level models.

## Networking & Connectivity

**Ethernet:**
- Standard 10/100/1000 Mbps on all models
- DHCP or static IP configuration
- PoE+ support on XT5 and XD5 models (eliminates separate power supply)

**Wi-Fi:**
- Optional module on most Series 5 models
- 802.11ac dual-band support
- Dual external antenna option for improved range
- Not recommended for high-bitrate video streaming

**Remote Management via BSN.cloud:**
Every BrightSign player includes free access to BSN.cloud, providing:
- Real-time player health monitoring and 24-hour reports
- Remote diagnostics, settings changes, and firmware updates
- Player reboot and command execution from anywhere
- Network grouping, tagging, and filtered reporting
- User/role management with granular permissions
- Integration with third-party CMS platforms

**Third-Party CMS Integration:**
BrightSign players work with numerous content management systems including Signagelive, Wallboard, signageOS, and many others that leverage the BSN.cloud APIs or Local DWS REST APIs.

## Storage & File Systems

**SD Cards:**
- Primary storage for content and scripts
- Class 10 or UHS-I recommended (minimum 4GB)
- FAT32 or exFAT file systems supported
- Cards up to 256GB tested and supported

**SSD Storage:**
- Optional SSD module for XC5, XT5, and XD5 models
- Requires BOS 9.0.15 or higher
- Recommended for high-volume content or caching

**USB Storage:**
- Content delivery via USB drives
- HID device support (keyboards, mice, touch controllers)
- USB-C on newer models for peripherals

**Internal Storage:**
- eMMC flash for operating system
- Persistent registry storage for settings
- Local storage APIs for HTML5 applications

**File Organization:**
Content is typically organized in a flat structure or simple directory hierarchy. The `autorun.brs` script in the root directory executes at boot and manages content playback.

## Hardware Interfaces

BrightSign players provide various hardware interfaces for external device integration:

**GPIO (General Purpose Input/Output):**
- 12-pin connector on HD/XT models
- 3.3V logic levels
- LED/switch control capability
- Current limit: 24mA per pin
- Power supply: 3.3V at 500mA (polyfuse protected)

**Serial Communication (UART):**
- 3.5mm jack connector
- RS-232 voltage levels on Series 4 XT/XD/HD
- TTL levels on GPIO alternate function
- Default: 115200 baud, 8N1 (8 data bits, no parity, 1 stop bit)
- Use case: External device control, sensor integration

**HDMI:**
- Primary video output with CEC for display control
- EDID parsing for automatic resolution configuration
- HDMI input on XT5 models for live video capture/passthrough
- Dual HDMI output on XT5/XC5 for multi-display setups

**USB:**
- Content delivery
- HID device input (keyboards, mice, touch controllers)
- Serial adapters and specialized peripherals

**Touchscreen Support:**
USB HID touchscreens work with compatible HTML5 applications for interactive experiences.

**I2C and SPI:**
Not available as dedicated interfaces on standard BrightSign models. GPIO and serial UART are the primary external communication mechanisms.

## Getting Started

BrightSign supports two primary development approaches:
- **BrightScript**: Proprietary scripting language with direct hardware access
- **JavaScript/HTML5**: Web-based development using the Chromium engine

### First Project: BrightScript Video Player

1. **Prepare SD Card:**
   Format as FAT32 (for cards ≤32GB) or exFAT (for larger cards).

2. **Create autorun.brs:**
   ```brightscript
   ' Simple looping video example
   videoPlayer = CreateObject("roVideoPlayer")
   videoPlayer.SetLoopMode(true)
   videoPlayer.PlayFile("video.mp4")

   ' Event loop (required to keep script running)
   msgPort = CreateObject("roMessagePort")
   videoPlayer.SetPort(msgPort)

   while true
       msg = wait(0, msgPort)
       if type(msg) = "roVideoEvent" then
           print "Video event: "; msg.GetInt()
       end if
   end while
   ```

3. **Deploy:** Copy `autorun.brs` and `video.mp4` to SD card root, insert into player, and power on.

### First Project: HTML5 Application

1. **Create autorun.brs** to launch an HTML widget:
   ```brightscript
   ' Launch HTML5 application
   rect = CreateObject("roRectangle", 0, 0, 1920, 1080)
   config = { url: "file:///sd:/index.html" }
   htmlWidget = CreateObject("roHtmlWidget", rect, config)

   msgPort = CreateObject("roMessagePort")
   htmlWidget.SetPort(msgPort)

   while true
       msg = wait(0, msgPort)
   end while
   ```

2. **Create index.html** with your web application.

3. **Deploy:** Copy all files to SD card and boot player.

### Development Workflow

1. **Write code** on development machine (BrightScript or HTML/JS)
2. **Deploy** via SD card, USB, or network (using `bsc` CLI or DWS)
3. **Test** on player, checking serial console or DWS logs for errors
4. **Iterate** using the DWS file upload for rapid testing
5. **Deploy to production** via BSN.cloud or CMS

### Deployment Strategies

| Strategy | Best For | Method |
|----------|----------|--------|
| Local | 1-10 players, demos | Manual SD card updates |
| Network | 10+ players, enterprise | BSN.cloud or third-party CMS |
| Hybrid | Initial setup + updates | SD card provisioning, network updates |

## Prerequisites

None - this chapter serves as the foundation for BrightSign development. Familiarity with general programming concepts is helpful but not required.

## Learning Outcomes

By completing this chapter, you should understand:
- BrightSign hardware ecosystem and model differentiation
- Player capabilities, limitations, and appropriate use cases
- BrightSign OS architecture and design philosophy
- Development environment setup and required tools
- Supported media formats and playback specifications
- Hardware interfaces for external device integration
- Basic project setup and deployment workflows

## Next Steps

Continue to [Chapter 2: BrightScript Language Reference](../chapter02-brightscript-language-reference/) to learn the BrightScript programming language, including syntax, built-in objects, and development patterns for BrightSign applications.


---

[↑ Part 1: Getting Started](README.md)
