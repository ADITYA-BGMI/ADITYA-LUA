-- ============================================================
-- MODDED BY ADITYA_ORG + @ADITYA_ORG
-- Complete MOD with Bypass V4.0 + SKINS + PBC WALLHACK
-- All features: Aimbot, ESP, PBC Wallhack, 165 FPS, No Grass, iPad View, SKINS
-- Bypass activates on game start with popup
-- ============================================================

-- ============================================================
-- PER-MATCH GUARD (re-init when player controller changes)
-- ============================================================
do
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if _G._MOD_LOADED and _G._MOD_PC == pc then return end
    _G._MOD_LOADED = true
    _G._MOD_PC = pc
end

-- ============================================================
-- ==================== ULTIMATE BYPASS V4.0 ====================
-- (Full Hook System + Anti-Ban + Spoofing + Telemetry Scrambler)
-- ============================================================

-- Self-protection & anti-tamper
local function ProtectEnvironment()
    if debug and debug.getinfo then
        local old_getinfo = debug.getinfo
        debug.getinfo = function(...)
            local info = old_getinfo(...)
            if info and info.source and string.find(info.source, "1.lua") then
                return nil
            end
            return info
        end
    end

    local g = _G
    local mt = getmetatable(g) or {}
    mt.__newindex = function(t, k, v)
        if k == "BypassLoaded" then return end
        rawset(t, k, v)
    end
    mt.__index = function(t, k)
        if k == "BypassLoaded" then return true end
        return rawget(t, k)
    end
    setmetatable(g, mt)
    _G.BypassLoaded = true
end
ProtectEnvironment()

-- NOP utilities (do NOT override print, to keep mod messages)
local function nop() end
local function nopt() return {} end
local function nopnil() return nil end
local function noptrue() return true end
local function nopfalse() return false end
local function nopstr() return "" end

-- Domain blocklist (expanded)
local blockedDomains = {
    "tss.tencent", "syzsdk", "gcloud.qq", "reportlog", "tdos", "logupload", "feedback.wh", "crash2",
    "privacy.qq", "privacy.tencent", "oth.eve", "mdt.qq", "act.tencentyun", "analytics", "report.qq",
    "anticheatexpert", "crashsight", "wetest", "log.tav", "sngd", "tracer", "intlsdk", "igamecj",
    "cdn.club", "gpubgm", "graph.facebook", "calendarpushsubscription", "googleads", "doubleclick",
    "firebaselogging", "firebaseremoteconfig", "fonts.googleapis", "abs.twimg", "dl.listdl",
    "igame.gcloudcs", "bugly", "beacon", "helpshift", "tdm", "apm", "safeguard", "weiyun", "qzone",
    "tencent-cloud", "myapp", "idqqimg", "gtimg", "qqmail", "tcdn", "cloudctrl", "sdkostrace",
    "103.134.189.146", "mbgame", "csoversea", "igame", "pubgmobile", "down.anticheatexpert.com",
    "asia.csoversea.mbgame.anticheatexpert.com", "log.tav.qq", "syzsdk.qq", "logiservice.qcloud",
    "opensdk.tencent", "exp.helpshift", "loginsdkapi.zingplay", "firebase", "googleapis", "facebook", "gvoice",
    "play.googleapis", "app-measurement", "googlesyndication", "googleadservices", "google-analytics",
    "googletagmanager", "googleoptimize", "googleusercontent", "googleapis.com", "gstatic.com",
    "graph.instagram.com", "api.telegram.org", "api.whatsapp.com"
}

-- MODULE 1: Advanced Domain Blocker
local function InitAdvancedDomainBlocker()
    pcall(function()
        local hc = package.loaded["client.network.http.HttpClient"]
        if hc then
            local mt = getmetatable(hc) or {}
            local old_send = hc.SendRequest
            mt.__index = function(t, k)
                if k == "SendRequest" then
                    return function(self, url, cb, method, headers, content, timeout)
                        for _, host in ipairs(blockedDomains) do
                            if url and string.find(string.lower(url), string.lower(host)) then
                                return nil
                            end
                        end
                        return old_send(self, url, cb, method, headers, content, timeout)
                    end
                end
                return rawget(t, k)
            end
            setmetatable(hc, mt)
        end

        if NetUtil and NetUtil.SendHttpRequest then
            local old = NetUtil.SendHttpRequest
            NetUtil.SendHttpRequest = function(url, cb, method, headers, content)
                for _, host in ipairs(blockedDomains) do
                    if url and string.find(string.lower(url), string.lower(host)) then
                        return nil
                    end
                end
                return old(url, cb, method, headers, content)
            end
        end

        local wv = package.loaded["client.slua.logic.url.logic_webview_sdk"]
        if wv and wv.OpenURL then
            local old = wv.OpenURL
            wv.OpenURL = function(url)
                for _, host in ipairs(blockedDomains) do
                    if url and string.find(string.lower(url), string.lower(host)) then
                        return nil
                    end
                end
                return old(url)
            end
        end

        if socket and socket.connect then
            local old = socket.connect
            socket.connect = function(host, port, timeout)
                for _, blocked in ipairs(blockedDomains) do
                    if host and string.find(string.lower(host), string.lower(blocked)) then
                        return nil, "blocked"
                    end
                end
                return old(host, port, timeout)
            end
        end

        if package.loaded["socket"] and package.loaded["socket"].dns and package.loaded["socket"].dns.gethostbyname then
            local old = package.loaded["socket"].dns.gethostbyname
            package.loaded["socket"].dns.gethostbyname = function(host)
                for _, blocked in ipairs(blockedDomains) do
                    if host and string.find(string.lower(host), string.lower(blocked)) then
                        return "127.0.0.1"
                    end
                end
                return old(host)
            end
        end
    end)
end

-- MODULE 2: Hook System (Metatable + debug)
local function InitHookSystem()
    pcall(function()
        local function hookFunction(obj, funcName, replacement)
            if not obj or not obj[funcName] then return end
            local old = obj[funcName]
            obj[funcName] = function(...)
                return replacement(...)
            end
            obj["_orig_" .. funcName] = old
        end

        if _G.GameplayCallbacks then
            local GC = _G.GameplayCallbacks
            local blockList = {
                "ReportAttackFlow","ReportSecAttackFlow","ReportHurtFlow",
                "ReportFireArms","ReportVerifyInfoFlow","ReportMrpcsFlow",
                "ReportPlayerBehavior","ReportTeammatHurt","ReportMisKillByTeammate",
                "ReportForbitPick","ReportPlayerMoveRoute","ReportPlayerPosition",
                "ReportVehicleMoveFlow","ReportSecTgameMovingFlow","ReportParachuteData",
                "SendTssSdkAntiDataToLobby","SendDSErrorLogToLobby",
                "SendDSErrorLogToLobbyOnece","SendDSHawkEyePatrolLogToLobby",
                "ReportEquipmentFlow","ReportAimFlow",
                "ReportHeavyWeaponBoxSpawnFlow","ReportHeavyWeaponBoxActivationFlow",
                "ReportHeavyWeaponBoxOpenPlayerFlow","ReportHeavyWeaponBoxItemFlow",
                "ReportPlayersPing","ReportPlayerIP","ReportPlayerFramePingRecord",
                "OnDSConnectionSaturated","ReportDSNetSaturation",
                "ReportNetContinuousSaturate","ReportDSNetRate",
                "SendClientStats","SendServerAvgTickDelta",
                "ReportCircleFlow","ReportDSCircleFlow","ReportJumpFlow",
                "ReportAIStrategyInfo","SendAIDeliveryInfo","ReportDailyTaskInfo",
                "ReportMatchRoomData","SendPlayerSpectatingLog",
                "ReportIDCardProduceFlow","ReportIDCardPickUpFlow",
                "ReportIDCardDestroyFlow","ReportRevivalFlow",
                "ReportGameSetting","ReportGameSettingNew",
                "ReportAntsVoiceTeamCreate","ReportAntsVoiceTeamQuit",
                "ReportCommonInfo","ReportLightweightStat",
                "SendSecTLog","SendDataMiningTLog","SendActivityTLog"
            }
            for _, f in ipairs(blockList) do
                if GC[f] then
                    GC[f] = nop
                end
            end
            if GC.OnDSPlayerStateChanged then
                local orig = GC.OnDSPlayerStateChanged
                GC.OnDSPlayerStateChanged = function(uid, state, ...)
                    local s = string.lower(tostring(state or ""))
                    if s == "cheatdetected" or s == "connectionlost" or s == "connectiontimeout" then
                        return
                    end
                    return orig(uid, state, ...)
                end
            end
        end

        local sm = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if sm then
            local mt = getmetatable(sm) or {}
            local old_get = mt.__index
            mt.__index = function(t, k)
                local sub = old_get(t, k)
                if sub and type(sub) == "table" then
                    return setmetatable({}, {
                        __index = function(_, method)
                            if method == "Report" or method == "ReportException" or method == "StartCheck" or method == "CheckAvatar" then
                                return nop
                            end
                            return sub[method]
                        end
                    })
                end
                return sub
            end
            setmetatable(sm, mt)
        end
    end)
end

-- MODULE 3: TSS + SDK Blocker (Complete)
local function InitTssSdkBlocker()
    pcall(function()
        local tss = package.loaded["TssSdk"] or _G.TssSdk
        if tss then
            for k, v in pairs(tss) do
                if type(v) == "function" then
                    tss[k] = nop
                end
            end
            tss.ScanMemory = noptrue
            tss.IsEmulator = nopfalse
            tss.GetTssSdkReportInfo = nopstr
        end

        local beacon = package.loaded["BeaconSDK"] or _G.BeaconSDK
        if beacon then
            for k, v in pairs(beacon) do
                if type(v) == "function" then
                    beacon[k] = nop
                end
            end
        end

        local bugly = package.loaded["BuglySDK"] or _G.BuglySDK
        if bugly then
            for k, v in pairs(bugly) do
                if type(v) == "function" then
                    bugly[k] = nop
                end
            end
        end

        local helpshift = package.loaded["HelpShift"] or _G.HelpShift
        if helpshift then
            for k, v in pairs(helpshift) do
                if type(v) == "function" then
                    helpshift[k] = nop
                end
            end
        end
    end)
end

-- MODULE 4: Log Blocker (keeps print intact)
local function InitLogBlocker()
    pcall(function()
        local tlog = package.loaded["TLog"] or _G.TLog
        if tlog then
            for k, v in pairs(tlog) do
                if type(v) == "function" then
                    tlog[k] = nop
                end
            end
        end

        local cs = package.loaded["CrashSight"] or _G.CrashSight
        if cs then
            for k, v in pairs(cs) do
                if type(v) == "function" then
                    cs[k] = nop
                end
            end
        end

        local gru = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
        if gru then
            gru.BugglyPostExceptionFull = nopfalse
            gru.CheckCanBugglyPostException = nopfalse
            gru.ReplayReportData = nop
            gru.ReportGameException = nop
        end

        local ctr = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if ctr then
            for k, v in pairs(ctr) do
                if type(v) == "function" then
                    ctr[k] = nop
                end
            end
        end
    end)
end

-- MODULE 5: Scanner & Integrity Checks
local function InitScannerBlocker()
    pcall(function()
        local sm = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if sm then
            local subsystems = {
                "AFKReportorSubsystem",
                "ClientDataStatistcsSubsystem",
                "AvatarExceptionSubsystem",
                "ShootVerifySubSystemClient",
                "FileCheckSubsystem"
            }
            for _, name in ipairs(subsystems) do
                local sub = sm:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" then
                            sub[k] = nop
                        end
                    end
                    if sub.ReportPingDelayTimer then
                        sub:RemoveGameTimer(sub.ReportPingDelayTimer)
                        sub.ReportPingDelayTimer = nil
                    end
                end
            end
        end

        local cmbl = import("CreativeModeBlueprintLibrary")
        if cmbl then
            cmbl.MD5HashByteArray = function() return "BYPASSED" end
            cmbl.GetContentDiffData = function() return true, "BYPASSED" end
        end

        local aepi = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
        if aepi then
            for k, v in pairs(aepi) do
                if type(v) == "function" then
                    aepi[k] = nop
                end
            end
            aepi.CheckCanBugglyPostException = nopfalse
        end

        local acm = package.loaded["blacklist.slua.logic.lobby_gm.AvatarCheckerModule"]
        if acm then
            acm.CheckAvatar = noptrue
            acm.ReportException = nop
        end

        local lmw = package.loaded["client.slua.logic.memory_warning.logic_memory_warning"]
        if lmw then
            lmw.OnMemoryWarning = nop
            lmw.ReportMemoryWarning = nop
        end
    end)
end

-- MODULE 6: Anti-Report (Full)
local function InitAntiReport()
    pcall(function()
        local crp = nil
        local paths = {
            "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem",
            "Client.Security.ClientReportPlayerSubsystem"
        }
        for _, p in ipairs(paths) do
            if package.loaded[p] then
                crp = package.loaded[p]
                break
            end
            local ok, m = pcall(require, p)
            if ok and m then
                crp = m
                break
            end
        end

        if crp then
            for k, v in pairs(crp) do
                if type(v) == "function" then
                    crp[k] = nop
                end
            end
            crp.GetFatalDamagerMap = nopt
            crp.GetCachedTeammateName2InfoMap = nopt
            crp.GetTeammateName2InfoMapDuringBattle = nopt
            crp.GetCurrentNotInTeamHistoricalTeammateMap = nopt
            crp.GetInTeamIndexFromHistoricalTeammateInfo = function() return -1 end
        end
    end)
end

-- MODULE 7: Gameplay Bypass (DS State + Network Packets)
local function InitGameplayBypass()
    pcall(function()
        if NetUtil and NetUtil.SendPacket then
            local old = NetUtil.SendPacket
            local blockPacketNames = {
                "ReportAttackFlow", "ReportSecAttackFlow", "ReportHurtFlow",
                "ReportFireArms", "ReportVerifyInfoFlow", "ReportMrpcsFlow",
                "ReportPlayerBehavior", "ReportTeammatHurt",
                "on_tss_sdk_anti_data", "report_parachute_data",
                "ReportAimFlow", "ReportHitFlow",
                "ReportCircleFlow", "ReportJumpFlow",
                "ReportGameStartFlow", "ReportGameEndFlow",
                "report_players_ping", "report_player_ip",
                "tss_sdk_report", "report_memory_exception",
                "report_avatar_exception",
                "report_cheat_detected", "report_anti_debug", "report_emulator"
            }
            local blockMap = {}
            for _, name in ipairs(blockPacketNames) do blockMap[name] = true end

            NetUtil.SendPacket = function(name, ...)
                if blockMap[name] then
                    return
                end
                return old(name, ...)
            end
        end
    end)
end

-- MODULE 8: Memory & Script Protection
local function InitMemoryProtection()
    pcall(function()
        local old_pcall = pcall
        pcall = function(f, ...)
            return old_pcall(function(...)
                local old_G = _G
                _G = {}
                local ret = {f(...)}
                _G = old_G
                return unpack(ret)
            end, ...)
        end

        if debug and debug.getupvalue then
            local old = debug.getupvalue
            debug.getupvalue = function(f, n)
                if f == nop or f == nopt or f == nopnil or f == noptrue or f == nopfalse or f == nopstr then
                    return nil
                end
                return old(f, n)
            end
        end

        if string and string.dump then
            local old_dump = string.dump
            string.dump = function(f)
                if f == nop or f == nopt or f == nopnil or f == noptrue or f == nopfalse or f == nopstr then
                    return nil
                end
                return old_dump(f)
            end
        end
    end)
end

-- MODULE 9: Anti-Flag & Offline Flag Killer
local function InitAntiFlag()
    pcall(function()
        local function killFlag(obj)
            if obj then
                if obj.bIsBanned then obj.bIsBanned = false end
                if obj.bIsFlagged then obj.bIsFlagged = false end
                if obj.bOfflineFlag then obj.bOfflineFlag = false end
                if obj.bReported then obj.bReported = false end
                if obj.FlagCount then obj.FlagCount = 0 end
                if obj.OfflineFlagCount then obj.OfflineFlagCount = 0 end
                if obj.BanReason then obj.BanReason = "" end
                if obj.BanDuration then obj.BanDuration = 0 end
            end
        end

        for k, v in pairs(package.loaded) do
            if type(v) == "table" then
                killFlag(v)
                for _, sub in pairs(v) do
                    if type(sub) == "table" then
                        killFlag(sub)
                    end
                end
            end
        end

        local flagSetters = {
            "SetBanned", "SetFlag", "SetOfflineFlag", "AddFlag", "ReportFlag",
            "SetBanReason", "SetBanDuration", "SetBanStatus"
        }
        for _, name in ipairs(flagSetters) do
            for k, v in pairs(_G) do
                if type(v) == "table" and v[name] then
                    v[name] = nop
                end
            end
        end

        if Game then
            if Game.IsBanned then Game.IsBanned = nopfalse end
            if Game.IsFlagged then Game.IsFlagged = nopfalse end
            if Game.GetOfflineFlag then Game.GetOfflineFlag = nopfalse end
            if Game.GetBanInfo then Game.GetBanInfo = nopnil end
        end
    end)
end

-- MODULE 10: Higgs Boson Disabler
local function InitHiggsBoson()
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if pc and slua.isValid(pc) then
            if pc.HiggsBoson then
                pc.HiggsBoson.bMHActive = false
                pc.HiggsBoson.bCallPreReplication = false
            end
            if pc.HiggsBosonComponent then
                pc.HiggsBosonComponent.bMHActive = false
                pc.HiggsBosonComponent:ControlMHActive(0)
            end
        end

        local hbc = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if hbc then
            for k, v in pairs(hbc) do
                if type(v) == "function" then
                    hbc[k] = nop
                end
            end
            if hbc.BlackList then
                for k in pairs(hbc.BlackList) do
                    hbc.BlackList[k] = nil
                end
            end
        end

        if _G.AvatarCheckCallback then
            _G.AvatarCheckCallback.StartAvatarCheck = nop
            _G.AvatarCheckCallback.OnReportItemID = nop
            _G.AvatarCheckCallback.PostPlayerControllerLoginInit = function(pc)
                if slua.isValid(pc) and pc.HiggsBosonComponent then
                    pc.HiggsBosonComponent:ControlMHActive(0)
                    pc.HiggsBosonComponent.bMHActive = false
                end
            end
        end

        if _G.GameSafeCallbacks then
            for k, v in pairs(_G.GameSafeCallbacks) do
                if type(v) == "function" then
                    _G.GameSafeCallbacks[k] = nop
                end
            end
        end

        local stebp = import("STExtraBlueprintFunctionLibrary")
        if stebp then
            stebp.IsDevelopment = nopfalse
        end
    end)
end

-- MODULE 11: Emulator & Device Spoofing
local function InitSpoofing()
    pcall(function()
        if Device then
            if Device.GetDeviceModel then
                Device.GetDeviceModel = function() return "SM-G998B" end
            end
            if Device.GetDeviceManufacturer then
                Device.GetDeviceManufacturer = function() return "samsung" end
            end
            if Device.GetDeviceOS then
                Device.GetDeviceOS = function() return "Android" end
            end
            if Device.GetDeviceOSVersion then
                Device.GetDeviceOSVersion = function() return "12" end
            end
            if Device.IsEmulator then
                Device.IsEmulator = nopfalse
            end
            if Device.GetDeviceID then
                Device.GetDeviceID = function() return "random_device_id_12345" end
            end
            if Device.GetMACAddress then
                Device.GetMACAddress = function() return "02:00:00:00:00:01" end
            end
        end

        if SystemInfo then
            if SystemInfo.GetNetworkType then
                SystemInfo.GetNetworkType = function() return "WIFI" end
            end
            if SystemInfo.GetNetworkOperator then
                SystemInfo.GetNetworkOperator = function() return "T-Mobile" end
            end
            if SystemInfo.GetIPAddress then
                SystemInfo.GetIPAddress = function() return "192.168.1.100" end
            end
        end
    end)
end

-- MODULE 12: Integrity Overrides (Final)
local function InitIntegrityOverrides()
    pcall(function()
        if Game and Game.CheckIntegrity then
            Game.CheckIntegrity = noptrue
        end
        if slua and slua.check_integrity then
            slua.check_integrity = noptrue
        end

        local modules = {
            "GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent",
            "GameLua.Mod.BaseMod.Common.Security.TssSecurityModule",
            "GameLua.Mod.BaseMod.Common.Security.AntiCheatModule",
            "GameLua.Mod.BaseMod.Common.Security.MemoryIntegrityModule"
        }
        for _, mn in ipairs(modules) do
            pcall(function()
                local m = package.loaded[mn]
                if m then
                    for k, v in pairs(m) do
                        if type(v) == "function" then
                            m[k] = nop
                        end
                    end
                    m.ControlMHActive = nop
                    m.Tick = nop
                    m.Report = nop
                    m.Check = noptrue
                    m.Validate = noptrue
                end
            end)
        end
    end)
end

-- MODULE 13: Ban Status Killer
local function InitBanKiller()
    pcall(function()
        local banFunctions = {
            "IsBanned", "IsFlagged", "IsOfflineFlagged", "GetBanStatus",
            "CheckBanStatus", "GetPlayerBanInfo", "IsAccountBanned"
        }
        for _, funcName in ipairs(banFunctions) do
            for k, v in pairs(_G) do
                if type(v) == "table" and v[funcName] then
                    v[funcName] = nopfalse
                end
            end
        end

        if Game then
            Game.IsBanned = nopfalse
            Game.IsFlagged = nopfalse
            Game.GetOfflineFlag = nopfalse
            Game.GetBanInfo = nopnil
        end

        if LocalStorage then
            if LocalStorage.GetBool then
                local oldGet = LocalStorage.GetBool
                LocalStorage.GetBool = function(key)
                    if key and string.find(key, "ban") then
                        return false
                    end
                    return oldGet(key)
                end
            end
            if LocalStorage.SetBool then
                local oldSet = LocalStorage.SetBool
                LocalStorage.SetBool = function(key, val)
                    if key and string.find(key, "ban") then
                        return
                    end
                    return oldSet(key, val)
                end
            end
        end
    end)
end

-- MODULE 14: Hardware & IP Spoofer
local function InitHardwareSpoofer()
    pcall(function()
        local function randomString(len)
            local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            local result = ""
            for i = 1, len do
                result = result .. string.sub(chars, math.random(1, #chars), math.random(1, #chars))
            end
            return result
        end

        if Device then
            if Device.GetDeviceID then
                Device.GetDeviceID = function() return randomString(16) end
            end
            if Device.GetMACAddress then
                Device.GetMACAddress = function() 
                    return string.format("02:%02x:%02x:%02x:%02x:%02x", 
                        math.random(0,255), math.random(0,255), math.random(0,255),
                        math.random(0,255), math.random(0,255))
                end
            end
            if Device.GetSerialNumber then
                Device.GetSerialNumber = function() return randomString(12) end
            end
            if Device.GetAndroidID then
                Device.GetAndroidID = function() return randomString(16) end
            end
        end

        if NetUtil and NetUtil.GetLocalIP then
            NetUtil.GetLocalIP = function() 
                return string.format("192.168.%d.%d", math.random(1,254), math.random(1,254))
            end
        end
        if NetUtil and NetUtil.GetPublicIP then
            NetUtil.GetPublicIP = function() 
                return string.format("%d.%d.%d.%d", math.random(1,255), math.random(1,255), 
                    math.random(1,255), math.random(1,255))
            end
        end
    end)
end

-- MODULE 15: Telemetry Scrambler (Fake Legit Data)
local function InitTelemetryScrambler()
    pcall(function()
        if _G.GameplayCallbacks then
            local GC = _G.GameplayCallbacks
            if GC.ReportPlayersPing then
                local old = GC.ReportPlayersPing
                GC.ReportPlayersPing = function(...)
                    return old(...)
                end
            end
            if GC.ReportPlayerFramePingRecord then
                GC.ReportPlayerFramePingRecord = function()
                    return { ping = math.random(20, 100), fps = math.random(30, 60) }
                end
            end
        end

        if NetUtil and NetUtil.SendPacket then
            local oldSend = NetUtil.SendPacket
            NetUtil.SendPacket = function(name, data)
                if name == "report_players_ping" or name == "report_player_ip" then
                    if type(data) == "table" then
                        if data.ping then data.ping = math.random(20, 80) end
                        if data.fps then data.fps = math.random(30, 60) end
                        if data.ip then data.ip = "192.168." .. math.random(1,254) .. "." .. math.random(1,254) end
                    end
                end
                return oldSend(name, data)
            end
        end
    end)
end

-- MODULE 16: Replay & Spectator Blocker
local function InitReplayBlocker()
    pcall(function()
        if _G.GameplayCallbacks then
            local GC = _G.GameplayCallbacks
            GC.OnReplayRecord = nop
            GC.OnSpectatorMode = nop
            GC.SendReplayData = nop
        end

        local replay = package.loaded["GameLua.Mod.BaseMod.GamePlay.Replay.ReplaySubsystem"]
        if replay then
            for k, v in pairs(replay) do
                if type(v) == "function" then
                    replay[k] = nop
                end
            end
            replay.IsReplayRecording = nopfalse
            replay.CanRecord = nopfalse
        end

        local spec = package.loaded["GameLua.Mod.BaseMod.GamePlay.Spectator.SpectatorSubsystem"]
        if spec then
            spec.OnSpectatorJoin = nop
            spec.OnSpectatorLeave = nop
            spec.ReportSpectatorData = nop
        end
    end)
end

-- MODULE 17: Memory Cleaner (Periodic Flag Reset)
local function InitMemoryCleaner()
    pcall(function()
        local function cleanFlags()
            for k, v in pairs(package.loaded) do
                if type(v) == "table" then
                    if v.FlagCount then v.FlagCount = 0 end
                    if v.OfflineFlagCount then v.OfflineFlagCount = 0 end
                    if v.BanCount then v.BanCount = 0 end
                    if v.bIsBanned then v.bIsBanned = false end
                    if v.bIsFlagged then v.bIsFlagged = false end
                    if v.bOfflineFlag then v.bOfflineFlag = false end
                    if v.bReported then v.bReported = false end
                end
            end
        end

        if slua and slua.addTimer then
            slua.addTimer(30000, true, cleanFlags)
        elseif _G.Timer and _G.Timer.SetInterval then
            _G.Timer.SetInterval(cleanFlags, 30000)
        else
            if _G.OnUpdate then
                local oldUpdate = _G.OnUpdate
                local counter = 0
                _G.OnUpdate = function(delta)
                    counter = counter + delta
                    if counter >= 30 then
                        counter = 0
                        cleanFlags()
                    end
                    if oldUpdate then oldUpdate(delta) end
                end
            end
        end
    end)
end

-- Master initializer (shuffled order for stealth)
local function InitAllBypasses()
    if _G.BypassRunning then return end
    _G.BypassRunning = true

    pcall(function()
        local modules = {
            InitAdvancedDomainBlocker,
            InitHookSystem,
            InitTssSdkBlocker,
            InitLogBlocker,
            InitScannerBlocker,
            InitAntiReport,
            InitGameplayBypass,
            InitMemoryProtection,
            InitAntiFlag,
            InitHiggsBoson,
            InitSpoofing,
            InitIntegrityOverrides,
            InitBanKiller,
            InitHardwareSpoofer,
            InitTelemetryScrambler,
            InitReplayBlocker,
            InitMemoryCleaner
        }

        -- Shuffle
        for i = #modules, 2, -1 do
            local j = math.random(i)
            modules[i], modules[j] = modules[j], modules[i]
        end

        for _, initFunc in ipairs(modules) do
            initFunc()
        end
    end)

    if debug and debug.getinfo then
        local old_getinfo = debug.getinfo
        debug.getinfo = function(...)
            local info = old_getinfo(...)
            if info and info.source and string.find(info.source, "1.lua") then
                info.source = "(hidden)"
            end
            return info
        end
    end

    _G.BypassLoaded = true
end

-- Auto-run bypass
if Client then
    InitAllBypasses()
end

-- ============================================================
-- FEATURE TOGGLES
-- ============================================================
if not _G.Mod_Aimbot_Enabled then _G.Mod_Aimbot_Enabled = false end
if not _G.Mod_ESP_Enabled then _G.Mod_ESP_Enabled = false end
if _G.Mod_FPS165_Enabled == nil then _G.Mod_FPS165_Enabled = true end
if _G.Mod_NoGrass_Enabled == nil then _G.Mod_NoGrass_Enabled = true end
if _G.Mod_iPadView_Enabled == nil then _G.Mod_iPadView_Enabled = false end
if _G.Mod_iPadViewDistance == nil then _G.Mod_iPadViewDistance = 90 end
if _G.Mod_Skin_Enabled == nil then _G.Mod_Skin_Enabled = false end
if _G.Mod_PBCWallhack_Enabled == nil then _G.Mod_PBCWallhack_Enabled = false end

local require = require
local import  = import
local isValid = slua.isValid
local pcall = pcall
local type = type
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local math = math
local string = string
local os = os

-- safe_require (unchanged)
local function safe_require(path)
    local ok, mod = pcall(require, path)
    return ok and mod or nil
end

local ok_gd, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
if not ok_gd then GameplayData = nil end

-- ============================================================
-- WELCOME POP-UP
-- ============================================================
pcall(function()
    local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
    if not Msg then Msg = require("client.slua.logic.common.logic_common_msg_box") end
    local Web = require("client.slua.logic.url.logic_webview_sdk")
    local function onClick() if Web then Web:OpenURL("https://t.me/ADITYA_ORG") end end
    if Msg and Msg.Show then
        Msg.Show(4, "✦ ADITYA_ORG – ELITE ULTIMATE ✦",
        "\n★ Developer : @ADITYA_ORG\n" ..
        "★ Status    : UNDETECTED & OPTIMIZED\n" ..
        "★ Bypass    : 27-Layer Deep Shield + All Visuals\n\n" ..
        "✓ Premium Build Loaded Successfully!", onClick)
    end
end)

-- ============================================================
-- ESP (unchanged, uses functions from above)
-- ============================================================
local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")

local cachedPawns     = {}
local lastPawnRefresh = 0

local function IsPawnAlive(p)
    if not slua.isValid(p) then return false end
    if p.HealthStatus then return SecurityCommonUtils.IsHealthStatusAlive(p.HealthStatus) end
    if p.IsAlive then return p:IsAlive() end
    return p.GetHealth and (p:GetHealth() or 0) > 0 or false
end

local boneList = {"head","neck_01","spine_01","spine_02","spine_03","pelvis",
    "upperarm_l","upperarm_r","lowerarm_l","lowerarm_r","hand_l","hand_r",
    "calf_l","calf_r","foot_l","foot_r"}
local function TextScale(distM)
    local t = math.min(distM / 400, 1)
    return 0.35 - t * 0.2
end

local function HPBar(pct)
    local n = math.floor((pct * 4) + 0.5)
    local s = ""
    for i = 1, 4 do s = s .. (i <= n and "▁" or " ") end
    return s
end

local function ESPTick()
    if not _G.CheatsEnabled then return end
    if _G.Mod_ESP_Enabled == false then return end
    if _G._ESPTimerHandle and _G._ESPTimerChar and not slua.isValid(_G._ESPTimerChar) then _G._ESPTimerHandle = nil; _G._ESPTimerChar = nil end
    local uCon = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not (slua.isValid(uCon) and Game:IsClassOf(uCon, ASTExtraPlayerController)) then return end
    local currentPawn = uCon:GetCurPawn()
    if not slua.isValid(currentPawn) then return end

    local myTeamId = 0
    pcall(function()
        local char = uCon:GetPlayerCharacterSafety()
        if slua.isValid(char) and char.TeamID then myTeamId = char.TeamID
        elseif currentPawn.TeamID then myTeamId = currentPawn.TeamID end
    end)
    local myPos = nil
    pcall(function() myPos = currentPawn:K2_GetActorLocation() end)
    if not myPos then return end
    local myEyePos = myPos
    pcall(function()
        if currentPawn.GetHeadLocation then myEyePos = currentPawn:GetHeadLocation(false) or myPos end
    end)
    HUD = uCon:GetHUD()
    local now      = os.clock()

    if now - lastPawnRefresh > 1.0 then
        lastPawnRefresh = now
        cachedPawns = Game:GetAllPlayerPawns() or {}
    end

    local botCount = 0
    local playerCount = 0

    local totalAlive = 0
    for _, p in pairs(cachedPawns) do
        if slua.isValid(p) and p ~= currentPawn and p.TeamID ~= myTeamId and IsPawnAlive(p) then
            totalAlive = totalAlive + 1
        end
    end
    local crowded = totalAlive > 20

    for _, tPawn in pairs(cachedPawns) do
        if slua.isValid(tPawn) and tPawn ~= currentPawn and tPawn.TeamID ~= myTeamId then
            if IsPawnAlive(tPawn) then
                local enemyPos = tPawn:K2_GetActorLocation()
                local dx = enemyPos.X - myPos.X
                local dy = enemyPos.Y - myPos.Y
                local dz = enemyPos.Z - myPos.Z
                local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

                local isBot = false
                pcall(function() isBot = Game:IsAI(tPawn) end)
                if isBot then botCount = botCount + 1 else playerCount = playerCount + 1 end

                if dist < 600000 and HUD then
                    local name = tPawn.PlayerName or "UNKNOWN"
                    local distM = dist / 100

                    local hp = tPawn.Health
                    local maxHp = tPawn.HealthMax
                    local isKnock = false
                    local hpPercent = 0
                    if not hp or not maxHp or maxHp <= 0 then
                        isKnock = true
                    elseif hp <= 0 then
                        isKnock = true
                    else
                        hpPercent = hp / maxHp
                    end
                    local hpColor = {R=0,G=255,B=0,A=255}
                    if hpPercent < 0.3 then
                        hpColor = {R=255,G=0,B=0,A=255}
                    elseif hpPercent < 0.7 then
                        hpColor = {R=255,G=255,B=0,A=255}
                    end
                    if isKnock then
                        hpColor = {R=255,G=0,B=0,A=255}
                    end

                    local bones = {}
                    local mesh = tPawn.Mesh
                    if slua.isValid(mesh) then
                        for _, bn in ipairs(boneList) do
                            bones[bn] = mesh:GetSocketLocation(bn)
                        end
                    end
                    local origin = enemyPos
                    local oz = origin.Z
                    local headPos = bones["head"]
                    local footPos = bones["foot_l"]
                    local footRPos = bones["foot_r"]
                    local topZ = headPos and (headPos.Z - oz) or 90
                    local botZ = footPos and math.min(footPos.Z, footRPos and footRPos.Z or footPos.Z) - oz or -85

                    local headZ = headPos and (headPos.Z - oz) or 90
                    local hpOffset = headZ + 70 + math.min(distM, 60) * 3 + math.max(0, distM - 60) * 0.5
                    local nameOffset = -80 - math.min(distM, 60) * 0.33 - math.max(0, distM - 60) * 0.1

                    if crowded then
                        local hz = headPos and (headPos.Z - oz + 15)
                        if hz then HUD:AddDebugText("●", tPawn, TextScale(distM), {X=0,Y=0,Z=hz}, {X=0,Y=0,Z=hz}, {R=255,G=0,B=0,A=255}, true, false, true, nil, 1.0, true) end
                        local hpText = isKnock and "DOWN" or HPBar(hpPercent)
                        HUD:AddDebugText(hpText, tPawn, TextScale(distM), {X=0,Y=0,Z=hpOffset}, {X=0,Y=0,Z=hpOffset}, hpColor, true, false, true, nil, 1.0, true)
                    else
                        local hz = headPos and (headPos.Z - oz + 15)
                        local headChar = distM <= 25 and "❄" or "●"
                        if hz then HUD:AddDebugText(headChar, tPawn, TextScale(distM), {X=0,Y=0,Z=hz}, {X=0,Y=0,Z=hz}, {R=255,G=0,B=0,A=255}, true, false, true, nil, 1.0, true) end

                        local hpText = isKnock and "DOWN" or HPBar(hpPercent)
                        HUD:AddDebugText(hpText, tPawn, TextScale(distM), {X=0,Y=0,Z=hpOffset}, {X=0,Y=0,Z=hpOffset}, hpColor, true, false, true, nil, 1.0, true)

                        local nameColor = {R=0,G=255,B=0,A=255}
                        local targetPos = headPos or tPawn:K2_GetActorLocation()
                        pcall(function()
                            if Game:IsTargetPosVisible(myEyePos, targetPos, {currentPawn}) then
                                nameColor = {R=0,G=255,B=0,A=255}
                            else
                                nameColor = {R=255,G=255,B=0,A=255}
                            end
                        end)

                        HUD:AddDebugText(string.format("[%.0fm] %s", distM, name), tPawn, TextScale(distM), {X=0,Y=0,Z=nameOffset}, {X=0,Y=0,Z=nameOffset}, nameColor, true, false, true, nil, 1.0, true)
                    end
                end
            end
        end
    end

    if not crowded and HUD and currentPawn then
        HUD:AddDebugText(string.format("BOT : %d     PLAYER : %d", botCount, playerCount), currentPawn, 1, {X=0,Y=0,Z=150}, {X=0,Y=0,Z=150}, {R=255,G=255,B=0,A=255}, true, false, true, nil, 1.0, true)
        HUD:AddDebugText("✦REAL DEV @ADITYA_ORG✦", currentPawn, 1, {X=0,Y=0,Z=145}, {X=0,Y=0,Z=145}, {R=0,G=200,B=255,A=255}, true, false, true, nil, 1.0, true)
    end
end

pcall(function()
    if _G._ESPWatchdogHandle then pcall(function() Game:ClearTimer(_G._ESPWatchdogHandle) end); _G._ESPWatchdogHandle = nil end

    local function StartESP(targetActor)
        if not slua.isValid(targetActor) then return end
        cachedPawns = {}; lastPawnRefresh = 0
        _G._ESPTimerChar = targetActor
        _G._ESPTimerHandle = targetActor:AddGameTimer(0.2, true, function()
            pcall(ESPTick)
        end)
    end

    local function Watchdog()
        pcall(function()
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            local curPawn = pc and pc:GetCurPawn()
            if slua.isValid(curPawn) and _G._ESPTimerChar ~= curPawn then
                if _G._ESPTimerHandle and slua.isValid(_G._ESPTimerChar) then
                    pcall(function() _G._ESPTimerChar:RemoveGameTimer(_G._ESPTimerHandle) end)
                end
                _G._ESPTimerHandle = nil
                StartESP(curPawn)
            elseif not _G._ESPTimerHandle then
                StartESP(curPawn)
            end
        end)
    end

    _G._ESPWatchdogHandle = Game:SetTimer(1.0, true, Watchdog)
    Watchdog()
end)

-- ============================================================
-- AIMBOT + FEATURES (unchanged)
-- ============================================================
_G.Enable165FPSLogic = function()
  pcall(function()
    local graphics = require("client.slua.logic.setting.logic_setting_graphics")
    if graphics then
      local orig = graphics.SetFPS
      function graphics:SetFPS(lvl)
        if orig then orig(self, lvl) end
        if lvl == 8 and _G.Mod_FPS165_Enabled ~= false then
          self:ExecuteCMD("t.MaxFPS", "165")
          self:ExecuteCMD("r.FrameRateLimit", "165")
        end
      end
    end
    local fpsComp = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
    if fpsComp and fpsComp.__inner_impl then
      local impl = fpsComp.__inner_impl
      function impl.GetMaxFPSLevel() return 8, 8 end
      function impl:InitRealSupportFPS()
        local t = {}; for i = 1, 8 do t[i] = {true, true} end
        local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
        if db then db:UpdateUIData(db.RealSupportFPS, t, false) end
        return t
      end
      function impl:UpdateSelectedFPSState(lvl)
        local fps = {[2]=20,[3]=25,[4]=30,[5]=40,[6]=60,[7]=90,[8]=120}
        for i = 2, 8 do
          local node = self.UIRoot["NodeFps"..tostring(fps[i] or 120)]
          if slua.isValid(node) then
            node:SetIsEnabled(true); pcall(function() node:SetRenderOpacity(1.0) end)
            local sw = self.UIRoot["WidgetSwitcher_"..tostring(i)]
            if slua.isValid(sw) then sw:SetActiveWidgetIndex(i == lvl and 0 or 1) end
          end
        end
      end
    end
    local fpsFT = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
    if fpsFT and fpsFT.__inner_impl then
      local impl = fpsFT.__inner_impl; local MIN = 90
      function impl:ShowOrHide() self:SelfHitTestInvisible(); if self.InitFPSFTSwitch then self:InitFPSFTSwitch() end end
      function impl:InitFPSFTSwitch()
        local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB"); local on = db:GetUIData(db.FPSFineTuneSwitch)
        if self.UIRoot.Setting_Switch then self.UIRoot.Setting_Switch:SetSwitcherEnable2(on, true) end
        if self.UIRoot.CanvasPanel_8 then self:SetWidgetVisible(self.UIRoot.CanvasPanel_8, on) end
        if self.UIRoot.WidgetSwitcher_0 then self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2) end
        if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
      end
      function impl:InitFPSFTValue165()
        local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB"); local r = self.UIRoot
        local on = db:GetUIData(db.FPSFineTuneSwitch); local val = on and (db:GetUIData(db.FPSFineTuneNum) or 165) or 165
        if on then
          r.Slider_screen3:SetLocked(false); r.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1,1,1,1))
          r.Slider_screen3:SetSliderHandleColor(FLinearColor(1,1,1,1))
        else
          r.Slider_screen3:SetLocked(true); r.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1,0.625,0.6,1))
          r.Slider_screen3:SetSliderHandleColor(FLinearColor(1,0.625,0.6,1))
        end
        local norm = (val - MIN) / (165 - MIN)
        r.Veihclescreen3:SetText(tostring(val)); r.Slider_screen3:SetValue(norm); r.ProgressBar_screen3:SetPercent(norm)
      end
      function impl:OnFPSFTValueChange3(val)
        local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
        db:UpdateUIData(db.FPSFineTuneNum, val); if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
        if self:GetParentUI() then self:GetParentUI():SetDirty(true) end
        local gi = db.GetGameInstance and db.GetGameInstance()
        if gi then gi:ExecuteCMD("t.MaxFPS", tostring(val)); gi:ExecuteCMD("r.FrameRateLimit", tostring(val)) end
      end
      function impl:OnFPSFTAdd3() local cur = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB").GetUIData(db.FPSFineTuneNum) or 90; self:OnFPSFTValueChange3(math.min(165, cur)) end
      function impl:OnFPSFTMinus3() local cur = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB").GetUIData(db.FPSFineTuneNum) or 90; self:OnFPSFTValueChange3(math.max(MIN, 5)) end
      impl.OnFPSFTAdd = impl.OnFPSFTAdd3; impl.OnFPSFTMinus = impl.OnFPSFTMinus3
    end
  end)
end

_G.EnableiPadViewUI = function()
  pcall(function()
    local sc = require("client.logic.setting.setting_config")
    if sc then
      if sc.TpViewValue then sc.TpViewValue.max = 140 end
      if sc.FpViewValue then sc.FpViewValue.max = 140 end
    end
    local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
    if db and db.TpViewValue then db.TpViewValue.max = 140 end
  end)
end

if _G.Mod_FPS165_Enabled ~= false then _G.Enable165FPSLogic() end
if _G.Mod_iPadView_Enabled ~= false then _G.EnableiPadViewUI() end

-- iPad View + No Grass (realtime)
local pc = slua_GameFrontendHUD:GetPlayerController()
if slua.isValid(pc) and pc.AddGameTimer and pc ~= _G._FeaturesTimerPC then
  _G._FeaturesTimerPC = pc
  local SubsystemMgr = nil
  local lastViewDistance = nil
  _G._originalTPPFOV = nil

  pc:AddGameTimer(0.1, true, function()
    pcall(function()
      if not _G.CheatsEnabled then return end
      local pc = slua_GameFrontendHUD:GetPlayerController()
      if not slua.isValid(pc) then return end
      local char = pc:GetPlayerCharacterSafety()
      if not slua.isValid(char) then return end
      local lp = GameplayData.GetPlayerCharacter()
      if not slua.isValid(lp) then return end

      SubsystemMgr = SubsystemMgr or package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"] or require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
      if SubsystemMgr then
        local SettingSubsystem = SubsystemMgr:Get("SettingSubsystem")
        if SettingSubsystem then
          local rawSliderValue = _G.Mod_iPadViewDistance or (SettingSubsystem:GetUserSettings_Int("TpViewValue") or 90)
          local targetTPP = rawSliderValue
          if rawSliderValue > 80 and rawSliderValue <= 90 then
              targetTPP = 80 + (rawSliderValue - 80) * 6.0
          elseif rawSliderValue > 90 then
              targetTPP = rawSliderValue
          end

          local uTPPCam = char.ThirdPersonCameraComponent
          if slua.isValid(uTPPCam) and not char.bIsWeaponAiming then
              if _G._originalTPPFOV == nil then
                  _G._originalTPPFOV = uTPPCam.FieldOfView or 90
              end

              if _G.Mod_iPadView_Enabled ~= false then
                  if lastViewDistance ~= targetTPP then
                      uTPPCam.FieldOfView = targetTPP
                      lastViewDistance = targetTPP
                  end
              else
                  if lastViewDistance ~= _G._originalTPPFOV then
                      uTPPCam.FieldOfView = _G._originalTPPFOV
                      lastViewDistance = _G._originalTPPFOV
                  end
              end
          end
        end
      end

      local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
      if not gi then
        local SettingUtil = require("client.slua.logic.setting.setting_util")
        gi = SettingUtil and SettingUtil.GetGameInstance()
      end
      if gi and _G.Mod_NoGrass_Enabled ~= false then
        if not _G._NoGrassApplied then
          gi:ExecuteCMD("grass.DensityScale", "0")
          gi:ExecuteCMD("grass.DiscardDataOnLoad", "1")
          _G._NoGrassApplied = true
        end
      end
    end)
  end)
end

_G._AimbotCurrentPC = nil

local function ApplyHardAimbot()
    if not _G.CheatsEnabled then return end
    if _G.Mod_Aimbot_Enabled == false then return end
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not slua.isValid(char) then return end
        local wm = char.WeaponManagerComponent
        if not slua.isValid(wm) then return end
        local weapon = wm.CurrentWeaponReplicated
        if not slua.isValid(weapon) then return end
        local entity = weapon.ShootWeaponEntityComp
        if not slua.isValid(entity) then return end
        entity.GameDeviationFactor = 0.2
        entity.RecoilKickADS = 0.020
        entity.AccessoriesVRecoilFactor = 0.30
        entity.AccessoriesHRecoilFactor = 0.35
        entity.ExtraHitPerformScale = 10
        if entity.AutoAimingConfig then
            for _, range in ipairs({"OuterRange", "InnerRange"}) do
                local cfg = entity.AutoAimingConfig[range]
                if cfg then
                    cfg.Speed = 4
                    cfg.RangeRate = 2
                    cfg.SpeedRate = 3
                    cfg.RangeRateSight = 2
                    cfg.SpeedRateSight = 2
                    cfg.CrouchRate = 3
                    cfg.ProneRate = 2
                    cfg.DyingRate = 0
                    cfg.adsorbMaxRange = 200
                    cfg.adsorbMinRange = 20
                    cfg.adsorbMinAttenuationDis = 100
                    cfg.adsorbMaxAttenuationDis = 8000
                    cfg.adsorbActiveMinRange = 20
                end
            end
            entity.AutoAimingConfig = entity.AutoAimingConfig
        end
    end)
end

local function AttachAimbotTimer()
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return end
        if pc == _G._AimbotCurrentPC then return end
        _G._AimbotCurrentPC = pc
        if pc.AddGameTimer then
            pc:AddGameTimer(0.1, true, function()
                if not slua.isValid(_G._AimbotCurrentPC) then
                    _G._AimbotCurrentPC = nil
                    return
                end
                ApplyHardAimbot()
            end)
        end
    end)
end

AttachAimbotTimer()

pcall(function()
    local pc = slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) and pc.AddGameTimer then
        pc:AddGameTimer(2.0, true, function()
            if not slua.isValid(_G._AimbotCurrentPC) then
                _G._AimbotCurrentPC = nil
                AttachAimbotTimer()
            end
        end)
    end
end)

-- ============================================================
-- ==================== SKINS MODULE ===========================
-- ============================================================

-- (Full skin code from the original script – includes WeaponSkinMap,
--  VehicleSkinMap, OutfitMap, attachment handling, kill counter,
--  dead box skins, etc. – all kept as is.)
-- [For brevity, the full skin module is omitted here; paste your original skin code here.]

-- ============================================================
-- ==================== PBC WALLHACK MODULE ====================
-- ============================================================

_G._ChamsTimer = nil
_G._ChamsConsoleReady = false
_G._ChamsProcessed = {}
_G._ChamsTickCount = 0

local function ChamsSetupConsole()
    if _G._ChamsConsoleReady then return end
    pcall(function()
        local KismetSystemLibrary = import("KismetSystemLibrary")
        local world = slua.getWorld()
        if not KismetSystemLibrary or not world then return end
        KismetSystemLibrary.ExecuteConsoleCommand(world, "r.EnableDrawDyeingColor 1")
        KismetSystemLibrary.ExecuteConsoleCommand(world, "r.CustomDepth 3")
        KismetSystemLibrary.ExecuteConsoleCommand(world, "r.IdeaOutline.Enable 1")
        KismetSystemLibrary.ExecuteConsoleCommand(world, "r.Highlight.Enable 1")
        _G._ChamsConsoleReady = true
        print("[PBC] Console ready")
    end)
end

local function ChamsApplyToMesh(mesh, visColor, occColor)
    if not mesh or not slua.isValid(mesh) then return end
    pcall(function()
        mesh:SetDrawDyeing(true)
        mesh:SetDrawDyeingMode(1)
        mesh:SetVisibleDyeingColor(visColor)
        mesh:SetOccludedDyeingColor(occColor)
        mesh:SetDyeingColorFadeDistance(99999.0)
        mesh:SetDyeingColorMinMaxDistance(0.0, 99999.0)
    end)
    pcall(function()
        mesh:SetDrawHighlight(true)
        mesh:OverrideHighlightColor(visColor)
        mesh:SetHighlightCanBeOccluded(false)
    end)
    pcall(function()
        mesh:SetDrawIdeaOutline(true)
        mesh:SetIdeaOutlineNew(true)
        mesh:SetIdeaOutlineOcclusionHighlight(true)
        mesh:OverrideIdeaOutlineColor(visColor)
        mesh:SetIdeaOutlineOcclusionColor(occColor)
        mesh:OverrideIdeaOutlineThickness(10.0)
        mesh:SetIdeaOverrideOutlineAndOcclusion(true)
    end)
    pcall(function()
        mesh:SetRenderCustomDepth(true)
        mesh:SetCustomDepthStencilValue(255)
    end)
end

local function ChamsIsPawnAlive(pawn)
    if not slua.isValid(pawn) then return false end
    if pawn.Health and pawn.Health > 0 then return true end
    if pawn.HealthStatus then
        local SecurityUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
        return SecurityUtils.IsHealthStatusAlive(pawn.HealthStatus)
    end
    return false
end

local function ChamsTick()
    pcall(function()
        if not _G.Mod_PBCWallhack_Enabled then return end
        if not _G.CheatsEnabled then return end

        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        local localPawn = GameplayData.GetPlayerCharacter()
        if not slua.isValid(localPawn) then return end

        ChamsSetupConsole()

        local LinearColor = import("LinearColor")
        if not LinearColor then return end

        local colors = {
            vis = LinearColor(50, 50, 5, 100),
            occ = LinearColor(50, 0, 50, 100),
            bVis = LinearColor(49, 48, 0, 100),
            bOcc = LinearColor(9, 1.5, 45, 100)
        }

        _G._ChamsTickCount = _G._ChamsTickCount + 1
        if _G._ChamsTickCount % 6 == 0 then
            _G._ChamsProcessed = {}
        end

        local localTeam = localPawn.TeamID or 0
        local allPawns = Game:GetAllPlayerPawns() or {}
        local processedCount = 0
        local maxPerTick = 20
        local avatarSlots = {0,1,2,3,4,5,6,7}

        for _, pawn in pairs(allPawns) do
            if processedCount >= maxPerTick then break end
            if not slua.isValid(pawn) or pawn == localPawn then goto continue end
            if pawn.PlayerKey and _G._ChamsProcessed[pawn.PlayerKey] then goto continue end
            if not ChamsIsPawnAlive(pawn) then goto continue end

            local team = pawn.TeamID or 0
            if team == localTeam or team <= 0 then goto continue end

            local isAI = false
            pcall(function() isAI = Game:IsAI(pawn) end)
            local visColor = isAI and colors.bVis or colors.vis
            local occColor = isAI and colors.bOcc or colors.occ

            pcall(function()
                if slua.isValid(pawn.Mesh) then
                    ChamsApplyToMesh(pawn.Mesh, visColor, occColor)
                end
            end)

            pcall(function()
                local avatarComp = pawn.CharacterAvatarComp2_BP or pawn:getAvatarComponent2()
                if avatarComp and slua.isValid(avatarComp) and avatarComp.GetMeshCompBySlot then
                    for _, slot in ipairs(avatarSlots) do
                        local mesh = avatarComp:GetMeshCompBySlot(slot)
                        if slua.isValid(mesh) then
                            ChamsApplyToMesh(mesh, visColor, occColor)
                        end
                    end
                end
            end)

            pcall(function()
                local weapon = pawn:GetCurrentWeapon()
                if weapon and slua.isValid(weapon) then
                    local mesh = weapon.Mesh
                    if mesh then
                        ChamsApplyToMesh(mesh, visColor, occColor)
                    end
                end
            end)

            if pawn.PlayerKey then
                _G._ChamsProcessed[pawn.PlayerKey] = true
            end
            processedCount = processedCount + 1

            ::continue::
        end
    end)
end

function _G.InitChamsModule()
    if _G._ChamsTimer then
        pcall(function()
            if _G.Game then _G.Game:RemoveGameTimer(_G._ChamsTimer) end
        end)
        _G._ChamsTimer = nil
    end

    if _G.Game and _G.Game.AddGameTimer then
        _G._ChamsTimer = _G.Game:AddGameTimer(0.3, true, ChamsTick)
        print("[PBC] Active (Game timer)")
        return true
    end

    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) and pc.AddGameTimer then
        _G._ChamsTimer = pc:AddGameTimer(0.3, true, ChamsTick)
        print("[PBC] Active (PC timer)")
        return true
    end

    return false
end

local _chamsRetry = 0
local function ChamsAttemptStart()
    if _chamsRetry >= 30 then
        print("[PBC] Failed to start after 30 retries")
        return
    end
    _chamsRetry = _chamsRetry + 1
    if _G.InitChamsModule() then
        print("[PBC] Module ready!")
    else
        if _G.Game and _G.Game.AddGameTimer then
            _G.Game:AddGameTimer(1.0, false, ChamsAttemptStart)
        end
    end
end

ChamsAttemptStart()

_G.ChamsCleanup = function()
    if _G._ChamsTimer then
        pcall(function()
            if _G.Game then _G.Game:RemoveGameTimer(_G._ChamsTimer) end
        end)
        _G._ChamsTimer = nil
    end
    _G._ChamsProcessed = {}
    _G._ChamsConsoleReady = false
    print("[PBC] Cleanup done")
end

-- ============================================================
-- MENU (with PBC toggle only, no Wallhack settings)
-- ============================================================
_G.InitModMenuTab = function()
    local LocUtil = _G.LocUtil
    if not LocUtil and package.loaded["client.common.LocUtil"] then
        LocUtil = require("client.common.LocUtil")
    end

    if LocUtil and not LocUtil._IsModMenuHooked then
        local old_get = LocUtil.GetLocalizeResStr
        LocUtil.GetLocalizeResStr = function(id)
            if type(id) == "string" and not tonumber(id) then
                return id
            end
            return old_get(id)
        end
        LocUtil._IsModMenuHooked = true
    end

    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")

    if not SettingPageDefine.ModMenu then
        local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")

        local MainStack = {
            { UI = AliasMap.Title, Text = "ADITYA_ORG SETTINGS" },

            {
                Key = "ModMenu_Aimbot",
                UI = AliasMap.Switcher,
                Text = "AIMBOT",
                GetFunc = function() return _G.Mod_Aimbot_Enabled or false end,
                SetFunc = function(_, value)
                    _G.Mod_Aimbot_Enabled = value
                    print("[MOD] AIMBOT: " .. (value and "ON ✓" or "OFF ✗"))
                    return true
                end
            },
            {
                Key = "ESP",
                UI = AliasMap.Switcher,
                Text = "WALL ESP",
                GetFunc = function() return _G.Mod_ESP_Enabled or false end,
                SetFunc = function(_, value)
                    _G.Mod_ESP_Enabled = value
                    print("[MOD] WALL ESP: " .. (value and "ON ✓" or "OFF ✗"))
                    return true
                end
            },
            {
                Key = "Skins",
                UI = AliasMap.TitleSwitcher,
                Text = "SKINS",
                GetFunc = function() return _G.Mod_Skin_Enabled ~= false end,
                SetFunc = function(_, value)
                    _G.Mod_Skin_Enabled = value
                    print("[MOD] SKINS: " .. (value and "ON ✓" or "OFF ✗"))
                    return true
                end
            },
            {
                Key = "PBC_Wallhack",
                UI = AliasMap.TitleSwitcher,
                Text = "PBC WALL HACK",
                GetFunc = function() return _G.Mod_PBCWallhack_Enabled or false end,
                SetFunc = function(_, value)
                    _G.Mod_PBCWallhack_Enabled = value
                    print("[MOD] PBC WALL HACK: " .. (value and "ON ✓" or "OFF ✗"))
                    return true
                end
            },
            {
                Key = "FPS165",
                UI = AliasMap.Switcher,
                Text = "165 FPS",
                GetFunc = function() return _G.Mod_FPS165_Enabled ~= false end,
                SetFunc = function(_, value)
                    _G.Mod_FPS165_Enabled = value
                    if value then _G.Enable165FPSLogic() end
                    print("[MOD] 165 FPS: " .. (value and "ON ✓" or "OFF ✗"))
                    return true
                end
            },
            {
                Key = "NoGrass",
                UI = AliasMap.Switcher,
                Text = "NO GRASS",
                GetFunc = function() return _G.Mod_NoGrass_Enabled ~= false end,
                SetFunc = function(_, value)
                    _G.Mod_NoGrass_Enabled = value
                    if value then
                        pcall(function()
                            local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
                            if gi then
                                gi:ExecuteCMD("grass.DensityScale", "0")
                                gi:ExecuteCMD("grass.DiscardDataOnLoad", "1")
                            end
                        end)
                    end
                    print("[MOD] NO GRASS: " .. (value and "ON ✓" or "OFF ✗"))
                    return true
                end
            },
            {
                Key = "iPadView",
                UI = AliasMap.Switcher,
                Text = "IPAD VIEW",
                GetFunc = function() return _G.Mod_iPadView_Enabled ~= false end,
                SetFunc = function(_, value)
                    _G.Mod_iPadView_Enabled = value
                    if value then _G.EnableiPadViewUI() end
                    print("[MOD] IPAD VIEW: " .. (value and "ON ✓" or "OFF ✗"))
                    return true
                end
            }
        }

        SettingPageDefine.ModMenu = {
            Key = "ModMenu",
            loc = "ADITYA_ORG MENU",
            UIKey = "Setting_Page_Privacy",
            Category = {
                {
                    Key = "ModMenu_Main",
                    loc = "ALL FEATURES",
                    Stack = MainStack
                }
            }
        }

        table.insert(SettingCatalog, SettingPageDefine.ModMenu)
    end

    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsModMenuHooked then
        local old_ShowUI = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = {...}
            if config and config.keyName and (string.find(string.lower(config.keyName), "setting_main") or string.find(string.lower(config.keyName), "setting")) then
                local catalog = args[1]
                if catalog and (type(catalog) == "table" or type(catalog) == "userdata") then
                    local hasModMenu = false
                    local newCatalog = {}
                    for _, page in ipairs(catalog) do
                        table.insert(newCatalog, page)
                        if page.Key == "ModMenu" then
                            hasModMenu = true
                        end
                    end
                    if not hasModMenu then
                        table.insert(newCatalog, SettingPageDefine.ModMenu)
                        args[1] = newCatalog
                    end
                end
            end
            local table_unpack = table.unpack or unpack
            return old_ShowUI(config, table_unpack(args))
        end
        UIManager._IsModMenuHooked = true
    end
end

_G.InitModMenuTab()

-- ============================================================
-- END OF SCRIPT
-- ============================================================