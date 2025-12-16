# Chapter 10: Introduction to Native Extensions

[← Back to Part 4: Advanced Topics](README.md) | [↑ Main](../README.md)

---

Native extensions allow you to run custom compiled code alongside the BrightSign OS. Unlike BrightScript or JavaScript applications that run within BrightSign's presentation framework, native extensions are Linux executables that integrate directly with the operating system.

This chapter provides a simple "Hello World" introduction to get you started with native extension development.

---

## What Are Native Extensions?

Native extensions are custom applications compiled for BrightSign's ARM-based Linux platform. They:

- Run as system services alongside the BrightSign OS
- Start automatically when the player boots
- Have direct access to Linux system capabilities
- Are packaged as squashfs archives and installed to the player

**Common Use Cases:**
- Custom hardware drivers
- Background data processing services
- Integration with proprietary protocols
- System-level monitoring and logging

**Prerequisites:**
- Linux development host (x86 architecture)
- BrightSign player running OS 9.x or later
- Docker (recommended for SDK building)
- Serial connection capability for development

---

## Extension Architecture Overview

### How Extensions Work

Extensions are installed to `/var/volatile/bsext/${extension_name}` on the player. The system invokes a control script during boot and shutdown:

```
/var/volatile/bsext/my-extension/
├── bsext_init          # Control script (required)
├── my-app              # Your compiled application
└── lib/                # Any required libraries
```

The `bsext_init` script receives lifecycle commands:
- `start` - Called during player boot
- `stop` - Called during shutdown
- `restart` - Called to restart the extension
- `run` - Run in foreground (useful for testing)

### Extension Lifecycle

1. Player boots and mounts the extension squashfs
2. System calls `bsext_init start`
3. Your script starts your application as a daemon
4. On shutdown, system calls `bsext_init stop`
5. Your script cleanly terminates your application

---

## Hello World Extension

Let's create a minimal extension that logs "Hello from BrightSign!" to the system log.

### Step 1: The Application

Create a simple C program:

```c
/* hello.c - Minimal BrightSign extension */
#include <stdio.h>
#include <syslog.h>
#include <signal.h>
#include <unistd.h>

static volatile int running = 1;

void handle_signal(int sig) {
    running = 0;
}

int main(int argc, char *argv[]) {
    /* Set up signal handling for clean shutdown */
    signal(SIGTERM, handle_signal);
    signal(SIGINT, handle_signal);

    /* Open syslog connection */
    openlog("hello-ext", LOG_PID, LOG_USER);
    syslog(LOG_INFO, "Hello from BrightSign!");

    /* Keep running until signaled to stop */
    while (running) {
        sleep(60);
        syslog(LOG_INFO, "Extension still running...");
    }

    syslog(LOG_INFO, "Extension shutting down");
    closelog();
    return 0;
}
```

Key points:
- **Signal handling**: Extensions must handle SIGTERM for clean shutdown
- **Syslog**: Use syslog for logging (viewable via serial console or SSH)
- **Daemon behavior**: Run continuously until signaled to stop

### Step 2: The Control Script

Create `bsext_init`:

```bash
#!/bin/sh
# bsext_init - Extension control script

# Get the directory where this script is located
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
APP="${SCRIPT_DIR}/hello"
PIDFILE="/var/run/hello-ext.pid"

case "$1" in
    start)
        echo "Starting hello extension..."
        start-stop-daemon --start --background \
            --make-pidfile --pidfile "$PIDFILE" \
            --exec "$APP"
        ;;
    stop)
        echo "Stopping hello extension..."
        start-stop-daemon --stop --pidfile "$PIDFILE"
        rm -f "$PIDFILE"
        ;;
    restart)
        $0 stop
        sleep 1
        $0 start
        ;;
    run)
        # Run in foreground for testing
        exec "$APP"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|run}"
        exit 1
        ;;
esac

exit 0
```

Important notes:
- Use `start-stop-daemon` for proper daemon management
- The script must work from any filesystem location
- Use `$(dirname "$(readlink -f "$0")")` to find the script's directory

### Step 3: Build the Extension

For local testing on your development machine:

```bash
# Native build (for testing on your dev machine)
gcc -o hello hello.c
```

For the BrightSign player, you'll need to cross-compile using the BrightSign SDK (covered in the next chapter).

### Step 4: Package as Squashfs

```bash
# Create extension directory
mkdir -p hello-ext
cp hello hello-ext/
cp bsext_init hello-ext/
chmod +x hello-ext/bsext_init

# Create squashfs archive
mksquashfs hello-ext hello-ext.squashfs -noappend
```

### Step 5: Install on Player

Transfer the squashfs to your player and install:

```bash
# On the player (via SSH)
mkdir -p /var/volatile/bsext/hello-ext
mount -t squashfs /path/to/hello-ext.squashfs /var/volatile/bsext/hello-ext

# Start the extension
/var/volatile/bsext/hello-ext/bsext_init start

# Check it's running
ps aux | grep hello

# View logs
logread | grep hello-ext
```

---

## Development Setup

### Preparing Your Player

Before developing extensions, you need to "unsecure" your player for development access:

1. **Connect via serial console** - Connect a USB-to-serial adapter to the player's service port
2. **Enable SSH** - Use the Diagnostic Web Server or serial console to enable SSH access
3. **Verify access** - Confirm you can SSH to the player

> See the [BrightSign Extension Template](https://github.com/brightsign/extension-template) documentation for detailed setup instructions.

### Required Tools

On your Linux development host:

```bash
# Install squashfs tools
sudo apt install squashfs-tools

# Install Docker (recommended for SDK)
sudo apt install docker.io

# Verify tools
mksquashfs --version
docker --version
```

---

## Testing Your Extension

### Manual Testing

Test in foreground mode before running as a daemon:

```bash
# Run in foreground to see output directly
/var/volatile/bsext/hello-ext/bsext_init run
```

Press Ctrl+C to stop. This helps debug startup issues before backgrounding.

### Checking Logs

```bash
# View system log for extension messages
logread | grep hello

# Follow log in real-time
logread -f
```

### Disabling Extensions

If an extension causes boot problems, disable it via registry:

```bash
# Disable extension auto-start
# (prevents crash loops during development)
```

---

## Common Pitfalls

### Path Independence

Extensions can be mounted at different paths. Never hardcode paths:

```c
/* BAD - hardcoded path */
FILE *f = fopen("/var/volatile/bsext/hello-ext/config.txt", "r");

/* GOOD - use argv[0] or /proc/self/exe to find your location */
char exe_path[PATH_MAX];
readlink("/proc/self/exe", exe_path, sizeof(exe_path));
```

### Library Dependencies

The player's OS libraries may change between versions. Include your own libraries:

```bash
# Copy required libraries into your extension
mkdir -p hello-ext/lib
cp /path/to/libfoo.so hello-ext/lib/

# Set library path in your init script
export LD_LIBRARY_PATH="${SCRIPT_DIR}/lib:${LD_LIBRARY_PATH}"
```

### Signal Handling

Always handle SIGTERM for clean shutdown:

```c
signal(SIGTERM, handle_signal);
signal(SIGINT, handle_signal);  /* For manual testing */
```

---

## Next Steps

This chapter covered the basics of native extensions. The next chapter, **Advanced Native Extensions**, covers:

- Building the cross-compilation SDK
- Complex application development
- Packaging for production
- Signing extensions for secure players
- Debugging techniques

---

## Resources

- [BrightSign Extension Template](https://github.com/brightsign/extension-template) - Official workshop and examples
- [BrightSign Open Source](https://brightsign.biz/open-source/) - SDK source bundles


---

[↑ Part 4: Advanced Topics](README.md) | [Next →](02-advanced-extensions.md)
