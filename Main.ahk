; dolpSol Macro
;   A macro for Sol's RNG on Roblox
;   GNU General Public License
;   Free for anyone to use
;   Modifications are welcome, however stealing credit is not
;   Hope you enjoy - BuilderDolphin
;   A "small" project started on 03/07/2024
;   
;   https://github.com/BuilderDolphin/dolphSol-Macro
;   
;   Feel free to provide any suggestions (through discord preferably, @builderdolphin). 

#singleinstance, force
#noenv
#persistent
SetWorkingDir, % A_ScriptDir "\lib"
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

#Include %A_ScriptDir%\lib
#Include ocr.ahk
#Include Gdip_All.ahk
#Include Gdip_ImageSearch.ahk

Gdip_Startup()

global version := "v1.0.1"

global canStart := 0
global macroStarted := 0
global reconnecting := 0

obbyCooldown := 120 ; 120 seconds
lastObby := A_TickCount - obbyCooldown*1000
hasObbyBuff := 0

obbyStatusEffectColor := 0x9CFFAC

statusEffectSpace := 5

mainDir := A_ScriptDir "\"

configPath := mainDir . "settings\config.ini"

configHeader := "; dolphSol Settings`n;   Do not put spaces between equals`n;   Additions may break this file and the macro overall, please be cautious`n;   If you mess up this file, clear it entirely and restart the macro`n`n[Options]`r`n"

; defaults
global options := {"DoingObby":1
    ,"CheckObbyBuff":1
    ,"CollectItems":1
    ,"ItemSpot1":1
    ,"ItemSpot2":1
    ,"ItemSpot3":1
    ,"ItemSpot4":1
    ,"ItemSpot5":1
    ,"ItemSpot6":1
    ,"ItemSpot7":1
    ,"WindowX":100
    ,"WindowY":100
    ,"VIP":0
    ,"ReconnectEnabled":1
    ,"AutoEquipEnabled":0
    ,"AutoEquipX":-0.415
    ,"AutoEquipY":-0.438
    ,"PrivateServerId":""
    ,"WebhookEnabled":0
    ,"WebhookLink":""
    ,"StatusBarEnabled":0
    ,"WasRunning":0
    ; ,"WebhookInvScreenshotEnabled":1 ; one day maybe when i figure out how to do discord screenshots
    ; ,"WebhookInvScreenshotInterval":60
    ; not really options but stats i guess
    ,"RunTime":0
    ,"Disconnects":0
    ,"ObbyCompletes":0
    ,"ObbyAttempts":0
    ,"CollectionLoops":0}

global privateServerPre := "https://www.roblox.com/games/15532962292/Sols-RNG?privateServerLinkCode="

getINIData(path){
    FileRead, retrieved, %path%

    retrievedData := {}
    readingPoint := 0

    if (!ErrorLevel){
        ls := StrSplit(retrieved,"`r`n")
        for i,v in ls {
            isHeader := RegExMatch(v,"\[(.*)]")
            if (v && readingPoint && !isHeader){
                RegExMatch(v,"(.*)(?==)",index)
                RegExMatch(v,"(?<==)(.*)",value)
                if (index){
                    retrievedData[index] := value
                }
            } else if (isHeader){
                readingPoint := 1
            }
        }
    } else {
        MsgBox, An error occurred while reading %path% data, please review the file.
        return
    }
    return retrievedData
}

writeToINI(path,object,header){
    if (!FileExist(path)){
        MsgBox, You are missing the file: %path%, please ensure that it is in the correct location.
        return
    }

    formatted := header

    for i,v in object {
        formatted .= i . "=" . v . "`r`n"
    }

    FileDelete, %path%
    FileAppend, %formatted%, %path%
}

; data loading
loadData(){
    global configPath
    savedRetrieve := getINIData(configPath)
    if (!savedRetrieve){
        MsgBox, Unable to retrieve config data, your settings have been set to their defaults.
        savedRetrieve := {}
    }
    newOptions := {}
    for i,v in options {
        if (savedRetrieve.HasKey(i)){
            newOptions[i] := savedRetrieve[i]
        } else {
            newOptions[i] := v
        }
    }
    options := newOptions
}
loadData()

saveOptions(){
    global configPath,configHeader
    writeToINI(configPath,options,configHeader)
}
saveOptions()

webhookPost(content := "", title := "", color := "1"){
    url := options.WebhookLink
    formattedTitle := ""
    if (title){
        formattedTitle = 
        (
            "title": "%title%",
        )
    }

    postdata =
    (
    {
    "embeds": [
        {
        %formattedTitle%
        "description": "%content%",
        "color": %color%
        }
    ]
    }
    ) ; Use https://leovoel.github.io/embed-visualizer/ to generate above webhook code
    WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    WebRequest.Open("POST", url, false)
    WebRequest.SetRequestHeader("Content-Type", "application/json")
    WebRequest.SetProxy(false)
    WebRequest.Send(postdata)   
}

global possibleDowns := ["w","a","s","d","Space","Enter","Esc","r"]

stop(terminate := 0) {
    for i,v in possibleDowns {
        Send {%v% Up}
    }

    if (running){
        updateStatus("Macro Stopped")
    }

    if (terminate){
        options.WasRunning := 0
    }

    applyNewUIOptions()
    saveOptions()

    if (terminate){
        OutputDebug, Terminated
        ExitApp
    }
}

global pauseDowns := []
global paused := 0

handlePause(){
    if (paused){
        applyNewUIOptions()
        saveOptions()
        updateUIOptions()

        WinActivate, Roblox
        for i,v in pauseDowns {
            Send {%v% Down}
        }
    } else {
        pauseDowns := []
        for i,v in possibleDowns {
            state := GetKeyState(v)
            if (state){
                pauseDowns.Push(v)
                Send {%v% Up}
            }
        }
        updateUIOptions()
        Gui mainUI:Show
    }
    paused := !paused
}

global regWalkFactor := 1.25 ; since i made the paths all with vip, normalize

walkSleep(d){
    Sleep, % d*(1 + (regWalkFactor-1)*(1-options.VIP))
}

press(k, duration := 50) {
    Send, {%k% Down}
    walkSleep(duration)
    Send, {%k% Up}
}
press2(k, k2, duration := 50) {
    Send, {%k% Down}
    Send, {%k2% Down}
    walkSleep(duration)
    Send, {%k% Up}
    Send, {%k2% Up}
}

reset() {
    press("Esc",150)
    Sleep, 50
    press("r",150)
    Sleep, 50
    press("Enter",150)
    Sleep, 50
}
jump() {
    press("Space")
}

; main stuff

global initialized := 0
global running := 0

initialize()
{
    initialized := 1
    getRobloxPos(pX,pY,width,height)
    MouseMove, % pX + width*0.5, % pY + height*0.5
    Sleep, 300
    MouseClick
    Sleep, 250
    Loop 20 {
        Click, WheelUp
        Sleep, 50
    }
    Loop 10 {
        Click, WheelDown
        Sleep, 100
    }
}


; Paths

align(fails := 0){ ; align v2
    updateStatus("Aligning Character")
    reset()
    Sleep, 5000

    closeChat()
    Sleep, 200

    clickMenuButton(2)
    Sleep, 500
    getRobloxPos(rX,rY,rW,rH)
    MouseMove, % rX + rW*0.15, % rY + rH*0.1
    Sleep, 200
    MouseClick
    Sleep, 500

    Send, {w Down}
    Send, {a Down}
    walkSleep(2750)
    Send, {a Up}
    walkSleep(1000)
    Send, {w Up}
    walkSleep(50)
    press("s",2500)
    walkSleep(50)
}

collect(num){
    if (!options["ItemSpot" . num]){
        return
    }
    Loop, 3 
    {
        press("f")
        Sleep, 200
    }
}

searchForItems(){
    updateStatus("Searching for Items")
    ; item 1
    updateStatus("Searching for Items (#1)")
    press("d",4250)
    press("w",1250)
    collect(1)

    ; item 2
    updateStatus("Searching for Items (#2)")
    press("w",1500)
    press("a",250)
    press("w",3100)
    press("d",250)
    collect(2)

    ; item 3
    updateStatus("Searching for Items (#3)")
    press("a",500)
    press2("s","a",2800)
    Send, {a Down}
    walkSleep(100)
    jump()
    walkSleep(700)
    jump()
    walkSleep(1200)
    Send, {w Down}
    walkSleep(750)
    Send, {a Up}
    Send, {w Up}
    press("d",250)
    press("s",250)
    Send, {a Down}
    jump()
    walkSleep(700)
    Send, {a Up}
    walkSleep(50)
    Send, {w Down}
    jump()
    walkSleep(900)
    Send, {w Up}
    press("d",800)
    collect(3)
    
    ; item 4
    updateStatus("Searching for Items (#4)")
    press("a",1550)
    press("w",1200)
    Send, {d Down}
    walkSleep(1250)
    Send {w Down}
    walkSleep(750)
    Send {d Up}
    Send {w Up}
    collect(4)

    ; item 5
    updateStatus("Searching for Items (#5)")
    press("a",1500)
    press("d",250)
    press("s",5100)
    press("a",1400)
    press("s",600)
    collect(5)

    ; item 6
    updateStatus("Searching for Items (#6)")
    Send {a Down}
    jump()
    walkSleep(300)
    Send {a Up}
    press("s",4100)
    press("d",250)
    collect(6)

    ; item 7
    updateStatus("Searching for Items (#7)")
    Send {s Down}
    walkSleep(2500)
    press("d",1000)
    Send {s Up}
    press("w",200)
    Send {d Down}
    walkSleep(100)
    jump()
    walkSleep(1250)
    Send {s Down}
    walkSleep(500)
    Send {s Up}
    jump()
    walkSleep(1000)
    Send {s Down}
    walkSleep(500)
    Send {d Up}
    Send {Space Down}
    walkSleep(1100)
    Send {Space Up}
    Send {s Up}
    Sleep, 500 ; normal bc waiting for jump to land
    press("d",700)
    press("w",850)
    press("d",150)
    collect(7)
    

    options.CollectionLoops += 1
}

doObby(){
    updateStatus("Doing Obby")
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
    options.ObbyAttempts += 1
}

walkToObby(){
    updateStatus("Walking to Obby")
    Send {a Down}
    walkSleep(2300)
    jump()
    walkSleep(2000)
    jump()
    walkSleep(1850)
    Send {a Up}
}

obbyRun(){
    global lastObby
    walkToObby()
    Sleep, 250
    doObby()
    lastObby := A_TickCount
    Sleep, 100
}

; End of paths

closeChat(){
    getRobloxPos(pX,pY,width,height)
    PixelGetColor, chatCheck, % pX + 75, % pY + 12, RGB
    if (compareColors(chatCheck,0xffffff) < 16){ ; is chat open??
        MouseMove, % pX + 75, % pY + 12
        Sleep, 300
        MouseClick
        Sleep, 100
    }
}

mouseActions(){
    updateStatus("Performing Mouse Actions")

    getRobloxPos(pX,pY,width,height)

    ; re equip
    if (options.AutoEquipEnabled){
        closeChat()

        checkPos := getStoragePositionFromUV(-1.209440, -0.695182)
        PixelGetColor, checkC, % checkPos[1], % checkPos[2], RGB
        alreadyOpen := compareColors(checkC,0xffffff) < 8

        if (!alreadyOpen){
            clickMenuButton(1)
        }
        Sleep, 100
        sPos := getStoragePositionFromUV(options.AutoEquipX,options.AutoEquipY)
        MouseMove, % sPos[1], % sPos[2]
        Sleep, 300
        MouseClick
        Sleep, 100
        ePos := getStoragePositionFromUV(storageEquipUV[1],storageEquipUV[2])
        MouseMove, % ePos[1], % ePos[2]
        Sleep, 300
        MouseClick
        Sleep, 100
        clickMenuButton(1)
    }

    Sleep, 250

    MouseMove, % pX + width*0.5, % pY + height*0.5
    Sleep, 300
    MouseClick
    Sleep, 250
}

isFullscreen() {
	WinGetPos,,, w, h, Roblox
	return (w = A_ScreenWidth && h = A_ScreenHeight)
}

getRobloxPos(ByRef x := "", ByRef y := "", ByRef width := "", ByRef height := ""){
    WinGetPos, x, y, width, height, Roblox

    if (!isFullscreen()){
        height -= 39
        width -= 16
        x += 8
        y += 31
    }
}


; screen stuff

checkHasObbyBuff(BRCornerX, BRCornerY, statusEffectHeight){
    if (!options.CheckObbyBuff){
        return 1
    }
    global obbyStatusEffectColor,obbyStatusEffectColor2,hasObbyBuff,statusEffectSpace
    Loop, 5
    {
        targetX := BRCornerX - (statusEffectHeight/2) - (statusEffectHeight + statusEffectSpace)*(A_Index-1)
        targetY := BRCornerY - (statusEffectHeight/2)
        PixelGetColor, color, targetX, targetY, RGB
        if (compareColors(color, obbyStatusEffectColor) < 16){
            hasObbyBuff := 1
            options.ObbyCompletes += 1
            updateStatus("Completed Obby")
            return 1
        }
    }  
    hasObbyBuff := 0
    return 0
}

getUV(x,y,oX,oY,width,height){
    return [((x-oX)*2 - width)/height,((y-oY)*2 - height)/height]
}
getFromUV(uX,uY,oX,oY,width,height){
    return [Floor((uX*height + width)/2)+oX,Floor((uY*height + height)/2)+oY]
}

spawnCheck(){ ; not in use
    if (!options.ExtraAlignment) {
        return 1
    }
    getRobloxPos(rX, rY, width, height)
    startPos := getFromUV(-0.55,-0.9,rX,rY,width,height)
    targetPos := getFromUV(-0.45,-0.9,rX,rY,width,height)
    startX := startPos[1]
    startY := startPos[2]
    distance := targetPos[1]-startX
    bitMap := Gdip_BitmapFromScreen(startX "|" startY "|" distance "|1")
    vEffect := Gdip_CreateEffect(5,50,30)
    Gdip_BitmapApplyEffect(bitMap,vEffect)
    ;Gdip_SaveBitmapToFile(bitMap,"test1.png")
    prev := 0
    greatestDiff := 0
    cat := 0
    Loop, %distance%
    {
        c := Gdip_GetPixelColor(bitMap,A_Index-1,0,1)
        if (!prev){
            prev := c
        }
        comp := compareColors(prev,c)
        greatestDiff := Max(comp,greatestDiff)
        if (greatestDiff = comp){
            cat := A_Index
        }
        prev := c
    }
    Gdip_DisposeEffect(vEffect)
    Gdip_DisposeBitmap(bitMap)
    return greatestDiff >= 5
}

getColorComponents(color){
    return [color & 255, (color >> 8) & 255, (color >> 16) & 255]
}

compareColors(color1, color2) ; determines how far apart 2 colors are
{
    color1V := getColorComponents(color1)
    color2V := getColorComponents(color2)

    cV := [color1V[1] - color2V[1], color1V[2] - color2V[2], color1V[3] - color2V[3]]
    dist := Abs(cV[1]) + Abs(cV[2]) + Abs(cV[3])
    return dist
}

clamp(x,mn,mx){
    nX := Min(x,mx)
    nX := Max(nX,mn)
    return nX
}

; menu ui stuff (ingame)

global menuBarOffset := 10 ;10 pixels from left edge

getMenuButtonPosition(num, ByRef posX := "", ByRef posY := ""){ ; num is 1-7, 1 being top, 7 only existing if you are the private server owner
    getRobloxPos(rX, rY, width, height)

    menuBarVSpacing := 10.5*(height/1080)
    menuBarButtonSize := 58*(width/1920)
    menuEdgeCenter := [rX + menuBarOffset, rY + (height/2)]
    startPos := [menuEdgeCenter[1]+(menuBarButtonSize/2),menuEdgeCenter[2]+(menuBarButtonSize/4)-(menuBarButtonSize+menuBarVSpacing-1)*3]
    
    posX := startPos[1]
    posY := startPos[2] + (menuBarButtonSize+menuBarVSpacing)*(num-1)

    MouseMove, % posX, % posY
}

clickMenuButton(num){
    getMenuButtonPosition(num, posX, posY)
    MouseMove, posX, posY
    Sleep, 200
    MouseClick
}

; storage ratio: w1649 : h952
global storageAspectRatio := 952/1649
global storageEquipUV := [-0.875,0.054] ; equip button

getAspectRatioSize(ratio, width, height){
    fH := width*ratio
    fW := height*(1/ratio)

    if (height >= fH){
        fW := width
    } else {
        fH := height
    }

    return [Floor(fW+0.5), Floor(fH+0.5)]
}

getStoragePositionFromUV(x,y){
    getRobloxPos(rX, rY, width, height)
    
    ar := getAspectRatioSize(storageAspectRatio, width, height)

    oX := Floor((width-ar[1])/2) + rX
    oY := Floor((height-ar[2])/2) + rY

    p := getFromUV(x,y,oX,oY,ar[1],ar[2]) ; [Floor((x*ar[2] + ar[1])/2)+oX,Floor((y*ar[2] + ar[2])/2)+oY]

    return p
}

getStorageUVFromPosition(x,y){
    getRobloxPos(rX, rY, width, height)
    
    ar := getAspectRatioSize(storageAspectRatio, width, height)

    oX := Floor((width-ar[1])/2) + rX
    oY := Floor((height-ar[2])/2) + rY

    p := getUV(x,y,oX,oY,ar[1],ar[2])

    return p
}

closeRoblox(){
    WinClose, Roblox
    WinClose, % "Roblox Crash"
}

; used from natro
GetRobloxHWND()
{
	if (hwnd := WinExist("Roblox ahk_exe RobloxPlayerBeta.exe"))
		return hwnd
	else if (WinExist("Roblox ahk_exe ApplicationFrameHost.exe"))
	{
		ControlGet, hwnd, Hwnd, , ApplicationFrameInputSinkWindow1
		return hwnd
	}
	else
		return 0
}

attemptReconnect(failed := 0){
    initialized := 0
    if (reconnecting && !failed){
        return
    }
    if (!options.ReconnectEnabled){
        stop()
        return
    }
    reconnecting := 1
    success := 0
    closeRoblox()
    updateStatus("Reconnecting")
    Sleep, 5000
    Loop 5 {
        Sleep, % (A_Index-1)*10000
        if (options.PrivateServerId && A_Index < 4){
            try Run % """roblox://placeID=15532962292&linkCode=" options.PrivateServerId """"
        } else {
            try Run % """roblox://placeID=15532962292"""
        }
        Loop 240 {
            if (GetRobloxHWND()){
                WinActivate, Roblox
                break
            }
            if (A_Index == 240){
                continue 2
            }
            Sleep 1000
        }
        updateStatus("Reconnecting, Roblox Opened")
        Sleep, 3000
        Loop 120 {
            getRobloxPos(pX,pY,width,height)

            PixelGetColor, color, % pX + (width/2), % pY + height*0.6, RGB
            
            if (compareColors(color,0xffffff) < 16){
                MouseMove, % pX + (width/2), % pY + height*0.6
                Sleep, 300
                MouseClick
                break
            }

            if (A_Index == 120 || !GetRobloxHWND()){
                continue 2
            }
            Sleep 1000
        }
        updateStatus("Reconnecting, Game Loaded")
        Sleep, 5000
        getRobloxPos(pX,pY,width,height)
        MouseMove, % pX + (width*0.6), % pY + (height*0.85)
        Sleep, 300
        MouseClick
        Sleep, 100
        MouseMove, % pX + (width*0.35), % pY + (height*0.95)
        Sleep, 300
        MouseClick
        updateStatus("Reconnect Complete")
        success := 1
        break
    }
    if (success){
        reconnecting := 0
    } else {
        Sleep, 30000
        attemptReconnect(1)
    }
}

checkDisconnect(){
    getRobloxPos(windowX, windowY, windowWidth, windowHeight)
	if ((windowWidth > 0) && !WinExist("Roblox Crash")) {
		pBMScreen := Gdip_BitmapFromScreen(windowX+(windowWidth/4) "|" windowY+(windowHeight/2) "|" windowWidth/2 "|1")
        matches := 0
        hW := windowWidth/2
		Loop %hW% {
            matches += (compareColors(Gdip_GetPixelColor(pBMScreen,A_Index-1,0,1),0x393b3d) < 16)
            if (matches >= 64){
                break
            }
        }
        Gdip_DisposeBitmap(pBMScreen)
        if (matches < 64){
            return 0
        }
	}
    updateStatus("Roblox Disconnected")
    options.Disconnects += 1
    return 1
}

/*
testPath := mainDir "images\test.png"
OutputDebug, testPath
pbm := Gdip_LoadImageFromFile(testPath) ; Gdip_BitmapFromScreen("0|0|100|100")
pbm2 := Gdip_ResizeBitmap(pbm,1500,1500,true)
Gdip_SaveBitmapToFile(pbm2,"test2.png")

MsgBox, % ocrFromBitmap(pbm2)
ExitApp
*/

robloxId := 0

mainLoop(){
    Global
    if (reconnecting){
        return
    }
    currentId := WinExist("Roblox")
    if (!currentId){
        attemptReconnect()
        return
    } else if (currentId != robloxId){
        OutputDebug, "Window switched"
        robloxId := currentId
    }

    if (checkDisconnect()){
        attemptReconnect()
        return
    }

    MouseGetPos, mouseX, mouseY
    local TLCornerX, TLCornerY, width, height
    getRobloxPos(TLCornerX, TLCornerY, width, height)
    BRCornerX := TLCornerX + width
    BRCornerY := TLCornerY + height
    statusEffectHeight := Floor((height/1080)*54)

    isActive := WinActive("Roblox")
    if (isActive == robloxId){
        if (!initialized){
            updateStatus("Initializing")
            initialize()
        }

        tMX := width/2
        tMY := height/2

        mouseActions()
        
        Sleep, 250

        align()
        
        if (options.DoingObby && (A_TickCount - lastObby) >= (obbyCooldown*1000)){
            obbyRun()
            hasBuff := checkHasObbyBuff(BRCornerX,BRCornerY,statusEffectHeight)
            Sleep, 1000
            hasBuff := hasBuff || checkHasObbyBuff(BRCornerX,BRCornerY,statusEffectHeight)
            align()
            hasBuff := hasBuff || checkHasObbyBuff(BRCornerX,BRCornerY,statusEffectHeight)
            if (!hasBuff)
            {
                updateStatus("Obby Failed, Retrying")
                lastObby := A_TickCount - obbyCooldown*1000
                obbyRun()
                hasBuff := checkHasObbyBuff(BRCornerX,BRCornerY,statusEffectHeight)
                Sleep, 1000
                hasBuff := hasBuff || checkHasObbyBuff(BRCornerX,BRCornerY,statusEffectHeight)
                align()
                hasBuff := hasBuff || checkHasObbyBuff(BRCornerX,BRCornerY,statusEffectHeight)
                if (!hasBuff){
                    lastObby := A_TickCount - obbyCooldown*1000
                }
            }
        }

        if (options.CollectItems){
            searchForItems()
        }
    }

    /*
    ;MouseMove, targetX, targetY
    Gui test1:Color, %color%
    GuiControl,,TestT,% checkHasObbyBuff(BRCornerX,BRCornerY,statusEffectHeight)
    */
}



; main ui

Menu Tray, Icon, shell32.dll, 3

Gui mainUI: New, +hWndhGui
Gui Color, 0xDADADA
Gui Add, Button, gStartClick vStartButton x8 y224 w80 h23, F1 - Start
Gui Add, Button, gPauseClick vPauseButton x96 y224 w80 h23, F2 - Pause
Gui Add, Button, gStopClick vStopButton x184 y224 w80 h23, F3 - Stop
Gui Font, s11 Norm, Segoe UI
Gui Add, Picture, gDiscordServerClick w26 h20 x462 y226, % mainDir "images\discordIcon.png"

Gui Add, Tab3, vMainTabs x8 y8 w484 h210 +0x800000, Main|Status|Settings|Credits
; main tab
Gui Tab, 1

Gui Font, s10 w600
Gui Add, GroupBox, x16 y40 w231 h70 vObbyOptionGroup -Theme +0x50000007, Obby
Gui Font, s9 norm
Gui Add, CheckBox, vObbyCheckBox x32 y59 w180 h26 +0x2, % " Do Obby (Every 2 Mins)"
Gui Add, CheckBox, vObbyBuffCheckBox x32 y80 w200 h26 +0x2, % " Check for Obby Buff Effect"
Gui Add, Button, gObbyHelpClick vObbyHelpButton x221 y50 w23 h23, ?

Gui Font, s10 w600
Gui Add, GroupBox, x252 y40 w231 h70 vAutoEquipGroup -Theme +0x50000007, Auto Equip
Gui Font, s9 norm
Gui Add, CheckBox, vAutoEquipCheckBox x268 y61 w190 h22 +0x2, % " Enable Auto Equip"
Gui Add, Button, gAutoEquipSlotSelectClick vAutoEquipSlotSelectButton x268 y83 w115 h22, Select Storage Slot
Gui Add, Button, gAutoEquipHelpClick vAutoEquipHelpButton x457 y50 w23 h23, ?

Gui Font, s10 w600
Gui Add, GroupBox, x16 y110 w467 h100 vCollectOptionGroup -Theme +0x50000007, Item Collecting
Gui Font, s9 norm
Gui Add, CheckBox, vCollectCheckBox x32 y129 w261 h26 +0x2, % " Collect Items Around the Map"
Gui Add, Button, gCollectHelpClick vCollectHelpButton x457 y120 w23 h23, ?

Gui Add, GroupBox, x26 y155 w447 h48 vCollectSpotsHolder -Theme +0x50000007, Collect From Spots
Gui Add, CheckBox, vCollectSpot1CheckBox x42 y174 w30 h26 +0x2, % " 1"
Gui Add, CheckBox, vCollectSpot2CheckBox x82 y174 w30 h26 +0x2, % " 2"
Gui Add, CheckBox, vCollectSpot3CheckBox x122 y174 w30 h26 +0x2, % " 3"
Gui Add, CheckBox, vCollectSpot4CheckBox x162 y174 w30 h26 +0x2, % " 4"
Gui Add, CheckBox, vCollectSpot5CheckBox x202 y174 w30 h26 +0x2, % " 5"
Gui Add, CheckBox, vCollectSpot6CheckBox x242 y174 w30 h26 +0x2, % " 6"
Gui Add, CheckBox, vCollectSpot7CheckBox x282 y174 w30 h26 +0x2, % " 7"

; status tab
Gui Tab, 2
Gui Font, s10 w600
Gui Add, GroupBox, x16 y40 w130 h170 vStatsGroup -Theme +0x50000007, Stats
Gui Font, s9 norm
Gui Add, Text, vStatsDisplay x22 y58 w118 h146, runtime: 123`ndisconnects: 1000

Gui Font, s10 w600
Gui Add, GroupBox, x151 y40 w200 h170 vWebhookGroup -Theme +0x50000007, Discord Webhook
Gui Font, s9 norm
Gui Add, CheckBox, vWebhookCheckBox x166 y63 w120 h16 +0x2 gEnableWebhookToggle, % " Enable Webhook"
Gui Add, Text, x161 y85 w100 h20 vWebhookInputHeader BackgroundTrans, Webhook URL:
Gui Add, Edit, x166 y105 w169 h20 vWebhookInput,% ""
Gui Add, Button, gWebhookHelpClick vWebhookHelpButton x325 y50 w23 h23, ?
; Gui Add, CheckBox, vWebhookInvScreenshotCheckBox x166 y135 w140 h16 +0x2, % " Inventory Screenshots"
; Gui Add, Text, x180 y155 w140 h20 c555555 vWebhookInvScreenshotIntervalText BackgroundTrans, % "+ Every             minute(s)"
; Gui Add, Edit, vWebhookInvScreenshotIntervalInput x224 y154 w30 h20, 60

Gui Font, s10 w600
Gui Add, GroupBox, x356 y40 w128 h170 vStatusOtherGroup -Theme +0x50000007, Other
Gui Font, s9 norm
Gui Add, CheckBox, vStatusBarCheckBox x366 y63 w110 h20 +0x2, % " Enable Status Bar"

; settings tab
Gui Tab, 3
Gui Font, s10 w600
Gui Add, GroupBox, x16 y40 w467 h65 vGeneralSettingsGroup -Theme +0x50000007, General
Gui Font, s9 norm
Gui Add, CheckBox, vVIPCheckBox x32 y58 w300 h22 +0x2, % " VIP Gamepass Owned (Movement Speed increase)"
Gui Add, Button, vImportSettingsButton gImportSettingsClick x30 y80 w130 h20, Import Settings

Gui Font, s10 w600
Gui Add, GroupBox, x16 y105 w467 h105 vReconnectSettingsGroup -Theme +0x50000007, Reconnect
Gui Font, s9 norm
Gui Add, CheckBox, vReconnectCheckBox x32 y127 w300 h16 +0x2, % " Enable Reconnect (Will reconnect if you disconnect)"
Gui Add, Text, x26 y148 w100 h20 vPrivateServerInputHeader BackgroundTrans, Private Server Link:
Gui Add, Edit, x31 y167 w437 h20 vPrivateServerInput,% ""


; credits tab
Gui Tab, 4
Gui Font, s10 w600
Gui Add, GroupBox, x16 y40 w231 h170 vCreditsGroup -Theme +0x50000007, The Creator
Gui Add, Picture, w75 h75 x23 y62, % mainDir "images\pfp.png"
Gui Font, s12 w600
Gui Add, Text, x110 y57 w130 h22,BuilderDolphin
Gui Font, s8 norm italic
Gui Add, Text, x120 y78 w80 h18,(dolphin)
Gui Font, s8 norm
Gui Add, Text, x115 y95 w124 h40,"This was supposed to be a short project to learn AHK..."
Gui Font, s8 norm
Gui Add, Text, x28 y145 w200 h32,% "More to come soon perhaps..."

Gui Font, s10 w600
Gui Add, GroupBox, x252 y40 w231 h90 vCreditsGroup2 -Theme +0x50000007, The Inspiration
Gui Add, Picture, w60 h60 x259 y62, % mainDir "images\auryn.ico"
Gui Font, s8 norm
Gui Add, Text, x326 y59 w150 h68,% "Natro Macro, a macro for Bee Swarm Simulator has greatly inspired this project and has helped me create this project overall."

Gui Font, s10 w600
Gui Add, GroupBox, x252 y130 w231 h80 vCreditsGroup3 -Theme +0x50000007, Other
Gui Font, s9 norm
Gui Add, Link, x268 y150 w200 h55, Join the <a href="https://discord.gg/DYUqwJchuV">Discord Server</a>! (Community)`n`nVisit the <a href="https://github.com/BuilderDolphin/dolphSol-Macro">GitHub</a>! (Updates + Versions)

Gui Show, % "w500 h254 x" clamp(options.WindowX,10,A_ScreenWidth-100) " y" clamp(options.WindowY,10,A_ScreenHeight-100), % "dolphSol Macro " version


; status bar
Gui statusBar:New, AlwaysOnTop
Gui Font, s10 norm
Gui Add, Text, x5 y5 w210 h15 vStatusBarText, Status: Waiting...


Gui mainUI:Default



global directValues := {"ObbyCheckBox":"DoingObby"
    ,"ObbyBuffCheckBox":"CheckObbyBuff"
    ,"CollectCheckBox":"CollectItems"
    ,"VIPCheckBox":"VIP"
    ,"AutoEquipCheckBox":"AutoEquipEnabled"
    ,"ReconnectCheckBox":"ReconnectEnabled"
    ,"WebhookCheckBox":"WebhookEnabled"
    ,"WebhookInput":"WebhookLink"
    ,"StatusBarCheckBox":"StatusBarEnabled"}

updateUIOptions(){
    for i,v in directValues {
        GuiControl,,%i%,% options[v]
    }

    if (options.PrivateServerId){
        GuiControl,, PrivateServerInput,% privateServerPre options.PrivateServerId
    } else {
        GuiControl,, PrivateServerInput,% ""
    }
    
    Loop 7 {
        v := options["ItemSpot" . A_Index]
        GuiControl,,CollectSpot%A_Index%CheckBox,%v%
    }
}
updateUIOptions()

validateWebhookLink(link){
    return RegExMatch(link,"\Qhttps://discord.com/api/webhooks/\E(\d+)/.*") && !RegExMatch(link,"=")
}

applyNewUIOptions(){
    global hGui
    Gui mainUI:Default

    VarSetCapacity(wp, 44), NumPut(44, wp)
    DllCall("GetWindowPlacement", "uint", hGUI, "uint", &wp)
	x := NumGet(wp, 28, "int"), y := NumGet(wp, 32, "int")
    
    options.WindowX := x
    options.WindowY := y

    for i,v in directValues {
        GuiControlGet, rValue,,%i%
        options[v] := rValue
    }

    GuiControlGet, privateServerL,,PrivateServerInput
    if (privateServerL){
        RegExMatch(privateServerL, "(?<=privateServerLinkCode=)(.{32})", serverId)
        if (!serverId && RegExMatch(privateServerL, "(?<=code=)(.{32})")){
            MsgBox, % "The private server link you provided is a share link, instead of a privateServerLinkCode link. To get the code link, paste the share link into your browser and run it. This should convert the link to a privateServerLinkCode link. Copy and paste the converted link into the Private Server setting to fix this issue.`n`nThe link should look like: https://www.roblox.com/games/15532962292/Sols-RNG?privateServerLinkCode=..."
        }
        options.PrivateServerId := serverId ""
    }

    GuiControlGet, webhookLink,,WebhookInput
    if (webhookLink){
        valid := validateWebhookLink(webhookLink)
        if (valid){
            options.WebhookLink := webhookLink
        } else {
            if (options.WebhookLink){
                MsgBox,0,New Webhook Link Invalid, % "Invalid webhook link, the link has been reverted to your previous valid one."
            } else {
                MsgBox,0,Webhook Link Invalid, % "Invalid webhook link, the webhook option has been disabled."
                options.WebhookEnabled := 0
            }
        }
    }

    Loop 7 {
        GuiControlGet, rValue,,CollectSpot%A_Index%CheckBox
        options["ItemSpot" . A_Index] := rValue
    }
}

global importingSettings := 0
handleImportSettings(){
    global configPath

    if (importingSettings){
        return
    }

    MsgBox, % 1 + 4096, % "Import Settings", % "To import the settings from a previous version folder of the Macro, please select the ""config.ini"" file located in the previous version's ""settings"" folder when prompted. Press OK to begin."

    IfMsgBox, Cancel
        return
    
    importingSettings := 1

    FileSelectFile, targetPath, 3,, Import dolphSol Settings Through a config.ini File, % "Configuration settings (config.ini)"

    if (targetPath && RegExMatch(targetPath,"\\config\.ini")){
        if (targetPath != configPath){
            FileRead, retrieved, %targetPath%

            if (!ErrorLevel){
                FileDelete, %configPath%
                FileAppend, %retrieved%, %configPath%

                loadData()
                updateUIOptions()
                saveOptions()

                MsgBox, 0,Import Settings,% "Success!"
            } else {
                MsgBox,0,Import Settings Error, % "An error occurred while reading the file, please try again."
            }
        } else {
            MsgBox, 0,Import Settings Error, % "Cannot import settings from the current macro!"
        }
    }
}

handleWebhookEnableToggle(){
    GuiControlGet, rValue,,WebhookCheckBox

    if (rValue){
        GuiControlGet, link,,WebhookInput
        if (!validateWebhookLink(link)){
            GuiControl, , WebhookCheckBox,0
            MsgBox,0,Webhook Link Invalid, % "Invalid webhook link, the webhook option has been disabled."
        }
    }
}

global statDisplayInfo := {"RunTime":"Run Time"
    ,"Disconnects":"Disconnects"
    ,"ObbyCompletes":"Obby Completes"
    ,"ObbyAttempts":"Obby Attempts"
    ,"CollectionLoops":"Collection Loops"}

formatNum(n,digits := 2){
    n := Floor(n+0.5)
    cDigits := Max(1,Ceil(Log(Max(n,1))))
    final := n
    if (digits > cDigits){
        loopCount := digits-cDigits
        Loop %loopCount% {
            final := "0" . final
        }
    }
    return final
}

getTimerDisplay(t){
    return formatNum(Floor(t/86400)) . ":" . formatNum(Floor(Mod(t,86400)/3600)) . ":" . formatNum(Floor(Mod(t,3600)/60)) . ":" . formatNum(Mod(t,60))
}

updateUI(){
    ; per 1s
    if (running){
        options.RunTime += 1
    }

    statText := ""
    for i,v in statDisplayInfo {
        value := options[i]
        if (statText){
            statText .= "`n"
        }
        if (i = "RunTime"){
            value := getTimerDisplay(value)
        }
        statText .= v . ": " . value
    }
    GuiControl, , StatsDisplay, % statText
}
updateUI()

global statusColors := {"Starting Macro":3447003
    ,"Roblox Disconnected":15548997
    ,"Reconnecting":9807270
    ,"Reconnecting, Roblox Opened":9807270
    ,"Reconnecting, Game Loaded":9807270
    ,"Reconnect Complete":3447003
    ,"Initializing":3447003
    ,"Searching for Items":15844367
    ,"Doing Obby":15105570
    ,"Completed Obby":5763719
    ,"Obby Failed, Retrying":11027200
    ,"Macro Stopped":3447003}

updateStatus(newStatus){
    if (options.WebhookEnabled){
        FormatTime, fTime, , HH:mm:ss
        webhookPost("[" fTime "]: " newStatus,,statusColors[newStatus] ? statusColors[newStatus] : 1)
    }
    GuiControl,statusBar:,StatusBarText,% "Status: " newStatus
}

global selectingAutoEquip := 0

startAutoEquipSelection(){
    if (selectingAutoEquip || macroStarted){
        return
    }

    MsgBox, % 1 + 4096, Begin Auto Equip Selection, % "Once you press OK, please click on the inventory slot that you would like to automatically equip.`n`nPlease ensure that your storage is open upon pressing OK. Press Cancel if it is not open yet."

    IfMsgBox, Cancel
        return
    
    if (macroStarted){
        return
    }

    selectingAutoEquip := 1

    w:=A_ScreenWidth,h:=A_ScreenHeight-2
    Gui Dimmer:New,+AlwaysOnTop +ToolWindow -Caption +E0x20 ;Clickthru
    Gui Color, 333333
    Gui Show,NoActivate x0 y0 w%w% h%h%,Dimmer
    WinSet Transparent,% 75,Dimmer
    Gui DimmerTop:New,+AlwaysOnTop +ToolWindow -Caption +E0x20
    Gui Color, 222222
    Gui Font, s13
    Gui Add, Text, % "x0 y0 w400 h40 cWhite 0x200 Center", Click the target storage slot (Right-click to cancel)
    Gui Show,% "NoActivate x" (A_ScreenWidth/2)-200 " y25 w400 h40"

    Gui mainUI:Hide


}

cancelAutoEquipSelection(){
    if (!selectingAutoEquip) {
        return
    }
    Gui Dimmer:Destroy
    Gui DimmerTop:Destroy
    Gui mainUI:Show
    selectingAutoEquip := 0
}

completeAutoEquipSelection(){
    if (!selectingAutoEquip){
        return
    }
    applyNewUIOptions()

    MouseGetPos, mouseX,mouseY
    uv := getStorageUVFromPosition(mouseX,mouseY)
    options.AutoEquipX := uv[1]
    options.AutoEquipY := uv[2]

    saveOptions()
    cancelAutoEquipSelection()

    MsgBox, 0,Auto Equip Selection,Success!
}

handleLClick(){
    if (selectingAutoEquip){
        completeAutoEquipSelection()
    }
}

handleRClick(){
    if (selectingAutoEquip){
        cancelAutoEquipSelection()
    }
}

SetTimer, SecondTick, 1000

startMacro(){
    if (!canStart){
        return
    }
    global robloxId
    if (macroStarted) {
        return
    }
    macroStarted := 1
    updateStatus("Starting Macro")

    ; cancel any interfering stuff
    cancelAutoEquipSelection()

    applyNewUIOptions()
    saveOptions()

    Gui, mainUI:+LastFoundExist
    WinSetTitle, % "dolphSol Macro " version " (Running)"

    if (options.StatusBarEnabled){
        Gui statusBar:Show, % "w220 h25 x" (A_ScreenWidth-300) " y50", dolphSol Status
    }
    
    robloxId := WinExist("Roblox")
    if (!robloxId){
        attemptReconnect()
    }

    running := 1
    WinActivate, Roblox
    while running {
        mainLoop()
        
        Sleep, 2000
    }
}

if (!options.WasRunning){
    options.WasRunning := 1
    saveOptions()
    MsgBox, 0,dolphSol Macro - Welcome, % "Welcome to dolphSol macro!`n`nIf this is your first time here, make sure to go through all of the tabs to make sure your settings are right.`n`nSince there is no current auto-update system in place, it is suggested that you join the Discord server and/or check the GitHub page for updates, which can both be found in the Credits page. (Discord link is also in the bottom right corner)"
}

canStart := 1

return

; button stuff

StartClick:
    startMacro()
    return

PauseClick:
    MsgBox, 0,% "Pause",% "Please note that the pause feature isn't very stable currently. It is suggested to stop instead."
    Pause
    return

StopClick:
    stop()
    Reload
    return

AutoEquipSlotSelectClick:
    startAutoEquipSelection()
    return

DiscordServerClick:
    Run % "https://discord.gg/DYUqwJchuV"
    return

EnableWebhookToggle:
    handleWebhookEnableToggle()
    return

ImportSettingsClick:
    handleImportSettings()
    return

; help buttons

ObbyHelpClick:
    MsgBox, 0, Obby, % "Section for attempting to complete the Obby on the map for the +30% luck buff every 2 minutes. If you have the VIP Gamepass, make sure to enable it in Settings.`n`nCheck For Obby Buff Effect - Checks your status effects upon completing the obby and attempts to find the buff. If it is missing, the macro will retry the obby one more time. Disable this if your macro keeps retrying the obby after completing it. The ObbyCompletes stat will only increase if this check is enabled.`n`nPLEASE NOTE: The macro's obby completion ability HIGHLY depends on a stable frame-rate, and will likely fail from any frame freezes. If your macro is unable to complete the obby at all, it is best to disable this option."
    return

AutoEquipHelpClick:
    MsgBox, 0, Auto Equip, % "Section for automatically equipping a specified aura every macro round. This is important for equipping auras without walk animations, which may interfere with the macro. This defaults to your first storage slot if not selected. Enabling this will close your chat window due to it possibly getting in the way of the storage button.`n`nUse the Select Storage Slot button to select a slot in your Aura Storage to automatically equip. Right click when selecting to cancel.`n`nThis feature is HIGHLY RECOMMENDED to be used on a non-animation aura for best optimization."
    return

CollectHelpClick:
    MsgBox, 0, Item Collecting, % "Section for automatically collecting naturally spawned items around the map. Enabling this will have the macro check the selected spots every loop after doing the obby (if enabled and ready).`n`nYou can also specify which spots to collect from. If a spot is disabled, the macro will not grab any items from the spot. Please note that the macro always takes the same path, it just won't collect from a spot if it's disabled. This feature is useful if you are sharing a server with a friend, and split the spots with them.`n`nItem Spots:`n 1 - Left of the Leaderboards`n 2 - Bottom left edge of the Map`n 3 - Under a tree next to the House`n 4 - Inside the House`n 5 - Under the tree next to Jake's Shop`n 6 - Under the tree next to the Mountain`n 7 - On top of the Hill with the Cave"
    return

WebhookHelpClick:
    MsgBox, 0, Discord Webhook, % "Section for connecting a Discord Webhook to have status messages displayed in a target Discord Channel. Enable this option by entering a valid Discord Webhook link.`n`nTo create a webhook, you must have Administrator permissions in a server (preferably your own, separate server). Go to your target channel, then configure it. Go to Integrations, and create a Webhook in the Webhooks Section. After naming it whatever you like, copy the Webhook URL, then paste it into the macro. Now you can enable the Discord Webhook option!`n`nRequires a valid Webhook URL to enable."

f1::startMacro()
f2::Pause
f3::
    stop()
    Reload

~LButton::handleLClick()
~RButton::handleRClick()

mainUIGuiClose:
    stop(1)

SecondTick:
updateUI()