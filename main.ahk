#SingleInstance Force

#NoEnv

Init:
  EnvGet msys_home, HOME
  msys_home := ReplaceSlash(msys_home)
  dl := "D:/DL"

  EnvSet WSLENV, NOTMUX:NOBLINK
  EnvSet NOBLINK, 1

  gui -MinimizeBox
  gui Font, s12
  gui Add, Edit, vExt
  gui Add, Button, Default ym, OK
  return

ButtonOK:
  gui Submit
  if (ext) {
    if (ext ~= "^\d+$")
      WSLRun("-c ""s " ext """", "")
    else if (ext == ".")
      run gvim ., % CurrentPathOr(dl)
    else
      NewTempFile(ext)
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

See also https://www.autohotkey.com/docs/KeyList.htm#SpecialKeys
*/

sc03A::Esc
Esc::sc03A

^sc03A::ToggleIME()


~<#Space::
  SetTimer LWinStateTimer, 50
  return

LWinStateTimer:
  if ! GetKeyState("LWin") {
    SetTimer,, Off
    sleep 50
    ToggleIME("on")
  }
  return


#F11::
  SoundSet, -2
  gosub ShowVolume
  return

#F12::
  SoundSet, +2
  gosub ShowVolume
  return

ShowVolume:
  SoundGet volume
  volume := round(volume)
  progress %volume%, %volume%
  SetTimer ProgressOff, -2000
  return

ProgressOff:
  progress Off
  return


; #e::run D:/DL
#e::return

#CapsLock::run D:/DL


^!h::WSLRun("-c ""s 2 tmux a""", "")

^!j::WSLRun("", CurrentPath())

^!,::
  EnvSet NOTMUX, 1
  WSLRun("", CurrentPath())
  EnvSet NOTMUX
  return

^!l::
  path := CurrentPathOr(msys_home)
  run C:/msys64/msys2_shell.cmd -mingw32 -where ., % path, Hide
  return

^!.::
  path := CurrentPathOr(msys_home)
  run C:/msys64/msys2_shell.cmd -mingw64 -where ., % path, Hide
  return

^!;::run cmd, % CurrentPathOr(dl), Max


^!u::WSLRun("-c ""python3 -q""", CurrentPathOr(dl))

^!i::WSLRun("-c irb", CurrentPathOr(dl))

^!o::
  GuiControl,, ext
  gui Show
  return

^!p::NewTempFile("txt")


^!y::run mspaint

; Open default browser
^!n::run http:

^!m::run https://learn.tsinghua.edu.cn/f/wlxt/index/course/student/

; ^!v::run gvim ~/.vimrc
^!v::WSLRun("-c ""vim ~/.vimrc""")


; Poweroff
^!+p::shutdown 8

; Reboot
^!+r::shutdown 2

; Restart explorer
^!+e::run cmd /c taskkill /f /im explorer.exe && start explorer,, Hide

; Hibernate
^!+h::DllCall("PowrProf\SetSuspendState", "int", 1, "int", 0, "int", 0)

; Close monitor
^!+m::run D:/App/bin/monitor.exe


#include D:/App/AHK/IME.ahk

WSLRun(cmd, dir := "") {
  ; run % "cmd /c bash " cmd, % dir, Max
  if (dir)
    run % "D:/opt/wsl-terminal/open-wsl.exe " cmd, % dir
  else
    run % "D:/opt/wsl-terminal/open-wsl.exe -C ~ " cmd
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
  if s {
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
