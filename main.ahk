#SingleInstance Force

#NoEnv

Init:
  EnvGet home, HOME
  home := ReplaceSlash(home)
  dl := "D:/DL"

  EnvSet NOBLINK, 1
  EnvSet WSLENV, NOBLINK/u

  gui -MinimizeBox
  gui Font, s12
  gui Add, Edit, vExt
  gui Add, Button, Default ym, OK
  return

ButtonOK:
  gui Submit
  if (ext)
    NewTempFile(ext)
  return


CapsLock::Esc
Esc::CapsLock

^+CapsLock::run taskmgr


^CapsLock::^Space

~<#Space::
  SetTimer LWinStateTimer, 50
  return

LWinStateTimer:
  if ! GetKeyState("LWin") {
    SetTimer,, Off
    sleep 50
    if (~IME_GetConvMode() & 1)
      send ^{Space}
    else if (IME_GetConvMode() & 8)
      send ^{CapsLock}
  }
  return


#e::run D:/DL

#CapsLock::run D:/dev/debug


^!h::run cmd /c bash -lc m,, Max

^!j::
  path := CurrentPathOr(home)
  run C:/msys64/msys2_shell.cmd -mingw64 -where ., % path, Hide
  return

^!l::
  path := CurrentPath()
  if (path)
    run cmd /c bash, % path, Max
  else
    run cmd /c bash ~,, Max
  return

^!;::run cmd, % CurrentPathOr(dl), Max


^!u::run cmd /c bash -lc "python3 -q", % CurrentPathOr(dl), Max

^!i::run cmd /c bash -lc irb, % CurrentPathOr(dl), Max

^!o::run gvim ., % CurrentPathOr(dl)


^!y::run mspaint

^!p::
  GuiControl,, ext
  gui Show
  return

^!n::NewTempFile("txt")

; Open default browser
^!m::run http:

^!,::run https://learn.tsinghua.edu.cn/

^!v::run gvim ~/.vimrc


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
  if ! s {
    MsgBox Empty String
    ExitApp
  }
  StringReplace s, s, \, /, All
  return s
}

CurrentPath() {
  WinGet name, ProcessName, A
  if (name != "explorer.exe")
    return ""

  WinGetClass class, A
  if (class ~= "Progman|WorkerW")
    return ReplaceSlash(A_Desktop)

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
