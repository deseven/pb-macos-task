EnableExplicit

IncludeFile "task.pbi"

Define task1.task::task
Define task2.task::task
Define task3.task::task
Define task4.task::task
Define task5.task::task

Debug "running task..."
task1\path = "/bin/echo"
AddElement(task1\args()) : task1\args() = "test"
If task::run(@task1)
  Debug "pid: " + Str(task1\pid)
Else
  Debug "task failed"
EndIf

Debug "----------"

Debug "running task and waiting for it to finish..."
task2\path = "/bin/sleep"
AddElement(task2\args()) : task2\args() = "3"
task2\wait_program = #True
If task::run(@task2)
  Debug "pid: " + Str(task2\pid)
  Debug "exit code: " + Str(task2\exit_code)
Else
  Debug "task failed"
EndIf

Debug "----------"

Debug "running task that produces some output..."
With task3
  \path = "/bin/cat"
  AddElement(\args()) : \args() = "/etc/hosts"
  AddElement(\args()) : \args() = "/non/existent/file"
  \read_output = #True
  If task::run(@task3)
    Debug "stdout: " + \stdout
    Debug "stderr: " + \stderr
  Else
    Debug "task failed"
  EndIf
EndWith

Debug "----------"

Debug "running a task in a thread that will produce an event..."
With task4
  \path = "/sbin/ping"
  AddElement(\args()) : \args() = "-q"
  AddElement(\args()) : \args() = "-c"
  AddElement(\args()) : \args() = "3"
  AddElement(\args()) : \args() = "127.0.0.1"
  \wait_program = #True
  \read_output = #True
  \finish_event = #PB_Event_FirstCustomValue
  \is_thread = #True ; very important!
EndWith
Define taskThread = CreateThread(task::@run(),@task4)
If IsThread(taskThread)
  OpenWindow(0,0,0,0,0,"",#PB_Window_Invisible)
  Repeat : Until WaitWindowEvent() = #PB_Event_FirstCustomValue
  CloseWindow(0)
  With task4
    Debug "pid: " + Str(\pid)
    Debug "exit code: " + Str(\exit_code)
    Debug "stdout: " + \stdout
    Debug "stderr: " + \stderr
  EndWith
Else
  Debug "task failed"
EndIf

Debug "----------"

Debug "running a task that will fail to run..."
With task5
  \path = "/no/such/file"
  \wait_program = #True
EndWith
If task::run(@task5)
  Debug "pid: " + Str(task5\pid)
  Debug "exit code: " + Str(task5\exit_code)
Else
  Debug "task failed"
EndIf