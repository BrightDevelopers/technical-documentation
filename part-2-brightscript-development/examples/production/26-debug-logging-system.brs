Library "common-functions.brs"

' Production-ready logging system with multiple levels
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

                ' Note: File logging removed for demo - AppendAsciiFile not available
                ' In production, use roAppendFile or roCreateFile/roWriteFile
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

' System resource monitoring for performance analysis
Sub CheckMemoryUsage()
    deviceInfo = CreateObject("roDeviceInfo")

    ' Get memory info
    memInfo = deviceInfo.GetGeneralMemoryLevel()
    print "Memory level: " + memInfo.level

    ' Get storage info
    storage = CreateObject("roStorageInfo", "/")
    print "Free space: " + storage.GetFreeSpace(.ToStr() + " bytes")
    print "Used space: " + storage.GetUsedSpace(.ToStr() + " bytes")
End Sub

' Test function for debugging
Function TrySomething() As Dynamic
    ' Simulate an operation that might fail
    if CreateObject("roDateTime").GetSecond() mod 2 = 0 then
        return "Success"
    else
        return invalid
    end if
End Function

' Production logging usage with error handling
Sub Main()
    ShowMessage("26: Debug Logging System")
    logger = CreateLogger("app.log")
    logger.setLevel("DEBUG")

    logger.info("Application started")
    logger.debug("Initializing components")

    ' Test debug helper
    testData = { name: "BrightScript", version: 1.0, active: true }
    Debug("Test Data", testData)
    Debug("Invalid Test", invalid)
    Debug("String Test", "Hello World")

    ' Error handling with logging
    result = TrySomething()
    if result = invalid then
        logger.error("Operation failed")
    else
        logger.info("Operation successful: " + result)
    end if

    ' Test system monitoring
    logger.info("Checking system resources...")
    CheckMemoryUsage()

    ' Test different log levels
    logger.debug("This is a debug message")
    logger.info("This is an info message")
    logger.warn("This is a warning message")
    logger.error("This is an error message")

    ' Change log level and test filtering
    logger.setLevel("ERROR")
    logger.debug("This debug message won't be shown")
    logger.info("This info message won't be shown")
    logger.error("Only error messages are shown now")

    logger.setLevel("INFO")
    logger.info("Application finished")
End Sub