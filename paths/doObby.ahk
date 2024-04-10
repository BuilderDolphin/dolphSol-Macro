#singleinstance, force
#noenv
RegExMatch(A_ScriptDir, ".*(?=\\paths)", mainDir)
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
#Include ..\lib\pathReference.ahk

; revision by sanji (sir.moxxi) and Flash (drflash55)

if (options.ArcanePath){
    if (options.VIP){

        Send {d Down} ;reposition
        walkSleep(50)
        Send {d Up}
        send {w down}
        walkSleep(100)
        jump()
        walkSleep(400)
        send {a down} ;move left earlier
        walkSleep(150)
        jump()
        walkSleep(200)
        send {w up} ;only move left in the air, prevents the first near miss
        walkSleep(200)
        send {w down}
        walkSleep(260)
        send {a up}
        walkSleep(100)
        jump()
        walkSleep(100)
        send {a down} ;move further left in the air
        walkSleep(330)
        send {a up}
        walkSleep(180)
        jump()
        walkSleep(100)
        send {a down} ;move further left in the air again, prevents the second near miss
        walkSleep(550)
        jump()
        walkSleep(230)
        send {w up}
        walkSleep(410)
        jump()
        walkSleep(550)
        jump()
        walkSleep(150)
        send {a up}
        Sleep, 100
        send {a down} ;start of arcane jump
        send {w down}
        walkSleep(1200)
        send {w up} ;positioning
        walkSleep(300)
        send {w down}
        walkSleep(50)
        jump()
        walkSleep(800)
        send {a up}
        send {w up}
        Sleep, 100
        send {a down} ;move against tree wall
        walkSleep(730)
        send {a up}
        send {w down}
        walkSleep(1000)
        send {w up}
        Send {a, d Down}
        Send {Left Down}
        Sleep, 250 ;adjusted cam turn
        Send {Left up}
        Send {a, d up}
        Sleep, 200
        send {a down}
        send {w down}
        walkSleep(325) ;adjusted timing for jump
        jump()
        arcaneTeleport()
        walkSleep(300)
        send {a up}
        send {w up}
        Sleep, 100
        send {w down}
        walkSleep(1500) ;move further forwards in case arcane teleport fell slightly short
        send {w up}
        send {a down}
        walkSleep(300)
        send {a up}
        send {s down}
        walkSleep(500) ;move back when macro moved to the left in case on the right side
        send {s up}
        send {d down}
        walkSleep(1000) ;try to head back to the blessing if missed on the left side
        send {d up}
    } else {
        send {w down}
        walkSleep(100)
        jump()
        walkSleep(550)
        send {a down}
        walkSleep(150)
        jump()
        walkSleep(650)
        jump()
        walkSleep(500)
        send {a up}
        walkSleep(100)
        jump()
        send {a down}
        walkSleep(200)
        send {a up}
        walkSleep(400)
        send {a down}
        send {w down}
        walkSleep(50)
        jump()
        walkSleep(300)
        send {w up}
        walkSleep(350)
        jump()
        walkSleep(700)
        jump()
        walkSleep(100)
        send {a up}
        Sleep, 100
        send {a down}
        send {w down}
        walkSleep(1250)
        jump()
        walkSleep(500)
        send {a up}
        send {w up}
        Sleep, 100
        send {a down}
        walkSleep(1100)
        send {a up}
        send {w down}
        walkSleep(700)
        send {w up}
        Send {a, d Down}
        Send {Left Down}
        walkSleep(200)
        Send {Left up}
        Send {a, d up}
        Sleep, 200
        send {a down}
        send {w down}
        walkSleep(300)
        jump()
        press("x",150)
        walkSleep(300)
        send {a up}
        send {w up}
        Sleep, 100
        send {w down}
        walkSleep(800)
        send {w up}
        send {a down}
        walkSleep(500)
        send {a up}
        send {d down}
        walkSleep(2000) 
        send {d up}
    }
} else {
    if (options.VIP) ;newest changes done here
    { 
        Send {d Down} ;reposition
        walkSleep(50)
        Send {d Up}
        send {w down}
        walkSleep(100)
        jump()
        walkSleep(400)
        send {a down} ;move left earlier
        walkSleep(150)
        jump()
        walkSleep(200)
        send {w up} ;only move left in the air, prevents the first near miss
        walkSleep(200)
        send {w down}
        walkSleep(260)
        send {a up}
        walkSleep(100)
        jump()
        walkSleep(100)
        send {a down} ;move further left in the air
        walkSleep(330)
        send {a up}
        walkSleep(180)
        jump()
        walkSleep(100)
        send {a down} ;move further left in the air again, prevents the second near miss
        walkSleep(550)
        jump()
        walkSleep(230)
        send {w up}
        walkSleep(410)
        jump()
        walkSleep(550)
        jump()
        walkSleep(1400)
        Send {s Down} ;real obby
        jump()
        walkSleep(350)
        Send {s Up}
        walkSleep(200)
        Send {s Down}
        walkSleep(60)
        jump()
        walkSleep(180)
        Send {s Up}
        walkSleep(500)
        Send {s Down}
        jump()
        walkSleep(150)
        Send {s Up}
        walkSleep(500)
        jump()
        walkSleep(40)
        send {w down}
        walkSleep(680)
        jump()
        walkSleep(430)
        send {a up}
        walkSleep(360)
        jump()
        walkSleep(640)
        jump()
        walkSleep(640)
        jump()
        walksleep(400)
        Send {d Down} ; finish
        walkSleep(600)
        Send {d Up}
        send {w up}
    } else {
        send {w Down}
        walkSleep(100)
        jump()
        walkSleep(550)
        send {a down}
        walkSleep(150)
        jump()
        walkSleep(650)
        jump()
        walkSleep(500)
        send {a up}
        walkSleep(100)
        jump()
        send {a down}
        walkSleep(200)
        send {a up}
        walkSleep(400)
        send {a down}
        send {w down}
        walkSleep(50)
        jump()
        walkSleep(300)
        send {w up}
        walkSleep(350)
        jump()
        walkSleep(700)
        jump()
        walkSleep(1300)
        Send {s Down} ;real obby
        jump()
        walkSleep(500)
        Send {s Up}
        walkSleep(200)
        Send {s Down}
        jump()
        walkSleep(300)
        Send {s Up}
        walkSleep(450)
        jump()
        Send {s Down}
        walkSleep(200)
        Send {s Up}
        walkSleep(450)
        send {w down}
        jump()
        walkSleep(700)
        jump()
        walkSleep(550)
        send {a up}
        walkSleep(100)
        jump()
        walkSleep(700)
        jump()
        walkSleep(700)
        jump()
        walkSleep(600)
        Send {d Down} ; finish
        walkSleep(450)
        send {w up}
        walkSleep(200)
        Send {d Up}
    }
}