#singleinstance, force
#noenv
RegExMatch(A_ScriptDir, ".*(?=\\paths)", mainDir)
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
#Include ..\lib\pathReference.ahk

alignCamera()

Send {Space Down}
Send {w Down}
Send {d Down}
walkSleep(40000)