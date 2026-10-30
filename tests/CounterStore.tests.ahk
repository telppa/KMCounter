#NoEnv
#NoTrayIcon
#SingleInstance Off
SetBatchLines, -1

; This test has no input hooks, hotkeys, GUI or application startup code.
global IniPath, CounterStoreReady, SavedCounterDates, HistoryDates
global today := "20240104", firstday, DataStorageDays, mouse, keyboard
global devicecaps := {w:300, h:200}, layout := {kw:52, kh:45, ks:2, khs:10, kvs:10}
global Checks := 0, TestDir

try
{
  parent := A_Args.Length() ? A_Args[1] : A_Temp
  if (!InStr(FileExist(parent), "D"))
    throw Exception("Test output parent directory must already exist")
  TestDir := parent "\KMCounter-tests-" A_Now "-" DllCall("GetCurrentProcessId") "-" A_TickCount
  if (FileExist(TestDir))
    throw Exception("Refusing to reuse an existing test directory")
  FileCreateDir, %TestDir%
  if (ErrorLevel)
    throw Exception("Cannot create isolated test directory")
  RunTests()
  FileAppend, % "PASS ALL " Checks " checks`nSynthetic fixtures: " TestDir "`n", *
}
catch e
{
  FileAppend, % "FAIL: " e.Message " | " e.Extra " | line " e.Line "`n", *
  ExitApp, 1
}
ExitApp, 0

RunTests()
{
  global
  fixture := "[history]`r`nstorage=999999999`r`n"
    . "[20240101]`r`nkeystrokes=10`r`nsc30=10`r`nlbcount=3`r`nmove=0.125`r`n"
    . "[20240103]`r`nkeystrokes=20`r`nsc30=17`r`nsc777=3`r`nlbcount=7`r`nmove=0.25`r`n"
    . "[total]`r`nkeystrokes=15`r`nsc30=15`r`nsc777=100`r`nlbcount=5`r`nmove=0.1`r`n"
    . "[custom]`r`nnote=keep-this`r`n"
  file := NewFixture("history.ini", fixture)
  ResetStore(file)
  InitializeCounterStore()
  Assert(DataStorageDays=0, "oversized legacy setting becomes show-all")
  Assert(SavedCounterDates.Count()=2, "both recorded dates are indexed")
  Assert(HistoryDates.Length()=4, "index includes recorded dates, today and Total")
  Assert(keyboard.total.keystrokes=30, "undercounted total recovers from daily records")
  Assert(keyboard.total.sc30=27, "per-key total recovers from daily records")
  Assert(keyboard.total.sc777=100, "higher lifetime value is preserved")
  Assert(mouse.total.lbcount=10, "mouse total recovers from daily records")
  Assert(mouse.total.move=0.375, "fractional mouse distance is preserved")
  InitializeCounterStore()
  Assert(keyboard.total.keystrokes=30, "initialization does not double count")
  Assert(LoadCounterDay(today), "new current day can be loaded")
  CountPhysicalKey(30)
  CountPhysicalKey(777)
  CountPhysicalKey(999)
  mouse[today].lbcount += 2
  mouse.total.lbcount += 2
  Assert(keyboard[today].keystrokes=3, "new day records each key once")
  Assert(keyboard.total.sc777=101, "new daily key does not reset lifetime key count")
  Assert(keyboard.total.sc999=1, "unlisted key is counted")
  Assert(LoadCounterDay("20240101"), "first historical date loads")
  Assert(LoadCounterDay("20240103"), "second historical date loads")
  Assert(keyboard.total.keystrokes=33, "history browsing preserves live keystrokes")
  Assert(keyboard.total.sc30=28, "history browsing preserves live per-key total")
  Assert(mouse.total.lbcount=12, "history browsing preserves live mouse total")
  Assert(keyboard[today].keystrokes=3, "history browsing preserves today")
  historicalDate := "20240103"
  Assert(keyboard[historicalDate].sc777=3, "historical keys outside the layout are loaded")
  Assert(!LoadCounterDay("20240102"), "missing day is not invented")
  Assert(NextHistoryDate("20240101",1)="20240103", "navigation skips a missing day")
  Assert(NextHistoryDate("20240103",-1)="20240101", "reverse navigation skips a missing day")
  Assert(NextHistoryDate(today,1)="Total", "today advances to Total")
  Assert(NextHistoryDate("Total",1)="20240101", "Total wraps to first saved day")
  Assert(NextHistoryDate("20240101",-1)="Total", "first day wraps backwards to Total")
  current := today, seen := {}
  Loop, % HistoryDates.Length()
  {
    current := NextHistoryDate(current,1)
    seen[current] := true
  }
  Assert(seen.Count()=4 and current=today, "navigation completes a bounded cycle")
  Assert(NormalizeHistoryDays(0)=0, "zero means all history")
  Assert(NormalizeHistoryDays(30)=30, "finite display window is accepted")
  Assert(NormalizeHistoryDays(36500)=36500, "upper supported value is accepted")
  Assert(NormalizeHistoryDays(-1)=0, "negative setting cannot prune data")
  Assert(NormalizeHistoryDays("invalid")=0, "invalid setting cannot prune data")
  Assert(IsCounterDate("20240229") and !IsCounterDate("20230229"), "leap years are validated")
  Assert(!IsCounterDate("99999999") and !IsCounterDate("total"), "invalid dates are rejected")
  DataStorageDays := 1
  BuildHistoryIndex()
  Assert(HistoryDates.Length()=3 and HistoryDates[1]="20240103", "finite window filters history view")
  Assert(SavedCounterDates.Count()=2, "finite window keeps all known dates")
  SaveData()
  Assert(IniRead(file,"20240101","keystrokes",-1)=10, "save does not delete oldest day")
  Assert(IniRead(file,"20240103","sc777",-1)=3, "save preserves historical unlisted key")
  Assert(IniRead(file,"custom","note","")="keep-this", "unknown configuration survives save")
  Assert(IniRead(file,"history","storage",-1)=36500, "legacy reader receives nonzero retention")
  Assert(IniRead(file,"history","view_days",-1)=1, "display window uses its own setting")
  ResetStore(file)
  InitializeCounterStore()
  Assert(keyboard.total.keystrokes=33, "save and reload do not double count")
  Assert(keyboard.total.sc777=101, "save and reload retain higher lifetime total")
  Assert(DataStorageDays=1, "new setting takes precedence over legacy field")
  LoadCounterDay(today)
  Assert(keyboard[today].sc999=1, "reload retains unlisted daily key")
  CountPhysicalKey(999)
  Assert(keyboard.total.sc999=2, "unlisted key continues correctly after reload")
  DataStorageDays := 0
  BuildHistoryIndex()
  Assert(HistoryDates[1]="20240101", "show-all restores access to old records")

  ResetStore(NewFixture("total-only.ini", "[total]`nkeystrokes=500`nsc30=500`n"))
  InitializeCounterStore()
  Assert(keyboard.total.keystrokes=500, "missing daily history does not erase total")
  Assert(HistoryDates.Length()=2 and HistoryDates[2]="Total", "empty history has bounded navigation")

  ResetStore(TestDir "\first-run.ini")
  InitializeCounterStore()
  Assert(keyboard.total.keystrokes=0 and mouse.total.lbcount=0, "first run works without an INI")
  LoadCounterDay(today)
  CountPhysicalKey(30)
  SaveData()
  Assert(IniRead(IniPath,"total","keystrokes",-1)=1, "first run can save its first counter")

  bad := "[20240101]`r`nkeystrokes=-1`r`n[total]`r`nkeystrokes=10`r`n"
  ResetStore(NewFixture("malformed.ini", bad))
  rejected := false
  try
    InitializeCounterStore()
  catch e
    rejected := true
  Assert(rejected, "invalid counter fails instead of overwriting data")
  FileRead, after, %IniPath%
  Assert(after=bad, "invalid input remains unchanged")
}

ResetStore(path)
{
  global
  IniPath := path, CounterStoreReady := false
  SavedCounterDates := {}, HistoryDates := [], mouse := {}, keyboard := {}
}

NewFixture(name, content)
{
  global TestDir
  path := TestDir "\" name
  if (FileExist(path))
    throw Exception("Refusing to overwrite test fixture", -1, name)
  file := FileOpen(path, "w", "UTF-16")
  if (!IsObject(file))
    throw Exception("Cannot create test fixture", -1, name)
  file.Write(content)
  file.Close()
  return path
}

Assert(condition, label)
{
  global Checks
  Checks += 1
  if (!condition)
    throw Exception(label)
  FileAppend, % "PASS " Checks " " label "`n", *
}

#Include %A_ScriptDir%\..\lib\CounterStore.ahk
