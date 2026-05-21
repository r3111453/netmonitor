#Warn
#NoEnv
#SingleInstance, Force

; ==================================================
; 系統還原工具 - 清空防火牆規則 / hosts / 關閉防火牆
; ==================================================

; 自動請求管理員權限
if not A_IsAdmin
{
    Run, *RunAs "%A_ScriptFullPath%"
    ExitApp
}

; 建立 GUI
Gui, New, , 系統還原工具
Gui, Color, 0x2D2D2D
Gui, Font, s10, Microsoft JhengHei

Gui, Add, Text, x10 y10 w380 cWhite, 警告：此操作會清除防火牆規則和 hosts 設定！
Gui, Add, Text, x10 y35 w380 c888888, 請先備份重要資料，建議在斷網狀態下執行。

; 分隔線
Gui, Add, Progress, x10 y55 w380 h2 c555555 Background555555

; ===== 防火牆區域 =====
Gui, Add, GroupBox, x10 y65 w380 h80 cWhite, 防火牆操作
Gui, Add, Button, x20 y90 w110 h30 gClearFirewallRules, 清空所有規則
Gui, Add, Button, x140 y90 w110 h30 gDisableFirewall, 關閉防火牆
Gui, Add, Text, x260 y95 w120 c888888, （需重啟生效）

; ===== hosts 區域 =====
Gui, Add, GroupBox, x10 y155 w380 h55 cWhite, hosts 操作
Gui, Add, Button, x20 y180 w110 h25 gClearHosts, 清空 hosts 內容

; ===== 進度與狀態 =====
Gui, Add, Text, x10 y220 w380 cYellow vStatusText, 狀態：就緒
Gui, Add, Progress, x10 y240 w380 h20 vProgressBar cGreen

; 顯示視窗
Gui, Show, w400 h280, 系統還原工具

return

; ==================================================
; 清空所有防火牆規則
; ==================================================
ClearFirewallRules:
    GuiControl, , StatusText, 狀態：正在清空防火牆規則...
    GuiControl, , ProgressBar, 20
    
    ; 備份當前規則（可選）
    RunWait, netsh advfirewall export "%A_Desktop%\firewall_backup_%A_Now%.wfw", , Hide
    
    ; 清空所有入站規則
    RunWait, netsh advfirewall firewall delete rule name=all, , Hide
    
    ; 清空所有出站規則
    RunWait, netsh advfirewall firewall delete rule name=all dir=out, , Hide
    
    GuiControl, , ProgressBar, 50
    Sleep, 500
    
    ; 顯示結果
    if ErrorLevel = 0
    {
        GuiControl, , StatusText, 狀態：防火牆規則已清空（備份於桌面）
        MsgBox, 4096, 完成, 防火牆規則已全部清空。`n`n備份檔案已儲存於桌面：firewall_backup_%A_Now%.wfw
    }
    else
    {
        GuiControl, , StatusText, 狀態：清空防火牆規則失敗
        MsgBox, 4096, 錯誤, 清空防火牆規則失敗，請確認是否以管理員權限執行。
    }
    
    GuiControl, , ProgressBar, 0
return

; ==================================================
; 關閉防火牆（所有設定檔）
; ==================================================
DisableFirewall:
    GuiControl, , StatusText, 狀態：正在關閉防火牆...
    GuiControl, , ProgressBar, 20
    
    ; 關閉所有設定檔的防火牆
    RunWait, netsh advfirewall set allprofiles state off, , Hide
    
    GuiControl, , ProgressBar, 50
    Sleep, 500
    
    if ErrorLevel = 0
    {
        GuiControl, , StatusText, 狀態：防火牆已關閉（建議重啟電腦）
        MsgBox, 4096, 完成, 防火牆已關閉。`n`n建議重啟電腦以確保完全生效。
    }
    else
    {
        GuiControl, , StatusText, 狀態：關閉防火牆失敗
        MsgBox, 4096, 錯誤, 關閉防火牆失敗，請確認是否以管理員權限執行。
    }
    
    GuiControl, , ProgressBar, 0
return

; ==================================================
; 清空 hosts 檔案內容
; ==================================================
ClearHosts:
    GuiControl, , StatusText, 狀態：正在清空 hosts 檔案...
    GuiControl, , ProgressBar, 20
    
    HostsFile := "C:\Windows\System32\drivers\etc\hosts"
    
    ; 備份原始 hosts 內容
    if FileExist(HostsFile)
    {
        FileCopy, %HostsFile%, %A_Desktop%\hosts_backup_%A_Now%.txt, 1
    }
    
    ; 清空 hosts 檔案（只保留預設註解和 localhost）
    HostsDefault := "# Windows Hosts File`n"
    HostsDefault .= "# 此檔案已被網路監控工具清空`n"
    HostsDefault .= "127.0.0.1       localhost`n"
    HostsDefault .= "::1             localhost"
    
    FileDelete, %HostsFile%
    FileAppend, %HostsDefault%, %HostsFile%, UTF-8
    
    GuiControl, , ProgressBar, 50
    Sleep, 500
    
    if ErrorLevel = 0
    {
        GuiControl, , StatusText, 狀態：hosts 已清空（備份於桌面）
        MsgBox, 4096, 完成, hosts 檔案已清空，僅保留 localhost 設定。`n`n備份檔案已儲存於桌面：hosts_backup_%A_Now%.txt
    }
    else
    {
        GuiControl, , StatusText, 狀態：清空 hosts 失敗
        MsgBox, 4096, 錯誤, 清空 hosts 檔案失敗，請確認是否以管理員權限執行。
    }
    
    GuiControl, , ProgressBar, 0
return

GuiClose:
    ExitApp