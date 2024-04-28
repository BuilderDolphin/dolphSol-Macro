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