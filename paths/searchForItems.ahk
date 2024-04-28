#singleinstance, force
#noenv
RegExMatch(A_ScriptDir, ".*(?=\\paths)", mainDir)
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
#Include ..\lib\pathReference.ahk

; revision by sanji (sir.moxxi) and Flash (drflash55)

if (options.ArcanePath){
    send {d Down}
    walkSleep(2600)
    send {s down}
    Send {d Up}
    walkSleep(700)
    send {s up}
    Send {d Down}
    walkSleep(750)
    Send {d Up}
    collect(1)

    send {a down}
    walksleep(300)
    send {a up}
    send {w down}
    walkSleep(500)
    arcaneTeleport()
    walkSleep(2400)
    Send {d Down}
    walkSleep(400)
    Send {d Up}
    send {w up}
    collect(2)

    ; void hop
    Send {d Down}
    walkSleep(500)
    Send {d Up}
    Sleep, 4000 ; from 1750 since there is a semi risk of getting anti cheated for a few seconds

    send {w down}
    walkSleep(300)
    jump()
    walkSleep(350)
    send {a down}
    walkSleep(250)
    jump()
    walkSleep(350)
    send {w up}
    walkSleep(250)
    jump()
    walkSleep(350)
    send {a up}
    send {w down}
    walkSleep(225)
    jump()
    walkSleep(315)
    Send {d Down}
    walkSleep(750)
    send {w up}
    Send {d Up}
    collect(3)

    send {a down}
    walkSleep(600)
    send {w down}
    walkSleep(50)
    jump()
    walkSleep(800)
    jump()
    walkSleep(400)
    send {a up}
    send {w up}
    press("d",200)
    send {w down}
    walksleep(300)
    send {w up}
    Send {d Down}
    walkSleep(500)
    send {w down}
    walkSleep(500)
    send {w up}
    Send, {d Up}
    Send {Right Down}
    Sleep, 650
    Send {Right Up}
    collect(4)

    alignCamera()
    send {a down}
    walksleep(850)
    send {a up}
    Send {s Down}
    walkSleep(1000)
    arcaneTeleport()
    walkSleep(2100)
    send {a down}
    walkSleep(1550)
    send {a up}
    walkSleep(600)
    Send {s Up}
    collect(5)

    send {a down}
    jump()
    walkSleep(300)
    send {a up}
    Send {s Down}
    walkSleep(1000)
    jump()
    realT := getWalkTime(150)
    Sleep, 150
    arcaneTeleport()
    Sleep, % realT-150
    walkSleep(2000)
    Send {s Up}
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
    Send {d Down}
    walkSleep(100)
    jump()
    walkSleep(800)
    Send {s Down}
    walkSleep(400)
    jump()
    walkSleep(200)
    Send {s Up}
    send {d Down}
    walkSleep(200)
    jump()
    walkSleep(800)
    jump()
    walkSleep(600)
    jump()
    walkSleep(800)
    jump()
    walkSleep(200)
    send {d up}
    send {w down}
    walksleep(100)
    send {w up}
    sleep, 100
    collect(7)
}else{
    Send {d Down}
    walkSleep(2600)
    Send {s Down}
    Send {d Up}
    walkSleep(700)
    Send {s Up}
    Send {d Down}
    walkSleep(750)
    Send {d Up}
    collect(1)

    send {a down}
    walksleep(300)
    send {a up}
    send {w down}
    walkSleep(3800)
    Send {d Down}
    walkSleep(400)
    Send {d Up}
    send {w up}
    collect(2)

    ; void hop
    Send {d Down}
    walkSleep(400)
    Send {d Up}
    Sleep, 4000 ; from 1750 since there is a semi risk of getting anti cheated for a few seconds

    send {w down}
    walkSleep(300)
    jump()
    walkSleep(350)
    send {a down}
    walkSleep(250)
    jump()
    walkSleep(350)
    send {w up}
    walkSleep(250)
    jump()
    walkSleep(350)
    send {a up}
    send {w down}
    walkSleep(100)
    jump()
    walkSleep(350)
    Send {d Down}
    walkSleep(750)
    send {w up}
    Send {d Up}
    collect(3)

    send {a down}
    walkSleep(600)
    send {w down}
    walkSleep(100)
    jump()
    walkSleep(800)
    jump()
    walkSleep(400)
    send {a up}
    send {w up}
    press("d",200)
    send {w down}
    walksleep(300)
    send {w up}
    Send {d Down}
    walkSleep(500)
    send {w down}
    walkSleep(500)
    send {w up}
    Send, {d Up}
    Send {Right Down}
    Sleep, 650
    Send {Right Up}
    collect(4)

    alignCamera()
    send {a down}
    walksleep(850)
    send {a up}
    Send {s Down}
    walkSleep(4000)
    send {a down}
    walkSleep(1550)
    send {a up}
    walkSleep(600)
    Send {s Up}
    collect(5)

    send {a down}
    jump()
    walkSleep(300)
    send {a up}
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
    Send {d Down}
    walkSleep(100)
    jump()
    walkSleep(800)
    Send {s Down}
    walkSleep(400)
    jump()
    walkSleep(200)
    Send {s Up}
    send {d Down}
    walkSleep(200)
    jump()
    walkSleep(800)
    jump()
    walkSleep(600)
    jump()
    walkSleep(800)
    jump()
    walkSleep(200)
    send {d up}
    send {w down}
    walksleep(100)
    send {w up}
    sleep, 100
    collect(7)
}