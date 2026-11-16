#NoEnv
#NoTrayIcon
#Persistent
#SingleInstance Off
SetBatchLines, -1
; Launched only by run-tests.py against a new disposable directory.
global IniPath:=A_Args[1] "\history.ini", CounterStoreReady:=false
global SavedCounterDates:={}, HistoryDates:=[], today:=SubStr(A_Now,1,8)
global firstday, DataStorageDays, mouse:={}, keyboard:={}
global devicecaps:={w:300,h:200}, layout:={kw:52,kh:45,ks:2,khs:10,kvs:10}
global hHookMouse:=0, hHookKeyboard:=0
if (A_Args.Length()!=2 or !InStr(FileExist(A_Args[1]),"D"))
  ExitApp, 2
RuntimeInit(A_Args[1])
InitializeCounterStore()
LoadCounterDay(today)
RuntimeStart()
if (!SaveData("startup"))
  ExitApp, 3
if (A_Args[2]="abrupt")
{
  CountPhysicalKey(30)
  if (!SaveData("checkpoint_before_abrupt"))
    ExitApp, 4
  CountPhysicalKey(31)
  FileAppend, ready, % A_Args[1] "\ready.txt"
}
else
{
  CountPhysicalKey(32)
  ExitApp, 7
}
return

; The test never allocates GUI resources. Production uses Class_CtlColors.
class CtlColors
{
  Free()
  {
  }
}
#Include %A_ScriptDir%\..\lib\CounterStore.ahk
#Include %A_ScriptDir%\..\lib\RuntimePersistence.ahk
