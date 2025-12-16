Library "common-functions.brs"

Sub ProcessWithGoto()
    count = 0

    start_label:
    count = count + 1
    print("Count: " + str(count))

    if count < 3 then goto start_label

    print("Finished with goto")
End Sub

Sub Main()
    ShowMessage("06: Goto Labels")
    ProcessWithGoto()
End Sub