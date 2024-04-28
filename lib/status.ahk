#singleinstance, force
#noenv
#persistent
SetWorkingDir, % A_ScriptDir
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

#Include, GDIP_All.ahk
#Include, ocr.ahk

Gdip_Startup()

global mainDir
RegExMatch(A_ScriptDir, "(.*)\\", mainDir)

global configPath := mainDir . "settings\config.ini"
global ssPath := "ss.jpg"
global imageDir := mainDir . "images\"


global webhookEnabled := 0
global webhookURL := ""
global discordID := ""
global sendMinimum := 10000
global pingMinimum := 100000
global auraImages := 0

global rareDisplaying := 0

global currentBiome := "Normal"
global currentBiomeTimer := 0
global currentBiomeDisplayed := 0

global biomeData := {"Normal":{color: 0xdddddd}
    ,"Windy":{color: 0x9ae5ff, duration: 120}
    ,"Rainy":{color: 0x027cbd, duration: 120}
    ,"Snowy":{color: 0xDceff9, duration: 120}
    ,"Starfall":{color: 0x011ab7, duration: 600, display: 1}
    ,"Null":{color: 0x838383, duration: 90, display: 1}
    ,"Glitched":{color: 0xbfff00, duration: 164, display: 1}}

FileRead, retrieved, %configPath%

if (!ErrorLevel){
    RegExMatch(retrieved, "(?<=WebhookEnabled=)(.*)", webhookEnabled)
    RegExMatch(retrieved, "(?<=WebhookLink=)(.*)", webhookURL)
    if (!webhookEnabled || !webhookURL){
        ExitApp
    }
    RegExMatch(retrieved, "(?<=DiscordUserID=)(.*)", discordID)
    RegExMatch(retrieved, "(?<=WebhookRollSendMinimum=)(.*)", sendMinimum)
    RegExMatch(retrieved, "(?<=WebhookRollPingMinimum=)(.*)", pingMinimum)
    RegExMatch(retrieved, "(?<=WebhookAuraRollImages=)(.*)", auraImages)
} else {
    MsgBox, An error occurred while reading %configPath% data, rarity webhook messages will not be sent.
    return
}

getUnixTime(){
    now := A_NowUTC
    EnvSub, now,1970, seconds
    return now
}

isFullscreen() {
	WinGetPos,,, w, h, Roblox
	return (w = A_ScreenWidth && h = A_ScreenHeight)
}

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

getUV(x,y,oX,oY,width,height){
    return [((x-oX)*2 - width)/height,((y-oY)*2 - height)/height]
}
getFromUV(uX,uY,oX,oY,width,height){
    return [Floor((uX*height + width)/2)+oX,Floor((uY*height + height)/2)+oY]
}

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

commaFormat(num){
    len := StrLen(num)
    final := ""
    Loop %len% {
        char := (len-A_Index)+1
        if (Mod(A_Index-1,3) = 0 && A_Index <= len && A_Index-1){
            final := "," . final
        }
        final := SubStr(num, char, 1) . final
    }
    return final
}

global staticData := getINIData("staticData.ini")

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

    url := webhookURL

    if (!url){
        ExitApp
    }

    if (data.pings){
        data.content := data.content ? data.content " <@" discordID ">" : "<@" discordID ">"
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

global similarCharacters := {"1":"l"
    ,"n":"m"
    ,"m":"n"
    ,"t":"f"
    ,"f":"t"
    ,"s":"S"
    ,"S":"s"
    ,"w":"W"
    ,"W":"w"}

identifyBiome(inputStr){
    if (!inputStr)
        return 0
    
    internalStr := RegExReplace(inputStr,"\s")
    internalStr := RegExReplace(internalStr,"^([\[\(\{\|IJ]+)")
    internalStr := RegExReplace(internalStr,"([\]\)\}\|IJ]+)$")

    highestRatio := 0
    matchingBiome := ""

    for v,_ in biomeData {
        if (v = "Glitched"){
            continue
        }
        scanIndex := 1
        accuracy := 0
        Loop % StrLen(v) {
            checkingChar := SubStr(v,A_Index,1)
            Loop % StrLen(internalStr) - scanIndex + 1 {
                index := scanIndex + A_Index - 1
                targetChar := SubStr(internalStr, index, 1)
                if (targetChar = checkingChar){
                    accuracy += 3 - A_Index
                    scanIndex := index+1
                    break
                } else if (similarCharacters[targetChar] = checkingChar){
                    accuracy += 2.5 - A_Index
                    scanIndex := index+1
                    break
                }
            }
        }
        ratio := accuracy/(StrLen(v)*2)
        if (ratio > highestRatio){
            matchingBiome := v
            highestRatio := ratio
        }
    }

    if (highestRatio < 0.70){
        matchingBiome := 0
        glitchedCheck := StrLen(internalStr)-StrLen(RegExReplace(internalStr,"\d")) + (RegExMatch(internalStr,"\.") ? 4 : 0)
        if (glitchedCheck >= 20){
            OutputDebug, % "glitched biome pro!"
            matchingBiome := "Glitched"
        }
    }


    return matchingBiome
}

determineBiome(){
    if (!WinActive("ahk_id " GetRobloxHWND()) && !WinActive("Roblox")){
        return
    }
    getRobloxPos(rX,rY,width,height)
    pBM := Gdip_BitmapFromScreen(rX "|" rY + height - height*0.102 + ((height/600) - 1)*10 "|" width*0.15 "|" height*0.03)

    effect := Gdip_CreateEffect(3,"2|0|0|0|0" . "|" . "0|1.5|0|0|0" . "|" . "0|0|1|0|0" . "|" . "0|0|0|1|0" . "|" . "0|0|0.2|0|1",0)
    effect2 := Gdip_CreateEffect(5,-100,250)
    effect3 := Gdip_CreateEffect(2,10,50)
    Gdip_BitmapApplyEffect(pBM,effect)
    Gdip_BitmapApplyEffect(pBM,effect2)
    Gdip_BitmapApplyEffect(pBM,effect3)

    identifiedBiome := 0
    Loop 10 {
        st := A_TickCount
        newSizedPBM := Gdip_ResizeBitmap(pBM,300+(A_Index*38),70+(A_Index*7.5),1,2)

        ocrResult := ocrFromBitmap(newSizedPBM)
        identifiedBiome := identifyBiome(ocrResult)

        Gdip_DisposeBitmap(newSizedPBM)

        if (identifiedBiome){
            break
        }
    }

    Gdip_DisposeEffect(effect)
    Gdip_DisposeEffect(effect2)
    Gdip_DisposeEffect(effect3)
    Gdip_DisposeBitmap(retrievedMap)
    Gdip_DisposeBitmap(pBM)

    DllCall("psapi.dll\EmptyWorkingSet", "ptr", -1)

    return identifiedBiome
}

getAuraInfo(starColor := 0, is100k := 0, is1m := 0){
    tName := staticData["name" starColor]
    if (tName){
        tImage := ""
        tRarity := 0
        if (staticData["nameMutation100k" starColor] && is100k){
            tName := staticData["nameMutation100k" starColor]
            tImage := staticData["imageMutation100k" starColor]
            tRarity := staticData["rarityMutation100k" starColor]
        } else if (staticData["nameMutation1m" starColor] && is1m && !is100k){
            tName := staticData["nameMutation1m" starColor]
            tImage := staticData["imageMutation1m" starColor]
            tRarity := staticData["rarityMutation1m" starColor]
        } else {
            tImage := staticData["image" starColor]
            tRarity := staticData["rarity" starColor]
        }
        return {name:tName,image:tImage,rarity:tRarity,color:starColor}
    } else {
        lowestCompNum := 0xffffff * 3
        targetColor := 0
        for i,v in staticData {
            RegExMatch(i, "(?<=name)(\d+)",targetId)
            if (targetId){
                comp := compareColors(starColor,targetId)
                if (comp < lowestCompNum){
                    lowestCompNum := comp
                    targetColor := targetId
                }
            }
        }
        if (lowestCompNum > 32){
            return 0
        }
        return getAuraInfo(targetColor,is100k,is1m)
    }
}

handleRollPost(bypass,auraInfo,starMap){
    Gdip_SaveBitmapToFile(starMap,ssPath)
    Gdip_DisposeBitmap(starMap)
    if (auraInfo && sendMinimum && sendMinimum <= auraInfo.rarity){
        webhookPost({embedContent: "# You rolled " auraInfo.name "!\n> ### 1/" commaFormat(auraInfo.rarity) " Chance",embedTitle: "Roll",embedColor: auraInfo.color,embedImage: auraImages ? auraInfo.image : 0,embedFooter: "Detected color " bypass,pings: (pingMinimum && pingMinimum <= auraInfo.rarity),files:[ssPath],embedThumbnail:"attachment://ss.jpg"})
    } else if (!auraInfo) {
        webhookPost({embedContent: "Unknown roll color: " bypass,embedTitle: "Roll?",embedColor: bypass,files:[ssPath],embedThumbnail:"attachment://ss.jpg"})
    }
}

rollDetection(bypass := 0,is1m := 0,starMap := 0){
    if (rareDisplaying && !bypass) {
        return
    }
    if (!GetRobloxHWND()){
        rareDisplaying := 0
        return
    }
    getRobloxPos(rX,rY,width,height)

    scanPoints := [[rX+1,rY+1],[rX+width-2,rY+1],[rX+1,rY+height-2],[rX+width-2,rY+height-2]]
    blackCorners := 0
    whiteCorners := 0
    for i,point in scanPoints {
        PixelGetColor, pColor, % point[1], % point[2], RGB
        blackCorners += compareColors(pColor,0x000000) < 8
        whiteCorners += compareColors(pColor,0xFFFFFF) < 8
    }
    PixelGetColor, cColor, % rX + width*0.5, % rY + height*0.5, RGB
    centerColored := cColor > 16

    if (blackCorners >= 4 && !bypass){
        rareDisplaying := 1
        if (centerColored){
            rareDisplaying := 2
            Sleep, 750
            blackCorners := 0
            for i,point in scanPoints {
                PixelGetColor, pColor, % point[1], % point[2], RGB
                blackCorners += compareColors(pColor,0x000000) < 8
            }
            PixelGetColor, cColor, % rX + width*0.5, % rY + height*0.5, RGB
            if (blackCorners < 4 || cColor <= 16){
                ; false detect
                rareDisplaying := 0
                return
            }

            topLeft := getFromUV(-0.2,-0.2,rX,rY,width,height)
            bottomRight := getFromUV(0.2,0.2,rX,rY,width,height)
            squareScale := [bottomRight[1]-topLeft[1]+1,bottomRight[2]-topLeft[2]+1]

            starMap := Gdip_BitmapFromScreen(topLeft[1] "|" topLeft[2] "|" squareScale[1] "|" squareScale[2])

            tData1mCheck := getAuraInfo(cColor,0,1)
            if (tData1mCheck && tData1mCheck.rarity < 1000000){
                tData1mCheck := 0
            }
            if (tData1mCheck){
                start := A_TickCount

                totalPixels := 32*32
                
                starCheckMap := Gdip_ResizeBitmap(starMap,32,32,0)

                effect := Gdip_CreateEffect(5,-30,60)
                Gdip_BitmapApplyEffect(starCheckMap,effect)

                starPixels := 0
                Loop, % 50 {
                    x := A_Index - 1
                    Loop, % 50 {
                        y := A_Index - 1

                        pixelColor := Gdip_GetPixel(starCheckMap, x, y)

                        if (compareColors(pixelColor,0x000000) > 32) {
                            starPixels += 1
                        }
                    }
                }

                is1m := starPixels/totalPixels >= 0.13

                Gdip_DisposeEffect(effect)
                Gdip_DisposeBitmap(starCheckMap)
                Gdip_DisposeBitmap(retrievedMap)
            }
            
            Sleep, 8000
            rollDetection(cColor,is1m,starMap)
        } else {
            if (sendMinimum && sendMinimum < 10000) {
                webhookPost({embedContent:"You rolled a 1/1k+",embedTitle:"Roll",pings: (pingMinimum && pingMinimum < 10000)})
            }
            Sleep, 5000
            rareDisplaying := 0
        }
    }
    if (!bypass) {
        return
    }

    is100k := whiteCorners >= 3
    if (!is100k){
        Loop 4 {
            Sleep, 500
            whiteCorners := 0
            for i,point in scanPoints {
                PixelGetColor, pColor, % point[1], % point[2], RGB
                whiteCorners += compareColors(pColor,0xFFFFFF) < 8
            }
            is100k := whiteCorners >= 3
            if (is100k){
                break
            }
        }
    }

    if (is100k && rareDisplaying >= 2){
        rareDisplaying := 3
        auraInfo := getAuraInfo(bypass,1)
        handleRollPost(bypass,auraInfo,starMap)
        Sleep, 6000
        rareDisplaying := 0
    } else if (rareDisplaying >= 2){
        auraInfo := getAuraInfo(bypass,0,is1m)
        if ((auraInfo.rarity >= 99999) && (auraInfo.rarity < 1000000)){
            rareDisplaying := 0
            return
        }
        handleRollPost(bypass,auraInfo,starMap)
        rareDisplaying := 0
    }
}

secondTick(){
    biomeFinished := 0
    if (currentBiomeTimer - getUnixTime() < 1 && currentBiome != "Normal"){
        biomeFinished := 1
    }
    rollDetection()

    if ((!rareDisplaying && currentBiome = "Normal") || biomeFinished){
        FormatTime, fTime, , HH:mm:ss
        if (biomeFinished && currentBiomeDisplayed){
            currentBiomeDisplayed := 0
            webhookPost({embedContent: "[" fTime "]: Rare Biome Ended - " currentBiome})
            currentBiome := "Normal"
        }

        detectedBiome := determineBiome()

        if (detectedBiome){
            currentBiome := detectedBiome
            targetData := biomeData[currentBiome]
            if (currentBiome != "Normal" && targetData){
                if (targetData.display){
                    currentBiomeDisplayed := 1

                    webhookPost({embedContent: "[" fTime "]: Rare Biome Started - " currentBiome,embedColor: targetData.color})
                }

                currentBiomeTimer := getUnixTime() + targetData.duration
            }
        }
    }
}

SetTimer, secondTimer, 1000

return

secondTimer:
secondTick()