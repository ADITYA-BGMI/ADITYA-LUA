-- ============================================================
-- MODDED BY ADITYA_ORG + @ADITYA_ORG
-- Complete MOD with Bypass V2.0 (14 Modules) + SKINS + PBC WALLHACK
-- All features: Aimbot, ESP, Wallhack, PBC Wallhack, 165 FPS, No Grass, iPad View, SKINS
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
-- FEATURE TOGGLES (updated with ESPConfig)
-- ============================================================
if not _G.Mod_Aimbot_Enabled then _G.Mod_Aimbot_Enabled = false end
if not _G.Mod_ESP_Enabled then _G.Mod_ESP_Enabled = false end
if _G.Mod_Wallhack_Enabled == nil then _G.Mod_Wallhack_Enabled = false end
if _G.Mod_FPS165_Enabled == nil then _G.Mod_FPS165_Enabled = true end
if _G.Mod_NoGrass_Enabled == nil then _G.Mod_NoGrass_Enabled = true end
if _G.Mod_iPadView_Enabled == nil then _G.Mod_iPadView_Enabled = false end
if _G.Mod_iPadViewDistance == nil then _G.Mod_iPadViewDistance = 90 end
if _G.Mod_Skin_Enabled == nil then _G.Mod_Skin_Enabled = false end  -- SKIN TOGGLE
if _G.Mod_PBCWallhack_Enabled == nil then _G.Mod_PBCWallhack_Enabled = false end  -- PBC WALLHACK TOGGLE

-- ============================================================
-- ESP CONFIG (new for wallhack colors/glow/brightness)
-- ============================================================
_G.ESPConfig = _G.ESPConfig or {
    Wallhack = false,
    WallhackVisibleColor = 4,
    WallhackInvisibleColor = 3,
    WallhackBrightness = 25,
    WallhackGlow = 3.0,
    ShowAI = false,
}
_G.Mod_Wallhack_Enabled = _G.ESPConfig.Wallhack

if _G.Mod_Chams_GreenEnabled == nil then _G.Mod_Chams_GreenEnabled = false end
if _G.Mod_Chams_YellowEnabled == nil then _G.Mod_Chams_YellowEnabled = false end
if _G.Mod_Chams_GreenRGB == nil then _G.Mod_Chams_GreenRGB = {R=0, G=255, B=0, A=255} end
if _G.Mod_Chams_YellowRGB == nil then _G.Mod_Chams_YellowRGB = {R=255, G=255, B=0, A=255} end

_G.ESPConfig = _G.ESPConfig or {
    RemoveGrass = false,
}

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

-- ============================================================
-- NOP FUNCTIONS (used by bypass and mod)
-- ============================================================
local function nop() end
local function nopt() return {} end
local function nopnil() return nil end
local function noptrue() return true end
local function nopfalse() return false end
local function nopstr() return "" end
_G.CheatsEnabled = true

local function safe_require(path)
    local ok, mod = pcall(require, path)
    return ok and mod or nil
end

local ok_gd, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
if not ok_gd then GameplayData = nil end

-- ============================================================
-- MODULE 1: DOMAIN BLOCKER (HTTP + SOCKET + WEBVIEW)
-- ============================================================
local blockedDomains = {
    "tss.tencent","syzsdk","gcloud.qq","reportlog","tdos","logupload","feedback.wh","crash2",
    "privacy.qq","privacy.tencent","oth.eve","mdt.qq","act.tencentyun","analytics","report.qq",
    "anticheatexpert","crashsight","wetest","log.tav","sngd","tracer","intlsdk","igamecj",
    "cdn.club","gpubgm","graph.facebook","calendarpushsubscription","googleads","doubleclick",
    "firebaselogging","firebaseremoteconfig","fonts.googleapis","abs.twimg","dl.listdl",
    "igame.gcloudcs","bugly","beacon","helpshift","tdm","apm","safeguard","weiyun","qzone",
    "tencent-cloud","myapp","idqqimg","gtimg","qqmail","tcdn","cloudctrl","sdkostrace",
    "103.134.189.146","mbgame","csoversea","igame","pubgmobile","down.anticheatexpert.com",
    "asia.csoversea.mbgame.anticheatexpert.com","log.tav.qq","syzsdk.qq","logiservice.qcloud",
    "opensdk.tencent","exp.helpshift","loginsdkapi.zingplay","firebase","googleapis","facebook","gvoice"
}

local function InitDomainBlocker()
    pcall(function()
        if package.loaded["client.network.http.HttpClient"] then
            local hc = package.loaded["client.network.http.HttpClient"]
            if hc and hc.SendRequest then
                local orig = hc.SendRequest
                hc.SendRequest = function(self, url, cb, method, headers, content, timeout)
                    for _, host in ipairs(blockedDomains) do
                        if url and string.find(string.lower(url), string.lower(host)) then
                            return nil
                        end
                    end
                    return orig(self, url, cb, method, headers, content, timeout)
                end
            end
        end
        if NetUtil and NetUtil.SendHttpRequest then
            local orig = NetUtil.SendHttpRequest
            NetUtil.SendHttpRequest = function(url, cb, method, headers, content)
                for _, host in ipairs(blockedDomains) do
                    if url and string.find(string.lower(url), string.lower(host)) then
                        return nil
                    end
                end
                return orig(url, cb, method, headers, content)
            end
        end
        local wv = package.loaded["client.slua.logic.url.logic_webview_sdk"]
        if wv and wv.OpenURL then
            local orig = wv.OpenURL
            wv.OpenURL = function(url)
                for _, host in ipairs(blockedDomains) do
                    if url and string.find(string.lower(url), string.lower(host)) then
                        return nil
                    end
                end
                return orig(url)
            end
        end
        if socket and socket.connect then
            local orig = socket.connect
            socket.connect = function(host, port, timeout)
                for _, blocked in ipairs(blockedDomains) do
                    if host and string.find(string.lower(host), string.lower(blocked)) then
                        return nil, "blocked"
                    end
                end
                return orig(host, port, timeout)
            end
        end
    end)
end

-- ============================================================
-- MODULE 2: SKIN BYPASS
-- ============================================================
local function InitSkinBypass()
    pcall(function()
        local puf = package.loaded["client.slua.logic.download.report.puffer_tlog"]
        if puf then
            puf.ReportEvent = nop
            puf.ReportDownloadResult = nop
            puf.ReportODPTDError = nop
        end
        local au = package.loaded["AvatarUtils"]
        if au then
            au.CheckIsWeaponInBlackList = nopfalse
            au.IsValidAvatar = noptrue
        end
        local sm = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        local fcs = sm and sm:Get("FileCheckSubsystem")
        if fcs then
            fcs.StartCheck = nop
            fcs.ReportAbnormalFile = nop
        end
        local ee = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
        if ee then
            ee.Report = nop
        end
    end)
end

-- ============================================================
-- MODULE 3: TSS + SDK BLOCKER
-- ============================================================
local function InitTssBlocker()
    pcall(function()
        local tss = package.loaded["TssSdk"] or _G.TssSdk
        if tss then
            if tss.OnRecvData then tss.OnRecvData = nop end
            if tss.SendReportInfo then tss.SendReportInfo = nop end
            if tss.ReportData then tss.ReportData = nop end
            tss.ScanMemory = noptrue
            tss.IsEmulator = nopfalse
            tss.GetTssSdkReportInfo = nopstr
        end
        local beacon = package.loaded["BeaconSDK"] or _G.BeaconSDK
        if beacon then
            beacon.Report = nop
            beacon.ReportEvent = nop
            beacon.ReportData = nop
        end
        local bugly = package.loaded["BuglySDK"] or _G.BuglySDK
        if bugly then
            bugly.ReportException = nop
            bugly.ReportError = nop
            bugly.SetUserData = nop
        end
        local helpshift = package.loaded["HelpShift"] or _G.HelpShift
        if helpshift then
            helpshift.Report = nop
            helpshift.SendFeedback = nop
            helpshift.ReportUser = nop
        end
    end)
end

-- ============================================================
-- MODULE 4: LOG BLOCKER
-- ============================================================
local function InitLogBlocker()
    pcall(function()
        local ssm = import("ScreenshotMTDer")
        if ssm then
            ssm.MTDePicture = nopstr
            ssm.ReMTDePicture = nopstr
            ssm.HasCaptured = noptrue
        end
        local tlog = package.loaded["TLog"] or _G.TLog
        if tlog then
            for _, f in ipairs({"Info","Warning","Error","Debug","Report"}) do
                if tlog[f] then tlog[f] = nop end
            end
        end
        local cs = package.loaded["CrashSight"] or _G.CrashSight
        if cs then
            cs.ReportException = nop
            cs.SetCustomData = nop
            cs.Log = nop
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
            ctr.SendReport = nop
            ctr.SendException = nop
        end
        local tru = package.loaded["client.slua.config.tlog.tlog_report_utils"]
        if tru then
            tru.ReportTLogEvent = nop
        end
    end)
end

-- ============================================================
-- MODULE 5: SCANNER BLOCKER
-- ============================================================
local function InitScannerBlocker()
    pcall(function()
        local sm = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if sm then
            local afk = sm:Get("AFKReportorSubsystem")
            if afk then
                afk.PlayerHaveAction = nop
                afk.ReportAFK = nop
            end
            local ds = sm:Get("ClientDataStatistcsSubsystem")
            if ds then
                ds.StartToCheck = nop
                ds.DelayCount = 0
                if ds.ReportPingDelayTimer then
                    ds:RemoveGameTimer(ds.ReportPingDelayTimer)
                    ds.ReportPingDelayTimer = nil
                end
            end
            local ae = sm:Get("AvatarExceptionSubsystem")
            if ae then
                ae.ReportException = nop
                ae.BindPlayerCharacter = nop
                ae.CheckAvatarValid = noptrue
            end
            local sv = sm:Get("ShootVerifySubSystemClient")
            if sv then
                sv.ReportVerifyFail = nop
                sv.OnVerifyFailed = nop
            end
        end
        local cmbl = import("CreativeModeBlueprintLibrary")
        if cmbl then
            cmbl.MD5HashByteArray = function() return "BYPASSED" end
            cmbl.GetContentDiffData = function() return true, "BYPASSED" end
        end
        local aepi = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
        if aepi then
            aepi.CheckAvatarException = nop
            aepi.CheckAvatarExceptionOnce = nop
            aepi.ReportAvatarException = nop
            aepi.CheckSlotMeshVisible = nopfalse
            aepi.CheckPawnVisible = nopfalse
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

-- ============================================================
-- MODULE 6: REPLAY TELEMETRY BLOCKER
-- ============================================================
local function InitReplayBlocker()
    pcall(function()
        local sm = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if sm then
            local rbrt = sm:Get("RescueBtnReplayTraceSubsystem")
            if rbrt then
                rbrt.ReportTrace = nop
                rbrt.StartTickMonitor = nop
                rbrt.TickMonitorCheck = nop
                rbrt.ReportTickMonitorHeartbeat = nop
            end
            local grs = sm:Get("GameReportSubsystem")
            if grs then
                grs.ReplayReportData = nopfalse
                grs.CheckCanBugglyPostException = nopfalse
                grs.BugglyPostExceptionFull = nopfalse
                grs.GetClientReplayDataReporter = nopnil
                if grs.Reporter then
                    for _, f in ipairs({"ReportIntArrayData","ReportUInt8ArrayData","ReportFloatArrayData"}) do
                        if grs.Reporter[f] then grs.Reporter[f] = nop end
                    end
                end
            end
        end
        local lrr = package.loaded["client.slua.logic.replay.logic_report_replay"]
        if lrr then
            lrr.ReportReplay = nop
            lrr.SendReportReq = nop
        end
        local lhr = package.loaded["client.slua.logic.home.logic_home_report"]
        if lhr then
            lhr.ShowInGameReportUI = nop
            lhr.SendReport = nop
        end
    end)
end

-- ============================================================
-- MODULE 7: ANTI-REPORT SYSTEM
-- ============================================================
local function InitAntiReport()
    pcall(function()
        local paths = {
            "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem",
            "Client.Security.ClientReportPlayerSubsystem"
        }
        local crp = nil
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
            local funcs = {
                "OnInit","_OnPlayerKilledOtherPlayer","_RecordFatalDamager",
                "_OnDeathReplayDataWhenFatalDamaged","_RecordMurdererFromDeathReplayData",
                "_RecordTeammatePlayerInfo","_OnBattleResult",
                "_OnShowQuickReportMutualExclusiveUI"
            }
            for _, f in ipairs(funcs) do
                if crp[f] then crp[f] = nop end
            end
            crp.GetFatalDamagerMap = nopt
            crp.GetCachedTeammateName2InfoMap = nopt
            crp.GetTeammateName2InfoMapDuringBattle = nopt
            crp.GetCurrentNotInTeamHistoricalTeammateMap = nopt
            crp.GetInTeamIndexFromHistoricalTeammateInfo = function() return -1 end
        end
    end)
end

-- ============================================================
-- MODULE 8: GAMEPLAY BYPASS (DS State + Network Packets)
-- ============================================================
local function InitGameplayBypass()
    pcall(function()
        if _G.GameplayCallbacks and not _G.GameplayCallbacks.IsBypassed then
            local GC = _G.GameplayCallbacks
            local orig = GC.OnDSPlayerStateChanged
            GC.OnDSPlayerStateChanged = function(uid, state, ...)
                if state and string.lower(tostring(state)) == "cheatdetected" then
                    return
                end
                if orig then
                    return orig(uid, state, ...)
                end
            end
            local blocklist = {
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
            for _, f in ipairs(blocklist) do
                if GC[f] then GC[f] = nop end
            end
            GC.GetWeaponReport = nopt
            GC.GetOneWeaponReport = nopt
            GC.GetGeneralTLogData = nopnil
            GC.IsBypassed = true
        end
        if NetUtil and NetUtil.SendPacket and not NetUtil.IsBypassed then
            local orig = NetUtil.SendPacket
            local bp = {
                ReportAttackFlow=1, ReportSecAttackFlow=1, ReportHurtFlow=1,
                ReportFireArms=1, ReportVerifyInfoFlow=1, ReportMrpcsFlow=1,
                ReportPlayerBehavior=1, ReportTeammatHurt=1,
                on_tss_sdk_anti_data=1, report_parachute_data=1,
                ReportAimFlow=1, ReportHitFlow=1,
                ReportCircleFlow=1, ReportJumpFlow=1,
                ReportGameStartFlow=1, ReportGameEndFlow=1,
                report_players_ping=1, report_player_ip=1,
                tss_sdk_report=1, report_memory_exception=1,
                report_avatar_exception=1
            }
            NetUtil.SendPacket = function(n, ...)
                if bp[n] then return end
                return orig(n, ...)
            end
            NetUtil.IsBypassed = true
        end
    end)
end

-- ============================================================
-- MODULE 9: CONNECTION GUARD
-- ============================================================
local function InitConnectionGuard()
    pcall(function()
        if _G.ConnectionGuardInitialized or not _G.GameplayCallbacks then
            return
        end
        local GC = _G.GameplayCallbacks
        local orig = GC.OnDSPlayerStateChanged
        local blockedStates = {
            cheatdetected = true,
            connectionlost = true,
            connectiontimeout = true,
            connectionexception = true,
            netdrivererror = true
        }
        GC.OnDSPlayerStateChanged = function(uid, state, ...)
            local s = state and string.lower(tostring(state)) or ""
            if blockedStates[s] then return end
            if orig then pcall(orig, uid, state, ...) end
        end
        GC.OnPlayerNetConnectionClosed = nop
        GC.OnPlayerActorChannelError = nop
        GC.OnPlayerRPCValidateFailed = nop
        GC.OnPlayerSpectateException = nop
        GC.OnShutdownAfterError = nop
        _G.ConnectionGuardInitialized = true
    end)
end

-- ============================================================
-- MODULE 10: HIGGS BOSON DISABLER
-- ============================================================
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
            if hbc.StaticShowSecurityAlertInDev then
                hbc.StaticShowSecurityAlertInDev = nop
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
        _G.BlackList = {}
        if _G.GameSafeCallbacks then
            if _G.GameSafeCallbacks.RecordStrategyTimestampInReplay then
                _G.GameSafeCallbacks.RecordStrategyTimestampInReplay = nop
            end
            _G.GameSafeCallbacks.DoAttackFlowStrategy = nop
            _G.GameSafeCallbacks.GetScriptReportContent = nopstr
        end
        local stebp = import("STExtraBlueprintFunctionLibrary")
        if stebp then
            stebp.IsDevelopment = nopfalse
        end
    end)
end

-- ============================================================
-- MODULE 11: ZR/PR BYPASSES
-- ============================================================
local function InitZRPRBypasses()
    pcall(function()
        local STExtraLib = import("STExtraBlueprintFunctionLibrary")
        if STExtraLib then
            STExtraLib.IsDevelopment = noptrue
        end
        local hiaPath = "GameLua.Mod.BaseMod.Client.Security.ClientGlueHiaSystem"
        local hia = package.loaded[hiaPath] or require(hiaPath)
        if hia then
            hia.CheckHitIntegrity = noptrue
        end
        local securityPath = "GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature"
        local security = package.loaded[securityPath] or require(securityPath)
        if security then
            security.ClientRPC_SyncBanID = nop
            security.ClientRPC_StrongTips = nop
            security.ClientRPC_NormalTips = nop
        end
        local dsFightPath = "GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem"
        local dsFight = package.loaded[dsFightPath] or require(dsFightPath)
        if dsFight then
            dsFight.GetSimpleFightData = nopt
        end
        local dsReportPath = "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem"
        local dsReport = package.loaded[dsReportPath] or require(dsReportPath)
        if dsReport then
            dsReport._AddEnemyMapToBattleResult = nop
        end
    end)
end

-- ============================================================
-- MODULE 12: MEMORY BYPASS
-- ============================================================
local function InitMemoryBypass()
    pcall(function()
        if not _G.old_print then
            _G.old_print = print
            print = nop
        end
        local function pmt(t)
            if not t then return end
            local mt = getmetatable(t) or {}
            mt.__metatable = "protected"
            setmetatable(t, mt)
        end
        pmt(_G)
        pmt(debug)
    end)
end

-- ============================================================
-- MODULE 13: INTEGRITY OVERRIDES
-- ============================================================
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
                if package.loaded[mn] then
                    local m = package.loaded[mn]
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

-- ============================================================
-- INITIALIZE ALL BYPASSES (AUTO-RUN on game start)
-- ============================================================
local function InitAllBypasses()
    if _G.Bypassed then return end
    pcall(function()
        print("[BYPASS V2.0] Starting All Bypasses...")
        InitDomainBlocker()
        InitSkinBypass()
        InitTssBlocker()
        InitLogBlocker()
        InitScannerBlocker()
        InitReplayBlocker()
        InitAntiReport()
        InitGameplayBypass()
        InitConnectionGuard()
        InitHiggsBoson()
        InitZRPRBypasses()
        InitMemoryBypass()
        InitIntegrityOverrides()
        _G.Bypassed = true
        print("[BYPASS V2.0] All 14 Bypasses Activated Successfully! - @ADITYA_ORG")
    end)
end

-- ============================================================
-- RUN BYPASS IMMEDIATELY (on script load)
-- ============================================================
InitAllBypasses()

-- ============================================================
-- WELCOME POP-UP (replaces the old bypass popup)
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
        "★ Bypass    : 5-Layer Deep Shield + All Visuals\n\n" ..
        "✓ Premium Build Loaded Successfully!", onClick)
    end
end)

-- ============================================================
-- STANDALONE WALLHACK (ZeroX6T style) - NOW WITH CUSTOM COLORS
-- ============================================================

-- Helper to convert color number to RGB table
local function GetColorFromIndex(idx)
    local colors = {
        {R=255,G=0,B=0},   -- 1 Red
        {R=255,G=255,B=255}, -- 2 White
        {R=255,G=255,B=0}, -- 3 Yellow
        {R=0,G=255,B=0},   -- 4 Green
        {R=0,G=255,B=255}, -- 5 Cyan
        {R=0,G=0,B=255},   -- 6 Blue
        {R=255,G=0,B=255}, -- 7 Purple
    }
    return colors[idx] or colors[4]
end

local function ApplyWallHack()
    if not _G.CheatsEnabled then return end
    if not _G.ESPConfig.Wallhack then return end

    local localPlayer = GameplayData and GameplayData.GetPlayerCharacter()
    if not localPlayer or not slua.isValid(localPlayer) then return end

    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not pc or not slua.isValid(pc) then return end

    local myTeam = localPlayer.TeamID or 0
    local allCharacters = Game:GetAllPlayerPawns()
    if not allCharacters then return end

    local cfg = _G.ESPConfig
    local brightnessFactor = cfg.WallhackBrightness / 25.0
    local glowIntensity = cfg.WallhackGlow

    for _, enemy in pairs(allCharacters) do
        if slua.isValid(enemy) and enemy ~= localPlayer then
            local targetTeam = enemy.TeamID or 0
            if targetTeam == myTeam then goto continue end

            local isAlive = false
            pcall(function() isAlive = enemy:IsAlive() end)
            if not isAlive then goto continue end

            if not cfg.ShowAI then
                local isBot = false
                pcall(function() isBot = Game:IsAI(enemy) end)
                if isBot then goto continue end
            end

            local meshes = {}
            if slua.isValid(enemy.Mesh) then
                table.insert(meshes, enemy.Mesh)
            end
            local SkelClass = import("SkeletalMeshComponent")
            if SkelClass then
                local childs = enemy:GetComponentsByClass(SkelClass)
                if childs then
                    local count = type(childs.Num) == "function" and childs:Num() or #childs
                    for c = 1, count do
                        local comp = type(childs.Get) == "function" and childs:Get(c-1) or childs[c]
                        if slua.isValid(comp) and comp ~= enemy.Mesh then
                            table.insert(meshes, comp)
                        end
                    end
                end
            end

            local isVisible = false
            if slua.isValid(pc) and type(pc.LineOfSightTo) == "function" then
                pcall(function() isVisible = pc:LineOfSightTo(enemy) end)
            end

            local colorIdx = isVisible and cfg.WallhackVisibleColor or cfg.WallhackInvisibleColor
            local baseColor = GetColorFromIndex(colorIdx)
            local finalColor = {
                R = math.min(255, math.floor(baseColor.R * brightnessFactor)),
                G = math.min(255, math.floor(baseColor.G * brightnessFactor)),
                B = math.min(255, math.floor(baseColor.B * brightnessFactor)),
                A = 255
            }
            local glowVec = {R=glowIntensity*255, G=glowIntensity*255, B=glowIntensity*255, A=0}

            enemy._WH_MIDs = enemy._WH_MIDs or {}
            for _, comp in ipairs(meshes) do
                if slua.isValid(comp) then
                    local ok, mat = pcall(function() return comp:GetMaterial(0) end)
                    if ok and slua.isValid(mat) then
                        local ok2, base = pcall(function() return mat:GetBaseMaterial() end)
                        if ok2 and slua.isValid(base) then
                            base.bDisableDepthTest = true
                            base.BlendMode = 2
                        end
                    end
                    comp.UseScopeDistanceCulling = false
                    comp.PrimitiveShadingStrategy = 1
                    comp.ShadingRate = 6

                    local ck = tostring(comp)
                    enemy._WH_MIDs[ck] = enemy._WH_MIDs[ck] or {}
                    for i = 0, 10 do
                        local ok3, mi = pcall(function() return comp:GetMaterial(i) end)
                        if not ok3 or not slua.isValid(mi) then break end
                        local mid = enemy._WH_MIDs[ck][i]
                        if not slua.isValid(mid) then
                            local ok4, nm = pcall(function() return comp:CreateAndSetMaterialInstanceDynamic(i) end)
                            if ok4 and slua.isValid(nm) then
                                enemy._WH_MIDs[ck][i] = nm
                                mid = nm
                            end
                        end
                        if slua.isValid(mid) then
                            pcall(function()
                                mid:SetVectorParameterValue("颜色", finalColor)
                                mid:SetVectorParameterValue("Color", finalColor)
                                mid:SetVectorParameterValue("BaseColor", finalColor)
                                mid:SetVectorParameterValue("BodyColor", finalColor)
                                mid:SetVectorParameterValue("DiffuseColor", finalColor)
                                mid:SetScalarParameterValue("EmissiveIntensity", glowIntensity)
                                mid:SetScalarParameterValue("GlowIntensity", glowIntensity)
                                mid:SetScalarParameterValue("EmissiveScale", glowIntensity)
                                mid:SetVectorParameterValue("EmissiveColor", {R=finalColor.R*glowIntensity, G=finalColor.G*glowIntensity, B=finalColor.B*glowIntensity, A=255})
                                mid:SetVectorParameterValue("ParaScaleOffset", glowVec)
                            end)
                        end
                    end
                end
            end
        end
        ::continue::
    end
end

local function StartWallhackTimer()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) and pc.AddGameTimer then
        if _G._WallhackTimer then
            pcall(function() pc:RemoveGameTimer(_G._WallhackTimer) end)
        end
        _G._WallhackTimer = pc:AddGameTimer(0.1, true, function()
            pcall(ApplyWallHack)
        end)
    end
end

pcall(function()
    StartWallhackTimer()
end)

pcall(function()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) and pc.AddGameTimer then
        pc:AddGameTimer(2.0, true, function()
            if not _G._WallhackTimer then
                StartWallhackTimer()
            end
        end)
    end
end)

-- ============================================================
-- ESP (unchanged)
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
                                if _G.Mod_Chams_GreenEnabled then
                                    nameColor = _G.Mod_Chams_GreenRGB or {R=0,G=255,B=0,A=255}
                                else
                                    nameColor = {R=0,G=255,B=0,A=255}
                                end
                            else
                                if _G.Mod_Chams_YellowEnabled then
                                    nameColor = _G.Mod_Chams_YellowRGB or {R=255,G=255,B=0,A=255}
                                else
                                    nameColor = {R=255,G=255,B=0,A=255}
                                end
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
-- AIMBOT + FEATURES
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
        entity.WeaponAimInTime = 20
        entity.SwitchFromIdleToBackpackTime = 0.15
        entity.SwitchFromBackpackToIdleTime = 0.15
        entity.ShotGunHorizontalSpread = 0.0
        entity.ShotGunVerticalSpread = 0.0
        entity.RecoilKickADS = 0.020
        entity.AccessoriesVRecoilFactor = 0.30
        entity.AccessoriesHRecoilFactor = 0.35
        entity.ExtraHitPerformScale = 10
        if entity.RecoilInfo then
            entity.RecoilInfo.VerticalRecoilMin = 0.2
            entity.RecoilInfo.VerticalRecoilMax = 0.5
            entity.RecoilInfo.RecoilSpeedVertical = 0.2
            entity.RecoilInfo.RecoilSpeedHorizontal = 0.15
            entity.RecoilInfo.VerticalRecoveryMax = 0.2
        end
        entity.RecoilModifierStand = 0.1
        entity.RecoilModifierCrouch = 0.1
        entity.RecoilModifierProne = 0.1
        if entity.AutoAimingConfig then
            for _, range in ipairs({"OuterRange", "InnerRange"}) do
                local cfg = entity.AutoAimingConfig[range]
                if cfg then
                    cfg.Speed = 8
                    cfg.RangeRate = 5
                    cfg.SpeedRate = 5
                    cfg.RangeRateSight = 4
                    cfg.SpeedRateSight = 4
                    cfg.CrouchRate = 4
                    cfg.ProneRate = 4
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
        pcall(function()
            local aimComp = char.BP_AutoAimingComponent_C
                         or char.BP_AutoAimingComponent
                         or char.AutoAimingComponent
            if slua.isValid(aimComp) and aimComp.Bones then
                pcall(function() aimComp.Bones[0] = "neck_01" end)
                pcall(function() aimComp.Bones[1] = "neck_01" end)
                pcall(function() aimComp.Bones[2] = "neck_01" end)
                pcall(function() aimComp.Bones:Set(0, "neck_01") end)
                pcall(function() aimComp.Bones:Set(1, "neck_01") end)
                pcall(function() aimComp.Bones:Set(2, "neck_01") end)
            end
        end)
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

local function sk_safe_require(path)
    local ok, mod = pcall(require, path)
    return ok and mod or nil
end

local BASE_PATH       = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"
local CONFIG_PATH     = BASE_PATH .. "config.ini"
local SAVE_KILL_PATH  = BASE_PATH .. "kill_counts.txt"
local ATTACH_PATH     = BASE_PATH .. "attachments.txt"

_G.WeaponSkinMap        = _G.WeaponSkinMap        or {}
_G.VehicleSkinMap       = _G.VehicleSkinMap        or {}
_G.OutfitMap            = _G.OutfitMap             or {}
_G.AttachmentOverrideMap= _G.AttachmentOverrideMap  or {}
_G.SkinAttachments      = _G.SkinAttachments        or {}
_G.SkinLoadedCache      = _G.SkinLoadedCache        or {}
_G.FakeKillCounts       = _G.FakeKillCounts         or {}
_G.LastEquippedOutfits  = _G.LastEquippedOutfits    or {}
_G.g_parts              = _G.g_parts               or {}
_G.skinAttachCache      = _G.skinAttachCache        or {}
_G.KillData             = _G.KillData              or { kills = {} }
_G.DeadBoxSkins         = _G.DeadBoxSkins          or {}
_G.AlreadyChangedSet    = _G.AlreadyChangedSet      or {}
_G.CurrentEquipVehicleID= _G.CurrentEquipVehicleID  or 0

local function SaveKillsToFile()
    pcall(function()
        local file = io.open(SAVE_KILL_PATH, "w")
        if file then
            for id, count in pairs(_G.KillData.kills) do
                file:write(string.format("%d:%d\n", id, count))
            end
            file:close()
        end
    end)
end

local function LoadKillsFromFile()
    pcall(function()
        local file = io.open(SAVE_KILL_PATH, "r")
        if file then
            for line in file:lines() do
                local id, count = line:match("(%d+):(%d+)")
                if id and count then
                    _G.KillData.kills[tonumber(id)] = tonumber(count)
                end
            end
            file:close()
        end
    end)
end

_G.getKills = function(weaponID) return _G.KillData.kills[weaponID] or 0 end

_G.AddKill = function(weaponID)
    if not weaponID then return end
    _G.KillData.kills[weaponID] = (_G.KillData.kills[weaponID] or 0) + 1
    _G._KillSaveDirty = (_G._KillSaveDirty or 0) + 1
    if _G._KillSaveDirty >= 3 then
        SaveKillsToFile()
        _G._KillSaveDirty = 0
    end
    pcall(function()
        local UIM = require("client.slua_ui_framework.manager")
        local MKC = UIM.GetUI(UIM.UI_Config_InGame.MainKillCounter)
        if MKC then
            if MKC.OnRefreshData then
                MKC:OnRefreshData()
            end
            if MKC.KillCounterItem and MKC.KillCounterItem.SetKillCounterItemShowWithNum then
                local sid = _G.get_skin_id(weaponID) or weaponID
                MKC.KillCounterItem:SetKillCounterItemShowWithNum(sid, _G.KillData.kills[weaponID], sid)
            end
        end
    end)
end

LoadKillsFromFile()

_G.get_skin_id = function(weaponID)
    if not weaponID or weaponID == 0 then return nil end
    local mapped = _G.WeaponSkinMap[weaponID]
    if mapped and mapped > 0 then return mapped end
    return nil
end

_G.download_item = function(i)
    if not i then return end
    pcall(function()
        local PM = require("client.slua.logic.download.puffer.puffer_manager")
        local PC = require("client.slua.logic.download.puffer_const")
        if PM.GetState(PC.ENUM_DownloadType.ODPAK, {i}) ~= PC.ENUM_DownloadState.Done then
            PM.Download(PC.ENUM_DownloadType.ODPAK, {i})
        end
    end)
end

local ATTACH_NAME_MAP = {
    ["Red Dot Sight"]          = "RedDot",
    ["Holographic Sight"]      = "Holo",
    ["2x Scope"]               = "Scope2x",
    ["3x Scope"]               = "Scope3x",
    ["4x Scope"]               = "Scope4x",
    ["6x Scope"]               = "Scope6x",
    ["8x Scope"]               = "Scope8x",
    ["Canted Sight"]           = "CantedSight",
    ["Flash Hider"]            = "FlashHider",
    ["Compensator"]            = "Compensator",
    ["Suppressor"]             = "Suppressor",
    ["Extended Mag"]           = "ExtMag",
    ["Quickdraw Mag"]          = "QuickMag",
    ["Extended Quickdraw Mag"] = "ExtQuickMag",
    ["Angled Foregrip"]        = "AngledGrip",
    ["Vertical Foregrip"]      = "VerticalGrip",
    ["Thumb Grip"]             = "ThumbGrip",
    ["Half Grip"]              = "HalfGrip",
    ["Light Grip"]             = "LightGrip",
    ["Laser Sight"]            = "LaserSight",
    ["Tactical Stock"]         = "TactStock",
    ["Stock"]                  = "MicroStock",
    ["Cheek Pad"]              = "CheekPad",
}

local _attachFileCache = nil

local function _parseAttachmentsFile()
    local result = {}
    pcall(function()
        local f = io.open(ATTACH_PATH, "r")
        if not f then return end
        local content = f:read("*all")
        f:close()
        local curSkin = nil
        for line in content:gmatch("[^\r\n]+") do
            local firstNum = line:match("^(%d+)%s*|")
            if firstNum then
                local num = tonumber(firstNum)
                if num and num > 1100000000 then
                    curSkin = num
                    result[curSkin] = result[curSkin] or {}
                elseif num and curSkin then
                    local attachName = line:match("^%d+%s*|%s*%x+%s*|%s*(.-)%s*$")
                    if not attachName then attachName = line:match("^%d+%s*|%s*(.-)%s*$") end
                    if attachName and attachName ~= "" then
                        local key = ATTACH_NAME_MAP[attachName]
                        if key then result[curSkin][key] = num end
                    end
                end
            elseif line:find("^#%-%-%-%-") and line:find("skin") then
                curSkin = nil
            end
        end
    end)
    return result
end

_G.GetAttachForSkin = function(skinId, key)
    if not skinId or skinId == 0 or not key then return nil end
    if not _attachFileCache then _attachFileCache = _parseAttachmentsFile() end
    local t = _attachFileCache[skinId]
    if not t then return nil end
    local v = t[key]
    return (v and v > 0) and v or nil
end

_G.GetAttachFileCache = function()
    if not _attachFileCache then _attachFileCache = _parseAttachmentsFile() end
    return _attachFileCache
end

local function ReadLiveConfig()
    pcall(function()
        local f = io.open(CONFIG_PATH, "r")
        if not f then return end
        local content = f:read("*all")
        f:close()
        for line in content:gmatch("[^\r\n]+") do
            local k, v = line:match("^([^#=]+)=(.+)$")
            if k and v then
                k = k:gsub("^%s+", ""):gsub("%s+$", "")
                if k == "cheats" then
                    _G.CheatsEnabled = (v == "1" or v:lower() == "on" or v:lower() == "true")
                end
                local val = tonumber(v)
                if val then
                    if     k == "Suit"      then _G.OutfitMap.Suit      = val
                    elseif k == "Hat"       then _G.OutfitMap.Hat       = val
                    elseif k == "Mask"      then _G.OutfitMap.Mask      = val
                    elseif k == "Glasses"   then _G.OutfitMap.Glasses   = val
                    elseif k == "Pants"     then _G.OutfitMap.Pants     = val
                    elseif k == "Shoes"     then _G.OutfitMap.Shoes     = val
                    elseif k == "Bag"       then _G.OutfitMap.Bag       = val
                    elseif k == "Helmet"    then _G.OutfitMap.Helmet    = val
                    elseif k == "Armor"     then _G.OutfitMap.Armor     = val
                    elseif k == "Parachute" then _G.OutfitMap.Parachute = val
                    elseif k == "Pet"       then _G.OutfitMap.Pet       = val
                    elseif k == "M416"    then _G.WeaponSkinMap[101004] = val
                    elseif k == "AKM"     then _G.WeaponSkinMap[101001] = val
                    elseif k == "SCAR"    then _G.WeaponSkinMap[101003] = val
                    elseif k == "UMP"     then _G.WeaponSkinMap[102002] = val
                    elseif k == "M762"    then _G.WeaponSkinMap[101008] = val
                    elseif k == "AUG"     then _G.WeaponSkinMap[101006] = val
                    elseif k == "ASM"     then _G.WeaponSkinMap[101101] = val
                    elseif k == "ACE32"   then _G.WeaponSkinMap[101102] = val
                    elseif k == "HoneyBadger" then _G.WeaponSkinMap[101012] = val
                    elseif k == "M24"     then _G.WeaponSkinMap[103002] = val
                    elseif k == "AWM"     then _G.WeaponSkinMap[103003] = val
                    elseif k == "Kar98"   then _G.WeaponSkinMap[103001] = val
                    elseif k == "M16A4"   then _G.WeaponSkinMap[101002] = val
                    elseif k == "GROZA"   then _G.WeaponSkinMap[101005] = val
                    elseif k == "QBZ"     then _G.WeaponSkinMap[101007] = val
                    elseif k == "MK47"    then _G.WeaponSkinMap[101009] = val
                    elseif k == "G36C"    then _G.WeaponSkinMap[101010] = val
                    elseif k == "FAMAS"   then _G.WeaponSkinMap[101100] = val
                    elseif k == "VSS"     then _G.WeaponSkinMap[103005] = val
                    elseif k == "Mini14"  then _G.WeaponSkinMap[103006] = val
                    elseif k == "MK14"    then _G.WeaponSkinMap[103007] = val
                    elseif k == "SLR"     then _G.WeaponSkinMap[103009] = val
                    elseif k == "QBU"     then _G.WeaponSkinMap[103010] = val
                    elseif k == "MK12"    then _G.WeaponSkinMap[103100] = val
                    elseif k == "AMR"     then _G.WeaponSkinMap[103012] = val
                    elseif k == "DSR"     then _G.WeaponSkinMap[103102] = val
                    elseif k == "Mosin"   then _G.WeaponSkinMap[103013] = val
                    elseif k == "SKS"     then _G.WeaponSkinMap[103004] = val
                    elseif k == "UZI"     then _G.WeaponSkinMap[102001] = val
                    elseif k == "Vector"  then _G.WeaponSkinMap[102003] = val
                    elseif k == "Thompson"then _G.WeaponSkinMap[102004] = val
                    elseif k == "Bizon"   then _G.WeaponSkinMap[102005] = val
                    elseif k == "MP5K"    then _G.WeaponSkinMap[102007] = val
                    elseif k == "P90"     then _G.WeaponSkinMap[102105] = val
                    elseif k == "S12K"    then _G.WeaponSkinMap[104003] = val
                    elseif k == "DBS"     then _G.WeaponSkinMap[104004] = val
                    elseif k == "S1897"   then _G.WeaponSkinMap[104001] = val
                    elseif k == "S686"    then _G.WeaponSkinMap[104002] = val
                    elseif k == "M249"    then _G.WeaponSkinMap[105001] = val
                    elseif k == "DP28"    then _G.WeaponSkinMap[105002] = val
                    elseif k == "MG3"     then _G.WeaponSkinMap[105010] = val
                    elseif k == "Pan"     then _G.WeaponSkinMap[108004] = val
                    elseif k == "Machete" then _G.WeaponSkinMap[108001] = val
                    elseif k == "Crowbar" then _G.WeaponSkinMap[108002] = val
                    elseif k == "Sickle"  then _G.WeaponSkinMap[108003] = val
                    elseif k == "Motorcycle_1901001"              then _G.VehicleSkinMap[1901001] = val
                    elseif k == "Vehicle_1901002"                 then _G.VehicleSkinMap[1901002] = val
                    elseif k == "Sidecar_Motorcycle_1902001"      then _G.VehicleSkinMap[1902001] = val
                    elseif k == "Dacia_1903001"                   then _G.VehicleSkinMap[1903001] = val
                    elseif k == "Dacia_1903002"                   then _G.VehicleSkinMap[1903002] = val
                    elseif k == "Dacia_1903003"                   then _G.VehicleSkinMap[1903003] = val
                    elseif k == "dacia_1903004"                   then _G.VehicleSkinMap[1903004] = val
                    elseif k == "Mini_Bus_1904001"                then _G.VehicleSkinMap[1904001] = val
                    elseif k == "MiniBus_1904002"                 then _G.VehicleSkinMap[1904002] = val
                    elseif k == "MiniBus_1904003"                 then _G.VehicleSkinMap[1904003] = val
                    elseif k == "Pickup_(Open_Top)_1905001"       then _G.VehicleSkinMap[1905001] = val
                    elseif k == "Pickup_(Closed_Top)_1906001"     then _G.VehicleSkinMap[1906001] = val
                    elseif k == "PickUp_1906005"                  then _G.VehicleSkinMap[1906005] = val
                    elseif k == "Buggy_1907001"                   then _G.VehicleSkinMap[1907001] = val
                    elseif k == "buggy_1907002"                   then _G.VehicleSkinMap[1907002] = val
                    elseif k == "buggy_1907003"                   then _G.VehicleSkinMap[1907003] = val
                    elseif k == "UAZ_1908001"                     then _G.VehicleSkinMap[1908001] = val
                    elseif k == "UAZ_(Closed_Top)_1909001"        then _G.VehicleSkinMap[1909001] = val
                    elseif k == "UAZ_(Open_Top)_1910001"          then _G.VehicleSkinMap[1910001] = val
                    elseif k == "PG-117_1911001"                  then _G.VehicleSkinMap[1911001] = val
                    elseif k == "Jet_Ski_1912001"                 then _G.VehicleSkinMap[1912001] = val
                    elseif k == "Mirado_(Closed_Top)_1914001"     then _G.VehicleSkinMap[1914001] = val
                    elseif k == "Mirado_(Open_Top)_1915001"       then _G.VehicleSkinMap[1915001] = val
                    elseif k == "Mirado_(Open_Top)_1915004"       then _G.VehicleSkinMap[1915004] = val
                    elseif k == "Rony_1916001"                    then _G.VehicleSkinMap[1916001] = val
                    elseif k == "Rony_1916002"                    then _G.VehicleSkinMap[1916002] = val
                    elseif k == "Rony_1916003"                    then _G.VehicleSkinMap[1916003] = val
                    elseif k == "Scooter_1917001"                 then _G.VehicleSkinMap[1917001] = val
                    elseif k == "Scooter_1917002"                 then _G.VehicleSkinMap[1917002] = val
                    elseif k == "Snowmobile_1918001"              then _G.VehicleSkinMap[1918001] = val
                    elseif k == "Tukshai_1919001"                 then _G.VehicleSkinMap[1919001] = val
                    elseif k == "Monster_Truck_1953001"           then _G.VehicleSkinMap[1953001] = val
                    elseif k == "Monster_Truck_1953002"           then _G.VehicleSkinMap[1953002] = val
                    elseif k == "Motor_Glider_1960001"            then _G.VehicleSkinMap[1960001] = val
                    elseif k == "Coupe_RB_1961001"                then _G.VehicleSkinMap[1961001] = val
                    elseif k == "Tank_1963001"                    then _G.VehicleSkinMap[1963001] = val
                    elseif k == "Mountain_Bike_1965001"           then _G.VehicleSkinMap[1965001] = val
                    elseif k == "UTV_(Utility_Task_Vehicle)_1966001" then _G.VehicleSkinMap[1966001] = val
                    elseif k == "2-Seat_Bike_1967001"             then _G.VehicleSkinMap[1967001] = val
                    elseif k == "Horse_1987001"                   then _G.VehicleSkinMap[1987001] = val
                    elseif k == "Hovercraft_1988001"              then _G.VehicleSkinMap[1988001] = val
                    elseif k == "Infected_Grizzly_Dacia_1903024"  then _G.VehicleSkinMap[1903024] = val
                    elseif k == "Anniversary_Celebration_Dacia_1903040" then _G.VehicleSkinMap[1903040] = val
                    end
                end
            end
        end
    end)
end
_G.ReadLiveConfig = ReadLiveConfig

local rawGetTableData     = CDataTable and CDataTable.GetTableData     or function() return nil end
local rawGetTableByFilter = CDataTable and CDataTable.GetTableByFilter or function() return nil end

_G.InjectWeaponLogicHooks = function(pawn)
    if not isValid(pawn) then return end
    if _G.__WeaponLogicHookInjected then return end
    _G.__WeaponLogicHookInjected = true
    pcall(function()
        local wm = pawn:GetWeaponManager()
        if not isValid(wm) then return end
        local old_GetEquipID = wm.GetEquipWeaponAvatarID
        if old_GetEquipID then
            wm.GetEquipWeaponAvatarID = function(self, weaponID)
                local forced = _G.get_skin_id(weaponID)
                if forced then return forced end
                return old_GetEquipID(self, weaponID)
            end
        end
        local old_GetWeaponAvatarID = wm.GetWeaponAvatarID
        if old_GetWeaponAvatarID then
            wm.GetWeaponAvatarID = function(self, weapon)
                if isValid(weapon) then
                    local forced = _G.get_skin_id(weapon:GetWeaponID())
                    if forced then return forced end
                end
                return old_GetWeaponAvatarID(self, weapon)
            end
        end
    end)
end

_G.ForceSyncWeaponSkins = function(pawn)
    local wm = pawn:GetWeaponManager()
    if not isValid(wm) then return end
    for i = 1, 3 do
        local wpn = wm:GetInventoryWeaponByPropSlot(i)
        if isValid(wpn) then
            local targetID = _G.get_skin_id(wpn:GetWeaponID())
            if targetID and targetID > 0 then
                pcall(function()
                    if wpn.synData then
                        local data = wpn.synData:Get(7)
                        if data and data.defineID and data.defineID.TypeSpecificID ~= targetID then
                            data.defineID.TypeSpecificID = targetID
                            wpn.synData:Set(7, data)
                            if wpn.OnWeaponSkinUpdate then wpn:OnWeaponSkinUpdate() end
                        end
                    end
                    if wpn.SetWeaponAvatarID then wpn:SetWeaponAvatarID(targetID) end
                end)
            end
        end
    end
end

_G.ApplyWeaponSkins = function(pawn)
    if not isValid(pawn) then return end
    _G.InjectWeaponLogicHooks(pawn)
    _G.ForceSyncWeaponSkins(pawn)
end

if not _G.AKTableHacked and CDataTable then
    local _old = CDataTable.GetTableData
    CDataTable.GetTableData = function(tableName, id)
        local numId = tonumber(id)
        if numId then
            local upgradeID = _G.get_skin_id(numId)
            if upgradeID and upgradeID ~= numId then
                if tableName == "WeaponAvatarBattleEffect"
                or tableName == "GoldClothBattleEffect"
                or tableName == "WeaponSkinVoiceCfg"
                or tableName == "AvatarWeaponHitFXData" then
                    return _old(tableName, upgradeID)
                end
            end
        end
        return _old(tableName, id)
    end
    _G.AKTableHacked = true
end

_G.muzzles = {
    id_flash_hider = { 201010, 201005, 201004 },
    id_compensator = { 201009, 201003, 201002 },
    id_suppressor  = { 201011, 201006, 201007 }
}
_G.foregrips = {
    id_Angledforegrip = 202001,
    id_thumb_grip     = 202006,
    id_vertical_grip  = 202002,
    id_light_grip     = 202004,
    id_half_grip      = 202005,
    id_ergonomic_grip = 202051,
    id_laser_sight    = 202007
}
_G.magazines = {
    id_expanded_mag       = { 204011, 204007, 204004 },
    id_quick_mag          = { 204012, 204008, 204005 },
    id_expanded_quick_mag = { 204013, 204009, 204006 }
}
_G.scopes = {
    id_reddot = 203001,
    id_holo   = 203002,
    id_2x     = 203003,
    id_3x     = 203014,
    id_4x     = 203004,
    id_6x     = 203015,
    id_8x     = 203005
}
_G.stock = {
    id_microStock = 205001,
    id_tactical   = 205002,
    id_bulletloop = 204014,
    id_CheekPad   = 205003
}

_G.ItemUpgradeSystem = nil
pcall(function()
    local MM  = require("client.module_framework.ModuleManager")
    local IUS = MM.GetModule(MM.CommonModuleConfig.ItemUpgradeManager)
    if IUS then
        IUS:DefineAndResetData()
        IUS:OnInitialize()
        _G.ItemUpgradeSystem = IUS
    end
end)

_G.get_group_id = function(itemId)
    if not _G.ItemUpgradeSystem or not itemId then return nil end
    local cfg = _G.ItemUpgradeSystem:GetUpgradeCfg(itemId)
    return cfg and cfg.GroupID or nil
end

_G.InitParts = function(groupId, itemId)
    if not itemId then return _G.g_parts end
    if _G.g_parts[itemId] and next(_G.g_parts[itemId]) then return _G.g_parts end
    _G.g_parts[itemId] = {}
    if not _G.ItemUpgradeSystem then return _G.g_parts end
    if _G.ItemUpgradeSystem:IsWeaponIsRefit(itemId) then
        groupId = _G.ItemUpgradeSystem:GetNormalGroupID(groupId or _G.get_group_id(itemId))
    else
        groupId = groupId or _G.get_group_id(itemId)
    end
    if not groupId then return _G.g_parts end
    local cfg = rawGetTableByFilter("ItemUpgradeUnLockConfig", "GroupID", groupId)
    if cfg then
        for _, info in pairs(cfg) do
            local partId = info.PartId
            if _G.ItemUpgradeSystem:IsWeaponIsRefit(itemId) then
                local switched = _G.ItemUpgradeSystem:PartIDSwitch(partId, true)
                if switched and switched ~= partId then partId = switched end
            end
            local item = rawGetTableData("Item", partId)
            if item and item.ItemName then
                _G.g_parts[itemId][item.ItemName] = partId
            end
        end
    end
    return _G.g_parts
end

_G.GetRawAttachMap = function(skinid)
    if not skinid or skinid <= 0 then return {} end
    if _G.skinAttachCache[skinid] then return _G.skinAttachCache[skinid] end
    local UAvatarUtils = import("AvatarUtils")
    if not UAvatarUtils then return {} end
    local list = UAvatarUtils.GetWeaponAvatarDefaultAttachmentSkin(skinid, {}, false) or {}
    _G.skinAttachCache[skinid] = list
    return list
end

_G.GetSlotFromSkinID = function(skinid, slot)
    if not skinid or not slot then return 0 end
    local list = _G.GetRawAttachMap(skinid)
    local attachmentTypeMap = {
        [1] = {291004,291102,291001,291006,291005,291002,293003,293004,293009,293007,293005,293006,295001,295002,291007,291003,292002,292003,291011,291008},
        [2] = {205005,205102,205007,205009,205006},
        [3] = {203008,203009,203006,203022,203010}
    }
    local targetIDs = attachmentTypeMap[slot]
    if not targetIDs then return 0 end
    for _, targetID in ipairs(targetIDs) do
        for attachID, attachSkinID in pairs(list) do
            if attachID == targetID then return attachSkinID end
        end
    end
    return 0
end

_G.AutoDetectAttach = function(skinid, base_id)
    if not skinid or not base_id then return 0 end
    local list = _G.GetRawAttachMap(skinid)
    local v = list[base_id]
    return (v and v > 0) and v or 0
end

_G.get_muzzleid = function(current_id, avatarid)
    local initial_id = current_id
    _G.InitParts(_G.get_group_id(avatarid), avatarid)
    local p = _G.g_parts[avatarid]
    local function is_in(t)
        for _, id in ipairs(_G.muzzles[t]) do if current_id == id then return true end end
        return false
    end
    if is_in("id_flash_hider") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "FlashHider")
                  or (p and p["Flash Hider"])
                  or (auto > 0 and auto)
                  or current_id
    elseif is_in("id_compensator") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "Compensator")
                  or (p and p["Compensator"])
                  or (auto > 0 and auto)
                  or current_id
    elseif is_in("id_suppressor") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "Suppressor")
                  or (p and p["Suppressor"])
                  or (auto > 0 and auto)
                  or current_id
    end
    return current_id, (initial_id ~= current_id)
end

_G.get_forgripid = function(current_id, avatarid)
    local initial_id = current_id
    _G.InitParts(_G.get_group_id(avatarid), avatarid)
    local p = _G.g_parts[avatarid]
    local auto = _G.AutoDetectAttach(avatarid, current_id)
    if current_id == _G.foregrips.id_Angledforegrip then
        current_id = _G.GetAttachForSkin(avatarid, "AngledGrip") or (p and p["Angled Foregrip"]) or (auto > 0 and auto) or current_id
    elseif current_id == _G.foregrips.id_thumb_grip then
        current_id = _G.GetAttachForSkin(avatarid, "ThumbGrip") or (p and p["Thumb Grip"]) or (auto > 0 and auto) or current_id
    elseif current_id == _G.foregrips.id_vertical_grip then
        current_id = _G.GetAttachForSkin(avatarid, "VerticalGrip") or (p and p["Vertical Foregrip"]) or (auto > 0 and auto) or current_id
    elseif current_id == _G.foregrips.id_light_grip then
        current_id = _G.GetAttachForSkin(avatarid, "LightGrip") or (p and p["Light Grip"]) or (auto > 0 and auto) or current_id
    elseif current_id == _G.foregrips.id_half_grip then
        current_id = _G.GetAttachForSkin(avatarid, "HalfGrip") or (p and p["Half Grip"]) or (auto > 0 and auto) or current_id
    elseif current_id == _G.foregrips.id_ergonomic_grip then
        current_id = (p and p["Ergonomic Grip"]) or (auto > 0 and auto) or current_id
    elseif current_id == _G.foregrips.id_laser_sight then
        current_id = _G.GetAttachForSkin(avatarid, "LaserSight") or (p and p["Laser Sight"]) or (auto > 0 and auto) or current_id
    end
    return current_id, (initial_id ~= current_id)
end

_G.get_magazinesid = function(current_id, avatarid)
    local initial_id = current_id
    _G.InitParts(_G.get_group_id(avatarid), avatarid)
    local p = _G.g_parts[avatarid]
    local function is_in(t)
        for _, id in ipairs(_G.magazines[t]) do if current_id == id then return true end end
        return false
    end
    if is_in("id_expanded_mag") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "ExtMag") or (p and p["Extended Mag"]) or _G.GetSlotFromSkinID(avatarid, 1) or (auto > 0 and auto) or current_id
    elseif is_in("id_quick_mag") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "QuickMag") or (p and p["Quickdraw Mag"]) or _G.GetSlotFromSkinID(avatarid, 1) or (auto > 0 and auto) or current_id
    elseif is_in("id_expanded_quick_mag") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "ExtQuickMag") or (p and p["Extended Quickdraw Mag"]) or _G.GetSlotFromSkinID(avatarid, 1) or (auto > 0 and auto) or current_id
    else
        local fb = _G.GetSlotFromSkinID(avatarid, 1)
        if fb and fb > 0 then current_id = fb end
    end
    return current_id, (initial_id ~= current_id)
end

_G.get_scopeid = function(current_id, avatarid)
    local initial_id = current_id
    _G.InitParts(_G.get_group_id(avatarid), avatarid)
    local p = _G.g_parts[avatarid]
    local auto = _G.AutoDetectAttach(avatarid, current_id)
    if current_id == _G.scopes.id_reddot then
        current_id = _G.GetAttachForSkin(avatarid, "RedDot") or (p and p["Red Dot Sight"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    elseif current_id == _G.scopes.id_holo then
        current_id = _G.GetAttachForSkin(avatarid, "Holo") or (p and p["Holographic Sight"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    elseif current_id == _G.scopes.id_2x then
        current_id = _G.GetAttachForSkin(avatarid, "Scope2x") or (p and p["2x Scope"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    elseif current_id == _G.scopes.id_3x then
        current_id = _G.GetAttachForSkin(avatarid, "Scope3x") or (p and p["3x Scope"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    elseif current_id == _G.scopes.id_4x then
        current_id = _G.GetAttachForSkin(avatarid, "Scope4x") or (p and p["4x Scope"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    elseif current_id == _G.scopes.id_6x then
        current_id = _G.GetAttachForSkin(avatarid, "Scope6x") or (p and p["6x Scope"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    elseif current_id == _G.scopes.id_8x then
        current_id = _G.GetAttachForSkin(avatarid, "Scope8x") or (p and p["8x Scope"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    else
        local fb = _G.GetSlotFromSkinID(avatarid, 3)
        if fb and fb > 0 then current_id = fb end
    end
    return current_id, (initial_id ~= current_id)
end

_G.get_stockid = function(current_id, avatarid)
    local initial_id = current_id
    _G.InitParts(_G.get_group_id(avatarid), avatarid)
    local p = _G.g_parts[avatarid]
    local auto = _G.AutoDetectAttach(avatarid, current_id)
    if current_id == _G.stock.id_microStock then
        current_id = _G.GetAttachForSkin(avatarid, "MicroStock") or (p and p["Stock"]) or _G.GetSlotFromSkinID(avatarid, 2) or (auto > 0 and auto) or current_id
    elseif current_id == _G.stock.id_tactical then
        current_id = _G.GetAttachForSkin(avatarid, "TactStock") or (p and p["Tactical Stock"]) or _G.GetSlotFromSkinID(avatarid, 2) or (auto > 0 and auto) or current_id
    elseif current_id == _G.stock.id_bulletloop then
        current_id = (p and p["Bullet Loop"]) or _G.GetSlotFromSkinID(avatarid, 2) or (auto > 0 and auto) or current_id
    elseif current_id == _G.stock.id_CheekPad then
        current_id = _G.GetAttachForSkin(avatarid, "CheekPad") or (p and p["Cheek Pad"]) or _G.GetSlotFromSkinID(avatarid, 2) or (auto > 0 and auto) or current_id
    else
        local fb = _G.GetSlotFromSkinID(avatarid, 2)
        if fb and fb > 0 then current_id = fb end
    end
    return current_id, (initial_id ~= current_id)
end

_G.apply_attachment = function(CurWeapon, avatarid)
    local array = CurWeapon.synData
    for AttachIdx = 0, 4 do
        local Data = array:Get(AttachIdx)
        local itemid = slua.IndexReference(Data, "defineID").TypeSpecificID
        if itemid and itemid > 0 and itemid < 10000000 then
            local isrefresh = false
            if AttachIdx == 0 then
                Data.defineID.TypeSpecificID, isrefresh = _G.get_muzzleid(slua.IndexReference(Data, "defineID").TypeSpecificID, avatarid)
                array:Set(AttachIdx, Data)
            elseif AttachIdx == 1 then
                Data.defineID.TypeSpecificID, isrefresh = _G.get_forgripid(slua.IndexReference(Data, "defineID").TypeSpecificID, avatarid)
                array:Set(AttachIdx, Data)
            elseif AttachIdx == 2 then
                Data.defineID.TypeSpecificID, isrefresh = _G.get_magazinesid(slua.IndexReference(Data, "defineID").TypeSpecificID, avatarid)
                array:Set(AttachIdx, Data)
            elseif AttachIdx == 3 then
                Data.defineID.TypeSpecificID, isrefresh = _G.get_stockid(slua.IndexReference(Data, "defineID").TypeSpecificID, avatarid)
                array:Set(AttachIdx, Data)
            elseif AttachIdx == 4 then
                Data.defineID.TypeSpecificID, isrefresh = _G.get_scopeid(slua.IndexReference(Data, "defineID").TypeSpecificID, avatarid)
                array:Set(AttachIdx, Data)
            else
                break
            end
            if isrefresh then
                _G.download_item(slua.IndexReference(Data, "defineID").TypeSpecificID)
                CurWeapon:DelayHandleAvatarMeshChanged()
            end
        end
    end
end

local WEAPON_NAMES = {
    "AKM","M16A4","SCAR","M416","GROZA","AUG","QBZ","M762",
    "MK47","G36C","HoneyBadger","ASM","FAMAS","ACE32",
    "UZI","UMP","Vector","Bizon","Thompson","MP5K","P90",
    "Kar98","M24","AWM","SKS","Mini14","MK14","SLR","QBU","MK12","AMR","DSR","VSS","Mosin",
    "S12K","DBS","S1897","S686",
    "M249","DP28","MG3",
    "Pan","Machete","Crowbar","Sickle",
}
local WEAPON_NAME_TO_ID = {
    AKM=101001,M16A4=101002,SCAR=101003,M416=101004,
    GROZA=101005,AUG=101006,QBZ=101007,M762=101008,
    MK47=101009,G36C=101010,HoneyBadger=101012,ASM=101101,FAMAS=101100,ACE32=101102,
    UZI=102001,UMP=102002,Vector=102003,Thompson=102004,Bizon=102005,MP5K=102007,P90=102105,
    Kar98=103001,M24=103002,AWM=103003,SKS=103004,VSS=103005,
    Mini14=103006,MK14=103007,SLR=103009,QBU=103010,MK12=103100,AMR=103012,DSR=103102,Mosin=103013,
    S12K=104003,DBS=104004,S1897=104001,S686=104002,
    M249=105001,DP28=105002,MG3=105010,
    Pan=108004,Machete=108001,Crowbar=108002,Sickle=108003,
}

_G.SyncAttachmentsToConfig = function()
    local cache = _G.GetAttachFileCache and _G.GetAttachFileCache()
    if not cache or not next(cache) then return end
    local hasSkin = false
    for _, w in ipairs(WEAPON_NAMES) do
        local baseId = WEAPON_NAME_TO_ID[w]
        if baseId and (_G.WeaponSkinMap[baseId] or 0) > 0 then hasSkin = true; break end
    end
    if not hasSkin then return end
    pcall(function()
        local f = io.open(CONFIG_PATH, "r")
        if not f then return end
        local content = f:read("*all"); f:close()
        local lines = {}
        for line in content:gmatch("[^\r\n]+") do table.insert(lines, line) end
        local filtered = {}
        for _, line in ipairs(lines) do
            local isAuto = false
            for _, w in ipairs(WEAPON_NAMES) do
                if line:find("^" .. w .. "_[%w%-]+=") then isAuto = true; break end
            end
            if not isAuto then table.insert(filtered, line) end
        end
        local ATTACH_TO_CONFIG_KEY = {
            Scope2x = "2x", Scope3x = "3x", Scope4x = "4x", Scope6x = "6x", Scope8x = "8x",
            RedDot = "RedDot", Holo = "Holo", CantedSight = "CantedSight",
            FlashHider = "FlashHider", Compensator = "Compensator", Suppressor = "Suppressor",
            ExtMag = "ExtMag", QuickMag = "QuickMag", ExtQuickMag = "ExtQuickMag",
            AngledGrip = "AngledGrip", ThumbGrip = "ThumbGrip", VerticalGrip = "VerticalGrip",
            LightGrip = "LightGrip", HalfGrip = "HalfGrip", LaserSight = "LaserSight",
            TactStock = "TactStock", MicroStock = "MicroStock", CheekPad = "CheekPad",
        }
        local KEY_ORDER = {
            "RedDot","Holo","CantedSight",
            "Scope2x","Scope3x","Scope4x","Scope6x","Scope8x",
            "FlashHider","Compensator","Suppressor",
            "ExtMag","QuickMag","ExtQuickMag",
            "AngledGrip","ThumbGrip","VerticalGrip","LightGrip","HalfGrip","LaserSight",
            "TactStock","MicroStock","CheekPad",
        }
        local outLines = {}
        table.insert(outLines, "; SyncAttachmentsToConfig ran")
        local foundCount = 0
        for _, line in ipairs(filtered) do
            table.insert(outLines, line)
            local wname, skinStr = line:match("^(%w+)=(%d+)$")
            if wname then
                local baseId = WEAPON_NAME_TO_ID[wname]
                if baseId then
                    local skinId = tonumber(skinStr)
                    if skinId and skinId > 0 then
                        local attaches = cache[skinId]
                        if attaches then
                            for _, key in ipairs(KEY_ORDER) do
                                local id = attaches[key]
                                local ck = ATTACH_TO_CONFIG_KEY[key]
                                if id and ck then
                                    table.insert(outLines, wname .. "_" .. ck .. "=" .. id)
                                    foundCount = foundCount + 1
                                end
                            end
                        else
                            table.insert(outLines, "; No cache entry for skin " .. skinId)
                        end
                    end
                    table.insert(outLines, "")
                end
            end
        end
        outLines[1] = "; SyncAttachmentsToConfig OK - matched " .. foundCount .. " attachments"
        local out = io.open(CONFIG_PATH, "w")
        if out then out:write(table.concat(outLines, "\n"), "\n"); out:close() end
    end)
end

_G.ApplyLocalPlayerSkins = function(p)
    if _G.Mod_Skin_Enabled == false then return end  -- SKIN TOGGLE CHECK
    if not isValid(p) then return end

    pcall(function()
        local BackpackUtils = import("BackpackUtils")
        local ac = p:getAvatarComponent2()
        if isValid(ac) and ac.NetAvatarData then
            local applyData = ac.NetAvatarData.SlotSyncData
            if isValid(applyData) then
                local ref = false
                for i = 0, applyData:Num() - 1 do
                    local eq = applyData:Get(i)
                    if eq and eq.ItemId ~= 0 then
                        local target = 0
                        if eq.SlotID == 5 and _G.OutfitMap.Suit then
                            target = _G.OutfitMap.Suit
                        elseif eq.SlotID == 8 and _G.OutfitMap.Bag and _G.OutfitMap.Bag ~= 501001 then
                            local bagBase = _G.OutfitMap.Bag
                            local level = 1
                            if BackpackUtils then level = BackpackUtils.GetEquipmentBagLevel(eq.AdditionalItemID) or 1 end
                            target = bagBase + (level - 1) * 1000
                        elseif eq.SlotID == 9 and _G.OutfitMap.Helmet and _G.OutfitMap.Helmet ~= 502001 then
                            local helBase = _G.OutfitMap.Helmet
                            local level = 1
                            if BackpackUtils then level = BackpackUtils.GetEquipmentHelmetLevel(eq.AdditionalItemID) or 1 end
                            target = helBase + (level - 1) * 1000
                        end
                        if target and target ~= 0 and eq.ItemId ~= target then
                            if _G.download_item and not _G.SkinLoadedCache[target] then
                                pcall(_G.download_item, target)
                                _G.SkinLoadedCache[target] = true
                            end
                            eq.ItemId = target
                            applyData:Set(i, eq)
                            ref = true
                        end
                    end
                end
                if ref and ac.OnRep_BodySlotStateChanged then ac:OnRep_BodySlotStateChanged() end
            end
            local extra_keys = {"Hat","Mask","Glasses","Pants","Shoes","Armor","Parachute"}
            for _, key in ipairs(extra_keys) do
                local id = _G.OutfitMap[key]
                if id and id > 0 and _G.LastEquippedOutfits[key] ~= id then
                    if _G.download_item and not _G.SkinLoadedCache[id] then
                        pcall(_G.download_item, id)
                        _G.SkinLoadedCache[id] = true
                    end
                    ac:PutOnCustomEquipmentByID(id, {})
                    _G.LastEquippedOutfits[key] = id
                end
            end
        end
    end)

    _G.ApplyWeaponSkins(p)
    for i = 1, 3 do
        local wpn = p:GetWeaponManager() and p:GetWeaponManager():GetInventoryWeaponByPropSlot(i)
        if isValid(wpn) then
            local target = _G.get_skin_id(wpn:GetWeaponID())
            if target and target > 0 then
                if not _G.SkinLoadedCache[target] then
                    pcall(_G.download_item, target)
                    _G.SkinLoadedCache[target] = true
                end
                if _G.apply_attachment then pcall(_G.apply_attachment, wpn, target) end
            end
        end
    end

    if _G.OutfitMap.Pet and _G.OutfitMap.Pet ~= 0 then
        pcall(function()
            local pc = slua_GameFrontendHUD:GetPlayerController()
            if pc and pc.PetComponent and pc.PetComponent.PetId ~= _G.OutfitMap.Pet then
                pc.PetComponent.PetId = _G.OutfitMap.Pet
                pc.PetComponent:OnRep_PetId()
            end
        end)
    end

    pcall(function()
        local CV = p.CurrentVehicle
        if isValid(CV) then
            local VA = CV.VehicleAvatar
            if isValid(VA) then
                local defId = tostring(VA:GetDefaultAvatarID() or "")
                local currentId = tostring(CV:GetAvatarId() or "")
                local vehTarget = 0
                for baseId, targetSkin in pairs(_G.VehicleSkinMap) do
                    if defId:find(tostring(baseId)) then vehTarget = targetSkin; break end
                end
                if vehTarget and vehTarget > 0 and currentId ~= tostring(vehTarget) then
                    if _G.download_item and not _G.SkinLoadedCache[vehTarget] then
                        pcall(_G.download_item, vehTarget)
                        _G.SkinLoadedCache[vehTarget] = true
                    end
                    VA.curSwitchEffectId = 7303001
                    VA:ChangeItemAvatar(vehTarget, true)
                    _G.CurrentEquipVehicleID = vehTarget
                end
            end
        end
    end)
end

if not table.contains then
    function table.contains(t, el)
        for _, v in ipairs(t) do if v == el then return true end end
        return false
    end
end

local function locationsClose(loc1, loc2, tolerance)
    local dx = loc1.X - loc2.X
    local dy = loc1.Y - loc2.Y
    local dz = loc1.Z - loc2.Z
    return dx*dx + dy*dy + dz*dz < tolerance*tolerance
end

_G.ApplyDeadBoxSkin = function()
    if _G.Mod_Skin_Enabled == false then return end  -- SKIN TOGGLE CHECK
    local pc = slua_GameFrontendHUD:GetPlayerController()
    if not pc then return end
    local uCharacter = pc:GetPlayerCharacterSafety()
    if not isValid(uCharacter) then return end
    local UGameplayStatics = import("GameplayStatics")
    if not UGameplayStatics then return end
    local uActor = import("Actor")
    if not uActor then return end
    local ok, UIUtil = pcall(require, "client.common.ui_util")
    if not ok or not UIUtil then return end
    local uGameInstance = UIUtil.GetGameInstance()
    if not uGameInstance then return end
    local APlayerTombBox = import("PlayerTombBox")
    if not APlayerTombBox then return end
    local uActorArray = UGameplayStatics.GetAllActorsOfClass(
        uGameInstance, APlayerTombBox,
        slua.Array(UEnums.EPropertyClass.Object, uActor))
    if not uActorArray then return end
    for _, actor in pairs(uActorArray) do
        if isValid(actor) then
            local DamageCauser = actor.DamageCauser
            if DamageCauser and DamageCauser.PlayerKey == pc.PlayerKey then
                local Deadboxavatar = actor.DeadBoxAvatarComponent_BP
                if Deadboxavatar and not table.contains(_G.AlreadyChangedSet, actor) then
                    local actorLocation = actor:K2_GetActorLocation()
                    local found = false
                    for _, entry in pairs(_G.DeadBoxSkins) do
                        if locationsClose(entry.location, actorLocation, 1.0) then
                            Deadboxavatar:ResetItemAvatar()
                            Deadboxavatar:PreChangeItemAvatar(entry.SkinID)
                            Deadboxavatar:SyncChangeItemAvatar(entry.SkinID)
                            table.insert(_G.AlreadyChangedSet, actor)
                            found = true
                            break
                        end
                    end
                    if not found then
                        local ApplySkinID = 0
                        local CV = uCharacter.CurrentVehicle
                        if CV then
                            local carSkinID = _G.CurrentEquipVehicleID
                            if carSkinID ~= 0 then ApplySkinID = tostring(carSkinID) .. "1" end
                        else
                            local cw = uCharacter:GetCurrentWeapon()
                            if cw and cw.synData then
                                ApplySkinID = slua.IndexReference(cw.synData:Get(7), "defineID").TypeSpecificID
                            end
                        end
                        Deadboxavatar:ResetItemAvatar()
                        Deadboxavatar:PreChangeItemAvatar(ApplySkinID)
                        Deadboxavatar:SyncChangeItemAvatar(ApplySkinID)
                        table.insert(_G.DeadBoxSkins, { location = actorLocation, SkinID = ApplySkinID })
                        table.insert(_G.AlreadyChangedSet, actor)
                    end
                end
            end
        end
    end
end

_G.RefreshKillCounterUI = function()
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not pc then return end
        local lp = pc:GetPlayerCharacterSafety()
        if not isValid(lp) then return end
        local cw = lp:GetCurrentWeapon()
        if not isValid(cw) then return end
        local wID = cw:GetWeaponID()
        if not wID or wID == 0 then return end
        local sid = _G.get_skin_id(wID)
        if not sid then return end
        local KillCounterUI = package.loaded["GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem"]
        if KillCounterUI and KillCounterUI.__inner_impl then
            KillCounterUI.__inner_impl:CheckNeedMainKillCounterUI(cw, pc.PlayerKey)
        end
        local UIM = require("client.slua_ui_framework.manager")
        local MKC = UIM.GetUI(UIM.UI_Config_InGame.MainKillCounter)
        if MKC and MKC.KillCounterItem then
            MKC:SetKillCounterItemShowWithNum(sid, _G.getKills(wID), sid)
        end
    end)
end

_G.ForceEnableKillCounterUI = function()
    if _G.KCUISystemHacked2 then return end
    pcall(function()
        local KillCounterUI = package.loaded["GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem"]
                           or require("GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem")
        if KillCounterUI and KillCounterUI.__inner_impl then
            local ui = KillCounterUI.__inner_impl
            ui.CheckSupportKCUI = function() return true end
            ui.CheckNeedMainKillCounterUI = function(self, Weapon, PlayerID)
                local pc = slua_GameFrontendHUD:GetPlayerController()
                local cw = isValid(Weapon) and Weapon
                        or (pc and pc:GetPlayerCharacterSafety() and pc:GetPlayerCharacterSafety():GetCurrentWeapon())
                if not isValid(cw) then self:UpdateMainKillCounterUI(false); return end
                local wID = cw:GetWeaponID()
                if not wID or wID == 0 then self:UpdateMainKillCounterUI(false); return end
                self:UpdateMainKillCounterUI(true, wID, _G.get_skin_id(wID) or wID)
            end
            local old_Update = ui.UpdateMainKillCounterUI
            ui.UpdateMainKillCounterUI = function(self, bShow, WeaponID, AvatarID)
                if not bShow then return old_Update(self, bShow, WeaponID, AvatarID) end
                return old_Update(self, bShow, WeaponID, AvatarID or _G.get_skin_id(WeaponID))
            end
            _G.KCUISystemHacked2 = true
        end
        local MM = require("client.module_framework.ModuleManager")
        if MM then
            local LogicKC = MM.GetModule(MM.CommonModuleConfig.LogicKillCounter)
            if LogicKC and not _G.KCLogicHacked2 then
                LogicKC.CheckSupportKC                = function() return true end
                LogicKC.CheckSupportKillCounterAvatar = function() return true end
                LogicKC.CheckHasWeaponKillCounter     = function() return true end
                LogicKC.GetBaseKillCounterIdByWeaponId= function() return 2100004 end
                LogicKC.GetEquipedKillCounterId        = function() return 2100004 end
                LogicKC.GetMyEquipedKillCounterId      = function() return 2100004 end
                LogicKC.GetOneWeaponKillCountInBattle  = function(_, _, wid) return _G.getKills(wid) end
                LogicKC.GetWeaponKillCountByUid        = function(_, _, wid) return _G.getKills(wid) end
                _G.KCLogicHacked2 = true
            end
        end
        local KillInfoPath = "GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo"
        local KillInfo = package.loaded[KillInfoPath] or require(KillInfoPath)
        if KillInfo and KillInfo.__inner_impl and not _G.KillInfoCounterHacked then
            local old_FileItem = KillInfo.__inner_impl.FileItem
            KillInfo.__inner_impl.FileItem = function(self, DRD)
                pcall(function()
                    local GD = require("GameLua.GameCore.Data.GameplayData")
                    local lp = GD.GetPlayerCharacter()
                    if isValid(lp) and DRD.Causer == lp:GetPlayerNameSafety() then
                        local cw = lp:GetCurrentWeapon()
                        if isValid(cw) then
                            local wid = cw:GetWeaponID()
                            local sid = _G.get_skin_id(wid)
                            if sid then DRD.CauserWeaponAvatarID = sid end
                            if _G.OutfitMap.Suit then DRD.CauserClothAvatarID = _G.OutfitMap.Suit end
                            DRD.IsUseColor = true
                            DRD.UseColor = import("LinearColor")(1.0, 0.8, 0.0, 1.0)
                            local expand_data = DRD.ExpandDataContent
                            if expand_data then
                                expand_data.KillCounterItemId = sid or wid
                                expand_data.KillCounterNum = _G.getKills(wid)
                            end
                            if DRD.ResultHealthStatus == 2 then
                                _G.AddKill(wid)
                                local UIM = require("client.slua_ui_framework.manager")
                                local MKC = UIM.GetUI(UIM.UI_Config_InGame.MainKillCounter)
                                if MKC and MKC.KillCounterItem then
                                    MKC:SetKillCounterItemShowWithNum(sid or wid, _G.getKills(wid), sid or wid)
                                end
                            end
                        end
                    end
                end)
                if old_FileItem then old_FileItem(self, DRD) end
            end
            _G.KillInfoCounterHacked = true
        end
        local ok2, WIIB = pcall(require, "GameLua.Mod.BaseMod.Client.Backpack.WeaponInfoItemBase")
        if ok2 and WIIB and WIIB.__inner_impl and not _G.WeaponInfoBackpackHacked then
            local o_UWA = WIIB.__inner_impl.UpdateWeaponAppearanceInfo
            if o_UWA then
                WIIB.__inner_impl.UpdateWeaponAppearanceInfo = function(self, TypeSpecificID, BattleData, DragOrigin)
                    local ItemData = rawGetTableData("Item", TypeSpecificID)
                    if not ItemData then return o_UWA(self, TypeSpecificID, BattleData, DragOrigin) end
                    local skin_id = _G.get_skin_id(TypeSpecificID)
                    if not skin_id or not _G.SkinLoadedCache[skin_id] then
                        return o_UWA(self, TypeSpecificID, BattleData, DragOrigin)
                    end
                    o_UWA(self, skin_id, BattleData, DragOrigin)
                    pcall(function()
                        self.TypeSpecificIDTemp = TypeSpecificID
                        self.ItemID             = TypeSpecificID
                        if self.UIRoot then
                            self.UIRoot.ItemID = TypeSpecificID
                            if self.UIRoot.TextBlock_WeaponName and ItemData.ItemName then
                                self.UIRoot.TextBlock_WeaponName:SetText(ItemData.ItemName)
                            end
                        end
                        if self.BindWeaponChangeEvent  then self:BindWeaponChangeEvent()  end
                        if self.UpdateBullet           then self:UpdateBullet()           end
                        if self.UpdateWeaponDurability then self:UpdateWeaponDurability() end
                        if self.UpdateWeaponAttachment then self:UpdateWeaponAttachment() end
                    end)
                end
                _G.WeaponInfoBackpackHacked = true
            end
        end
    end)
end

if not _G.BattleKillBroadcastSkinHacked then
    pcall(function()
        local BattleKillBroadcastSubSystem = require("GameLua.Mod.BaseMod.Client.BattleKillBroadcast.BattleKillBroadcastSubSystem")
        if not (BattleKillBroadcastSubSystem and BattleKillBroadcastSubSystem.__inner_impl) then return end
        local o_Copy = BattleKillBroadcastSubSystem.__inner_impl.CopyKillOrPutDownMessageDataUserDataToLuaTable
        BattleKillBroadcastSubSystem.__inner_impl.CopyKillOrPutDownMessageDataUserDataToLuaTable = function(self, messageData)
            local msgData = o_Copy(self, messageData)
            pcall(function()
                local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                local character = pc and pc:GetPlayerCharacterSafety()
                if character and isValid(character) and msgData.bIamCauser and _G.LuaStateWrapper then
                    msgData.bShowBottomBothSidesKillInfo = true
                    local weapon = character:GetCurrentWeapon()
                    if weapon and isValid(weapon) then
                        local weapon_id = weapon:GetItemDefineID() and weapon:GetItemDefineID().TypeSpecificID or 0
                        if weapon_id ~= 0 then
                            local expand_data = slua.LuaArchiverDecode(_G.LuaStateWrapper, msgData.ExpandDataContent) or {}
                            local isClassic = false
                            local uGameState = slua_GameFrontendHUD:GetGameState()
                            if uGameState and isValid(uGameState) then
                                local EGameModeType = import("EGameModeType")
                                if uGameState.GameModeType == EGameModeType.ETypicalGameMode then isClassic = true end
                            end
                            local syn_data = weapon.synData
                            if syn_data and isValid(syn_data) then
                                local define_id = slua.IndexReference(syn_data:Get(7), "defineID")
                                if define_id and isValid(define_id) then
                                    expand_data.CauserWeaponAvatarID = define_id.TypeSpecificID
                                end
                            end
                            if isClassic then
                                expand_data.KillCounterItemId = weapon_id
                                expand_data.KillCounterNum = _G.getKills and _G.getKills(weapon_id) or 0
                            end
                            msgData.bShowKillNum = true
                            msgData.ExpandDataContent = slua.LuaArchiverEncode(_G.LuaStateWrapper, expand_data)
                        end
                    end
                end
            end)
            return msgData
        end
        _G.BattleKillBroadcastSkinHacked = true
    end)
end

ReadLiveConfig()
_G.ForceEnableKillCounterUI()

_G._SetupSkinTimer = function()
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not (pc and slua.isValid(pc)) then return end
        if _G.SkinTimerPC == pc then return end
        _G.SkinTimerPC = pc
        _G._SkinTimerInstalled = true
        _G._SkinTickCount = 0
        pc:AddGameTimer(0.5, true, function()
            pcall(function()
                local lpc = slua_GameFrontendHUD:GetPlayerController()
                if not (lpc and slua.isValid(lpc)) then return end
                local pawn = lpc:GetPlayerCharacterSafety()
                if not (pawn and slua.isValid(pawn)) then return end
                _G._SkinTickCount = (_G._SkinTickCount or 0) + 1
                local tick = _G._SkinTickCount
                if tick % 4 == 1 then
                    _G.ReadLiveConfig()
                    _G.SyncAttachmentsToConfig()
                end
                if tick % 10 == 1 then
                    _G.ApplyLocalPlayerSkins(pawn)
                    _G.ApplyDeadBoxSkin()
                end
                _G.RefreshKillCounterUI()
            end)
        end)
    end)
end

_G._SetupSkinTimer()

-- ============================================================
-- ==================== PBC WALLHACK MODULE ====================
-- (dyeing/outline chams, controlled by separate toggle)
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
        mesh:OverrideIdeaOutlineThickness(3.0)
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
        -- Controlled by separate PBC WALLHACK toggle
        if not _G.Mod_PBCWallhack_Enabled then return end
        if not _G.CheatsEnabled then return end

        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        local localPawn = GameplayData.GetPlayerCharacter()
        if not slua.isValid(localPawn) then return end

        ChamsSetupConsole()

        local LinearColor = import("LinearColor")
        if not LinearColor then return end

        local colors = {
            vis = LinearColor(10, 10, 1, 100),    -- cyan
            occ = LinearColor(10, 0, 10, 100),    -- purple
            bVis = LinearColor(9.8, 9.5, 0, 100),
            bOcc = LinearColor(1.8, 0.3, 9.0, 100)
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

            -- Main mesh
            pcall(function()
                if slua.isValid(pawn.Mesh) then
                    ChamsApplyToMesh(pawn.Mesh, visColor, occColor)
                end
            end)

            -- Avatar components
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

            -- Weapon mesh
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
-- MENU (updated: added SKIN toggle and PBC WALLHACK toggle)
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

        local ModMenuStack = {
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
            -- ===== WALLHACK SECTION =====
            { UI = AliasMap.Title, Text = "--- WALLHACK ---" },
            {
                Key = "WH_Enabled",
                UI = AliasMap.TitleSwitcher,
                Text = "Wallhack",
                GetFunc = function() return _G.ESPConfig.Wallhack end,
                SetFunc = function(_, value)
                    _G.ESPConfig.Wallhack = value
                    _G.Mod_Wallhack_Enabled = value
                    print("[MOD] WALLHACK: " .. (value and "ON ✓" or "OFF ✗"))
                    return true
                end
            },
            {
                Key = "WH_VisibleColor",
                UI = AliasMap.Switcher,
                Text = "Visible Color",
                SwitcherText = {"Red","White","Yellow","Green","Cyan","Blue","Purple"},
                SwitcherValue = {1,2,3,4,5,6,7},
                GetFunc = function() return _G.ESPConfig.WallhackVisibleColor or 4 end,
                SetFunc = function(_, value)
                    _G.ESPConfig.WallhackVisibleColor = value
                    return true
                end
            },
            {
                Key = "WH_InvisibleColor",
                UI = AliasMap.Switcher,
                Text = "Invisible Color",
                SwitcherText = {"Red","White","Yellow","Green","Cyan","Blue","Purple"},
                SwitcherValue = {1,2,3,4,5,6,7},
                GetFunc = function() return _G.ESPConfig.WallhackInvisibleColor or 3 end,
                SetFunc = function(_, value)
                    _G.ESPConfig.WallhackInvisibleColor = value
                    return true
                end
            },
            {
                Key = "WH_Brightness",
                UI = AliasMap.Slider,
                Text = "Brightness",
                Min = 1,
                Max = 50,
                Step = 1,
                IsPercent = false,
                GetFunc = function() return _G.ESPConfig.WallhackBrightness or 25 end,
                SetFunc = function(_, value)
                    _G.ESPConfig.WallhackBrightness = value
                    return true
                end
            },
            {
                Key = "WH_Glow",
                UI = AliasMap.Slider,
                Text = "Glow Intensity",
                Min = 0,
                Max = 10,
                Step = 0.5,
                IsPercent = false,
                GetFunc = function() return _G.ESPConfig.WallhackGlow or 3.0 end,
                SetFunc = function(_, value)
                    _G.ESPConfig.WallhackGlow = value
                    return true
                end
            },
            {
                Key = "WH_ShowAI",
                UI = AliasMap.TitleSwitcher,
                Text = "Show AI",
                GetFunc = function() return _G.ESPConfig.ShowAI end,
                SetFunc = function(_, value)
                    _G.ESPConfig.ShowAI = value
                    return true
                end
            },
            -- ===== END WALLHACK SECTION =====
            -- ===== SKIN TOGGLE =====
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
            -- ===== NEW PBC WALLHACK TOGGLE =====
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
            -- ==============================
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
                    Stack = ModMenuStack
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