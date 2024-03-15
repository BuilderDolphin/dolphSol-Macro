; A testing tool - BuilderDolphin

#singleinstance, force
#noenv
#persistent
SetWorkingDir, %A_ScriptDir%
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

Gui main:New, +AlwaysOnTop

Gui Add, StatusBar, vPosDisplay,Position

Gui Show, w250 h150 x10 y10

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

global currentText := ""

update(){
    Gui main:Default
    MouseGetPos, mouseX,mouseY
    PixelGetColor, rColor, %mouseX%, %mouseY%, RGB
    Gui Color, %rColor%
    getRobloxPos(rX,rY,rW,rH)
    currentText := mouseX ", " mouseY " (" rColor ") | " rW " x " rH " (" rX ", " rY ")"
    GuiControl,,PosDisplay, % currentText
}

shiftMouse(sX,sY){
    MouseGetPos, mouseX,mouseY
    MouseMove, % mouseX + sX, % mouseY + sY, 0
}

global scanning := 0
global scanStart := [0,0]
handleScan(){
    MouseGetPos, mouseX,mouseY
    if (scanning){
        sX := mouseX - scanStart[1] + 1
        sY := mouseY - scanStart[2] + 1
        MsgBox, 4096,Size,% sX " x " sY
    } else {
        scanStart := [mouseX,mouseY]
    }
    scanning := !scanning
}

SetTimer, FrameTick, 50

return

FrameTick:
update()

f4::ExitApp

Numpad2::shiftMouse(0,1)
Numpad4::shiftMouse(-1,0)
Numpad6::shiftMouse(1,0)
Numpad8::shiftMouse(0,-1)

Numpad0::OutputDebug, % currentText
NumpadDot::OutputDebug, % "-"
NumpadAdd::handleScan()

mainGuiClose:
ExitApp