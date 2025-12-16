Library "common-functions.brs"

' Basic function
Function Add(a As Integer, b As Integer) As Integer
    return a + b
End Function

' Function with default parameters
Function Greet(name = "World" As String) As String
    return "Hello, " + name + "!"
End Function

' Sub (void function) 
Sub PrintMessage(msg As String)
    print "Message: " + msg
End Sub

' Function with multiple return types (Dynamic)
Function GetValue(index As Integer) As Dynamic
    if index = 0 then
        return "String value"
    else if index = 1 then
        return 42
    else
        return invalid
    end if
End Function

Sub Main()
    ' Display test name
    ShowMessage("03: Function Examples")
    
    result = Add(5, 3)
    print "5 + 3 = " + result.ToStr()
    
    greeting = Greet("BrightScript")
    print greeting
    
    PrintMessage("Testing functions")
    
    value = GetValue(0)
    print "Value: " + value
End Sub