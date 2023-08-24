#NoEnv
#SingleInstance Off

Init:
  ; The coordinates are relative to the active window by default.
  ; It doesn't hurt, as negative coordinates are supported.
  MouseGetPos x, y
  PixelGetColor c, x, y, RGB
  r := c >> 16
  g := c >> 8 & 0xff
  b := c & 0xff
  hexStr := format("#{}", SubStr(c, 3))
  rgbStr := format("rgb({},{},{})", r, g, b)
  ; text := hexStr "`n" rgbStr

  gui -MinimizeBox
  gui Font, s14, Consolas
  gui Add, Edit, ReadOnly, % hexStr
  gui Add, Edit, x+8 ReadOnly, % rgbStr
  ; gui Add, Edit, w180 Disabled ReadOnly r2 -VScroll -Wrap -WantReturn, % text
  ; gui Add, Button, w120 hp gBtnClicked Default, OK
  ; GuiControl Focus, Button1
  gui Show,, Color
  ; GuiControl Enable, Edit1
  return

; GuiSize:
;   GuiControl Move, Button1, % "x" (A_GuiWidth - 120) // 2
;   return

GuiClose:
GuiEscape:
; BtnClicked:
  ExitApp
