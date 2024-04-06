#singleinstance, force
#noenv
#persistent
SetWorkingDir, % A_ScriptDir
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

#Include, GDIP_All.ahk

Gdip_Startup()

global mainDir
RegExMatch(A_ScriptDir, "(.*)\\", mainDir)

global configPath := mainDir . "settings\config.ini"
global ssPath := mainDir . "images\ss.png"


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
    this.Ptr := DllCall( "GlobalAlloc", "UInt",0x40, "UInt",1, "Ptr"  )          ; allocate global memory

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
    pvData  := NumGet( ComObjValue( retData ) + 8 + A_PtrSize )
    DllCall( "RtlMoveMemory", "Ptr",pvData, "Ptr",this.Ptr, "Ptr",this.Len )

    this.Ptr := DllCall( "GlobalFree", "Ptr",this.Ptr, "Ptr" )                   ; free global memory 

    retHeader := "multipart/form-data; boundary=----------------------------" . Boundary
	}

  StrPutUTF8( str ) {
    Local ReqSz := StrPut( str, "utf-8" ) - 1
    this.Len += ReqSz                                  ; GMEM_ZEROINIT|GMEM_MOVEABLE = 0x42
    this.Ptr := DllCall( "GlobalReAlloc", "Ptr",this.Ptr, "UInt",this.len + 1, "UInt", 0x42 )   
    StrPut( str, this.Ptr + this.len - ReqSz, ReqSz, "utf-8" )
  }
  
  LoadFromFile( Filename ) {
    Local objFile := FileOpen( FileName, "r" )
    this.Len += objFile.Length                     ; GMEM_ZEROINIT|GMEM_MOVEABLE = 0x42 
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
		Return (n        = 0x474E5089) ? "image/png"
		     : (n        = 0x38464947) ? "image/gif"
		     : (n&0xFFFF = 0x4D42    ) ? "image/bmp"
		     : (n&0xFFFF = 0xD8FF    ) ? "image/jpeg"
		     : (n&0xFFFF = 0x4949    ) ? "image/tiff"
		     : (n&0xFFFF = 0x4D4D    ) ? "image/tiff"
		     : "application/octet-stream"
	}

}

webhookPost(data := 0){
    data := data ? data : {}

    url := webhookURL

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

    if (!data.embedContent || data.noEmbed)
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
        if (lowestCompNum > 32){
            return 0
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
            
            Sleep, 8000
            rollDetection(cColor)
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
        if (auraInfo && sendMinimum && sendMinimum <= auraInfo.rarity){
            webhookPost({embedContent: "# You rolled " auraInfo.name "!\n> ### 1/" commaFormat(auraInfo.rarity) " Chance",embedTitle: "Roll",embedColor: auraInfo.color,embedImage: auraImages ? auraInfo.image : 0,embedFooter: "Detected color " bypass,pings: (pingMinimum && pingMinimum <= auraInfo.rarity)})
        } else if (!auraInfo) {
            webhookPost({embedContent: "Unknown roll color: " bypass,embedTitle: "Roll?",embedColor: bypass})
        }
        Sleep, 6000
        rareDisplaying := 0
    } else if (rareDisplaying >= 2){
        auraInfo := getAuraInfo(bypass,0)
        if ((auraInfo.rarity >= 99999) && (auraInfo.rarity < 10000000)){
            rareDisplaying := 0
            return
        }
        if (auraInfo && sendMinimum && sendMinimum <= auraInfo.rarity){
            webhookPost({embedContent: "# You rolled " auraInfo.name "!\n> ### 1/" commaFormat(auraInfo.rarity) " Chance",embedTitle: "Roll",embedColor: auraInfo.color,embedImage: auraImages ? auraInfo.image : 0,embedFooter: "Detected color " bypass,pings: (pingMinimum && pingMinimum <= auraInfo.rarity)})
        } else if (!auraInfo) {
            webhookPost({embedContent: "Unknown roll color: " bypass,embedTitle: "Roll?",embedColor: bypass})
        }
        rareDisplaying := 0
    }
}

SetTimer, secondTimer, 1000

return

secondTimer:
rollDetection()