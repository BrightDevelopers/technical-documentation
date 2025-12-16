# Chapter 11: Design Patterns

[← Back to Part 2: BrightScript Development](README.md) | [↑ Main](../../README.md)

---

## Overview

Design patterns are proven solutions to common programming problems. In BrightScript development, these patterns enable you to build maintainable, scalable digital signage applications. This chapter explores key design patterns adapted for BrightScript's unique constraints and capabilities, drawing from production BrightSign systems and modern software architecture principles.

## Table of Contents

1. [Singleton Pattern](#singleton-pattern)
2. [Observer Pattern](#observer-pattern)
3. [Command Pattern](#command-pattern)
4. [State Machine Pattern](#state-machine-pattern)
5. [Factory Pattern](#factory-pattern)
6. [Manager Pattern](#manager-pattern)
7. [Validation Pattern](#validation-pattern)
8. [Best Practices](#best-practices)

---

## Singleton Pattern

### Concept

The Singleton pattern ensures a class has only one instance throughout the application lifecycle, providing a global point of access to shared resources. In BrightScript, this is particularly useful for managing system resources like configuration settings, device information, and logging systems.

### Implementation

```brightscript
' Global singleton instance storage
Function GetApplicationSingleton() As Object
    ' Check if singleton exists in global scope
    if m.global = invalid or m.global.appInstance = invalid then
        ' Initialize global scope if needed
        if m.global = invalid then
            m.global = CreateObject("roAssociativeArray")
        end if

        ' Create singleton instance
        m.global.appInstance = CreateApplicationInstance()
    end if

    return m.global.appInstance
End Function

Function CreateApplicationInstance() As Object
    instance = {
        deviceInfo: CreateObject("roDeviceInfo"),
        systemTime: CreateObject("roSystemTime"),
        config: {},

        ' Singleton methods
        getDeviceID: Function() As String
            return m.deviceInfo.GetDeviceUniqueId()
        End Function,

        getConfiguration: Function(key As String) As Dynamic
            if m.config.DoesExist(key) then
                return m.config[key]
            end if
            return invalid
        End Function,

        setConfiguration: Function(key As String, value As Dynamic) As Void
            m.config[key] = value
        End Function
    }

    return instance
End Function

' Usage
Sub Main()
    ' First access creates the singleton
    app = GetApplicationSingleton()
    app.setConfiguration("debug", true)

    ' Subsequent accesses return the same instance
    sameApp = GetApplicationSingleton()
    debug = sameApp.getConfiguration("debug")  ' Returns true

    print "Device ID: " + app.getDeviceID()
End Sub
```

### Use Cases

- **Global Configuration Management**: Store application-wide settings accessible from any module
- **Device Resource Coordination**: Manage access to device-specific resources (roDeviceInfo, roSystemTime)
- **Logging System**: Centralize log collection and output management
- **Registry Manager**: Single point of access for persistent storage

### Best Practices

1. **Lazy Initialization**: Create the singleton only when first accessed
2. **Thread Safety**: BrightScript is single-threaded, but ensure initialization is atomic
3. **Minimal Global State**: Use singletons sparingly to avoid tight coupling
4. **Clear Lifecycle**: Document when the singleton is created and destroyed

### Common Pitfalls

- **Overuse**: Not everything needs to be a singleton; use for truly global resources
- **Testing Difficulties**: Singletons can make unit testing harder due to shared state
- **Hidden Dependencies**: Other objects may depend on singleton without explicit declaration

---

## Observer Pattern

### Concept

The Observer pattern establishes a one-to-many dependency between objects, where changes in one object (subject) automatically notify all dependent objects (observers). This enables loose coupling and reactive system design, essential for event-driven BrightSign applications.

### Implementation

```brightscript
' Event subject that notifies observers
Function CreateEventSubject() As Object
    return {
        observers: [],

        subscribe: Function(observer As Object) As Void
            ' Validate observer has required method
            if type(observer) = "roAssociativeArray" then
                if observer.DoesExist("onNotify") then
                    m.observers.Push(observer)
                else
                    print "Error: Observer missing onNotify method"
                end if
            end if
        End Function,

        unsubscribe: Function(observer As Object) As Void
            newObservers = []
            for each obs in m.observers
                if obs <> observer then
                    newObservers.Push(obs)
                end if
            end for
            m.observers = newObservers
        End Function,

        notify: Function(eventData As Object) As Void
            for each observer in m.observers
                observer.onNotify(eventData)
            end for
        End Function
    }
End Function

' Observer implementation examples
Function CreateLoggerObserver() As Object
    return {
        onNotify: Function(eventData As Object) As Void
            timestamp = CreateObject("roDateTime").ToIsoString()
            print "[" + timestamp + "] Event: " + eventData.type
            if eventData.DoesExist("message") then
                print "  Message: " + eventData.message
            end if
        End Function
    }
End Function

Function CreateMetricsObserver() As Object
    return {
        eventCount: 0,

        onNotify: Function(eventData As Object) As Void
            m.eventCount = m.eventCount + 1
            print "Total events processed: " + m.eventCount.ToStr()
        End Function
    }
End Function

' Usage
Sub Main()
    ' Create subject
    mediaEvents = CreateEventSubject()

    ' Create and subscribe observers
    logger = CreateLoggerObserver()
    metrics = CreateMetricsObserver()

    mediaEvents.subscribe(logger)
    mediaEvents.subscribe(metrics)

    ' Trigger events - all observers are notified
    mediaEvents.notify({
        type: "VIDEO_STARTED",
        message: "Playing video1.mp4"
    })

    mediaEvents.notify({
        type: "VIDEO_ENDED",
        message: "Video playback complete"
    })
End Sub
```

### Event Bus Pattern

A centralized event bus extends the observer pattern for complex applications:

```brightscript
Function CreateEventBus() As Object
    return {
        msgPort: CreateObject("roMessagePort"),
        subscribers: {},  ' Event type -> [observers]

        subscribe: Function(eventType As String, observer As Object) As Void
            if not m.subscribers.DoesExist(eventType) then
                m.subscribers[eventType] = []
            end if
            m.subscribers[eventType].Push(observer)
        End Function,

        publish: Function(eventType As String, eventData As Object) As Void
            if m.subscribers.DoesExist(eventType) then
                for each observer in m.subscribers[eventType]
                    observer.onNotify(eventData)
                end for
            end if
        End Function,

        unsubscribe: Function(eventType As String, observer As Object) As Void
            if m.subscribers.DoesExist(eventType) then
                newSubscribers = []
                for each obs in m.subscribers[eventType]
                    if obs <> observer then
                        newSubscribers.Push(obs)
                    end if
                end for
                m.subscribers[eventType] = newSubscribers
            end if
        End Function
    }
End Function

' Usage with multiple event types
Sub EventBusExample()
    eventBus = CreateEventBus()

    ' Video observer
    videoObserver = {
        onNotify: Function(data As Object) As Void
            print "Video event: " + data.action
        End Function
    }

    ' Network observer
    networkObserver = {
        onNotify: Function(data As Object) As Void
            print "Network event: " + data.status
        End Function
    }

    ' Subscribe to specific event types
    eventBus.subscribe("VIDEO", videoObserver)
    eventBus.subscribe("NETWORK", networkObserver)

    ' Publish events to specific subscribers
    eventBus.publish("VIDEO", {action: "play"})
    eventBus.publish("NETWORK", {status: "connected"})
End Sub
```

### Use Cases

- **Event Notification Systems**: Notify multiple components when events occur
- **UI Updates**: Update multiple display elements when data changes
- **Plugin Communication**: Allow plugins to communicate without direct coupling
- **State Change Propagation**: Notify interested parties when application state changes

### Best Practices

1. **Define Clear Interfaces**: Observers should implement consistent notification methods
2. **Error Handling**: Protect against observer failures affecting other observers
3. **Memory Management**: Provide unsubscribe mechanism to prevent memory leaks
4. **Event Data Standardization**: Use consistent event data structures

### Common Pitfalls

- **Memory Leaks**: Forgetting to unsubscribe can prevent garbage collection
- **Update Storms**: Too many notifications can impact performance
- **Order Dependencies**: Observers should not depend on notification order

---

## Command Pattern

### Concept

The Command pattern encapsulates requests as objects, enabling parameterization of clients with different requests, queuing of requests, and support for undoable operations. This is valuable for building flexible control systems and action queues in BrightSign applications.

### Implementation

```brightscript
' Command interface - all commands implement execute()
Function CreatePlayVideoCommand(videoPlayer As Object, filename As String) As Object
    return {
        player: videoPlayer,
        file: filename,
        previousState: invalid,

        execute: Function() As Void
            m.previousState = m.player.getState()
            print "Executing: Play video " + m.file
            m.player.playFile(m.file)
        End Function,

        undo: Function() As Void
            if m.previousState <> invalid then
                print "Undoing: Restore state " + m.previousState
                m.player.setState(m.previousState)
            end if
        End Function,

        getName: Function() As String
            return "PlayVideo: " + m.file
        End Function
    }
End Function

Function CreateSetVolumeCommand(player As Object, newVolume As Integer) As Object
    return {
        player: player,
        volume: newVolume,
        previousVolume: player.getVolume(),

        execute: Function() As Void
            print "Executing: Set volume to " + m.volume.ToStr()
            m.player.setVolume(m.volume)
        End Function,

        undo: Function() As Void
            print "Undoing: Restore volume to " + m.previousVolume.ToStr()
            m.player.setVolume(m.previousVolume)
        End Function,

        getName: Function() As String
            return "SetVolume: " + m.volume.ToStr()
        End Function
    }
End Function

' Command invoker with queue and undo support
Function CreateCommandManager() As Object
    return {
        commandQueue: [],
        executedCommands: [],

        addCommand: Function(command As Object) As Void
            m.commandQueue.Push(command)
        End Function,

        executeNext: Function() As Boolean
            if m.commandQueue.Count() = 0 then return false

            command = m.commandQueue.Shift()
            command.execute()
            m.executedCommands.Push(command)

            return true
        End Function,

        executeAll: Function() As Void
            while m.commandQueue.Count() > 0
                m.executeNext()
            end while
        End Function,

        undo: Function() As Boolean
            if m.executedCommands.Count() = 0 then return false

            command = m.executedCommands.Pop()
            command.undo()

            return true
        End Function,

        getHistory: Function() As Object
            history = []
            for each cmd in m.executedCommands
                history.Push(cmd.getName())
            end for
            return history
        End Function,

        clear: Function() As Void
            m.commandQueue = []
            m.executedCommands = []
        End Function
    }
End Function

' Simple player for demonstration
Function CreateSimplePlayer() As Object
    return {
        state: "stopped",
        currentFile: "",
        volume: 50,

        playFile: Function(filename As String) As Void
            m.currentFile = filename
            m.state = "playing"
        End Function,

        setState: Function(newState As String) As Void
            m.state = newState
        End Function,

        getState: Function() As String
            return m.state
        End Function,

        setVolume: Function(level As Integer) As Void
            m.volume = level
        End Function,

        getVolume: Function() As Integer
            return m.volume
        End Function
    }
End Function

' Usage
Sub Main()
    player = CreateSimplePlayer()
    cmdMgr = CreateCommandManager()

    ' Queue commands
    cmdMgr.addCommand(CreatePlayVideoCommand(player, "intro.mp4"))
    cmdMgr.addCommand(CreateSetVolumeCommand(player, 75))
    cmdMgr.addCommand(CreatePlayVideoCommand(player, "main.mp4"))

    ' Execute all commands
    cmdMgr.executeAll()

    ' Show command history
    print "Command history:"
    for each cmd in cmdMgr.getHistory()
        print "  " + cmd
    end for

    ' Undo last two commands
    print "Undoing commands..."
    cmdMgr.undo()
    cmdMgr.undo()
End Sub
```

### Use Cases

- **Action Queuing**: Queue operations to execute sequentially
- **Undo/Redo Functionality**: Support reversible operations
- **Macro Recording**: Record and replay sequences of actions
- **Scheduled Operations**: Schedule commands for delayed execution
- **Remote Control**: Encapsulate remote control button actions

### Best Practices

1. **Command Interface Consistency**: All commands should have execute() method
2. **State Preservation**: Store previous state for undo operations
3. **Command Validation**: Validate command parameters before execution
4. **Clear Naming**: Use descriptive command names for debugging

### Common Pitfalls

- **Incomplete Undo**: Not all operations are easily reversible
- **State Complexity**: Complex state changes may be difficult to undo correctly
- **Memory Overhead**: Storing undo history consumes memory

---

## State Machine Pattern

### Concept

The State Machine pattern manages object behavior that varies based on internal state. Each state encapsulates specific behaviors and transitions to other states based on events. This is essential for managing complex workflows in media playback and system control.

### Implementation

```brightscript
' Basic state machine
Function CreateStateMachine(initialState As String) As Object
    return {
        state: initialState,
        transitions: {},
        stateHandlers: {},

        addTransition: Function(fromState As String, event As String, toState As String) As Void
            key = fromState + ":" + event
            m.transitions[key] = toState
        End Function,

        addStateHandler: Function(state As String, handler As Object) As Void
            m.stateHandlers[state] = handler
        End Function,

        handleEvent: Function(event As String) As Boolean
            key = m.state + ":" + event

            if m.transitions.DoesExist(key) then
                oldState = m.state
                newState = m.transitions[key]

                ' Exit current state
                if m.stateHandlers.DoesExist(oldState) then
                    if m.stateHandlers[oldState].DoesExist("onExit") then
                        m.stateHandlers[oldState].onExit()
                    end if
                end if

                ' Change state
                print "State transition: " + oldState + " -> " + newState + " (event: " + event + ")"
                m.state = newState

                ' Enter new state
                if m.stateHandlers.DoesExist(newState) then
                    if m.stateHandlers[newState].DoesExist("onEnter") then
                        m.stateHandlers[newState].onEnter()
                    end if
                end if

                return true
            else
                print "Invalid transition: " + m.state + " + " + event
                return false
            end if
        End Function,

        getState: Function() As String
            return m.state
        End Function,

        executeStateAction: Function(action As String) As Void
            if m.stateHandlers.DoesExist(m.state) then
                handler = m.stateHandlers[m.state]
                if handler.DoesExist(action) then
                    handler[action]()
                end if
            end if
        End Function
    }
End Function

' Media player state machine example
Function CreateMediaPlayerStateMachine() As Object
    sm = CreateStateMachine("IDLE")

    ' Define transitions
    sm.addTransition("IDLE", "LOAD", "LOADING")
    sm.addTransition("LOADING", "LOADED", "READY")
    sm.addTransition("LOADING", "ERROR", "ERROR")
    sm.addTransition("READY", "PLAY", "PLAYING")
    sm.addTransition("PLAYING", "PAUSE", "PAUSED")
    sm.addTransition("PLAYING", "STOP", "IDLE")
    sm.addTransition("PLAYING", "END", "IDLE")
    sm.addTransition("PAUSED", "RESUME", "PLAYING")
    sm.addTransition("PAUSED", "STOP", "IDLE")
    sm.addTransition("ERROR", "RESET", "IDLE")

    ' Define state handlers
    sm.addStateHandler("IDLE", {
        onEnter: Sub()
            print "[IDLE] Player ready for new content"
        End Sub
    })

    sm.addStateHandler("LOADING", {
        onEnter: Sub()
            print "[LOADING] Loading media content..."
        End Sub
    })

    sm.addStateHandler("PLAYING", {
        onEnter: Sub()
            print "[PLAYING] Media playback started"
        End Sub,
        onExit: Sub()
            print "[PLAYING] Leaving playback state"
        End Sub
    })

    sm.addStateHandler("PAUSED", {
        onEnter: Sub()
            print "[PAUSED] Playback paused"
        End Sub
    })

    sm.addStateHandler("ERROR", {
        onEnter: Sub()
            print "[ERROR] Playback error occurred"
        End Sub
    })

    return sm
End Function

' Advanced state machine with guards
Function CreateGuardedStateMachine() As Object
    return {
        state: "IDLE",
        context: {},  ' Shared state

        transitions: {},
        guards: {},    ' Conditions for transitions

        addTransition: Function(fromState As String, event As String, toState As String, guard As Dynamic) As Void
            key = fromState + ":" + event
            m.transitions[key] = toState
            if guard <> invalid then
                m.guards[key] = guard
            end if
        End Function,

        canTransition: Function(fromState As String, event As String) As Boolean
            key = fromState + ":" + event

            if not m.transitions.DoesExist(key) then
                return false
            end if

            if m.guards.DoesExist(key) then
                ' Check guard condition
                return m.guards[key](m.context)
            end if

            return true
        End Function,

        handleEvent: Function(event As String) As Boolean
            if m.canTransition(m.state, event) then
                key = m.state + ":" + event
                newState = m.transitions[key]
                print "Transition: " + m.state + " -> " + newState
                m.state = newState
                return true
            end if
            return false
        End Function,

        setContext: Function(key As String, value As Dynamic) As Void
            m.context[key] = value
        End Function,

        getContext: Function(key As String) As Dynamic
            if m.context.DoesExist(key) then
                return m.context[key]
            end if
            return invalid
        End Function
    }
End Function

' Usage
Sub Main()
    ' Basic state machine
    playerSM = CreateMediaPlayerStateMachine()

    print "=== Testing Media Player State Machine ==="
    playerSM.handleEvent("LOAD")
    playerSM.handleEvent("LOADED")
    playerSM.handleEvent("PLAY")
    playerSM.handleEvent("PAUSE")
    playerSM.handleEvent("RESUME")
    playerSM.handleEvent("STOP")

    print ""
    print "=== Testing Guarded State Machine ==="

    ' Guarded state machine example
    guardedSM = CreateGuardedStateMachine()

    ' Add transition with guard
    hasPermissionGuard = Function(context As Object) As Boolean
        if context.DoesExist("userLevel") then
            return context.userLevel >= 5
        end if
        return false
    End Function

    guardedSM.addTransition("IDLE", "ADMIN_ACTION", "ADMIN_MODE", hasPermissionGuard)

    ' Try without permission
    guardedSM.setContext("userLevel", 3)
    result = guardedSM.handleEvent("ADMIN_ACTION")
    print "Transition with low permission: " + result.ToStr()

    ' Try with permission
    guardedSM.setContext("userLevel", 7)
    result = guardedSM.handleEvent("ADMIN_ACTION")
    print "Transition with high permission: " + result.ToStr()
End Sub
```

### Use Cases

- **Media Player Control**: Manage playback states (idle, playing, paused, stopped)
- **Download Manager**: Track download lifecycle (queued, downloading, complete, failed)
- **Application Workflow**: Control application startup, running, shutdown sequences
- **Network Connection**: Manage connection states (disconnected, connecting, connected)

### Best Practices

1. **Explicit States**: Define all possible states clearly
2. **Valid Transitions**: Document which state transitions are allowed
3. **Entry/Exit Actions**: Use onEnter/onExit for state setup and cleanup
4. **State Validation**: Validate state transitions before executing
5. **Context Management**: Store shared data in context object

### Common Pitfalls

- **State Explosion**: Too many states make the machine hard to maintain
- **Missing Transitions**: Forgetting valid state transitions causes errors
- **Circular Dependencies**: States should not have circular action dependencies

---

## Factory Pattern

### Concept

The Factory pattern provides an interface for creating objects without specifying their exact class. In BrightScript, factories abstract object creation, enable plugin instantiation, and support dependency injection.

### Implementation

```brightscript
' Basic factory function using "new" prefix convention
Function newLogger(debugEnabled As Boolean) As Object
    return {
        debug: debugEnabled,
        logFile: invalid,

        log: Function(level As String, message As String) As Void
            timestamp = CreateObject("roDateTime").ToIsoString()
            logEntry = "[" + timestamp + "] " + level + ": " + message

            if m.debug then
                print logEntry
            end if

            ' Write to log file if configured
            if m.logFile <> invalid then
                m.logFile.Write(logEntry + chr(10))
                m.logFile.Flush()
            end if
        End Function,

        setLogFile: Function(filename As String) As Void
            m.logFile = CreateObject("roCreateFile", filename)
        End Function
    }
End Function

' Parameterized factory for different player types
Function CreateMediaPlayerFactory() As Object
    return {
        createPlayer: Function(mediaType As String) As Object
            if mediaType = "video" then
                return m.createVideoPlayer()
            else if mediaType = "audio" then
                return m.createAudioPlayer()
            else if mediaType = "image" then
                return m.createImagePlayer()
            else
                print "Error: Unknown media type " + mediaType
                return invalid
            end if
        End Function,

        createVideoPlayer: Function() As Object
            player = CreateObject("roVideoPlayer")
            return {
                nativePlayer: player,
                type: "video",

                play: Function(filename As String) As Boolean
                    return m.nativePlayer.PlayFile(filename)
                End Function,

                stop: Function() As Void
                    m.nativePlayer.Stop()
                End Function,

                setVolume: Function(level As Integer) As Void
                    m.nativePlayer.SetVolume(level)
                End Function
            }
        End Function,

        createAudioPlayer: Function() As Object
            player = CreateObject("roAudioPlayer")
            return {
                nativePlayer: player,
                type: "audio",

                play: Function(filename As String) As Boolean
                    return m.nativePlayer.PlayFile(filename)
                End Function,

                stop: Function() As Void
                    m.nativePlayer.Stop()
                End Function,

                setVolume: Function(level As Integer) As Void
                    m.nativePlayer.SetVolume(level)
                End Function
            }
        End Function,

        createImagePlayer: Function() As Object
            player = CreateObject("roImagePlayer")
            return {
                nativePlayer: player,
                type: "image",

                display: Function(filename As String) As Void
                    m.nativePlayer.DisplayFile(filename)
                End Function,

                stop: Function() As Void
                    ' Image player cleanup
                    m.nativePlayer = invalid
                End Function
            }
        End Function
    }
End Function

' Plugin factory with dependency injection
Function CreatePluginFactory(systemResources As Object) As Object
    return {
        msgPort: systemResources.msgPort,
        diagnostics: systemResources.diagnostics,

        createPlugin: Function(pluginType As String, config As Object) As Object
            ' Validate plugin type
            if pluginType = "network" then
                return m.createNetworkPlugin(config)
            else if pluginType = "logging" then
                return m.createLoggingPlugin(config)
            else if pluginType = "media" then
                return m.createMediaPlugin(config)
            end if

            return invalid
        End Function,

        createNetworkPlugin: Function(config As Object) As Object
            plugin = {
                msgPort: m.msgPort,
                diagnostics: m.diagnostics,
                urlTransfer: CreateObject("roUrlTransfer"),
                config: config,

                initialize: Function() As Boolean
                    m.urlTransfer.SetPort(m.msgPort)
                    m.diagnostics.log("INFO", "Network plugin initialized")
                    return true
                End Function,

                download: Function(url As String) As Boolean
                    m.urlTransfer.SetUrl(url)
                    return m.urlTransfer.AsyncGetToFile("SD:/download.tmp")
                End Function
            }

            plugin.initialize()
            return plugin
        End Function,

        createLoggingPlugin: Function(config As Object) As Object
            return {
                diagnostics: m.diagnostics,
                logLevel: config.logLevel,

                log: Function(message As String) As Void
                    m.diagnostics.log(m.logLevel, message)
                End Function
            }
        End Function,

        createMediaPlugin: Function(config As Object) As Object
            return {
                msgPort: m.msgPort,
                videoPlayer: CreateObject("roVideoPlayer"),

                initialize: Function() As Void
                    m.videoPlayer.SetPort(m.msgPort)
                End Function,

                play: Function(file As String) As Void
                    m.videoPlayer.PlayFile(file)
                End Function
            }
        End Function
    }
End Function

' Usage
Sub Main()
    print "=== Basic Factory Pattern ==="
    logger = newLogger(true)
    logger.log("INFO", "Application started")
    logger.log("DEBUG", "Debug message example")

    print ""
    print "=== Media Player Factory ==="
    factory = CreateMediaPlayerFactory()

    videoPlayer = factory.createPlayer("video")
    audioPlayer = factory.createPlayer("audio")

    print "Created video player: " + videoPlayer.type
    print "Created audio player: " + audioPlayer.type

    print ""
    print "=== Plugin Factory with Dependency Injection ==="

    ' Setup system resources
    systemResources = {
        msgPort: CreateObject("roMessagePort"),
        diagnostics: newLogger(true)
    }

    pluginFactory = CreatePluginFactory(systemResources)

    ' Create plugins with configuration
    networkPlugin = pluginFactory.createPlugin("network", {
        timeout: 30000
    })

    loggingPlugin = pluginFactory.createPlugin("logging", {
        logLevel: "DEBUG"
    })

    if networkPlugin <> invalid then
        print "Network plugin created successfully"
    end if

    if loggingPlugin <> invalid then
        loggingPlugin.log("Plugin system initialized")
    end if
End Sub
```

### Use Cases

- **Plugin Instantiation**: Create plugins with standardized interfaces
- **Object Creation Abstraction**: Hide complex object creation logic
- **Dependency Injection**: Inject shared resources into created objects
- **Configuration-Based Creation**: Create objects based on configuration data
- **Testing**: Easily swap implementations for testing

### Best Practices

1. **Naming Convention**: Use "new" prefix for factory functions (e.g., newLogger)
2. **Dependency Injection**: Pass required dependencies to factories
3. **Validation**: Validate parameters before creating objects
4. **Error Handling**: Return invalid for creation failures
5. **Interface Consistency**: Ensure created objects implement expected interfaces

### Common Pitfalls

- **Over-Engineering**: Don't use factories for simple object creation
- **Hidden Complexity**: Factory complexity should not exceed direct creation
- **Tight Coupling**: Factories should not depend on too many external resources

---

## Manager Pattern

### Concept

The Manager pattern coordinates multiple related objects, manages their lifecycle, and provides a unified interface for complex operations. Managers are essential for organizing BrightScript applications with multiple subsystems.

### Implementation

```brightscript
' Resource manager coordinating multiple subsystems
Function CreateApplicationManager() As Object
    return {
        msgPort: CreateObject("roMessagePort"),
        isRunning: false,

        ' Subsystem references
        diagnostics: invalid,
        networking: invalid,
        mediaPlayer: invalid,

        ' Lifecycle management
        initialize: Function(config As Object) As Boolean
            print "Initializing application manager..."

            ' Create diagnostics subsystem
            m.diagnostics = newLogger(config.debugEnabled)
            m.diagnostics.log("INFO", "Diagnostics initialized")

            ' Create networking subsystem
            m.networking = m.createNetworkingSubsystem(config)
            if m.networking = invalid then
                m.diagnostics.log("ERROR", "Failed to initialize networking")
                return false
            end if

            ' Create media player subsystem
            m.mediaPlayer = m.createMediaSubsystem()
            if m.mediaPlayer = invalid then
                m.diagnostics.log("ERROR", "Failed to initialize media player")
                return false
            end if

            m.isRunning = true
            m.diagnostics.log("INFO", "Application manager initialized")
            return true
        End Function,

        createNetworkingSubsystem: Function(config As Object) As Object
            return {
                msgPort: m.msgPort,
                diagnostics: m.diagnostics,
                urlTransfer: CreateObject("roUrlTransfer"),
                downloadQueue: [],

                queueDownload: Function(url As String) As Void
                    m.downloadQueue.Push(url)
                    m.diagnostics.log("INFO", "Queued download: " + url)
                End Function,

                processQueue: Function() As Void
                    if m.downloadQueue.Count() > 0 then
                        url = m.downloadQueue.Shift()
                        m.startDownload(url)
                    end if
                End Function,

                startDownload: Function(url As String) As Void
                    m.urlTransfer.SetPort(m.msgPort)
                    m.urlTransfer.SetUrl(url)
                    m.diagnostics.log("INFO", "Starting download: " + url)
                End Function
            }
        End Function,

        createMediaSubsystem: Function() As Object
            return {
                msgPort: m.msgPort,
                diagnostics: m.diagnostics,
                videoPlayer: CreateObject("roVideoPlayer"),
                playlist: [],
                currentIndex: 0,

                loadPlaylist: Function(files As Object) As Void
                    m.playlist = files
                    m.currentIndex = 0
                    m.diagnostics.log("INFO", "Loaded playlist with " + files.Count().ToStr() + " items")
                End Function,

                playNext: Function() As Boolean
                    if m.playlist.Count() = 0 then return false

                    if m.currentIndex >= m.playlist.Count() then
                        m.currentIndex = 0
                    end if

                    file = m.playlist[m.currentIndex]
                    m.videoPlayer.PlayFile(file)
                    m.diagnostics.log("INFO", "Playing: " + file)
                    m.currentIndex = m.currentIndex + 1

                    return true
                End Function,

                stop: Function() As Void
                    m.videoPlayer.Stop()
                    m.diagnostics.log("INFO", "Media playback stopped")
                End Function
            }
        End Function,

        ' Event loop management
        processEvents: Function(timeoutMs As Integer) As Boolean
            msg = wait(timeoutMs, m.msgPort)

            if msg = invalid then return true

            msgType = type(msg)

            if msgType = "roVideoEvent" then
                return m.handleVideoEvent(msg)
            else if msgType = "roUrlEvent" then
                return m.handleUrlEvent(msg)
            else
                m.diagnostics.log("WARNING", "Unhandled event: " + msgType)
            end if

            return true
        End Function,

        handleVideoEvent: Function(msg As Object) As Boolean
            eventCode = msg.GetInt()

            if eventCode = 8 then  ' Media ended
                m.diagnostics.log("INFO", "Video ended, playing next")
                m.mediaPlayer.playNext()
            else if eventCode = 19 then  ' Media failed
                m.diagnostics.log("ERROR", "Video playback failed")
            end if

            return true
        End Function,

        handleUrlEvent: Function(msg As Object) As Boolean
            responseCode = msg.GetResponseCode()

            if responseCode = 200 then
                m.diagnostics.log("INFO", "Download completed successfully")
                m.networking.processQueue()
            else
                m.diagnostics.log("ERROR", "Download failed: " + responseCode.ToStr())
            end if

            return true
        End Function,

        ' Coordinated operations
        startPlayback: Function(playlist As Object) As Boolean
            if not m.isRunning then
                m.diagnostics.log("ERROR", "Cannot start playback - manager not initialized")
                return false
            end if

            m.mediaPlayer.loadPlaylist(playlist)
            return m.mediaPlayer.playNext()
        End Function,

        downloadContent: Function(urls As Object) As Void
            for each url in urls
                m.networking.queueDownload(url)
            end for
            m.networking.processQueue()
        End Function,

        ' Cleanup
        shutdown: Function() As Void
            m.diagnostics.log("INFO", "Shutting down application manager")

            if m.mediaPlayer <> invalid then
                m.mediaPlayer.stop()
                m.mediaPlayer = invalid
            end if

            if m.networking <> invalid then
                m.networking = invalid
            end if

            m.isRunning = false
            m.diagnostics.log("INFO", "Shutdown complete")
        End Function,

        getStatus: Function() As Object
            return {
                isRunning: m.isRunning,
                playlistSize: m.mediaPlayer.playlist.Count(),
                downloadQueueSize: m.networking.downloadQueue.Count()
            }
        End Function
    }
End Function

' Timer manager for scheduled operations
Function CreateTimerManager() As Object
    return {
        msgPort: CreateObject("roMessagePort"),
        timers: {},

        createTimer: Function(name As String, intervalSec As Integer, repeating As Boolean) As Object
            timer = CreateObject("roTimer")
            timer.SetPort(m.msgPort)

            if repeating then
                timer.SetElapsed(intervalSec, intervalSec)
            else
                timer.SetElapsed(intervalSec, 0)
            end if

            m.timers[name] = timer
            return timer
        End Function,

        startTimer: Function(name As String) As Boolean
            if m.timers.DoesExist(name) then
                m.timers[name].Start()
                return true
            end if
            return false
        End Function,

        stopTimer: Function(name As String) As Boolean
            if m.timers.DoesExist(name) then
                m.timers[name].Stop()
                return true
            end if
            return false
        End Function,

        handleTimerEvent: Function(msg As Object) As String
            if type(msg) <> "roTimerEvent" then return ""

            ' Identify which timer fired using identity verification
            for each timerName in m.timers
                timer = m.timers[timerName]
                if type(timer) = "roTimer" then
                    if stri(msg.GetSourceIdentity()) = stri(timer.GetIdentity()) then
                        return timerName
                    end if
                end if
            end for

            return "unknown"
        End Function,

        cleanup: Function() As Void
            for each timerName in m.timers
                m.timers[timerName].Stop()
                m.timers[timerName] = invalid
            end for
            m.timers.Clear()
        End Function
    }
End Function

' Usage
Sub Main()
    print "=== Application Manager Pattern ==="

    ' Create and initialize manager
    appManager = CreateApplicationManager()

    config = {
        debugEnabled: true
    }

    if not appManager.initialize(config) then
        print "Failed to initialize application"
        return
    end if

    ' Start media playback
    playlist = ["video1.mp4", "video2.mp4", "video3.mp4"]
    appManager.startPlayback(playlist)

    ' Queue downloads
    downloads = ["http://example.com/content1.mp4", "http://example.com/content2.mp4"]
    appManager.downloadContent(downloads)

    ' Check status
    status = appManager.getStatus()
    print "Running: " + status.isRunning.ToStr()
    print "Playlist size: " + status.playlistSize.ToStr()

    ' Process events (in production, this would be a continuous loop)
    for i = 1 to 5
        appManager.processEvents(1000)
    end for

    ' Shutdown
    appManager.shutdown()

    print ""
    print "=== Timer Manager Pattern ==="

    timerMgr = CreateTimerManager()

    ' Create timers
    heartbeat = timerMgr.createTimer("heartbeat", 5, true)
    timeout = timerMgr.createTimer("timeout", 30, false)

    timerMgr.startTimer("heartbeat")
    timerMgr.startTimer("timeout")

    print "Timers started, waiting for events..."

    ' Handle timer events
    for i = 1 to 3
        msg = wait(6000, timerMgr.msgPort)
        if msg <> invalid then
            timerName = timerMgr.handleTimerEvent(msg)
            print "Timer fired: " + timerName
        end if
    end for

    timerMgr.cleanup()
    print "Timer manager cleanup complete"
End Sub
```

### Use Cases

- **Application Lifecycle**: Manage startup, running, and shutdown phases
- **Resource Coordination**: Coordinate access to shared resources across subsystems
- **Event Routing**: Route events to appropriate handlers
- **Subsystem Integration**: Integrate multiple subsystems into cohesive application
- **State Synchronization**: Keep multiple components synchronized

### Best Practices

1. **Clear Responsibilities**: Define manager's scope of coordination
2. **Initialization Order**: Initialize dependencies in correct order
3. **Error Recovery**: Handle subsystem failures gracefully
4. **Resource Cleanup**: Implement thorough cleanup in shutdown
5. **Status Reporting**: Provide status information about managed resources

### Common Pitfalls

- **God Object**: Manager should coordinate, not implement everything
- **Tight Coupling**: Subsystems should remain loosely coupled
- **Initialization Complexity**: Keep initialization logic manageable

---

## Validation Pattern

### Concept

The Validation pattern ensures data integrity and prevents errors by validating inputs, configurations, and system state. Proper validation is critical for robust BrightSign applications that handle external data and user configurations.

### Implementation

```brightscript
' Input validation utilities
Function CreateValidator() As Object
    return {
        ' String validation
        validateString: Function(value As Dynamic, minLength As Integer, maxLength As Integer) As Object
            result = {
                valid: false,
                error: ""
            }

            if type(value) <> "roString" and type(value) <> "String" then
                result.error = "Value must be a string"
                return result
            end if

            length = Len(value)

            if length < minLength then
                result.error = "String too short (min: " + minLength.ToStr() + ")"
                return result
            end if

            if length > maxLength then
                result.error = "String too long (max: " + maxLength.ToStr() + ")"
                return result
            end if

            result.valid = true
            return result
        End Function,

        ' Numeric validation
        validateInteger: Function(value As Dynamic, minValue As Integer, maxValue As Integer) As Object
            result = {
                valid: false,
                error: ""
            }

            if type(value) <> "roInt" and type(value) <> "Integer" and type(value) <> "roInteger" then
                result.error = "Value must be an integer"
                return result
            end if

            if value < minValue then
                result.error = "Value too small (min: " + minValue.ToStr() + ")"
                return result
            end if

            if value > maxValue then
                result.error = "Value too large (max: " + maxValue.ToStr() + ")"
                return result
            end if

            result.valid = true
            return result
        End Function,

        ' URL validation
        validateUrl: Function(url As String) As Object
            result = {
                valid: false,
                error: ""
            }

            if type(url) <> "roString" and type(url) <> "String" then
                result.error = "URL must be a string"
                return result
            end if

            url = url.Trim()

            if url.Len() = 0 then
                result.error = "URL cannot be empty"
                return result
            end if

            ' Check protocol
            hasHttp = url.Left(7) = "http://" or url.Left(8) = "https://"
            hasFile = url.Left(5) = "file:"

            if not hasHttp and not hasFile then
                result.error = "URL must start with http://, https://, or file:"
                return result
            end if

            result.valid = true
            return result
        End Function,

        ' File path validation
        validateFilePath: Function(path As String) As Object
            result = {
                valid: false,
                error: "",
                exists: false
            }

            if type(path) <> "roString" and type(path) <> "String" then
                result.error = "Path must be a string"
                return result
            end if

            if path.Len() = 0 then
                result.error = "Path cannot be empty"
                return result
            end if

            ' Check for valid storage prefix
            validPrefixes = ["SD:", "USB1:", "USB2:", "SSD:", "pool:"]
            hasValidPrefix = false

            for each prefix in validPrefixes
                if path.Left(prefix.Len()) = prefix then
                    hasValidPrefix = true
                    exit for
                end if
            end for

            if not hasValidPrefix then
                result.error = "Path must start with valid storage prefix (SD:, USB1:, etc.)"
                return result
            end if

            ' Check if file exists
            fs = CreateObject("roFileSystem")
            result.exists = fs.Exists(path)
            result.valid = true

            return result
        End Function,

        ' Configuration validation
        validateConfig: Function(config As Object, schema As Object) As Object
            result = {
                valid: true,
                errors: []
            }

            if type(config) <> "roAssociativeArray" then
                result.valid = false
                result.errors.Push("Configuration must be an associative array")
                return result
            end if

            ' Check required fields
            for each field in schema.required
                if not config.DoesExist(field) then
                    result.valid = false
                    result.errors.Push("Missing required field: " + field)
                end if
            end for

            ' Validate field types
            for each field in config
                if schema.fields.DoesExist(field) then
                    expectedType = schema.fields[field]
                    actualType = type(config[field])

                    if actualType <> expectedType then
                        result.valid = false
                        result.errors.Push("Field '" + field + "' has wrong type (expected " + expectedType + ", got " + actualType + ")")
                    end if
                end if
            end for

            return result
        End Function
    }
End Function

' Production validation pattern from BrightSign systems
Function ValidateSystemConfiguration(config As Object) As Boolean
    ' Pattern 1: Object creation validation
    registrySection = CreateObject("roRegistrySection", "app_config")
    if type(registrySection) <> "roRegistrySection" then
        print "ERROR: Unable to create registry section"
        return false
    end if

    ' Pattern 2: Required field validation
    requiredFields = ["deviceID", "serverUrl", "refreshInterval"]
    for each field in requiredFields
        if not config.DoesExist(field) then
            print "ERROR: Missing required configuration field: " + field
            return false
        end if
    end for

    ' Pattern 3: Type validation
    if type(config.refreshInterval) <> "roInt" and type(config.refreshInterval) <> "Integer" then
        print "ERROR: refreshInterval must be an integer"
        return false
    end if

    ' Pattern 4: Range validation
    if config.refreshInterval < 60 or config.refreshInterval > 86400 then
        print "ERROR: refreshInterval out of range (60-86400)"
        return false
    end if

    ' Pattern 5: Conditional validation
    if config.DoesExist("useWireless") and config.useWireless = true then
        if not config.DoesExist("ssid") or config.ssid = "" then
            print "ERROR: SSID required when wireless is enabled"
            return false
        end if
    end if

    return true
End Function

' Sanitization utilities
Function CreateSanitizer() As Object
    return {
        sanitizeString: Function(input As String) As String
            ' Remove control characters
            output = ""
            for i = 0 to Len(input) - 1
                char = Mid(input, i, 1)
                charCode = Asc(char)

                ' Keep printable characters
                if charCode >= 32 and charCode <= 126 then
                    output = output + char
                end if
            end for

            return output
        End Function,

        sanitizeFilename: Function(filename As String) As String
            ' Remove invalid filename characters
            invalidChars = ["/", "\", ":", "*", "?", "<", ">", "|"]
            output = filename

            for each char in invalidChars
                output = output.Replace(char, "_")
            end for

            return output
        End Function,

        sanitizeUrl: Function(url As String) As String
            ' Basic URL encoding for spaces
            return url.Replace(" ", "%20")
        End Function
    }
End Function

' Usage
Sub Main()
    print "=== Validation Pattern Examples ==="

    validator = CreateValidator()

    ' String validation
    print "Testing string validation:"
    result = validator.validateString("test", 3, 10)
    print "  Valid: " + result.valid.ToStr()

    result = validator.validateString("ab", 3, 10)
    print "  Too short - Valid: " + result.valid.ToStr() + ", Error: " + result.error

    ' Integer validation
    print ""
    print "Testing integer validation:"
    result = validator.validateInteger(50, 0, 100)
    print "  Valid: " + result.valid.ToStr()

    result = validator.validateInteger(150, 0, 100)
    print "  Out of range - Valid: " + result.valid.ToStr() + ", Error: " + result.error

    ' URL validation
    print ""
    print "Testing URL validation:"
    result = validator.validateUrl("http://example.com/video.mp4")
    print "  Valid URL - Valid: " + result.valid.ToStr()

    result = validator.validateUrl("invalid-url")
    print "  Invalid URL - Valid: " + result.valid.ToStr() + ", Error: " + result.error

    ' File path validation
    print ""
    print "Testing file path validation:"
    result = validator.validateFilePath("SD:/content/video.mp4")
    print "  Valid path - Valid: " + result.valid.ToStr() + ", Exists: " + result.exists.ToStr()

    ' Configuration validation
    print ""
    print "Testing configuration validation:"

    schema = {
        required: ["serverUrl", "refreshInterval"],
        fields: {
            serverUrl: "roString",
            refreshInterval: "roInt"
        }
    }

    goodConfig = {
        serverUrl: "http://example.com",
        refreshInterval: 300
    }

    result = validator.validateConfig(goodConfig, schema)
    print "  Good config - Valid: " + result.valid.ToStr()

    badConfig = {
        serverUrl: "http://example.com"
        ' Missing refreshInterval
    }

    result = validator.validateConfig(badConfig, schema)
    print "  Bad config - Valid: " + result.valid.ToStr()
    if result.errors.Count() > 0 then
        print "  Errors: " + result.errors[0]
    end if

    ' Production validation pattern
    print ""
    print "Testing production validation pattern:"

    systemConfig = {
        deviceID: "BS-12345",
        serverUrl: "https://api.example.com",
        refreshInterval: 600
    }

    if ValidateSystemConfiguration(systemConfig) then
        print "  System configuration valid"
    else
        print "  System configuration invalid"
    end if

    ' Sanitization
    print ""
    print "Testing sanitization:"

    sanitizer = CreateSanitizer()

    dirtyString = "Hello" + chr(0) + chr(1) + "World"
    clean = sanitizer.sanitizeString(dirtyString)
    print "  Sanitized string: " + clean

    dirtyFilename = "my/file:name*.txt"
    cleanFilename = sanitizer.sanitizeFilename(dirtyFilename)
    print "  Sanitized filename: " + cleanFilename
End Sub
```

### Use Cases

- **Configuration Loading**: Validate external configuration data
- **User Input**: Sanitize and validate user-provided data
- **API Responses**: Validate data from network requests
- **File Operations**: Validate file paths before operations
- **Device Capability**: Validate device supports required features

### Best Practices

1. **Validate Early**: Check inputs at system boundaries
2. **Clear Error Messages**: Provide actionable error descriptions
3. **Fail Fast**: Reject invalid data immediately
4. **Sanitize Inputs**: Clean data in addition to validation
5. **Type Checking**: Always verify object types before operations
6. **Range Checking**: Validate numeric values are within acceptable ranges

### Common Pitfalls

- **Incomplete Validation**: Missing edge cases in validation logic
- **Silent Failures**: Not reporting validation errors clearly
- **Performance**: Excessive validation can impact performance
- **Over-Validation**: Validating internal data that's guaranteed to be correct

---

## Best Practices

### General Pattern Guidelines

1. **Choose Appropriate Patterns**
   - Don't force patterns where they don't fit
   - Combine patterns when necessary
   - Keep implementations simple and maintainable

2. **BrightScript-Specific Considerations**
   - Use "m" scope correctly in object methods
   - Follow "new" prefix convention for factory functions
   - Leverage roAssociativeArray for flexible objects
   - Use type() for object validation

3. **Memory Management**
   - Set references to invalid for cleanup
   - Clear arrays and collections
   - Use RunGarbageCollector() for circular references
   - Unsubscribe from event systems

4. **Error Handling**
   - Validate all inputs
   - Check object creation success
   - Provide meaningful error messages
   - Use early returns for error conditions

5. **Documentation**
   - Document pattern usage and intent
   - Explain complex pattern combinations
   - Provide usage examples
   - Document dependencies and requirements

### Testing Patterns

1. **Testable Design**
   - Use dependency injection for flexibility
   - Provide factory methods for test doubles
   - Keep business logic separate from infrastructure
   - Design for isolated unit testing

2. **Pattern Validation**
   - Test pattern implementations thoroughly
   - Verify error handling paths
   - Test edge cases and boundary conditions
   - Validate memory cleanup

### Performance Considerations

1. **Pattern Overhead**
   - Measure pattern impact on performance
   - Optimize critical paths
   - Balance abstraction with efficiency
   - Profile before optimizing

2. **Resource Usage**
   - Monitor memory consumption
   - Manage object lifecycle carefully
   - Avoid unnecessary object creation
   - Reuse objects when appropriate

---

## Conclusion

Design patterns provide proven solutions to common problems in BrightScript development. The patterns covered in this chapter—Singleton, Observer, Command, State Machine, Factory, Manager, and Validation—form a solid foundation for building maintainable, scalable digital signage applications.

### Key Takeaways

- **Singleton**: Manages global state and shared resources
- **Observer**: Enables loose coupling through event notification
- **Command**: Encapsulates actions for queuing and undo operations
- **State Machine**: Manages complex behavior and workflows
- **Factory**: Abstracts object creation and supports dependency injection
- **Manager**: Coordinates multiple subsystems and resources
- **Validation**: Ensures data integrity and prevents errors

### Combining Patterns

Real-world applications often combine multiple patterns:

```brightscript
' Example: Application using multiple patterns
Sub ProductionApplication()
    ' Singleton: Global configuration
    config = GetApplicationSingleton()

    ' Factory: Create subsystems
    systemResources = {
        msgPort: CreateObject("roMessagePort"),
        diagnostics: newLogger(true)
    }

    factory = CreatePluginFactory(systemResources)

    ' Manager: Coordinate subsystems
    appManager = CreateApplicationManager()
    appManager.initialize(config)

    ' Observer: Event notification
    eventBus = CreateEventBus()
    eventBus.subscribe("PLAYBACK", CreateLoggerObserver())

    ' State Machine: Control workflow
    stateMachine = CreateMediaPlayerStateMachine()

    ' Command: Queue operations
    commandManager = CreateCommandManager()

    ' Application runs with all patterns working together
    ' ...
End Sub
```

### Next Steps

- Review [Chapter 5: Plugin Architecture](../chapter05-plugin-architecture/) for advanced modular programming patterns
- Study production BrightScript code to see patterns in action
- Practice implementing patterns in your own projects
- Combine patterns to solve complex architectural challenges

Congratulations on completing the BrightSign Development Guide! You now have the knowledge to build professional, maintainable digital signage applications using proven design patterns and best practices.


---

[← Previous](03-debugging-brightscript.md) | [↑ Part 2: BrightScript Development](README.md) | [Next →](05-plugin-architecture.md)
