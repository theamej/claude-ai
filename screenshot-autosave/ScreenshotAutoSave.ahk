; ScreenshotAutoSave.ahk
;
; Auto-saves a PNG (or JPG) file every time you press Print Screen, in addition
; to the normal clipboard copy Windows already does. Alt+Print Screen works the
; same way for just the active window.
;
; Requirements: AutoHotkey v1 (https://www.autohotkey.com/) and PowerShell
; (already on every modern Windows install).
;
; Setup:
;   1. Install AutoHotkey v1 from autohotkey.com if you don't have it.
;   2. Double-click this file to run it. A tray icon appears while it's active.
;   3. Press Print Screen — a file shows up in the folder set below within a
;      second, and a small notification confirms the path.
;   4. To run it every time you log in: press Win+R, type shell:startup, hit
;      Enter, then drop a shortcut to this .ahk file into that folder.
;
; If Print Screen opens the Snipping/Snip & Sketch overlay instead of saving
; instantly, turn that off first: Settings > Accessibility > Keyboard >
; "Use the Print Screen key to open screen snipping" (set it Off), so Print
; Screen goes back to an instant full-screen clipboard copy this script relies on.

#SingleInstance Force
#Persistent
SetWorkingDir, %A_ScriptDir%

; ---- Settings you can change ----
SaveFolder := A_MyPictures . "\Screenshots"
ImageFormat := "png"   ; "png" or "jpg"
; ----------------------------------

if !FileExist(SaveFolder)
    FileCreateDir, %SaveFolder%

; Write the helper PowerShell script once (it just saves whatever image is on
; the clipboard to the path it's given).
HelperPath := A_Temp . "\ScreenshotAutoSave_SaveClipboard.ps1"
HelperScript =
(
param([string]$Path)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
    $img = [System.Windows.Forms.Clipboard]::GetImage()
    $ext = [System.IO.Path]::GetExtension($Path).ToLower()
    if ($ext -eq ".jpg" -or $ext -eq ".jpeg") {
        $img.Save($Path, [System.Drawing.Imaging.ImageFormat]::Jpeg)
    } else {
        $img.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    Write-Output "OK"
} else {
    Write-Output "NOIMAGE"
}
)
FileDelete, %HelperPath%
FileAppend, %HelperScript%, %HelperPath%

TrayTip, Screenshot Auto-Save, Running. Press Print Screen (or Alt+Print Screen for the active window) to save a screenshot to:`n%SaveFolder%, 4, 1
return

MakeFilePath() {
    global SaveFolder, ImageFormat
    FormatTime, stamp,, yyyy-MM-dd_HH-mm-ss
    return SaveFolder . "\Screenshot_" . stamp . "." . ImageFormat
}

SaveClipboardTo(path) {
    global HelperPath
    RunWait, powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%HelperPath%" "%path%",, Hide
}

; Plain Print Screen: full-screen capture. The leading ~ lets Windows still do
; its normal clipboard copy — this script just persists that image to a file.
~PrintScreen::
    Sleep, 150
    path := MakeFilePath()
    SaveClipboardTo(path)
    if FileExist(path)
        TrayTip, Screenshot saved, %path%, 2, 1
    else
        TrayTip, Screenshot Auto-Save, No image was on the clipboard to save., 2, 2
return

; Alt+Print Screen: active-window capture, same idea.
~!PrintScreen::
    Sleep, 150
    path := MakeFilePath()
    SaveClipboardTo(path)
    if FileExist(path)
        TrayTip, Screenshot saved, %path%, 2, 1
    else
        TrayTip, Screenshot Auto-Save, No image was on the clipboard to save., 2, 2
return
