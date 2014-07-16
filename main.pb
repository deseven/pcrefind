#name = "PCREfinder"
#ver = "1.2.1." + #PB_Editor_BuildCount
CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  #path = "/"
  #inputposy = 566
CompilerElse
  #path = ""
  #inputposy = 568
CompilerEndIf

Mutex = CreateMutex()

OpenWindow(0,#PB_Ignore,#PB_Ignore,800,600,#name + " " + #ver,#PB_Window_SystemMenu|#PB_Window_ScreenCentered)
FindBtn = ButtonGadget(#PB_Any,10,568,240,25,"Find")

Global PCREinput = ComboBoxGadget(#PB_Any,260,#inputposy,530,25,#PB_ComboBox_Editable)
AddGadgetItem(PCREinput,-1,"eMail: " + Chr(9) + "([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})")
AddGadgetItem(PCREinput,-1,"IPv4: " + Chr(9) + "\b(?:\d{1,3}\.){3}\d{1,3}\b") ;ip
AddGadgetItem(PCREinput,-1,"Time: " + Chr(9) + "([01]?[0-9]|2[0-3]):[0-5][0-9]") ;hex
AddGadgetItem(PCREinput,-1,"URL: " + Chr(9) + "(https?://([-\w\.]+)+(:\d+)?(/([\w/_\.]*(\?\S+)?)?)?)") ;url
AddGadgetItem(PCREinput,-1,"HTML: " + Chr(9) + "</?\w+((\s+\w+(\s*=\s*(?:" + #DQUOTE$ + ".*?" + #DQUOTE$ + "|'.*?'|[^'" +#DQUOTE$ + ">\s]+))?)+\s*|\s*)/?>") ;html


Global DirSelector = ExplorerTreeGadget(#PB_Any,10,10,240,550,#path,#PB_Explorer_AlwaysShowSelection|#PB_Explorer_NoFiles|#PB_Explorer_AutoSort)
Global Results = ListViewGadget(#PB_Any,260,10,530,550)
Global Dim Results$(0)
Global Placeholder = TextGadget(#PB_Any,10,570,780,25,"...",#PB_Text_Center)
HideGadget(Placeholder,1)
FindInProgress = #False

Enumeration
  #m_error
  #m_info
  #m_question
EndEnumeration

Procedure Message(message.s,type)
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Select type
      Case #m_error
        MessageBox_(0,message,#name,#MB_OK|#MB_ICONERROR)
      Case #m_info
        MessageBox_(0,message,#name,#MB_OK|#MB_ICONINFORMATION)
      Case #m_question
        If MessageBox_(0,message,#name,#MB_YESNO|#MB_ICONQUESTION) = #IDYES
          ProcedureReturn #True
        Else
          ProcedureReturn #False
        EndIf
      Default
        MessageBox_(0,message,MyName,#MB_OK|#MB_ICONINFORMATION)
    EndSelect
  CompilerElse
    Select type
      Case #m_error
        MessageRequester(#name,message,#PB_MessageRequester_Ok)
      Case #m_info
        MessageRequester(#name,message,#PB_MessageRequester_Ok)
      Case #m_question
        If MessageRequester(#name,message,#PB_MessageRequester_YesNo) = #PB_MessageRequester_Yes
          ProcedureReturn #True
        Else
          ProcedureReturn #False
        EndIf
      Default
        MessageRequester(#name,message,#PB_MessageRequester_Ok)
    EndSelect
  CompilerEndIf
  ProcedureReturn #True
EndProcedure

Procedure Find(dummy)
  Shared Mutex
  PCRE.s = GetGadgetText(PCREinput)
  If FindString(PCRE,Chr(9))
    PCRE = StringField(PCRE,2,Chr(9))
  EndIf
  If Len(PCRE) > 1
    If ExamineDirectory(0,GetGadgetText(DirSelector),"*.*")
      ClearGadgetItems(Results)
      SetCurrentDirectory(GetGadgetText(DirSelector))
      If CreateRegularExpression(0,PCRE,#PB_RegularExpression_AnyNewLine)
        While NextDirectoryEntry(0)
          If DirectoryEntryType(0) = #PB_DirectoryEntry_File
            If ReadFile(0,DirectoryEntryName(0),#PB_File_SharedRead)
              SetGadgetText(Placeholder,DirectoryEntryName(0))
              line = 1
              While Not Eof(0)
                Found = ExtractRegularExpression(0,ReadString(0),Results$())
                For i = 0 To Found - 1
                  LockMutex(Mutex)
                  AddGadgetItem(Results,-1,"[" + DirectoryEntryName(0) + ":" + line + "] " + Results$(i))
                  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
                    SetGadgetState(Results,CountGadgetItems(Results)-1)
                  CompilerEndIf
                  UnlockMutex(Mutex)
                Next
                ReDim Results$(0)
                line + 1
              Wend
              CloseFile(0)
            EndIf
          EndIf
        Wend
        FreeRegularExpression(0)
      Else
        Message(RegularExpressionError(),#m_error)
      EndIf
      FinishDirectory(0)
    Else
      Message("Select the directory first!",#m_error)
    EndIf
  Else
    Message("Empty expression!",#m_error)
  EndIf
EndProcedure

Repeat
  ev = WaitWindowEvent(300)
  If FindInProgress
    If Not IsThread(FindThread)
      SetGadgetText(Placeholder,"...")
      HideGadget(Placeholder,1)
      HideGadget(FindBtn,0)
      HideGadget(PCREinput,0)
      FindInProgress = #False
      SetGadgetState(Results,CountGadgetItems(Results)-1)
    EndIf
  EndIf
  If ev = #PB_Event_Gadget And EventGadget() = FindBtn And Not FindInProgress
    FindThread = CreateThread(@Find(),dummy)
    FindInProgress = #True
    HideGadget(FindBtn,1)
    HideGadget(PCREinput,1)
    HideGadget(Placeholder,0)
    SetActiveGadget(Results)
  EndIf
Until ev = #PB_Event_CloseWindow
; IDE Options = PureBasic 5.20 LTS (MacOS X - x86)
; CursorPosition = 72
; FirstLine = 65
; Folding = -
; EnableXP
; CompileSourceDirectory