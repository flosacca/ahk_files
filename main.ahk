#SingleInstance Force

#NoEnv

Init:
  EnvGet msys_home, HOME
  msys_home := ReplaceSlash(msys_home)
  home := "D:/root"
  wsltty := "D:/opt/wsltty/bin/mintty.exe"

  EnvSet WSLENV, LOAD_TMUX:NOBLINK
  EnvSet NOBLINK, 1

  gui -MinimizeBox
  gui Font, s12
  gui Add, Edit, vId
  gui Add, Button, Default ym, OK
  return


ButtonOK:
  gui Submit
  if (id) {
    if (id ~= "^\d+$") {
      args := GetProfile(id)
      if (args != "ERROR")
        run % wsltty " -~ " args
    }
    else if (id == ".")
      run gvim ., % CurrentPathOr(home)
    else
      NewTempFile(id)
  }
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

^sc03A::ToggleIME()

#sc03A::run % home
#e::return


~<#Space::
  SetTimer LWinStateTimer, 50
  return

LWinStateTimer:
  if !GetKeyState("LWin") {
    SetTimer,, Off
    sleep 50
    ToggleIME("on")
  }
  return


; Volumn_Mute
#F10::send {vkAD}

; Volumn_Down
#F11::send {vkAE}

; Volumn_Up
#F12::send {vkAF}


^!h::OpenWSL(CurrentPath())

^!j::
  EnvSet LOAD_TMUX, 1
  OpenWSL(CurrentPath())
  EnvSet LOAD_TMUX
  return

^!l::
  path := CurrentPathOr(msys_home)
  run C:/msys64/msys2_shell.cmd -mingw64 -where ., % path, Hide
  return

^!.::
  path := CurrentPathOr(msys_home)
  run C:/msys64/msys2_shell.cmd -mingw32 -where ., % path, Hide
  return

^!;::run cmd /k cls, % CurrentPathOr(home), Max


^!u::OpenWSL(CurrentPathOr(home), "bash -lc python3 -q")

^!i::OpenWSL(CurrentPathOr(home), "bash -lc irb")

^!o::
  GuiControl,, id
  gui Show
  return

^!p::NewTempFile("txt")


^!y::run mspaint

; Open default browser
^!n::run http:

^!m::run https://learn.tsinghua.edu.cn/f/wlxt/index/course/student/

^!v::OpenWSL("", "vim .vimrc")


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


#include D:/App/AHK/IME.ahk

OpenWSL(dir := "", prog := "-", dist := "") {
  global wsltty
  base := wsltty " --WSL=" dist
  if (dir)
    base .= " --dir=" dir
  else
    base .= " -~"
  run % base " " prog
}

GetProfile(id) {
  IniRead args, D:/etc/wsltty.ini, profile, %id%
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

ReplaceSlash(s) {
  if (s) {
    StringReplace s, s, \, /, All
  }
  return s
}

CurrentPath() {
  WinGet name, ProcessName, A
  if (name != "explorer.exe")
    return ""

  WinGetClass class, A
  ; if (class ~= "Progman|WorkerW")
  ;   return ReplaceSlash(A_Desktop)

  if (class ~= "(Cabinet|Explore)WClass") {
    WinGet hwnd, ID, A
    for w in ComObjCreate("Shell.Application").windows
      if (w.hwnd == hwnd)
        return ReplaceSlash(w.document.folder.self.path)
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
| vkF4        | Same as vkF3                              | 全角     |
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
