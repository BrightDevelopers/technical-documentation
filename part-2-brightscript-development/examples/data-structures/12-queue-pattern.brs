Library "common-functions.brs"

' FIFO queue implementation with standard operations
Function CreateQueue() As Object
    return {
        items: [],

        enqueue: Function(item As Dynamic) As Void
            m.items.Push(item)
        End Function,

        dequeue: Function() As Dynamic
            if m.items.Count() > 0 then
                return m.items.Shift()
            end if
            return invalid
        End Function,

        peek: Function() As Dynamic
            if m.items.Count() > 0 then
                return m.items[0]
            end if
            return invalid
        End Function,

        isEmpty: Function() As Boolean
            return m.items.Count() = 0
        End Function,

        size: Function() As Integer
            return m.items.Count()
        End Function
    }
End Function

Sub Main()
    ShowMessage("12: Queue Pattern")
    
    ' Create and test queue
    queue = CreateQueue()
    
    if queue.isEmpty() then
        print("Queue is empty: true")
    else
        print("Queue is empty: false")
    end if
    
    ' Add items
    queue.enqueue("First")
    queue.enqueue("Second") 
    queue.enqueue("Third")
    
    print("Queue size: " + queue.size().ToStr())
    print("Next item: " + queue.peek())
    
    ' Remove items
    while not queue.isEmpty()
        item = queue.dequeue()
        print("Dequeued: " + item)
    end while
    
    if queue.isEmpty() then
        print("Queue is empty: true")
    else
        print("Queue is empty: false")
    end if
End Sub