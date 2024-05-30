#singleinstance, force
#noenv
RegExMatch(A_ScriptDir, ".*(?=\\paths)", mainDir)
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
#Include ..\lib\pathReference.ahk

walkSend("w","Down")
walkSend("d","Down")
walkSleep(2500)
walkSend("d","Up")
walkSleep(2000)
press("d",500)
walkSleep(1000)
press("d",250)
walkSleep(100)
walkSend("d","Down")
;first jump
jump()

if (options.VIP){
    walkSleep(500)
    walkSend("d","Up")
    walkSleep(200)
    jump()
    walkSleep(150)
    walkSend("w","Up")
    Sleep, 500
    jump()
    press("w",500)
    Sleep, 200
    jump()
    walkSend("w","Down")
    walkSleep(600)
    walkSend("d","Down")
    walkSleep(550)
    jump()
    walkSleep(250)
    walkSend("w","Up")
    walkSleep(300)
    jump()
    walkSend("w","Down")
    walkSleep(350)
    walkSend("d","Up")
    walkSleep(300)
    walkSend("d","Down")
    jump()
    walkSleep(700)
    jump()
    walkSleep(500)
    walkSend("d","Up")
    walkSleep(500)
    walkSend("w","Up")
} else {
    walkSleep(600)
    walkSend("d","Up")
    walkSleep(150)
    jump()
    walkSleep(200)
    walkSend("w","Up")
    Sleep, 500
    jump()
    press("w",500)
    Sleep, 200
    jump()
    walkSend("w","Down")
    walkSleep(600)
    walkSend("d","Down")
    walkSleep(500)
    walkSend("w","Up")
    walkSleep(100)
    jump()
    Sleep, 100
    walkSend("w","Down")
    Sleep, 500
    jump()
    walkSend("w","Down")
    walkSleep(350)
    walkSend("d","Up")
    walkSleep(300)
    walkSend("d","Down")
    jump()
    walkSleep(700)
    jump()
    walkSleep(600)
    walkSend("d","Up")
    walkSleep(500)
    walkSend("w","Up")
}

