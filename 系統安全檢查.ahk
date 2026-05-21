; ==================================================
; 系統安全防護檢查工具
; 功能：檢查防火牆狀態、hosts 封鎖規則、防火牆規則
; ==================================================

; 顯示啟動提示
ToolTip, 系統安全檢查已啟動，將每10分鐘檢查一次
Sleep, 2000
ToolTip

; 設定檢查間隔（毫秒），預設 10 分鐘
CheckInterval := 600000

; 開始定期檢查
SetTimer, CheckAll, %CheckInterval%

; 立即執行一次檢查
Gosub, CheckAll

; 建立隱藏 GUI 保持運作
Gui, New, +hwndhGui
Gui, Show, Hide

return

; ==================================================
; 主檢查流程
; ==================================================
CheckAll:
    Gosub, CheckFirewallStatus
    Gosub, CheckHostsRules
    Gosub, CheckFirewallRules
    Gosub, UpdateTrayTip
return

; ==================================================
; 1. 檢查 Windows 防火牆狀態（支援繁體/簡體/英文）
; ==================================================
CheckFirewallStatus:
    RunWait, %ComSpec% /c netsh advfirewall show allprofiles state > "%A_Temp%\fw_check.txt", , Hide
    FileRead, fwOutput, %A_Temp%\fw_check.txt
    FileDelete, %A_Temp%\fw_check.txt
    
    LogTime := A_Now
    
    ; 檢查是否有設定檔被關閉（支援多種語言）
    if InStr(fwOutput, "關閉")      ; 繁體中文
    or InStr(fwOutput, "关闭")      ; 簡體中文
    or InStr(fwOutput, "off")       ; 英文
    or InStr(fwOutput, "OFF")
    {
        ; 防火牆被關閉，嘗試重新開啟
        RunWait, netsh advfirewall set allprofiles state on, , Hide
        
        ; 記錄到日誌
        FileAppend, %LogTime% - ⚠️ 防火牆被關閉，已自動重新開啟`n, %A_ScriptDir%\防火牆檢查紀錄.txt, UTF-8-RAW
        
        ; 顯示警告
        ToolTip, ⚠️ 防火牆已被關閉，已自動重新開啟！
        SetTimer, ClearToolTip, -3000
    }
    else
    {
        ; 防火牆正常時也記錄
        FileAppend, %LogTime% - ✅ 防火牆運作正常`n, %A_ScriptDir%\防火牆檢查紀錄.txt, UTF-8-RAW
    }
return

; ==================================================
; 2. 檢查 hosts 封鎖規則是否完整
; ==================================================
CheckHostsRules:
    CriticalDomains := ["8591.com.tw", "www.52pojie.cn", "googleads.g.doubleclick.net"]
    HostsFile := "C:\Windows\System32\drivers\etc\hosts"
    LogTime := A_Now
    
    if !FileExist(HostsFile)
    {
        FileAppend, %LogTime% - ❌ hosts 檔案不存在！`n, %A_ScriptDir%\防火牆檢查紀錄.txt, UTF-8-RAW
        ToolTip, ⚠️ hosts 檔案不存在！
        SetTimer, ClearToolTip, -5000
        return
    }
    
    FileRead, HostsContent, %HostsFile%
    MissingCount := 0
    MissingList := ""
    
    for index, domain in CriticalDomains
    {
        if (InStr(HostsContent, "0.0.0.0`t" domain) = 0 and InStr(HostsContent, "0.0.0.0 " domain) = 0)
        {
            MissingCount++
            MissingList .= domain . " "
        }
    }
    
    if (MissingCount > 0)
    {
        FileAppend, %LogTime% - ⚠️ hosts 遺失 %MissingCount% 個封鎖規則 (%MissingList%)`n, %A_ScriptDir%\防火牆檢查紀錄.txt, UTF-8-RAW
        ToolTip, ⚠️ hosts 遺失 %MissingCount% 個封鎖規則 (%MissingList%)，建議重新執行主程式
        SetTimer, ClearToolTip, -4000
    }
    else
    {
        ; hosts 規則完整時也記錄
        arrayLength := CriticalDomains.MaxIndex()
        FileAppend, %LogTime% - ✅ hosts 封鎖規則完整 (檢查了 %arrayLength% 個域名)`n, %A_ScriptDir%\防火牆檢查紀錄.txt, UTF-8-RAW
    }
return

; ==================================================
; 3. 檢查防火牆 IP 封鎖規則是否存在（支援繁體/簡體/英文）
; ==================================================
CheckFirewallRules:
    SampleIPs := ["147.185.132.22", "212.73.148.24", "45.33.65.239"]
    MissingRules := 0
    MissingIPList := ""
    ExistIPList := ""
    
    for index, ip in SampleIPs
    {
        tempFile := A_Temp . "\rule_check_" . ip . ".txt"
        RunWait, %ComSpec% /c netsh advfirewall firewall show rule name="Block_%ip%" > "%tempFile%" 2>&1, , Hide
        
        FileRead, ruleOutput, %tempFile%
        FileDelete, %tempFile%
        
        ; 判斷是否遺失（支援繁體、簡體、英文）
        if InStr(ruleOutput, "沒有符合的規則")              ; 繁體中文
        or InStr(ruleOutput, "No rules match")              ; 英文
        or InStr(ruleOutput, "找不到")                      ; 簡體中文（部分）
        or InStr(ruleOutput, "找不到符合指定條件的規則")    ; 簡體中文（完整）
        or InStr(ruleOutput, "未找到")                      ; 其他
        or (ruleOutput = "")                                ; 輸出為空
        {
            MissingRules++
            MissingIPList .= ip . " "
        }
        else
        {
            ExistIPList .= ip . " "
        }
    }
    
    LogTime := A_Now
    arrayLength := SampleIPs.MaxIndex()
    
    if (MissingRules > 0)
    {
        FileAppend, %LogTime% - ⚠️ 防火牆遺失 %MissingRules% 個 IP 封鎖規則 (%MissingIPList%)，完整 %ExistIPList% 個`n, %A_ScriptDir%\防火牆檢查紀錄.txt, UTF-8-RAW
        ToolTip, ⚠️ 防火牆遺失 %MissingRules% 個 IP 封鎖規則 (%MissingIPList%)，建議重新執行主程式
        SetTimer, ClearToolTip, -4000
    }
    else
    {
        ; 防火牆規則完整時也記錄
        FileAppend, %LogTime% - ✅ 防火牆 IP 封鎖規則完整 (檢查了 %arrayLength% 個，全部存在)`n, %A_ScriptDir%\防火牆檢查紀錄.txt, UTF-8-RAW
    }
return

; ==================================================
; 4. 更新托盤圖示提示
; ==================================================
UpdateTrayTip:
    Menu, Tray, Tip, 安全防護檢查中... 檢查間隔: 10 分鐘
return

; ==================================================
; 清除 ToolTip
; ==================================================
ClearToolTip:
    ToolTip
return

; ==================================================
; GUI 關閉事件
; ==================================================
GuiClose:
    ExitApp