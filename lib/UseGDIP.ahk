; Link:   	https://www.autohotkey.com/boards/viewtopic.php?f=6&t=8050
; Author:	just me
; Date:
; for:     	AHK_L

/*
Some of us including me are sometimes using direct GDI+ DllCalls instead of including the GDIP lib. In this cases, you have to determine when and where to load the DLL and call GdiplusStartup() to initialize GDI+,
and also, when and where to call GdiplusShutdown() and unload the DLL. To simplify this process I wrote this function. It should be stored in one of the function library folders to be auto-included when needed.
It loads and initializes GDI+ at load-time and also calls GdiplusShutdown() and unloads the DLL when the script terminates. Of course, you are still responsible to destroy all existing GDI+ objects before the shutdown will be done.
Note: On my Win 8.1 64-bit system UseGDIP() needs about 220 KB additional memory.

Edit: Function updated on 2020-11-10: Added GetModuleHandleEx() to prevent untimely release.
*/

UseGDIP(Params*) { ; Loads and initializes the Gdiplus.dll at load-time
   ; GET_MODULE_HANDLE_EX_FLAG_PIN = 0x00000001
   Static GdipObject := ""
        , GdipModule := ""
        , GdipToken  := ""
   Static OnLoad := UseGDIP()
   If (GdipModule = "") {
      If !DllCall("LoadLibrary", "Str", "Gdiplus.dll", "UPtr")
         UseGDIP_Error("The Gdiplus.dll could not be loaded!`n`nThe program will exit!")
      If !DllCall("GetModuleHandleEx", "UInt", 0x00000001, "Str", "Gdiplus.dll", "PtrP", GdipModule, "UInt")
         UseGDIP_Error("The Gdiplus.dll could not be loaded!`n`nThe program will exit!")
      VarSetCapacity(SI, 24, 0), NumPut(1, SI, 0, "UInt") ; size of 64-bit structure
      If DllCall("Gdiplus.dll\GdiplusStartup", "PtrP", GdipToken, "Ptr", &SI, "Ptr", 0)
         UseGDIP_Error("GDI+ could not be startet!`n`nThe program will exit!")
      GdipObject := {Base: {__Delete: Func("UseGDIP").Bind(GdipModule, GdipToken)}}
   }
   Else If (Params[1] = GdipModule) && (Params[2] = GdipToken)
      DllCall("Gdiplus.dll\GdiplusShutdown", "Ptr", GdipToken)
}
UseGDIP_Error(ErrorMsg) {
   MsgBox, 262160, UseGDIP, %ErrorMsg%
   ExitApp
}