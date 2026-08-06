; Title:   	OSDTIP()
; Link:   	autohotkey.com/boards/viewtopic.php?t=76881#p333577
; Author:	SKAN
; Date:   	04.06.2020
; for:     	AHK_L

/*  OSDTIP_Pop(MainText, SubText, TimeOut, Options, FontName, Transparency)

  Note: Total parameters are variadic. This function uses Progress UI to display the notification. You need to be well versed with its options.

  Simple usage call: OSDTIP_Pop("Notification", "Message", -3000)
  The above will popup the UI within the work area at right-bottom corner of Primary monitor.

  Parameters explained:
  MainText : Main text will be BOLD by default. Pass WM400 in options to normalize it. Default font size is 9pt. Use FM option, like FM16 to make it bigger.
  SubText : Displayed in normal font weight. Pass WS600 in options for BOLD text. Default font size is 10pt. . Use FS option, like FS16 to make it bigger.
  By default, both MainText and SubText are left aligned. In options, pass C01 to display MainText centered or C10 to center SubText or C11 to display both centered.
  TimeOut :
  Pass number of milliseconds expressed as a negative number. For eg. -3000 will auto-dismiss the UI in 3 seconds.
  If this parameter is omitted, the UI wil stay on until OSDTIP_Pop() (without any parameters) is called. If a positive value is passed, eg.3000, it will be ignored.
  When the parameter is either omitted or is a negative number, the UI can be dismissed with a mouse left click.
  If this parameter is 0, mouse left click will not work and OSDTIP_Pop() has to be called to dismiss UI.
  Options : See Progress command for available options. B1 M is forced.. Other options can be overridden.
  To control the width and height of UI specify it like W200 H100. This will create a 201x101 UI as the window will have 1px border around it.
  Also note that, by default this function will enforce a minimum height of 102px. To override and have a natural height, use the custom option value U1.
  Pass custom option U2 to play a sound when UI is popping up. This will play "Windows\Media\Windows Notify.wav" as a system sound.
  Note that SoundPlay will play a sound at "Master volume level", but this function calls PlaySound() API to play the sound at "System sounds" level.
  By default, the progress bar height is 1px and so it appears as a horizontal gray line between MainText and SubText. To hide it, pass ZH0 in options.
  If you pass ZH3 or greater ( except ZH4 ), the bar of the progress bar will be visible with PBS_MARQUEE style applied to it.
  The color of marquee is BLACK by default and can be set with MarqueeColor parameter.
  FontName : Default is Segoe UI. Trebuchet MS is a good alternative.
  Transparency : This OSDTIP is opaque by default. You may try a value in range: 100-240 (full range: 0-255)
  Marquee : Use parameters 7,8,9 to set the color/bg/speed of Marquee when Progress bar height is 3px or more. (See example below)
  The default values are 0x000000/0xF0F0F0/0 (note: 0 is fastest and Marquee will run with a delay of 30ms)
  Examples

  Simple auto-dismiss notification:
  Code: Select all - Toggle Line numbers

  OSDTIP_Pop("Notification", "Message", -3000) ; #Persistent required


*/

/*  OSDTIP_Desktop(MainText, SubText, TimeOut, Options, FontName, Transparency)

  Note: Total parameters are variadic. This function uses Progress UI to display the notification. You need to be well versed with its options.

  Simple usage call: OSDTIP_Desktop("MainText", "SubText") ; Script needs #Persistent

  The above will apparently stick the UI within the work area at right-bottom corner of Desktop (Primary monitor).
  The text will be 50% transparent on a 100% transparent window
  Image
  Parameters explained:
  MainText : Main text will be BOLD by default. Pass WM400 in options to normalize it. Default font size is 28pt. Use FM option, like FM18 to make it smaller.
  SubText : Displayed in normal font weight. Pass WS600 in options for BOLD text. Default font size is 14pt. . Use FS option, like FS18 to make it bigger.
  By default, both MainText and SubText are both right aligned. In options, pass custom option U4 to override this to make both text centered. Additionally, pass
  C01 to display SubText left-aligned or C10 to display MainText left-aligned or C00 to display both left-aligned.
  TimeOut :
  Pass number of milliseconds expressed as a negative number. For eg. -3000 will auto-dismiss the UI in 3 seconds.
  If this parameter is omitted, the UI wil stay on until OSDTIP_Desktop() (without any parameters) is called. If a positive value is passed, eg.3000, it will be ignored.
  When the parameter is either omitted or is a negative number, the UI can be moved around the desktop with a mouse left click.
  If this parameter is 0, mouse left click will not work and the UI will appear to a part of Desktop.
  Options : See Progress command for available options. M is forced.. Other options can be overridden.
  By default, the UI is placed on Bottom-Right corner. Use custom option U5 to over-ride this, which will result in screen-centered UI.
  When U5 is specified, you may use parameters 7 & 8 to position the UI relative to any edge of the screen.
  By default, the progress bar height is 1px and it appears as a white line between MainText and SubText. To hide it, pass ZH0 in options or to increase it use
  something like ZH3 to set its height to 3px. The color of the Progress can be specified as parameter 9.
  FontName : Default is Segoe UI.
  Transparency : This OSDTIP is full transparent by default and the default value is A0A0A0 127. A0A0A0 is window color that is fully transparent and
  127 makes the text 50% transparent. You may try a value in range: 100-240 (full range: 0-255) without changing A0A0A0 else window will be visible.
  XOffset, YOffset : When U5 is specified in options, the UI will be centered on screen. You may use these to parameters to place the UI at a different corner
  The default values are -10,-10, and a positive values like 10,10 will place the UI on the Left-Top corner of the Desktop.
  You may refer the image posted at WinPos_ for a better understanding
  LineColor : Default Line color is White. You may pass a custom color in 0xbbggrr format.

  A real world example to show Current user and User logon-datetime on Desktop.
  Note: Script needs #Persistent and one dependency : UserLastLogon()
  Code: Select all - Toggle Line numbers

  OSDTIP_Desktop(A_UserName, UserLastLogon(A_UserName,,"d MMM, hh:mm tt"), 0)

*/

/*  OSDTIP_Volume(MuteOn, VolumeLevel, TimeOut, Options, FontName, Transparency)

  Note: Total parameters are variadic. This function uses Progress UI to display the notification. You need to be well versed with its options.

  Simple usage example:
  Code: Select all - Toggle Line numbers

  Volume_Mute:: OSDTIP_Volume("+1",   "", -2000)
  Volume_Up::   OSDTIP_Volume(  "", "+5", -2000)
  Volume_Down:: OSDTIP_Volume(  "", "-5", -2000)
  Pressing the Hotkeys would show a center-screen UI like follows:
  (The volume bar will be red when Mute is On)
  Image            Image
  Parameters explained:
  MuteOn : True or False. Pass "+1" to toggle the state
  VolumeLevel : You may pass an absolute value (Range 0-100) or pass a signed value like "-1" or "+10" to decrement/increment current level.
  It is possible Mute/Unmute and set volume level simultaneously: For eg. OSDTIP_Volume(1,25) will mute and also set volume level to 25%
  TimeOut :
  Pass number of milliseconds expressed as a negative number. For eg. -2000 will auto-dismiss the UI in 2 seconds.
  If this parameter is omitted, the UI wil stay on until OSDTIP_Volume() (without any parameters) is called. If a positive value is passed, eg.2000, it will be ignored.
  Options : See Progress command for available options. B1 is forced.. Other options can be overridden.
  This UI is disabled by default. If you want to dismiss it with a mouse click, pass M in Options.
  FontName : Default is Trebuchet MS.
  Transparency : This OSDTIP uses transparency level: 222 by default. You may pass a custom value or 255 to make the window opaque.

  #SingleInstance, Force
  SetScrollLockState, AlwaysOff
  ScrollLock::Return

  #If GetKeyState("ScrollLock","P")
  PrintScreen::  OSDTIP_Volume("", (A_TimeSincePriorHotkey>100 ? "-1" : "-5"), -2000)
  Pause::        OSDTIP_Volume("", (A_TimeSincePriorHotkey>100 ? "+1" : "+5"), -2000)
  +PrintScreen:: OSDTIP_Volume("", "-15", -2000)
  +Pause::       OSDTIP_Volume("", "+15", -2000)
  F12::          OSDTIP_Volume("+1",,-2000) ; Mute
  #If

*/

/*  OSDTIP_KBLeds(Keyname, State, TimeOut, Options, FontName, Transparency)

  Note: Total parameters are variadic. This function uses Progress UI to display the notification. You need to be well versed with its options.

  Simple usage call:
  Code: Select all - Toggle Line numbers

  CapsLock::   OSDTIP_KBLeds("CapsLock",,  -2000)
  ScrollLock:: OSDTIP_KBLeds("ScrollLock",,-2000)
  NumLock::    OSDTIP_KBLeds("NumLock",,   -2000)
  Pressing the Hotkeys would show a center-screen UI like follows:
  Image
  Parameters explained:
  KeyName : Can be one of these: CapsLock, ScrollLock, NumLock. If called without a KeyName the UI will displayed without affecting any KeyState.
  State : This can be on of these: On, Off, AlwaysOn, AlwaysOff, This parameter needs to contain an On or Off otherwise appropriate state
  needed to toggle will be appended automatically. The following are possible calls for CapsLock. It is ditto for NumLock and ScrollLock
  Code: Select all - Toggle Line numbers

  OSDTIP_KBLeds("CapsLock", "On")
  OSDTIP_KBLeds("CapsLock")        ; Toggle current state
  OSDTIP_KBLeds("CapsLock", "Off")

  OSDTIP_KBLeds("CapsLock", "AlwaysOn")
  OSDTIP_KBLeds("CapsLock", "Always")    ; Toggle current state
  OSDTIP_KBLeds("CapsLock", "AlwaysOff")
  Formatting: CapsLock and NumsLock are MainText and ScrollLock is SubText. Refer Progress command and use FM FS WM WS to control the size and weight of these text.
  TimeOut :
  Pass number of milliseconds expressed as a negative number. For eg. -3000 will auto-dismiss the UI in 3 seconds.
  If this parameter is omitted, the UI wil stay on until OSDTIP_KBLeds() (without any parameters) is called. If a positive value is passed, eg.3000, it will be ignored.
  Options : See Progress command for available options. B1 and text alignment is forced.. Other options can be overridden.
  This UI is disabled by default. If you want to dismiss it with a mouse click, pass M in Options.
  Pass custom option U2 to play a sound when either CapsLock becomes On or NumLock becomes Off
  The sound played will be "Windows\Media\Windows Default.wav" . Note that SoundPlay will play a sound at "Master volume level", but this function calls
  PlaySound() API to play the sound at "System sounds" level.
  FontName : Default is Trebuchet MS.
  Transparency : This OSDTIP uses transparency level: 222 by default. You may pass a custom value or 255 to make the window opaque.

  ScrollLock::Return
  CapsLock::Return
  NumLock::Return

  #If GetKeyState("CapsLock","P")
   1:: OSDTIP_KBLeds("CapsLock",,  -2000)
   2:: OSDTIP_KBLeds("ScrollLock",,-2000)
   3:: OSDTIP_KBLeds("NumLock",,   -2000)
  #If

*/

/*  OSDTIP_Alert(MainText, SubText, TimeOut, Options, FontName, Transparency)

  Note: Total parameters are variadic. This function uses Progress UI to display the notification. You need to be well versed with its options.

  Simple usage call: OSDTIP_Alert("MainText", "SubText")

  Use V0 in options for inverted color: OSDTIP_Alert("MainText", "SubText",, "V0")

  Use V1, V2, V3, V4 to display themed alert. These four Vn options (Remember it as W.I.S.E) may be used to display
  Warning, Info, Success, Error messages.

  Customised UI: OSDTIP_Alert("MainText", "SubText",, "CWFFEBFF CT654665 CB6C2085 ZH32 ZX12 ZY10")
  Use CW and CT to specify window/text color. CB for bar color. ZH for bar width. ZX and ZY for X/Y margins.

  Parameters explained:

  MainText :			Main text will be BOLD by default. Pass WM400 in options to normalize it. Default font size is 11pt. Use FM option, like FM14 to make it bigger.
  SubText :   			Displayed in normal font weight. Pass WS600 in options for BOLD text. Default font size is 10pt. . Use FS option, like FS14 to make it bigger.
							By default,   both MainText and SubText are left aligned. In options, pass C01 to display MainText centered or C10 to center SubText or C11 to display both centered.
  TimeOut :  			Pass number of milliseconds expressed as a negative number. For eg. -3000 will auto-dismiss the alert in 3 seconds.
							If this parameter is omitted, the alert wil stay on until OSDTIP_Alert() (without any parameters) is called. If a positive value is passed, eg.3000, it will be ignored.
							When the parameter is either omitted or is a negative number, the alert can be dismissed with a mouse left click.
							If this parameter is 0, mouse left click will not work and OSDTIP_Alert() has to be called to dismiss UI.
  Options:   			See Progress command for available options. B1 M is forced.. Other options can be overridden.
							To control the width and height of UI specify it like W200 H100. This will create a 201x101 UI as the window will have 1px border around it.
  FontName:			Default is Segoe UI. You may use a monospaced font like Consolas to display tab-formatted text.
  Transparency:		This OSDTIP uses transparency level: 240 by default. You may pass a custom value or 255 to make the window opaque.
  XOffset,
  YOffset,
  MonitorNumber:	By default the alert will be centered on primary monitor. You may use these to parameters to place the alert at a different corner of any monitor
							ositive value pairs like 10,10 will place the alert on the Left-Top corner of the Desktop, while negative values like -10,-10 will position it at Right-Bottom corner.

  You may refer the image posted at WinPos_ for a better understanding.
*/

/*
*/

/*
*/

OSDTIP_Alert(P*) {                        ; OSDTIP_Alert v0.54 by SKAN on D37P/D383 @ tiny.cc/osdtip
Local
Static FN:="", ID:=0, PS:="", PM:="", P8:=(A_PtrSize=8 ? "Ptr" : "")
  If !IsObject(FN)
    FN := Func(A_ThisFunc).Bind(A_ThisFunc)

  If (P.Count()=0 || P[1]==A_ThisFunc) {
    If (P[4]=0x201) ;            WM_NCLBUTTONDOWN=0xA1, HTCAPTION=2       ; WM_LBUTTONDOWN=0x201
    Return DllCall("SendMessage", "Ptr",ID, "Int",0xA1,"Ptr",2, "Ptr",0)  ;
    OnMessage(0x201, FN, 0),  OnMessage(0x010, FN, 0)                     ; WM_LBUTTONDOWN, WM_CLOSE
    SetTimer, %FN%, OFF
    Progress, 6:OFF
    Return ID:=0
  }

  MT:=P[1], ST:=P[2], OP := P[4] . A_Space, TMR:=P[3], FONT:=P[5] ? P[5] : "Segoe UI",
  TRN :=Round(P[6]) ? P[6] & 255 : 255, Title := (TMR=0 ? "0x0" : A_ScriptHwnd) . ":" . A_ThisFunc
  OP.= InStr(OP,"V1") ? "CWFFFFE2 CT856442 CBEBB800" : InStr(OP,"V2") ? "CWF0F8FF CT1A4482 CB3399FF"
    :  InStr(OP,"V3") ? "CWF0FFE9 CT155724 CB429300" : InStr(OP,"V4") ? "CWFFEEED CT721C24 CBE40000"
    :  InStr(OP,"V0") ? "CW3F3F3F CTDADADA CB797979" : ""
  PBG := (F := InStr(OP,"CB",1)) ? SubStr(OP, F+2, 6) : "797979"
  PBG := Format("0x{5:}{6:}{3:}{4:}{1:}{2:}", StrSplit(PBG)*)

  WinClose, ahk_id %ID%
  DetectHiddenWindows, % ("On", DHW:=A_DetectHiddenWindows)
  SetWinDelay, % (-1, SWD:=A_WinDelay)
  SetControlDelay, % (0, SCD:=A_WinDelay)

  DllCall("uxtheme\SetThemeAppProperties", "Int",0)
  Progress, 6: ZX6 ZY4 ZH16 FS10 FM11 WS400 WM800 C00 CT222222 %OP% B1 M Hide
          , %ST%, %MT%, %Title%, %FONT%
  DllCall("uxtheme\SetThemeAppProperties", "Int",7)
  WinWait, %Title% ahk_class AutoHotkey2
  ControlGetPos,,,,         PBS, msctls_progress321
  ControlGetPos, X1,,,, Static1
  ControlGetPos, X2,,,, Static2
  NM := X1+Round(PBS//2)
  Progress, 6: ZY4 ZH16 FS10 FM11 WS400 WM800 C00 CT222222 CB797979 %OP% ZX%NM% B1 M Hide
          , %ST%, %MT%, %Title%, %FONT%
  WinWait, %Title% ahk_class AutoHotkey2

  WinSet, Transparent, %TRN%, % "ahk_id" . (ID:=WinExist())
  WinGetPos, WX, WY, WW, WH
  ControlGetPos,,,,         PBS, msctls_progress321
  ControlGetPos,, Y1, W1, H1, Static1
  ControlGetPos,, Y2, W2, H2, Static2
  WH := Y1 + H1 + Round(H2) + 2

  SysGet, M, MonitorWorkArea, % Round(P[9])
  mX := mLeft, mY := mTop, mW := mRight-mLeft, mH := mBottom-mTop
  WX := mX + ( P[7]="" ? (mW//2)-(WW//2) : P[7]<0 ? mW-WW+P[7]+1 : P[7] )
  WY := mY + ( P[8]="" ? (mH//2)-(WH//2) : P[8]<0 ? mH-WH+P[8]+1 : P[8] )
  WinMove,,, % WX , % WY , % WW, % WH

  ControlMove, Static1, % X1+PBS, % Y1,      % W1, % H1
  ControlMove, Static2, % X2+PBS, % Y1+H1+2, % W2, % H2
  Control, ExStyle, -0x20000,    msctls_progress321                      ; WS_EX_STATICEDGE, removed
  SendMessage, 0x2001, 1, % PBG, msctls_progress321                      ; PBM_SETBACKCOLOR
  ControlMove, msctls_progress321, 0, 0, % PBS, % WH

  SetControlDelay, %SCD%
  SetWinDelay, %SWD%
  DetectHiddenWindows, %DHW%
  SC := DllCall("GetClassLong" . P8, "Ptr",ID, "Int",-26, "UInt")        ; GCL_STYLE
  DllCall("SetClassLong" . P8, "Ptr",ID, "Int",-26, "Ptr",SC|0x20000)    ; GCL_STYLE, CS_DROPSHADOW
  Progress, 6:SHOW
  DllCall("SetClassLong" . P8, "Ptr",ID, "Int",-26, "Ptr",SC)            ; GCL_STYLE

  If (Round(TMR)<0)
    SetTimer, %FN%, %TMR%
  OnMessage(0x202, FN, TMR=0 ? 0 : -1),  OnMessage(0x010, FN)            ; WM_LBUTTONUP,  WM_CLOSE
Return ID := WinExist()
}
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
OSDTIP_Desktop(P*) {                    ; OSDTIP_Desktop v0.50 by SKAN on D35P/D36E @ tiny.cc/osdtip
Local
Static FN:="", ID:=0, PS:="", PM:="", P8:=(A_PtrSize=8 ? "Ptr" : "")

  If !IsObject(FN)
    FN := Func(A_ThisFunc).Bind(A_ThisFunc)

  If (P.Count()=0 || P[1]==A_ThisFunc) {
    If (P[4]=0x201) ;            WM_NCLBUTTONDOWN=0xA1, HTCAPTION=2      ; WM_LBUTTONDOWN=0x201
    Return DllCall("SendMessage", "Ptr",ID, "Int",0xA1,"Ptr",2, "Ptr",0) ;
    OnMessage(0x201, FN, 0),  OnMessage(0x010, FN, 0)                    ; WM_LBUTTONDOWN, WM_CLOSE
    SetTimer, %FN%, OFF
    Progress, 7:OFF
    Return ID:=0
  }

  MT:=P[1], ST:=P[2], TMR:=P[3], OP:=P[4], FONT:=P[5] ? P[5] : "Segoe UI"
  TRN:=P[6] ? P[6] : "A0A0A0 127", Title := (TMR=0 ? "0x0" : A_ScriptHwnd) . ":" . A_ThisFunc

  If (ID) {
    Progress, 7:, % (ST=PS ? "" : PS:=ST), % (MT=PM ? "" : PM:=MT), %Title%
    SetTimer, %FN%, % Round(TMR)<0 ? TMR : "OFF"
    OnMessage(0x201, FN, TMR=0 ? 0 : -1)                                 ; WM_LBUTTONDOWN
    Return ID
  }

  DetectHiddenWindows, % ("Off", DHW:=A_DetectHiddenWindows)
  If !hSDV:=DllCall("GetWindow", "Ptr",WinExist("ahk_class Progman"), "UInt",5, "Ptr")  ; GW_CHILD=5
      hSDV:=DllCall("GetWindow", "Ptr",WinExist("ahk_class WorkerW"), "UInt",5, "Ptr")  ; GW_CHILD=5
  DetectHiddenWindows, On
  SetWinDelay, % (-1, SWD:=A_WinDelay)

  DllCall("uxtheme\SetThemeAppProperties", "Int",0)
  Progress, 7: ZX0 ZY0 ZH1 w200 FS14 FM28 CWA0A0A0 CTFEFEFE B %OP% M HIDE
          , %ST%, %MT%, %Title%, %FONT%
  DllCall("uxtheme\SetThemeAppProperties", "Int",7)
  WinWait %Title% ahk_class AutoHotkey2

  Control, Style,   0x50000000,  msctls_progress321                      ; WS_VISIBLE | WS_CHILD
  Control, ExStyle,-0x20000,     msctls_progress321                      ; WS_EX_STATICEDGE
  If !InStr(OP,"U4") {
    Control, Style,  0x50000002, Static1                                 ; WS_VISIBLE | WS_CHILD
    Control, Style,  0x50000002, Static2                                 ; | SS_RIGHT
    }
  SendMessage, 0x2001, 0, P[9]!="" ? P[9] : 0xFFFFFF, msctls_progress321 ; PBM_SETBACKCOLOR=0x2001
  WinSet, TransColor, %TRN%
  WinGetPos, X, Y, W, H
  SysGet, M, MonitorWorkArea
  If !InStr(OP,"U5")
    X:=MRight-W-14, Y:=MBottom-H-14
  Else
    X := P[7]="" ? (MRight/2) -(W/2) : P[7]<0 ? MRight -W+P[7] : P[7]
  , Y := P[8]="" ? (MBottom/2)-(H/2) : P[8]<0 ? MBottom-H+P[8] : P[8]
  ID:=WinExist()               ; SetWindowPos HWND_BOTTOM=1, SWP_SHOWWINDOW=0x40 SWP_NOACTIVATE=0x10
  DllCall("SetWindowPos", "Ptr",ID, "Ptr",1, "Int",X, "Int",Y, "Int",W+2, "Int",H, "UInt",0x40|0x10)
  DllCall("SetWindowPos", "Ptr",ID, "Ptr",1, "Int",X, "Int",Y, "Int",W+0, "Int",H, "UInt",0x40|0x10)
  DllCall("SetWindowLong" . P8, "Ptr",ID, "Int",-8, "Ptr",hSDV)          ; GWL_HWNDPARENT
  SetWinDelay, %SWD%
  DetectHiddenWindows, %DHW%
  Progress, 7:SHOW
  If (Round(TMR)<0)
    SetTimer, %FN%, %TMR%
  OnMessage(0x201, FN, TMR=0 ? 0 : -1),  OnMessage(0x010, FN)            ; WM_LBUTTONDOWN,  WM_CLOSE
Return ID
}
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
OSDTIP_Volume(P*) {                      ; OSDTIP_Volume v0.50 by SKAN on D35P/D369 @ tiny.cc/osdtip
Local
Static FN:="", ID:=0, PV:=0, P8:=(A_PtrSize=8 ? "Ptr" : "")

  If !IsObject(FN)
    FN := Func(A_ThisFunc).Bind(A_ThisFunc)

  If (P.Count()=0 || P[1]==A_ThisFunc) {
    OnMessage(0x202, FN, 0),  OnMessage(0x010, FN, 0)                   ; WM_LBUTTONUP, WM_CLOSE
    SetTimer, %FN%, OFF
    Progress, 8:OFF
    Return ID:=0
  }

  M:=P[1], V:=P[2], VSigned:=InStr("+-",SubStr(V,1,1)), TMR:=P[3]
  OP:=P[4], FONT:=P[5] ? P[5] : "Trebuchet MS",  TRN:=Round(P[6]) ? P[6] & 255 : 222
  Title := (TMR=0 ? "0x0" : A_ScriptHwnd) . ":" . A_ThisFunc

  If (M!="")
    SoundSet, %M%,, MUTE
  SoundGet, M,, MUTE
  If ( V!="" && !VSigned)
    SoundSet, %V%
  SoundGet, VOL
  VOL:=Round(VOL)

  If WinExist("ahk_id" . ID)
    {
      If (V && VSigned)
        SoundSet, % VOL:=(VOL:=V ? Round((VOL+V)/V)*V : VOL)>100 ? 100 : VOL<0 ? 0 : Round(VOL)
      SendMessage, 0x0409, 1, % (M="On" ? 0x0030FF:0x00FFAA), msctls_progress321 ; PBM_SETBARCOLOR
      SendMessage, 0x2001, 0, % (M="On" ? 0x00175A:0x00402E), msctls_progress321 ; PBM_SETBACKCOLOR
      Progress, 8:%VOL%, % PV!=VOL ? PV:=VOL : "",, %Title%
      SetTimer, %FN%, % Round(TMR)<0 ? TMR : "OFF"
      Return ID
    }

  DetectHiddenWindows, % ("On", DHW:=A_DetectHiddenWindows)
  SetWinDelay, % (-1, SWD:=A_WinDelay)
  DllCall("uxtheme\SetThemeAppProperties", "Int",0)
  Progress, 8:C11 w318 ZH24 ZX28 ZY4 WM400 WS600 FM16 FS22 CT111111 CWF0F0F0 %OP% B1 HIDE
          , % PV:=VOL, V O L U M E, %Title%, %FONT%
  DllCall("uxtheme\SetThemeAppProperties", "Int",7)
  WinWait, %Title% ahk_class AutoHotkey2

  WinSet, Transparent, %TRN%, % "ahk_id" . (ID:=WinExist())
  SendMessage, 0x0409, 1, % (M="On" ? 0x0030FF:0x00FFAA), msctls_progress321 ; PBM_SETBARCOLOR
  SendMessage, 0x2001, 0, % (M="On" ? 0x00175A:0x00402E), msctls_progress321 ; PBM_SETBACKCOLOR
  Control, ExStyle, -0x20000, msctls_progress321
  DetectHiddenWindows, %DHW%
  Progress, 8:%VOL%
  SC := DllCall("GetClassLong" . P8, "Ptr",ID, "Int",-26, "UInt")       ; GCL_STYLE
  DllCall("SetClassLong" . P8, "Ptr",ID, "Int",-26, "Ptr",SC|0x20000)   ; GCL_STYLE, CS_DROPSHADOW
  Progress, 8:SHOW
  DllCall("SetClassLong" . P8, "Ptr",ID, "Int",-26, "Ptr",SC)           ; GCL_STYLE
  If (Round(TMR)<0)
    SetTimer, %FN%, %TMR%
  OnMessage(0x202, FN, TMR=0 ? 0 : -1),  OnMessage(0x010, FN)           ; WM_LBUTTONUP,  WM_CLOSE
Return ID := WinExist()
}
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
OSDTIP_KBLeds(P*) {                      ; OSDTIP_KBLeds v0.50 by SKAN on D361/D367 @ tiny.cc/osdtip
Local
Static FN:="", ID:=0

  If !IsObject(FN)
    FN := Func(A_ThisFunc).Bind(A_ThisFunc)

  If (P.Count()=0 || P[1]==A_ThisFunc) {
    OnMessage(0x202, FN, 0),  OnMessage(0x010, FN, 0)                   ; WM_LBUTTONUP, WM_CLOSE
    SetTimer, %FN%, OFF
    Progress, 9:OFF
    Return ID:=0
  }

  Key := P[1], ST:=P[2], TMR:=P[3], OP:=P[4], FONT:=P[5] ? P[5] : "Trebuchet MS"
  Title := (TMR=0 ? "0x0" : A_ScriptHwnd) . ":" . A_ThisFunc, TRN:=Round(P[6]) ? P[6] & 255 : 222

  If WinExist("ahk_id" . ID) {
    ST.=InStr(ST,"off") || InStr(ST,"on") ? "" :  GetKeyState(Key,"T") ? "Off" : "On"
    Switch (Key) {
      Case "CapsLock"   : SetCapsLockState,   %ST%
      Case "ScrollLock" : SetScrollLockState, %ST%
      Case "NumLock"    : SetNumLockState,    %ST%
    }
    C:=GetKeyState("CapsLock","T"), S:=GetKeyState("ScrollLock","T"), N:=GetKeyState("NumLock","T")
    SendMessage, 0x2001, 1,% C ? 0x00FFAA:0x808080, msctls_progress321 ; PBM_SETBACKCOLOR
    SendMessage, 0x2001, 1,% S ? 0x00AAFF:0x808080, msctls_progress322 ; PBM_SETBACKCOLOR
    SendMessage, 0x2001, 1,% N ? 0x00FFAA:0x808080, msctls_progress323 ; PBM_SETBACKCOLOR

    If (Key="CapsLock" && C=1) || (Key="NumLock" && N=0)
    If ( InStr(OP,"U2",1) && FileExist(WAV:=A_WinDir . "\Media\Windows Default.wav") )
      DllCall("winmm\PlaySoundW", "WStr",WAV, "Ptr",0, "Int",0x220013)  ; SND_FILENAME | SND_ASYNC

    SetTimer, %FN%, % Round(TMR)<0 ? TMR : "OFF"
    Progress, 9:,,,%Title%
    Return ID
  }

  DetectHiddenWindows, % ("On", DHW:=A_DetectHiddenWindows)
  SetWinDelay, % (-1, SWD:=A_WinDelay)
  SetControlDelay, % (0, SCD:=A_ControlDelay)
  DllCall("uxtheme\SetThemeAppProperties", "Int",0)
  Progress, 9:ZX32 ZY6 ZH32 W172 WM600 WS400 FM16 FS16 CT101010 CWF0F0F0 %OP% C00 B1 HIDE
          , ScrollLock, CapsLock, %Title%, %FONT%
  WinWait %Title% ahk_class AutoHotkey2

  WinGetPos, WX, WY, WW, WH, % "ahk_id" . (ID:=WinExist())
  Loop, Parse, % "msctls_progress32|msctls_progress32|Static", |
  DllCall("CreateWindowEx", "Int",0, "Str",A_LoopField, "Str","NumLock" ; WS_VISIBLE | WS_CHILD
       ,"Int",0x50000000, "Int",0, "Int",0, "Int",10, "Int",10, "Ptr",ID, "Ptr",0, "Ptr",0, "Ptr",0)
  DllCall("uxtheme\SetThemeAppProperties", "Int",7)
  SendMessage, 0x31, 0, 0,            Static1                           ; WM_GETFONT
  SendMessage, 0x30, %ErrorLevel%, 1, Static3                           ; WM_SETFONT
  ControlGetPos, CX, CY, CW, CH, Static1
  YM:=CY-1, NX:=CX+CH+24, WW:=WW+CH+24, WH:=(CH*3)+(YM*4)+2, PH:=Round(CH/2), PY:=CY+(PH/2)
  WX:=(A_ScreenWidth/2)-(WW/2), WY := (A_ScreenHeight/2)-(WH/2)
  WinMove,% "ahk_id" WinExist(),,% WX,% WY,% WW, % WH
  ControlMove, Static1,            % NX, % CY,             % CW, % CH
  ControlMove, Static2,            % NX, % CY+CH+YM,       % CW, % CH
  ControlMove, Static3,            % NX, % CY+CH+YM+CH+YM, % CW, % CH
  ControlMove, msctls_progress321, % CX, % PY,             % CH, % PH
  ControlMove, msctls_progress322, % CX, % PY+CH+YM,       % CH, % PH
  ControlMove, msctls_progress323, % CX, % PY+CH+YM+CH+YM, % CH, % PH
  Loop 3
  Control, Style, +0x202, Static%A_Index%                               ; SS_RIGHT | SS_CENTERIMAGE
  WinSet, Transparent, %TRN%
  SetControlDelay, %SCD%
  SetWinDelay, %SWD%
  DetectHiddenWindows, %DHW%

  P8 := (A_PtrSize=8 ? "Ptr":"")
  SC := DllCall("GetClassLong" . P8, "Ptr",ID, "Int",-26, "UInt")       ; GCL_STYLE
  DllCall("SetClassLong" . P8, "Ptr",ID, "Int",-26, "Ptr",SC|0x20000)   ; GCL_STYLE, CS_DROPSHADOW
  Progress, 9:SHOW
  DllCall("SetClassLong" . P8, "Ptr",ID, "Int",-26, "Ptr",SC)           ; GCL_STYLE

  P[3]:=0, n:=%A_ThisFunc%(P*)
  If (Round(TMR)<0)
    SetTimer, %FN%, %TMR%
  OnMessage(0x202, FN, TMR=0 ? 0 : -1),  OnMessage(0x010, FN)           ; WM_LBUTTONUP,  WM_CLOSE
Return ID
}
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
OSDTIP_Pop(P*) {                            ; OSDTIP_Pop v0.55 by SKAN on D361/D36E @ tiny.cc/osdtip
Local
Static FN:="", ID:=0, PM:="", PS:=""

  If !IsObject(FN)
    FN := Func(A_ThisFunc).Bind(A_ThisFunc)

  If (P.Count()=0 || P[1]==A_ThisFunc) {
    OnMessage(0x202, FN, 0),  OnMessage(0x010, FN, 0)                   ; WM_LBUTTONUP, WM_CLOSE
    SetTimer, %FN%, OFF
    DllCall("AnimateWindow", "Ptr",ID, "Int",200, "Int",0x50004)        ; AW_VER_POSITIVE | AW_SLIDE
    Progress, 10:OFF                                                    ; | AW_HIDE
    Return ID:=0
  }

  MT:=P[1], ST:=P[2], TMR:=P[3], OP:=P[4], FONT:=P[5] ? P[5] : "Segoe UI"
  Title := (TMR=0 ? "0x0" : A_ScriptHwnd) . ":" . A_ThisFunc

  If (ID) {
    Progress, 10:, % (ST=PS ? "" : PS:=ST), % (MT=PM ? "" : PM:=MT), %Title%
    OnMessage(0x202, FN, TMR=0 ? 0 : -1)                                ; v0.55
    SetTimer, %FN%, % Round(TMR)<0 ? TMR : "OFF"
    Return ID
  }

  If ( InStr(OP,"U2",1) && FileExist(WAV:=A_WinDir . "\Media\Windows Notify.wav") )
    DllCall("winmm\PlaySoundW", "WStr",WAV, "Ptr",0, "Int",0x220013)    ; SND_FILENAME | SND_ASYNC
                                                                        ; | SND_NODEFAULT
  DetectHiddenWindows, % ("On", DHW:=A_DetectHiddenWindows)             ; | SND_NOSTOP | SND_SYSTEM
  SetWinDelay, % (-1, SWD:=A_WinDelay)
  DllCall("uxtheme\SetThemeAppProperties", "Int",0)
  Progress, 10:C00 ZH1 FM9 FS10 CWF0F0F0 CT101010 %OP% B1 M HIDE,% PS:=ST, % PM:=MT, %Title%, %FONT%
  DllCall("uxtheme\SetThemeAppProperties", "Int",7)                     ; STAP_ALLOW_NONCLIENT
                                                                        ; | STAP_ALLOW_CONTROLS
  WinWait, %Title% ahk_class AutoHotkey2                                ; | STAP_ALLOW_WEBCONTENT
  WinGetPos, X, Y, W, H
  SysGet, M, MonitorWorkArea
  WinMove,% "ahk_id" . WinExist(),,% MRight-W,% MBottom-(H:=InStr(OP,"U1",1) ? H : Max(H,100)), W, H
  If ( TRN:=Round(P[6]) & 255 )
    WinSet, Transparent, %TRN%
  ControlGetPos,,,,H, msctls_progress321
  If (H>2) {
    ColorMQ:=Round(P[7]),  ColorBG:=P[8]!="" ? Round(P[8]) : 0xF0F0F0,  SpeedMQ:=Round(P[9])
    Control, ExStyle, -0x20000,        msctls_progress321               ; v0.55 WS_EX_STATICEDGE
    Control, Style, +0x8,              msctls_progress321               ; PBS_MARQUEE
    SendMessage, 0x040A, 1, %SpeedMQ%, msctls_progress321               ; PBM_SETMARQUEE
    SendMessage, 0x0409, 1, %ColorMQ%, msctls_progress321               ; PBM_SETBARCOLOR
    SendMessage, 0x2001, 1, %ColorBG%, msctls_progress321               ; PBM_SETBACKCOLOR
  }
  DllCall("AnimateWindow", "Ptr",WinExist(), "Int",200, "Int",0x40008)  ; AW_VER_NEGATIVE | AW_SLIDE
  SetWinDelay, %SWD%
  DetectHiddenWindows, %DHW%
  If (Round(TMR)<0)
    SetTimer, %FN%, %TMR%
  OnMessage(0x202, FN, TMR=0 ? 0 : -1),  OnMessage(0x010, FN)           ; WM_LBUTTONUP,  WM_CLOSE
Return ID:=WinExist()
}
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
OSDTIP(hWnd:="") {
Local OSDTIP
  If (hWnd="")
     Return A_ScriptHwnd . ":OSDTIP_" . "ahk_class AutoHotkey2"
  If !WinExist("ahk_id" . hWnd)
     Return 0
  WinGetTitle, OSDTIP
  OSDTIP := StrSplit(OSDTIP,":")
  If ( OSDTIP[1] = A_ScriptHwnd )
       OSDTIP[2]()

}
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -