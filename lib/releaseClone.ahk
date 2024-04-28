#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

#Include, Gdip_All.ahk

global macroDir
RegExMatch(A_ScriptDir, "(.*)(?=\\)", macroDir)

global targetDir

MsgBox, 4, Warning, Creating/cloning for a release will either create a new directory or modify this macro's files. Proceed?

IfMsgBox, No
    Exit

MsgBox, 3,Make New Directory?,Would you like to make a new directory for release? If not, this directory will be prepared for release.

global inputNewDir
IfMsgBox, Cancel
    Exit
IfMsgBox, No
    targetDir := macroDir
IfMsgBox, Yes
    InputBox, targetDir, New Directory Path, Please enter the new directory path to create the release on.,,,,,,,, % macroDir . "-release"

RegExMatch(targetDir, ".*(?=\\.+\\?)", targetParent)
if (!FileExist(targetParent)){
    MsgBox, ,Error,The parent directory you have entered for the new directory does not exist.`n`nTarget Directory: %targetDir%`nParent Directory: %targetParent%
    Exit
}

if (FileExist(targetDir)){
    MsgBox, 4, Warning, Proceeding will replace any existing files in this directory with their reset versions. Would you like to continue?
    IfMsgBox, No
        Exit
}

FileCopyDir, %macroDir%, %targetDir%, 1
exists := FileExist(targetDir)
if (ErrorLevel){
    MsgBox,, Error, % "An error occurred, please try again."
    Exit
}

token := Gdip_Startup()

empty := Gdip_CreateBitmap(1,1)
Gdip_SaveBitmapToFile(empty,targetDir . "\lib\ss.jpg")
Gdip_DisposeBitmap(empty)

Gdip_Shutdown(token)

configHeader := "; dolphSol Settings`n;   Do not put spaces between equals`n;   Additions may break this file and the macro overall, please be cautious`n;   If you mess up this file, clear it entirely and restart the macro`n`n[Options]`r`n"

FileDelete, % targetDir . "\settings\config.ini"
FileAppend, % configHeader, % targetDir . "\settings\config.ini"

MsgBox, ,Release Process Complete,% "The directory " . targetDir . " is ready for release!"