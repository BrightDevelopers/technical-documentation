Library "common-functions.brs"

Sub VariableExamples()
    ' Production-tested integer patterns
    setupVersion$ = "8.0.0.1"
    networkPriority% = 0
    timeBetweenNetConnects% = 60
    deviceFWVersionNumber% = 524407

    ' String operations with type suffixes from production
    deviceUniqueID$ = "BS123456"  ' Example value since modelObject not available
    timeServer$ = "ntp://time.brightsignnetwork.com"
    staticIPAddress$ = "192.168.1.100"
    hostName$ = "brightsign-player"

    ' Boolean validation patterns used in production
    modelSupportsWifi = false
    useWireless = true  ' Example value
    enableDiagnostics = true  ' Example value
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
    
    ' Display some variables
    print "Setup Version: " + setupVersion$
    print "Network Priority: " + str(networkPriority%
    print "Device ID: " + deviceUniqueID$
    print "WiFi Supported: " + str(modelSupportsWifi
End Sub

Sub Main()
    ' Display test name
    ShowMessage("02: Variable Examples")
    VariableExamples()
End Sub