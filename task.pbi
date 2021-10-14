; pb-macos-task rev.1
; written by deseven
;
; https://github.com/deseven/pb-macos-task

DeclareModule task
  
  Structure task
    path.s
    workdir.s
    List args.s()
    wait_program.b
    is_thread.b
    finish_event.i
    pid.i
    exit_code.l
    stdin.s
    stdout.s
    stderr.s
  EndStructure
  
  Declare run(*task.task)
  
EndDeclareModule

Module task
  
  Procedure run(*task.task)
    Protected i
    Protected task
    Protected arg.s
    Protected argsArray
    Protected writePipe,writeHandle,string,stringData
    Protected readPipe,readHandle,errorPipe,errorHandle
    Protected outputData,errorData,stdoutNative,stderrNative
    
    If FileSize(*task\path) > 0
      
      If *task\is_thread
        Protected Pool = CocoaMessage(0,0,"NSAutoreleasePool new")
      EndIf
      
      If ListSize(*task\args())
        SelectElement(*task\args(),0)
        arg = *task\args()
        argsArray = CocoaMessage(0,0,"NSArray arrayWithObject:$",@arg)
        If ListSize(*task\args()) > 1
          For i = 1 To ListSize(*task\args()) - 1
            SelectElement(*task\args(),i)
            arg = *task\args()
            argsArray = CocoaMessage(0,argsArray,"arrayByAddingObject:$",@arg)
          Next
        EndIf
      EndIf
      
      task = CocoaMessage(0,CocoaMessage(0,0,"NSTask alloc"),"init")
      
      CocoaMessage(0,task,"setLaunchPath:$",@*task\path)
      
      If argsArray
        CocoaMessage(0,task,"setArguments:",argsArray)
      EndIf
      
      If *task\workdir
        CocoaMessage(0,task,"setCurrentDirectoryPath:$",@*task\workdir)
      EndIf
      
      If *task\stdin
        writePipe = CocoaMessage(0,0,"NSPipe pipe")
        writeHandle = CocoaMessage(0,writePipe,"fileHandleForWriting")
        CocoaMessage(0,task,"setStandardInput:",writePipe)
        string = CocoaMessage(0,0,"NSString stringWithString:$",@*task\stdin)
        stringData = CocoaMessage(0,string,"dataUsingEncoding:",#NSUTF8StringEncoding)
      EndIf
      
      If *task\wait_program
        readPipe = CocoaMessage(0,0,"NSPipe pipe")
        readHandle = CocoaMessage(0,readPipe,"fileHandleForReading")
        errorPipe = CocoaMessage(0,0,"NSPipe pipe")
        errorHandle = CocoaMessage(0,errorPipe,"fileHandleForReading")
        CocoaMessage(0,task,"setStandardOutput:",readPipe)
        CocoaMessage(0,task,"setStandardError:",errorPipe)
      EndIf
      
      CocoaMessage(0,task,"launch")
      
      *task\pid = CocoaMessage(0,task,"processIdentifier")
      
      If *task\stdin
        CocoaMessage(0,writeHandle,"writeData:",stringData)
        CocoaMessage(0,writeHandle,"closeFile")
      EndIf
      
      If *task\wait_program
        outputData = CocoaMessage(0,readHandle,"readDataToEndOfFile")
        CocoaMessage(0,readHandle,"closeFile")
        errorData = CocoaMessage(0,errorHandle,"readDataToEndOfFile")
        CocoaMessage(0,errorHandle,"closeFile")
        CocoaMessage(0,task,"waitUntilExit")
        *task\exit_code = CocoaMessage(0,task,"terminationStatus")
        If outputData
          stdoutNative = CocoaMessage(0,CocoaMessage(0,0,"NSString alloc"),"initWithData:",outputData,"encoding:",#NSUTF8StringEncoding)
          *task\stdout = PeekS(CocoaMessage(0,stdoutNative,"UTF8String"),-1,#PB_UTF8)
        EndIf
        If errorData
          stderrNative = CocoaMessage(0,CocoaMessage(0,0,"NSString alloc"),"initWithData:",errorData,"encoding:",#NSUTF8StringEncoding)
          *task\stderr = PeekS(CocoaMessage(0,stderrNative,"UTF8String"),-1,#PB_UTF8)
        EndIf
      EndIf
      
      CocoaMessage(0,task,"release")
      
      If Pool
        CocoaMessage(0,Pool,"release")
      EndIf
      
      If *task\finish_event
        PostEvent(*task\finish_event)
      EndIf
      
      ProcedureReturn #True
    EndIf
  EndProcedure
  
EndModule