Library "common-functions.brs"

' Image display and slideshow functionality
Sub DisplayImage(filename As String)
    imagePlayer = CreateObject("roImagePlayer")

    ' Display single image
    ok = imagePlayer.DisplayFile(filename)

    if ok then
        print "Displaying: " + filename
    else
        print "Failed to display image"
    end if

    ' Display for 2 seconds (shorter for demo)
    sleep(2000)
    
    ' Clear the image display
    imagePlayer.StopDisplay()
End Sub

' Automated image slideshow with timed transitions
Sub ImageSlideshow(imageList As Object, duration As Integer)
    imagePlayer = CreateObject("roImagePlayer")

    for each image in imageList
        imagePlayer.DisplayFile(image)
        sleep(duration * 1000)  ' Duration in seconds
        ' Clear between images for cleaner transitions
        imagePlayer.StopDisplay()
        sleep(100)  ' Brief pause between images
    end for
End Sub

Sub Main()
    ShowMessage("16: Image Slideshow")
    print "Starting image slideshow demo..."
    
    ' Test single image display
    print "Displaying single image..."
    DisplayImage("png-01.png")
    
    print "Preparing slideshow..."
    
    ' Create image list for slideshow - using all 5 PNG and 5 JPG images
    images = [
        "png-01.png", "png-02.png", "png-03.png", "png-04.png", "png-05.png",
        "jpg-01.jpg", "jpg-02.jpg", "jpg-03.jpg", "jpg-04.jpg", "jpg-05.jpg"
    ]
    
    ' Test slideshow with 1 second intervals (faster for demo)
    print "Starting slideshow with " + images.Count().ToStr() + " images..."
    ImageSlideshow(images, 1)
    
    print "Slideshow complete"
End Sub