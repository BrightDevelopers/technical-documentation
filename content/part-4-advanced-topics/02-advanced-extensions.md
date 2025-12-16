# Chapter 11: Advanced Native Extensions

[← Back to Part 4: Advanced Topics](README.md) | [↑ Main](../../README.md)

---

This chapter provides in-depth coverage of native extension development for BrightSign players. Building on the introduction from Chapter 10, we cover the complete development workflow from SDK setup through production deployment.

---

## Building the Cross-Compilation SDK

Native extensions must be compiled for BrightSign's ARM architecture. This requires building a cross-compilation SDK from BrightSign's open-source Yocto build system.

### Prerequisites

- Linux x86_64 development host (Ubuntu 20.04+ recommended)
- Docker installed and configured
- At least 100GB free disk space
- High-speed internet connection
- Several hours for initial SDK build

### Obtaining Source Bundles

Download the source bundles from BrightSign's Open Source Release page:

1. Visit [brightsign.biz/open-source/](https://brightsign.biz/open-source/)
2. Download the source bundle matching your target OS version
3. Extract to your development directory

```bash
mkdir -p ~/brightsign-sdk
cd ~/brightsign-sdk
tar xzf brightsign-os9-sources.tar.gz
```

### Building with Docker

The SDK build has many dependencies. Using Docker simplifies the process:

```bash
# Clone the extension template for Docker setup
git clone https://github.com/brightsign/extension-template.git
cd extension-template

# Build the Docker container
docker build -t brightsign-sdk .

# Run the container interactively
docker run -it -v ~/brightsign-sdk:/workspace brightsign-sdk
```

### SDK Generation

Inside the Docker container:

```bash
cd /workspace/brightsign-sources

# Initialize the build environment
source oe-init-build-env

# Build the SDK (this takes several hours)
bitbake meta-toolchain

# The SDK installer will be in tmp/deploy/sdk/
```

### Installing the SDK

```bash
# Run the SDK installer
./tmp/deploy/sdk/oecore-x86_64-cortexa72-toolchain-*.sh

# Accept the license and choose installation directory
# Default: /opt/brightsign-sdk

# Source the SDK environment (do this before each build session)
source /opt/brightsign-sdk/environment-setup-cortexa72-brightsign-linux
```

After sourcing, your shell has cross-compilation tools configured:
- `$CC` - C compiler for ARM
- `$CXX` - C++ compiler for ARM
- `$CFLAGS` - Compiler flags
- `$LDFLAGS` - Linker flags

---

## Application Development

### Project Structure

A well-organized extension project:

```
my-extension/
├── src/
│   ├── main.c
│   ├── config.c
│   └── config.h
├── sh/
│   └── bsext_init
├── lib/                    # Third-party libraries (source)
├── build/                  # Build output
├── CMakeLists.txt
├── Makefile
└── README.md
```

### Using CMake

CMakeLists.txt for cross-compilation:

```cmake
cmake_minimum_required(VERSION 3.10)
project(my-extension C)

set(CMAKE_C_STANDARD 11)

# Source files
set(SOURCES
    src/main.c
    src/config.c
)

# Create executable
add_executable(my-extension ${SOURCES})

# Link libraries
target_link_libraries(my-extension pthread)

# Installation
install(TARGETS my-extension DESTINATION bin)
```

Build commands:

```bash
# Source SDK environment first
source /opt/brightsign-sdk/environment-setup-cortexa72-brightsign-linux

# Configure with CMake
mkdir build && cd build
cmake ..

# Build
make

# The binary is ready for the player
file my-extension
# Output: my-extension: ELF 64-bit LSB executable, ARM aarch64...
```

### Native vs Cross Compilation

Develop and test on your host first, then cross-compile:

```bash
# Native build for local testing
mkdir build-native && cd build-native
CC=gcc cmake ..
make
./my-extension  # Test locally

# Cross build for player
source /opt/brightsign-sdk/environment-setup-cortexa72-brightsign-linux
mkdir build-arm && cd build-arm
cmake ..
make
# Deploy build-arm/my-extension to player
```

---

## Complete Example: Time Publisher

This example creates a UDP time broadcast service (based on the official extension template):

### main.c

```c
/*
 * time_publisher.c - Broadcasts current time via UDP
 *
 * This extension sends timestamps to port 5005, allowing
 * other devices on the network to synchronize or monitor.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <time.h>
#include <syslog.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define BROADCAST_PORT 5005
#define BROADCAST_ADDR "255.255.255.255"
#define INTERVAL_SEC 10

static volatile sig_atomic_t running = 1;

static void signal_handler(int sig) {
    syslog(LOG_INFO, "Received signal %d, shutting down", sig);
    running = 0;
}

static int setup_signals(void) {
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = signal_handler;
    sigemptyset(&sa.sa_mask);

    if (sigaction(SIGTERM, &sa, NULL) < 0) return -1;
    if (sigaction(SIGINT, &sa, NULL) < 0) return -1;

    return 0;
}

static int create_broadcast_socket(void) {
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock < 0) {
        syslog(LOG_ERR, "Failed to create socket");
        return -1;
    }

    int broadcast = 1;
    if (setsockopt(sock, SOL_SOCKET, SO_BROADCAST,
                   &broadcast, sizeof(broadcast)) < 0) {
        syslog(LOG_ERR, "Failed to set broadcast option");
        close(sock);
        return -1;
    }

    return sock;
}

static void broadcast_time(int sock) {
    struct sockaddr_in dest;
    memset(&dest, 0, sizeof(dest));
    dest.sin_family = AF_INET;
    dest.sin_port = htons(BROADCAST_PORT);
    inet_pton(AF_INET, BROADCAST_ADDR, &dest.sin_addr);

    time_t now = time(NULL);
    char *timestr = ctime(&now);
    timestr[strlen(timestr) - 1] = '\0';  /* Remove newline */

    char message[128];
    snprintf(message, sizeof(message), "BrightSign Time: %s", timestr);

    sendto(sock, message, strlen(message), 0,
           (struct sockaddr *)&dest, sizeof(dest));

    syslog(LOG_DEBUG, "Broadcast: %s", message);
}

int main(int argc, char *argv[]) {
    openlog("time-publisher", LOG_PID | LOG_NDELAY, LOG_DAEMON);
    syslog(LOG_INFO, "Time Publisher starting");

    if (setup_signals() < 0) {
        syslog(LOG_ERR, "Failed to setup signals");
        return 1;
    }

    int sock = create_broadcast_socket();
    if (sock < 0) {
        return 1;
    }

    syslog(LOG_INFO, "Broadcasting time every %d seconds on port %d",
           INTERVAL_SEC, BROADCAST_PORT);

    while (running) {
        broadcast_time(sock);

        /* Use a loop for sleep to check running flag more frequently */
        for (int i = 0; i < INTERVAL_SEC && running; i++) {
            sleep(1);
        }
    }

    close(sock);
    syslog(LOG_INFO, "Time Publisher stopped");
    closelog();

    return 0;
}
```

### bsext_init

```bash
#!/bin/sh
# Time Publisher Extension Control Script

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
APP="${SCRIPT_DIR}/time_publisher"
NAME="time-publisher"
PIDFILE="/var/run/${NAME}.pid"

# Add extension's lib directory to library path
export LD_LIBRARY_PATH="${SCRIPT_DIR}/lib:${LD_LIBRARY_PATH}"

start() {
    echo "Starting ${NAME}..."
    if [ -f "$PIDFILE" ]; then
        PID=$(cat "$PIDFILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo "${NAME} already running (PID: $PID)"
            return 1
        fi
        rm -f "$PIDFILE"
    fi

    start-stop-daemon --start --background \
        --make-pidfile --pidfile "$PIDFILE" \
        --exec "$APP"

    echo "${NAME} started"
}

stop() {
    echo "Stopping ${NAME}..."
    if [ ! -f "$PIDFILE" ]; then
        echo "${NAME} not running"
        return 0
    fi

    start-stop-daemon --stop --pidfile "$PIDFILE" --retry 10
    rm -f "$PIDFILE"
    echo "${NAME} stopped"
}

status() {
    if [ -f "$PIDFILE" ]; then
        PID=$(cat "$PIDFILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo "${NAME} running (PID: $PID)"
            return 0
        fi
    fi
    echo "${NAME} not running"
    return 1
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 1
        start
        ;;
    status)
        status
        ;;
    run)
        # Run in foreground for debugging
        echo "Running ${NAME} in foreground (Ctrl+C to stop)..."
        exec "$APP"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|run}"
        exit 1
        ;;
esac

exit $?
```

---

## Packaging for Deployment

### Creating the Extension Package

```bash
#!/bin/bash
# build-extension.sh

NAME="time-publisher"
VERSION="1.0.0"

# Create staging directory
rm -rf staging
mkdir -p staging/lib

# Copy application
cp build-arm/time_publisher staging/

# Copy init script
cp sh/bsext_init staging/
chmod +x staging/bsext_init

# Copy any required libraries
# cp /path/to/libfoo.so staging/lib/

# Create squashfs
mksquashfs staging "${NAME}-${VERSION}.squashfs" \
    -noappend \
    -comp xz \
    -b 256K

echo "Created ${NAME}-${VERSION}.squashfs"
ls -lh "${NAME}-${VERSION}.squashfs"
```

### Squashfs Options

```bash
# Production squashfs with compression
mksquashfs staging extension.squashfs \
    -noappend \          # Start fresh
    -comp xz \           # Best compression
    -b 256K \            # Block size
    -no-exports \        # Don't include export table
    -no-xattrs           # Don't include extended attributes

# Development squashfs (faster to create)
mksquashfs staging extension.squashfs \
    -noappend \
    -comp lzo            # Faster compression
```

---

## Installation and Management

### Manual Installation

```bash
# Transfer to player
scp extension.squashfs brightsign@192.168.1.100:/storage/sd/

# SSH to player
ssh brightsign@192.168.1.100

# Create mount point and install
mkdir -p /var/volatile/bsext/my-extension
mount -t squashfs /storage/sd/extension.squashfs /var/volatile/bsext/my-extension

# Start the extension
/var/volatile/bsext/my-extension/bsext_init start
```

### Automated Installation Script

```bash
#!/bin/sh
# install-extension.sh - Run on player

EXTENSION_NAME="$1"
SQUASHFS_PATH="$2"

if [ -z "$EXTENSION_NAME" ] || [ -z "$SQUASHFS_PATH" ]; then
    echo "Usage: $0 <extension-name> <squashfs-path>"
    exit 1
fi

MOUNT_POINT="/var/volatile/bsext/${EXTENSION_NAME}"
INIT_SCRIPT="${MOUNT_POINT}/bsext_init"

# Stop existing extension if running
if [ -x "$INIT_SCRIPT" ]; then
    "$INIT_SCRIPT" stop 2>/dev/null
fi

# Unmount if already mounted
umount "$MOUNT_POINT" 2>/dev/null

# Create mount point
mkdir -p "$MOUNT_POINT"

# Mount new squashfs
mount -t squashfs "$SQUASHFS_PATH" "$MOUNT_POINT"

# Start extension
"$INIT_SCRIPT" start

echo "Extension ${EXTENSION_NAME} installed and started"
```

### Removal

```bash
# Stop the extension
/var/volatile/bsext/my-extension/bsext_init stop

# Unmount
umount /var/volatile/bsext/my-extension

# Remove mount point
rmdir /var/volatile/bsext/my-extension

# Remove squashfs file
rm /storage/sd/extension.squashfs
```

---

## Production Signing

For deployment on secure (production) players, extensions must be cryptographically signed.

### The Signing Process

1. **Complete development and testing** on unsecured players
2. **Package your extension** as a squashfs archive
3. **Submit to BrightSign** or an authorized partner for signing
4. **Receive a signed .bsfw file** for deployment

### Signed Extension Format

Signed extensions are distributed as `.bsfw` files (BrightSign FirmWare format). These can be:

- Installed via BSN.cloud
- Deployed with presentation packages
- Installed via USB during setup

### Security Considerations

- Signed extensions cannot be modified after signing
- Test thoroughly before submitting for signing
- Version your extensions for update management
- Keep your source code and build environment reproducible

---

## Debugging Techniques

### Serial Console Debugging

Connect via serial for real-time debugging:

```bash
# On your development host
screen /dev/ttyUSB0 115200

# Or use minicom
minicom -D /dev/ttyUSB0 -b 115200
```

### Syslog Integration

Use appropriate log levels:

```c
#include <syslog.h>

openlog("my-ext", LOG_PID | LOG_NDELAY, LOG_DAEMON);

syslog(LOG_ERR, "Error: %s", error_message);
syslog(LOG_WARNING, "Warning: unusual condition");
syslog(LOG_INFO, "Extension started");
syslog(LOG_DEBUG, "Processing item %d", item_id);
```

View logs on the player:

```bash
# View all logs
logread

# Follow logs in real-time
logread -f

# Filter for your extension
logread | grep my-ext
```

### GDB Remote Debugging

For complex debugging, use GDB server:

```bash
# On the player
gdbserver :2345 /var/volatile/bsext/my-ext/my-app

# On your development host (with SDK)
source /opt/brightsign-sdk/environment-setup-*
$GDB build-arm/my-app
(gdb) target remote 192.168.1.100:2345
(gdb) continue
```

### Core Dumps

Enable core dumps for crash analysis:

```bash
# On the player
ulimit -c unlimited
echo "/tmp/core.%e.%p" > /proc/sys/kernel/core_pattern

# After a crash, analyze with GDB
$GDB build-arm/my-app /tmp/core.my-app.1234
```

---

## Best Practices

### Resource Management

```c
/* Always clean up resources */
void cleanup(void) {
    if (socket_fd >= 0) close(socket_fd);
    if (file_handle) fclose(file_handle);
    closelog();
}

/* Register cleanup for signals and exit */
atexit(cleanup);
```

### Configuration Files

Store configuration in a predictable location:

```c
/* Find config relative to executable */
char config_path[PATH_MAX];
char exe_dir[PATH_MAX];

readlink("/proc/self/exe", exe_dir, sizeof(exe_dir));
dirname(exe_dir);
snprintf(config_path, sizeof(config_path), "%s/config.json", exe_dir);
```

### Library Management

Include all dependencies:

```bash
# Find required libraries
ldd build-arm/my-app

# Copy needed libraries
cp /path/to/lib*.so staging/lib/

# In bsext_init, set library path
export LD_LIBRARY_PATH="${SCRIPT_DIR}/lib:${LD_LIBRARY_PATH}"
```

### Watchdog Integration

For critical extensions, implement watchdog support:

```c
#include <sys/ioctl.h>
#include <linux/watchdog.h>

int watchdog_fd = open("/dev/watchdog", O_WRONLY);

/* Pet the watchdog regularly in your main loop */
while (running) {
    ioctl(watchdog_fd, WDIOC_KEEPALIVE, 0);
    /* Do work... */
    sleep(1);
}
```

---

## Troubleshooting

### Extension Won't Start

1. Check permissions: `ls -la /var/volatile/bsext/my-ext/`
2. Verify init script is executable: `chmod +x bsext_init`
3. Run in foreground: `./bsext_init run`
4. Check logs: `logread | grep my-ext`

### Library Not Found

```bash
# Check what libraries are missing
LD_LIBRARY_PATH=/var/volatile/bsext/my-ext/lib ldd /var/volatile/bsext/my-ext/my-app

# Verify library path in init script
export LD_LIBRARY_PATH="${SCRIPT_DIR}/lib:${LD_LIBRARY_PATH}"
```

### Crashes at Startup

1. Enable core dumps
2. Check for missing dependencies
3. Verify cross-compilation target matches player architecture
4. Test with minimal code first

### Boot Loop Prevention

During development, extensions that crash can cause boot loops. Use registry to disable:

```bash
# Disable extension auto-start via registry
# (Check BrightSign documentation for specific keys)
```

---

## Resources

- [BrightSign Extension Template](https://github.com/brightsign/extension-template) - Official workshop repository
- [BrightSign Open Source](https://brightsign.biz/open-source/) - Source bundles and SDK materials
- [Yocto Project Documentation](https://docs.yoctoproject.org/) - Build system reference
- [Squashfs Tools](https://github.com/plougher/squashfs-tools) - Packaging utilities


---

[← Previous](01-intro-to-extensions.md) | [↑ Part 4: Advanced Topics](README.md) | [Next →](03-writing-software-for-the-npu.md)
