#singleinstance, force
#noenv
#persistent
SetWorkingDir, % A_ScriptDir
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

global mainDir
RegExMatch(A_ScriptDir, "(.*)\\", mainDir)

global configPath := mainDir . "settings\config.ini"


global webhookEnabled := 0
global webhookURL := ""
global discordID := ""
global sendMinimum := 10000
global pingMinimum := 100000
global auraImages := 0

global rareDisplaying := 0

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

webhookRollPost(content := "", title := "", color := "1", image := "", footer := "",pings := 0){
    url := webhookURL
    formattedTitle := ""
    if (title){
        formattedTitle = 
        (
            "title": "%title%",
        )
    }

    pingContent := ""
    if (pings){
        pingContent := "<@" . discordID . ">"
    }

    formattedImage := ""
    if (image){
        formattedImage =
        (
        "image": {
            "url": "%image%"
        },
        )
    }

    formattedFooter := ""
    if (footer){
        formattedFooter =
        (
            "footer":{
                "text":"Detected Color ID: %footer%"
            },
        )
    }

    postdata =
    (
    {
    "content": "%pingContent%",
    "embeds": [
        {
        %formattedTitle%
        "description": "%content%",
        %formattedImage%
        %formattedFooter%
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

getAuraInfo(starColor := 0, is100k := 0){
    tName := staticData["name" starColor]
    if (tName){
        tImage := ""
        tRarity := 0
        if (staticData["nameMutation100k" starColor] && is100k){
            tName := staticData["nameMutation100k" starColor]
            tImage := staticData["imageMutation100k" starColor]
            tRarity := staticData["rarityMutation100k" starColor]
        } else if (staticData["nameMutation10m" starColor] && !is100k){
            tName := staticData["nameMutation10m" starColor]
            tImage := staticData["imageMutation10m" starColor]
            tRarity := staticData["rarityMutation10m" starColor]
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
        return getAuraInfo(targetColor,is100k)
    }
}

rollDetection(bypass := 0){
    if (rareDisplaying && !bypass) {
        return
    }
    if (WinActive("Roblox") != WinExist("Roblox")){
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
            Sleep, 500
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
            
            Sleep, 8750
            rollDetection(cColor)
        } else {
            if (sendMinimum && sendMinimum < 10000) {
                webhookRollPost("You rolled a 1/1k+","Roll",0,,,pingMinimum && pingMinimum < 10000)
            }
            Sleep, 5000
            rareDisplaying := 0
        }
    }
    if (!bypass) {
        return
    }
    if (whiteCorners >= 3 && rareDisplaying >= 2){
        rareDisplaying := 3
        auraInfo := getAuraInfo(bypass,1)
        if (sendMinimum && sendMinimum <= auraInfo.rarity){
            webhookRollPost("# You rolled " auraInfo.name "!\n> ### 1/" commaFormat(auraInfo.rarity) " Chance","Roll",auraInfo.color,auraImages ? auraInfo.image : 0,bypass,pingMinimum && pingMinimum <= auraInfo.rarity)
        }
        Sleep, 6000
        rareDisplaying := 0
    } else if (rareDisplaying >= 2){
        auraInfo := getAuraInfo(bypass,0)
        if ((auraInfo.rarity >= 99999) && (auraInfo.rarity < 10000000)){
            rareDisplaying := 0
            return
        }
        if (sendMinimum && sendMinimum <= auraInfo.rarity){
            webhookRollPost("# You rolled " auraInfo.name "!\n> ### 1/" commaFormat(auraInfo.rarity) " Chance","Roll",auraInfo.color,auraImages ? auraInfo.image : 0,bypass,pingMinimum && pingMinimum <= auraInfo.rarity)
        }
        rareDisplaying := 0
    }
}

SetTimer, secondTimer, 1000

return

secondTimer:
rollDetection()