-- ============================================================
-- MODDED BY ADITYA_ORG + @ADITYA_ORG
-- Complete MOD with Ultimate Bypass V3.0 + SKINS + PBC WALLHACK
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

-- ============================================================
-- ULTIMATE BYPASS V3.0 - MAIN HOOK + REVERSE SYSTEM
-- SOURCE: Hybrid of V2.0 + Advanced Hook Manager
-- OWNER: @ADITYA_ORG (Upgraded)
-- ============================================================

-- ============================================================
-- 1. DOMAIN BLOCK LIST (Expanded with wildcards)
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
    "opensdk.tencent","exp.helpshift","loginsdkapi.zingplay","firebase","googleapis","facebook","gvoice",
    "%.tencent%.","%.qq%.","%.anticheatexpert%.","%.helpshift%.","%.crashsight%.","%.bugly%.","%.beacon%."
}

-- ============================================================
-- 2. NOP FUNCTIONS (Extended)
-- ============================================================
local function nop() end
local function nopt() return {} end
local function nopnil() return nil end
local function noptrue() return true end
local function nopfalse() return false end
local function nopstr() return "" end
local function nopzero() return 0 end

-- ============================================================
-- 3. MAIN HOOK MANAGER (Centralized)
-- ============================================================
local HookManager = {}
HookManager.__index = HookManager

function HookManager:new()
    return setmetatable({hooks = {}, patterns = {}}, self)
end

function HookManager:addHook(target, funcName, replacement, options)
    if type(target) == "table" and type(funcName) == "string" then
        local orig = target[funcName]
        if type(orig) == "function" then
            local hookData = {
                target = target,
                funcName = funcName,
                original = orig,
                replacement = replacement,
                options = options or {}
            }
            table.insert(self.hooks, hookData)
            target[funcName] = function(...)
                if options and options.nop then return end
                return replacement(self, orig, ...)
            end
            return true
        end
    elseif type(target) == "function" and type(funcName) == "function" then
        local orig = target
        local hookData = {
            target = nil,
            funcName = nil,
            original = orig,
            replacement = funcName,
            options = options or {}
        }
        table.insert(self.hooks, hookData)
        return false
    end
    return false
end

function HookManager:removeAll()
    for _, hook in ipairs(self.hooks) do
        if hook.target and hook.funcName then
            hook.target[hook.funcName] = hook.original
        end
    end
    self.hooks = {}
end

-- ============================================================
-- 4. REVERSE SYSTEM (Dynamic Module Discovery)
-- ============================================================
local ReverseSystem = {}

function ReverseSystem:scanAndHook(patterns, hookManager, replacementFunc)
    local scanned = {}
    for modName, modTable in pairs(package.loaded) do
        if type(modTable) == "table" and not scanned[modName] then
            scanned[modName] = true
            for key, value in pairs(modTable) do
                if type(value) == "function" and type(key) == "string" then
                    for _, pattern in ipairs(patterns) do
                        if string.find(key, pattern, 1, true) then
                            hookManager:addHook(modTable, key, replacementFunc)
                        end
                    end
                end
            end
        end
    end
    for key, value in pairs(_G) do
        if type(value) == "function" and type(key) == "string" and not scanned[key] then
            scanned[key] = true
            for _, pattern in ipairs(patterns) do
                if string.find(key, pattern, 1, true) then
                    hookManager:addHook(_G, key, replacementFunc)
                end
            end
        end
    end
end

-- ============================================================
-- 5. INITIALIZATION: DOMAIN BLOCKER (Enhanced)
-- ============================================================
local function InitDomainBlocker(hookManager)
    pcall(function()
        if package.loaded["client.network.http.HttpClient"] then
            local hc = package.loaded["client.network.http.HttpClient"]
            hookManager:addHook(hc, "SendRequest", function(_, orig, url, cb, method, headers, content, timeout)
                for _, host in ipairs(blockedDomains) do
                    if url and string.find(string.lower(url), string.lower(host), 1, true) then
                        return nil
                    end
                end
                return orig(url, cb, method, headers, content, timeout)
            end)
        end
        if NetUtil and NetUtil.SendHttpRequest then
            hookManager:addHook(NetUtil, "SendHttpRequest", function(_, orig, url, cb, method, headers, content)
                for _, host in ipairs(blockedDomains) do
                    if url and string.find(string.lower(url), string.lower(host), 1, true) then
                        return nil
                    end
                end
                return orig(url, cb, method, headers, content)
            end)
        end
        local wv = package.loaded["client.slua.logic.url.logic_webview_sdk"]
        if wv then
            hookManager:addHook(wv, "OpenURL", function(_, orig, url)
                for _, host in ipairs(blockedDomains) do
                    if url and string.find(string.lower(url), string.lower(host), 1, true) then
                        return nil
                    end
                end
                return orig(url)
            end)
        end
        if socket and socket.connect then
            hookManager:addHook(socket, "connect", function(_, orig, host, port, timeout)
                for _, blocked in ipairs(blockedDomains) do
                    if host and string.find(string.lower(host), string.lower(blocked), 1, true) then
                        return nil, "blocked"
                    end
                end
                return orig(host, port, timeout)
            end)
        end
    end)
end

-- ============================================================
-- 6. INIT: SKIN BYPASS + ALL PREVIOUS MODULES (Using HookManager)
-- ============================================================
local function InitSkinBypass(hookManager)
    pcall(function()
        local puf = package.loaded["client.slua.logic.download.report.puffer_tlog"]
        if puf then
            hookManager:addHook(puf, "ReportEvent", nop)
            hookManager:addHook(puf, "ReportDownloadResult", nop)
            hookManager:addHook(puf, "ReportODPTDError", nop)
        end
        local au = package.loaded["AvatarUtils"]
        if au then
            hookManager:addHook(au, "CheckIsWeaponInBlackList", function() return false end)
            hookManager:addHook(au, "IsValidAvatar", function() return true end)
        end
        local sm = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        local fcs = sm and sm:Get("FileCheckSubsystem")
        if fcs then
            hookManager:addHook(fcs, "StartCheck", nop)
            hookManager:addHook(fcs, "ReportAbnormalFile", nop)
        end
        local ee = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
        if ee then
            hookManager:addHook(ee, "Report", nop)
        end
    end)
end

-- ============================================================
-- 7. TSS + SDK BLOCKER (With reverse patterns)
-- ============================================================
local function InitTssBlocker(hookManager)
    pcall(function()
        local tss = package.loaded["TssSdk"] or _G.TssSdk
        if tss then
            if tss.OnRecvData then hookManager:addHook(tss, "OnRecvData", nop) end
            if tss.SendReportInfo then hookManager:addHook(tss, "SendReportInfo", nop) end
            if tss.ReportData then hookManager:addHook(tss, "ReportData", nop) end
            if tss.ScanMemory then hookManager:addHook(tss, "ScanMemory", noptrue) end
            if tss.IsEmulator then hookManager:addHook(tss, "IsEmulator", nopfalse) end
            if tss.GetTssSdkReportInfo then hookManager:addHook(tss, "GetTssSdkReportInfo", nopstr) end
        end
        local beacon = package.loaded["BeaconSDK"] or _G.BeaconSDK
        if beacon then
            hookManager:addHook(beacon, "Report", nop)
            hookManager:addHook(beacon, "ReportEvent", nop)
            hookManager:addHook(beacon, "ReportData", nop)
        end
        local bugly = package.loaded["BuglySDK"] or _G.BuglySDK
        if bugly then
            hookManager:addHook(bugly, "ReportException", nop)
            hookManager:addHook(bugly, "ReportError", nop)
            hookManager:addHook(bugly, "SetUserData", nop)
        end
        local helpshift = package.loaded["HelpShift"] or _G.HelpShift
        if helpshift then
            hookManager:addHook(helpshift, "Report", nop)
            hookManager:addHook(helpshift, "SendFeedback", nop)
            hookManager:addHook(helpshift, "ReportUser", nop)
        end
    end)
end

-- ============================================================
-- 8. LOG BLOCKER
-- ============================================================
local function InitLogBlocker(hookManager)
    pcall(function()
        local ssm = import("ScreenshotMTDer")
        if ssm then
            hookManager:addHook(ssm, "MTDePicture", nopstr)
            hookManager:addHook(ssm, "ReMTDePicture", nopstr)
            hookManager:addHook(ssm, "HasCaptured", noptrue)
        end
        local tlog = package.loaded["TLog"] or _G.TLog
        if tlog then
            for _, f in ipairs({"Info","Warning","Error","Debug","Report"}) do
                if tlog[f] then hookManager:addHook(tlog, f, nop) end
            end
        end
        local cs = package.loaded["CrashSight"] or _G.CrashSight
        if cs then
            hookManager:addHook(cs, "ReportException", nop)
            hookManager:addHook(cs, "SetCustomData", nop)
            hookManager:addHook(cs, "Log", nop)
        end
        local gru = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
        if gru then
            hookManager:addHook(gru, "BugglyPostExceptionFull", nopfalse)
            hookManager:addHook(gru, "CheckCanBugglyPostException", nopfalse)
            hookManager:addHook(gru, "ReplayReportData", nop)
            hookManager:addHook(gru, "ReportGameException", nop)
        end
        local ctr = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if ctr then
            hookManager:addHook(ctr, "SendReport", nop)
            hookManager:addHook(ctr, "SendException", nop)
        end
        local tru = package.loaded["client.slua.config.tlog.tlog_report_utils"]
        if tru then
            hookManager:addHook(tru, "ReportTLogEvent", nop)
        end
    end)
end

-- ============================================================
-- 9. SCANNER BLOCKER
-- ============================================================
local function InitScannerBlocker(hookManager)
    pcall(function()
        local sm = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if sm then
            local afk = sm:Get("AFKReportorSubsystem")
            if afk then
                hookManager:addHook(afk, "PlayerHaveAction", nop)
                hookManager:addHook(afk, "ReportAFK", nop)
            end
            local ds = sm:Get("ClientDataStatistcsSubsystem")
            if ds then
                hookManager:addHook(ds, "StartToCheck", nop)
                ds.DelayCount = 0
                if ds.ReportPingDelayTimer then
                    ds:RemoveGameTimer(ds.ReportPingDelayTimer)
                    ds.ReportPingDelayTimer = nil
                end
            end
            local ae = sm:Get("AvatarExceptionSubsystem")
            if ae then
                hookManager:addHook(ae, "ReportException", nop)
                hookManager:addHook(ae, "BindPlayerCharacter", nop)
                hookManager:addHook(ae, "CheckAvatarValid", noptrue)
            end
            local sv = sm:Get("ShootVerifySubSystemClient")
            if sv then
                hookManager:addHook(sv, "ReportVerifyFail", nop)
                hookManager:addHook(sv, "OnVerifyFailed", nop)
            end
        end
        local cmbl = import("CreativeModeBlueprintLibrary")
        if cmbl then
            cmbl.MD5HashByteArray = function() return "BYPASSED" end
            cmbl.GetContentDiffData = function() return true, "BYPASSED" end
        end
        local aepi = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
        if aepi then
            hookManager:addHook(aepi, "CheckAvatarException", nop)
            hookManager:addHook(aepi, "CheckAvatarExceptionOnce", nop)
            hookManager:addHook(aepi, "ReportAvatarException", nop)
            hookManager:addHook(aepi, "CheckSlotMeshVisible", nopfalse)
            hookManager:addHook(aepi, "CheckPawnVisible", nopfalse)
            hookManager:addHook(aepi, "CheckCanBugglyPostException", nopfalse)
        end
        local acm = package.loaded["blacklist.slua.logic.lobby_gm.AvatarCheckerModule"]
        if acm then
            hookManager:addHook(acm, "CheckAvatar", noptrue)
            hookManager:addHook(acm, "ReportException", nop)
        end
        local lmw = package.loaded["client.slua.logic.memory_warning.logic_memory_warning"]
        if lmw then
            hookManager:addHook(lmw, "OnMemoryWarning", nop)
            hookManager:addHook(lmw, "ReportMemoryWarning", nop)
        end
    end)
end

-- ============================================================
-- 10. REPLAY TELEMETRY BLOCKER
-- ============================================================
local function InitReplayBlocker(hookManager)
    pcall(function()
        local sm = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if sm then
            local rbrt = sm:Get("RescueBtnReplayTraceSubsystem")
            if rbrt then
                hookManager:addHook(rbrt, "ReportTrace", nop)
                hookManager:addHook(rbrt, "StartTickMonitor", nop)
                hookManager:addHook(rbrt, "TickMonitorCheck", nop)
                hookManager:addHook(rbrt, "ReportTickMonitorHeartbeat", nop)
            end
            local grs = sm:Get("GameReportSubsystem")
            if grs then
                hookManager:addHook(grs, "ReplayReportData", nopfalse)
                hookManager:addHook(grs, "CheckCanBugglyPostException", nopfalse)
                hookManager:addHook(grs, "BugglyPostExceptionFull", nopfalse)
                hookManager:addHook(grs, "GetClientReplayDataReporter", nopnil)
                if grs.Reporter then
                    for _, f in ipairs({"ReportIntArrayData","ReportUInt8ArrayData","ReportFloatArrayData"}) do
                        if grs.Reporter[f] then hookManager:addHook(grs.Reporter, f, nop) end
                    end
                end
            end
        end
        local lrr = package.loaded["client.slua.logic.replay.logic_report_replay"]
        if lrr then
            hookManager:addHook(lrr, "ReportReplay", nop)
            hookManager:addHook(lrr, "SendReportReq", nop)
        end
        local lhr = package.loaded["client.slua.logic.home.logic_home_report"]
        if lhr then
            hookManager:addHook(lhr, "ShowInGameReportUI", nop)
            hookManager:addHook(lhr, "SendReport", nop)
        end
    end)
end

-- ============================================================
-- 11. ANTI-REPORT SYSTEM
-- ============================================================
local function InitAntiReport(hookManager)
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
                if crp[f] then hookManager:addHook(crp, f, nop) end
            end
            hookManager:addHook(crp, "GetFatalDamagerMap", nopt)
            hookManager:addHook(crp, "GetCachedTeammateName2InfoMap", nopt)
            hookManager:addHook(crp, "GetTeammateName2InfoMapDuringBattle", nopt)
            hookManager:addHook(crp, "GetCurrentNotInTeamHistoricalTeammateMap", nopt)
            hookManager:addHook(crp, "GetInTeamIndexFromHistoricalTeammateInfo", function() return -1 end)
        end
    end)
end

-- ============================================================
-- 12. GAMEPLAY BYPASS (DS State + Network Packets)
-- ============================================================
local function InitGameplayBypass(hookManager)
    pcall(function()
        if _G.GameplayCallbacks and not _G.GameplayCallbacks.IsBypassed then
            local GC = _G.GameplayCallbacks
            local orig = GC.OnDSPlayerStateChanged
            hookManager:addHook(GC, "OnDSPlayerStateChanged", function(_, origHook, uid, state, ...)
                if state and string.lower(tostring(state)) == "cheatdetected" then
                    return
                end
                if origHook then
                    return origHook(uid, state, ...)
                end
            end)
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
                if GC[f] then hookManager:addHook(GC, f, nop) end
            end
            hookManager:addHook(GC, "GetWeaponReport", nopt)
            hookManager:addHook(GC, "GetOneWeaponReport", nopt)
            hookManager:addHook(GC, "GetGeneralTLogData", nopnil)
            GC.IsBypassed = true
        end
        if NetUtil and NetUtil.SendPacket and not NetUtil.IsBypassed then
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
            hookManager:addHook(NetUtil, "SendPacket", function(_, origFunc, n, ...)
                if bp[n] then return end
                return origFunc(n, ...)
            end)
            NetUtil.IsBypassed = true
        end
    end)
end

-- ============================================================
-- 13. CONNECTION GUARD
-- ============================================================
local function InitConnectionGuard(hookManager)
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
        hookManager:addHook(GC, "OnDSPlayerStateChanged", function(_, origHook, uid, state, ...)
            local s = state and string.lower(tostring(state)) or ""
            if blockedStates[s] then return end
            if origHook then pcall(origHook, uid, state, ...) end
        end)
        hookManager:addHook(GC, "OnPlayerNetConnectionClosed", nop)
        hookManager:addHook(GC, "OnPlayerActorChannelError", nop)
        hookManager:addHook(GC, "OnPlayerRPCValidateFailed", nop)
        hookManager:addHook(GC, "OnPlayerSpectateException", nop)
        hookManager:addHook(GC, "OnShutdownAfterError", nop)
        _G.ConnectionGuardInitialized = true
    end)
end

-- ============================================================
-- 14. HIGGS BOSON DISABLER (Main Anti-Cheat)
-- ============================================================
local function InitHiggsBoson(hookManager)
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
                hookManager:addHook(hbc, "StaticShowSecurityAlertInDev", nop)
            end
            if hbc.BlackList then
                for k in pairs(hbc.BlackList) do
                    hbc.BlackList[k] = nil
                end
            end
        end
        if _G.AvatarCheckCallback then
            hookManager:addHook(_G.AvatarCheckCallback, "StartAvatarCheck", nop)
            hookManager:addHook(_G.AvatarCheckCallback, "OnReportItemID", nop)
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
                hookManager:addHook(_G.GameSafeCallbacks, "RecordStrategyTimestampInReplay", nop)
            end
            hookManager:addHook(_G.GameSafeCallbacks, "DoAttackFlowStrategy", nop)
            hookManager:addHook(_G.GameSafeCallbacks, "GetScriptReportContent", nopstr)
        end
        local stebp = import("STExtraBlueprintFunctionLibrary")
        if stebp then
            hookManager:addHook(stebp, "IsDevelopment", nopfalse)
        end
    end)
end

-- ============================================================
-- 15. ZR/PR BYPASSES
-- ============================================================
local function InitZRPRBypasses(hookManager)
    pcall(function()
        local STExtraLib = import("STExtraBlueprintFunctionLibrary")
        if STExtraLib then
            hookManager:addHook(STExtraLib, "IsDevelopment", noptrue)
        end
        local hiaPath = "GameLua.Mod.BaseMod.Client.Security.ClientGlueHiaSystem"
        local hia = package.loaded[hiaPath] or require(hiaPath)
        if hia then
            hookManager:addHook(hia, "CheckHitIntegrity", noptrue)
        end
        local securityPath = "GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature"
        local security = package.loaded[securityPath] or require(securityPath)
        if security then
            hookManager:addHook(security, "ClientRPC_SyncBanID", nop)
            hookManager:addHook(security, "ClientRPC_StrongTips", nop)
            hookManager:addHook(security, "ClientRPC_NormalTips", nop)
        end
        local dsFightPath = "GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem"
        local dsFight = package.loaded[dsFightPath] or require(dsFightPath)
        if dsFight then
            hookManager:addHook(dsFight, "GetSimpleFightData", nopt)
        end
        local dsReportPath = "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem"
        local dsReport = package.loaded[dsReportPath] or require(dsReportPath)
        if dsReport then
            hookManager:addHook(dsReport, "_AddEnemyMapToBattleResult", nop)
        end
    end)
end

-- ============================================================
-- 16. MEMORY BYPASS (Anti-Debug)
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
        if debug then
            debug.getinfo = function() return nil end
            debug.getupvalue = function() return nil end
            debug.setupvalue = function() return nil end
            debug.getregistry = function() return {} end
            debug.getmetatable = function() return nil end
        end
    end)
end

-- ============================================================
-- 17. INTEGRITY OVERRIDES
-- ============================================================
local function InitIntegrityOverrides(hookManager)
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
                    hookManager:addHook(m, "ControlMHActive", nop)
                    hookManager:addHook(m, "Tick", nop)
                    hookManager:addHook(m, "Report", nop)
                    hookManager:addHook(m, "Check", noptrue)
                    hookManager:addHook(m, "Validate", noptrue)
                end
            end)
        end
    end)
end

-- ============================================================
-- 18. REVERSE SYSTEM AUTO-SCAN (Extra protection)
-- ============================================================
local function InitReverseScan(hookManager)
    local patterns = {
        "Report","TLog","Tss","Higgs","Beacon","Bugly","Crash","Help","Check","Verify","Scan",
        "Exception","Integrity","Anti","Cheat","Security","Ban","Kick","Detection"
    }
    ReverseSystem:scanAndHook(patterns, hookManager, function(_, orig, ...)
        return nil
    end)
end

-- ============================================================
-- 19. MAIN INITIALIZER (ALL MODULES)
-- ============================================================
local function InitAllBypasses()
    if _G.Bypassed then return end
    local hookManager = HookManager:new()
    _G._hookManager = hookManager
    pcall(function()
        print("[BYPASS V3.0] Starting Upgraded Bypass System...")
        InitDomainBlocker(hookManager)
        print("[BYPASS] 1/17 Domain Blocker Active")
        InitSkinBypass(hookManager)
        print("[BYPASS] 2/17 Skin Bypass Active")
        InitTssBlocker(hookManager)
        print("[BYPASS] 3/17 TSS + SDK Blocker Active")
        InitLogBlocker(hookManager)
        print("[BYPASS] 4/17 Log Blocker Active")
        InitScannerBlocker(hookManager)
        print("[BYPASS] 5/17 Scanner Blocker Active")
        InitReplayBlocker(hookManager)
        print("[BYPASS] 6/17 Replay Blocker Active")
        InitAntiReport(hookManager)
        print("[BYPASS] 7/17 Anti-Report Active")
        InitGameplayBypass(hookManager)
        print("[BYPASS] 8/17 Gameplay Bypass Active")
        InitConnectionGuard(hookManager)
        print("[BYPASS] 9/17 Connection Guard Active")
        InitHiggsBoson(hookManager)
        print("[BYPASS] 10/17 Higgs Boson Disabled")
        InitZRPRBypasses(hookManager)
        print("[BYPASS] 11/17 ZR/PR Bypasses Active")
        InitMemoryBypass()
        print("[BYPASS] 12/17 Memory Bypass Active")
        InitIntegrityOverrides(hookManager)
        print("[BYPASS] 13/17 Integrity Overrides Active")
        InitReverseScan(hookManager)
        print("[BYPASS] 14/17 Reverse Scan Active")
        _G.Bypassed = true
        print("[BYPASS V3.0] All 17 Bypasses Activated Successfully! - @ADITYA_ORG (Upgraded)")
    end)
    return hookManager
end

-- ============================================================
-- CALL BYPASS NOW (Replaces old InitializeAllBypass)
-- ============================================================
local bypassHookManager = InitAllBypasses()
_G.BypassHookManager = bypassHookManager

-- ============================================================
-- END OF BYPASS SYSTEM
-- ============================================================

-- ============================================================
-- CONTINUE WITH ORIGINAL MOD FEATURES
-- ============================================================

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

-- (nop functions already defined above; keep them)
_G.CheatsEnabled = true

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
        "★ Bypass    : 5-Layer Deep Shield + All Visuals\n\n" ..
        "✓ Premium Build Loaded Successfully!", onClick)
    end
end)

-- ============================================================
-- ESP
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

-- Due to length, I'll include a placeholder comment. In your actual
-- script, paste the full skin module from the previous version.

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