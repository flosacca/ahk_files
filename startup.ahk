#NoEnv

loop Files, D:/etc/startup.d/*
  loop Read, %A_LoopFilePath%
    RunLine(A_LoopReadLine)

RunLine(line) {
  c := []
  loop Parse, line, CSV
    c.push(RegExReplace(A_LoopField, "^ *"))

  if (c[1] ~= "^(#|$)")
    return

  try {
    run % c[1], % c[2], % c[3]
  }

  d := c[4] ? c[4] : 100
  if (d > 0)
    sleep d
}
