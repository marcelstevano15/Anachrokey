#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
#Include Gdip_All.ahk

; ============================================================
; Auto-execute section - runs once when the script loads.
; Must stay ABOVE the first hotkey (::) - AHK stops running
; top-level code sequentially once it hits one.
; ============================================================
global ClipHistory := []
global PeekList := []
global PeekActive := false
OnClipboardChange(Func("ClipHistory_Update"))

Menu, QuickLinkMenu, Add, Control Panel, QL_ControlPanel
Menu, QuickLinkMenu, Add, Device Manager, QL_DeviceManager
Menu, QuickLinkMenu, Add, Task Manager, QL_TaskManager
Menu, QuickLinkMenu, Add, Command Prompt, QL_CmdPrompt
Menu, QuickLinkMenu, Add, My Computer, QL_MyComputer
Menu, QuickLinkMenu, Add, Windows Explorer, QL_Explorer
Menu, QuickLinkMenu, Add, Network Connections, QL_NetConnections
Menu, QuickLinkMenu, Add, System Properties, QL_SystemProps
Menu, QuickLinkMenu, Add, Disk Management, QL_DiskMgmt
Menu, QuickLinkMenu, Add, Services, QL_Services
Menu, QuickLinkMenu, Add, Event Viewer, QL_EventViewer
Menu, QuickLinkMenu, Add, Registry Editor, QL_Regedit
Menu, QuickLinkMenu, Add, System Configuration (msconfig), QL_MsConfig
Menu, QuickLinkMenu, Add, Add or Remove Programs, QL_AddRemove
Menu, QuickLinkMenu, Add, Search, QL_Search
Menu, QuickLinkMenu, Add, Run..., QL_Run
return
; ============================================================

; Ctrl+Shift+N - New Folder (XP Classic Explorer via File menu; Desktop via direct create+rename)
^+n::
    WinGetClass, cls, A
    if (cls = "Progman" or cls = "WorkerW") {
        ; Desktop: AppsKey only opens a context menu for a selected icon (does nothing
        ; if none is selected), so simulate the New Folder behavior directly instead.
        baseName := "New Folder"
        folderName := baseName
        n := 2
        while FileExist(A_Desktop "\" folderName)
        {
            folderName := baseName " (" n ")"
            n++
        }
        FileCreateDir, %A_Desktop%\%folderName%
        Sleep, 300
        Send, {F5}          ; refresh desktop so the new icon appears
        Sleep, 300
        SendRaw, %folderName%  ; type-to-select the matching icon in the ListView
        Sleep, 150
        Send, {F2}          ; enter rename mode, ready for the user to type a new name
    } else {
        Send !f
        Sleep, 100
        Send w
        Sleep, 100
        Send f
    }
return

; Win+Up - Maximize window
#Up::
    id := WinExist("A")
    WinGet, style, Style, ahk_id %id%
    if !(style & 0x40000)  ; skip fixed-size dialogs (Run, Winver, msgbox, etc)
        return
    WinGet, state, MinMax, ahk_id %id%
    if (state != 1)
        WinMaximize, ahk_id %id%
return

; Win+Down - Restore if maximized, Minimize if restored
#Down::
    id := WinExist("A")
    WinGet, style, Style, ahk_id %id%
    if !(style & 0x40000)  ; skip fixed-size dialogs (Run, Winver, msgbox, etc)
        return
    WinGet, state, MinMax, ahk_id %id%
    if (state = 1)
        WinRestore, ahk_id %id%
    else if (state = 0)
        WinMinimize, ahk_id %id%
return

; Win+Left / Win+Right - Snap window to left/right half of screen (toggle back to original position)
#Left::
    id := WinExist("A")
    WinGet, style, Style, ahk_id %id%
    if !(style & 0x40000)  ; skip fixed-size dialogs (Run, Winver, msgbox, etc)
        return
    if (SnapState_%id% = "left") {
        ; already left, do nothing
    } else if (SnapState_%id% = "right") {
        WinMove, ahk_id %id%,, OrigX_%id%, OrigY_%id%, OrigW_%id%, OrigH_%id%
        SnapState_%id% := ""
    } else {
        WinGetPos, OrigX_%id%, OrigY_%id%, OrigW_%id%, OrigH_%id%, ahk_id %id%
        SysGet, mon, MonitorWorkArea
        WinMove, ahk_id %id%,, monLeft, monTop, (monRight-monLeft)/2, monBottom-monTop
        SnapState_%id% := "left"
    }
return

#Right::
    id := WinExist("A")
    WinGet, style, Style, ahk_id %id%
    if !(style & 0x40000)  ; skip fixed-size dialogs (Run, Winver, msgbox, etc)
        return
    if (SnapState_%id% = "right") {
        ; already right, do nothing
    } else if (SnapState_%id% = "left") {
        WinMove, ahk_id %id%,, OrigX_%id%, OrigY_%id%, OrigW_%id%, OrigH_%id%
        SnapState_%id% := ""
    } else {
        WinGetPos, OrigX_%id%, OrigY_%id%, OrigW_%id%, OrigH_%id%, ahk_id %id%
        SysGet, mon, MonitorWorkArea
        halfW := (monRight-monLeft)/2
        WinMove, ahk_id %id%,, monLeft + halfW, monTop, halfW, monBottom-monTop
        SnapState_%id% := "right"
    }
return

; Win+Home - Minimize all windows EXCEPT the active one (XP only has Win+M = minimize all)
#Home::
    hWndActive := WinExist("A")
    WinGet, id, List
    Loop, %id%
    {
        this_id := id%A_Index%
        if (this_id != hWndActive) {
            WinGetTitle, t, ahk_id %this_id%
            if (t != "")
                WinMinimize, ahk_id %this_id%
        }
    }
return

; Win+B - Focus system tray (7+), not present in XP
#b::
    ControlFocus,, ahk_class TrayNotifyWnd
return

; Win+PrintScreen - Screenshot, auto-save to Pictures\Screenshots (creates folder if missing)
#PrintScreen::
    shotDir := GetScreenshotDir()
    FormatTime, ts,, yyyy-MM-dd HH.mm.ss
    outFile := shotDir "\Screenshot " ts ".png"

    pToken := Gdip_Startup()
    screen := "0|0|" A_ScreenWidth "|" A_ScreenHeight
    pBitmap := Gdip_BitmapFromScreen(screen)
    Gdip_SaveBitmapToFile(pBitmap, outFile)
    Gdip_DisposeImage(pBitmap)
    Gdip_Shutdown(pToken)
return

; Win+Shift+S - Region screenshot (drag-select an area, auto-saved to Pictures\Screenshots)
#+s::
    shotDir := GetScreenshotDir()
    CoordMode, Mouse, Screen

    ; Dark dimmed overlay across the whole screen (classic Snipping Tool look)
    Gui, DimOverlay:-Caption +AlwaysOnTop +ToolWindow +E0x20
    Gui, DimOverlay:Color, 000000
    Gui, DimOverlay:Show, x0 y0 w%A_ScreenWidth% h%A_ScreenHeight%, DimOverlay
    WinSet, Transparent, 130, DimOverlay

    ; Wait for the drag to start (or Escape to cancel)
    Loop {
        if GetKeyState("LButton", "P")
            break
        if GetKeyState("Escape", "P") {
            Gui, DimOverlay:Destroy
            return
        }
        Sleep, 10
    }
    MouseGetPos, startX, startY

    ; Lightened selection window sitting on top of the dim overlay - the area
    ; under the drag looks "cut out" / brighter than the dimmed surroundings
    Gui, SelRect:-Caption +AlwaysOnTop +ToolWindow +E0x08
    Gui, SelRect:Color, FFFFFF
    Gui, SelRect:Show, x%startX% y%startY% w1 h1, SelRect
    WinSet, Transparent, 90, SelRect

    Loop {
        if !GetKeyState("LButton", "P")
            break
        MouseGetPos, curX, curY
        x1 := (startX < curX) ? startX : curX
        y1 := (startY < curY) ? startY : curY
        w  := Abs(curX - startX)
        h  := Abs(curY - startY)
        WinMove, SelRect,, %x1%, %y1%, %w%, %h%
        if GetKeyState("Escape", "P") {
            Gui, SelRect:Destroy
            Gui, DimOverlay:Destroy
            return
        }
        Sleep, 15
    }
    MouseGetPos, endX, endY
    Gui, SelRect:Destroy
    Gui, DimOverlay:Destroy
    Sleep, 50  ; let the screen redraw fully before capturing (so overlays aren't in the shot)

    x1 := (startX < endX) ? startX : endX
    y1 := (startY < endY) ? startY : endY
    w  := Abs(endX - startX)
    h  := Abs(endY - startY)
    if (w < 3 or h < 3)
        return  ; selection too small, treat as cancelled

    FormatTime, ts,, yyyy-MM-dd HH.mm.ss
    outFile := shotDir "\Snip " ts ".png"

    pToken := Gdip_Startup()
    region := x1 "|" y1 "|" w "|" h
    pBitmap := Gdip_BitmapFromScreen(region)
    Gdip_SaveBitmapToFile(pBitmap, outFile)
    Gdip_DisposeImage(pBitmap)
    Gdip_Shutdown(pToken)
return

GetScreenshotDir() {
    VarSetCapacity(picPath, 520, 0)
    DllCall("shell32\SHGetFolderPathW", "UInt", 0, "Int", 0x27, "UInt", 0, "Int", 0, "UInt", &picPath) ; CSIDL_MYPICTURES
    picDir := StrGet(&picPath, "UTF-16")
    shotDir := picDir "\Screenshots"
    IfNotExist, %shotDir%
        FileCreateDir, %shotDir%
    return shotDir
}

; ============================================================
; Win+X - Quick Link menu (admin shortcuts, like Win8+)
; ============================================================
#x::
    Menu, QuickLinkMenu, Show
return

QL_ControlPanel:
    Run, control.exe
return
QL_DeviceManager:
    Run, devmgmt.msc
return
QL_TaskManager:
    Run, taskmgr.exe
return
QL_CmdPrompt:
    Run, cmd.exe
return
QL_MyComputer:
    Run, explorer.exe /e,::{20D04FE0-3AEA-1069-A2D8-08002B30309D}
return
QL_NetConnections:
    Run, control.exe ncpa.cpl
return
QL_SystemProps:
    Run, control.exe sysdm.cpl
return
QL_Run:
    Send, #r
return
QL_Explorer:
    Run, explorer.exe
return
QL_DiskMgmt:
    Run, diskmgmt.msc
return
QL_Services:
    Run, services.msc
return
QL_EventViewer:
    Run, eventvwr.msc
return
QL_Regedit:
    Run, regedit.exe
return
QL_MsConfig:
    Run, msconfig.exe
return
QL_AddRemove:
    Run, control.exe appwiz.cpl
return
QL_Search:
    Run, explorer.exe ::{E17D4FC0-5564-11D1-83F2-00A0C90DC849}
return

; ============================================================
; Win+V - Clipboard history (keeps the last 10 text clips)
; ============================================================
ClipHistory_Update(type) {
    global ClipHistory
    if (type != 1)  ; only track text, not images/files
        return
    text := Clipboard
    if (text = "")
        return
    ; avoid duplicate consecutive entries
    if (ClipHistory.Length() > 0 && ClipHistory[1] = text)
        return
    ClipHistory.InsertAt(1, text)
    if (ClipHistory.Length() > 10)
        ClipHistory.Pop()
}

#v::
    Gui, ClipGui:Destroy
    Gui, ClipGui:+AlwaysOnTop +ToolWindow
    itemsList := ""
    loop, % ClipHistory.Length() {
        preview := SubStr(ClipHistory[A_Index], 1, 80)
        StringReplace, preview, preview, |, /, All  ; pipe is the ListBox item separator, so strip it
        itemsList .= (itemsList = "" ? "" : "|") preview
    }
    Gui, ClipGui:Add, ListBox, x0 y0 w400 h200 vClipSelection gClipGui_Select, %itemsList%
    Gui, ClipGui:Show,, Clipboard History
return

ClipGui_Select:
    if (A_GuiEvent = "DoubleClick") {
        GuiControlGet, sel,, ClipSelection
        idx := 0
        loop, % ClipHistory.Length() {
            preview := SubStr(ClipHistory[A_Index], 1, 80)
            if (preview = sel) {
                idx := A_Index
                break
            }
        }
        if (idx > 0) {
            Clipboard := ClipHistory[idx]
            Gui, ClipGui:Destroy
        }
    }
return

GuiClose:
    Gui, Destroy
return

; ============================================================
; Win+, - Peek Desktop (toggle: minimize all / restore all)
; ============================================================
#,::
    if (PeekActive) {
        loop, % PeekList.Length()
            WinRestore, % "ahk_id " PeekList[A_Index]
        PeekList := []
        PeekActive := false
    } else {
        PeekList := []
        WinGet, idList, List
        Loop, %idList%
        {
            this_id := idList%A_Index%
            WinGetTitle, t, ahk_id %this_id%
            WinGet, mmState, MinMax, ahk_id %this_id%
            if (t != "" && mmState != -1) {
                PeekList.Push(this_id)
                WinMinimize, ahk_id %this_id%
            }
        }
        PeekActive := true
    }
return

; ============================================================
; Win+Shift+Left / Win+Shift+Right - Move window to other monitor
; (only does anything if more than one monitor is connected)
; ============================================================
#+Left::
    MoveToMonitor(-1)
return

#+Right::
    MoveToMonitor(1)
return

MoveToMonitor(direction) {
    SysGet, monCount, MonitorCount
    if (monCount < 2)
        return  ; single monitor - nothing to do
    id := WinExist("A")
    WinGetPos, wx, wy, ww, wh, ahk_id %id%
    curMon := 1
    Loop, %monCount% {
        SysGet, m, Monitor, %A_Index%
        if (wx >= mLeft && wx < mRight) {
            curMon := A_Index
            break
        }
    }
    newMon := curMon + direction
    if (newMon < 1)
        newMon := monCount
    if (newMon > monCount)
        newMon := 1
    SysGet, cur, MonitorWorkArea, %curMon%
    SysGet, targ, MonitorWorkArea, %newMon%
    offsetX := wx - curLeft
    offsetY := wy - curTop
    WinMove, ahk_id %id%,, targLeft + offsetX, targTop + offsetY
}

