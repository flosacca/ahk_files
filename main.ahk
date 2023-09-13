#NoEnv
#SingleInstance Off


; The top section doesn't have to have a label.
; The label here is to avoid forgetting the "return".
Init:
  ; Note: The hotkeys are installed before the stop section is executed,
  ; therefore before the previous script instance is closed.
  ClosePreviousInstance()

  EnvGet msys_home, HOME
  home := "D:\root"

  gui OpenBox:New, -MinimizeBox, Open
  gui Font, s12, Verdana
  gui Add, Edit, vEditOpen
  gui Add, Button, hp x+8 gOpenSubmit Default, OK

  gui ColorBox:New, -MaximizeBox, Color
  gui Font, s14, Consolas
  gui Add, Text, vHidden Hidden
  gui Add, Edit, xp vEditHex ReadOnly, % format("{:7}", "")
  gui Add, Edit, x+8 vEditRgb ReadOnly, % format("{:16}", "")
  return


OpenSubmit:
  gui Submit
  if (EditOpen) {
    if (EditOpen ~= "^\d+$") {
      args := GetProfile(EditOpen)
      if (args != "ERROR")
        OpenWSL("", args)
    }
    else if (EditOpen == ".")
      run gvim ., % CurrentPathOr(home)
    else
      NewTempFile(EditOpen)
  }
  return

OpenBoxGuiEscape:
ColorBoxGuiEscape:
  gui Cancel
  return


/*
There are some special keys in Japanese keyboard:

| Key               | Scan code |
| ----------------- | --------- |
| 英数 (CapsLock)   | sc03A     |
| 半角/全角         | sc029     |
| ひらがな/カタカナ | sc070     |
| 変換              | sc079     |
| 無変換            | sc07B     |

The CapsLock key is replaced with 英数 key and Shift+英数 gives CapsLock.

Mapping sc03A works as mapping CapsLock and sometimes works more proper.
All mappings using CapsLock will not work when any mapping of sc03A exists.

See also https://www.autohotkey.com/docs/KeyList.htm#SpecialKeys
*/

sc03A::Esc
Esc::sc03A

F1::
^sc03A::ToggleIME()

#sc03A::run % home
#e::return


; Volumn_Mute
#F10::send {vkAD}

; Volumn_Down
#F11::send {vkAE}

; Volumn_Up
#F12::send {vkAF}


#Tab::ShowCursorColor()
#`::send #{Tab}


#IfWinActive ahk_exe chrome.exe
^d::send ^f
#IfWinActive


^!h::OpenWSL(CurrentPath(), "zsh -l")

^!j::OpenWSL(CurrentPath(), "tmux")

^!l::
  path := CurrentPathOr(msys_home)
  run C:\msys64\msys2_shell.cmd -mingw64 -where ., % path, Hide
  return

^!.::
  path := CurrentPathOr(msys_home)
  run C:\msys64\msys2_shell.cmd -mingw32 -where ., % path, Hide
  return

^!;::run cmd /k cls, % CurrentPathOr(home), Max


^!u::OpenWSL(CurrentPathOr(home), "bash -lc ""python3 -q""")

^!i::OpenWSL(CurrentPathOr(home), "bash -lc irb")

^!o::
  gui OpenBox:Default
  GuiControl,, EditOpen
  gui Show
  return

^!p::NewTempFile("txt")


^!y::run mspaint

; Open default browser
^!n::run http:

^!v::OpenWSL("", "bash -lc ""vim .vimrc""")


; Poweroff
^!+p::shutdown 8

; Reboot
^!+[::shutdown 2

; Restart explorer
^!+e::
  run taskkill /f /im explorer.exe,, Hide
  sleep 500
  run explorer
  return

; Hibernate
^!+h::DllCall("PowrProf\SetSuspendState", "int", 1, "int", 0, "int", 0)

; Close monitor
^!+m::SendMessage, 0x112, 0xF170, 2,, Program Manager


ShowCursorColor() {
  ; The coordinates are relative to the active window by default.
  ; It doesn't hurt, as negative coordinates are supported.
  MouseGetPos x, y
  PixelGetColor c, x, y, RGB

  r := c >> 16
  g := c >> 8 & 0xff
  b := c & 0xff
  hexStr := format("#{}", SubStr(c, 3))
  rgbStr := format("rgb({:3},{:3},{:3})", r, g, b)

  gui ColorBox:Default
  GuiControl,, EditHex, % hexStr
  GuiControl,, EditRgb, % rgbStr
  GuiControl Focus, Hidden

  ; There's a strange thing. A GUI takes a moment to be focused after being
  ; displayed only when the first time launched via #Tab.
  ; This is a workaround. The second "Show" works as "WinActivate".
  gui Show, NoActivate
  gui Show
}


#include %A_ScriptDir%\IME.ahk

OpenWSL(dir := "", prog := "bash -l", dist := "") {
  base := "D:\opt\wsltty\bin\mintty.exe --WSLmode -e /bin/wslbridge2"
  if (dist)
    base .= " -d " dist
  if (dir)
    run % base " " prog, % dir
  else
    run % base " -W ""~"" " prog
}

GetProfile(id) {
  IniRead args, D:\etc\wsltty.ini, profile, %id%
  return args
}

SmartOr(a, b) {
  return a ? a : b
}

RandHex(len := 8) {
  loop % len {
    random a,, 0xF
    s .= format("{:X}", a)
  }
  return s
}

NewTempFile(ext, exe := "gvim") {
  s := A_Temp "\" RandHex() "." ext
  FileAppend,, % s
  run % exe " " s
}

CurrentProcessName() {
  WinGet name, ProcessName, A
  return name
}

CurrentPath() {
  if (CurrentProcessName() != "explorer.exe")
    return ""

  WinGetClass class, A
  ; if (class ~= "Progman|WorkerW")
  ;   return A_Desktop

  if (class ~= "(Cabinet|Explore)WClass") {
    WinGet hwnd, ID, A
    for w in ComObjCreate("Shell.Application").windows
      if (w.hwnd == hwnd) {
        path := w.document.folder.self.path
        return path ~= "^:" ? "" : path
      }
  }

  return ""
}

CurrentPathOr(defaultPath) {
  return SmartOr(CurrentPath(), defaultPath)
}

/*
| Virtual key | Effect under Japanese IME                 | Remarks  |
| ----------- | ----------------------------------------- | -------- |
| vkF0        | Toggle between english and last kana mode | 英数     |
| vkF1        | Switch to katakana mode                   | カタカナ |
| vkF2        | Switch to hiragana mode                   | ひらがな |
| vkF3        | Toggle between english and hiragana mode  | 半角     |
| vkF4        | The same as vkF3                          | 全角     |
*/
ToggleIME(action := "toggle") {
  /*
  | Lang | IME  | Mode     | Bits set     |
  | ---- | ---- | -------- | ------------ |
  | EN   | -    | -        | 0            |
  | ZH   | MS   | EN       | none         |
  | ZH   | MS   | ZH       | 0, 10        |
  | JP   | MS   | hiragana | 0, 3         |
  | JP   | MS   | katakana | 0, 3, 1      |
  | JP   | MS   | initial  | 0, 3, 4      |
  | JP   | MS   | EN       | none or prev |
  */
  mode := IME_GetConvMode()

  if (action == "toggle") {
    if (mode & 8)
      send {vkF0}
    else if (mode != 1)
      send ^{Space}
  }
  else if (action == "on") {
    if (mode & 8)
      send {vkF2}
    else if (mode == 0)
      send ^{Space}
  }
}

ClosePreviousInstance() {
  title := GetTitle()
  mark := "[INTERMEDIATE] " title
  if (!(CloseWindow(mark) || A_IsAdmin)) {
    SetTitle(mark)
    runWait % "*RunAs " DllCall("GetCommandLine", "str")
  }
  SetTitle("")
  CloseWindow(title)
  SetTitle(title)
}

/*
AutoHotkey has its own wrapper commands for these Win32 APIs.
These commands works by *WinTitle Criteria*.
To make them generally work, `DetectHiddenWindows On` has to be applied,
even if an HWND is specified by the "ahk_id" criteria.
*/

FindWindow(title, cls := "") {
  cls := cls ? cls : "AutoHotkey"
  return DllCall("FindWindow", "str", "AutoHotkey", "str", title)
}

CloseWindow(args*) {
  hwnd := FindWindow(args*)
  if (!hwnd)
    return 0
  ; WM_CLOSE = 0x10
  DllCall("PostMessage", "ptr", hwnd, "uint", 0x10, "ptr", 0, "ptr", 0)
  return 1
}

GetTitle(hwnd := 0) {
  hwnd := hwnd ? hwnd : A_ScriptHwnd
  count := DllCall("GetWindowTextLength", "ptr", hwnd) + 1
  VarSetCapacity(title, count * (A_IsUnicode ? 2 : 1))
  DllCall("GetWindowText", "ptr", A_ScriptHwnd, "str", title, "int", count)
  return title
}

SetTitle(title, hwnd := 0) {
  hwnd := hwnd ? hwnd : A_ScriptHwnd
  DllCall("SetWindowText", "ptr", hwnd, "str", title)
}
