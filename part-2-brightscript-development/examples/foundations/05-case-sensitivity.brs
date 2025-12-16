Library "common-functions.brs"

' These are all equivalent - keywords are case insensitive
Sub Main()
' Display test name
ShowMessage("05: Case Sensitivity")

' Variable names are also case insensitive
userName$ = "John"
USERNAME$ = "Jane"  ' Same variable as userName$
print "userName: " + userName$     ' Outputs: Jane

' But string content IS case sensitive
if userName$ = "john" then      ' FALSE - case sensitive comparison
    print("Match!")
end if

if LCase(userName$) = "jane" then   ' TRUE - after converting to lowercase
    print("Match!")
end if
End Sub