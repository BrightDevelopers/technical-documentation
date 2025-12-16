# BrightScript Language Reference Manual 

[← Back to Part 2: BrightScript Development](README.md) | [↑ Main](../../README.md)

---

	 
## Table of Contents
1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Language Fundamentals](#language-fundamentals)
4. [Variables and Types](#variables-and-types)
5. [Control Flow](#control-flow)
6. [Functions and Scope](#functions-and-scope)
7. [Objects and Interfaces](#objects-and-interfaces)
8. [Arrays and Collections](#arrays-and-collections)
9. [Libraries](#libraries)
10. [String Operations](#string-operations)
11. [File Operations](#file-operations)
12. [Networking](#networking)
13. [Media Playback](#media-playback)
14. [Event Handling](#event-handling)
15. [XML Processing](#xml-processing)
16. [Best Practices](#best-practices)
17. [Common Patterns](#common-patterns)
18. [Debugging](#debugging)

---

## Introduction

BrightScript is a powerful scripting language designed for building media and networked applications on BrightSign digital signage players. BrightSign spun out of Roku in 2009.Note that the BrightSign implementation has diverged significantly from the Roku implementation. It combines simplicity with robust functionality for programming media player features.

### Key Characteristics
- **Not case sensitive** - `Print`, `PRINT`, and `print` are all equivalent
- **Dynamic typing** with optional type declarations
- **Object-oriented** with interfaces and components
- **Event-driven** architecture
- **Garbage collected** with reference counting
- **Single-threaded** with asynchronous operations

### Quick Example

This simple program demonstrates the basic structure of a BrightScript application, showing variable declarations with type suffixes, object creation, and string concatenation:

```brightscript
Sub Main()
    print "Hello, BrightScript!"

    ' Create a message port for events
    msgPort = CreateObject("roMessagePort")

    ' Simple variable usage
    name$ = "BrightSign"
    count% = 42
    pi! = 3.14159

    print "Device: " + name$ + " Count: " + str(count%)
End Sub
```

> **See also:** [01-hello-world.brs](examples/01-hello-world.brs) for the complete working example.

---

## Getting Started

### Program Structure

This example shows the basic program structure with a main entry point and a supporting function, demonstrating how BrightScript applications are organized:

> **See also:** [01-hello-world.brs](examples/01-hello-world.brs) and [07-basic-program-structure.brs](examples/07-basic-program-structure.brs) for complete working examples.

```brightscript
Sub Main()
    ' Your code here
    print "Starting application..."
    RunApplication()
End Sub

Function RunApplication() As Void
    ' Application logic
    device$ = "BrightSign"
    print "Running on: " + device$
End Function
```

### Comments

BrightScript supports two styles of comments - single quote and REM statements, with multi-line comments achieved through multiple single-line comments:

```brightscript
' This is a single-line comment
REM This is also a comment

' Multi-line comments use multiple single-line comments
' Line 1 of comment
' Line 2 of comment
```

---

## Language Fundamentals

### Reserved Words

The following words are reserved and cannot be used as identifiers:

```
and, as, boolean, box, createobject, dim, double, dynamic, each, else,
elseif, end, endfunction, endif, endfor, endsub, endwhile, eval, exit,
false, float, for, function, getglobalaa, getlastruncompileerror,
getlastrunruntimeerror, goto, if, in, integer, interface, invalid, let,
library, line_num, m, mod, next, not, object, or, pos, print, rem,
return, rnd, run, step, stop, string, sub, tab, then, to, true, type,
void, while
```

### Case Sensitivity

**BrightScript is case-insensitive for keywords and identifiers**, but **case-sensitive for string comparisons**. This example demonstrates the difference between keyword/variable case insensitivity and string content case sensitivity:

> **See also:** [05-case-sensitivity.brs](examples/05-case-sensitivity.brs) for a complete working example.

```brightscript
' These are all equivalent - keywords are case insensitive
Sub Main()
SUB main()
sub MAIN()

' Variable names are also case insensitive
userName$ = "John"
USERNAME$ = "Jane"  ' Same variable as userName$
print userName$     ' Outputs: Jane

' But string content IS case sensitive
if userName$ = "john" then      ' FALSE - case sensitive comparison
    print "Match!"
end if

if LCase(userName$) = "jane" then   ' TRUE - after converting to lowercase
    print "Match!"
end if
End Sub
```

### LIBRARY Statement

This example shows how to include external BrightScript files at the beginning of your script, making their functions available in your program:

```brightscript
Library "core/setupCore.brs"
Library "common/helpers.brs"

Sub Main()
    ' Can now use functions from included libraries
    SetupDevice()
End Sub
```

### Production Pattern: Multiple Library Includes

This real-world example shows how production BrightScript applications typically structure their library includes and initialization, including version tracking, debug configuration, and centralized diagnostics:

```brightscript
Library "setupCommon.brs"
Library "setupNetworkDiagnostics.brs"

Sub Main()
    ' Production pattern: version tracking
    version = "8.0.0.1"

    ' Production pattern: debug flag initialization
    debugParams = EnableDebugging("current-sync.json")
    sysFlags = {}
    sysFlags.debugOn = debugParams.serialDebugOn
    sysFlags.systemLogDebugOn = debugParams.systemLogDebugOn

    ' Production pattern: centralized diagnostics
    diagnostics = newDiagnostics(sysFlags)
    diagnostics.printDebug("setup.brs version " + version + " started")
End Sub
```

---

## Variables and Types

### Type System

This example demonstrates BrightScript's flexible type system, showing how variables can be dynamically typed or explicitly declared with type suffixes:

```brightscript
' Dynamic typing
a = 5           ' Integer
a = "hello"     ' Now a String
a = 3.14        ' Now a Float

' Type declarations
name$ = "John"          ' String ($ suffix)
count% = 100           ' Integer (% suffix)
price! = 19.99         ' Float (! suffix)
value# = 1.234567890   ' Double (# suffix)
```

### Basic Types

| Type | Description | Example | Declaration Suffix |
|------|-------------|---------|-------------------|
| Boolean | True or False | `isReady = true` | N/A |
| Integer | 32-bit signed integer | `networkPriority% = 0` | % |
| Float | Single precision | `radius! = 5.0` | ! |
| Double | Double precision | `pi# = 3.141592653589` | # |
| String | ASCII characters | `deviceID$ = "AB123456"` | $ |
| Object | Reference to object | `msgPort = CreateObject("roMessagePort")` | N/A |
| Invalid | Null/undefined value | `result = invalid` | N/A |

### Variable Examples

This comprehensive example showcases production-tested variable patterns, including type suffixes, device information retrieval, boolean configuration, and critical object validation that prevents device crashes:

> **See also:** [02-variable-examples.brs](examples/02-variable-examples.brs) for a complete working example.

```brightscript
Sub VariableExamples()
    ' Production-tested integer patterns
    setupVersion$ = "8.0.0.1"
    networkPriority% = 0
    timeBetweenNetConnects% = 60
    deviceFWVersionNumber% = 524407

    ' String operations with type suffixes from production
    deviceUniqueID$ = modelObject.GetDeviceUniqueId()
    timeServer$ = "ntp://time.brightsignnetwork.com"
    staticIPAddress$ = "192.168.1.100"
    hostName$ = "brightsign-player"

    ' Boolean validation patterns used in production
    modelSupportsWifi = false
    useWireless = setupParams.useWireless
    enableDiagnostics = GetBoolFromNumericString(setup_sync.LookupMetadata("client", "diagnosticLoggingEnabled"))
    performLegacySetup = true

    ' Production object validation pattern
    registrySection = CreateObject("roRegistrySection", "networking")
    if type(registrySection) <> "roRegistrySection" then
        print "Error: Unable to create roRegistrySection"
        stop
    end if

    ' Invalid handling pattern from production code
    nc = CreateObject("roNetworkConfiguration", 1)
    if nc = invalid then
        print "Unable to create roNetworkConfiguration - index = 1"
        return
    end if
End Sub
```

---

## Control Flow

### IF/THEN/ELSE Statements

#### Single-line IF

These production patterns show concise single-line conditional statements used for error handling and configuration writes:

```brightscript
if not ok then stop

if setupParams.inheritNetworkProperties then registrySection.Write("inp", "yes")

' Multiple statements with colons - production pattern
if type(registrySection) <> "roRegistrySection" then print "Error: Unable to create roRegistrySection" : stop
```

#### Multi-line IF Block

This production example demonstrates critical validation patterns: object creation checking, device family detection for firmware compatibility, and network configuration logic:

```brightscript
Sub ProductionValidationPattern()
    ' Pattern 1: Object validation with early termination
    if type(registrySection) <> "roRegistrySection" then
        print "Error: Unable to create roRegistrySection"
        stop
    end if

    ' Pattern 2: Device family detection
    if modelObject.GetFamily() = "pantera" then
        minVersionNumber% = 524407
        minVersion$ = "8.0.119"
    else if modelObject.GetFamily() = "pagani" then
        minVersionNumber% = 524407
        minVersion$ = "8.0.119"
    else
        minVersionNumber% = 524407
        minVersion$ = "8.0.119"
    end if

    ' Pattern 3: Network configuration logic
    if setupParams.useWireless and modelSupportsWifi then
        registrySection.Write("wifi", "yes")
        registrySection.Write("ss", setupParams.ssid$)
        return true
    else
        registrySection.Write("wifi", "no")
        return false
    end if
End Sub
```

### FOR Loops

#### Standard FOR Loop

These production examples show real-world FOR loop usage: configuring DNS servers in the registry, providing visual error feedback through GPIO LED flashing, and early loop exit:

```brightscript
' Production pattern: iterating through DNS servers
for i = 1 to 3
    currentDns = dnsServers[i-1]
    if IsString(currentDns) then
        registrySection.Write("d"+StripLeadingSpaces(stri(i))+registrySuffix$, currentDns)
    else
        registrySection.Write("d"+StripLeadingSpaces(stri(i))+registrySuffix$, "")
    end if
next

' Production pattern: LED flashing for error indication
for flash_index = 0 to 9
    sw.SetWholeState(2 ^ 1 + 2 ^ 2 + 2 ^ 3 + 2 ^ 4 + 2 ^ 5 + 2 ^ 6 + 2 ^ 7 + 2 ^ 8 + 2 ^ 9 + 2 ^ 10)
    sleep(500)
    sw.SetWholeState(0)
    sleep(500)
next

' Exit early
for i = 1 to 100
    if i > 50 then exit for
    print i
end for
```

#### FOR EACH Loop

These production examples demonstrate real-world FOR EACH usage patterns: iterating through storage devices for auto-detection, processing log files with proper file naming, iterating through network configuration hosts, and file type filtering during directory scanning:

```brightscript
' Production pattern: iterate over storage devices
devices = ["USB1:/","SD:/","SD2:/","SSD:/"]
for each device in devices
    if DeviceIsMounted(device) then
        return device
    endif
next

' Production pattern: iterate over log files
listOfLogFiles = MatchFiles("/" + m.uploadLogFolder, "*.log")
for each file in listOfLogFiles
    fullFilePath = m.uploadLogFolder + "/" + file
    contentDisposition$ = GetContentDisposition(file)
    m.AddUploadHeaders(m.uploadLogFileURLXfer, contentDisposition$)
    return
next

' Production pattern: iterate over network hosts
for each networkHost in setupParams.networkHosts
    ParseProxyBypass(bypassProxyHosts, networkHost)
next

' Production pattern: Processing directory contents with file filtering
files = ListDir("/")
for each file in files
    if IsVideoFile(file) then
        print "Found video: " + file
    end if
end for
```

### WHILE Loops

These examples show essential WHILE loop patterns: basic counting loops with termination conditions, infinite event loops with conditional exits for button handling, and retry loops with attempt limiting for robust error handling:

```brightscript
' Basic while loop
counter = 0
while counter < 10
    print counter
    counter = counter + 1
end while

' Infinite loop with exit
while true
    msg = wait(1000, msgPort)  ' Wait 1 second

    if type(msg) = "roGpioButton" then
        if msg.GetInt() = 12 then
            exit while  ' Exit on button 12
        end if
    end if
end while

' Conditional processing
done = false
attempts = 0
while not done and attempts < 3
    done = TryConnection()
    attempts = attempts + 1
end while
```

### GOTO and Labels

This example demonstrates the GOTO statement for loop control, showing label definition syntax and conditional branching that mimics traditional BASIC programming patterns (though modern BrightScript development typically favors structured loops):

> **See also:** [06-goto-labels.brs](examples/06-goto-labels.brs) for a complete working example.

```brightscript
Sub ProcessWithGoto()
    count = 0

    start_label:
    count = count + 1
    print "Count: "; count

    if count < 5 then
        goto start_label
    end if

    print "Done!"
End Sub
```

---

## Functions and Scope

### Function Declaration

These production function examples demonstrate real-world BrightScript function patterns: WiFi capability detection using network configuration objects, data conversion utilities for boolean and string handling, device validation using storage objects, and proper resource cleanup with invalid assignment:

> **See also:** [03-function-examples.brs](examples/03-function-examples.brs) for a complete working example.

```brightscript
' Production naming pattern: Pascal case with descriptive names
Function GetModelSupportsWifi() As Boolean
    modelSupportsWifi = false
    nc = CreateObject("roNetworkConfiguration", 1)
    if type(nc) = "roNetworkConfiguration" then
        currentConfig = nc.GetCurrentConfig()
        if type(currentConfig) = "roAssociativeArray" then
            modelSupportsWifi = true
        end if
    end if
    nc = invalid
    return modelSupportsWifi
End Function

' Production pattern: Boolean conversion functions
Function GetBoolFromNumericString(value$ As String) As Boolean
    if value$ = "1" then return true
    return false
End Function

' Production pattern: String conversion functions
Function GetYesNoFromBoolean(value As Boolean) As String
    if value then return "yes"
    return "no"
End Function

Function GetNumericStringFromNumber(value% As Integer) As String
    return stri(value%)
End Function

' Production pattern: Device validation function
Function DeviceIsMounted(deviceName$ As String) As Boolean
    du = CreateObject("roStorageInfo", deviceName$)
    if type(du) = "roStorageInfo" then
        return true
    endif
    return false
End Function
```

### Anonymous Functions

These examples showcase BrightScript's anonymous function capabilities: assigning functions to variables for dynamic execution, creating function collections within associative arrays for organized code structure, and implementing object methods that can be called directly:

```brightscript
' Assign function to variable
myFunc = Function(x As Integer, y As Integer) As Integer
    return x * y
End Function

result = myFunc(5, 3)  ' result = 15

' Functions in associative arrays
math = {
    add: Function(a, b)
        return a + b
    End Function,

    multiply: Function(a, b)
        return a * b
    End Function
}

print math.add(5, 3)       ' Output: 8
print math.multiply(5, 3)  ' Output: 15
```

### Production Object Factory Pattern

Real production code uses factory functions with specific naming conventions:

> **See also:** [09-object-factory-pattern.brs](examples/09-object-factory-pattern.brs) and [11-networking-object-factory.brs](examples/11-networking-object-factory.brs) for complete working examples.

```brightscript
' Production pattern: "new" prefix for factory functions
Function newDiagnostics(sysFlags As Object) As Object
    return {
        debugOn: sysFlags.debugOn,
        systemLogDebugOn: sysFlags.systemLogDebugOn,

        printDebug: Function(message As String) As Void
            if m.debugOn then
                print "[DEBUG] " + message
            end if

            if m.systemLogDebugOn then
                systemLog = CreateObject("roSystemLog")
                systemLog.SendLine("[DEBUG] " + message)
            end if
        End Function,

        SetSystemInfo: Function(sysInfo As Object, diagnosticCodes As Object) As Void
            ' Store system information for diagnostics
            m.sysInfo = sysInfo
            m.diagnosticCodes = diagnosticCodes
        End Function
    }
End Function

' Production pattern: Object composition and method assignment
Function newNetworking(Setup As Object) As Object
    networking = CreateObject("roAssociativeArray")

    ' Reference other objects from setup
    networking.systemTime = m.systemTime
    networking.diagnostics = m.diagnostics
    networking.msgPort = m.msgPort

    ' Production pattern: Assign function references to object methods
    networking.InitializeNetworkDownloads = InitializeNetworkDownloads
    networking.StartSync = StartSync
    networking.URLEvent = URLEvent
    networking.PoolEvent = PoolEvent

    ' Constants defined as object properties
    networking.POOL_EVENT_FILE_DOWNLOADED = 1
    networking.POOL_EVENT_FILE_FAILED = -1
    networking.URL_EVENT_COMPLETE = 1

    return networking
End Function

' Production usage pattern
Sub ProductionMain()
    ' Factory functions create configured objects
    Setup = newSetup(diagnostics)
    Setup.networking = Setup.newNetworking(Setup)
    Setup.logging = Setup.newLogging()

    ' Cross-reference objects
    Setup.logging.networking = Setup.networking

    ' Initialize with system info
    Setup.SetSystemInfo(sysInfo, diagnosticCodes)

    ' Start main event loop
    Setup.EventLoop()
End Sub
```

### The "m" Scope - Object Self-Reference

**The `m` variable is BrightScript's "self" reference** - it provides access to the current object's properties and methods. In production code, `m` is extensively used for object state management, cross-referencing between objects, and method implementations.

> **See also:** [08-m-scope-device-manager.brs](examples/08-m-scope-device-manager.brs) and [10-application-manager-cross-references.brs](examples/10-application-manager-cross-references.brs) for complete working examples.

#### Basic "m" Usage - Object Self-Reference

```brightscript
' Production pattern: Object with state and methods
Function CreateDeviceManager() As Object
    return {
        deviceUniqueID$: "",
        isConfigured: false,
        lastSyncTime$: "",

        ' Method that uses "m" to access object properties
        configure: Function(setupParams As Object) As Boolean
            m.deviceUniqueID$ = setupParams.deviceID$
            m.isConfigured = true
            m.lastSyncTime$ = CreateObject("roDateTime").ToIsoString()

            print "Device " + m.deviceUniqueID$ + " configured at " + m.lastSyncTime$
            return m.isConfigured
        End Function,

        ' Method that reads object state via "m"
        getStatus: Function() As String
            if m.isConfigured then
                return "Device " + m.deviceUniqueID$ + " ready (last sync: " + m.lastSyncTime$ + ")"
            else
                return "Device not configured"
            end if
        End Function
    }
End Function

' Usage
device = CreateDeviceManager()
device.configure({ deviceID$: "BS-12345" })
print device.getStatus()  ' Output: Device BS-12345 ready (last sync: 2024-01-15T10:30:00Z)
```

#### Production Pattern: Object Cross-References with "m"

Based on production code examples, objects commonly reference each other through `m`:

```brightscript
' Production pattern: Master object that contains sub-objects
Function newApplicationManager() As Object
    manager = CreateObject("roAssociativeArray")

    ' Core properties accessible via "m" in methods
    manager.msgPort = CreateObject("roMessagePort")
    manager.isRunning = false
    manager.diagnostics = invalid
    manager.networking = invalid
    manager.logging = invalid

    ' Method that creates and cross-references sub-objects
    manager.initialize = Function(debugEnabled As Boolean) As Void
        ' Create diagnostics object and store reference via "m"
        m.diagnostics = {
            debugEnabled: debugEnabled,

            printDebug: Function(message As String) As Void
                if m.debugEnabled then
                    print "[DEBUG] " + message
                end if
            End Function
        }

        ' Create networking object that references parent via "m"
        m.networking = {
            parentManager: m,  ' Reference to parent object
            downloadActive: false,

            startDownload: Function(url As String) As Void
                m.downloadActive = true
                ' Access parent's diagnostics via cross-reference
                m.parentManager.diagnostics.printDebug("Starting download: " + url)
            End Function,

            finishDownload: Function() As Void
                m.downloadActive = false
                m.parentManager.diagnostics.printDebug("Download completed")
            End Function
        }

        ' Create logging object with references to both parent and networking
        m.logging = {
            parentManager: m,

            logNetworkEvent: Function(eventType As String) As Void
                status$ = "unknown"
                if m.parentManager.networking.downloadActive then
                    status$ = "active"
                else
                    status$ = "idle"
                end if

                logEntry$ = eventType + " - Network status: " + status$
                m.parentManager.diagnostics.printDebug(logEntry$)
            End Function
        }

        m.isRunning = true
        m.diagnostics.printDebug("Application manager initialized")
    End Function

    return manager
End Function

' Real usage pattern from production code
Sub Main()
    ' Create main application manager
    appManager = newApplicationManager()
    appManager.initialize(true)

    ' Objects can access each other through "m" references
    appManager.networking.startDownload("http://content.server.com/file.mp4")
    appManager.logging.logNetworkEvent("DOWNLOAD_START")
    appManager.networking.finishDownload()
    appManager.logging.logNetworkEvent("DOWNLOAD_COMPLETE")
End Sub
```

#### Production Pattern: "m" in Object Factories

Production code uses `m` extensively in factory functions that create configured objects:

```brightscript
' Production pattern: Factory function using "m" for setup context
Function newNetworkingObject(parentSetup As Object) As Object
    networking = CreateObject("roAssociativeArray")

    ' Store references to parent context via direct assignment
    networking.systemTime = parentSetup.systemTime
    networking.diagnostics = parentSetup.diagnostics
    networking.msgPort = parentSetup.msgPort

    ' Properties that will be accessed via "m" in methods
    networking.downloadQueue = []
    networking.retryCount% = 0
    networking.maxRetries% = 10

    ' Method that uses "m" to access object state and parent references
    networking.processDownload = Function(fileUrl$ As String) As Boolean
        m.diagnostics.printDebug("Processing download: " + fileUrl$)

        ' Use "m" to access object properties
        m.downloadQueue.Push(fileUrl$)
        m.retryCount% = 0

        ' Create URL transfer object
        xfer = CreateObject("roUrlTransfer")
        xfer.SetPort(m.msgPort)  ' Use parent's message port via "m"
        xfer.SetUrl(fileUrl$)

        ' Attempt download with retry logic
        while m.retryCount% < m.maxRetries%
            responseCode% = xfer.GetToFile("temp_download.dat")

            if responseCode% = 200 then
                m.diagnostics.printDebug("Download successful after " + m.retryCount%.toStr() + " retries")
                return true
            else
                m.retryCount% = m.retryCount% + 1
                m.diagnostics.printDebug("Download failed, retry " + m.retryCount%.toStr() + "/" + m.maxRetries%.toStr())
            end if
        end while

        m.diagnostics.printDebug("Download failed after " + m.maxRetries%.toStr() + " attempts")
        return false
    End Function

    ' Method that uses "m" for state management
    networking.getDownloadStatus = Function() As Object
        return {
            queueSize: m.downloadQueue.Count(),
            currentRetry: m.retryCount%,
            maxRetries: m.maxRetries%
        }
    End Function

    return networking
End Function
```

#### Critical Production Pattern: "m" Scope Validation

Production code often validates object state through `m`:

```brightscript
' Production pattern: Object with validation methods using "m"
Function newRegistryManager(sectionName$ As String) As Object
    manager = {
        sectionName$: sectionName$,
        registrySection: CreateObject("roRegistrySection", sectionName$),
        isValid: false,

        ' Validation method using "m" to check object state
        validate: Function() As Boolean
            if type(m.registrySection) = "roRegistrySection" then
                m.isValid = true
                print "Registry section '" + m.sectionName$ + "' created successfully"
                return true
            else
                m.isValid = false
                print "Error: Unable to create registry section '" + m.sectionName$ + "'"
                return false
            end if
        End Function,

        ' Safe write method that validates via "m" before operation
        writeValue: Function(key$ As String, value$ As String) As Boolean
            if not m.isValid then
                print "Registry section '" + m.sectionName$ + "' is invalid - cannot write"
                return false
            end if

            m.registrySection.Write(key$, value$)
            m.registrySection.Flush()
            print "Written to " + m.sectionName$ + ": " + key$ + " = " + value$
            return true
        End Function,

        ' Safe read method using "m" for validation
        readValue: Function(key$ As String, defaultValue$ = "" As String) As String
            if not m.isValid then
                print "Registry section '" + m.sectionName$ + "' is invalid - returning default"
                return defaultValue$
            end if

            if m.registrySection.Exists(key$) then
                return m.registrySection.Read(key$)
            else
                return defaultValue$
            end if
        End Function
    }

    ' Initialize validation state
    manager.validate()
    return manager
End Function

' Usage pattern from production code
Sub ConfigureDevice()
    ' Create registry manager and validate
    deviceRegistry = newRegistryManager("device_config")
    networkRegistry = newRegistryManager("networking")

    ' Use objects - they handle validation internally via "m"
    deviceRegistry.writeValue("device_id", "BS-12345")
    deviceRegistry.writeValue("setup_complete", "true")

    networkRegistry.writeValue("connection_type", "ethernet")
    networkRegistry.writeValue("dhcp_enabled", "true")

    ' Read configuration
    deviceID$ = deviceRegistry.readValue("device_id", "unknown")
    print "Device configured with ID: " + deviceID$
End Sub
```

**Key Production Insights:**
- **`m` is "self"** - Always refers to the current object's context
- **Cross-referencing** - Objects store references to each other and access via `m.parentObject`
- **State validation** - Methods use `m.isValid` patterns to check object state
- **Method chaining** - Objects call their own methods via `m.methodName()`
- **Property access** - All object properties accessed via `m.propertyName`

This pattern enables the complex object hierarchies and cross-references seen in production BrightSign applications.

---

## Objects and Interfaces

### Creating Objects

These production examples demonstrate critical object creation patterns: message port setup for event handling, registry section creation with mandatory validation and error handling, device information retrieval for system capabilities, network configuration with proper interface indexing, and timer setup with message port binding and validation:

```brightscript
' Production pattern: Object creation with validation
msgPort = CreateObject("roMessagePort")
registrySection = CreateObject("roRegistrySection", "networking")
if type(registrySection) <> "roRegistrySection" then
    print "Error: Unable to create roRegistrySection"
    stop
end if

' Production pattern: Device info and model checking
modelObject = CreateObject("roDeviceInfo")
deviceUniqueID$ = modelObject.GetDeviceUniqueId()
deviceModel$ = modelObject.GetModel()
deviceFamily$ = modelObject.GetFamily()

' Production pattern: Network configuration objects
nc = CreateObject("roNetworkConfiguration", 0)
if type(nc) = "roNetworkConfiguration" then
    nc.ResetInterfaceSettings()
    nc.Apply()
else
    print "Unable to create roNetworkConfiguration - index = 0"
end if

' Production pattern: Timer with message port setup
checkAlarm = CreateObject("roTimer")
checkAlarm.SetPort(msgPort)
checkAlarm.SetDate(-1, -1, -1)
checkAlarm.SetTime(-1, -1, 0, 0)
if not checkAlarm.Start() then stop
```

### Working with Interfaces

These examples show production interface interaction patterns: network configuration interface validation for WiFi capability detection, URL transfer object setup for HTTP operations with proper error handling, and storage device interface validation for reliable device mounting detection:

```brightscript
' Production pattern: Network interface detection
nc1 = CreateObject("roNetworkConfiguration", 1)
if type(nc1) = "roNetworkConfiguration" then
    currentConfig = nc1.GetCurrentConfig()
    if type(currentConfig) = "roAssociativeArray" then
        modelSupportsWifi = true
    end if
end if

' Production pattern: URL transfer with validation
xfer = CreateObject("roUrlTransfer")
xfer.SetPort(msgPort)
xfer.SetUrl(recurl)
if not xfer.AsyncGetToFile("autorun.tmp") then stop

' Production pattern: Storage info validation
du = CreateObject("roStorageInfo", deviceName$)
if type(du) = "roStorageInfo" then
    return true
endif
```

### Associative Arrays (Objects)

This comprehensive example demonstrates associative array usage as object containers: creating object literals with properties and methods, accessing properties through both dot notation and bracket syntax, adding and removing properties dynamically, and checking for property existence with built-in methods:

```brightscript
' Create object literal
person = {
    name: "John Doe",
    age: 30,
    city: "New York",

    ' Method
    describe: Function() As String
        return m.name + " is " + m.age.toStr() + " years old"
    End Function
}

' Access properties
print person.name
print person["age"]

' Call methods
print person.describe()

' Add new properties
person.email = "john@example.com"
person["phone"] = "555-1234"

' Delete property
person.Delete("phone")

' Check if property exists
if person.DoesExist("email") then
    print "Email: " + person.email
end if
```

---

## Arrays and Collections

### Arrays (roArray)

> **See also:** [12-queue-pattern.brs](examples/12-queue-pattern.brs) for a complete working example using arrays.

These examples demonstrate BrightScript array fundamentals: creating arrays with literal syntax and CreateObject methods, essential array operations including push/pop/shift/unshift for queue and stack operations, array manipulation methods like sorting and reversing, multi-dimensional array handling with DIM, and practical iteration patterns for data processing:

```brightscript
' Create arrays
numbers = [1, 2, 3, 4, 5]
mixed = [1, "two", 3.14, true, invalid]

' Using CreateObject
arr = CreateObject("roArray", 10, true)  ' Size 10, resizable

' Array operations
arr.Push(100)           ' Add to end
arr.Unshift(0)         ' Add to beginning
last = arr.Pop()        ' Remove from end
first = arr.Shift()     ' Remove from beginning
arr.Delete(2)           ' Delete at index 2
arr.Clear()             ' Remove all elements

' Array methods
numbers = [3, 1, 4, 1, 5]
numbers.Sort()          ' Sort in place
reversed = numbers.Reverse()
count = numbers.Count()
numbers.Append([9, 2, 6])  ' Add multiple elements

' Multi-dimensional arrays
Dim matrix[3, 3]
matrix[0, 0] = 1
matrix[1, 1] = 5
matrix[2, 2] = 9

' Array iteration
scores = [95, 87, 92, 88, 90]
total = 0
for each score in scores
    total = total + score
end for
average = total / scores.Count()
print "Average: "; average
```

### Lists (roList)

This example shows BrightScript's linked list implementation using roList: adding elements to both head and tail positions for flexible insertion, iterating through the list using head/next navigation patterns, and removing elements from specific positions for dynamic list management:

```brightscript
' Create linked list
list = CreateObject("roList")

' List operations
list.AddTail("first")
list.AddTail("second")
list.AddHead("zero")

' Iterate through list
node = list.GetHead()
while node <> invalid
    print node
    node = list.GetNext()
end while

' Remove items
list.RemoveHead()
list.RemoveTail()
```

---

## Libraries

BrightScript supports including external libraries using the `Library` statement. Libraries allow code reuse and modular organization by including external BrightScript files at the beginning of your script, making their functions available in your program.

### Library Inclusion Syntax

```brightscript
Library "filename.brs"
```

### Example Usage

> **See also:** [22-production-library-pattern.brs](examples/22-production-library-pattern.brs) for a complete working example.

This demonstrates proper library inclusion patterns:

```brightscript
Library "common-functions.brs"
Library "setupCommon.brs"
Library "setupNetworkDiagnostics.brs"
```

All examples in this collection use the shared `common-functions.brs` library for consistent message display functionality.

### Production Pattern: Multiple Library Includes

This real-world example shows how production BrightScript applications typically structure their library includes and initialization, including version tracking, debug configuration, and centralized diagnostics:

```brightscript
Library "setupCommon.brs"
Library "setupNetworkDiagnostics.brs"

Sub Main()
    ' Production pattern: version tracking
    version = "8.0.0.1"

    ' Production pattern: debug flag initialization
    debugParams = EnableDebugging("current-sync.json")
    sysFlags = {}
    sysFlags.debugOn = debugParams.serialDebugOn
    sysFlags.systemLogDebugOn = debugParams.systemLogDebugOn

    ' Production pattern: centralized diagnostics
    diagnostics = newDiagnostics(sysFlags)
    diagnostics.printDebug("setup.brs version " + version + " started")
End Sub
```

---

## String Operations

### String Basics

These fundamental examples show essential BrightScript string operations: concatenation using the + operator for combining text, length measurement with the Len() function, case conversion with UCase/LCase for standardization, and string trimming methods for removing whitespace from different positions:

```brightscript
' String concatenation
first$ = "Hello"
second$ = "World"
combined$ = first$ + " " + second$
print combined$  ' Output: Hello World

' String length
text$ = "BrightScript"
length = len(text$)
print "Length: "; length  ' Output: Length: 12

' Case conversion
upper$ = UCase("hello")     ' HELLO
lower$ = LCase("WORLD")     ' world

' String trimming
trimmed$ = "  spaces  ".Trim()      ' "spaces"
leftTrim$ = "  spaces".TrimLeft()   ' "spaces"
rightTrim$ = "spaces  ".TrimRight() ' "spaces"
```

### String Methods

These examples demonstrate advanced BrightScript string manipulation: substring extraction using Left/Right/Mid methods for precise text parsing, search and replace operations with Instr and Replace methods, conditional string matching for validation, tokenization for parsing delimited data, and type conversion between strings and numbers with proper formatting:

```brightscript
' Substring operations
text$ = "BrightScript Programming"
leftPart$ = text$.Left(6)        ' "Bright"
rightPart$ = text$.Right(11)     ' "Programming"
middle$ = text$.Mid(7, 6)        ' "Script"

' Find and replace
position = text$.Instr("Script")  ' Returns 7 (1-based)
replaced$ = text$.Replace("Script", "Sign")

' String comparison
if text$.Instr("Bright") > 0 then
    print "Contains 'Bright'"
end if

' Split string (using tokenize)
csv$ = "apple,banana,orange"
fruits = csv$.Tokenize(",")
for each fruit in fruits
    print fruit
end for

' Number to string conversion
num% = 42
str$ = Str(num%)          ' " 42" (with leading space)
str$ = num%.ToStr()       ' "42" (no space)
str$ = StrI(num%)         ' "42" (trimmed)

' String to number conversion
str$ = "123"
num% = Val(str$)          ' 123
num% = str$.ToInt()       ' 123
num! = str$.ToFloat()     ' 123.0
```

### Advanced String Examples

These practical functions showcase real-world string processing techniques: phone number formatting with digit extraction and pattern application for user interface display, and query string parsing using tokenization to convert URL parameters into associative arrays for web application development:

> **See also:** [04-string-functions.brs](examples/04-string-functions.brs) for a complete working example.

```brightscript
Function FormatPhoneNumber(phone As String) As String
    ' Remove all non-digits
    digits = ""
    for i = 1 to Len(phone)
        ch$ = Mid(phone, i, 1)
        if ch$ >= "0" and ch$ <= "9" then
            digits = digits + ch$
        end if
    end for

    ' Format as (XXX) XXX-XXXX
    if Len(digits) = 10 then
        return "(" + Left(digits, 3) + ") " + Mid(digits, 4, 3) + "-" + Right(digits, 4)
    else
        return phone  ' Return original if not 10 digits
    end if
End Function

Function ParseQueryString(query As String) As Object
    params = {}
    pairs = query.Tokenize("&")

    for each pair in pairs
        parts = pair.Tokenize("=")
        if parts.Count() = 2 then
            key = parts[0]
            value = parts[1]
            params[key] = value
        end if
    end for

    return params
End Function
```

---

## File Operations

### Reading Files

These file reading examples demonstrate essential input operations: simple text file reading with ReadAsciiFile for quick content retrieval, line-by-line processing using roReadFile for large file handling with EOF checking, and binary file reading with roByteArray for multimedia and data file processing:

```brightscript
' Read entire text file
content$ = ReadAsciiFile("config.txt")
if content$ <> "" then
    print "File contents: " + content$
end if

' Read with roReadFile object
file = CreateObject("roReadFile", "data.txt")
if file <> invalid then
    ' Read line by line
    while not file.AtEof()
        line$ = file.ReadLine()
        print line$
    end while
    file = invalid  ' Close file
end if

' Read binary file
byteArray = CreateObject("roByteArray")
byteArray.ReadFile("image.jpg")
print "File size: "; byteArray.Count(); " bytes"
```

### Writing Files

These file writing examples show essential output operations: simple text file creation with WriteAsciiFile for configuration storage, log file appending using roAppendFile with proper flushing for persistent logging, and structured file creation with roCreateFile for multi-line content with automatic resource cleanup:

```brightscript
' Write text file
WriteAsciiFile("output.txt", "Hello, World!")

' Append to file
AppendFile = CreateObject("roAppendFile", "log.txt")
if AppendFile <> invalid then
    AppendFile.SendLine("Log entry: " + CreateObject("roDateTime").ToIsoString())
    AppendFile.Flush()
    AppendFile = invalid
end if

' Create file with roCreateFile
file = CreateObject("roCreateFile", "newfile.txt")
if file <> invalid then
    file.SendLine("Line 1")
    file.SendLine("Line 2")
    file.SendLine("Line 3")
    file.Flush()
    file = invalid
end if
```

### Directory Operations

These directory management examples showcase essential filesystem operations: directory content listing with ListDir for file discovery, directory creation with CreateDirectory for storage organization, file deletion with DeleteFile for cleanup operations, file existence checking using object creation patterns, and advanced file information retrieval using roFileSystem for metadata access:

```brightscript
' List directory contents
files = ListDir("/")
for each file in files
    print file
end for

' Create directory
CreateDirectory("mydata")

' Delete file
DeleteFile("temp.txt")

' Check if file exists
if CreateObject("roReadFile", "config.txt") <> invalid then
    print "Config file exists"
end if

' Get file info
Function GetFileInfo(path As String) As Object
    info = {}
    fs = CreateObject("roFileSystem")
    stat = fs.Stat(path)

    if stat <> invalid then
        info.size = stat.size
        info.type = stat.type
        info.mtime = stat.mtime
    end if

    return info
End Function
```

---

## Networking

### HTTP Requests

These production HTTP examples demonstrate robust networking patterns: file download with retry logic and network interface binding, temporary file handling for safe downloads with GPIO error indication, async download setup with proper validation and message port configuration, and URL event handling with identity verification for reliable download completion detection:

```brightscript
' Production pattern: Download file with retry and error handling
Sub ProductionDownloadWithRetry(setupParams As Object, msgPort As Object)
    numRetries% = 0
    while numRetries% < 10
        ' Create URL transfer object
        xfer = CreateObject("roUrlTransfer")
        recurl = setupParams.base + setupParams.recoverySetup
        print "### Looking for file from " + recurl

        ' Production pattern: Bind to network interface
        xfer.BindToInterface(binding%)
        xfer.SetUrl(recurl)

        ' Production pattern: Download to temporary file first
        response_code = xfer.GetToFile("autorun.tmp")
        print "### xfer to card response code = " + stri(response_code)

        if response_code = 200 then
            ' Success - move temp file to final location
            MoveFile("autorun.tmp", "autorun.brs")
            return
        else
            ' Production pattern: Visual error indication with GPIO
            sw = CreateObject("roGpioControlPort")
            for flash_index = 0 to 9
                sw.SetWholeState(2 ^ 1 + 2 ^ 2 + 2 ^ 3 + 2 ^ 4 + 2 ^ 5 + 2 ^ 6 + 2 ^ 7 + 2 ^ 8 + 2 ^ 9 + 2 ^ 10)
                sleep(500)
                sw.SetWholeState(0)
                sleep(500)
            next
        end if
        numRetries% = numRetries% + 1
    end while

    ' Production pattern: Last resort - reboot system
    RebootSystem()
End Sub

' Production pattern: Async download with validation
Function StartAsyncDownload(url As String, filename As String, msgPort As Object) As Object
    xfer = CreateObject("roUrlTransfer")
    xfer.SetPort(msgPort)
    xfer.SetUrl(url)

    ' Production pattern: Always check async operation success
    if not xfer.AsyncGetToFile(filename) then
        print "Error: Failed to start async download"
        return invalid
    end if

    return xfer
End Function

' Production pattern: Handle URL events with identity verification
Sub HandleUrlEvent(msg As Object, xfer As Object)
    if type(msg) = "roUrlEvent" then
        if msg.GetSourceIdentity() = xfer.GetIdentity() then
            if msg.GetInt() = 1 then  ' URL_EVENT_COMPLETE
                responseCode% = msg.GetResponseCode()
                if responseCode% = 200 then
                    print "Download completed successfully"
                    ProcessDownloadedFile()
                else
                    print "Download failed with response code: " + stri(responseCode%)
                    HandleDownloadError(responseCode%)
                end if
            end if
        end if
    end if
End Sub
```

### HTTP Server

These HTTP server examples demonstrate web service creation: basic server setup with port configuration and message port binding, GET endpoint registration with custom event handlers for status requests, POST endpoint setup for file upload handling, and response management with proper headers and status codes:

```brightscript
Sub CreateWebServer()
    server = CreateObject("roHttpServer", { port: 8080 })
    server.SetPort(msgPort)

    ' Add GET endpoint
    server.AddGetFromEvent({
        url_path: "/status",
        user_data: {
            HandleEvent: HandleStatusRequest
        }
    })

    ' Add POST endpoint for file upload
    server.AddPostToFile({
        url_path: "/upload",
        destination_directory: "/storage/",
        user_data: {
            HandleEvent: HandleFileUpload
        }
    })
End Sub

Sub HandleStatusRequest(userData As Object, e As Object)
    response = {
        status: "running",
        time: CreateObject("roDateTime").ToIsoString()
    }

    e.SetResponseBodyString(FormatJson(response))
    e.AddResponseHeader("Content-Type", "application/json")
    e.SendResponse(200)
End Sub

Sub HandleFileUpload(userData As Object, e As Object)
    filename = e.GetRequestHeader("X-Filename")
    print "File uploaded: " + filename

    e.SetResponseBodyString("Upload successful")
    e.SendResponse(200)
End Sub
```

### Network Configuration

These network configuration examples demonstrate essential network management: basic interface configuration with DHCP and static IP setup, DNS server configuration with multiple server support, network configuration application for immediate effect, and network status retrieval for monitoring and diagnostics:

> **See also:** [18-network-configuration.brs](examples/18-network-configuration.brs) for a complete working example.

```brightscript
' Configure network interface
Sub ConfigureNetwork()
    nc = CreateObject("roNetworkConfiguration", 0)  ' eth0

    ' Set DHCP
    nc.SetDHCP()

    ' Or set static IP
    nc.SetIP4Address("192.168.1.100")
    nc.SetIP4Netmask("255.255.255.0")
    nc.SetIP4Gateway("192.168.1.1")
    nc.SetDNSServers(["8.8.8.8", "8.8.4.4"])

    ' Apply configuration
    nc.Apply()
End Sub

' Get network status
Function GetNetworkStatus() As Object
    nc = CreateObject("roNetworkConfiguration", 0)
    config = nc.GetCurrentConfig()

    status = {
        ip: config.ip4_address,
        netmask: config.ip4_netmask,
        gateway: config.ip4_gateway,
        dhcp: config.dhcp,
        dns: config.dns_servers
    }

    return status
End Function
```

---

## Media Playback

### Video Playback

These video playback examples demonstrate multimedia control: basic video player setup with message port binding for event handling, video mode configuration for display resolution, file playback with success validation, comprehensive event loop handling for media state tracking, and advanced playlist management with seek controls and volume adjustment:

> **See also:** [14-video-player.brs](examples/14-video-player.brs) and [17-complete-media-player.brs](examples/17-complete-media-player.brs) for complete working examples.

```brightscript
Sub PlayVideo(filename As String, msgPort As Object)
    videoPlayer = CreateObject("roVideoPlayer")
    videoPlayer.SetPort(msgPort)

    ' Configure video
    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")

    ' Play video file
    ok = videoPlayer.PlayFile(filename)
    if ok then
        print "Playing: " + filename
    else
        print "Failed to play video"
    end if

    ' Handle video events
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roVideoEvent" then
            eventType = msg.GetInt()

            if eventType = 8 then  ' MediaEnded
                print "Video finished"
                exit while
            else if eventType = 3 then  ' Playing
                print "Video started"
            end if
        end if
    end while
End Sub

' Advanced video control with playlist and parameter configuration
Sub AdvancedVideoPlayer()
    vp = CreateObject("roVideoPlayer")

    ' Set video parameters
    aa = CreateObject("roAssociativeArray")
    aa.filename = "video.mp4"
    aa.probeData = true

    ' Create playlist
    vp.AddEvent(0, aa)  ' Play at time 0
    vp.AddEvent(10000, {filename: "video2.mp4"})  ' Play at 10 seconds

    ' Control playback
    vp.Play()
    vp.Pause()
    vp.Resume()
    vp.Stop()
    vp.Seek(30000)  ' Seek to 30 seconds

    ' Set volume
    vp.SetVolume(50)
End Sub
```

### Audio Playback

These audio playback examples show multimedia audio control: basic audio player setup with message port configuration, audio output configuration for HDMI routing with volume control, event handling for audio completion detection, and multi-track playlist management with roAudioPlayerMx including loop mode configuration:

> **See also:** [15-audio-player.brs](examples/15-audio-player.brs) and [17-complete-media-player.brs](examples/17-complete-media-player.brs) for complete working examples.

```brightscript
Sub PlayAudio(filename As String, msgPort As Object)
    audioPlayer = CreateObject("roAudioPlayer")
    audioPlayer.SetPort(msgPort)

    ' Configure audio output
    audioConfig = CreateObject("roAudioConfiguration")
    audioConfig.SetAudioOutput("hdmi")
    audioConfig.SetVolume(75)

    ' Play audio file
    ok = audioPlayer.PlayFile(filename)

    ' Handle audio events
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roAudioEvent" then
            if msg.GetInt() = 8 then  ' MediaEnded
                print "Audio finished"
                exit while
            end if
        end if
    end while
End Sub

' Multi-track audio playlist with loop functionality
Sub CreateAudioPlaylist()
    player = CreateObject("roAudioPlayerMx")
    player.SetPort(msgPort)

    ' Add multiple tracks
    player.AddAudioFile("track1.mp3")
    player.AddAudioFile("track2.mp3")
    player.AddAudioFile("track3.mp3")

    ' Set loop mode
    player.SetLoopMode(true)

    ' Start playback
    player.Play()
End Sub
```

### Image Display

These image display examples demonstrate visual content management: single image display with roImagePlayer using file validation and timing control, and automated slideshow functionality with duration-based timing for cycling through image collections:

> **See also:** [16-image-slideshow.brs](examples/16-image-slideshow.brs) and [17-complete-media-player.brs](examples/17-complete-media-player.brs) for complete working examples.

```brightscript
Sub DisplayImage(filename As String)
    imagePlayer = CreateObject("roImagePlayer")

    ' Display single image
    ok = imagePlayer.DisplayFile(filename)

    if ok then
        print "Displaying: " + filename
    else
        print "Failed to display image"
    end if

    ' Display for 5 seconds
    sleep(5000)
End Sub

' Automated image slideshow with timed transitions
Sub ImageSlideshow(imageList As Object, duration As Integer)
    imagePlayer = CreateObject("roImagePlayer")

    for each image in imageList
        imagePlayer.DisplayFile(image)
        sleep(duration * 1000)  ' Duration in seconds
    end for
End Sub
```

---

## Event Handling - Message Ports as Event Bus

**Message ports (`roMessagePort`) are the cornerstone of BrightScript's event-driven architecture.** Think of a message port as a centralized event bus where multiple objects can send events, and your application listens for and processes these events in a single location. This design eliminates the need for polling and creates responsive, efficient applications.

> **See also:** [21-production-event-loop.brs](examples/21-production-event-loop.brs) and [24-complete-event-bus.brs](examples/24-complete-event-bus.brs) for complete working examples.

### Understanding the Message Port Concept

The message port acts as a **central communication hub**:
- **Publishers**: Objects like timers, GPIO ports, media players, network components post events
- **Subscribers**: Your main event loop listens for and processes events
- **Asynchronous**: Events are queued and processed when your application is ready
- **Thread-safe**: BrightScript handles thread synchronization internally

```brightscript
' The message port is your application's event bus
msgPort = CreateObject("roMessagePort")

' Multiple objects can post to the same port
timer = CreateObject("roTimer")
timer.SetPort(msgPort)                    ' Timer events -> msgPort

videoPlayer = CreateObject("roVideoPlayer")
videoPlayer.SetPort(msgPort)              ' Video events -> msgPort

gpio = CreateObject("roGpioControlPort")
gpio.SetPort(msgPort)                     ' Button events -> msgPort

httpRequest = CreateObject("roUrlTransfer")
httpRequest.SetPort(msgPort)              ' HTTP events -> msgPort

' Your application processes ALL events from ONE place
while true
    msg = wait(0, msgPort)  ' Listen to the event bus
    ProcessEvent(msg)       ' Handle any type of event
end while
```

### Basic Event Loop Pattern

Every BrightScript application follows this fundamental pattern:

```brightscript
Sub ProductionEventLoop()
    ' Production pattern: Main message port for all events
    msgPort = CreateObject("roMessagePort")

    ' Production pattern: Network URL transfer setup
    xfer = CreateObject("roUrlTransfer")
    xfer.SetPort(msgPort)

    ' Production pattern: Timer setup with identity tracking
    checkAlarm = CreateObject("roTimer")
    checkAlarm.SetPort(msgPort)
    checkAlarm.SetDate(-1, -1, -1)
    checkAlarm.SetTime(-1, -1, 0, 0)
    if not checkAlarm.Start() then stop

    ' Production pattern: Registration response timer
    registrationResponseTimer = CreateObject("roTimer")
    registrationResponseTimer.SetPort(msgPort)
    registrationResponseTimer.SetElapsed(60, 0)

    ' Production event loop - real patterns from production applications
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roUrlEvent" then
            ' Production pattern: URL event handling with identity check
            if msg.GetSourceIdentity() = xfer.GetIdentity() then
                if msg.GetInt() = 1 then  ' URL_EVENT_COMPLETE
                    if msg.GetResponseCode() = 200 then
                        ProcessSuccessfulDownload()
                    else
                        ProcessDownloadError(msg.GetResponseCode())
                    end if
                end if
            end if

        else if type(msg) = "roTimerEvent" then
            ' Production pattern: Timer identity verification
            if type(checkAlarm) = "roTimer" and stri(msg.GetSourceIdentity()) = stri(checkAlarm.GetIdentity()) then
                StartSync()
            else if type(registrationResponseTimer) = "roTimer" and stri(msg.GetSourceIdentity()) = stri(registrationResponseTimer.GetIdentity()) then
                HandleRegistrationTimeout()
            end if

        else if type(msg) = "roDatagramEvent" and IsString(msg.GetUserData()) and msg.GetUserData() = "bootstrap" then
            ' Production pattern: Bootstrap message handling
            payload = ParseJson(msg.GetString())
            if payload <> invalid and payload.message <> invalid then
                ProcessBootstrapMessage(payload)
            end if

        else if type(msg) = "roControlCloudMessageEvent" and IsString(msg.GetUserData()) and msg.GetUserData() = "bootstrap" then
            ' Production pattern: Control cloud message handling
            jsonObject = ParseJson(msg.GetData())
            if jsonObject <> invalid then
                ProcessCloudMessage(jsonObject)
            end if
        end if
    end while
End Sub
```

### The Wait Function - Heart of Event Processing

The `wait()` function is your interface to the message port event bus:

```brightscript
' Syntax: wait(timeout_ms, port_or_array_of_ports)

' 1. Block indefinitely until event arrives
msg = wait(0, msgPort)
if msg <> invalid then
    ' Process the event
end if

' 2. Block with timeout (non-blocking after timeout)
msg = wait(1000, msgPort)  ' Wait up to 1 second
if msg = invalid then
    print "No event in 1 second - do background work"
    DoBackgroundProcessing()
else
    ProcessEvent(msg)
end if

' 3. Non-blocking check (poll for events)
msg = wait(0, msgPort)  ' Returns immediately
if msg <> invalid then
    ProcessEvent(msg)
end if

' 4. Listen to multiple event buses
primaryPort = CreateObject("roMessagePort")
secondaryPort = CreateObject("roMessagePort")
ports = [primaryPort, secondaryPort]

msg = wait(0, ports)  ' Wait on array of ports
if msg <> invalid then
    ' Event came from one of the ports
end if
```

### Advanced Event Bus Patterns

#### 1. Event Queue Processing

Process all pending events before continuing:

```brightscript
Sub ProcessAllPendingEvents(msgPort As Object)
    ' Drain the event queue
    while true
        msg = wait(0, msgPort)  ' Non-blocking check
        if msg = invalid then exit while  ' No more events

        ProcessEvent(msg)
    end while
End Sub

' Usage in main loop
Sub MainLoop()
    while true
        ' Process all accumulated events
        ProcessAllPendingEvents(msgPort)

        ' Do other work
        UpdateUI()
        sleep(50)  ' Brief pause
    end while
End Sub
```

#### 2. Event Prioritization

Handle critical events first:

```brightscript
Sub PrioritizedEventLoop()
    while true
        msg = wait(100, msgPort)  ' 100ms timeout

        if msg <> invalid then
            ' Handle critical events immediately
            if type(msg) = "roStorageHotplugEvent" then
                HandleCriticalStorageEvent(msg)
            else if type(msg) = "roSystemLogEvent" then
                HandleSystemError(msg)
            else
                ' Queue regular events for batch processing
                eventQueue.Push(msg)
            end if
        end if

        ' Process queued events in batches
        if eventQueue.Count() > 0 then
            ProcessEventBatch(eventQueue)
        end if
    end while
End Sub
```

#### 3. Event Routing and Filtering

Route events to specific handlers:

```brightscript
Function CreateEventRouter() As Object
    return {
        msgPort: CreateObject("roMessagePort"),
        routes: {},

        ' Register event handler
        route: Function(eventType As String, handler As Function) As Void
            m.routes[eventType] = handler
        End Function,

        ' Route events to appropriate handlers
        processEvents: Function() As Void
            msg = wait(100, m.msgPort)
            if msg <> invalid then
                eventType = type(msg)

                if m.routes.DoesExist(eventType) then
                    handler = m.routes[eventType]
                    handler(msg)
                else
                    print "Unhandled event: " + eventType
                end if
            end if
        End Function,

        ' Get the port for objects to post to
        getPort: Function() As Object
            return m.msgPort
        End Function
    }
End Function

' Usage
Sub AdvancedEventHandling()
    router = CreateEventRouter()

    ' Register event handlers
    router.route("roTimerEvent", Function(msg As Object)
        print "Timer elapsed at: " + CreateObject("roDateTime").ToIsoString()
    End Function)

    router.route("roVideoEvent", Function(msg As Object)
        code = msg.GetInt()
        if code = 8 then  ' MediaEnd
            print "Video finished - play next"
            PlayNextVideo()
        end if
    End Function)

    router.route("roHttpEvent", Function(msg As Object)
        responseCode = msg.GetResponseCode()
        print "HTTP response: " + responseCode.ToStr()
    End Function)

    ' Connect objects to the event bus
    timer = CreateObject("roTimer")
    timer.SetPort(router.getPort())
    timer.SetElapsed(10, 0)
    timer.Start()

    video = CreateObject("roVideoPlayer")
    video.SetPort(router.getPort())

    ' Process events
    while true
        router.processEvents()
    end while
End Sub
```

#### 4. Event State Machine

Combine event handling with state management:

```brightscript
Function CreateStatefulEventHandler() As Object
    return {
        state: "IDLE",
        msgPort: CreateObject("roMessagePort"),

        processEvent: Function(msg As Object) As Void
            eventType = type(msg)

            ' State-based event handling
            if m.state = "IDLE" then
                if eventType = "roGpioButton" and msg.GetInt() = 0 then
                    print "Starting playback"
                    m.state = "PLAYING"
                    StartVideoPlayback()
                end if

            else if m.state = "PLAYING" then
                if eventType = "roVideoEvent" then
                    if msg.GetInt() = 8 then  ' MediaEnd
                        print "Playback finished"
                        m.state = "IDLE"
                    end if
                else if eventType = "roGpioButton" and msg.GetInt() = 1 then
                    print "Pausing playback"
                    m.state = "PAUSED"
                    PausePlayback()
                end if

            else if m.state = "PAUSED" then
                if eventType = "roGpioButton" and msg.GetInt() = 1 then
                    print "Resuming playback"
                    m.state = "PLAYING"
                    ResumePlayback()
                end if
            end if
        End Function,

        run: Function() As Void
            while true
                msg = wait(0, m.msgPort)
                if msg <> invalid then
                    m.processEvent(msg)
                end if
            end while
        End Function
    }
End Function
```

### Real-World Event Bus Example

Here's a comprehensive example showing message ports managing multiple subsystems:

```brightscript
Sub CompleteEventBusExample()
    ' Create the main event bus
    mainEventBus = CreateObject("roMessagePort")

    ' === MEDIA SUBSYSTEM ===
    videoPlayer = CreateObject("roVideoPlayer")
    videoPlayer.SetPort(mainEventBus)

    audioPlayer = CreateObject("roAudioPlayer")
    audioPlayer.SetPort(mainEventBus)

    ' === NETWORK SUBSYSTEM ===
    httpServer = CreateObject("roHttpServer", { port: 8080 })
    httpServer.SetPort(mainEventBus)
    httpServer.AddGetFromEvent({ url_path: "/status" })

    downloader = CreateObject("roUrlTransfer")
    downloader.SetPort(mainEventBus)

    ' === HARDWARE SUBSYSTEM ===
    gpio = CreateObject("roGpioControlPort")
    gpio.SetPort(mainEventBus)

    storage = CreateObject("roStorageHotplug")
    storage.SetPort(mainEventBus)

    ' === TIMING SUBSYSTEM ===
    mainTimer = CreateObject("roTimer")
    mainTimer.SetPort(mainEventBus)
    mainTimer.SetElapsed(30, 0)  ' Heartbeat every 30 seconds
    mainTimer.Start()

    watchdogTimer = CreateObject("roTimer")
    watchdogTimer.SetPort(mainEventBus)

    ' === EVENT PROCESSING ===
    print "Event bus initialized - listening for events..."

    while true
        msg = wait(0, mainEventBus)

        ' MEDIA EVENTS
        if type(msg) = "roVideoEvent" then
            code = msg.GetInt()
            if code = 3 then
                print "Video started playing"
            else if code = 8 then
                print "Video finished - check for next item"
                CheckPlaylist()
            else if code = 19 then
                print "Video failed to play"
                HandlePlaybackError()
            end if

        else if type(msg) = "roAudioEvent" then
            if msg.GetInt() = 8 then
                print "Audio finished"
                PlayNextAudio()
            end if

        ' NETWORK EVENTS
        else if type(msg) = "roHttpEvent" then
            print "HTTP request - sending status response"
            HandleHttpRequest(msg)

        else if type(msg) = "roUrlEvent" then
            code = msg.GetResponseCode()
            if code = 200 then
                print "Download completed successfully"
                ProcessDownloadedContent()
            else
                print "Download failed: " + code.ToStr()
            end if

        ' HARDWARE EVENTS
        else if type(msg) = "roGpioButton" then
            button = msg.GetInt()
            print "Button " + button.ToStr() + " pressed"

            if button = 0 then
                ' Play/pause toggle
                TogglePlayback()
            else if button = 1 then
                ' Next content
                PlayNext()
            else if button = 12 then
                ' Shutdown
                print "Shutdown requested"
                exit while
            end if

        else if type(msg) = "roStorageAttached" then
            print "Storage device attached - scanning for content"
            ScanForNewContent()

        else if type(msg) = "roStorageDetached" then
            print "Storage device removed"
            HandleStorageRemoval()

        ' TIMING EVENTS
        else if type(msg) = "roTimerEvent" then
            userData = msg.GetUserData()

            if userData = invalid then
                ' Main heartbeat timer
                print "Heartbeat - system status OK"
                SendHeartbeat()
            else if userData = "watchdog" then
                print "Watchdog timeout - restarting system"
                RestartSystem()
            end if

        else
            print "Unknown event: " + type(msg)
        end if
    end while

    print "Shutting down event bus..."
End Sub
```

### Event Bus Best Practices

#### 1. Single Event Loop
**DO:** Use one main event loop for your application
```brightscript
' GOOD: Single event bus
mainPort = CreateObject("roMessagePort")
' All objects post to mainPort
while true
    msg = wait(0, mainPort)
    HandleAnyEvent(msg)
end while
```

**DON'T:** Create multiple competing event loops
```brightscript
' BAD: Competing event loops
while true
    msg1 = wait(0, port1)
    msg2 = wait(0, port2)  ' This wait may block
    ' Events can get stuck in queues
end while
```

#### 2. Event Source Management
Keep track of what objects are posting to your event bus:

```brightscript
Function CreateManagedEventBus() As Object
    return {
        msgPort: CreateObject("roMessagePort"),
        sources: [],  ' Track event sources

        registerSource: Function(obj As Object, name As String) As Void
            obj.SetPort(m.msgPort)
            m.sources.Push({ object: obj, name: name })
            print "Registered event source: " + name
        End Function,

        cleanup: Function() As Void
            ' Cleanup all registered sources
            for each source in m.sources
                source.object = invalid
            end for
            m.sources.Clear()
        End Function
    }
End Function
```

#### 3. Event Loop Performance
Balance responsiveness with CPU usage:

```brightscript
Sub OptimizedEventLoop()
    maxEventsPerCycle = 10
    eventCount = 0

    while true
        msg = wait(50, msgPort)  ' 50ms timeout prevents 100% CPU

        if msg <> invalid then
            ProcessEvent(msg)
            eventCount = eventCount + 1

            ' Limit events per cycle to prevent starvation
            if eventCount >= maxEventsPerCycle then
                eventCount = 0
                sleep(10)  ' Brief pause
            end if
        else
            ' No events - do background work
            eventCount = 0
            DoBackgroundTasks()
        end if
    end while
End Sub
```

### Debugging Event Buses

Add logging to understand event flow:

```brightscript
Sub EventDebugger(msg As Object)
    timestamp = CreateObject("roDateTime").ToIsoString()
    eventType = type(msg)

    print "[" + timestamp + "] EVENT: " + eventType

    ' Add specific debugging for different event types
    if eventType = "roVideoEvent" then
        print "  Video Code: " + msg.GetInt().ToStr()
    else if eventType = "roGpioButton" then
        print "  Button: " + msg.GetInt().ToStr()
    else if eventType = "roHttpEvent" then
        print "  HTTP Code: " + msg.GetResponseCode().ToStr()
    end if
End Sub

' Use in your event loop:
while true
    msg = wait(0, msgPort)
    if msg <> invalid then
        EventDebugger(msg)  ' Debug first
        ProcessEvent(msg)   ' Then process
    end if
end while
```

**The message port event bus pattern is fundamental to BrightScript development.** Master this concept, and you'll be able to build responsive, maintainable applications that handle multiple simultaneous operations gracefully.

---

## XML Processing

### Parsing XML

These XML processing examples demonstrate structured data handling: basic XML parsing with roXMLElement for document processing, element access using dot notation for hierarchical navigation, attribute retrieval with @ syntax, iteration through XML node lists, and advanced document navigation with path-based element selection:

> **See also:** [27-xml-processing.brs](examples/27-xml-processing.brs) for a complete working example.

```brightscript
Sub ParseXmlExample()
    xmlString = "<?xml version='1.0'?><root><item id='1'>First</item><item id='2'>Second</item></root>"

    ' Parse XML
    xml = CreateObject("roXMLElement")
    if xml.Parse(xmlString) then
        print "XML parsed successfully"

        ' Access elements using dot notation
        items = xml.item  ' Returns roXMLList
        print "Found " + items.Count().ToStr() + " items"

        ' Iterate through items
        for each item in items
            id = item@id  ' Get attribute with @
            text = item.GetText()
            print "Item " + id + ": " + text
        end for
    else
        print "Failed to parse XML"
    end if
End Sub

' Advanced XML document navigation with attribute filtering
Sub NavigateXml()
    xmlStr = ReadAsciiFile("data.xml")
    doc = CreateObject("roXMLElement")
    doc.Parse(xmlStr)

    ' Navigate using dot notation
    firstBook = doc.library.books.book[0]
    title = firstBook.title.GetText()
    author = firstBook@author  ' Attribute

    ' Find all books by author
    allBooks = doc.library.books.book
    for each book in allBooks
        if book@author = "Smith" then
            print book.title.GetText()
        end if
    end for
End Sub
```

### Creating XML

This XML generation example demonstrates programmatic XML document creation: root element creation with roXMLElement, child element addition with proper nesting, attribute assignment for metadata, element body content setting, and complete XML document generation with header formatting:

```brightscript
Function CreateXmlDocument() As String
    root = CreateObject("roXMLElement")
    root.SetName("catalog")

    ' Add product
    product = root.AddBodyElement()
    product.SetName("product")
    product.AddAttribute("id", "123")

    ' Add child elements
    name = product.AddElement("name")
    name.SetBody("BrightSign Player")

    price = product.AddElement("price")
    price.SetBody("299.99")
    price.AddAttribute("currency", "USD")

    ' Generate XML string
    xmlString = root.GenXML({ header: true })
    return xmlString
End Function
```

---

## Best Practices

### Logging

BrightScript provides multiple logging mechanisms for diagnostics and debugging. Understanding the `roSystemLog` object and the `SendLine` command is essential for production logging.

#### roSystemLog Object

`roSystemLog` is a system object used for logging diagnostic messages to the device's system log. This is particularly useful in production environments where you need persistent logging that survives application restarts.

**Key characteristics:**
- Created using `CreateObject("roSystemLog")`
- Writes log entries to the BrightSign device's system log (not just console output)
- System logs persist and can be accessed for troubleshooting
- Used for debugging and diagnostics in production environments

```brightscript
' Production pattern: System log for diagnostics
systemLog = CreateObject("roSystemLog")
systemLog.SendLine("[DEBUG] Application initialized")
systemLog.SendLine("[INFO] Network connection established")
```

#### SendLine Command

`SendLine()` is a method available on multiple file-writing objects in BrightScript. It writes a line of text to the target destination and automatically appends a newline character.

**Objects that support SendLine:**

1. **roSystemLog** - Writes to system log
2. **roAppendFile** - Appends lines to existing files  
3. **roCreateFile** - Writes lines to new files

#### Logging Pattern Examples

```brightscript
' Pattern 1: System logging for production diagnostics
Function CreateDiagnostics(systemLogEnabled As Boolean) As Object
    return {
        systemLogEnabled: systemLogEnabled,
        
        logEvent: Function(message As String) As Void
            if m.systemLogEnabled then
                systemLog = CreateObject("roSystemLog")
                systemLog.SendLine("[EVENT] " + message)
            end if
        End Function,
        
        logError: Function(message As String) As Void
            ' Always log errors to system log
            systemLog = CreateObject("roSystemLog")
            systemLog.SendLine("[ERROR] " + message)
            print "ERROR: " + message
        End Function
    }
End Function

' Pattern 2: Dual logging - console and system log
Function printDebug(message As String, useSystemLog As Boolean) As Void
    ' Console output for development
    print "[DEBUG] " + message
    
    ' System log for production
    if useSystemLog then
        systemLog = CreateObject("roSystemLog")
        systemLog.SendLine("[DEBUG] " + message)
    end if
End Function

' Pattern 3: File logging with roAppendFile
Sub LogToFile(logFile As String, message As String)
    file = CreateObject("roAppendFile", logFile)
    if file <> invalid then
        timestamp = CreateObject("roDateTime").ToIsoString()
        file.SendLine(timestamp + " - " + message)
        file.Flush()
        file = invalid  ' Clean up
    end if
End Sub

' Pattern 4: Creating structured log files
Sub CreateLogFile(filename As String, entries As Object)
    file = CreateObject("roCreateFile", filename)
    if file <> invalid then
        file.SendLine("Log started: " + CreateObject("roDateTime").ToIsoString())
        file.SendLine("==========================================")
        
        for each entry in entries
            file.SendLine(entry)
        end for
        
        file.Flush()
        file = invalid
    end if
End Sub
```

#### Comparison: System Log vs File Logging

| Aspect | roSystemLog | roAppendFile/roCreateFile |
|--------|-------------|---------------------------|
| **Destination** | System log (device-level) | Text files |
| **Persistence** | System-managed, survives app restarts | File-based storage |
| **Use Case** | Production diagnostics, system events | Application logs, data files |
| **Access** | Via device diagnostic tools | Direct file reading |
| **Overhead** | Minimal | File I/O overhead |

#### Best Practices for Logging

```brightscript
' 1. Always validate object creation
Sub SafeLog(message As String)
    file = CreateObject("roAppendFile", "app.log")
    if file <> invalid then
        file.SendLine(message)
        file.Flush()
        file = invalid
    else
        print "ERROR: Could not create log file"
    end if
End Sub

' 2. Use configuration flags for log levels
Function CreateConfigurableLogger(config As Object) As Object
    return {
        debugEnabled: config.debugEnabled,
        infoEnabled: config.infoEnabled,
        useSystemLog: config.useSystemLog,
        
        debug: Function(msg As String) As Void
            if m.debugEnabled then
                print "[DEBUG] " + msg
                if m.useSystemLog then
                    systemLog = CreateObject("roSystemLog")
                    systemLog.SendLine("[DEBUG] " + msg)
                end if
            end if
        End Function,
        
        info: Function(msg As String) As Void
            if m.infoEnabled then
                print "[INFO] " + msg
                if m.useSystemLog then
                    systemLog = CreateObject("roSystemLog")
                    systemLog.SendLine("[INFO] " + msg)
                end if
            end if
        End Function
    }
End Function

' 3. Always flush after writing to ensure data persistence
Sub WriteLog(message As String)
    logFile = CreateObject("roAppendFile", "events.log")
    if logFile <> invalid then
        logFile.SendLine(message)
        logFile.Flush()  ' Ensure data is written to disk
        logFile = invalid  ' Release resources
    end if
End Sub

' 4. Include timestamps for audit trails
Sub LogWithTimestamp(message As String)
    timestamp = CreateObject("roDateTime").ToIsoString()
    logEntry = timestamp + " | " + message
    
    systemLog = CreateObject("roSystemLog")
    systemLog.SendLine(logEntry)
End Sub

' 5. Use structured logging for production
Function CreateProductionLogger(logFile As String) As Object
    return {
        logFile: logFile,
        
        log: Function(level As String, component As String, message As String) As Void
            timestamp = CreateObject("roDateTime").ToIsoString()
            logEntry = timestamp + " [" + level + "] [" + component + "] " + message
            
            ' Write to file
            file = CreateObject("roAppendFile", m.logFile)
            if file <> invalid then
                file.SendLine(logEntry)
                file.Flush()
                file = invalid
            end if
            
            ' Critical errors also go to system log
            if level = "ERROR" or level = "CRITICAL" then
                systemLog = CreateObject("roSystemLog")
                systemLog.SendLine(logEntry)
            end if
        End Function
    }
End Function
```

### Error Handling

These production error handling patterns demonstrate critical robustness techniques: mandatory object creation validation with immediate program termination on failure, network configuration validation with early return patterns, device info validation for system stability, file operation validation for data integrity, and timer creation validation with comprehensive error checking:

> **See also:** [23-production-validation-pattern.brs](examples/23-production-validation-pattern.brs) for a complete working example.

```brightscript
' Production pattern: Object creation with immediate validation and stop
registrySection = CreateObject("roRegistrySection", "networking")
if type(registrySection) <> "roRegistrySection" then
    print "Error: Unable to create roRegistrySection"
    stop
end if

' Production pattern: Network configuration validation
nc = CreateObject("roNetworkConfiguration", 1)
if nc = invalid then
    print "Unable to create roNetworkConfiguration - index = 1"
    return
end if

' Production pattern: Device info validation with error message
modelObject = CreateObject("roDeviceInfo")
if type(modelObject) <> "roDeviceInfo" then
    print "Error: Unable to create roDeviceInfo"
    stop
end if

' Production pattern: File operation validation
ok = WriteAsciiFile("test.txt", "content")
if not ok then
    print "Error: Unable to write to file"
    return false
end if

' Production pattern: Timer creation validation
checkAlarm = CreateObject("roTimer")
checkAlarm.SetPort(msgPort)
if not checkAlarm.Start() then
    print "Error: Unable to start timer"
    stop
end if

' Error handling pattern using Eval for safe code execution
Function TryOperation(code As String) As Dynamic
    result = Eval(code)

    if type(result) = "roList" then
        ' Compile error
        print "Compile error in: " + code
        return invalid
    else if type(result) = "Integer" then
        ' Runtime error
        print "Runtime error code: " + result.ToStr()
        return invalid
    else
        return result
    end if
End Function
```

### Memory Management

These memory optimization examples demonstrate resource management: proper object cleanup by setting references to invalid for garbage collection, array clearing for memory release, manual garbage collection for circular reference handling, and efficient string building using array join methods instead of concatenation loops:

```brightscript
' Clean up objects
Sub Cleanup()
    ' Set objects to invalid to release memory
    m.videoPlayer = invalid
    m.audioPlayer = invalid
    m.imagePlayer = invalid

    ' Clear arrays
    m.dataArray.Clear()

    ' Run garbage collector for circular references
    RunGarbageCollector()
End Sub

' Efficient string concatenation avoiding loop-based building
Function BuildLargeString(parts As Object) As String
    ' Don't concatenate in loop - inefficient
    ' result = ""
    ' for each part in parts
    '     result = result + part  ' BAD
    ' end for

    ' Better: use array and join
    return parts.Join("")
End Function
```

### Code Organization

These code organization examples demonstrate maintainable programming practices: descriptive function naming for self-documenting code, logical function grouping for related operations, and meaningful constant usage replacing magic numbers for better code clarity and maintainability:

```brightscript
' Use meaningful function names
Function ValidateEmailAddress(email As String) As Boolean
    ' Check for @ symbol and domain
    if email.Instr("@") <= 0 then return false
    if email.Instr(".") <= 0 then return false
    return true
End Function

' Logically grouped database functions for related operations
Function CreateDatabaseConnection() As Object
    ' Database setup code
End Function

Function ExecuteDatabaseQuery(query As String) As Object
    ' Query execution
End Function

Function CloseDatabaseConnection() As Void
    ' Cleanup code
End Function

' Constants replacing magic numbers for maintainable configuration
Function SetVideoMode() As Void
    HD_WIDTH = 1920
    HD_HEIGHT = 1080
    REFRESH_RATE = 60

    mode = CreateObject("roVideoMode")
    mode.SetMode(HD_WIDTH.ToStr() + "x" + HD_HEIGHT.ToStr() + "x" + REFRESH_RATE.ToStr() + "p")
End Function
```

---

## Common Patterns

### State Machine

This state machine example demonstrates structured state management: object-based state machine creation with centralized state tracking, state transition logging for debugging, and event-driven state changes with conditional logic for different system states:

> **See also:** [13-state-machine.brs](examples/13-state-machine.brs) for a complete working example.

```brightscript
Function CreateStateMachine() As Object
    return {
        state: "IDLE",

        setState: Function(newState As String) As Void
            print "State change: " + m.state + " -> " + newState
            m.state = newState
        End Function,

        handleEvent: Function(event As String) As Void
            if m.state = "IDLE" then
                if event = "START" then
                    m.setState("RUNNING")
                end if

            else if m.state = "RUNNING" then
                if event = "PAUSE" then
                    m.setState("PAUSED")
                else if event = "STOP" then
                    m.setState("IDLE")
                end if

            else if m.state = "PAUSED" then
                if event = "RESUME" then
                    m.setState("RUNNING")
                else if event = "STOP" then
                    m.setState("IDLE")
                end if
            end if
        End Function
    }
End Function
```

### Queue Pattern

This queue implementation demonstrates essential data structure patterns: FIFO queue creation with array-based storage, enqueue/dequeue operations for adding and removing elements, queue state checking with peek and isEmpty methods, and size tracking for capacity management:

> **See also:** [12-queue-pattern.brs](examples/12-queue-pattern.brs) for a complete working example.

```brightscript
Function CreateQueue() As Object
    return {
        items: [],

        enqueue: Function(item As Dynamic) As Void
            m.items.Push(item)
        End Function,

        dequeue: Function() As Dynamic
            if m.items.Count() > 0 then
                return m.items.Shift()
            end if
            return invalid
        End Function,

        peek: Function() As Dynamic
            if m.items.Count() > 0 then
                return m.items[0]
            end if
            return invalid
        End Function,

        isEmpty: Function() As Boolean
            return m.items.Count() = 0
        End Function,

        size: Function() As Integer
            return m.items.Count()
        End Function
    }
End Function
```

### Registry Settings - Production Patterns

**Critical:** Always validate registry section creation and handle failures:

This comprehensive registry management example demonstrates production-ready persistent storage patterns: safe registry section creation with validation and error handling, settings manager object with built-in validation methods, proper read/write/delete operations with flushing, and real-world production usage with multiple registry sections for different configuration categories:

> **See also:** [19-registry-settings.brs](examples/19-registry-settings.brs) and [20-registry-manager-validation.brs](examples/20-registry-manager-validation.brs) for complete working examples.

```brightscript
' Production pattern: Safe registry section creation
Function CreateSettingsManager(sectionName As String) As Object
    return {
        section: CreateObject("roRegistrySection", sectionName),
        sectionName: sectionName,

        ' Production pattern: Always validate registry creation
        isValid: Function() As Boolean
            return type(m.section) = "roRegistrySection"
        End Function,

        set: Function(key As String, value As String) As Boolean
            if not m.isValid() then
                print "Error: Registry section '" + m.sectionName + "' invalid"
                return false
            end if

            m.section.Write(key, value)
            m.section.Flush()
            return true
        End Function,

        get: Function(key As String, defaultValue = "" As String) As String
            if not m.isValid() then
                print "Error: Registry section '" + m.sectionName + "' invalid"
                return defaultValue
            end if

            if m.section.Exists(key) then
                return m.section.Read(key)
            end if
            return defaultValue
        End Function,

        delete: Function(key As String) As Boolean
            if not m.isValid() then return false

            m.section.Delete(key)
            m.section.Flush()
            return true
        End Function
    }
End Function

' Production pattern: Complete system configuration with multiple sections
Sub ConfigureSystem()
    ' Multiple registry sections for different purposes
    registrySection = CreateObject("roRegistrySection", "networking")
    if type(registrySection) <> "roRegistrySection" then
        print "Error: Unable to create roRegistrySection"
        stop  ' Production code actually stops on failure
    end if

    ' Supervisor section with special naming
    supervisorSection = CreateObject("roRegistrySection", "!supervisor.brightsignnetwork.com")
    if type(supervisorSection) <> "roRegistrySection" then
        print "Error: Unable to create supervisorRegistrySection"
        stop
    end if

    ' Production pattern: Clear old values first
    registrySection.Delete("old_setting")
    registrySection.Delete("deprecated_value")

    ' Write new settings - production patterns from production applications
    registrySection.Write("u", setupParams.user)
    registrySection.Write("p", setupParams.password)
    registrySection.Write("tz", setupParams.timezone$)
    registrySection.Write("un", setupParams.unitName$)
    registrySection.Write("tbnc", GetNumericStringFromNumber(setupParams.timeBetweenNetConnects%))
    registrySection.Write("cdr", GetYesNoFromBoolean(setupParams.contentDownloadsRestricted))
    registrySection.Write("wifi", "yes")
    registrySection.Write("ss", setupParams.ssid$)
    registrySection.Write("pp", setupParams.passphrase$)

    ' Production pattern: Always flush after writes
    registrySection.Flush()

    ' Production pattern: Delete entries to clear state
    registrySection.Delete("registration_in_progress")
    registrySection.Flush()
End Sub

' Production utility functions for registry data conversion
Function GetYesNoFromBoolean(value as boolean) as string
    if value then return "yes"
    return "no"
end function

Function GetNumericStringFromNumber(value% as integer) as string
    return stri(value%)
end function
```

### Timer Utilities - Production Patterns

**Critical Timer Identity Check:** Production code always verifies timer identity:

These comprehensive timer management examples demonstrate production-tested timing patterns: centralized timer manager with identity tracking, critical timer identity verification using string conversion, multi-timer event handling with proper cleanup, real-world timer usage patterns from production BrightSign applications, and specialized daily timer configuration for scheduled operations:

> **See also:** [25-timer-manager.brs](examples/25-timer-manager.brs) for a complete working example.

```brightscript
' Production pattern: Safe timer management with identity verification
Function CreateProductionTimerManager() As Object
    return {
        msgPort: CreateObject("roMessagePort"),
        timers: {},  ' Track multiple timers

        createTimer: Function(name As String, intervalSec As Integer) As Object
            timer = CreateObject("roTimer")
            timer.SetPort(m.msgPort)
            timer.SetElapsed(intervalSec, 0)

            ' Store timer reference with name
            m.timers[name] = timer
            return timer
        End Function,

        ' Production pattern: Always verify timer identity
        handleTimerEvent: Function(msg As Object) As String
            if type(msg) <> "roTimerEvent" then return ""

            ' Check each timer to find which one fired
            for each timerName in m.timers
                timer = m.timers[timerName]
                if type(timer) = "roTimer" then
                    ' CRITICAL: Use stri() for identity comparison
                    if stri(msg.GetSourceIdentity()) = stri(timer.GetIdentity()) then
                        return timerName
                    end if
                end if
            end for

            return "unknown"
        End Function,

        cleanup: Function() As Void
            ' Production pattern: Clean up all timers
            for each timerName in m.timers
                m.timers[timerName] = invalid
            end for
            m.timers.Clear()
        End Function
    }
End Function

' Production example: WiFi monitoring with proper identity verification
Sub RealTimerUsageExample()
    connectionTimerMsgPort = CreateObject("roMessagePort")
    checkWifiTimer = CreateObject("roTimer")
    checkWifiTimer.SetPort(connectionTimerMsgPort)
    checkWifiTimer.SetElapsed(15, 0)  ' 15 second interval
    checkWifiTimer.Start()

    while true
        msg = wait(0, connectionTimerMsgPort)

        ' PRODUCTION PATTERN: Always verify timer identity
        if type(msg) = "roTimerEvent" and type(checkWifiTimer) = "roTimer" then
            if stri(msg.GetSourceIdentity()) = stri(checkWifiTimer.GetIdentity()) then
                print "Wifi connection check timer fired"
                ' Handle the specific timer event
                CheckWifiConnection()
                exit while
            end if
        end if
    end while

    ' Production pattern: Clean up timers
    checkWifiTimer = invalid
    connectionTimerMsgPort = invalid
End Sub

' Production example: Scheduled operations with daily and timeout timers
Sub SetupDailyLogTimer()
    cutoverTimer = CreateObject("roTimer")
    cutoverTimer.SetPort(msgPort)
    cutoverTimer.SetDate(-1, -1, -1)
    cutoverTimer.SetTime(hour%, minute%, 0, 0)  ' Set specific time
    cutoverTimer.Start()

    ' Production pattern: Registration timeout timer
    registrationResponseTimer = CreateObject("roTimer")
    registrationResponseTimer.SetPort(msgPort)
    registrationResponseTimer.SetElapsed(60, 0)  ' 60 second timeout
    registrationResponseTimer.Start()
End Sub
```

---

## Debugging

### Debug Print Statements

These debugging examples demonstrate essential troubleshooting techniques: conditional debug printing with boolean flags for production control, object content inspection using FormatJson for complex data structures, type information printing for variable validation, and advanced debug helper functions with timestamp formatting and automatic type detection:

```brightscript
' Basic debugging
Sub DebugExample()
    debugOn = true

    if debugOn then print "=== Starting function ==="

    value = 42
    if debugOn then print "Value: "; value

    ' Print object contents
    obj = { name: "test", count: 10 }
    if debugOn then print "Object: "; FormatJson(obj)

    ' Print type information
    if debugOn then print "Type: "; type(obj)
End Sub

' Advanced debug helper with type detection and formatting
Function Debug(label As String, value As Dynamic) As Void
    timestamp = CreateObject("roDateTime").ToIsoString()

    if type(value) = "roAssociativeArray" or type(value) = "roArray" then
        print "[" + timestamp + "] " + label + ": " + FormatJson(value)
    else if value = invalid then
        print "[" + timestamp + "] " + label + ": invalid"
    else
        print "[" + timestamp + "] " + label + ": " + value.ToStr()
    end if
End Function
```

### Using STOP and Debugger

These debugger examples demonstrate interactive debugging techniques: strategic breakpoint placement with the STOP statement for execution suspension, debugger command usage including continue, step, and print commands for interactive debugging, and conditional breakpoints for targeted debugging when specific conditions are met:

```brightscript
Sub DebuggingWithStop()
    x = 10
    y = 20

    ' Insert breakpoint
    stop  ' Drops into debugger

    ' Continue execution with 'cont' command
    ' Step with 'step' command
    ' Print variables with 'print' command

    result = x + y
    print result
End Sub

' Conditional breakpoint for targeted debugging
Sub ConditionalBreak(value As Integer)
    for i = 1 to 100
        if i = value then
            stop  ' Break when condition met
        end if

        ' Process...
    end for
End Sub
```

### Performance Profiling

These performance measurement examples demonstrate optimization techniques: execution time measurement using roTimespan for function benchmarking, memory usage monitoring with device info retrieval for resource tracking, and storage space monitoring for capacity management and performance optimization:

```brightscript
' Simple timer for performance measurement
Function TimeFunction(func As Function, args As Dynamic) As Integer
    startTime = CreateObject("roTimespan")
    startTime.Mark()

    ' Execute function
    result = func(args)

    elapsed = startTime.TotalMilliseconds()
    print "Execution time: " + elapsed.ToStr() + "ms"

    return elapsed
End Function

' System resource monitoring for performance analysis
Sub CheckMemoryUsage()
    deviceInfo = CreateObject("roDeviceInfo")

    ' Get memory info
    memInfo = deviceInfo.GetGeneralMemoryLevel()
    print "Memory level: " + memInfo.level

    ' Get storage info
    storage = CreateObject("roStorageInfo", "/")
    print "Free space: " + storage.GetFreeSpace().ToStr() + " bytes"
    print "Used space: " + storage.GetUsedSpace().ToStr() + " bytes"
End Sub
```

### Logging System

This comprehensive logging system demonstrates production-ready diagnostic capabilities: hierarchical log level management with DEBUG/INFO/WARN/ERROR priorities, timestamp-based log entry formatting for audit trails, dual output to console and file for comprehensive logging, method-specific logging functions for convenience, and practical usage patterns for error handling and application monitoring:

> **See also:** [26-debug-logging-system.brs](examples/26-debug-logging-system.brs) for a complete working example.

```brightscript
' Create logging system
Function CreateLogger(logFile As String) As Object
    return {
        logFile: logFile,
        logLevel: "INFO",  ' DEBUG, INFO, WARN, ERROR

        setLevel: Function(level As String) As Void
            m.logLevel = level
        End Function,

        log: Function(level As String, message As String) As Void
            levels = { "DEBUG": 0, "INFO": 1, "WARN": 2, "ERROR": 3 }

            if levels[level] >= levels[m.logLevel] then
                timestamp = CreateObject("roDateTime").ToIsoString()
                logEntry = timestamp + " [" + level + "] " + message

                ' Print to console
                print logEntry

                ' Write to file
                AppendAsciiFile(m.logFile, logEntry + chr(10))
            end if
        End Function,

        debug: Function(msg As String) As Void
            m.log("DEBUG", msg)
        End Function,

        info: Function(msg As String) As Void
            m.log("INFO", msg)
        End Function,

        warn: Function(msg As String) As Void
            m.log("WARN", msg)
        End Function,

        error: Function(msg As String) As Void
            m.log("ERROR", msg)
        End Function
    }
End Function

' Production logging usage with error handling
Sub Main()
    logger = CreateLogger("app.log")
    logger.setLevel("DEBUG")

    logger.info("Application started")
    logger.debug("Initializing components")

    ' Error handling with logging
    result = TrySomething()
    if result = invalid then
        logger.error("Operation failed")
    else
        logger.info("Operation successful")
    end if
End Sub
```

---

## Appendix: Complete Example Application

Here's a complete BrightScript application that demonstrates many of the concepts covered:

```brightscript
' ========================================
' Media Player Application
' ========================================

Library "core/setupCore.brs"

Sub Main()
    ' Initialize application
    app = CreateMediaPlayerApp()
    app.Run()
End Sub

Function CreateMediaPlayerApp() As Object
    app = {
        ' Properties
        msgPort: CreateObject("roMessagePort"),
        videoPlayer: invalid,
        audioPlayer: invalid,
        imagePlayer: invalid,
        currentMedia: invalid,
        playlist: [],
        settings: invalid,
        logger: invalid,

        ' Methods
        Run: MediaPlayerApp_Run,
        Initialize: MediaPlayerApp_Initialize,
        LoadPlaylist: MediaPlayerApp_LoadPlaylist,
        PlayNext: MediaPlayerApp_PlayNext,
        HandleEvent: MediaPlayerApp_HandleEvent,
        Cleanup: MediaPlayerApp_Cleanup
    }

    return app
End Function

Sub MediaPlayerApp_Run()
    m.Initialize()

    ' Main event loop
    while true
        msg = wait(100, m.msgPort)

        if msg <> invalid then
            if not m.HandleEvent(msg) then
                exit while
            end if
        end if
    end while

    m.Cleanup()
End Sub

Sub MediaPlayerApp_Initialize()
    ' Setup logging
    m.logger = CreateLogger("media_player.log")
    m.logger.info("Media Player starting...")

    ' Load settings
    m.settings = CreateSettingsManager()
    volume = Val(m.settings.get("volume", "75"))

    ' Create media players
    m.videoPlayer = CreateObject("roVideoPlayer")
    m.videoPlayer.SetPort(m.msgPort)
    m.videoPlayer.SetVolume(volume)

    m.audioPlayer = CreateObject("roAudioPlayer")
    m.audioPlayer.SetPort(m.msgPort)
    m.audioPlayer.SetVolume(volume)

    m.imagePlayer = CreateObject("roImagePlayer")

    ' Load playlist
    m.LoadPlaylist()

    ' Start playback
    if m.playlist.Count() > 0 then
        m.PlayNext()
    end if

    m.logger.info("Initialization complete")
End Sub

Sub MediaPlayerApp_LoadPlaylist()
    ' Read playlist from file or scan directory
    files = ListDir("/media")

    for each file in files
        if IsMediaFile(file) then
            m.playlist.Push({
                filename: "/media/" + file,
                type: GetMediaType(file)
            })
        end if
    end for

    m.logger.info("Loaded " + m.playlist.Count().ToStr() + " media files")
End Sub

Sub MediaPlayerApp_PlayNext()
    if m.playlist.Count() = 0 then return

    ' Get next media item
    m.currentMedia = m.playlist.Shift()
    m.playlist.Push(m.currentMedia)  ' Add to end for loop

    ' Play based on type
    if m.currentMedia.type = "video" then
        m.logger.info("Playing video: " + m.currentMedia.filename)
        m.videoPlayer.PlayFile(m.currentMedia.filename)

    else if m.currentMedia.type = "audio" then
        m.logger.info("Playing audio: " + m.currentMedia.filename)
        m.audioPlayer.PlayFile(m.currentMedia.filename)

    else if m.currentMedia.type = "image" then
        m.logger.info("Displaying image: " + m.currentMedia.filename)
        m.imagePlayer.DisplayFile(m.currentMedia.filename)

        ' Set timer for image duration
        timer = CreateObject("roTimer")
        timer.SetPort(m.msgPort)
        timer.SetElapsed(10, 0)  ' 10 seconds
        timer.Start()
    end if
End Sub

Function MediaPlayerApp_HandleEvent(msg As Object) As Boolean
    if type(msg) = "roVideoEvent" or type(msg) = "roAudioEvent" then
        if msg.GetInt() = 8 then  ' MediaEnded
            m.logger.info("Media finished")
            m.PlayNext()
        end if

    else if type(msg) = "roTimerEvent" then
        ' Image display timer
        m.logger.info("Image timer expired")
        m.PlayNext()

    else if type(msg) = "roGpioButton" then
        button = msg.GetInt()
        m.logger.info("Button pressed: " + button.ToStr())

        if button = 0 then  ' Next
            m.PlayNext()
        else if button = 12 then  ' Exit
            return false
        end if
    end if

    return true
End Function

Sub MediaPlayerApp_Cleanup()
    m.logger.info("Shutting down...")

    ' Stop playback
    if m.videoPlayer <> invalid then
        m.videoPlayer.Stop()
        m.videoPlayer = invalid
    end if

    if m.audioPlayer <> invalid then
        m.audioPlayer.Stop()
        m.audioPlayer = invalid
    end if

    ' Save settings
    ' m.settings.set("lastPlayed", m.currentMedia.filename)

    m.logger.info("Cleanup complete")
End Sub

' ========================================
' Helper Functions
' ========================================

Function IsMediaFile(filename As String) As Boolean
    extensions = ["mp4", "mov", "mp3", "wav", "jpg", "png"]

    for each ext in extensions
        if filename.Instr("." + ext) > 0 then
            return true
        end if
    end for

    return false
End Function

Function GetMediaType(filename As String) As String
    if filename.Instr(".mp4") > 0 or filename.Instr(".mov") > 0 then
        return "video"
    else if filename.Instr(".mp3") > 0 or filename.Instr(".wav") > 0 then
        return "audio"
    else if filename.Instr(".jpg") > 0 or filename.Instr(".png") > 0 then
        return "image"
    end if

    return "unknown"
End Function

Function CreateLogger(logFile As String) As Object
    ' Logger implementation from earlier...
    return {
        logFile: logFile,
        info: Function(msg As String)
            print "[INFO] " + msg
            AppendAsciiFile(m.logFile, msg + chr(10))
        End Function
    }
End Function

Function CreateSettingsManager() As Object
    ' Settings manager implementation from earlier...
    return {
        section: CreateObject("roRegistrySection", "media_player"),
        get: Function(key As String, defaultValue As String) As String
            if m.section.Exists(key) then
                return m.section.Read(key)
            end if
            return defaultValue
        End Function,
        set: Function(key As String, value As String)
            m.section.Write(key, value)
            m.section.Flush()
        End Function
    }
End Function
```

---

## Quick Reference Card

### Type Suffixes
- `$` - String
- `%` - Integer
- `!` - Float
- `#` - Double

### Common Objects
- `roMessagePort` - Event handling
- `roTimer` - Timing events
- `roArray` - Dynamic arrays
- `roAssociativeArray` - Hash tables
- `roVideoPlayer` - Video playback
- `roAudioPlayer` - Audio playback
- `roNetworkConfiguration` - Network setup
- `roUrlTransfer` - HTTP client
- `roHttpServer` - HTTP server
- `roRegistrySection` - Persistent storage
- `roGpioControlPort` - GPIO/Button input

### Essential Functions
- `CreateObject(type, ...)` - Create object instance
- `print` - Output to console
- `wait(timeout, port)` - Wait for events
- `type(variable)` - Get type of variable
- `sleep(ms)` - Pause execution
- `invalid` - Null/undefined value

### String Functions
- `Len(str)` - Length
- `Left(str, n)` - First n characters
- `Right(str, n)` - Last n characters
- `Mid(str, start, len)` - Substring
- `Instr(str, find)` - Find position
- `UCase(str)` / `LCase(str)` - Case conversion
- `Str(num)` / `Val(str)` - Type conversion

---

This reference manual provides comprehensive coverage of the BrightScript language with practical examples that work on real BrightSign players. Use it as a quick reference and learning guide for developing BrightScript applications.


---

[↑ Part 2: BrightScript Development](README.md) | [Next →](02-practical-development.md)
