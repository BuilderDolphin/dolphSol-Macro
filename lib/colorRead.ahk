; A testing tool - BuilderDolphin

#singleinstance, force
#noenv
#persistent
SetWorkingDir, %A_ScriptDir%
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

Gui main:New, +AlwaysOnTop

Gui Add, StatusBar, vPosDisplay,Position

Gui Show, w150 h150 x10 y10

update(){
    Gui main:Default
    MouseGetPos, mouseX,mouseY
    PixelGetColor, rColor, %mouseX%, %mouseY%, RGB
    Gui Color, %rColor%
    GuiControl,,PosDisplay,%mouseX%, %mouseY% (%rColor%)
}

shiftMouse(sX,sY){
    MouseGetPos, mouseX,mouseY
    MouseMove, % mouseX + sX, % mouseY + sY, 0
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

mainGuiClose:
ExitApp