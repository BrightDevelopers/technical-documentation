Library "common-functions.brs"

' Advanced string manipulation functions
Function FormatPhoneNumber(phone As String) As String
    ' Remove all non-digits
    digits = ""
    for i = 1 to Len(phone)
        ch$ = Mid(phone, i, 1)
        if ch$ >= "0" and ch$ <= "9" then
            digits = digits + ch$
        end if
    end for

    ' Format as (XXX) XXX-XXXX
    if Len(digits) = 10 then
        return "(" + Left(digits, 3) + ") " + Mid(digits, 4, 3) + "-" + Right(digits, 4)
    else
        return phone  ' Return original if not 10 digits
    end if
End Function

Function ParseQueryString(query As String) As Object
    params = {}
    pairs = query.Tokenize("&")

    for each pair in pairs
        parts = pair.Tokenize("=")
        if parts.Count() = 2 then
            key = parts[0]
            value = parts[1]
            params[key] = value
        end if
    end for

    return params
End Function


Sub Main()
    ' Display test name
    ShowMessage("04: String Functions")
    
    ' Test phone number formatting
    rawPhone = "1234567890"
    formatted = FormatPhoneNumber(rawPhone)
    print "Raw: " + rawPhone
    print "Formatted: " + formatted
    
    ' Test query string parsing
    queryString = "name=BrightScript&version=1.0&debug=true"
    params = ParseQueryString(queryString)
    
    print "Query parameters:"
    for each key in params
        print "  " + key + " = " + params[key]
    end for
End Sub