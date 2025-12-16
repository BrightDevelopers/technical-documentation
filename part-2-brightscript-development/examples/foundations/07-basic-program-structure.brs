Library "common-functions.brs"

Sub Main()
    ShowMessage("07: Basic Program Structure")
    ' Your code here
    print("Starting application...")
    RunApplication()
End Sub

Function RunApplication() As Void
    ' Application logic
    device$ = "BrightSign"
    print("Running on: " + device$)
End Function