#NoEnv
#NoTrayIcon
#SingleInstance Off
SetBatchLines, -1

; Synthetic INIs only. No application startup, hooks, hotkeys, or GUI.
global IniPath, CounterStoreReady, SavedCounterDates, HistoryDates
global today, firstday, DataStorageDays, mouse, keyboard
global devicecaps := {w:300,h:200}, layout := {kw:52,kh:45,ks:2,khs:10,kvs:10}
global RuntimeReady, RuntimeSaving, RuntimePid, RuntimeDirtyDays, RuntimeRevision
global RuntimeSavedRevision, RuntimeEvents, RuntimeLogPath, RuntimeStatePath
global RuntimeLastSave, RuntimeLastHeartbeat, Checks:=0, TestDir
try
{
  parent := A_Args.Length() ? A_Args[1] : A_Temp
  if (!InStr(FileExist(parent),"D"))
    throw Exception("Test output parent must already exist")
  TestDir := parent "\KMCounter-runtime-tests-" A_Now "-" DllCall("GetCurrentProcessId") "-" A_TickCount
  if (FileExist(TestDir))
    throw Exception("Refusing to reuse test directory")
  FileCreateDir, %TestDir%
  if (ErrorLevel)
    throw Exception("Cannot create test directory")
  RunTests()
  FileAppend, % "PASS ALL " Checks " checks`nSynthetic fixtures: " TestDir "`n", *
}
catch e
{
  FileAppend, % "FAIL " e.Message " | " e.Extra " | line " e.Line "`n", *
  ExitApp, 1
}
ExitApp, 0

RunTests()
{
  global
  IniPath := TestDir "\history.ini"
  fixture := "[history]`r`nstorage=30`r`n[20240101]`r`nkeystrokes=4`r`nsc30=4`r`n"
    . "[total]`r`nkeystrokes=20`r`nsc30=20`r`n[custom]`r`nnote=保留 Unicode`r`n"
  f := FileOpen(IniPath,"w","UTF-16")
  f.Write(fixture), f.Close()
  RuntimeLogPath := TestDir "\runtime.log", RuntimeStatePath := TestDir "\runtime.state"
  ResetStore("20240131")
  base := keyboard.total.keystrokes
  CountPhysicalKey(30)
  CountPhysicalKey(30)
  Assert(SaveData("checkpoint"),"atomic checkpoint succeeds")
  Assert(IniRead(IniPath,today,"keystrokes",-1)=2,"live counts persisted")
  Assert(IniRead(IniPath,"custom","note","")="保留 Unicode","unknown Unicode configuration preserved")
  RuntimeEnsureDay("20240201")
  CountPhysicalKey(31)
  Assert(keyboard[20240131].keystrokes=2 and keyboard[today].keystrokes=1,"month boundary separates days")
  Assert(keyboard.total.keystrokes=base+3,"rollover retains lifetime total")
  Assert(SaveData("rollover"),"rollover checkpoint succeeds")
  Assert(IniRead(IniPath,"20240131","keystrokes",-1)=2 and IniRead(IniPath,"20240201","keystrokes",-1)=1,"both days persist")
  RuntimeEnsureDay("20240210")
  CountPhysicalKey(32)
  Assert(!SavedCounterDates.HasKey("20240205"),"sleep gap does not invent daily records")
  RuntimeEnsureDay("20240131")
  CountPhysicalKey(33)
  Assert(keyboard[today].keystrokes=3 and keyboard.total.keystrokes=base+5,"clock rollback resumes cached day")
  Assert(SaveData("backward_clock"),"backward clock save succeeds")
  total := keyboard.total.keystrokes
  ResetStore("20240210")
  Assert(keyboard.total.keystrokes=total and keyboard[today].keystrokes=1,"restart preserves totals and current day")
  RuntimeEnsureDay("20240101")
  CountPhysicalKey(30)
  Assert(keyboard[today].keystrokes=5,"clock rollback loads a previously uncached saved day")
  RuntimeEnsureDay("20241231")
  CountPhysicalKey(34)
  RuntimeEnsureDay("20250101")
  CountPhysicalKey(35)
  Assert(SaveData("year_boundary"),"year boundary persists without process replacement")
  RuntimeEnsureDay("20280228")
  CountPhysicalKey(36)
  RuntimeEnsureDay("20280229")
  CountPhysicalKey(37)
  RuntimeEnsureDay("20280301")
  CountPhysicalKey(38)
  Assert(SaveData("leap_boundary") and IniRead(IniPath,"20280229","keystrokes",-1)=1,"leap day survives save")
  FileRead, beforeFailure, %IniPath%
  lock := FileOpen(IniPath,"r-d","UTF-16")
  Assert(IsObject(lock),"only disposable destination is locked")
  CountPhysicalKey(39)
  Assert(!SaveData("locked_destination"),"replace failure is reported")
  lock.Close()
  FileRead, afterFailure, %IniPath%
  Assert(beforeFailure==afterFailure,"failed replace leaves the entire original unchanged")
  Assert(RuntimeDirtyDays.Count()>0,"failed save retains dirty counters")
  Assert(SaveData("retry"),"retry commits after unlocking")
  Assert(IniRead(IniPath,today,"sc39",-1)=1,"retry preserves unsaved counter")
  FileRead, previous, % IniPath ".previous"
  Assert(previous==beforeFailure,"previous checkpoint is exact previous text")
  FileRead, logText, %RuntimeLogPath%
  Assert(InStr(logText,"event=save_failed") and InStr(logText,"event=save_ok"),"save results are logged")
  FileGetTime, timeBefore, %IniPath%, M
  Sleep, 1100
  Assert(SaveData("idle",false),"idle tick succeeds")
  FileGetTime, timeAfter, %IniPath%, M
  Assert(timeBefore=timeAfter,"idle tick avoids writing")
  RuntimeEnsureDay("20280302")
  CountPhysicalKey(40)
  RuntimeLastSave := A_TickCount-60001
  RuntimeMaintenance("20280302")
  Assert(IniRead(IniPath,today,"sc40",-1)=1,"maintenance commits after interval or rollover")
  CountPhysicalKey(41)
  RuntimeLastSave := A_TickCount
  RuntimeMaintenance(today)
  Assert(IniRead(IniPath,today,"sc41",0)=0,"maintenance waits until the next checkpoint")
  RuntimeLastSave := A_TickCount-60001
  RuntimeMaintenance(today)
  Assert(IniRead(IniPath,today,"sc41",0)=1,"periodic checkpoint saves new counter")
  Assert(IniRead(IniPath,"20240101","keystrokes",0)=5,"old history survives all checkpoints")
  rejected := false
  try
    RuntimeEnsureDay("20230229")
  catch e
    rejected := true
  Assert(rejected and today="20280302","invalid date leaves current date unchanged")
  RuntimeSaving := true
  Assert(ExitFunc("Reload",9)=1,"exit during checkpoint is deferred")
  SetTimer, RuntimeDeferredExit, Off
  Assert(RuntimeDeferredReason="Reload" and RuntimeDeferredCode=9,"deferred exit retains reload intent and code")
  RuntimeSaving := false
  ; Read failure must not leave the caller in a new Critical state.
  IniWrite(-1,IniPath,"20230201","keystrokes")
  SavedCounterDates[20230201] := true
  criticalBefore := A_IsCritical, rejected := false
  try
    RuntimeEnsureDay("20230201")
  catch e
    rejected := true
  Assert(rejected and A_IsCritical=criticalBefore,"failed rollover restores caller's Critical state (rejected=" rejected ", before=" criticalBefore ", after=" A_IsCritical ")")
}

ResetStore(day)
{
  global
  today:=day, CounterStoreReady:=false, SavedCounterDates:={}, HistoryDates:=[]
  mouse:={}, keyboard:={}, RuntimeDirtyDays:={}, RuntimeRevision:=0
  RuntimeSavedRevision:=-1, RuntimeSaving:=false, RuntimeReady:=true, RuntimeEvents:=[]
  RuntimePid:=DllCall("GetCurrentProcessId"), RuntimeLastSave:=A_TickCount, RuntimeLastHeartbeat:=A_TickCount
  InitializeCounterStore()
  LoadCounterDay(today)
}

Assert(condition,label)
{
  global Checks
  Checks += 1
  if (!condition)
    throw Exception(label)
  FileAppend, % "PASS " Checks " " label "`n", *
}

#Include %A_ScriptDir%\..\lib\CounterStore.ahk
#Include %A_ScriptDir%\..\lib\RuntimePersistence.ahk
