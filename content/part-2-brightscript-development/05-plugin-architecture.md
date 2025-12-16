# Chapter 5: Plugin Architecture

[← Back to Part 2: BrightScript Development](README.md) | [↑ Main](../../README.md)

---

## Advanced Modular Programming Patterns

This chapter explores advanced modular programming patterns for building scalable, maintainable BrightScript applications. Based on real-world BrightSign production systems, these patterns enable clean separation of concerns, robust inter-plugin communication, and flexible extensibility.

## Core Architecture Principles

### Library-Based Plugin System

BrightScript plugins are organized as separate library files included using the `Library` statement:

```brightscript
Library "setupCommon.brs"
Library "setupNetworkDiagnostics.brs"

Sub Main()
    ' Plugin functionality now available
    diagnostics = newDiagnostics(sysFlags)
    networking = newNetworking(Setup)
End Sub
```

File organization pattern:
```
project/
├── setupCommon.brs           # Core utilities and shared functions
├── setupNetworkDiagnostics.brs  # Network-specific functionality
├── autorun-setup.brs         # Main application entry point
└── current-sync.json         # Configuration data
```

## Factory Pattern

### Plugin Creation Convention

Plugins are created using factory functions with a consistent "new" prefix naming convention:

```brightscript
Function newDiagnostics(sysFlags as object) as object
    diagnostics = {}

    ' Plugin properties
    diagnostics.debug = sysFlags.debugOn
    diagnostics.systemLogDebug = sysFlags.systemLogDebugOn

    ' System resources
    if diagnostics.systemLogDebug then
        diagnostics.systemLog = CreateObject("roSystemLog")
    end if

    ' Plugin methods
    diagnostics.PrintDebug = PrintDebug
    diagnostics.PrintTimestamp = PrintTimestamp
    diagnostics.SetSystemInfo = SetSystemInfo
    diagnostics.TurnDebugOn = TurnDebugOn

    return diagnostics
end function
```

### Advanced Factory with Dependencies

```brightscript
Function newNetworking(Setup as object) as object
    networking = CreateObject("roAssociativeArray")

    ' Dependency injection
    networking.systemTime = Setup.systemTime
    networking.diagnostics = Setup.diagnostics
    networking.msgPort = Setup.msgPort

    ' Plugin-specific properties
    networking.uploadLogFileURLXfer = CreateObject("roUrlTransfer")
    networking.uploadLogFileURLXfer.SetPort(networking.msgPort)
    networking.assetPool = CreateObject("roAssetPool", "pool")

    ' Plugin constants
    networking.POOL_EVENT_FILE_DOWNLOADED = 1
    networking.POOL_EVENT_FILE_FAILED = -1
    networking.URL_EVENT_COMPLETE = 1

    ' Method assignment
    networking.InitializeNetworkDownloads = InitializeNetworkDownloads
    networking.StartSync = StartSync
    networking.URLEvent = URLEvent
    networking.PoolEvent = PoolEvent

    return networking
end function
```

## Dependency Injection

### Cross-Plugin Communication

Parent objects are passed to child plugins to enable resource sharing and cross-referencing:

```brightscript
Function newSetup(diagnostics as object) as object
    Setup = {}

    ' Core system resources
    Setup.diagnostics = diagnostics
    Setup.systemTime = CreateObject("roSystemTime")
    Setup.msgPort = CreateObject("roMessagePort")

    ' Plugin factory functions
    Setup.newLogging = newLogging
    Setup.newNetworking = newNetworking

    ' Plugin instantiation
    Setup.logging = Setup.newLogging()
    Setup.networking = Setup.newNetworking(Setup)

    ' Cross-plugin references
    Setup.logging.networking = Setup.networking

    ' Master plugin methods
    Setup.SetSystemInfo = SetupSetSystemInfo
    Setup.EventLoop = EventLoop

    return Setup
end function
```

### Propagating State Across Plugins

```brightscript
Sub SetupSetSystemInfo(sysInfo as object, diagnosticCodes as object)
    ' Propagate system info to all plugins
    m.diagnostics.SetSystemInfo(sysInfo, diagnosticCodes)
    m.networking.SetSystemInfo(sysInfo, diagnosticCodes)
    m.logging.SetSystemInfo(sysInfo, diagnosticCodes)
end sub
```

## Event-Driven Architecture

### Central Message Port Pattern

A single message port routes events to appropriate plugins:

```brightscript
Sub EventLoop()
    while true
        msg = wait(0, m.msgPort)

        ' Route events to appropriate plugins
        if (type(msg) = "roUrlEvent") then
            m.networking.URLEvent(msg)

        else if (type(msg) = "roSyncPoolEvent") then
            m.networking.PoolEvent(msg)

        else if (type(msg) = "roTimerEvent") then
            ' Critical: Timer identity verification for plugin events
            if type(m.networking.checkAlarm) = "roTimer" and stri(msg.GetSourceIdentity()) = stri(m.networking.checkAlarm.GetIdentity()) then
                m.networking.StartSync()
            else if type(m.networking.registrationResponseTimer) = "roTimer" and stri(msg.GetSourceIdentity()) = stri(m.networking.registrationResponseTimer.GetIdentity()) then
                m.networking.HandleRegistrationTimeout()
            end if

            ' Route to logging plugin
            if type(m.logging) = "roAssociativeArray" then
                if type(m.logging.cutoverTimer) = "roTimer" then
                    if msg.GetSourceIdentity() = m.logging.cutoverTimer.GetIdentity() then
                        m.logging.HandleTimerEvent(msg)
                    end if
                end if
            end if

        else if (type(msg) = "roDatagramEvent") and IsString(msg.GetUserData()) and msg.GetUserData() = "bootstrap" then
            ' Handle bootstrap messages
            payload = ParseJson(msg.GetString())
            if payload <> invalid and payload.message <> invalid then
                m.networking.ProcessBootstrapMessage(payload)
            end if
        end if
    end while
end sub
```

### Plugin Event Handlers

```brightscript
Sub URLEvent(msg as object)
    m.diagnostics.PrintTimestamp()
    m.diagnostics.PrintDebug("### url_event")

    if type(m.xfer) <> "roUrlTransfer" then return
    if msg.GetSourceIdentity() = m.xfer.GetIdentity() then
        if msg.GetInt() = m.URL_EVENT_COMPLETE then
            if msg.GetResponseCode() = 200 then
                m.ProcessSuccessfulDownload()
            else
                m.ProcessDownloadError(msg.GetResponseCode())
            end if
        end if
    end if
end sub
```

### Timer Management

Timer identity verification is critical for routing timer events correctly:

```brightscript
Function CreateTimerManager() as object
    return {
        msgPort: CreateObject("roMessagePort"),
        timers: {},  ' Plugin state storage

        createTimer: Function(name As String, intervalSec As Integer) As Object
            timer = CreateObject("roTimer")
            timer.SetPort(m.msgPort)
            timer.SetElapsed(intervalSec, 0)

            ' Store in plugin state
            m.timers[name] = timer
            return timer
        End Function,

        handleTimerEvent: Function(msg As Object) As String
            ' Use "m" to access plugin state
            for each timerName in m.timers
                timer = m.timers[timerName]
                if type(timer) = "roTimer" then
                    if stri(msg.GetSourceIdentity()) = stri(timer.GetIdentity()) then
                        return timerName
                    end if
                end if
            end for
            return "unknown"
        End Function
    }
end function
```

## Service Registration

### Interface Design

Organize plugin capabilities into logical service groups:

```brightscript
Function newLogging() as object
    logging = CreateObject("roAssociativeArray")

    ' File management services
    logging.CreateLogFile = CreateLogFile
    logging.MoveExpiredCurrentLog = MoveExpiredCurrentLog
    logging.MoveCurrentLog = MoveCurrentLog
    logging.OpenOrCreateCurrentLog = OpenOrCreateCurrentLog
    logging.DeleteExpiredFiles = DeleteExpiredFiles
    logging.FlushLogFile = FlushLogFile

    ' Logging services
    logging.WritePlaybackLogEntry = WritePlaybackLogEntry
    logging.WriteEventLogEntry = WriteEventLogEntry
    logging.WriteDiagnosticLogEntry = WriteDiagnosticLogEntry

    ' Configuration services
    logging.InitializeLogging = InitializeLogging
    logging.ReinitializeLogging = ReinitializeLogging
    logging.InitializeCutoverTimer = InitializeCutoverTimer

    ' Event handling services
    logging.HandleTimerEvent = HandleLoggingTimerEvent
    logging.CutoverLogFile = CutoverLogFile
    logging.PushLogFilesOnBoot = PushLogFilesOnBoot

    return logging
end function
```

### Capability Organization

Group related functionality into sub-interfaces:

```brightscript
' Group related functionality into logical services
networking.fileServices = {
    UploadLogFiles: UploadLogFiles
    UploadLogFileHandler: UploadLogFileHandler
    GetContentDisposition: GetContentDisposition
}

networking.eventServices = {
    SendError: SendError
    SendEvent: SendEvent
    SendErrorCommon: SendErrorCommon
    SendEventCommon: SendEventCommon
}

networking.syncServices = {
    StartSync: StartSync
    URLEvent: URLEvent
    PoolEvent: PoolEvent
    SetPoolSizes: SetPoolSizes
}
```

## Resource Management

### Memory Cleanup Pattern

Proper cleanup is essential for long-running applications:

```brightscript
Sub Cleanup()
    ' Set plugin objects to invalid for garbage collection
    m.videoPlayer = invalid
    m.audioPlayer = invalid
    m.imagePlayer = invalid
    m.networking = invalid
    m.logging = invalid
    m.diagnostics = invalid

    ' Clear plugin arrays and collections
    m.dataArray.Clear()
    m.eventQueue.Clear()
    m.timerCollection.Clear()

    ' Run garbage collector for circular references
    RunGarbageCollector()
End Sub
```

### Lifecycle Management

Manage resource allocation and deallocation systematically:

```brightscript
Function CreateManagedPlugin(pluginType as string) as object
    plugin = {}
    plugin.resources = []
    plugin.timers = []

    plugin.addResource = Function(resource as object, resourceType as string)
        m.resources.Push({resource: resource, type: resourceType})
    End Function

    plugin.cleanup = Function()
        ' Clean up all managed resources
        for each item in m.resources
            if item.type = "timer" and type(item.resource) = "roTimer" then
                item.resource.Stop()
            else if item.type = "file" and type(item.resource) = "roCreateFile" then
                item.resource.Flush()
            end if
            item.resource = invalid
        end for
        m.resources.Clear()
    End Function

    return plugin
end function
```

### Garbage Collection

Handle circular references between plugins:

```brightscript
' Set plugin references to invalid for garbage collection
m.childPlugin = invalid

' Clear plugin collections
m.pluginArray.Clear()
m.pluginRegistry = {}

' Run garbage collector for circular references
RunGarbageCollector()
```

## Configuration-Driven Design

### External Configuration

Load plugin settings from external configuration files:

```brightscript
Sub ParseAutoplayCommon(setupParams as object, setup_sync as object)
    ' Plugin configuration from external sync specification
    setupParams.version = setup_sync.LookupMetadata("client", "version")
    setupParams.base = setup_sync.LookupMetadata("client", "base")
    setupParams.dwsEnabled = GetBoolFromNumericString(setup_sync.LookupMetadata("client", "dwsEnabled"))
    setupParams.networkDiagnosticsEnabled = GetBoolFromNumericString(setup_sync.LookupMetadata("client", "networkDiagnosticsEnabled"))
    setupParams.uploadLogFilesAtBoot = GetBoolFromNumericString(setup_sync.LookupMetadata("client", "uploadLogFilesAtBoot"))

    ' Network configuration
    setupParams.useWireless = GetBoolFromNumericString(setup_sync.LookupMetadata("client", "useWireless"))
    setupParams.ssid$ = setup_sync.LookupMetadata("client", "ssid")
    setupParams.passphrase$ = setup_sync.LookupMetadata("client", "passphrase")

    ' Security settings
    setupParams.enableUnsafeAuthentication = setup_sync.LookupMetadata("server", "enableUnsafeAuthentication")
end sub
```

### Plugin Configuration Application

Apply configuration to plugin instances:

```brightscript
Function InitializeNetworkDownloads(setupParams as object) as boolean
    ' Apply configuration to plugin
    m.nextURL$ = setupParams.nextURL$
    m.user$ = setupParams.user$
    m.password$ = GetPassword(setupParams.password$)
    m.enableBasicAuthentication = setupParams.enableBasicAuthentication
    m.uploadLogFileURL$ = setupParams.uploadLogFileURL$

    ' Configure sub-plugins based on parameters
    if setupParams.networkDiagnosticsEnabled then
        PerformNetworkDiagnostics(setupParams.testEthernetEnabled, setupParams.testWirelessEnabled, setupParams.testInternetEnabled)
    end if

    return true
end function
```

### Feature Detection

Dynamically detect available features based on firmware version:

```brightscript
Function newFeatureDetector(featureMinRevs as object) as object
    detector = {
        featureMinRevs: featureMinRevs

        isSupported: Function(featureName$ as string) as boolean
            modelObject = CreateObject("roDeviceInfo")
            fwVersion$ = modelObject.GetVersion()

            featureExists = m.featureMinRevs.DoesExist(featureName$)
            if featureExists then
                featureMinFWRev = m.featureMinRevs[featureName$]
                featureMinFWRevVSFWVersion% = CompareFirmwareVersions(featureMinFWRev, fwVersion$)
                if featureMinFWRevVSFWVersion% <= 0 then
                    return true
                end if
            end if
            return false
        End Function

        getAvailableFeatures: Function() as object
            availableFeatures = []
            for each featureName in m.featureMinRevs
                if m.isSupported(featureName) then
                    availableFeatures.Push(featureName)
                end if
            end for
            return availableFeatures
        End Function
    }

    return detector
end function
```

## State Management with "m" Scope

### Plugin Self-Reference

Plugin methods access their own state through the "m" scope:

```brightscript
Sub PrintDebug(debugStr$ as string)
    ' Validate plugin context
    if type(m) <> "roAssociativeArray" then stop

    ' Access plugin state via "m"
    if m.debug then
        print debugStr$
    end if

    if m.systemLogDebug then
        m.systemLog.SendLine(debugStr$)
    end if
end sub
```

### Plugin Method Patterns

Methods are assigned as references and use "m" to access plugin state:

```brightscript
Function CreateMediaPlayer() as object
    player = {}

    ' Core interface methods
    player.Initialize = MediaPlayer_Initialize
    player.LoadPlaylist = MediaPlayer_LoadPlaylist
    player.PlayNext = MediaPlayer_PlayNext
    player.HandleEvent = MediaPlayer_HandleEvent
    player.Cleanup = MediaPlayer_Cleanup

    ' Plugin-specific methods
    player.SetVolume = MediaPlayer_SetVolume
    player.GetStatus = MediaPlayer_GetStatus
    player.TogglePlayback = MediaPlayer_TogglePlayback

    return player
end function
```

## Plugin Identity and Validation

### Object Type Validation

Always validate object creation:

```brightscript
' Critical validation pattern used throughout production code
registrySection = CreateObject("roRegistrySection", "networking")
if type(registrySection) <> "roRegistrySection" then
    print "Error: Unable to create roRegistrySection"
    stop
end if
```

### Plugin Interface Validation

Verify that plugins implement required methods:

```brightscript
Function ValidatePlugin(plugin as object, requiredMethods as object) as boolean
    if type(plugin) <> "roAssociativeArray" then return false

    for each methodName in requiredMethods
        if not plugin.DoesExist(methodName) then
            print "Plugin missing required method: " + methodName
            return false
        end if
    end for

    return true
end function
```

### Timer Identity Verification

Production pattern for verifying timer identity:

```brightscript
' Always verify timer identity for plugin communication
if (type(msg) = "roTimerEvent") then
    if type(m.networking.checkAlarm) = "roTimer" and stri(msg.GetSourceIdentity()) = stri(m.networking.checkAlarm.GetIdentity()) then
        m.networking.StartSync()
    else if type(m.networking.registrationResponseTimer) = "roTimer" and stri(msg.GetSourceIdentity()) = stri(m.networking.registrationResponseTimer.GetIdentity()) then
        m.networking.HandleRegistrationTimeout()
    end if
end if
```

## Plugin Extension Hooks

### Extension Registration

Allow plugins to be extended dynamically:

```brightscript
Function CreateExtensiblePlugin() as object
    return {
        extensions: {}
        hooks: {}

        registerExtension: Function(name as string, extension as object)
            m.extensions[name] = extension
        End Function

        registerHook: Function(hookName as string, callback as function)
            if not m.hooks.DoesExist(hookName) then
                m.hooks[hookName] = []
            end if
            m.hooks[hookName].Push(callback)
        End Function

        executeHook: Function(hookName as string, data as object)
            if m.hooks.DoesExist(hookName) then
                for each callback in m.hooks[hookName]
                    callback(data)
                end for
            end if
        End Function

        getExtension: Function(name as string) as object
            if m.extensions.DoesExist(name) then
                return m.extensions[name]
            end if
            return invalid
        End Function
    }
end function
```

## Production Patterns

### Complete Plugin System

Real-world example from BrightSign production code:

```brightscript
Library "setupCommon.brs"
Library "setupNetworkDiagnostics.brs"

Sub Main()
    ' Initialize core system
    setupVersion$ = "4.0.0.1"
    debugParams = EnableDebugging("current-sync.json")

    sysFlags = {}
    sysFlags.debugOn = debugParams.serialDebugOn
    sysFlags.systemLogDebugOn = debugParams.systemLogDebugOn

    ' Create plugin system
    diagnostics = newDiagnostics(sysFlags)
    diagnostics.printDebug("setup script version " + setupVersion$ + " started")

    ' Create master plugin container
    Setup = newSetup(diagnostics)

    ' Initialize system info for all plugins
    modelObject = CreateObject("roDeviceInfo")
    sysInfo = CreateObject("roAssociativeArray")
    sysInfo.deviceUniqueID$ = modelObject.GetDeviceUniqueId()
    sysInfo.deviceFWVersion$ = modelObject.GetVersion()
    sysInfo.setupVersion$ = setupVersion$

    Setup.SetSystemInfo(sysInfo, diagnosticCodes)

    ' Configure plugins from external specification
    currentSync = CreateObject("roSyncSpec")
    if currentSync.ReadFromFile("current-sync.json") then
        setupParams = ParseAutoplay(currentSync)

        ' Initialize plugin services
        Setup.networkingActive = Setup.networking.InitializeNetworkDownloads(setupParams)
        Setup.logging.InitializeLogging(false, false, false, setupParams.diagnosticLoggingEnabled, setupParams.variableLoggingEnabled, setupParams.uploadLogFilesAtBoot, setupParams.uploadLogFilesAtSpecificTime, setupParams.uploadLogFilesTime%)

        ' Start plugin event loop
        Setup.EventLoop()
    end if
end sub
```

### Media Player Plugin

Complete plugin implementation example:

```brightscript
Function CreateMediaPlayerPlugin() as object
    return {
        ' Plugin state
        videoPlayer: invalid
        audioPlayer: invalid
        imagePlayer: invalid
        currentMedia: invalid
        playlist: []
        msgPort: CreateObject("roMessagePort")

        ' Plugin interface
        initialize: Function(volume as integer) as void
            m.videoPlayer = CreateObject("roVideoPlayer")
            m.videoPlayer.SetPort(m.msgPort)
            m.videoPlayer.SetVolume(volume)

            m.audioPlayer = CreateObject("roAudioPlayer")
            m.audioPlayer.SetPort(m.msgPort)
            m.audioPlayer.SetVolume(volume)

            m.imagePlayer = CreateObject("roImagePlayer")
        End Function

        loadPlaylist: Function(mediaFiles as object) as void
            m.playlist = []
            for each file in mediaFiles
                if IsMediaFile(file) then
                    m.playlist.Push({
                        filename: file,
                        type: GetMediaType(file)
                    })
                end if
            end for
        End Function

        playNext: Function() as void
            if m.playlist.Count() = 0 then return

            m.currentMedia = m.playlist.Shift()
            m.playlist.Push(m.currentMedia)  ' Loop playlist

            if m.currentMedia.type = "video" then
                m.videoPlayer.PlayFile(m.currentMedia.filename)
            else if m.currentMedia.type = "audio" then
                m.audioPlayer.PlayFile(m.currentMedia.filename)
            else if m.currentMedia.type = "image" then
                m.imagePlayer.DisplayFile(m.currentMedia.filename)
            end if
        End Function

        handleEvent: Function(msg as object) as boolean
            if type(msg) = "roVideoEvent" or type(msg) = "roAudioEvent" then
                if msg.GetInt() = 8 then  ' MediaEnded
                    m.playNext()
                end if
            end if
            return true
        End Function

        cleanup: Function() as void
            if m.videoPlayer <> invalid then
                m.videoPlayer.Stop()
                m.videoPlayer = invalid
            end if
            if m.audioPlayer <> invalid then
                m.audioPlayer.Stop()
                m.audioPlayer = invalid
            end if
            m.imagePlayer = invalid
        End Function
    }
end function
```

## Best Practices

### Naming Conventions

- **Factory Functions**: Use "new" prefix (`newDiagnostics`, `newNetworking`)
- **Plugin Methods**: Use descriptive, action-oriented names
- **Plugin Properties**: Use clear, domain-specific naming
- **Library Files**: Use descriptive names with .brs extension

### Error Handling

Always validate plugin creation and method calls:

```brightscript
' Always validate plugin creation
diagnostics = newDiagnostics(sysFlags)
if type(diagnostics) <> "roAssociativeArray" then
    print "Error: Failed to create diagnostics plugin"
    stop
end if

' Validate plugin methods before calling
if diagnostics.DoesExist("PrintDebug") then
    diagnostics.PrintDebug("Plugin created successfully")
end if
```

### Configuration Management

Use external configuration files for flexibility:

```brightscript
' Use external configuration files
currentSync = CreateObject("roSyncSpec")
if currentSync.ReadFromFile("current-sync.json") then
    setupParams = ParseAutoplay(currentSync)
    ConfigureAllPlugins(setupParams)
end if
```

### Event Loop Design

Single central event loop with plugin routing:

```brightscript
' Single central event loop with plugin routing
Sub EventLoop()
    while true
        msg = wait(0, m.msgPort)

        ' Route to appropriate plugin with identity verification
        if type(msg) = "roTimerEvent" then
            RouterTimerEvent(msg)
        else if type(msg) = "roUrlEvent" then
            m.networking.URLEvent(msg)
        end if
    end while
End Sub
```

### Plugin Testing

Validate plugin functionality systematically:

```brightscript
' Validate plugin functionality
Function TestPlugin(plugin as object) as boolean
    requiredMethods = ["initialize", "process", "cleanup"]

    for each method in requiredMethods
        if not plugin.DoesExist(method) then
            return false
        end if
    end for

    return true
end function
```

### Documentation Standards

- Document plugin interfaces and expected behaviors
- Include usage examples for each plugin
- Document plugin dependencies and requirements
- Maintain plugin version compatibility information

## Summary

BrightScript plugin architecture enables building sophisticated, maintainable applications with:

- **Clean separation of concerns** through library-based modular design
- **Factory pattern** for consistent plugin creation
- **Dependency injection** for resource sharing and cross-plugin communication
- **Event-driven architecture** with central message port routing
- **Service registration** for organized capability interfaces
- **Resource management** with proper lifecycle handling
- **Configuration-driven design** for flexible deployment
- **Production-proven patterns** from real-world BrightSign systems

These patterns scale from simple utilities to complex production systems, providing a solid foundation for professional BrightScript application development.

## Prerequisites

- Chapter 2: BrightScript Language Reference
- Chapter 3: Practical Development
- Chapter 4: Debugging BrightScript

## Next Steps

Continue to [Chapter 6: JavaScript Playback](../chapter06-javascript-playback/) to learn HTML5 and JavaScript development for media applications.


---

[← Previous](04-design-patterns.md) | [↑ Part 2: BrightScript Development](README.md)
