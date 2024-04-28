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

if (RegExMatch(A_ScriptDir,"\.zip")){
    MsgBox, 0, % "Running From ZIP", % "You are attempting to run the script from a ZIP file.`n`nPlease Extract/Unzip the file first, then run the script in the extracted folder."
    ExitApp
}

#Include %A_ScriptDir%\lib
#Include ocr.ahk
#Include Gdip_All.ahk
#Include Gdip_ImageSearch.ahk

Gdip_Startup()

global version := "v1.3.5"

global robloxId := 0

global canStart := 0
global macroStarted := 0
global reconnecting := 0

global isSpawnCentered := 0
global atSpawn := 0

global pathsRunning := []

obbyCooldown := 120 ; 120 seconds
lastObby := A_TickCount - obbyCooldown*1000
hasObbyBuff := 0

obbyStatusEffectColor := 0x9CFFAC

statusEffectSpace := 5

global mainDir := A_ScriptDir "\"

configPath := mainDir . "settings\config.ini"
global ssPath := "ss.jpg"
global pathDir := mainDir . "paths\"
global imgDir := mainDir . "images\"

configHeader := "; dolphSol Settings`n;   Do not put spaces between equals`n;   Additions may break this file and the macro overall, please be cautious`n;   If you mess up this file, clear it entirely and restart the macro`n`n[Options]`r`n"

global potionIndex := {0:"None"
    ,1:"Fortune Potion I"
    ,2:"Fortune Potion II"
    ,3:"Fortune Potion III"
    ,4:"Haste Potion I"
    ,5:"Haste Potion II"
    ,6:"Heavenly Potion I"
    ,7:"Heavenly Potion II"
    ,8:"Universe Potion I"}


global craftingInfo := {"Gilded Coin":{slot:13,addSlots:1,maxes:[1],attempts:5,addedAttempts:1}
    ,"Fortune Potion I":{slot:1,subSlot:1,addSlots:4,maxes:[5,1,5,1],attempts:2}
    ,"Fortune Potion II":{slot:1,subSlot:2,addSlots:5,maxes:[1,10,5,10,2],attempts:2}
    ,"Fortune Potion III":{slot:1,subSlot:3,addSlots:5,maxes:[1,15,10,15,5],attempts:2}
    ,"Haste Potion I":{slot:2,subSlot:1,addSlots:4,maxes:[10,5,10,1],attempts:2}
    ,"Haste Potion II":{slot:2,subSlot:2,addSlots:5,maxes:[1,10,10,15,2],attempts:2}
    ,"Heavenly Potion I":{slot:3,subSlot:1,addSlots:4,maxes:[100,50,20,1],attempts:2}
    ,"Heavenly Potion II":{slot:3,subSlot:2,addSlots:5,maxes:[2,125,75,50,1],attempts:2}
    ,"Universe Potion I":{slot:4,subSlot:1,addSlots:3,maxes:[10,15,2],attempts:2}}

global rarityIndex := {0:"None"
    ,1:"1/1k+"
    ,2:"1/10k+"
    ,3:"1/100k+"}

reverseIndices(t){
    newT := {}
    for i,v in t {
        newT[v] := i
    }
    return newT
}

global reversePotionIndex := reverseIndices(potionIndex)
global reverseRarityIndex := reverseIndices(rarityIndex)

; defaults
global options := {"DoingObby":1
    ,"AzertyLayout":0
    ,"ArcanePath":0
    ,"CheckObbyBuff":1
    ,"CollectItems":1
    ,"ItemSpot1":1
    ,"ItemSpot2":1
    ,"ItemSpot3":1
    ,"ItemSpot4":1
    ,"ItemSpot5":1
    ,"ItemSpot6":1
    ,"ItemSpot7":1
    ,"Screenshotinterval":60
    ,"WindowX":100
    ,"WindowY":100
    ,"VIP":0
    ,"BackOffset":0
    ,"ReconnectEnabled":1
    ,"AutoEquipEnabled":0
    ,"AutoEquipX":-0.415
    ,"AutoEquipY":-0.438
    ,"PrivateServerId":""
    ,"WebhookEnabled":0
    ,"WebhookLink":""
    ,"WebhookImportantOnly":0
    ,"DiscordUserID":""
    ,"WebhookRollSendMinimum":10000
    ,"WebhookRollPingMinimum":100000
    ,"WebhookAuraRollImages":0
    ,"StatusBarEnabled":0
    ,"WasRunning":0
    ,"FirstTime":0
    ,"CraftingInterval":10
    ,"ItemCraftingEnabled":0
    ,"CraftingGildedCoin":1
    ,"PotionCraftingEnabled":0
    ,"PotionCraftingSlot1":0
    ,"PotionCraftingSlot2":0
    ,"PotionCraftingSlot3":0
    ,"LastCraftSession":0
    ,"InvScreenshotsEnabled":1
    ,"LastInvScreenshot":0

    ,"ExtraRoblox":0 ; mainly for me (builderdolphin) to run my 3rd acc on 2nd monitor, not used for anything else, not intended for public use unless yk what you're doing i guess

    ; not really options but stats i guess
    ,"RunTime":0
    ,"Disconnects":0
    ,"ObbyCompletes":0
    ,"ObbyAttempts":0
    ,"CollectionLoops":0}

global sData := {}

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

updateYesClicked(){
    Run % (sData.versionLink ? sData.versionLink : "https://github.com/BuilderDolphin/dolphSol-Macro/releases/latest")
    ExitApp
}

updateStaticData(){
    url := "https://raw.githubusercontent.com/BuilderDolphin/dolphSol-Macro/main/lib/staticData.ini"

    WinHttp := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    WinHttp.Open("GET", url, false)
    WinHttp.SetRequestHeader("Cache-Control", "no-cache")
    WinHttp.SetRequestHeader("Pragma", "no-cache")
    WinHttp.Send()

    If (WinHttp.Status = 200) {
        content := WinHttp.ResponseText
        FileDelete, staticData.ini
        FileAppend, %content%, staticData.ini
    }

    sData := getINIData("staticData.ini")
    if (sData.latestVersion != version){
        MsgBox, 4, % "New Update Available", % "A new update is available! Would you like to head to the GitHub page to update your macro?" . (sData.updateNotes ? ("`n`nUpdate Notes:`n" . sData.updateNotes) : "")
        
        IfMsgBox Yes
            updateYesClicked()
    }
}
updateStaticData()

; CreateFormData() by tmplinshi, AHK Topic: https://autohotkey.com/boards/viewtopic.php?t=7647
; Thanks to Coco: https://autohotkey.com/boards/viewtopic.php?p=41731#p41731
; Modified version by SKAN, 09/May/2016

CreateFormData(ByRef retData, ByRef retHeader, objParam) {
	New CreateFormData(retData, retHeader, objParam)
}

Class CreateFormData {

    __New(ByRef retData, ByRef retHeader, objParam) {

        Local CRLF := "`r`n", i, k, v, str, pvData
        ; Create a random Boundary
        Local Boundary := this.RandomBoundary()
        Local BoundaryLine := "------------------------------" . Boundary

        this.Len := 0 ; GMEM_ZEROINIT|GMEM_FIXED = 0x40
        this.Ptr := DllCall( "GlobalAlloc", "UInt",0x40, "UInt",1, "Ptr" ) ; allocate global memory

        ; Loop input paramters
        For k, v in objParam
        {
            If IsObject(v) {
                For i, FileName in v
                {
                    str := BoundaryLine . CRLF
                    . "Content-Disposition: form-data; name=""" . k . """; filename=""" . FileName . """" . CRLF
                    . "Content-Type: " . this.MimeType(FileName) . CRLF . CRLF
                    this.StrPutUTF8( str )
                    this.LoadFromFile( Filename )
                    this.StrPutUTF8( CRLF )
                }
            } Else {
                str := BoundaryLine . CRLF
                . "Content-Disposition: form-data; name=""" . k """" . CRLF . CRLF
                . v . CRLF
                this.StrPutUTF8( str )
            }
        }

        this.StrPutUTF8( BoundaryLine . "--" . CRLF )

        ; Create a bytearray and copy data in to it.
        retData := ComObjArray( 0x11, this.Len ) ; Create SAFEARRAY = VT_ARRAY|VT_UI1
        pvData := NumGet( ComObjValue( retData ) + 8 + A_PtrSize )
        DllCall( "RtlMoveMemory", "Ptr",pvData, "Ptr",this.Ptr, "Ptr",this.Len )

        this.Ptr := DllCall( "GlobalFree", "Ptr",this.Ptr, "Ptr" ) ; free global memory 

        retHeader := "multipart/form-data; boundary=----------------------------" . Boundary
    }

    StrPutUTF8( str ) {
        Local ReqSz := StrPut( str, "utf-8" ) - 1
        this.Len += ReqSz ; GMEM_ZEROINIT|GMEM_MOVEABLE = 0x42
        this.Ptr := DllCall( "GlobalReAlloc", "Ptr",this.Ptr, "UInt",this.len + 1, "UInt", 0x42 ) 
        StrPut( str, this.Ptr + this.len - ReqSz, ReqSz, "utf-8" )
    }

    LoadFromFile( Filename ) {
        Local objFile := FileOpen( FileName, "r" )
        this.Len += objFile.Length ; GMEM_ZEROINIT|GMEM_MOVEABLE = 0x42 
        this.Ptr := DllCall( "GlobalReAlloc", "Ptr",this.Ptr, "UInt",this.len, "UInt", 0x42 )
        objFile.RawRead( this.Ptr + this.Len - objFile.length, objFile.length )
        objFile.Close() 
    }

    RandomBoundary() {
        str := "0|1|2|3|4|5|6|7|8|9|a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z"
        Sort, str, D| Random
        str := StrReplace(str, "|")
        Return SubStr(str, 1, 12)
    }

    MimeType(FileName) {
        n := FileOpen(FileName, "r").ReadUInt()
        Return (n = 0x474E5089) ? "image/png"
        : (n = 0x38464947) ? "image/gif"
        : (n&0xFFFF = 0x4D42 ) ? "image/bmp"
        : (n&0xFFFF = 0xD8FF ) ? "image/jpeg"
        : (n&0xFFFF = 0x4949 ) ? "image/tiff"
        : (n&0xFFFF = 0x4D4D ) ? "image/tiff"
        : "application/octet-stream"
    }

}

webhookPost(data := 0){
    data := data ? data : {}

    url := options.webhookLink

    if (data.pings){
        data.content := data.content ? data.content " <@" options.DiscordUserID ">" : "<@" options.DiscordUserID ">"
    }

    payload_json := "
		(LTrim Join
		{
			""content"": """ data.content """,
			""embeds"": [{
                " (data.embedAuthor ? """author"": {""name"": """ data.embedAuthor """" (data.embedAuthorImage ? ",""icon_url"": """ data.embedAuthorImage """" : "") "}," : "") "
                " (data.embedTitle ? """title"": """ data.embedTitle """," : "") "
				""description"": """ data.embedContent """,
                " (data.embedThumbnail ? """thumbnail"": {""url"": """ data.embedThumbnail """}," : "") "
                " (data.embedImage ? """image"": {""url"": """ data.embedImage """}," : "") "
                " (data.embedFooter ? """footer"": {""text"": """ data.embedFooter """}," : "") "
				""color"": """ (data.embedColor ? data.embedColor : 0) """
			}]
		}
		)"

    if ((!data.embedContent && !data.embedTitle) || data.noEmbed)
        payload_json := RegExReplace(payload_json, ",.*""embeds.*}]", "")
    

    objParam := {payload_json: payload_json}

    for i,v in (data.files ? data.files : []) {
        objParam["file" i] := [v]
    }

    CreateFormData(postdata,hdr_ContentType,objParam)

    WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    WebRequest.Open("POST", url, true)
    WebRequest.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko")
    WebRequest.SetRequestHeader("Content-Type", hdr_ContentType)
    WebRequest.SetRequestHeader("Pragma", "no-cache")
    WebRequest.SetRequestHeader("Cache-Control", "no-cache, no-store")
    WebRequest.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
    WebRequest.Send(postdata)
    WebRequest.WaitForResponse()
}

HasVal(haystack, needle) {
    for index, value in haystack
        if (value = needle)
            return index
    if !(IsObject(haystack))
        throw Exception("Bad haystack!", -1, haystack)
    return 0
}

global possibleDowns := ["w","a","s","d","Space","Enter","Esc","r"]

liftKeys(){
    for i,v in possibleDowns {
        Send {%v% Up}
    }
}

stop(terminate := 0) {
    if (running){
        updateStatus("Macro Stopped")
    }

    if (terminate){
        options.WasRunning := 0
    }

    DetectHiddenWindows, On
    WinClose, % mainDir . "lib\status.ahk"

    for i,v in pathsRunning {
        WinClose, % v
    }

    liftKeys()

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

        WinActivate, ahk_id %robloxId%
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

getWalkTime(d){
    return d*(1 + (regWalkFactor-1)*(1-options.VIP))
}

walkSleep(d){
    Sleep, % getWalkTime(d)
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

arcaneTeleport(){
    press("x",50)
}

; main stuff

global initialized := 0
global running := 0

initialize()
{
    initialized := 1
    resetZoom()
    if (options.InitialAlign){
        ; runPath("initialAlignment",[],1) no more no reset!
    }
}

resetZoom(){
    Loop 2 {
        if (checkInvOpen()){
            clickMenuButton(1)
        } else {
            break
        }
        Sleep, 400
    }

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

alignCamera(){
    closeChat()
    Sleep, 200

    clickMenuButton(2)
    Sleep, 500
    getRobloxPos(rX,rY,rW,rH)
    MouseMove, % rX + rW*0.15, % rY + 44 + rH*0.05 + options.BackOffset
    Sleep, 200
    MouseClick
    Sleep, 500
}

align(forCollection := 0){ ; align v2
    if (isSpawnCentered && forCollection){
        isSpawnCentered := 0
        atSpawn := 0
        return
    }
    updateStatus("Aligning Character")
    if (atSpawn){
        atSpawn := 0
    } else {
        reset()
        Sleep, 4000
    }

    alignCamera()

    Send, {w Down}
    Send, {a Down}
    walkSleep(2500)
    Send, {a Up}
    walkSleep(750)
    Send, {w Up}
    Sleep, 50
    if (forCollection){
        Send, {s Down}
        Send, {d Down}
        walkSleep(1000)
        Send, {s Up}
        walkSleep(100)
        Send, {d Up}
        Sleep, 50
    } else {
        press("s",2500)
        Sleep, 50
    }
}

collect(num){
    if (!options["ItemSpot" . num]){
        return
    }
    Loop, 6 
    {
        Send {f}
        Sleep, 75
    }
    Send {e}
    Sleep, 50
}

runPath(pathName,voidPoints,noCenter = 0){
    try {
        targetDir := pathDir . pathName . ".ahk"
        if (!FileExist(targetDir)){
            MsgBox, 0, % "Error",% "Path file: " . targetDir . " does not exist."
            return
        }
        if (HasVal(pathsRunning,targetDir)){
            return
        }
        pathsRunning.Push(targetDir)
        
        DetectHiddenWindows, On
        Run, % """" . A_AhkPath . """ """ . targetDir . """"

        stopped := 0

        Loop 5 {
            if (WinExist(targetDir)){
                break
            }
            Sleep, 200
        }

        getRobloxPos(rX,rY,width,height)
        scanPoints := [[rX+1,rY+1],[rX+width-2,rY+1],[rX+1,rY+height-2],[rX+width-2,rY+height-2]]

        voidPoints := voidPoints ? voidPoints : []
        startTick := A_TickCount
        expectedVoids := 0
        voidCooldown := 0

        while (WinExist(targetDir)){
            for i,v in voidPoints {
                if (v){
                    if (A_TickCount-startTick >= getWalkTime(v)){
                        expectedVoids += 1
                        voidPoints[i] := 0
                    }
                }
            }

            blackCorners := 0
            for i,point in scanPoints {
                PixelGetColor, pColor, % point[1], % point[2], RGB
                blackCorners += compareColors(pColor,0x000000) < 8
            }
            PixelGetColor, pColor, % rX+width*0.5, % rY+height*0.5, RGB
            centerBlack := compareColors(pColor,0x000000) < 8
            if (blackCorners = 3 && centerBlack){
                if (!voidCooldown){
                    voidCooldown := 5
                    expectedVoids -= 1
                    if (expectedVoids < 0){
                        stopped := 1
                        break
                    }
                }
            }
            Sleep, 225
            voidCooldown := Max(0,voidCooldown-1)
        }

        if (stopped){
            WinClose, % targetDir
            isSpawnCentered := 0
            atSpawn := 1
        } else if (!noCenter) {
            isSpawnCentered := 1
        }
        liftKeys()
        pathsRunning.Remove(HasVal(pathsRunning,targetDir))
    } catch e {
        MsgBox, 0,Path Error,% "An error occurred when running path: " . pathDir . "`n:" . e
    }
}

searchForItemsOld(){
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

searchForItems(){
    updateStatus("Searching for Items")
    
    atSpawn := 0

    runPath("searchForItems",[8250],1)

    options.CollectionLoops += 1
}

doObby(){
    updateStatus("Doing Obby")
    
    runPath("doObby",[],1)

    options.ObbyAttempts += 1
}

walkToObby(){
    updateStatus("Walking to Obby")
    if(options.ArcanePath){
        if(options.VIP){
            send {a down}
            walkSleep(2300)
            jump()
            walkSleep(500)
            arcaneTeleport()
            walkSleep(625)
            jump()
            walkSleep(1850)
            send {a up}
        }else{
            send {a down}
            walkSleep(2300)
            jump()
            walkSleep(500)
            arcaneTeleport()
            walkSleep(550)
            jump()
            walkSleep(1850)
            send {a up}
        }
    } else {
        send {a down}
        walkSleep(2300)
        jump()
        walkSleep(2000)
        jump()
        walkSleep(1850)
        send {a up}
    }
}

obbyRun(){
    global lastObby
    walkToObby()
    Sleep, 250
    doObby()
    lastObby := A_TickCount
    Sleep, 100
}

walkToJakesShop(){
    press("a",800)
    press("s",1200)
}

walkToPotionCrafting(){
    Send {a Down}
    walkSleep(2300)
    jump()
    walkSleep(300 + 100*(!options.VIP))
    Send {a Up}
    press("s",9500)
    Send {w Down}
    jump()
    walkSleep(1150)
    Send {w Up}
    Send {Space Down}
    Send {d Down}
    walkSleep(2000)
    Send {Space Up}
    walkSleep(3000)
    Send {d Up}
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

checkInvOpen(){
    checkPos := getPositionFromAspectRatioUV(0.861357, 0.494592,storageAspectRatio)
    PixelGetColor, checkC, % checkPos[1], % checkPos[2], RGB
    alreadyOpen := compareColors(checkC,0xffffff) < 8
    return alreadyOpen
}

mouseActions(){
    updateStatus("Performing Mouse Actions")

    getRobloxPos(pX,pY,width,height)

    ; close jake shop if popup

    openP := getPositionFromAspectRatioUV(0.718,0.689,599/1015)
    openP2 := getPositionFromAspectRatioUV(0.718,0.689,1135/1015)
    MouseMove, % openP[1], % openP2[2]
    Sleep, 200
    MouseClick
    Sleep, 200

    ; re equip
    if (options.AutoEquipEnabled){
        closeChat()
        alreadyOpen := checkInvOpen()

        if (!alreadyOpen){
            clickMenuButton(1)
        }
        Sleep, 100
        sPos := getPositionFromAspectRatioUV(options.AutoEquipX,options.AutoEquipY,storageAspectRatio)
        MouseMove, % sPos[1], % sPos[2]
        Sleep, 300
        MouseClick
        Sleep, 100
        ePos := getPositionFromAspectRatioUV(storageEquipUV[1],storageEquipUV[2],storageAspectRatio)
        MouseMove, % ePos[1], % ePos[2]
        Sleep, 300
        MouseClick
        Sleep, 100
        clickMenuButton(1)
    }

    Sleep, 250

    if (options.ExtraRoblox){ ; for afking my 3rd alt lol
        MouseMove, 2150, 700
        Sleep, 300
        MouseClick
        Sleep, 250
        jump()
        Sleep, 500
        Loop 5 {
            Send {f}
            Sleep, 200
        }
        MouseMove, 2300,800
        Sleep, 300
        MouseClick
        Sleep, 250
    }

    MouseMove, % pX + width*0.5, % pY + height*0.5
    Sleep, 300
    MouseClick
    Sleep, 250
}

isFullscreen() {
	WinGetPos,,, w, h, Roblox
	return (w = A_ScreenWidth && h = A_ScreenHeight)
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

getRobloxPos(ByRef x := "", ByRef y := "", ByRef width := "", ByRef height := "", hwnd := ""){
    if !hwnd
        hwnd := GetRobloxHWND()
    VarSetCapacity( buf, 16, 0 )
    DllCall( "GetClientRect" , "UPtr", hwnd, "ptr", &buf)
    DllCall( "ClientToScreen" , "UPtr", hwnd, "ptr", &buf)

    x := NumGet(&buf,0,"Int")
    y := NumGet(&buf,4,"Int")
    width := NumGet(&buf,8,"Int")
    height := NumGet(&buf,12,"Int")
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
    startPos := [menuEdgeCenter[1]+(menuBarButtonSize/2),menuEdgeCenter[2]+(menuBarButtonSize/4)-(menuBarButtonSize+menuBarVSpacing-1)*3] ; final factor = 0.5x (x is number of menu buttons visible to all, so exclude private server button)
    
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
global storageEquipUV := [-0.625,0.0423] ; equip button

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

getPositionFromAspectRatioUV(x,y,aspectRatio){
    getRobloxPos(rX, rY, width, height)
    
    ar := getAspectRatioSize(aspectRatio, width, height)

    oX := Floor((width-ar[1])/2) + rX
    oY := Floor((height-ar[2])/2) + rY

    p := getFromUV(x,y,oX,oY,ar[1],ar[2]) ; [Floor((x*ar[2] + ar[1])/2)+oX,Floor((y*ar[2] + ar[2])/2)+oY]

    return p
}

getAspectRatioUVFromPosition(x,y,aspectRatio){
    getRobloxPos(rX, rY, width, height)
    
    ar := getAspectRatioSize(aspectRatio, width, height)

    oX := Floor((width-ar[1])/2) + rX
    oY := Floor((height-ar[2])/2) + rY

    p := getUV(x,y,oX,oY,ar[1],ar[2])

    return p
}

/*
Sleep, 10000
MouseGetPos, mx,my
p := getAspectRatioUVFromPosition(mx,my,storageAspectRatio)
OutputDebug, % p[1] " " p[2]
*/

clickCraftingSlot(num,isPotionSlot := 0){
    getRobloxPos(rX,rY,width,height)

    scrollCenter := 0.17*width + rX
    scrollerHeight := 0.78*height
    scrollStartY := 0.15*height + rY

    slotHeight := (width/1920)*138

    if (isPotionSlot){ ; potion select sub menu
        scrollCenter := 0.365*width + rX
        scrollerHeight := 0.38*height
        scrollStartY := 0.325*height + rY
        slotHeight := (width/1920)*129
    }

    MouseMove, % scrollCenter, % scrollStartY-2
    Sleep, 250
    Click, WheelDown ; in case res upd
    Sleep, 100
    Loop 10 {
        Click, WheelUp
        Sleep, 75
    }

    fittingSlots := Floor(scrollerHeight/slotHeight) + (Mod(scrollerHeight, slotHeight) > height*0.045)
    if (fittingSlots < num){
        rCount := num-fittingSlots
        if (num = 13 && !isPotionSlot){
            rCount += 5
        }
        Loop %rCount% {
            Click, WheelDown
            Sleep, 200
        }
        MouseMove, % scrollCenter, % scrollStartY + slotHeight*(fittingSlots-1) + rCount
    } else {
        MouseMove, % scrollCenter, % scrollStartY + slotHeight*(num-1)
    }

    Sleep, 300
    MouseClick
    Sleep, 200
    MouseGetPos, mouseX,mouseY
    MouseMove, % mouseX + width/4, % mouseY
}

craftingClickAdd(totalSlots,maxes := 0,isGear := 0){
    if (!maxes){
        maxes := []
    }

    getRobloxPos(rX,rY,width,height)

    startXAmt := 0.6*width + rX
    startX := 0.635*width + rX
    startY := 0.413*height + rY
    slotSize := 0.033*height

    if (isGear){
        startXAmt := 0.582*width + rX
        startX := 0.62*width + rX
        startY := 0.395*height + rY
        slotSize := 0.033*height
    }

    slotI := 1
    Loop %totalSlots% {
        clickCount := maxes[slotI]
        MouseMove, % (clickCount == 1) ? startX : startXAmt, % startY + slotSize*(A_Index-1)
        Sleep, 200
        MouseClick, WheelUp
        Sleep, 200
        if (clickCount > 1){
            MouseClick
            Sleep, 200
            clickCount := clickCount ? clickCount : 100
            Send % clickCount
            Sleep, 200
        }
        MouseMove, % startX, % startY + slotSize*(A_Index-1)
        Sleep, 200
        slotI += 1
        MouseClick
        Sleep, 200
    }

    if (isGear){
        MouseMove, % 0.43*width + rX, % 0.635*height + rY
    } else {
        MouseMove, % 0.46*width + rX, % 0.63*height + rY
    }
    Sleep, 250
    MouseClick
}

handleCrafting(){
    getRobloxPos(rX,rY,rW,rH)
    if (options.PotionCraftingEnabled || options.ItemCraftingEnabled){
        updateStatus("Beginning Crafting Cycle")
    }
    if (options.PotionCraftingEnabled){
        align()
        updateStatus("Walking to Stella's Cave (Crafting)")
        walkToPotionCrafting()
        Sleep, 2000
        press("f")
        Sleep, 500
        updateStatus("Crafting Potions")
        Loop 3 {
            v := options["PotionCraftingSlot" A_Index]
            if (v && craftingInfo[potionIndex[v]]){
                info := craftingInfo[potionIndex[v]]
                loopCount := info.attempts
                clickCraftingSlot(info.slot)
                Sleep, 200
                clickCraftingSlot(info.subSlot,1)
                Sleep, 200
                Loop %loopCount% {
                    craftingClickAdd(info.addSlots,info.maxes)
                    Sleep, 200
                }
            }
        }
        MouseMove, % rX + rW*0.175, % rY + rH*0.05
        Sleep, 200
        MouseClick
        Sleep, 500
        resetZoom()
    }
    if (options.ItemCraftingEnabled){
        align()
        updateStatus("Walking to Jake's Shop (Crafting)")
        walkToJakesShop()
        Sleep, 100
        press("f")
        Sleep, 4500
        openP := getPositionFromAspectRatioUV(-0.718,0.689,599/1015)
        openP2 := getPositionFromAspectRatioUV(-0.718,0.689,1135/1015)
        MouseMove, % openP[1], % openP2[2]
        Sleep, 200
        MouseClick
        Sleep, 500
        updateStatus("Crafting Items")
        if (options.CraftingGildedCoin){
            info := craftingInfo["Gilded Coin"]
            loopCount := info.attempts + Floor(info.addedAttempts*options.CraftingInterval)
            clickCraftingSlot(info.slot)
            Sleep, 200
            Loop %loopCount% {
                craftingClickAdd(info.addSlots,info.maxes,1)
                Sleep, 200
            }
        }
        MouseMove, % rX + rW*0.175, % rY + rH*0.05
        Sleep, 200
        MouseClick
        Sleep, 500
        resetZoom()
    }
}

waitForInvVisible(){
    Loop 20 {
        alreadyOpen := checkInvOpen()
        if (alreadyOpen)
            break
        Sleep, 500
    }
}

screenshotInventories(){ ; from all closed
    updateStatus("Inventory screenshots")
    topLeft := getPositionFromAspectRatioUV(-1.3,-0.9,storageAspectRatio)
    bottomRight := getPositionFromAspectRatioUV(1.3,0.75,storageAspectRatio)
    totalSize := [bottomRight[1]-topLeft[1]+1,bottomRight[2]-topLeft[2]+1]

    closeChat()

    clickMenuButton(1)
    Sleep, 200

    waitForInvVisible()

    ssMap := Gdip_BitmapFromScreen(topLeft[1] "|" topLeft[2] "|" totalSize[1] "|" totalSize[2])
    Gdip_SaveBitmapToFile(ssMap,ssPath)
    Gdip_DisposeBitmap(ssMap)
    try webhookPost({files:[ssPath],embedImage:"attachment://ss.jpg",embedTitle: "Aura Storage Screenshot"})

    Sleep, 200
    clickMenuButton(3)
    Sleep, 200

    waitForInvVisible()

    itemButton := getPositionFromAspectRatioUV(0.564405, -0.451327, storageAspectRatio)
    MouseMove, % itemButton[1], % itemButton[2]
    Sleep, 200
    MouseClick
    Sleep, 200

    ssMap := Gdip_BitmapFromScreen(topLeft[1] "|" topLeft[2] "|" totalSize[1] "|" totalSize[2])
    Gdip_SaveBitmapToFile(ssMap,ssPath)
    Gdip_DisposeBitmap(ssMap)
    try webhookPost({files:[ssPath],embedImage:"attachment://ss.jpg",embedTitle: "Item Inventory Screenshot"})

    Sleep, 200
    clickMenuButton(3)
    Sleep, 200
}

checkBottomLeft(){
    getRobloxPos(rX,rY,width,height)

    start := [rX, rY + height*0.86]
    finish := [rX + width*0.14, rY + height]
    totalSize := [finish[1]-start[1]+1, finish[2]-start[2]+1]
    readMap := Gdip_BitmapFromScreen(start[1] "|" start[2] "|" totalSize[1] "|" totalSize[2])
    ;Gdip_ResizeBitmap(readMap,500,500,1)
    readEffect1 := Gdip_CreateEffect(7,100,-100,50)
    readEffect2 := Gdip_CreateEffect(2,10,100)
    Gdip_BitmapApplyEffect(readMap,readEffect1)
    Gdip_BitmapApplyEffect(readMap,readEffect2)
    Gdip_SaveBitmapToFile(readMap,ssPath)
    OutputDebug, % ocrFromBitmap(readMap)
    Gdip_DisposeBitmap(readMap)
    Gdip_DisposeEffect(readEffect1)
}

getUnixTime(){
    now := A_NowUTC
    EnvSub, now,1970, seconds
    return now
}


closeRoblox(){
    WinClose, Roblox
    WinClose, % "Roblox Crash"
}

playBitMap := Gdip_CreateBitmapFromFile(imgDir . "play.png")

isPlayButtonOpen(){
    global playBitMap

    getRobloxPos(pX,pY,width,height)
    
    targetW := height*0.025
    startX := width*0.5 - targetW/2
    retrievedMap := Gdip_BitmapFromScreen(pX + startX "|" pY + height*0.575 "|" targetW "|" height*0.05)
    effect := Gdip_CreateEffect(5,-60,80)
    Gdip_BitmapApplyEffect(retrievedMap,effect)
    playMap := Gdip_ResizeBitmap(retrievedMap,30,30,0)

    blackPixels := 0
    whitePixels := 0

    Loop % 30 {
        tX := A_Index-1
        Loop % 30 {
            tY := A_Index-1
            pixelColor := Gdip_GetPixel(playMap, tX, tY)
            blackPixels += compareColors(pixelColor,0x000000) < 32
            whitePixels += compareColors(pixelColor,0xffffff) < 32
        }
    }

    Gdip_DisposeEffect(effect)
    Gdip_DisposeBitmap(playMap)
    Gdip_DisposeBitmap(retrievedMap)
    
    if (whitePixels > 30 && blackPixels > 30){
        ratio := whitePixels/blackPixels

        return (ratio > 0.35) && (ratio < 0.65)
    }
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
            rHwnd := GetRobloxHWND()
            if (rHwnd){
                WinActivate, ahk_id %rHwnd%
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

            valid := 0
            if (isPlayButtonOpen()){
                Sleep, 2000
                valid := isPlayButtonOpen()
            }
            
            if (valid){
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
        Sleep, 10000
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

checkDisconnect(wasChecked := 0){
    getRobloxPos(windowX, windowY, windowWidth, windowHeight)
	if ((windowWidth > 0) && !WinExist("Roblox Crash")) {
		pBMScreen := Gdip_BitmapFromScreen(windowX+(windowWidth/4) "|" windowY+(windowHeight/2) "|" windowWidth/2 "|1")
        matches := 0
        hW := windowWidth/2
		Loop %hW% {
            matches += (compareColors(Gdip_GetPixelColor(pBMScreen,A_Index-1,0,1),0x393b3d) < 8)
            if (matches >= 128){
                break
            }
        }
        Gdip_DisposeBitmap(pBMScreen)
        if (matches < 128){
            return 0
        }
	}
    if (wasChecked){
        updateStatus("Roblox Disconnected")
        options.Disconnects += 1
        return 1
    } else {
        Sleep, 3000
        return checkDisconnect(1)
    }
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

mainLoop(){
    Global
    if (reconnecting){
        return
    }
    currentId := GetRobloxHWND()
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

    WinActivate, ahk_id %robloxId%
    
    if (!initialized){
        updateStatus("Initializing")
        initialize()
    }

    tMX := width/2
    tMY := height/2

    mouseActions()
    
    Sleep, 250

    if (options.InvScreenshotsEnabled && getUnixTime()-options.LastInvScreenshot >= (options.ScreenshotInterval*60)){
        options.LastInvScreenshot := getUnixTime()

        screenshotInventories()
    }

    Sleep, 250

    if (getUnixTime()-options.LastCraftSession >=  options.CraftingInterval*60){
        options.LastCraftSession := getUnixTime()
        
        handleCrafting()
    }
    
    if (options.DoingObby && (A_TickCount - lastObby) >= (obbyCooldown*1000)){
        align()
        obbyRun()
        hasBuff := checkHasObbyBuff(BRCornerX,BRCornerY,statusEffectHeight)
        Sleep, 1000
        hasBuff := hasBuff || checkHasObbyBuff(BRCornerX,BRCornerY,statusEffectHeight)
        if (!hasBuff){
            Sleep, 5000
            hasBuff := hasBuff || checkHasObbyBuff(BRCornerX,BRCornerY,statusEffectHeight)
        }
        if (!hasBuff)
        {
            align()
            updateStatus("Obby Failed, Retrying")
            lastObby := A_TickCount - obbyCooldown*1000
            obbyRun()
            hasBuff := checkHasObbyBuff(BRCornerX,BRCornerY,statusEffectHeight)
            Sleep, 1000
            hasBuff := hasBuff || checkHasObbyBuff(BRCornerX,BRCornerY,statusEffectHeight)
            if (!hasBuff){
                Sleep, 5000
                hasBuff := hasBuff || checkHasObbyBuff(BRCornerX,BRCornerY,statusEffectHeight)
            }
            if (!hasBuff){
                lastObby := A_TickCount - obbyCooldown*1000
            }
        }
    }

    if (options.CollectItems){
        align(1)
        searchForItems()
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

Gui Add, Tab3, vMainTabs x8 y8 w484 h210 +0x800000, Main|Crafting|Status|Settings|Credits
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

; crafting tab
Gui Tab, 2
Gui Font, s10 w600
Gui Add, GroupBox, x16 y40 w231 h110 vItemCraftingGroup -Theme +0x50000007, Item Crafting
Gui Font, s9 norm
Gui Add, CheckBox, vItemCraftingCheckBox x32 y58 w190 h22 +0x2, % " Automatic Item Crafting"
Gui Font, s9 w600
Gui Add, GroupBox, x21 y80 w221 h65 vItemCraftingOptionsGroup -Theme +0x50000007, Crafting Options
Gui Font, s9 norm
Gui Add, CheckBox, vCraftGildedCoinCheckBox x37 y98 w190 h22 +0x2, % " Gilded Coin"

potionSlotOptions := "None||Fortune Potion I|Haste Potion I|Heavenly Potion I|Universe Potion I|Fortune Potion II|Haste Potion II|Heavenly Potion II|Fortune Potion III"
Gui Font, s10 w600
Gui Add, GroupBox, x252 y40 w231 h170 vPotionCraftingGroup -Theme +0x50000007, Potion Crafting
Gui Font, s9 norm
Gui Add, CheckBox, vPotionCraftingCheckBox x268 y58 w200 h22 +0x2, % " Automatic Potion Crafting"
Gui Font, s9 w600
Gui Add, GroupBox, x257 y80 w221 h125 vPotionCraftingSlotsGroup -Theme +0x50000007, Crafting Slots
Gui Font, s9 norm
Gui Add, Text, x270 y107 w100 h16 vItemCraftingSlot1Header BackgroundTrans, Slot 1:
Gui Add, DropDownList, x312 y103 w120 h10 vPotionCraftingSlot1DropDown R9, % potionSlotOptions
Gui Add, Text, x270 y140 w100 h16 vItemCraftingSlot2Header BackgroundTrans, Slot 2:
Gui Add, DropDownList, x312 y136 w120 h10 vPotionCraftingSlot2DropDown R9, % potionSlotOptions
Gui Add, Text, x270 y173 w100 h16 vItemCraftingSlot3Header BackgroundTrans, Slot 3:
Gui Add, DropDownList, x312 y169 w120 h10 vPotionCraftingSlot3DropDown R9, % potionSlotOptions

Gui Font, s10 w600
Gui Add, GroupBox, x16 y150 w231 h60 vCraftingIntervalGroup -Theme +0x50000007, Crafting Interval
Gui Font, s10 norm
Gui Add, Text, x32 y170 w170 h35 vCraftingIntervalText BackgroundTrans, Craft every              minutes
Gui Font, s9 norm
Gui Add, Edit, x100 y171 w45 h18 vCraftingIntervalInput, 10
Gui Add, UpDown, vCraftingIntervalUpDown Range1-300, 10



; status tab
Gui Tab, 3
Gui Font, s10 w600
Gui Add, GroupBox, x16 y40 w130 h170 vStatsGroup -Theme +0x50000007, Stats
Gui Font, s9 norm
Gui Add, Text, vStatsDisplay x22 y58 w118 h146, runtime: 123`ndisconnects: 1000

Gui Font, s10 w600
Gui Add, GroupBox, x151 y40 w200 h170 vWebhookGroup -Theme +0x50000007, Discord Webhook
Gui Font, s7.5 norm
Gui Add, CheckBox, vWebhookCheckBox x166 y63 w120 h16 +0x2 gEnableWebhookToggle, % " Enable Webhook"
Gui Add, Text, x161 y85 w100 h20 vWebhookInputHeader BackgroundTrans, Webhook URL:
Gui Add, Edit, x166 y103 w169 h18 vWebhookInput,% ""
Gui Add, Button, gWebhookHelpClick vWebhookHelpButton x325 y50 w23 h23, ?
Gui Add, CheckBox, vWebhookImportantOnlyCheckBox x166 y126 w140 h16 +0x2, % " Important events only"
Gui Add, Text, vWebhookUserIDHeader x161 y145 w150 h14 BackgroundTrans, % "Discord User ID (Pings):"
Gui Add, Edit, x166 y162 w169 h16 vWebhookUserIDInput,% ""
Gui Font, s7.4 norm
Gui Add, CheckBox, vWebhookInventoryScreenshots x161 y182 w130 h26 +0x2, % "Inventory Screenshots (mins)"
Gui Add, Edit, x294 y186 w50 h18
Gui Add, UpDown, vInvScreenshotinterval Range1-1440

Gui Font, s10 w600
Gui Add, GroupBox, x356 y40 w128 h50 vStatusOtherGroup -Theme +0x50000007, Other
Gui Font, s9 norm
Gui Add, CheckBox, vStatusBarCheckBox x366 y63 w110 h20 +0x2, % " Enable Status Bar"

Gui Font, s9 w600
Gui Add, GroupBox, x356 y90 w128 h120 vRollDetectionGroup -Theme +0x50000007, Roll Detection
Gui Font, s8 norm
Gui Add, Button, gRollDetectionHelpClick vRollDetectionHelpButton x458 y99 w23 h23, ?
Gui Add, Text, vWebhookRollSendHeader x365 y110 w110 h16 BackgroundTrans, % "Send Minimum:"
Gui Add, Edit, vWebhookRollSendInput x370 y126 w102 h18, 10000
Gui Add, Text, vWebhookRollPingHeader x365 y146 w110 h16 BackgroundTrans, % "Ping Minimum:"
Gui Add, Edit, vWebhookRollPingInput x370 y162 w102 h18, 100000
Gui Add, CheckBox, vWebhookRollImageCheckBox gWebhookRollImageCheckBoxClick x365 y183 w100 h18, Aura Images

; settings tab
Gui Tab, 4
Gui Font, s10 w600
Gui Add, GroupBox, x16 y40 w467 h65 vGeneralSettingsGroup -Theme +0x50000007, General
Gui Font, s9 norm
Gui Add, CheckBox, vVIPCheckBox x32 y58 w150 h22 +0x2, % " VIP Gamepass Owned"
Gui Add, CheckBox, vArcaneCheckBox gArcaneCheckBoxClick x222 y58 w200 h22 +0x2, % " Arcane Teleport Paths"
Gui Add, Text, x222 y82 w200 h18, % "Collection Back Button Y Offset:"
Gui Add, Edit, x396 y81 w50 h18
Gui Add, UpDown, vBackOffsetUpDown Range-500-500, 0
Gui Add, Button, vImportSettingsButton gImportSettingsClick x30 y80 w130 h20, Import Settings

Gui Font, s10 w600
Gui Add, GroupBox, x16 y105 w467 h105 vReconnectSettingsGroup -Theme +0x50000007, Reconnect
Gui Font, s9 norm
Gui Add, CheckBox, vReconnectCheckBox x32 y127 w300 h16 +0x2, % " Enable Reconnect (Will reconnect if you disconnect)"
Gui Add, Text, x26 y148 w100 h20 vPrivateServerInputHeader BackgroundTrans, Private Server Link:
Gui Add, Edit, x31 y167 w437 h20 vPrivateServerInput,% ""


; credits tab
Gui Tab, 5
Gui Font, s10 w600
Gui Add, GroupBox, x16 y40 w231 h133 vCreditsGroup -Theme +0x50000007, The Creator
Gui Add, Picture, w75 h75 x23 y62, % mainDir "images\pfp.png"
Gui Font, s12 w600
Gui Add, Text, x110 y57 w130 h22,BuilderDolphin
Gui Font, s8 norm italic
Gui Add, Text, x120 y78 w80 h18,(dolphin)
Gui Font, s8 norm
Gui Add, Text, x115 y95 w124 h40,"This was supposed to be a short project to learn AHK..."
Gui Font, s8 norm
Gui Add, Text, x28 y145 w200 h32 BackgroundTrans,% "More to come soon perhaps..."
Gui Add, Button, x28 y177 w206 h32 gMoreCreditsClick,% "More Credits"

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
    ,"ArcaneCheckBox":"ArcanePath"
    ,"ObbyBuffCheckBox":"CheckObbyBuff"
    ,"CollectCheckBox":"CollectItems"
    ,"VIPCheckBox":"VIP"
    ,"BackOffsetUpDown":"BackOffset"
    ,"AutoEquipCheckBox":"AutoEquipEnabled"
    ,"CraftingIntervalUpDown":"CraftingInterval"
    ,"ItemCraftingCheckBox":"ItemCraftingEnabled"
    ,"InvScreenshotinterval":"ScreenshotInterval"
    ,"CraftGildedCoinCheckBox":"CraftingGildedCoin"
    ,"PotionCraftingCheckBox":"PotionCraftingEnabled"
    ,"ReconnectCheckBox":"ReconnectEnabled"
    ,"WebhookCheckBox":"WebhookEnabled"
    ,"WebhookInput":"WebhookLink"
    ,"WebhookImportantOnlyCheckBox":"WebhookImportantOnly"
    ,"WebhookRollImageCheckBox":"WebhookAuraRollImages"
    ,"WebhookUserIDInput":"DiscordUserID"
    ,"WebhookInventoryScreenshots":"InvScreenshotsEnabled"
    ,"StatusBarCheckBox":"StatusBarEnabled"}

global directNumValues := {"WebhookRollSendInput":"WebhookRollSendMinimum"
    ,"WebhookRollPingInput":"WebhookRollPingMinimum"}

updateUIOptions(){
    for i,v in directValues {
        GuiControl,,%i%,% options[v]
    }

    for i,v in directNumValues {
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

    Loop 3 {
        v := options["PotionCraftingSlot" . A_Index]
        GuiControl,ChooseString,PotionCraftingSlot%A_Index%DropDown,% potionIndex[v]
    }
}
updateUIOptions()

validateWebhookLink(link){
    return RegexMatch(link, "i)https:\/\/(canary\.|ptb\.)?(discord|discordapp)\.com\/api\/webhooks\/([\d]+)\/([a-z0-9_-]+)") ; filter by natro
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

    for i,v in directNumValues {
        GuiControlGet, rValue,,%i%
        m := 0
        if rValue is number
            m := 1
        options[v] := m ? rValue : 0
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

    Loop 3 {
        GuiControlGet, rValue,,PotionCraftingSlot%A_Index%DropDown
        options["PotionCraftingSlot" . A_Index] := reversePotionIndex[rValue]
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

    importingSettings := 0
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
    ,"Macro Stopped":3447003
    ,"Beginning Crafting Cycle":1752220}

global importantStatuses := {"Starting Macro":1
    ,"Roblox Disconnected":1
    ,"Reconnecting":1
    ,"Reconnecting, Roblox Opened":1
    ,"Reconnecting, Game Loaded":1
    ,"Reconnect Complete":1
    ,"Initializing":1
    ,"Macro Stopped":1}

updateStatus(newStatus){
    if (options.WebhookEnabled){
        FormatTime, fTime, , HH:mm:ss
        if (!options.WebhookImportantOnly || importantStatuses[newStatus]){
            try webhookPost({embedContent: "[" fTime "]: " newStatus,embedColor: (statusColors[newStatus] ? statusColors[newStatus] : 1)})
        }
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
    uv := getAspectRatioUVFromPosition(mouseX,mouseY,storageAspectRatio)
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

    Run, % """" . A_AhkPath . """ """ mainDir . "lib\status.ahk"""

    if (options.StatusBarEnabled){
        Gui statusBar:Show, % "w220 h25 x" (A_ScreenWidth-300) " y50", dolphSol Status
    }
    
    robloxId := GetRobloxHWND()
    if (!robloxId){
        attemptReconnect()
    }

    running := 1
    WinActivate, ahk_id %robloxId%
    while running {
        try mainLoop()
        catch e
            try webhookPost({embedContent: "what: " e.what ", file: " e.file
        . ", line: " e.line ", message: " e.message ", extra: " e.extra,embedTitle: "Error Received",color: 15548997})
        
        Sleep, 2000
    }
}

if (!options.FirstTime){
    options.FirstTime := 1
    saveOptions()
    MsgBox, 0,dolphSol Macro - Welcome, % "Welcome to dolphSol macro!`n`nIf this is your first time here, make sure to go through all of the tabs to make sure your settings are right.`n`nIf you are here from an update, remember that you can import all of your previous settings in the Settings menu.`n`nMake sure join the Discord server and check the GitHub page for the community and future updates, which can both be found in the Credits page. (Discord link is also in the bottom right corner)"
}

if (!options.WasRunning){
    options.WasRunning := 1
    saveOptions()
    
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

WebhookRollImageCheckBoxClick:
    Gui mainUI:Default
    GuiControlGet, v,, WebhookRollImageCheckBox
    if (v){
        MsgBox, 0, Aura Roll Image Warning, % "Warning: Currently, the aura image display for the webhook is fairly unstable, and may cause random delays in webhook sends due to image loading. Enable at your own risk."
    }
    return

ArcaneCheckBoxClick:
    Gui mainUI:Default
    GuiControlGet,v,,ArcaneCheckBox
    if (v){
        MsgBox, 0, Arcane Teleport Notice, % "With the Arcane Teleport option enabled, please ensure that you are auto-equipping any type of Arcane aura at ALL TIMES, otherwise your paths will break.`n`nRemember: It is preferred to select a slot with Arcane in the non-scrolled Aura Storage state (not scrolled down), as reconnecting will reset the scroll upon rejoin, possibly causing you to select a different aura."
    }
    return

MoreCreditsClick:
    creditText =
(
Development

- Assistant Developer - Stanley (stanleyrekt)
- Path Contribution - sanji (sir.moxxi), Flash (drflash55)
- Path Inspiration - Aod_Shanaenae

Supporters (Donations)

- @Bigman
- @sir.moxxi (sanji)
- @zrx
- @dj_frost
- @FlamePrince101 - Member
- @jw
- @Maz - Member
- @dead_is4
- @CorruptExpy_II
- @Ami.n
- @s.a.t.s
- @UnamedWasp - Member
- @JujuFRFX
- @Xon67
- @NightLT98 - Member

Thank you to everyone who currently supports and uses the macro! You guys are amazing!
)
    MsgBox, 0, More Credits, % creditText
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
    MsgBox, 0, Discord Webhook, % "Section for connecting a Discord Webhook to have status messages displayed in a target Discord Channel. Enable this option by entering a valid Discord Webhook link.`n`nTo create a webhook, you must have Administrator permissions in a server (preferably your own, separate server). Go to your target channel, then configure it. Go to Integrations, and create a Webhook in the Webhooks Section. After naming it whatever you like, copy the Webhook URL, then paste it into the macro. Now you can enable the Discord Webhook option!`n`nRequires a valid Webhook URL to enable.`n`nImportant events only - The webhook will only send important events such as disconnects, rolls, and initialization, instead of all of the obby/collecting/crafting ones.`n`nYou can provide your Discord ID here as well to be pinged for rolling a rarity group or higher when detected by the system. You can select the minimum notification/send rarity in the Roll Detection system.`n`nHourly Inventory Screenshots - Screenshots of both your Aura Storage and Item Inventory are sent to your webhook."
    return

RollDetectionHelpClick:
    MsgBox, 0, Roll Detection, % "Section for detecting rolled auras through the registered star color (if 10k+). Any 10k+ auras that can be sent will be sent to the webhook, with the option to ping if the rarity is above the minimum.`n`nFor minimum settings, the number determines the lowest possible rarity the webhook will send/ping for. Values of 0 will disable the option completely. Values under 10,000 will toggle all 1k+ rolls, due to them being near undetectable.`n`nAura Images can be toggled to show the wiki-based images of your rolled auras in the webhook. WARNING: After some testing, this has proven to show some lag, leading to some send delay issues. Use at your own risk!"
    return

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