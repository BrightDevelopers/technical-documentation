Library "common-functions.brs"

Sub Main()
    ' Display test name
    ShowMessage("01: Hello World")
    print "Hello, BrightScript!"

    ' Create a message port for events
    msgPort = CreateObject("roMessagePort")

    ' Simple variable usage
    name$ = "BrightSign"
    count% = 42
    pi! = 3.14159

    print "Device: " + name$ + " Count: " + str(count%)
End Sub
