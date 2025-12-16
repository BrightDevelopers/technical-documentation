' Common functions shared across all examples

' Display test name on screen
Sub ShowMessage(message As String)
    ' Print to console
    print chr(10) + "===================================="
    print "RUNNING: " + message
    print "====================================" + chr(10)
    
    ' Create text widget for on-screen display
    r = CreateObject("roRectangle", 50, 950, 600, 100)
    tw = CreateObject("roTextWidget", r, 1, 2, 1)
    tw.SetForegroundColor(&hFFFFFF)  ' White text
    tw.SetBackgroundColor(&h0033CC)  ' Blue background
    tw.PushString(message)
    tw.Show()
End Sub

' Clear the on-screen message
Sub ClearMessage()
    r = CreateObject("roRectangle", 50, 950, 600, 100)
    tw = CreateObject("roTextWidget", r, 1, 2, 1)
    tw.Clear()
    tw.Show()
End Sub

' Display error message in red
Sub ShowError(errorMsg As String)
    print chr(10) + "!!!!! ERROR !!!!!"
    print errorMsg
    print "!!!!!!!!!!!!!!!!!" + chr(10)
    
    ' Create text widget for on-screen display
    r = CreateObject("roRectangle", 50, 950, 600, 100)
    tw = CreateObject("roTextWidget", r, 1, 2, 1)
    tw.SetForegroundColor(&hFFFFFF)  ' White text
    tw.SetBackgroundColor(&hCC0000)  ' Red background
    tw.PushString("ERROR: " + errorMsg)
    tw.Show()
End Sub

' Display success message in green
Sub ShowSuccess(successMsg As String)
    print chr(10) + "===== SUCCESS ====="
    print successMsg
    print "===================" + chr(10)
    
    ' Create text widget for on-screen display
    r = CreateObject("roRectangle", 50, 950, 600, 100)
    tw = CreateObject("roTextWidget", r, 1, 2, 1)
    tw.SetForegroundColor(&hFFFFFF)  ' White text
    tw.SetBackgroundColor(&h00CC00)  ' Green background
    tw.PushString(successMsg)
    tw.Show()
End Sub