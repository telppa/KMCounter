; Periodic checkpoints and lifecycle diagnostics. No input hooks in this module.
RuntimeInit(directory:="")
{
  global RuntimeLogPath, RuntimeStatePath, RuntimePid, RuntimeReady, RuntimeRevision
  global RuntimeSavedRevision, RuntimeDirtyDays, RuntimeSaving, RuntimeLastSave
  global RuntimeLastHeartbeat, RuntimeEvents, RuntimeOwnsSession, RuntimeSessionStart
  if (directory="")
    directory := A_ScriptDir
  RuntimePid := DllCall("GetCurrentProcessId")
  RuntimeLogPath := directory "\KMCounter-runtime.log"
  RuntimeStatePath := directory "\KMCounter-runtime.state"
  RuntimeReady := false, RuntimeOwnsSession := false, RuntimeSaving := false
  RuntimeRevision := 0, RuntimeSavedRevision := -1, RuntimeDirtyDays := {}
  RuntimeLastSave := A_TickCount, RuntimeLastHeartbeat := A_TickCount
  RuntimeEvents := [], RuntimeSessionStart := A_Now
  OnExit("ExitFunc")
  OnError("RuntimeError")
  RuntimeLog("startup_begin")
}

RuntimeStart()
{
  global RuntimeReady, RuntimeOwnsSession, RuntimeStatePath, RuntimePid, today
  previous := ""
  if (FileExist(RuntimeStatePath))
    FileRead, previous, %RuntimeStatePath%
  if (SubStr(previous,1,7)="running" or SubStr(previous,1,16)="exit_save_failed")
    RuntimeLog("previous_session_unclean", Trim(previous))
  RuntimeOwnsSession := true
  RuntimeWriteState("running")
  RuntimeReady := true
  RuntimeMarkDirty()
  RuntimeLog("startup_ready", "date=" today " pid=" RuntimePid)
  SetTimer, RuntimeMaintenance, 5000
}

RuntimeLog(event, detail:="")
{
  global RuntimeLogPath, RuntimePid
  if (RuntimeLogPath="")
    return false
  try
  {
    if (FileExist(RuntimeLogPath))
    {
      FileGetSize, size, %RuntimeLogPath%
      if (size > 2097152)
        FileMove, %RuntimeLogPath%, % RuntimeLogPath ".1", 1
    }
    detail := StrReplace(StrReplace(detail,"`r"," "),"`n"," ")
    FileAppend, % A_Now " pid=" RuntimePid " event=" event " " detail "`r`n", %RuntimeLogPath%, UTF-8
    return !ErrorLevel
  }
  catch e
    return false
}

RuntimeWriteState(state)
{
  global RuntimeStatePath, RuntimePid
  f := FileOpen(RuntimeStatePath, "w", "UTF-8")
  if (!IsObject(f))
    return false
  f.Write(state " " A_Now " pid=" RuntimePid)
  f.Close()
  return true
}

RuntimeError(e)
{
  RuntimeLog("unhandled_error", "line=" e.Line " what=" e.What " message=" e.Message)
  return 0 ; Preserve AHK's normal error handling; do not silently continue.
}

RuntimeMarkDirty()
{
  global RuntimeRevision, RuntimeDirtyDays, today
  RuntimeRevision += 1
  RuntimeDirtyDays[today] := RuntimeRevision
}

RuntimeEnsureDay(newDate:="")
{
  global today, mouse, keyboard, SavedCounterDates, RuntimeEvents
  if (newDate="")
    newDate := SubStr(A_Now,1,8)
  if (newDate=today)
    return false
  if (!IsCounterDate(newDate))
    throw Exception("Invalid rollover date",-1,newDate)
  oldCritical := A_IsCritical
  Critical
  try
  {
    oldDate := today
    ; Load a previously recorded date only if the clock moved back. No lifetime
    ; counters are reinitialized, and already cached dates keep their live counts.
    if (!IsObject(mouse[newDate]) or !IsObject(keyboard[newDate]))
    {
      data := SavedCounterDates.HasKey(newDate) ? ReadCounterSection(newDate) : {}
      mouse[newDate] := {}, keyboard[newDate] := {}
      for _, key in ["lbcount","rbcount","mbcount","xbcount","wheel","hwheel","move"]
        mouse[newDate,key] := data.HasKey(key) ? data[key] : 0
      for key,value in data
        if (key="keystrokes" or RegExMatch(key,"^sc\d+$"))
          keyboard[newDate,key] := value
      if (!keyboard[newDate].HasKey("keystrokes"))
        keyboard[newDate].keystrokes := 0
    }
    RuntimeMarkDirty()
    SavedCounterDates[oldDate] := true
    today := newDate
    RuntimeMarkDirty()
    SavedCounterDates[today] := true
    BuildHistoryIndex()
    RuntimeEvents.Push("from=" oldDate " to=" today)
  }
  finally
    Critical, %oldCritical%
  return true
}

RuntimeMaintenance(newDate:="")
{
  global RuntimeReady, RuntimeLastSave, RuntimeLastHeartbeat, RuntimeEvents
  if (!RuntimeReady)
    return
  try
  {
    changed := RuntimeEnsureDay(newDate)
    changed := changed or RuntimeEvents.Length()>0
    while (RuntimeEvents.Length())
      RuntimeLog("day_rollover_in_process",RuntimeEvents.RemoveAt(1))
    if (changed or A_TickCount-RuntimeLastSave >= 60000 or A_TickCount < RuntimeLastSave)
    {
      RuntimeLastSave := A_TickCount
      SaveData(changed ? "rollover" : "periodic",false)
    }
    if (A_TickCount-RuntimeLastHeartbeat >= 300000 or A_TickCount < RuntimeLastHeartbeat)
    {
      RuntimeLog("heartbeat")
      RuntimeLastHeartbeat := A_TickCount
    }
  }
  catch e
    RuntimeLog("maintenance_error","line=" e.Line " message=" e.Message)
}

RuntimeSnapshot()
{
  global RuntimeRevision, RuntimeDirtyDays, mouse, keyboard, today
  global DataStorageDays, devicecaps, layout
  oldCritical := A_IsCritical
  Critical
  snap := {revision:RuntimeRevision, versions:RuntimeDirtyDays.Clone(), sections:{}}
  for date,version in snap.versions
  {
    values := mouse[date].Clone()
    for key,value in keyboard[date]
      values[key] := value
    snap.sections[date] := values
  }
  values := mouse.total.Clone()
  for key,value in keyboard.total
    values[key] := value
  snap.sections.total := values
  snap.sections.history := {storage:36500, view_days:DataStorageDays}
  snap.sections.devicecaps := {w:devicecaps.w, h:devicecaps.h}
  snap.sections.layout := {kw:layout.kw, kh:layout.kh, ks:layout.ks, khs:layout.khs, kvs:layout.kvs}
  Critical, %oldCritical%
  return snap
}

RuntimePatchSection(text, section, updates)
{
  ; Names here are validated dates or fixed ASCII configuration names.
  if (!RegExMatch(section,"^(\d{8}|total|history|devicecaps|layout)$"))
    throw Exception("Unexpected section",-1,section)
  pattern := "im)^\[" section "\][ \t]*\r?\n(?:[^\[][^\r\n]*\r?\n|\r?\n|[^\[\r\n][^\r\n]*$)*"
  pos := RegExMatch(text,pattern,block)
  if (!pos)
    block := "[" section "]`r`n"
  remaining := updates.Clone(), output := ""
  ; Preserve all existing non-updated keys, comments and line endings.
  lines := StrSplit(block,"`n")
  for index,line in lines
  {
    if (index=lines.Length() and line="")
      break
    ending := SubStr(line,0)="`r" ? "`r`n" : "`n"
    if (RegExMatch(line,"^([^=;\r\n]+)=(.*)$",m))
    {
      key := Trim(m1)
      if (remaining.HasKey(key))
      {
        value := remaining[key]
        if (IsCounterField(key))
          CounterNumber(value,key)
        output .= key "=" value ending
        remaining.Delete(key)
        continue
      }
    }
    output .= RTrim(line,"`r") ending
  }
  for key,value in remaining
  {
    if (IsCounterField(key))
      CounterNumber(value,key)
    output .= key "=" value "`r`n"
  }
  if (pos)
    return SubStr(text,1,pos-1) output SubStr(text,pos+StrLen(block))
  return RTrim(text,"`r`n") "`r`n" output
}

RuntimeAtomicWrite(text, path)
{
  global RuntimePid
  stage := path ".writing-" RuntimePid
  previousStage := path ".previous-writing-" RuntimePid
  f := FileOpen(stage,"w","UTF-16")
  if (!IsObject(f))
    throw Exception("Cannot open checkpoint staging file",-1,A_LastError)
  try
  {
    written := f.Write(text)
    f.Read(0) ; Flush AHK's write buffer before the operating-system flush.
    if (written != StrLen(text)*2 or f.Length != StrLen(text)*2+2)
      throw Exception("Incomplete checkpoint write")
    if (!DllCall("FlushFileBuffers","Ptr",f.__Handle))
      throw Exception("Cannot flush checkpoint",-1,A_LastError)
  }
  finally
    f.Close()
  FileRead, verify, %stage%
  if (ErrorLevel or !(verify == text))
    throw Exception("Checkpoint read-back mismatch")
  if (FileExist(path))
  {
    FileCopy, %path%, %previousStage%, 1
    if (ErrorLevel)
      throw Exception("Cannot preserve previous checkpoint",-1,A_LastError)
    if (!DllCall("MoveFileExW","WStr",previousStage,"WStr",path ".previous","UInt",9))
      throw Exception("Cannot commit previous checkpoint",-1,A_LastError)
  }
  ; Same-volume replace only after a complete flushed and verified new file.
  if (!DllCall("MoveFileExW","WStr",stage,"WStr",path,"UInt",9))
    throw Exception("Cannot replace checkpoint",-1,A_LastError)
  DllCall("WritePrivateProfileStringW","Ptr",0,"Ptr",0,"Ptr",0,"WStr",path)
  return true
}

SaveData(reason:="manual",force:=true)
{
  global RuntimeSaving, RuntimeReady, RuntimeRevision, RuntimeSavedRevision
  global RuntimeDirtyDays, SavedCounterDates, IniPath, today
  if (!RuntimeReady or RuntimeSaving)
    return false
  if (!force and RuntimeRevision=RuntimeSavedRevision)
    return true
  RuntimeSaving := true
  started := A_TickCount
  try
  {
    if (force)
      RuntimeMarkDirty()
    snap := RuntimeSnapshot()
    text := ""
    if (FileExist(IniPath))
    {
      FileRead, text, %IniPath%
      if (ErrorLevel)
        throw Exception("Cannot read current history; refusing to replace")
    }
    for section,values in snap.sections
      text := RuntimePatchSection(text,section,values)
    RuntimeAtomicWrite(text,IniPath)
    oldCritical := A_IsCritical
    Critical
    for date,version in snap.versions
    {
      SavedCounterDates[date] := true
      if (RuntimeDirtyDays[date]=version)
        RuntimeDirtyDays.Delete(date)
    }
    RuntimeSavedRevision := snap.revision
    Critical, %oldCritical%
    RuntimeLog("save_ok","reason=" reason " date=" today " revision=" snap.revision " elapsed_ms=" (A_TickCount-started))
    return true
  }
  catch e
  {
    RuntimeLog("save_failed","reason=" reason " message=" e.Message " code=" e.Extra)
    return false
  }
  finally
    RuntimeSaving := false
}

ExitFunc(ExitReason,ExitCode)
{
  global RuntimeReady, RuntimeSaving, RuntimeOwnsSession, hHookMouse, hHookKeyboard
  global RuntimeDeferredReason, RuntimeDeferredCode
  RuntimeLog("exit_begin","reason=" ExitReason " code=" ExitCode)
  if (RuntimeSaving)
  {
    RuntimeLog("exit_deferred","checkpoint_in_progress original_reason=" ExitReason)
    RuntimeDeferredReason := ExitReason, RuntimeDeferredCode := ExitCode
    SetTimer, RuntimeDeferredExit, -500
    return 1
  }
  saved := !RuntimeReady or SaveData("exit_" ExitReason)
  if (!saved and ExitReason!="Shutdown" and ExitReason!="Logoff" and ExitReason!="Close")
  {
    RuntimeLog("exit_cancelled","save_failed; counter_kept_running")
    TrayTip, KMCounter, 保存失败，程序继续计数。请检查磁盘空间及 KMCounter-runtime.log。, 10, 3
    return 1
  }
  if (hHookMouse)
    DllCall("UnhookWindowsHookEx","Ptr",hHookMouse)
  if (hHookKeyboard)
    DllCall("UnhookWindowsHookEx","Ptr",hHookKeyboard)
  try
    CtlColors.Free()
  catch e
    RuntimeLog("cleanup_error",e.Message)
  if (RuntimeOwnsSession)
    RuntimeWriteState(saved ? "clean_exit" : "exit_save_failed")
  RuntimeLog("exit_complete","reason=" ExitReason " code=" ExitCode " saved=" saved)
  return 0
}

RuntimeDeferredExit()
{
  global RuntimeDeferredReason, RuntimeDeferredCode
  if (RuntimeDeferredReason="Reload")
  {
    Reload
    return
  }
  ExitApp, %RuntimeDeferredCode%
}
