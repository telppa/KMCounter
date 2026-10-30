; Persistence and history navigation. No hooks or GUI in this module.
NormalizeHistoryDays(value)
{
  ; Zero is an explicit show-all setting. No setting deletes stored records.
  if (!RegExMatch(value, "^\d+$") or value > 36500)
    return 0
  return value + 0
}

IsCounterField(key)
{
  return RegExMatch(key, "^(lbcount|rbcount|mbcount|xbcount|wheel|hwheel|move|keystrokes|sc\d+)$")
}

IsCounterDate(value)
{
  if (!RegExMatch(value, "^\d{8}$"))
    return false
  year := SubStr(value, 1, 4) + 0
  month := SubStr(value, 5, 2) + 0
  day := SubStr(value, 7, 2) + 0
  if (year < 1601 or month < 1 or month > 12 or day < 1)
    return false
  days := [31,28,31,30,31,30,31,31,30,31,30,31]
  if (Mod(year,400)=0 or (Mod(year,4)=0 and Mod(year,100)!=0))
    days[2] := 29
  return day <= days[month]
}

CounterNumber(text, field)
{
  if (!RegExMatch(text, "^\d+(\.\d+)?$"))
    throw Exception("Invalid counter value; refusing to overwrite data", -1, field "=" text)
  if (field != "move" and text + 0 != Floor(text + 0))
    throw Exception("Non-integer counter value", -1, field)
  return text + 0
}

InitializeCounterStore()
{
  global IniPath, CounterStoreReady, SavedCounterDates, HistoryDates
  global today, DataStorageDays, mouse, keyboard
  if (CounterStoreReady)
    return
  SavedCounterDates := {}, sums := {}, persisted := {}, section := ""
  content := ""
  if (FileExist(IniPath))
  {
    FileRead, content, %IniPath%
    if (ErrorLevel)
      throw Exception("Cannot read the counter file; no data has been changed", -1, IniPath)
  }
  content := StrReplace(StrReplace(content, "`r`n", "`n"), "`r", "`n")
  Loop, Parse, content, `n, `r
  {
    line := Trim(A_LoopField, " `t")
    if (RegExMatch(line, "^\[([^\]]+)\]$", match))
    {
      section := match1
      if (IsCounterDate(section))
        SavedCounterDates[section] := true
      continue
    }
    pos := InStr(line, "=")
    if (!pos or (!IsCounterDate(section) and section != "total"))
      continue
    key := Trim(SubStr(line, 1, pos-1))
    if (!IsCounterField(key))
      continue
    value := CounterNumber(Trim(SubStr(line, pos+1)), key)
    if (section = "total")
      persisted[key] := value
    else
      sums[key] := (sums.HasKey(key) ? sums[key] : 0) + value
  }
  content := ""
  ; Do not lower a lifetime total when some old daily sections are absent.
  for key, value in persisted
    if (!sums.HasKey(key) or value > sums[key])
      sums[key] := value
  mouse.total := {}, keyboard.total := {}
  for key, value in sums
  {
    if (key = "keystrokes" or RegExMatch(key, "^sc\d+$"))
      keyboard.total[key] := value
    else
      mouse.total[key] := (key="move" ? Round(value, 6) : value)
  }
  for _, key in ["lbcount","rbcount","mbcount","xbcount","wheel","hwheel","move"]
    if (!mouse.total.HasKey(key))
      mouse.total[key] := 0
  if (!keyboard.total.HasKey("keystrokes"))
    keyboard.total.keystrokes := 0
  ; Keep the legacy 'storage' field nonzero for safe accidental old-version reads.
  legacyDays := IniRead(IniPath, "history", "storage", 0)
  DataStorageDays := NormalizeHistoryDays(IniRead(IniPath, "history", "view_days", legacyDays))
  BuildHistoryIndex()
  CounterStoreReady := true
}

BuildHistoryIndex()
{
  global SavedCounterDates, HistoryDates, DataStorageDays, today, firstday
  text := "", cutoff := ""
  if (DataStorageDays > 0)
    cutoff := EnvAdd(today, -DataStorageDays, "Days", 1, 8)
  for date, _ in SavedCounterDates
    if (cutoff="" or date >= cutoff)
      text .= date "`n"
  text .= today "`n"
  Sort, text, N U
  HistoryDates := []
  Loop, Parse, text, `n, `r
    if (A_LoopField != "")
      HistoryDates.Push(A_LoopField)
  firstday := HistoryDates[1]
  HistoryDates.Push("Total")
}

NextHistoryDate(current, direction)
{
  global HistoryDates, today
  current := (current="" ? today : current)
  index := 0
  for i, value in HistoryDates
    if (value = current)
    {
      index := i
      break
    }
  if (!index)
    return today
  index += (direction < 0 ? -1 : 1)
  if (index < 1)
    index := HistoryDates.Length()
  if (index > HistoryDates.Length())
    index := 1
  return HistoryDates[index]
}

ReadCounterSection(date)
{
  global IniPath
  out := {}
  content := IniRead(IniPath, date, "", "")
  content := StrReplace(StrReplace(content, "`r`n", "`n"), "`r", "`n")
  Loop, Parse, content, `n, `r
  {
    pos := InStr(A_LoopField, "=")
    if (!pos)
      continue
    key := Trim(SubStr(A_LoopField, 1, pos-1))
    if (IsCounterField(key))
      out[key] := CounterNumber(Trim(SubStr(A_LoopField, pos+1)), key)
  }
  return out
}

LoadCounterDay(date)
{
  global CounterStoreReady, SavedCounterDates, today, mouse, keyboard
  if (!CounterStoreReady)
    InitializeCounterStore()
  if (date="Total")
    return true
  if (date!=today and !SavedCounterDates.HasKey(date))
    return false
  if (IsObject(mouse[date]) and IsObject(keyboard[date]))
    return true
  data := ReadCounterSection(date)
  mouse[date] := {}, keyboard[date] := {}
  for _, key in ["lbcount","rbcount","mbcount","xbcount","wheel","hwheel","move"]
    mouse[date, key] := data.HasKey(key) ? data[key] : 0
  for key, value in data
    if (key="keystrokes" or RegExMatch(key, "^sc\d+$"))
      keyboard[date, key] := value
  if (!keyboard[date].HasKey("keystrokes"))
    keyboard[date].keystrokes := 0
  ; In particular, NEVER reread or overwrite mouse.total / keyboard.total here.
  return true
}

CountPhysicalKey(sc)
{
  global today, keyboard
  key := "sc" sc
  if (!keyboard[today].HasKey(key))
    keyboard[today, key] := 0
  ; A key absent today may already have a lifetime count.
  if (!keyboard.total.HasKey(key))
    keyboard.total[key] := 0
  keyboard[today, key] += 1
  keyboard.total[key] += 1
  keyboard[today].keystrokes += 1
  keyboard.total.keystrokes += 1
}


SaveData()
{
  ; 保存历史数据存储天数
  IniWrite(36500, IniPath, "history", "storage")
  IniWrite(DataStorageDays, IniPath, "history", "view_days")
  ; 保存屏幕信息
  IniWrite(devicecaps.w,  IniPath, "devicecaps", "w")
  IniWrite(devicecaps.h,  IniPath, "devicecaps", "h")
  ; 保存布局信息
  IniWrite(layout.kw,     IniPath, "layout", "kw")
  IniWrite(layout.kh,     IniPath, "layout", "kh")
  IniWrite(layout.ks,     IniPath, "layout", "ks")
  IniWrite(layout.khs,    IniPath, "layout", "khs")
  IniWrite(layout.kvs,    IniPath, "layout", "kvs")
  ; 保存鼠标信息
  for k, v in ["lbcount", "rbcount", "mbcount", "xbcount", "wheel", "hwheel", "move"]
  {
    IniWrite(mouse[today][v],   IniPath,   today, v)
    IniWrite(mouse["total"][v], IniPath, "total", v)
  }
  ; 保存按键信息
  for k, v in keyboard[today]
    IniWrite(v, IniPath, today, k)
  for k, v in keyboard["total"]
    IniWrite(v, IniPath, "total", k)
}

IniRead(Filename, Section:="", Key:="", Default:=""){
  IniRead, OutputVar, %Filename%, %Section%, %Key%, %Default%
  ; 不管是没找到键 亦或是 键值为空 都返回默认值
  return, OutputVar="" ? Default : OutputVar
}

IniWrite(Value, Filename, Section, Key:=""){
  IniWrite, %Value%, %Filename%, %Section%, %Key%
}

EnvAdd(Var, Value, TimeUnits, StartingPos, Length){
  EnvAdd, Var, %Value%, %TimeUnits%
  ; 日期经过 EnvAdd 计算后位数会发生变化，所以用 SubStr 还原。
  return, SubStr(Var, StartingPos, Length)
}
