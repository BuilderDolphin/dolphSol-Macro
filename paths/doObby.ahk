#singleinstance, force
#noenv
RegExMatch(A_ScriptDir, ".*(?=\\paths)", mainDir)
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
#Include ..\lib\pathReference.ahk


if (options.VIP)
{    
    Send {w Down}
    walkSleep(100)
    jump()
    walkSleep(550)
    Send {a Down}
    walkSleep(150)
    jump()
    walkSleep(650)
    jump()
    walkSleep(400)
    Send {a Up}
    walkSleep(200)
    jump()
    Send {a Down}
    walkSleep(200)
    Send {a Up}
    walkSleep(400)
    Send {w Up}
    Send {a Down}
    Send {w Down}
    jump()
    walkSleep(300)
    Send {w Up}
    walkSleep(350)
    jump()
    walkSleep(700)
    jump()
    walkSleep(1400)
    Send {s Down} ;real obby
    jump()
    walkSleep(700)
    jump()
    walkSleep(300)
    Send {s Up}
    walkSleep(350)
    jump()
    Send {s Down}
    walkSleep(200)
    Send {s Up}
    walkSleep(450)
    Send {w Down}
    jump()
    walkSleep(700)
    jump()
    walkSleep(650)
    Send {a Up}
    walkSleep(50)
    jump()
    walkSleep(700)
    jump()
    walkSleep(700)
    jump()
    walkSleep(600)
    Send {d Down} ; finish
    walkSleep(600)
    Send {d Up}
    Send {w Up}
} else {
    Send {w Down}
    walkSleep(100)
    jump()
    walkSleep(550)
    Send {a Down}
    walkSleep(150)
    jump()
    walkSleep(650)
    jump()
    walkSleep(500)
    Send {a Up}
    walkSleep(100)
    jump()
    Send {a Down}
    walkSleep(200)
    Send {a Up}
    walkSleep(400)
    Send {a Down}
    Send {w Down}
    walkSleep(50)
    jump()
    walkSleep(300)
    Send {w Up}
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
    Send {w Down}
    jump()
    walkSleep(700)
    jump()
    walkSleep(550)
    Send {a Up}
    walkSleep(100)
    jump()
    walkSleep(700)
    jump()
    walkSleep(700)
    jump()
    walkSleep(600)
    Send {d Down} ; finish
    walkSleep(450)
    Send {w Up}
    walkSleep(200)
    Send {d Up}
}