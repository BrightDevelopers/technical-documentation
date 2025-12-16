Library "common-functions.brs"

' XML parsing and document creation examples
Sub ParseXmlExample()
    xmlString = "<?xml version='1.0'?><root><item id='1'>First</item><item id='2'>Second</item></root>"

    ' Parse XML
    xml = CreateObject("roXMLElement")
    if xml.Parse(xmlString) then
        print "XML parsed successfully"

        ' Access elements using dot notation
        items = xml.item  ' Returns roXMLList
        print "Found " + items.Count().ToStr() + " items"

        ' Iterate through items
        for each item in items
            id = item@id  ' Get attribute with @
            text = item.GetText()
            print "Item " + id + ": " + text
        end for
    else
        print "Failed to parse XML"
    end if
End Sub

' Advanced XML document navigation with attribute filtering
Sub NavigateXml()
    ' Note: ReadAsciiFile not available in demo - using sample XML instead
    xmlStr = "<?xml version='1.0'?><library><books><book author='Smith'><title>Book 1</title></book><book author='Jones'><title>Book 2</title></book></books></library>"
    doc = CreateObject("roXMLElement")
    doc.Parse(xmlStr)

    ' Navigate using proper BrightScript XML syntax with dot notation
    ' Access nested elements directly
    if doc.books <> invalid then
        bookList = doc.books.book  ' Returns roXMLList of book elements
        if type(bookList) = "roXMLList" and bookList.Count() > 0 then
            ' Get first book
            firstBook = bookList[0]
            if firstBook.title <> invalid then
                print "First book title: " + firstBook.title.GetText()
            end if
            
            ' Find all books by author Smith
            for each book in bookList
                author = book@author  ' Use @ for attributes
                if author = "Smith" then
                    if book.title <> invalid then
                        print "Smith's book: " + book.title.GetText()
                    end if
                end if
            end for
        end if
    end if
End Sub

Function CreateXmlDocument() As String
    root = CreateObject("roXMLElement")
    root.SetName("catalog")

    ' Add product
    product = root.AddBodyElement()
    product.SetName("product")
    product.AddAttribute("id", "123")

    ' Add child elements
    name = product.AddElement("name")
    name.SetBody("BrightSign Player")

    price = product.AddElement("price")
    price.SetBody("299.99")
    price.AddAttribute("currency", "USD")

    ' Generate XML string
    xmlString = root.GenXML({ header: true })
    return xmlString
End Function

Sub Main()
    ShowMessage("27: XML Processing")
    ' Test XML parsing
    print "Testing XML parsing..."
    ParseXmlExample()
    
    ' Test XML creation
    print "Creating XML document..."
    xmlDoc = CreateXmlDocument()
    print xmlDoc
    
    ' Test XML navigation (would need data.xml file)
    print "Testing XML navigation..."
    NavigateXml()
End Sub