# Chapter 4: Debugging BrightScript

[← Back to Part 2: BrightScript Development](README.md) | [↑ Main](../../README.md)

---

## Introduction

Debugging BrightScript applications requires a different approach than traditional desktop or web development. BrightSign players run in embedded environments with limited direct access, making effective debugging techniques essential for development success. This chapter covers comprehensive debugging strategies specific to BrightScript development.

## Console Debugging

### Print Statements

BrightScript provides multiple ways to output debug information to the console:

```brightscript
' Standard print statement
print "Debug message"

' Question mark shorthand
? "Debug message"

' Print with concatenation
print "Value: " + str(myValue)

' Print object inspection
print myObject
```

**Accessing Console Output:**
- Via SSH: `ssh admin@<player-ip>`
- Via Telnet: `telnet <player-ip> 23`
- Via Serial Port: Connect using 3.5mm serial cable

### Variable Inspection

Print variable types and values during runtime:

```brightscript
function debugVariable(name as String, value as Dynamic)
    print "Variable: " + name
    print "Type: " + type(value)
    print "Value: " + formatJson(value)
end function

' Usage
myData = { id: 123, name: "Test" }
debugVariable("myData", myData)
```

### Execution Flow Tracking

Track execution flow through your application:

```brightscript
function trackExecution(functionName as String, action as String)
    timestamp = CreateObject("roDateTime")
    print "[" + timestamp.ToISOString() + "] " + functionName + " - " + action
end function

function processData(data as Object)
    trackExecution("processData", "START")

    ' Processing logic
    result = transformData(data)

    trackExecution("processData", "END")
    return result
end function
```

## Error Handling

### Try/Catch Patterns

Modern BrightScript supports exception handling:

```brightscript
function safeNetworkRequest(url as String) as Object
    try
        transfer = CreateObject("roUrlTransfer")
        transfer.SetUrl(url)
        response = transfer.GetToString()
        return { success: true, data: ParseJson(response) }
    catch e
        print "Network error: " + e.getMessage()
        print "Stack trace: " + formatJson(e.getStack())
        return { success: false, error: e.getMessage() }
    end try
end function
```

### Graceful Failure Handling

Handle failures without crashing the application:

```brightscript
function loadConfiguration() as Object
    defaultConfig = {
        apiUrl: "https://api.example.com"
        timeout: 30000
        retryCount: 3
    }

    try
        configFile = ReadAsciiFile("config.json")
        if configFile <> invalid then
            userConfig = ParseJson(configFile)
            if userConfig <> invalid then
                ' Merge user config with defaults
                for each key in userConfig
                    defaultConfig[key] = userConfig[key]
                end for
            end if
        end if
    catch e
        print "Config load failed, using defaults: " + e.getMessage()
    end try

    return defaultConfig
end function
```

### Runtime Error Detection

Check for invalid values before operations:

```brightscript
function safeArrayAccess(arr as Object, index as Integer) as Dynamic
    if arr = invalid then
        print "ERROR: Array is invalid"
        return invalid
    end if

    if type(arr) <> "roArray" then
        print "ERROR: Not an array, type is: " + type(arr)
        return invalid
    end if

    if index < 0 or index >= arr.Count() then
        print "ERROR: Index " + str(index) + " out of bounds (0-" + str(arr.Count()-1) + ")"
        return invalid
    end if

    return arr[index]
end function
```

## Logging Systems

### Production-Ready Logging with Levels

Implement a comprehensive logging system:

```brightscript
function CreateLogger() as Object
    logger = {
        logLevel: 2  ' 0=ERROR, 1=WARN, 2=INFO, 3=DEBUG
        syslog: CreateObject("roSystemLog")

        error: function(msg as String)
            if m.logLevel >= 0 then
                timestamp = CreateObject("roDateTime").ToISOString()
                logMsg = "[ERROR] " + timestamp + " - " + msg
                print logMsg
                m.syslog.SendLine(logMsg)
            end if
        end function

        warn: function(msg as String)
            if m.logLevel >= 1 then
                timestamp = CreateObject("roDateTime").ToISOString()
                logMsg = "[WARN] " + timestamp + " - " + msg
                print logMsg
                m.syslog.SendLine(logMsg)
            end if
        end function

        info: function(msg as String)
            if m.logLevel >= 2 then
                timestamp = CreateObject("roDateTime").ToISOString()
                logMsg = "[INFO] " + timestamp + " - " + msg
                print logMsg
                m.syslog.SendLine(logMsg)
            end if
        end function

        debug: function(msg as String)
            if m.logLevel >= 3 then
                timestamp = CreateObject("roDateTime").ToISOString()
                logMsg = "[DEBUG] " + timestamp + " - " + msg
                print logMsg
            end if
        end function
    }

    return logger
end function

' Usage
logger = CreateLogger()
logger.info("Application started")
logger.debug("Processing item: " + itemId)
logger.error("Failed to load resource")
```

### Remote Syslog Configuration

Configure remote logging to a syslog server:

```brightscript
function configureRemoteLogging(syslogServer as String)
    registry = CreateObject("roRegistrySection", "networking")
    registry.Write("syslog", syslogServer)
    registry.Flush()

    print "Remote logging configured for: " + syslogServer
end function

' Usage
configureRemoteLogging("192.168.1.100")
' or
configureRemoteLogging("syslog.company.com")
```

### Log Rotation Implementation

Implement basic log rotation for file-based logging:

```brightscript
function RotatingFileLogger() as Object
    logger = {
        logFile: "SD:/logs/app.log"
        maxSize: 1048576  ' 1MB
        maxFiles: 5

        write: function(msg as String)
            timestamp = CreateObject("roDateTime").ToISOString()
            logEntry = timestamp + " - " + msg + chr(10)

            ' Check if rotation needed
            if m.needsRotation() then
                m.rotate()
            end if

            ' Append to current log file
            file = CreateObject("roAppendFile", m.logFile)
            if file <> invalid then
                file.SendLine(logEntry)
                file.Flush()
                file = invalid
            end if
        end function

        needsRotation: function() as Boolean
            info = CreateObject("roFileInfo", m.logFile)
            if info = invalid then return false
            return info.GetSize() > m.maxSize
        end function

        rotate: function()
            ' Shift existing logs
            for i = m.maxFiles - 1 to 1 step -1
                oldFile = m.logFile + "." + str(i)
                newFile = m.logFile + "." + str(i + 1)
                if CreateObject("roFileInfo", oldFile).Exists() then
                    MoveFile(oldFile, newFile)
                end if
            end for

            ' Move current to .1
            if CreateObject("roFileInfo", m.logFile).Exists() then
                MoveFile(m.logFile, m.logFile + ".1")
            end if
        end function
    }

    return logger
end function
```

## Network Diagnostics

### Connection Testing

Test network connectivity before operations:

```brightscript
function testNetworkConnection(host as String) as Boolean
    nc = CreateObject("roNetworkConfiguration", 0)
    if nc = invalid then return false

    ' Check if interface is up
    config = nc.GetCurrentConfig()
    if config.ip4_address = "" then
        print "No IP address assigned"
        return false
    end if

    print "IP: " + config.ip4_address
    print "Gateway: " + config.ip4_gateway

    ' Test DNS resolution
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetUrl("http://" + host)

    return true
end function
```

### API Debugging with Headers

Debug API requests with detailed logging:

```brightscript
function debugApiRequest(url as String, headers as Object) as Object
    print "=== API Request ==="
    print "URL: " + url
    print "Headers:"
    for each key in headers
        print "  " + key + ": " + headers[key]
    end for

    transfer = CreateObject("roUrlTransfer")
    transfer.SetUrl(url)
    transfer.RetainBodyOnError(true)

    ' Add headers
    for each key in headers
        transfer.AddHeader(key, headers[key])
    end for

    ' Synchronous request for debugging
    responseCode = transfer.GetToString()

    print "=== API Response ==="
    print "Response: " + str(responseCode)

    return { code: responseCode, body: transfer.GetString() }
end function
```

### Timeout Handling

Implement custom timeout logic:

```brightscript
function requestWithTimeout(url as String, timeoutMs as Integer) as Object
    port = CreateObject("roMessagePort")
    transfer = CreateObject("roUrlTransfer")
    transfer.SetUrl(url)
    transfer.SetPort(port)

    startTime = CreateObject("roTimeSpan")
    startTime.Mark()

    if transfer.AsyncGetToString() then
        while true
            msg = wait(1000, port)

            if msg <> invalid then
                if type(msg) = "roUrlEvent" then
                    if msg.GetResponseCode() > 0 then
                        return {
                            success: true
                            code: msg.GetResponseCode()
                            data: msg.GetString()
                        }
                    end if
                end if
            end if

            ' Check timeout
            if startTime.TotalMilliseconds() > timeoutMs then
                transfer.AsyncCancel()
                return { success: false, error: "timeout" }
            end if
        end while
    end if

    return { success: false, error: "request_failed" }
end function
```

## Registry Debugging

### Configuration Inspection

Inspect registry settings:

```brightscript
function dumpRegistry()
    print "=== Registry Dump ==="

    registry = CreateObject("roRegistry")
    sections = registry.GetSectionList()

    for each sectionName in sections
        print "Section: " + sectionName
        section = CreateObject("roRegistrySection", sectionName)
        keys = section.GetKeyList()

        for each key in keys
            value = section.Read(key)
            print "  " + key + " = " + value
        end for
    end for

    print "=== End Registry Dump ==="
end function
```

### Persistent State Analysis

Debug state persistence issues:

```brightscript
function debugRegistryState(sectionName as String)
    section = CreateObject("roRegistrySection", sectionName)

    if section = invalid then
        print "Registry section '" + sectionName + "' does not exist"
        return
    end if

    print "=== Registry Section: " + sectionName + " ==="
    keys = section.GetKeyList()

    if keys.Count() = 0 then
        print "No keys in section"
        return
    end if

    for each key in keys
        value = section.Read(key)
        print key + " = " + value + " (length: " + str(len(value)) + ")"
    end for
end function

function validateRegistryWrite(section as String, key as String, value as String)
    reg = CreateObject("roRegistrySection", section)

    ' Write value
    success = reg.Write(key, value)
    print "Write " + key + " = " + value + ": " + str(success)

    ' Flush to storage
    flushSuccess = reg.Flush()
    print "Flush success: " + str(flushSuccess)

    ' Read back to verify
    readValue = reg.Read(key)
    print "Read back: " + readValue

    if readValue = value then
        print "Registry write/read verified"
    else
        print "ERROR: Registry mismatch!"
    end if
end function
```

## Media Debugging

### Playback Issue Diagnosis

Debug video and audio playback:

```brightscript
function debugMediaPlayback(player as Object, filePath as String)
    print "=== Media Playback Debug ==="
    print "File: " + filePath

    ' Check file existence
    fileInfo = CreateObject("roFileInfo", filePath)
    if not fileInfo.Exists() then
        print "ERROR: File does not exist"
        return
    end if

    print "File size: " + str(fileInfo.GetSize()) + " bytes"

    ' Check playability
    playability = player.GetFilePlayability(filePath)
    print "Playability:"
    print "  Video: " + playability.video
    print "  Audio: " + playability.audio
    print "  File: " + playability.file

    if playability.video <> "playable" then
        print "WARNING: Video may not be playable"
    end if
end function
```

### Format Compatibility Check

Verify media format support:

```brightscript
function checkMediaCompatibility(filePath as String) as Object
    player = CreateObject("roVideoPlayer")

    ' Probe the file
    probe = player.ProbeFile(filePath)

    if probe = invalid then
        return { compatible: false, error: "probe_failed" }
    end if

    result = {
        compatible: true
        videoFormat: probe.VideoFormat
        audioFormat: probe.AudioFormat
        width: probe.VideoWidth
        height: probe.VideoHeight
        duration: probe.VideoDuration
    }

    print "Media Info:"
    print "  Video: " + result.videoFormat + " (" + str(result.width) + "x" + str(result.height) + ")"
    print "  Audio: " + result.audioFormat
    print "  Duration: " + str(result.duration) + "ms"

    return result
end function
```

### Event Troubleshooting

Debug media player events:

```brightscript
function debugMediaEvents()
    port = CreateObject("roMessagePort")
    player = CreateObject("roVideoPlayer")
    player.SetPort(port)

    player.PlayFile("video.mp4")

    while true
        msg = wait(0, port)

        if type(msg) = "roVideoEvent" then
            eventType = msg.GetInt()

            if eventType = 8 then
                print "Event: Media Ended"
                exit while
            else if eventType = 13 then
                position = msg.GetInfo()
                print "Event: Position - " + str(position) + "ms"
            else if eventType = 15 then
                print "Event: Playback Failure"
                print "Message: " + msg.GetMessage()
                print "Data: " + formatJson(msg.GetData())
                exit while
            else
                print "Event: " + str(eventType)
            end if
        end if
    end while
end function
```

## Performance Analysis

### Memory Usage Monitoring

Track memory consumption:

```brightscript
function logMemoryUsage(context as String)
    gc = RunGarbageCollector()

    print "=== Memory Usage: " + context + " ==="
    print "Objects freed: " + str(gc.freed)
    print "Orphaned: " + str(gc.orphaned)
    print "Uptime: " + str(UpTime(0)) + "s"
end function

' Usage in application
logMemoryUsage("Application Start")
' ... perform operations ...
logMemoryUsage("After Data Load")
```

### Execution Timing

Measure function execution time:

```brightscript
function TimedExecution(functionName as String) as Object
    return {
        name: functionName
        timer: CreateObject("roTimeSpan")

        start: function()
            m.timer.Mark()
            print "TIMING [" + m.name + "] START"
        end function

        stop: function()
            elapsed = m.timer.TotalMilliseconds()
            print "TIMING [" + m.name + "] END - " + str(elapsed) + "ms"
            return elapsed
        end function
    }
end function

' Usage
function processLargeDataset(data as Object)
    timer = TimedExecution("processLargeDataset")
    timer.start()

    ' Processing logic
    result = []
    for each item in data
        result.push(transformItem(item))
    end for

    timer.stop()
    return result
end function
```

### Optimization Techniques

Identify and optimize bottlenecks:

```brightscript
function optimizedLoop(items as Object) as Object
    timer = CreateObject("roTimeSpan")
    timer.Mark()

    count = items.Count()
    result = CreateObject("roArray", count, true)  ' Pre-allocate

    for i = 0 to count - 1
        result[i] = processItem(items[i])
    end for

    elapsed = timer.TotalMilliseconds()
    print "Processed " + str(count) + " items in " + str(elapsed) + "ms"
    print "Average: " + str(elapsed / count) + "ms per item"

    return result
end function
```

## Event System Debugging

### Message Port Inspection

Debug message port events:

```brightscript
function debugMessagePort(port as Object, timeoutMs as Integer)
    print "=== Message Port Debug (timeout: " + str(timeoutMs) + "ms) ==="

    startTime = CreateObject("roTimeSpan")
    startTime.Mark()

    eventCount = 0

    while startTime.TotalMilliseconds() < timeoutMs
        msg = port.GetMessage()

        if msg <> invalid then
            eventCount = eventCount + 1
            print "Event #" + str(eventCount) + ":"
            print "  Type: " + type(msg)

            if type(msg) = "roUrlEvent" then
                print "  Response Code: " + str(msg.GetResponseCode())
            else if type(msg) = "roVideoEvent" then
                print "  Event Code: " + str(msg.GetInt())
            else if type(msg) = "roTimerEvent" then
                print "  Timer ID: " + str(msg.GetSourceIdentity())
            end if
        else
            sleep(100)
        end if
    end while

    print "Total events received: " + str(eventCount)
end function
```

### Timer Identity Verification

Verify timer event sources:

```brightscript
function createIdentifiedTimer(id as String, intervalMs as Integer, port as Object) as Object
    timer = CreateObject("roTimer")
    timer.SetPort(port)
    timer.SetUserData({ id: id })

    print "Created timer: " + id + " (identity: " + str(timer.GetIdentity()) + ")"

    return timer
end function

function handleTimerEvents()
    port = CreateObject("roMessagePort")

    timer1 = createIdentifiedTimer("refresh", 5000, port)
    timer2 = createIdentifiedTimer("heartbeat", 1000, port)

    timer1.Start()
    timer2.Start()

    while true
        msg = wait(0, port)

        if type(msg) = "roTimerEvent" then
            userData = msg.GetUserData()
            if userData <> invalid then
                print "Timer fired: " + userData.id
            else
                print "Unknown timer: " + str(msg.GetSourceIdentity())
            end if
        end if
    end while
end function
```

## Object Reference Debugging

### "m" Scope Issues

Debug scope-related problems:

```brightscript
function DebugScope() as Object
    obj = {
        name: "TestObject"
        data: { value: 42 }

        printScope: function()
            print "=== Scope Debug ==="
            print "Object name: " + m.name
            print "Has data: " + str(m.data <> invalid)

            ' Check for common scope issues
            if m.global <> invalid then
                print "WARNING: 'global' reference in scope"
            end if

            ' Print all members
            for each key in m
                print "  " + key + ": " + type(m[key])
            end for
        end function

        testMethod: function()
            ' This will work
            print m.data.value

            ' This would fail if m is not used
            ' print data.value  ' ERROR
        end function
    }

    return obj
end function
```

### Circular Reference Detection

Identify and prevent circular references:

```brightscript
function detectCircularReference(obj as Object, visited = invalid as Object) as Boolean
    if visited = invalid then
        visited = {}
    end if

    objId = str(obj)

    if visited[objId] <> invalid then
        print "CIRCULAR REFERENCE DETECTED!"
        return true
    end if

    visited[objId] = true

    if type(obj) = "roAssociativeArray" then
        for each key in obj
            if type(obj[key]) = "roAssociativeArray" or type(obj[key]) = "roArray" then
                if detectCircularReference(obj[key], visited) then
                    print "  via key: " + key
                    return true
                end if
            end if
        end for
    else if type(obj) = "roArray" then
        for i = 0 to obj.Count() - 1
            if type(obj[i]) = "roAssociativeArray" or type(obj[i]) = "roArray" then
                if detectCircularReference(obj[i], visited) then
                    print "  via index: " + str(i)
                    return true
                end if
            end if
        end for
    end if

    return false
end function
```

### Memory Leak Prevention

Best practices to avoid memory leaks:

```brightscript
function SafeObjectCleanup() as Object
    manager = {
        resources: []

        addResource: function(resource as Object)
            m.resources.push(resource)
        end function

        cleanup: function()
            print "Cleaning up " + str(m.resources.Count()) + " resources"

            ' Clean up in reverse order
            for i = m.resources.Count() - 1 to 0 step -1
                resource = m.resources[i]

                ' Clear message ports
                if resource.SetPort <> invalid then
                    resource.SetPort(invalid)
                end if

                ' Stop active operations
                if resource.Stop <> invalid then
                    resource.Stop()
                end if

                ' Nullify reference
                m.resources[i] = invalid
            end for

            m.resources.Clear()

            ' Force garbage collection
            gc = RunGarbageCollector()
            print "GC freed " + str(gc.freed) + " objects"
        end function
    }

    return manager
end function

' Usage pattern
function runApplication()
    manager = SafeObjectCleanup()

    player = CreateObject("roVideoPlayer")
    manager.addResource(player)

    timer = CreateObject("roTimer")
    manager.addResource(timer)

    ' ... use resources ...

    ' Clean up when done
    manager.cleanup()
    manager = invalid
end function
```

## BrightScript Debugger

### Interactive Debugging

Enable and use the BrightScript debugger:

```brightscript
' Enable debugger via registry
function enableDebugger()
    reg = CreateObject("roRegistrySection", "brightscript")
    reg.Write("debug", "1")
    reg.Flush()
    print "Debugger enabled - will break on STOP statements"
end function

' Set breakpoints with STOP
function debugFunction(data as Object)
    print "Before processing"

    STOP  ' Debugger will break here

    result = processData(data)

    return result
end function
```

### Debugger Commands

Common debugger commands:
- `bt` - Print backtrace of function calls
- `step` or `s` - Step one statement
- `cont` or `c` - Continue execution
- `var` - Display local variables
- `print <expr>` or `? <expr>` - Evaluate expression
- `list` - Show current source code
- `gc` - Run garbage collector and show stats
- `exit` - Exit debugger

### Runtime Inspection

Inspect variables during execution:

```
BrightScript Debugger> var
Local Variables:
data = <Component: roAssociativeArray>
result = <Component: roArray>
index = 5

BrightScript Debugger> ? data.count()
10

BrightScript Debugger> ? result[0]
{id: 1, name: "test"}
```

## Best Practices

1. **Always use logging levels** - Separate debug, info, warning, and error messages
2. **Include timestamps** - Essential for correlating events in production
3. **Log context, not just errors** - Include relevant state information
4. **Clean up resources** - Always clear message ports and stop timers
5. **Avoid circular references** - Never create bidirectional object references
6. **Use try/catch judiciously** - Don't hide important errors
7. **Monitor memory usage** - Run garbage collector periodically in long-running apps
8. **Test error paths** - Ensure graceful degradation when resources fail
9. **Validate external data** - Check API responses and file contents before use
10. **Disable debugger in production** - Prevent unexpected hangs on errors

## Debugging Checklist

When troubleshooting issues:

- [ ] Check console output for print statements and errors
- [ ] Verify file paths and permissions
- [ ] Confirm network connectivity and API availability
- [ ] Inspect registry values for configuration issues
- [ ] Review media file formats and playability
- [ ] Monitor memory usage and run garbage collector
- [ ] Verify message port event handling
- [ ] Check for circular references in object graphs
- [ ] Test timeout and error handling paths
- [ ] Use debugger to step through problem areas

## Conclusion

Effective debugging in BrightScript requires understanding the event-driven architecture, proper resource management, and leveraging available tools like logging systems and the BrightScript debugger. By following these practices and using the provided code examples, you can diagnose and resolve issues efficiently in your BrightSign applications.

## Next Steps

Continue to [Chapter 5: Plugin Architecture](../chapter05-plugin-architecture/) to learn advanced modular programming patterns for building maintainable BrightScript applications.


---

[← Previous](02-practical-development.md) | [↑ Part 2: BrightScript Development](README.md) | [Next →](04-design-patterns.md)
