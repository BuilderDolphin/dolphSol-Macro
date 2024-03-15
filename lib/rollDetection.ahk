#singleinstance, force
#noenv
#persistent
SetWorkingDir, % A_ScriptDir
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

global mainDir
RegExMatch(A_ScriptDir, "(.*)\\", mainDir)

global configPath := mainDir . "settings\config.ini"

global webhookURL := ""
global discordID := ""
global rareMinimum := 0

global rareDisplaying := 0

FileRead, retrieved, %configPath%

if (!ErrorLevel){
    RegExMatch(retrieved, "(?<=WebhookLink=)(.*)", webhookURL)
    RegExMatch(retrieved, "(?<=DiscordUserID=)(.*)", discordID)
    RegExMatch(retrieved, "(?<=WebhookRarePingMinimum=)(.*)", rareMinimum)
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

webhookPost(content := "", title := "", color := "1",pings := 0){
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

    postdata =
    (
    {
    "content": "%pingContent%",
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
    try WebRequest.Send(postdata)  
}

rollDetection(bypass := 0){
    if (rareDisplaying && !bypass) {
        return
    }
    if (WinActive("Roblox") != WinExist("Roblox")){
        return
    }
    getRobloxPos(rX,rY,width,height)

    scanPoints := [[rX,rY],[rX+width-1,rY],[rX,rY+height-1],[rX+width-1,rY+height-1]]
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
            OutputDebug, % A_NowUTC
            Sleep, 9000
            rollDetection(cColor)
        } else {
            try webhookPost("You rolled a 1/1k+","Roll",0,rareMinimum && (rareDisplaying >= rareMinimum))
            Sleep, 5000
            rareDisplaying := 0
        }
    }
    if (!bypass) {
        return
    }
    OutputDebug, % A_NowUTC
    if (whiteCorners >= 4 && rareDisplaying >= 2){
        rareDisplaying := 3
        try webhookPost("You rolled a 1/100k+!!! (Star color: " . bypass . ")","Roll",bypass,rareMinimum && (rareDisplaying >= rareMinimum))
        Sleep, 6000
        rareDisplaying := 0
    } else if (rareDisplaying >= 2){
        try webhookPost("You rolled a 1/10k+! (Star color: " . bypass . ")","Roll",bypass,rareMinimum && (rareDisplaying >= rareMinimum))
        rareDisplaying := 0
    }
}

SetTimer, secondTimer, 1000

return

secondTimer:
rollDetection()