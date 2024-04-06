#singleinstance, force
#noenv
RegExMatch(A_ScriptDir, ".*(?=\\paths)", mainDir)
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
#Include ..\lib\pathReference.ahk

Send {d Down}
walkSleep(1300)
jump()
walkSleep(1200)
Send {s Down}
Send {d Up}
walkSleep(700)
Send {s Up}
Send {d Down}
walkSleep(750)
Send {d Up}
collect(1)

press("a",300)
Send {w Down}
walkSleep(3800)
Send {d Down}
walkSleep(400)
Send {d Up}
Send {w Up}
collect(2)

; void hop
Send {d Down}
walkSleep(400)
Send {d Up}
Sleep, 4000 ; from 1750 since there is a semi risk of getting anti cheated for a few seconds

Send {w Down}
walkSleep(300)
jump()
walkSleep(350)
Send {a Down}
walkSleep(250)
jump()
walkSleep(350)
Send {w Up}
walkSleep(250)
jump()
walkSleep(350)
Send {a Up}
Send {w Down}
walkSleep(100)
jump()
walkSleep(350)
Send {d Down}
walkSleep(750)
Send {w Up}
Send {d Up}
collect(3)

Send, {a Down}
walkSleep(700)
Send {w Down}
walkSleep(100)
jump()
walkSleep(800)
jump()
walkSleep(400)
Send {a Up}
Send {w Up}
press("d",200)
press("w",300)
Send {d Down}
walkSleep(500)
Send {w Down}
walkSleep(500)
Send, {w Up}
Send, {d Up}
Send {Right Down}
Sleep, 650
Send {Right Up}
collect(4)

alignCamera()
press("a",850)
Send {s Down}
walkSleep(4000)
Send {a Down}
walkSleep(1550)
Send {a Up}
walkSleep(600)
Send {s Up}
collect(5)

Send {a Down}
jump()
walkSleep(300)
Send {a Up}
press("s",4000)
press("d",250)
Send {Left Down}
Sleep, 1000
Send {Left Up}
collect(6)

alignCamera()
Send {s Down}
walkSleep(2500)
press("d",500)
Send {s Up}
press("w",200)
Send {d Down}
walkSleep(100)
jump()
walkSleep(1000)
Send {s Down}
walkSleep(400)
Send {s Up}
jump()
walkSleep(1000)
Send {s Down}
Send {d Up}
walkSleep(300)
Send {Space Down}
walkSleep(1100)
Send {Space Up}
Send {s Up}
Sleep, 500 ; normal bc waiting for jump to land
press("d",400)
press("w",850)
collect(7)

press("w",2750)
