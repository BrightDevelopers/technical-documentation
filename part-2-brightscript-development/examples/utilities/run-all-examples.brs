' Progress tracking functions
Function ReadProgress() As Integer
    ' Read the last completed example number from progress.txt
    ' Returns 0 if file doesn't exist or can't be read
    
    ' Try to read from progress.txt file on SD card root
    readFile = CreateObject("roReadFile", "progress.txt")
    if readFile <> invalid then
        progressStr = readFile.ReadLine()
        ' Note: roReadFile closes automatically when variable goes out of scope
        if progressStr <> invalid and progressStr <> "" then
            progressNum = val(progressStr)
            if progressNum > 0 then
                print "[PROGRESS] Resuming from example " + str(progressNum + 1) + " (last completed: " + str(progressNum) + ")"
                return progressNum
            end if
        end if
    end if
    
    print "[PROGRESS] No progress file found - starting from beginning"
    return 0  ' Start from beginning if no progress found
End Function

Sub WriteProgress(exampleNumber As Integer)
    ' Write the completed example number to progress.txt on SD card root
    
    ' Create/overwrite progress.txt with the current example number
    writeFile = CreateObject("roCreateFile", "progress.txt")
    if writeFile <> invalid then
        writeFile.SendLine(str(exampleNumber))
        ' Note: roCreateFile closes automatically when variable goes out of scope
        print "[PROGRESS] Saved progress to progress.txt: example " + str(exampleNumber) + " completed"
    else
        print "[PROGRESS] ERROR: Could not create progress.txt file"
    end if
End Sub

Sub ClearProgress()
    ' Clear progress tracking by deleting progress.txt
    
    ' Delete the progress file to start from beginning
    deleteFile = CreateObject("roFileSystem")
    if deleteFile <> invalid then
        if deleteFile.Exists("progress.txt") then
            deleteFile.Delete("progress.txt")
            print "[PROGRESS] Deleted progress.txt - will start from beginning"
        else
            print "[PROGRESS] No progress.txt found - already starting from beginning"
        end if
    else
        print "[PROGRESS] ERROR: Could not access file system to delete progress.txt"
    end if
End Sub


' Function to run an example by calling its run() function
Sub RunExample(exampleName As String, exampleNumber As Integer)
    ' Starting example

    print "=== Running Example " + str(exampleNumber) + ": " + exampleName + " ==="

    ' Use run() to execute the example file
    run(exampleName)

    print "=== Completed Example " + str(exampleNumber) + ": " + exampleName + " ==="
    
    ' Write progress after successful completion
    WriteProgress(exampleNumber)
    
    sleep(2000)  ' Brief pause between examples

    ' Example completed
End Sub

Sub Main()
    ' Configuration variables
    resumeFromLastGood = true  ' Set to false to always start from beginning
    
    ' Starting demo system

    print "BrightScript Examples Demo"
    
    ' Check resume settings
    startFromExample = 1
    if resumeFromLastGood then
        lastCompleted = ReadProgress()
        if lastCompleted > 0 and lastCompleted < 27 then
            startFromExample = lastCompleted + 1
            print "Resuming from example " + str(startFromExample) + " (last completed: " + str(lastCompleted) + ")"
        else if lastCompleted >= 27 then
            print "All examples already completed. Starting fresh..."
            ClearProgress()
        else
            print "Starting from the beginning..."
        end if
    else
        print "Starting from the beginning (resumeFromLastGood = false)"
        ClearProgress()
    end if
    
    print "Running examples " + str(startFromExample) + "-27 sequentially..."
    sleep(2000)

    ' Create array of all examples for easier iteration
    examples = [
        "01-hello-world.brs",
        "02-variable-examples.brs",
        "03-function-examples.brs",
        "04-string-functions.brs",
        "05-case-sensitivity.brs",
        "06-goto-labels.brs",
        "07-basic-program-structure.brs",
        "08-m-scope-device-manager.brs",
        "09-object-factory-pattern.brs",
        "10-application-manager-cross-references.brs",
        "11-networking-object-factory.brs",
        "12-queue-pattern.brs",
        "13-state-machine.brs",
        "14-video-player.brs",
        "15-audio-player.brs",
        "16-image-slideshow.brs",
        "17-complete-media-player.brs",
        "18-network-configuration.brs",
        "19-registry-settings.brs",
        "20-registry-manager-validation.brs",
        "21-production-event-loop.brs",
        "22-production-library-pattern.brs",
        "23-production-validation-pattern.brs",
        "24-complete-event-bus.brs",
        "25-timer-manager.brs",
        "26-debug-logging-system.brs",
        "27-xml-processing.brs"
    ]
    
    ' Run examples starting from the resume point
    for i = startFromExample - 1 to 26  ' Array is 0-based, examples are 1-based
        RunExample(examples[i], i + 1)
    end for

    print "=== ALL EXAMPLES COMPLETED ==="
    print "Demo finished successfully!"
    
    ' Mark all examples as complete
    WriteProgress(27)
    
    sleep(5000)

End Sub
