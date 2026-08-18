-----v0.014(修復重置腳本)
---------------------------------------
--服務
----------------------------------------
repeat task.wait(0.1) until game:IsLoaded() and game:GetService("Players").LocalPlayer

local Settings = ...

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
local mainUI = playerGui and playerGui:FindFirstChild("Main")
local bottomHUD = mainUI and mainUI:FindFirstChild("BottomHUDList")
local inCombatUI = bottomHUD and bottomHUD:FindFirstChild("InCombat")

-- Fast Attack Serve
local Modules = ReplicatedStorage:WaitForChild("Modules", 10)
local Net = Modules and Modules:WaitForChild("Net", 10)
local RegisterAttack = Net and Net:WaitForChild("RE/RegisterAttack", 10)
local RegisterHit = Net and Net:WaitForChild("RE/RegisterHit", 10)
local RemoteSeed = Net and Net:FindFirstChild("seed")

----------------------------------------
-- 防重複啟用
----------------------------------------
if getgenv().AutoBountyLoaded then
    local StarterGui = game:GetService("StarterGui")
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Banana Cat Hub",
            Text = "腳本已在運行中，請勿重複執行！",
            Duration = 3
        })
    end)
    return
end

getgenv().AutoBountyLoaded = true

-- ==========================================
-- 2. Hook Check (執行器檢測)
-- ==========================================
local executorName = (identifyexecutor and identifyexecutor()) or "Unknown"
local lowerName = string.lower(executorName)

local unsupportedList = {"xeno", "solara"}
local isUnsupportedName = false

for _, name in ipairs(unsupportedList) do
    if string.find(lowerName, name) then
        isUnsupportedName = true
        break
    end
end

local isMissingFunctions = (hookmetamethod == nil) or (getrawmetatable == nil) or (setreadonly == nil)
local disableHook = isUnsupportedName or isMissingFunctions

if disableHook then
    warn("[Anti-Crash] Detected limited executor (" .. executorName .. "). Silent Aim hooks have been disabled to prevent freezing.")
    
    task.spawn(function()
        task.wait(5)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "⚠️ 執行器限制",
                Text = "檢測到不支援 Hook 的執行器 (" .. executorName .. ") 已禁用自瞄以防崩潰 其餘功能正常載入",
                Duration = 15,
                Icon = "rbxassetid://11419714821"
            })
        end)
    end)
end

----------------------------------------
-- WindUI
----------------------------------------
local WindUI = loadstring(request({
    Url = "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
}).Body)()

WindUI:SetTheme(_G.Theme)

local Window = WindUI:CreateWindow({
    Title         = "Banana Cat Hub - Blox Fruit",
    Icon          = "https://raw.githubusercontent.com/okdiannao478-alt/Banana-Cat-Hub/main/IMG_6868.PNG",
    Author        = "2026最新自動獵賞",
    Folder        = "Auto Bounty",
    Size          = UDim2.fromOffset(640, 560),
    Transparent   = false,
    Theme         = "Dark",
    Acrylic       = false,
    HideSearchBar = false,
    SideBarWidth  = 180,
    User = {
        Enabled   = true, Anonymous = false,
        Callback  = function() notify(LocalPlayer.Name, "ID: "..LocalPlayer.UserId, 3) end
    },
    -- 隱藏 WindUI 原本的頂部開啟按鈕，改用左下角自訂圓形按鈕
    OpenButton = {
        Enabled = false,
    }
})

-- Banana Cat Hub：左下角香蕉貓圖片按鈕，只負責顯示/隱藏 UI
local BananaCatHubToggleGui = Instance.new("ScreenGui")
BananaCatHubToggleGui.Name = "BananaCatHubToggleGui"
BananaCatHubToggleGui.ResetOnSpawn = false
BananaCatHubToggleGui.IgnoreGuiInset = true
BananaCatHubToggleGui.DisplayOrder = 9999

pcall(function()
    local oldGui = game:GetService("CoreGui"):FindFirstChild("BananaCatHubToggleGui")
    if oldGui then oldGui:Destroy() end
end)

-- 從 GitHub 取得使用者提供的香蕉貓圖片，使用執行器本地素材載入
local BananaCatHubIconUrl = "https://raw.githubusercontent.com/okdiannao478-alt/Banana-Cat-Hub/main/IMG_6868.PNG"
local BananaCatHubIconPath = "BananaCatHubIcon_6868.png"
local BananaCatHubIconAsset = nil

pcall(function()
    if isfile and writefile and getsynasset then
        if not isfile(BananaCatHubIconPath) then
            local iconResponse = request({ Url = BananaCatHubIconUrl })
            if iconResponse and iconResponse.Body then
                writefile(BananaCatHubIconPath, iconResponse.Body)
            end
        end
        if isfile(BananaCatHubIconPath) then
            BananaCatHubIconAsset = getsynasset(BananaCatHubIconPath)
        end
    end
end)

-- 左下角圓形香蕉貓開關：使用使用者提供的 IMG_6868.PNG，只負責顯示/隱藏 UI
local BananaCatHubToggleButton = Instance.new("ImageButton")
BananaCatHubToggleButton.Name = "BananaCatToggle"
BananaCatHubToggleButton.AnchorPoint = Vector2.new(0, 1)
BananaCatHubToggleButton.Position = UDim2.new(0, 18, 1, -18)
BananaCatHubToggleButton.Size = UDim2.fromOffset(68, 68)
BananaCatHubToggleButton.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
BananaCatHubToggleButton.BackgroundTransparency = 0.05
BananaCatHubToggleButton.BorderSizePixel = 0
BananaCatHubToggleButton.Image = BananaCatHubIconAsset or ""
BananaCatHubToggleButton.ScaleType = Enum.ScaleType.Fit
BananaCatHubToggleButton.AutoButtonColor = true
BananaCatHubToggleButton.ZIndex = 20
BananaCatHubToggleButton.Parent = BananaCatHubToggleGui

local BananaCatHubToggleCorner = Instance.new("UICorner")
BananaCatHubToggleCorner.CornerRadius = UDim.new(1, 0)
BananaCatHubToggleCorner.Parent = BananaCatHubToggleButton

local BananaCatHubToggleStroke = Instance.new("UIStroke")
BananaCatHubToggleStroke.Thickness = 2
BananaCatHubToggleStroke.Color = Color3.fromRGB(255, 255, 255)
BananaCatHubToggleStroke.Transparency = 0.05
BananaCatHubToggleStroke.Parent = BananaCatHubToggleButton

-- 若執行器不支援 getsynasset，至少顯示名稱而不影響開關功能
if not BananaCatHubIconAsset then
    local BananaCatHubFallback = Instance.new("TextLabel")
    BananaCatHubFallback.BackgroundTransparency = 1
    BananaCatHubFallback.Size = UDim2.fromScale(1, 1)
    BananaCatHubFallback.Text = "🍌"
    BananaCatHubFallback.TextSize = 30
    BananaCatHubFallback.Font = Enum.Font.GothamBold
    BananaCatHubFallback.TextColor3 = Color3.fromRGB(255, 224, 80)
    BananaCatHubFallback.ZIndex = 21
    BananaCatHubFallback.Parent = BananaCatHubToggleButton
end

-- 圖示旁的載入通知：自訂外觀，不改動 WindUI 或任何功能邏輯
local BananaCatHubHint = Instance.new("Frame")
BananaCatHubHint.Name = "BananaCatHubHint"
BananaCatHubHint.AnchorPoint = Vector2.new(0, 1)
BananaCatHubHint.Position = UDim2.new(0, 98, 1, -22)
BananaCatHubHint.Size = UDim2.fromOffset(238, 58)
BananaCatHubHint.BackgroundColor3 = Color3.fromRGB(31, 31, 38)
BananaCatHubHint.BackgroundTransparency = 0.08
BananaCatHubHint.BorderSizePixel = 0
BananaCatHubHint.ZIndex = 19
BananaCatHubHint.Parent = BananaCatHubToggleGui

local BananaCatHubHintCorner = Instance.new("UICorner")
BananaCatHubHintCorner.CornerRadius = UDim.new(0, 12)
BananaCatHubHintCorner.Parent = BananaCatHubHint

local BananaCatHubHintStroke = Instance.new("UIStroke")
BananaCatHubHintStroke.Thickness = 1
BananaCatHubHintStroke.Color = Color3.fromRGB(255, 255, 255)
BananaCatHubHintStroke.Transparency = 0.72
BananaCatHubHintStroke.Parent = BananaCatHubHint

local BananaCatHubHintIcon = Instance.new("ImageLabel")
BananaCatHubHintIcon.BackgroundTransparency = 1
BananaCatHubHintIcon.Position = UDim2.fromOffset(8, 7)
BananaCatHubHintIcon.Size = UDim2.fromOffset(44, 44)
BananaCatHubHintIcon.Image = BananaCatHubIconAsset or ""
BananaCatHubHintIcon.ScaleType = Enum.ScaleType.Fit
BananaCatHubHintIcon.ZIndex = 20
BananaCatHubHintIcon.Parent = BananaCatHubHint

local BananaCatHubHintText = Instance.new("TextLabel")
BananaCatHubHintText.BackgroundTransparency = 1
BananaCatHubHintText.Position = UDim2.fromOffset(58, 7)
BananaCatHubHintText.Size = UDim2.new(1, -66, 1, -14)
BananaCatHubHintText.Font = Enum.Font.GothamSemibold
BananaCatHubHintText.Text = "點擊左下角香蕉貓\n開啟 / 關閉 UI"
BananaCatHubHintText.TextColor3 = Color3.fromRGB(255, 255, 255)
BananaCatHubHintText.TextSize = 14
BananaCatHubHintText.TextXAlignment = Enum.TextXAlignment.Left
BananaCatHubHintText.TextYAlignment = Enum.TextYAlignment.Center
BananaCatHubHintText.ZIndex = 20
BananaCatHubHintText.Parent = BananaCatHubHint

task.delay(7, function()
    if BananaCatHubHint and BananaCatHubHint.Parent then
        BananaCatHubHint:Destroy()
    end
end)

local BananaCatHubIsOpen = false
Window:Toggle(false)

BananaCatHubToggleButton.MouseButton1Click:Connect(function()
    BananaCatHubIsOpen = not BananaCatHubIsOpen
    Window:Toggle(BananaCatHubIsOpen)
end)

BananaCatHubToggleGui.Parent = game:GetService("CoreGui")

Window:OnDestroy(function()
    pcall(function()
        if BananaCatHubToggleGui then BananaCatHubToggleGui:Destroy() end
    end)
    getgenv().AutoBountyLoaded = nil
end)

----------------------------------------
--變數
----------------------------------------
--自動換服
_G.ServerRegion = "Singapore"
_G.HopMinPlayers = 6
_G.HopMaxPlayers = 7
_G.HopMinBounty = 3000000
_G.HopMaxBounty = math.huge

--選擇陣營
_G.SelectTeam = "Pirates"

local function SelectTeam()
    local lp = game:GetService("Players").LocalPlayer
    if not lp.Team or lp.Team.Name ~= _G.SelectTeam then
        local args = {
            "SetTeam2",
            _G.SelectTeam
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer(unpack(args))
    end
end

local FilterParagraph = nil

-- Fast Attack
_G.FastAttack = true
_G.FastAttackMode = "模式2(部分帳號失效可使用)"
_G.AttackDistance = 500
_G.FastAttackSpeed = 0.05

--Fruit m1
_G.FruitsM1Enable = true
_G.FruitsM1DelayValue = 0.05

--ESP Players
_G.ESP_Master         = true
_G.ESP_ShowName       = true
_G.ESP_ShowHealth     = true
_G.ESP_ShowDistance   = true
_G.ESP_TeamColor      = true
_G.ESP_ShowLevel      = true
_G.ESP_ShowPVPStatus  = true
_G.ESP_ShowTracers    = false
_G.ESP_TracerColor    = Color3.fromRGB(255, 255, 255)
_G.ESP_HighlightColor = Color3.fromRGB(30, 30, 30)
_G.ESP_FontSize       = 12

local Tracers = {}

--Auto Enabled PVP
_G.AutoEnablePVP = true

--Auto Buso
_G.AutoBusoEnabled = true

--Auto V3
_G.AutoV3_Enabled = true

--Auto V4
_G.AutoV4_Enabled = true

--Auto Ken
_G.AutoKenEnabled = true

--自動順步
_G.AutoSoru = false
local AutoSoruConn = nil
local LastSoruTime = 0
local SORU_COOLDOWN = 10
local MAX_SORU_DISTANCE = 900

--Hitbox
_G.Hitbox_Enabled = false
_G.Hitbox_Size = 1
_G.Hitbox_Transparency = 0.5

--Auto Flee
_G.AutoFlee = true
_G.AutoFleeHP = 30
_G.AutoFleeConn = nil

-- 移除動作
_G.RemoveAnim = true
_G.RemoveAnimCharConn = nil
_G.RemoveAnimTrackConn = nil

-- Walk on water
_G.WaterWalkEnabled = true

--移除岩漿傷害
_G.RemoveLavaEnabled = true
local lavaRemoved = false

-- 移除鬼船傷害
_G.RemoveGhostShipLavaEnabled = true
local ghostShipLavaRemoved = false

--自動列賞
_G.FTP2_Enabled = false
_G.FTP2_FlightConn = nil
_G.FTP2_PlayerLeaveConn = nil
_G.FTP2_Attachment = nil
_G.FTP2_LinearVelocity = nil
_G.FTP2_AntiGravity = nil
_G.FTP2_LastTeleportTicks = {}
_G.FTP2_TeleportPauseUntil = 0
_G.FTP2_TeleportFails = {}
_G.FTP2_BlockedEntrances = {}
_G.FTP2_Blacklist = {}
_G.FTP2_HasTriggeredHop = false
_G.FTP2_TimeoutLimit = 120

_G.FTP2_HistoryWindow = 0.35
_G.FTP2_ClearTimeout = 10
_G.FTP2_FlySpeed = 275
_G.FTP2_HeightOffset = 30
_G.FTP2_OrbitRadius = 50
_G.FTP2_OrbitInterval = 0.016
_G.FTP2_LowHpLockPercent = 30
_G.FTP2_NoTeleportRange = 300
_G.FTP2_CurrentTarget = nil
_G.FTP2_TargetLockTime = 0
_G.TargetHistory = {}
_G.FTP2_StartTime = 0
_G.FTP2_FleeReturnPos = nil

_G.FTP2_SafeZonePositions = {
    World1 = {
        { pos = Vector3.new(-3000, 250, 2057), radius = 700 },
        { pos = Vector3.new(1101, 16, 1446), radius = 400 },
    },
    World2 = {
        { pos = Vector3.new(-12, 29, 2840), radius = 200 },
        { pos = Vector3.new(-376, 149, 307), radius = 150 },
        { pos = Vector3.new(-6437, 306, -4730), radius = 150 },
    },
    World3 = {
        { pos = Vector3.new(-338, 21, 5539), radius = 200 },
        { pos = Vector3.new(-12550, 337, -7506), radius = 400 },
        { pos = Vector3.new(-5046, 315, -2993), radius = 300 },
        { pos = Vector3.new(-16228, 9, 443), radius = 300 },
        { pos = Vector3.new(28695, 14959, -81), radius = 10000 },
        { pos = Vector3.new(9637, -1989, 9618), radius = 10000 },
    }
}

local StartServerHop
local IsSafeToHopCheck

--自瞄
_G.SilentAimEnabled = true
_G.SilentAimTargetMode = "目前鎖定的目標玩家"
_G.SilentAimTeamCheck = true
local currentSilentAimTarget = nil
local currentSilentAimTargetPos = nil

--Camlock
_G.CamlockEnabled = false

--自動放技能
_G.AutoSkillMainEnable = false
_G.AutoSkillWeapons = {
    ["Melee"] = {
        Enable = false,
        Skills = {
            Z = { Enable = false, HoldTime = 0 },
            X = { Enable = false, HoldTime = 0 },
            C = { Enable = false, HoldTime = 0 },
        }
    },
    ["Blox Fruit"] = {
        Enable = false,
        Skills = {
            Z = { Enable = false, HoldTime = 0 },
            X = { Enable = false, HoldTime = 0 },
            C = { Enable = false, HoldTime = 0 },
            V = { Enable = false, HoldTime = 0 },
            F = { Enable = false, HoldTime = 0 },
        }
    },
    ["Gun"] = {
        Enable = false,
        Skills = {
            Z = { Enable = false, HoldTime = 0 },
            X = { Enable = false, HoldTime = 0 },
        }
    },
    ["Sword"] = {
        Enable = false,
        Skills = {
            Z = { Enable = false, HoldTime = 0 },
            X = { Enable = false, HoldTime = 0 },
        }
    },
}

local SkillKeyMap = {
    Z = Enum.KeyCode.Z,
    X = Enum.KeyCode.X,
    C = Enum.KeyCode.C,
    V = Enum.KeyCode.V,
    F = Enum.KeyCode.F
}
local SkillCoolDownTrack = {}

--FPS
_G.UnlockFPS = true

--低配模式
_G.LowVisualMode = false
_G.LowVisualConnection = nil

--移除迷霧
_G.RemoveFogEnabled = true

--anti AFK
_G.AntiAFK_ENABLED = true
_G.AntiAFK_Connection = nil

--anti kick
_G.AutoRejoinEnabled = true

--自動執行
local queue_on_teleport = queue_on_teleport or (syn and syn.queue_on_teleport)

if isfile and isfile("AutoBounty.file") then
    local success, content = pcall(function() return readfile("AutoBounty.file") end)
    _G.AutoExecute = (success and content == "true")
else
    _G.AutoExecute = true
end

local ScriptLoadstring = [[if isfile("AutoBounty.file") then
    if readfile("AutoBounty.file") == "true" then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/okdiannao478-alt/Banana-Cat-Hub/main/BananaCatHub.lua"))()
    end
end]]

--主題
_G.Theme = "Dark"

local availableThemes = WindUI:GetThemes()
local themeList = {}
for themeName, _ in pairs(availableThemes) do
    table.insert(themeList, themeName)
end

--自動隱藏UI
_G.AutoHideEnabled = false

--快捷鍵
_G.CurrentKey = "G"
_G.KeyDisabled = false

----------------------------------------
-- [FIX 4] 配置自動保存
----------------------------------------
local ConfigFolder = "AutoBounty_Config"
local ConfigFile = ConfigFolder .. "/settings_" .. tostring(LocalPlayer.UserId) .. ".json"
local ConfigReady = false
local ConfigSaving = false
local ConfigDirty = false

local ConfigKeys = {
    "ServerRegion", "HopMinPlayers", "HopMaxPlayers","HopMinBounty", "HopMaxBounty",
    "FastAttack", "FastAttackMode", "AttackDistance", "FastAttackSpeed", "FruitsM1Enable", "FruitsM1DelayValue",
    "ESP_Master", "ESP_ShowName", "ESP_ShowHealth", "ESP_ShowDistance", "ESP_ShowTracers", "ESP_TeamColor", "ESP_ShowLevel", "ESP_ShowPVPStatus", "ESP_FontSize",
    "AutoEnablePVP",
    "AutoBusoEnabled",
    "AutoV3_Enabled",
    "AutoV4_Enabled",
    "AutoKenEnabled",
    "AutoSoru",
    "Hitbox_Enabled", "Hitbox_Size", "Hitbox_Transparency",
    "AutoFlee", "AutoFleeHP",
    "RemoveAnim",
    "WaterWalkEnabled",
    "RemoveLavaEnabled",
    "RemoveGhostShipLavaEnabled",
    "SelectTeam",
    "FTP2_Enabled", "FTP2_FlySpeed", "FTP2_HeightOffset", "FTP2_OrbitRadius", "FTP2_OrbitInterval", "FTP2_LowHpLockPercent", "FTP2_NoTeleportRange", "FTP2_TimeoutLimit", "FTP2_HistoryWindow", "FTP2_ClearTimeout",
    "SilentAimEnabled", "SilentAimTargetMode", "SilentAimTeamCheck",
    "CamlockEnabled",
    "AutoSkillMainEnable", "AutoSkillWeapons",
    "UnlockFPS",
    "LowVisualMode",
    "RemoveFogEnabled",
    "AntiAFK_ENABLED", "AutoRejoinEnabled",
    "AutoExecute",
    "Theme",
    "AutoHideEnabled",
    "CurrentKey", "KeyDisabled",
}

local function CopyConfigValue(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, item in pairs(value) do
        copy[key] = CopyConfigValue(item)
    end
    return copy
end

local function CollectConfig()
    local data = {}
    for _, key in ipairs(ConfigKeys) do
        if _G[key] ~= nil then
            data[key] = CopyConfigValue(_G[key])
        end
    end
    return data
end

local function ApplyConfig(data)
    if type(data) ~= "table" then return end
    for _, key in ipairs(ConfigKeys) do
        if data[key] ~= nil then
            _G[key] = CopyConfigValue(data[key])
        end
    end
end

local function SaveConfig(force)
    if ConfigSaving or (not force and not ConfigDirty) or typeof(writefile) ~= "function" then
        return false
    end
    ConfigSaving = true
    local ok = pcall(function()
        if typeof(isfolder) == "function" and typeof(makefolder) == "function" and not isfolder(ConfigFolder) then
            makefolder(ConfigFolder)
        end
        writefile(ConfigFile, HttpService:JSONEncode(CollectConfig()))
    end)
    ConfigSaving = false
    if ok then ConfigDirty = false end
    return ok
end

local function LoadConfig()
    if typeof(readfile) ~= "function" or typeof(isfile) ~= "function" or not isfile(ConfigFile) then
        return false
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(ConfigFile))
    end)
    if ok and type(data) == "table" then
        ApplyConfig(data)
        return true
    end
    return false
end

local function MarkConfigDirty()
    ConfigDirty = true
end

local InitialConfig = CollectConfig()
LoadConfig()
if type(Settings) == "table" then
    ApplyConfig(Settings)
end
ConfigReady = true

SelectTeam()

task.spawn(function()
    while task.wait(3) do
        if ConfigReady and ConfigDirty then
            SaveConfig(true)
        end
    end
end)

----------------------------------------
--功能核心邏輯
----------------------------------------
--自動換服
local RegionValues = {
    "Oregon",
    "Florida",
    "Texas",
    "California",
    "HongKong",
    "Germany",
    "Brazil",
    "Singapore",
}

local function FormatNumber(n)
    local num = math.floor(tonumber(n) or 0)
    local str = tostring(num)
    local k
    while true do
        str, k = string.gsub(str, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return str
end

local function ParseServerInfo(text)
    if type(text) ~= "string" or text == "" then
        return nil
    end

    local region = text:match("Region:%s*(.-)%s*%-%s*Players:") or text:match("Region:%s*(.-)%s*$")
    local currentPlayers, maxPlayers = text:match("Players:%s*(%d+)%s*/%s*(%d+)")
    local bountyText = text:match("Bounty:%s*([%d,]+)")

    if not currentPlayers or not maxPlayers or not bountyText then
        return nil
    end

    local bounty = tonumber((bountyText:gsub(",", "")))
    if not bounty then
        return nil
    end

    return {
        Region = region or "Unknown",
        Players = tonumber(currentPlayers),
        MaxPlayers = tonumber(maxPlayers),
        Bounty = bounty,
        Raw = text,
    }
end

local function IsServerAllowed(info)
    if not info then
        return false
    end

    local minP = tonumber(_G.HopMinPlayers) or 6
    local maxP = tonumber(_G.HopMaxPlayers) or 7
    local minB = tonumber(_G.HopMinBounty) or 3000000
    local maxB = tonumber(_G.HopMaxBounty) or math.huge

    if info.Players < minP or info.Players > maxP then
        return false
    end

    -- 排除已滿伺服器（人數 >= 伺服器上限）
    local maxPlayers = tonumber(info.MaxPlayers) or 0
    if maxPlayers > 0 and info.Players >= maxPlayers then
        return false
    end

    if info.Bounty < minB or info.Bounty > maxB then
        return false
    end

    if _G.ServerRegion and _G.ServerRegion ~= "" then
        local targetRegion = tostring(_G.ServerRegion):lower()
        local serverRegion = tostring(info.Region):lower()
        if not serverRegion:find(targetRegion, 1, true) then
            return false
        end
    end

    return true
end

local function BuildFilterText()
    local bountyStr
    local minB = tonumber(_G.HopMinBounty) or 3000000
    local maxB = _G.HopMaxBounty

    if maxB == math.huge or not maxB then
        bountyStr = string.format("≥ %s", FormatNumber(minB))
    else
        bountyStr = string.format("%s ~ %s", FormatNumber(minB), FormatNumber(maxB))
    end

    return string.format(
        "🌐 地區｜%s\n👥 人數｜%d ~ %d 人\n💰 賞金｜%s",
        tostring(_G.ServerRegion),
        tonumber(_G.HopMinPlayers) or 6,
        tonumber(_G.HopMaxPlayers) or 7,
        bountyStr
    )
end

local function BuildServerInfoText(info, job)
    return string.format(
        "🌐 地區｜%s\n👥 人數｜%s / %s\n💰 賞金｜%s\n🆔 序號｜%s",
        tostring(info.Region),
        tostring(info.Players),
        tostring(info.MaxPlayers),
        FormatNumber(info.Bounty),
        tostring(job)
    )
end

local function SetParagraphDesc(paragraph, text)
    if not paragraph then return end
    if paragraph.SetDesc then
        paragraph:SetDesc(text)
    elseif paragraph.Set then
        paragraph:Set({ Desc = text })
    elseif paragraph.SetTitle then
        paragraph:SetTitle(paragraph.Title or "當前篩選", text)
    end
end

local function RefreshFilterParagraph()
    SetParagraphDesc(FilterParagraph, BuildFilterText())
end

local function StopServerHop()
    getgenv().IsServerHopping = false
    getgenv().ShuttingDown = false

    if getgenv().ServerHopHiddenGui then
        getgenv().ServerHopHiddenGui = nil
        local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local serverBrowser = PlayerGui and PlayerGui:FindFirstChild("ServerBrowser")
        if serverBrowser then
            pcall(function()
                serverBrowser.Enabled = false
                if serverBrowser:FindFirstChild("Frame") then
                    serverBrowser.Frame.Visible = true
                end
            end)
        end
    end

end

local function StartServerHop()
    if getgenv().IsServerHopping == true then
        return
    end

    getgenv().IsServerHopping = true
    getgenv().ShuttingDown = true

    -- [換服超時] 開始換服後若未在3分鐘內成功換服：三海進二海、二海進三海，其餘重進伺服器
    local hopStartTime = tick()
    task.spawn(function()
        while getgenv().IsServerHopping do
            if tick() - hopStartTime >= 180 then
                local placeId = game.PlaceId
                if table.find({7449423635, 100117331123089}, placeId) then
                    -- 三海 → 二海
                    pcall(function()
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelDressrosa")
                    end)
                elseif table.find({4442272183, 79091703265657}, placeId) then
                    -- 二海 → 三海
                    pcall(function()
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelZou")
                    end)
                else
                    -- 其他(一海) → 執行重進伺服器
                    pcall(function()
                        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
                    end)
                end
                getgenv().IsServerHopping = false
                return
            end
            task.wait(5)
        end
    end)

    -- [安全檢查] 必須安全且無PVP狀態才能開始換服
    if IsSafeToHopCheck and not IsSafeToHopCheck() then
        while getgenv().IsServerHopping and IsSafeToHopCheck and not IsSafeToHopCheck() do
            task.wait(1)
        end
        if not getgenv().IsServerHopping then
            return
        end
    end

    local currentJobId = game.JobId
    local triedJobs = {}
    local ServerBrowserRemote = ReplicatedStorage:FindFirstChild("__ServerBrowser")

    local directServers = nil
    if ServerBrowserRemote then
        for _, method in ipairs({ "getServers", "fetchServers", "getServerList", "fetch", "servers", "searchServers" }) do
            local ok, result = pcall(function()
                return ServerBrowserRemote:InvokeServer(method)
            end)
            if ok and type(result) == "table" then
                local arr = result.Servers or result.ServerList or result.Data or result
                if type(arr) == "table" then
                    local parsed = {}
                    for _, s in ipairs(arr) do
                        if type(s) == "table" then
                            local jobId = s.JobId or s.Job or s.id or s.teleportData
                            if type(jobId) == "string" and tostring(jobId):find("-", 1, true) then
                                table.insert(parsed, {
                                    JobId = tostring(jobId),
                                    Region = tostring(s.Region or s.RegionName or s.region or ""),
                                    Players = tonumber(s.Players or s.PlayerCount or s.CurrentPlayers or s.currentPlayers) or 0,
                                    MaxPlayers = tonumber(s.MaxPlayers or s.MaximumPlayers or s.maxPlayers) or 0,
                                    Bounty = tonumber(s.Bounty or s.ServerBounty or s.bounty) or 0,
                                })
                            end
                        end
                    end
                    if #parsed > 0 then
                        directServers = parsed
                        break
                    end
                end
            end
        end
    end

    local useHiddenGui = false
    local Inside = nil
    if not directServers then
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
        local serverBrowser = PlayerGui:FindFirstChild("ServerBrowser")

        if not serverBrowser then
            getgenv().IsServerHopping = false
            return
        end

        useHiddenGui = true
        getgenv().ServerHopHiddenGui = true

        pcall(function()
            if serverBrowser:FindFirstChild("Frame") then
                serverBrowser.Frame.Visible = false
            end
        end)

        serverBrowser.Enabled = true

        pcall(function()
            if serverBrowser:FindFirstChild("Frame") then
                serverBrowser.Frame.Visible = false
            end
        end)

        local Filters = serverBrowser.Frame:FindFirstChild("Filters")
        local SearchRegion = Filters and Filters:FindFirstChild("SearchRegion")
        local TextBox = SearchRegion and SearchRegion:FindFirstChild("TextBox")
        if TextBox then
            TextBox.Text = _G.ServerRegion
        end

        local ScrollingFrame = serverBrowser.Frame.ScrollingFrame
        local FakeScroll = serverBrowser.Frame.FakeScroll
        Inside = FakeScroll and FakeScroll:FindFirstChild("Inside")

        task.spawn(function()
            while getgenv().IsServerHopping do
                if ScrollingFrame then
                    ScrollingFrame.CanvasPosition = Vector2.new(0, math.random(100, 7000))
                end
                task.wait(0.3)
            end
        end)
    end

    task.wait(0.5)

    task.spawn(function()
        while getgenv().IsServerHopping do
            local candidate = nil

            if directServers then
                for _, s in ipairs(directServers) do
                    if s.JobId ~= currentJobId and not triedJobs[s.JobId] then
                        local info = {
                            Region = s.Region,
                            Players = s.Players,
                            MaxPlayers = s.MaxPlayers,
                            Bounty = s.Bounty,
                        }
                        if IsServerAllowed(info) then
                            candidate = { info = info, job = s.JobId }
                            break
                        end
                    end
                end
            elseif useHiddenGui and Inside then
                for _, template in ipairs(Inside:GetChildren()) do
                    if template.Name == "Template" then
                        local joinButton = template:FindFirstChild("Join")
                        local textLabel = template:FindFirstChild("TextLabel")
                        local info = textLabel and ParseServerInfo(textLabel.Text)

                        if joinButton and info and IsServerAllowed(info) then
                            local job = joinButton:GetAttribute("Job")
                            if job and tostring(job):find("-", 1, true) then
                                job = tostring(job)
                                if job ~= currentJobId and not triedJobs[job] then
                                    candidate = { info = info, job = job }
                                    break
                                end
                            end
                        end
                    end
                end
            end

            if candidate and getgenv().IsServerHopping then
                -- 換服前再次確認安全且無PVP狀態
                if IsSafeToHopCheck and not IsSafeToHopCheck() then
                    task.wait(1)
                else
                    pcall(function()
                        ServerBrowserRemote:InvokeServer("teleport", candidate.job)
                    end)

                    triedJobs[candidate.job] = true
                end
            end

            task.wait(5)
        end
    end)
end

--Fast Attack
local function IsAlive(char)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local Settings = {
    MaxTargets = 20,
    AutoScanRemotes = true
}

local State = {
    FoundRemote = nil,
    FoundRemoteId = nil,
    consecutiveFailures = 0,
    maxConsecutiveFailures = 5,
    
    M1_Remotes = nil,
    M1_Net = nil,
    M1_RegisterAttack = nil,
    M1_RegisterHit = nil,
    M1_Enemies = nil
}

local function GetRandomValidPart(target)
    if not target then return nil end
    local hrp = target:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local parts = { 
        target:FindFirstChild("Head"), 
        target:FindFirstChild("UpperTorso"), 
        target:FindFirstChild("LowerTorso"), 
        target:FindFirstChild("Torso"), 
        hrp 
    }
    local validParts = {}
    for _, p in ipairs(parts) do
        if p and p:IsA("BasePart") then table.insert(validParts, p) end
    end
    if #validParts > 0 then return validParts[math.random(1, #validParts)] end
    return hrp
end

if Settings.AutoScanRemotes then
    task.spawn(function()
        local folders = { 
            ReplicatedStorage:FindFirstChild("Util"), 
            ReplicatedStorage:FindFirstChild("Common"), 
            ReplicatedStorage:FindFirstChild("Remotes"), 
            ReplicatedStorage:FindFirstChild("Assets"), 
            ReplicatedStorage:FindFirstChild("FX") 
        }
        local function checkChild(child)
            if child:IsA("RemoteEvent") and child:GetAttribute("Id") then
                State.FoundRemoteId = child:GetAttribute("Id")
                State.FoundRemote = child
            end
        end
        for _, folder in ipairs(folders) do
            if folder then
                for _, child in ipairs(folder:GetChildren()) do checkChild(child) end
                folder.ChildAdded:Connect(checkChild)
            end
        end
    end)
end

local function M1_CheckAndGetCoreComponents()
    if State.M1_Remotes and State.M1_Net and State.M1_RegisterAttack and State.M1_RegisterHit and State.M1_Enemies then
        return State.M1_Remotes, State.M1_Net, State.M1_RegisterAttack, State.M1_RegisterHit, State.M1_Enemies
    end
    local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local Modules = ReplicatedStorage:FindFirstChild("Modules")
    local NetInstance = Modules and Modules:FindFirstChild("Net")
    local RegAttack = NetInstance and (NetInstance:FindFirstChild("RE/RegisterAttack") or NetInstance:FindFirstChild("RegisterAttack"))
    local RegHit = NetInstance and (NetInstance:FindFirstChild("RE/RegisterHit") or NetInstance:FindFirstChild("RegisterHit"))
    local Enemies = workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("NPCs")
    
    if Remotes and Modules and NetInstance and RegAttack and RegHit and Enemies then
        State.M1_Remotes = Remotes
        State.M1_Net = NetInstance
        State.M1_RegisterAttack = RegAttack
        State.M1_RegisterHit = RegHit
        State.M1_Enemies = Enemies
        return Remotes, NetInstance, RegAttack, RegHit, Enemies
    end
    return nil, nil, nil, nil, nil
end

local function M1_GatherAllTargets(OthersEnemies)
    local myPos = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and LocalPlayer.Character.PrimaryPart.Position
    if not myPos then return nil end
    
    local firstPart = nil
    
    local _, _, _, _, EnemiesFolder = M1_CheckAndGetCoreComponents()
    if EnemiesFolder then
        for _, Enemy in ipairs(EnemiesFolder:GetChildren()) do
            if Enemy == LocalPlayer.Character or not IsAlive(Enemy) then continue end
            local enemyRoot = Enemy:FindFirstChild("HumanoidRootPart")
            if not enemyRoot then continue end
            
            if (enemyRoot.Position - myPos).Magnitude < _G.AttackDistance then
                local foundPart = GetRandomValidPart(Enemy)
                if foundPart then
                    table.insert(OthersEnemies, {Enemy, foundPart})
                    if not firstPart then firstPart = foundPart end
                end
            end
        end
    end
    
    for _, OtherPlayer in ipairs(Players:GetPlayers()) do
        if OtherPlayer == LocalPlayer then continue end
        local OtherChar = OtherPlayer.Character
        if not IsAlive(OtherChar) then continue end
        local enemyRoot = OtherChar:FindFirstChild("HumanoidRootPart")
        if not enemyRoot then continue end
        
        if (enemyRoot.Position - myPos).Magnitude < _G.AttackDistance then
            local foundPart = GetRandomValidPart(OtherChar)
            if foundPart then
                table.insert(OthersEnemies, {OtherChar, foundPart})
                if not firstPart then firstPart = foundPart end
            end
        end
    end
    
    return firstPart
end

local function M1_Attack(BasePart, OthersEnemies)
    local _, _, temp_RegisterAttack, temp_RegisterHit, _ = M1_CheckAndGetCoreComponents()
    if not (BasePart and OthersEnemies and #OthersEnemies > 0 and temp_RegisterAttack and temp_RegisterHit) then
        State.consecutiveFailures = State.consecutiveFailures + 1
        if State.consecutiveFailures >= State.maxConsecutiveFailures then
            State.M1_Remotes = nil; State.M1_Net = nil; State.M1_RegisterAttack = nil; State.M1_RegisterHit = nil; State.M1_Enemies = nil; State.consecutiveFailures = 0
        end
        return
    end
    State.consecutiveFailures = 0
    local success, _ = pcall(function()
        temp_RegisterAttack:FireServer(0.3)
        temp_RegisterHit:FireServer(BasePart, OthersEnemies)
    end)
    if not success then State.M1_RegisterAttack = nil; State.M1_RegisterHit = nil end
end

local function PerformAttackMode1()
    local OthersEnemies = {}
    local primaryTargetPart = M1_GatherAllTargets(OthersEnemies)
    if #OthersEnemies > 0 then 
        M1_Attack(primaryTargetPart, OthersEnemies) 
    end
end

local function GetMode2Targets()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return {} end
    local targets = {}
    local myPos = root.Position
    
    local sourceFolders = {
        workspace:FindFirstChild("Enemies"),
        workspace:FindFirstChild("NPCs"),
        workspace:FindFirstChild("Characters")
    }
    
    local function checkModel(model)
        if not model or model == char then return end
        local tRoot = model:FindFirstChild("HumanoidRootPart")
        local tHum = model:FindFirstChild("Humanoid")
        if tRoot and tHum and tHum.Health > 0 then
            local dist = (tRoot.Position - myPos).Magnitude
            if dist <= _G.AttackDistance then
                table.insert(targets, { 
                    Model = model, 
                    Root = tRoot, 
                    Head = model:FindFirstChild("Head") or tRoot 
                })
            end
        end
    end

    for _, folder in ipairs(sourceFolders) do
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                if #targets >= Settings.MaxTargets then break end
                checkModel(model)
            end
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if #targets >= Settings.MaxTargets then break end
        if player ~= LocalPlayer and player.Character then
            checkModel(player.Character)
        end
    end
    
    return targets
end

local function PerformAttackMode2()
    local char = LocalPlayer.Character
    if not char then return end
    local hasTool = char:FindFirstChildOfClass("Tool") or char:FindFirstChild("EquippedWeapon")
    if not hasTool then return end
    
    local targets = GetMode2Targets()
    if #targets == 0 then return end
    
    local mainTarget = targets[1]
    local hitList = {}
    for i, target in ipairs(targets) do 
        table.insert(hitList, {target.Model, target.Root}) 
    end
    
    RegisterAttack:FireServer(0)
    
    local fakeHash = tostring(LocalPlayer.UserId):sub(2,4) .. tostring(math.random(10000, 99999))
    pcall(function()
        RegisterHit:FireServer(mainTarget.Head, hitList, {}, fakeHash)
    end)
    
    if State.FoundRemote and State.FoundRemoteId then
        pcall(function()
            local seedValue = RemoteSeed and RemoteSeed:InvokeServer() or 1
            local encryptedId = bit32.bxor(State.FoundRemoteId + 909090, seedValue * 2)
            local rawName = "RE/RegisterHit"
            local timestamp = math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1
            local encryptedName = string.gsub(rawName, ".", function(c) 
                return string.char(bit32.bxor(string.byte(c), timestamp)) 
            end)
            State.FoundRemote:FireServer(encryptedName, encryptedId, mainTarget.Head, hitList)
        end)
    end
end

local function PerformAttack()
    if _G.FastAttackMode == "模式1" then
        local Character = LocalPlayer.Character
        local Equipped = Character and IsAlive(Character) and Character:FindFirstChildOfClass("Tool")
        if not Equipped or Equipped.ToolTip == "Gun" then return end
        PerformAttackMode1()
    else
        PerformAttackMode2()
    end
end

local manualConnection = nil

local function stopManual()
    if manualConnection then
        manualConnection:Disconnect()
        manualConnection = nil
    end
end

local function startManual()
    if manualConnection then return end
    manualConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if _G.FastAttack then return end 
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            pcall(PerformAttack)
        end
    end)
end

if not _G.FastAttack then startManual() end

LocalPlayer.CharacterRemoving:Connect(function() stopManual() end)
LocalPlayer.CharacterAdded:Connect(function()
    if not _G.FastAttack then startManual() end
end)

local isRunning = true
task.spawn(function()
    while isRunning do
        local startTime = tick()
        
        if _G.FastAttack then
            pcall(PerformAttack)
        end
        
        local elapsed = tick() - startTime
        local waitTime = math.max((_G.FastAttackSpeed or 0.05) - elapsed, 0.001)
        task.wait(waitTime)
    end
end)

--Fruit M1
local function GetFruitRemote()
    for _, loc in ipairs({ LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack") }) do
        if loc then
            for _, tool in ipairs(loc:GetChildren()) do
                local remote = tool:IsA("Tool") and tool:FindFirstChild("LeftClickRemote", true)
                if remote then 
                    return remote, tool.Name 
                end
            end
        end
    end
    return nil, "不是M1果實"
end

task.spawn(function()
    while true do
        if _G.FruitsM1Enable then
            local char   = LocalPlayer.Character
            local hrp    = char and char:FindFirstChild("HumanoidRootPart")
            local remote = GetFruitRemote()
            if hrp and remote then 
                remote:FireServer(-hrp.CFrame.UpVector, 2, true) 
            end
        end
        task.wait(_G.FruitsM1DelayValue)
    end
end)

--ESP Players
local function CheckPVP(plr)
    if plr:GetAttribute("PvpDisabled") == false then return true end
    if plr:GetAttribute("InCombat") == true or plr:GetAttribute("CombatPd") == true then return true end
    for name, value in pairs(plr:GetAttributes()) do
        if string.find(string.lower(name), "pvp") and value == true then return true end
    end
    local ls = plr:FindFirstChild("leaderstats")
    if ls and ls:FindFirstChild("PVP") then
        local v = ls.PVP.Value
        if v == "Enabled" or v == true then return true end
    end
    return false
end

local function removeTracer(p)
    if Tracers[p] then
        Tracers[p].Visible = false
        Tracers[p]:Remove()
        Tracers[p] = nil
    end
end

local function removeESP(p)
    removeTracer(p)
    if p.Character then
        local h = p.Character:FindFirstChild("ESP_Highlight")
        if h then h:Destroy() end
        local head = p.Character:FindFirstChild("Head")
        if head then
            local bill = head:FindFirstChild("ESP_Billboard")
            if bill then bill:Destroy() end
        end
    end
end

local function createESP(p)
    if p == LocalPlayer or not _G.ESP_Master then return end
    local char = p.Character if not char then return end
    local head = char:FindFirstChild("Head") if not head then return end
    
    if not char:FindFirstChild("ESP_Highlight") then
        local h = Instance.new("Highlight")
        h.Name = "ESP_Highlight"
        h.FillColor = _G.ESP_HighlightColor
        h.OutlineColor = Color3.fromRGB(255, 255, 255)
        h.FillTransparency = 0.55
        h.OutlineTransparency = 0.1
        h.Adornee = char
        h.Parent = char
    end
    
    if not head:FindFirstChild("ESP_Billboard") then
        local bill = Instance.new("BillboardGui")
        bill.Name = "ESP_Billboard"
        bill.AlwaysOnTop = true
        bill.Size = UDim2.new(0, 200, 0, 110)
        bill.StudsOffset = Vector3.new(0, 4.5, 0)
        bill.Adornee = head
        bill.Parent = head
        
        local text = Instance.new("TextLabel", bill)
        text.Name = "InfoLabel"
        text.Size = UDim2.new(1, 0, 0, 80)
        text.BackgroundTransparency = 1
        text.TextStrokeTransparency = 0.1
        text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        text.Font = Enum.Font.GothamBold
        text.TextSize = _G.ESP_FontSize
        text.TextColor3 = Color3.fromRGB(255, 255, 255)
        text.RichText = true
        text.TextYAlignment = Enum.TextYAlignment.Bottom
        
        local barBG = Instance.new("Frame", bill)
        barBG.Name = "HealthBarBG"
        barBG.Size = UDim2.new(0, 110, 0, 5)
        barBG.Position = UDim2.new(0.5, -55, 0, 90)
        barBG.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        barBG.BorderSizePixel = 0
        barBG.Visible = false
        
        local cornerBG = Instance.new("UICorner")
        cornerBG.CornerRadius = UDim.new(1, 0)
        cornerBG.Parent = barBG
        
        local barFG = Instance.new("Frame", barBG)
        barFG.Name = "HealthBarFG"
        barFG.Size = UDim2.new(1, 0, 1, 0)
        barFG.BackgroundColor3 = Color3.fromRGB(0, 255, 130)
        barFG.BorderSizePixel = 0
        
        local cornerFG = Instance.new("UICorner")
        cornerFG.CornerRadius = UDim.new(1, 0)
        cornerFG.Parent = barFG
    end
end

local function updateTracer(p, targetHRP)
    if not _G.ESP_ShowTracers or not _G.ESP_Master then 
        removeTracer(p)
        return 
    end
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myHRP and targetHRP then
        local currentCam = workspace.CurrentCamera
        local startPos, startEv = currentCam:WorldToViewportPoint(myHRP.Position)
        local endPos, ev = currentCam:WorldToViewportPoint(targetHRP.Position)
        if ev and startEv then
            local tr = Tracers[p] or Drawing.new("Line")
            Tracers[p] = tr
            tr.Visible = true
            tr.From = Vector2.new(startPos.X, startPos.Y)
            tr.To = Vector2.new(endPos.X, endPos.Y)
            
            if _G.ESP_TeamColor and p.TeamColor then
                tr.Color = p.TeamColor.Color
            else
                tr.Color = _G.ESP_TracerColor
            end
            tr.Thickness = 1.8
            tr.Transparency = 0.75
        else
            removeTracer(p)
        end
    else
        removeTracer(p)
    end
end

RunService.RenderStepped:Connect(function()
    if not _G.ESP_Master then return end
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character
        if not char then removeESP(p) continue end
        local head = char:FindFirstChild("Head")
        local hrp2 = char:FindFirstChild("HumanoidRootPart")
        local hum2 = char:FindFirstChildOfClass("Humanoid")
        if not (head and hrp2 and hum2) then removeESP(p) continue end

        createESP(p)

        if _G.ESP_ShowTracers then
            updateTracer(p, hrp2)
        else
            removeTracer(p)
        end

        local bill = head:FindFirstChild("ESP_Billboard")
        local h = char:FindFirstChild("ESP_Highlight")
        if not (bill and h) then continue end

        if _G.ESP_TeamColor and p.TeamColor then
            h.OutlineColor = p.TeamColor.Color
        else
            h.OutlineColor = Color3.fromRGB(255, 255, 255)
        end

        local info = bill:FindFirstChild("InfoLabel")
        local barBG = bill:FindFirstChild("HealthBarBG")
        local barFG = barBG and barBG:FindFirstChild("HealthBarFG")

        if info then
            local display = ""
            if _G.ESP_ShowName then
                display = display .. "<b>" .. p.Name .. "</b>\n"
            end
            if _G.ESP_ShowLevel then
                local lv = "???"
                local data = p:FindFirstChild("Data") or p:FindFirstChild("leaderstats")
                if data and data:FindFirstChild("Level") then lv = data.Level.Value end
                display = display .. '<font color="#FFFFFF">Lv. ' .. tostring(lv) .. '</font>\n'
            end
            if _G.ESP_ShowPVPStatus then
                if CheckPVP(p) then
                    display = display .. '<font color="#00FF88">[ Safe PVP ]</font>\n'
                else
                    display = display .. '<font color="#FF4D4D">[ Enabled PVP ]</font>\n'
                end
            end
            local hpText = ""
            if _G.ESP_ShowHealth then
                hpText = '<font color="#FFFFFF">HP: ' .. math.floor(hum2.Health) .. "/" .. math.floor(hum2.MaxHealth) .. '</font> '
            end
            local distText = ""
            if _G.ESP_ShowDistance and myHRP then
                distText = '<font color="#FFFFFF">[' .. math.floor((myHRP.Position - hrp2.Position).Magnitude) .. 'm]</font>'
            end
            if _G.ESP_ShowHealth or _G.ESP_ShowDistance then
                display = display .. hpText .. distText .. "\n"
            end
            info.Text = display
            info.TextSize = _G.ESP_FontSize
        end

        if barBG and barFG then
            if _G.ESP_ShowHealth then
                barBG.Visible = true
                local hpPercent = math.clamp(hum2.Health / hum2.MaxHealth, 0, 1)
                barFG.Size = UDim2.fromScale(hpPercent, 1)
                if hpPercent > 0.5 then
                    barFG.BackgroundColor3 = Color3.fromRGB(255 * (1 - hpPercent) * 2, 255, 50)
                else
                    barFG.BackgroundColor3 = Color3.fromRGB(255, 255 * hpPercent * 2, 50)
                end
            else
                barBG.Visible = false
            end
        end
    end
end)

local PlayerCharConns = {}

Players.PlayerRemoving:Connect(function(p)
    removeESP(p)
    if PlayerCharConns[p] then
        PlayerCharConns[p]:Disconnect()
        PlayerCharConns[p] = nil
    end
end)

Players.PlayerAdded:Connect(function(p)
    if PlayerCharConns[p] then
        PlayerCharConns[p]:Disconnect()
    end
    PlayerCharConns[p] = p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if _G.ESP_Master then createESP(p) end
    end)
end)

--Auto Enabled PVP
local function GetCommF()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("CommF_")
end

task.spawn(function()
    while true do
        if _G.AutoEnablePVP and not getgenv().IsServerHopping then
            local remote = GetCommF()
            if remote then 
                pcall(function()
                    remote:InvokeServer("EnablePvp") 
                end)
            end
        end
        task.wait(1)
    end
end)

--Auto Buso
task.spawn(function()
    while task.wait(1) do
        if _G.AutoBusoEnabled then
            local player = game.Players.LocalPlayer
            if player and player.Character and not player.Character:FindFirstChild("HasBuso") then
                pcall(function()
                    game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Buso")
                end)
            end
        end
    end
end)

-- Auto V3
local function toggleV3()
    if UserInputService:GetFocusedTextBox() then return end
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.T, false, game)
    task.wait(1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.T, false, game)
end

task.spawn(function()
    while task.wait(0.5) do
        if not game.Players.LocalPlayer or not game.Players.LocalPlayer:IsDescendantOf(game.Players) then break end
        if _G.AutoV3_Enabled then
            toggleV3()
            task.wait(1)
        end
    end
end)

-- Auto V4
local function GetAwakeningRemote()
    local player = Players.LocalPlayer
    if not player then return nil end

    local backpack = player:FindFirstChild("Backpack")
    local awakening = backpack and backpack:FindFirstChild("Awakening")
    if awakening and awakening:FindFirstChild("RemoteFunction") then
        return awakening.RemoteFunction
    end

    local char = player.Character
    local charAwakening = char and char:FindFirstChild("Awakening")
    if charAwakening and charAwakening:FindFirstChild("RemoteFunction") then
        return charAwakening.RemoteFunction
    end

    return nil
end

task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AutoV4_Enabled then
            local remote = GetAwakeningRemote()
            if remote then
                task.spawn(function()
                    pcall(function()
                        remote:InvokeServer(true)
                    end)
                end)
            end
        end
    end
end)

-- Auto Ken
local function toggleKenVision()
    if UserInputService:GetFocusedTextBox() then return end
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

task.spawn(function()
    while task.wait(0.1) do
        if not LocalPlayer or not LocalPlayer:IsDescendantOf(Players) then break end

        if not _G.AutoKenEnabled then continue end

        local kenLeft   = LocalPlayer:GetAttribute("KenDodgesLeft")
        local kenActive = LocalPlayer:GetAttribute("KenActive")

        if kenLeft ~= nil then
            if not kenActive then
                toggleKenVision()
                task.wait(0.5)
            end
        else
            toggleKenVision()
            task.wait(2.0)
        end
    end
end)

--自動順步
local function SoruTo(targetPosition)
    local Character = LocalPlayer and LocalPlayer.Character
    if not Character then return false end

    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = Character:FindFirstChild("Humanoid")
    if not HumanoidRootPart or not Humanoid or Humanoid.Health <= 0 then return false end

    local startCFrame = HumanoidRootPart.CFrame
    local finalPos = targetPosition
    local finalCFrame = (startCFrame - startCFrame.Position) + finalPos + Vector3.new(0, HumanoidRootPart.Size.Y * 1.5, 0)

    local randomId = math.random(1, 999999999)
    
    ReplicatedStorage.Remotes.CommE:FireServer(
        "Soru",
        startCFrame,
        finalCFrame,
        workspace:GetServerTimeNow(),
        randomId
    )
    return true
end

local function GetClosestPlayerForSoru()
    local closestPlayer = nil
    local shortestDistance = math.huge

    local Character = LocalPlayer and LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then
        return nil, math.huge
    end

    local myPos = Character.HumanoidRootPart.Position

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local otherChar = player.Character
            local otherHum = otherChar and otherChar:FindFirstChild("Humanoid")
            local otherRoot = otherChar and otherChar:FindFirstChild("HumanoidRootPart")
            if otherHum and otherRoot and otherHum.Health > 0 then
                local distance = (otherRoot.Position - myPos).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer, shortestDistance
end

local function SoruToClosestPlayer()
    if tick() - LastSoruTime < SORU_COOLDOWN then
        return
    end

    local targetPlayer, distance = GetClosestPlayerForSoru()
    
    if not targetPlayer or distance > MAX_SORU_DISTANCE then 
        return 
    end

    local targetChar = targetPlayer.Character
    if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
        local targetPos = (targetChar.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)).Position
        
        local success = SoruTo(targetPos)
        
        if success then
            LastSoruTime = tick()
            
            pcall(function()
                if WindUI then
                    WindUI:Notify({
                        Title = "自動順步",
                        Content = string.format("觸發：%s (%dM)", targetPlayer.Name, math.floor(distance)),
                        Duration = 3,
                        Icon = "zap"
                    })
                end
            end)
        end
    end
end

local function StartAutoSoru()
    if AutoSoruConn then return end
    AutoSoruConn = task.spawn(function()
        while _G.AutoSoru do
            pcall(SoruToClosestPlayer)
            task.wait(1)
        end
        AutoSoruConn = nil
    end)
end

local function StopAutoSoru()
    if AutoSoruConn then
        task.cancel(AutoSoruConn)
        AutoSoruConn = nil
    end
end

if _G.AutoSoru then 
    StartAutoSoru() 
end

--Hitbox
local function getRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function applyHitboxToPlayer(plr)
    if plr == LocalPlayer then return end
    if not plr.Character then return end
    
    local r = getRoot(plr.Character)
    if r and r:IsA("BasePart") then
        r.CanCollide = false
        if _G.Hitbox_Enabled then
            r.Size = Vector3.new(_G.Hitbox_Size, _G.Hitbox_Size, _G.Hitbox_Size)
            r.Transparency = _G.Hitbox_Transparency
        else
            r.Size = Vector3.new(2, 2, 1)
            r.Transparency = 0
        end
    end
end

local function applyHitboxAll()
    for _, plr in pairs(Players:GetPlayers()) do
        applyHitboxToPlayer(plr)
    end
end

local function setupPlayerEvents(plr)
    if plr == LocalPlayer then return end

    plr.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        applyHitboxToPlayer(plr)
    end)

    if plr.Character then
        applyHitboxToPlayer(plr)
    end
end

for _, plr in pairs(Players:GetPlayers()) do
    setupPlayerEvents(plr)
end

Players.PlayerAdded:Connect(function(plr)
    setupPlayerEvents(plr)
end)

Players.PlayerRemoving:Connect(function(plr)
    task.defer(applyHitboxAll)
end)

local hitboxTick = 0
RunService.Heartbeat:Connect(function()
    if not _G.Hitbox_Enabled then return end
    hitboxTick = hitboxTick + 1
    if hitboxTick % 30 ~= 0 then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            applyHitboxToPlayer(plr)
        end
    end
end)

--Auto flee（修改版）
-- 穿牆輔助：啟用/停用角色的無碰撞
local function SetCharNoclip(char, enabled)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not enabled
        end
    end
end

local function StartAutoFlee()
    if _G.AutoFleeConn then return end
    _G.AutoFleeConn = task.spawn(function()
        local wasFleeing = false
        -- 獨立逃跑用的飛行組件（不與自動列賞共用，避免互相覆蓋）
        local fleeAttachment = nil
        local fleeLinearVelocity = nil
        local fleeAntiGravity = nil

        local function SetupFleeComponents(hrp)
            -- 清理舊的組件
            if fleeLinearVelocity then fleeLinearVelocity:Destroy() fleeLinearVelocity = nil end
            if fleeAntiGravity then fleeAntiGravity:Destroy() fleeAntiGravity = nil end
            if fleeAttachment then fleeAttachment:Destroy() fleeAttachment = nil end

            local att = Instance.new("Attachment")
            att.Name = "AutoFlee_Attachment"
            att.Parent = hrp
            fleeAttachment = att

            local lv = Instance.new("LinearVelocity")
            lv.Name = "AutoFlee_LinearVelocity"
            lv.MaxForce = math.huge
            lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
            lv.VectorVelocity = Vector3.new(0, 0, 0)
            lv.Attachment0 = att
            lv.Parent = hrp
            fleeLinearVelocity = lv

            -- 計算角色總質量以抵消重力
            local totalMass = 0
            local char = hrp.Parent
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and not part.Massless then
                        totalMass = totalMass + part:GetMass()
                    end
                end
            end

            local vf = Instance.new("VectorForce")
            vf.Name = "AutoFlee_AntiGravity"
            vf.ApplyAtCenterOfMass = true
            vf.Attachment0 = att
            vf.Force = Vector3.new(0, totalMass * workspace.Gravity, 0)
            vf.Parent = hrp
            fleeAntiGravity = vf
        end

        local function ClearFleeComponents()
            if fleeLinearVelocity then fleeLinearVelocity:Destroy() fleeLinearVelocity = nil end
            if fleeAntiGravity then fleeAntiGravity:Destroy() fleeAntiGravity = nil end
            if fleeAttachment then fleeAttachment:Destroy() fleeAttachment = nil end
        end

        while _G.AutoFlee do
            task.wait(0.05)
            pcall(function()
                -- 自動列賞開啟時不接管，讓自動列賞自己處理逃跑
                if _G.FTP2_Enabled then
                    if wasFleeing then
                        wasFleeing = false
                        ClearFleeComponents()
                        SetCharNoclip(LocalPlayer.Character, false)
                    end
                    return
                end

                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hum or not hrp or hum.Health <= 0 then
                    if wasFleeing then
                        wasFleeing = false
                        ClearFleeComponents()
                        SetCharNoclip(char, false)
                    end
                    return
                end
                
                local hpPercent = (hum.Health / hum.MaxHealth) * 100
                if hpPercent <= _G.AutoFleeHP then
                    if not wasFleeing then
                        wasFleeing = true
                        -- 穿牆 + 建立飛行組件
                        SetCharNoclip(char, true)
                        SetupFleeComponents(hrp)
                    else
                        -- 每次都確認組件仍然存在於正確的 hrp
                        local needSetup = not fleeLinearVelocity or fleeLinearVelocity.Parent ~= hrp
                        if needSetup then
                            SetupFleeComponents(hrp)
                        end
                    end
                    -- 持續往上飛，速度 300
                    if fleeLinearVelocity then
                        fleeLinearVelocity.VectorVelocity = Vector3.new(0, 300, 0)
                    end
                elseif wasFleeing then
                    -- 血量恢復，停止逃跑
                    wasFleeing = false
                    ClearFleeComponents()
                    SetCharNoclip(char, false)
                end
            end)
        end

        -- 迴圈結束時恢復碰撞並清理組件
        pcall(function()
            if wasFleeing then
                SetCharNoclip(LocalPlayer.Character, false)
            end
            if fleeLinearVelocity then fleeLinearVelocity:Destroy() fleeLinearVelocity = nil end
            if fleeAntiGravity then fleeAntiGravity:Destroy() fleeAntiGravity = nil end
            if fleeAttachment then fleeAttachment:Destroy() fleeAttachment = nil end
        end)
        _G.AutoFleeConn = nil
    end)
end

local function StopAutoFlee()
    _G.AutoFleeConn = nil
    pcall(function()
        SetCharNoclip(LocalPlayer.Character, false)
    end)
end

if _G.AutoFlee then StartAutoFlee() end

-- [FIX 2] 移除動作
local function DisableAnimForChar(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    local animator = hum:WaitForChild("Animator", 5)
    if not animator then return end

    for _, t in pairs(animator:GetPlayingAnimationTracks()) do
        t:Stop()
    end

    if _G.RemoveAnimTrackConn then
        _G.RemoveAnimTrackConn:Disconnect()
        _G.RemoveAnimTrackConn = nil
    end

    _G.RemoveAnimTrackConn = animator.AnimationPlayed:Connect(function(t)
        if _G.RemoveAnim then
            t:Stop()
        end
    end)
end

local function StartRemoveAnim()
    if _G.RemoveAnimCharConn then return end

    if LocalPlayer and LocalPlayer.Character then
        DisableAnimForChar(LocalPlayer.Character)
    end

    _G.RemoveAnimCharConn = LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if _G.RemoveAnim then
            DisableAnimForChar(char)
        end
    end)
end

local function StopRemoveAnim()
    if _G.RemoveAnimTrackConn then
        _G.RemoveAnimTrackConn:Disconnect()
        _G.RemoveAnimTrackConn = nil
    end
    if _G.RemoveAnimCharConn then
        _G.RemoveAnimCharConn:Disconnect()
        _G.RemoveAnimCharConn = nil
    end
end

if _G.RemoveAnim then 
    StartRemoveAnim() 
end

--walk on water
task.spawn(function()
    local lastWaterSize = -1
    while task.wait(0.5) do
        local waterPlane = Workspace.Map and Workspace.Map:FindFirstChild("WaterBase-Plane")
        if waterPlane then
            local targetSize = _G.WaterWalkEnabled and 112 or 80
            if targetSize ~= lastWaterSize then
                lastWaterSize = targetSize
                waterPlane.Size = Vector3.new(1000, targetSize, 1000)
            end
        end
    end
end)

-- Remove Lava
local function removeLava()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name == "LavaParts" and v.Parent and v.Parent.Name == "CircleIsland"
           and v.Parent.Parent and v.Parent.Parent.Name == "Map" then
            v:Destroy()
        end
    end
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == "LavaParts" and v.Parent and v.Parent.Name == "CircleIsland"
           and v.Parent.Parent and v.Parent.Parent.Name == "Map" then
            v:Destroy()
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do
        if _G.RemoveLavaEnabled and not lavaRemoved then
            lavaRemoved = true
            removeLava()
            WindUI:Notify({ Title = "已移除岩漿傷害", Content = "已成功移除岩漿物件", Duration = 3 })
        elseif not _G.RemoveLavaEnabled then
            lavaRemoved = false
        end
    end
end)

-- 移除鬼船傷害
local function removeGhostShipLava()
    local deletedCount = 0
    
    if Workspace:FindFirstChild("Map") 
       and Workspace.Map:FindFirstChild("GhostShipInterior") 
       and Workspace.Map.GhostShipInterior:FindFirstChild("LavaParts") then
        
        local lavaPartsFolder = Workspace.Map.GhostShipInterior.LavaParts
        local children = lavaPartsFolder:GetChildren()
        local targetIndices = {3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}
        
        for _, index in ipairs(targetIndices) do
            local part = children[index]
            if part then
                part:Destroy()
                deletedCount = deletedCount + 1
            end
        end
        
        if lavaPartsFolder:FindFirstChild("Lava") then
            lavaPartsFolder.Lava:Destroy()
            deletedCount = deletedCount + 1
        end
    end
    
    return deletedCount
end

task.spawn(function()
    while task.wait(0.5) do
        if _G.RemoveGhostShipLavaEnabled and not ghostShipLavaRemoved then
            ghostShipLavaRemoved = true
            local deletedCount = removeGhostShipLava()
            
            WindUI:Notify({
                Title = "已移除鬼船傷害",
                Content = "已成功移除岩漿物件",
                Duration = 3,
                Type = "Success"
            })
            
        elseif not _G.RemoveGhostShipLavaEnabled then
            ghostShipLavaRemoved = false
        end
    end
end)

--自動列賞
local function GetCombatStatus()
    local mainUI = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("Main")
    local bottomHUD = mainUI and mainUI:FindFirstChild("BottomHUDList")
    local inCombatUI = bottomHUD and bottomHUD:FindFirstChild("InCombat")

    if inCombatUI and inCombatUI.Visible then
        local rawText = ""
        
        if inCombatUI:IsA("TextLabel") then
            rawText = inCombatUI.Text
        else
            local childText = inCombatUI:FindFirstChildWhichIsA("TextLabel", true)
            if childText then
                rawText = childText.Text
            end
        end

        local lowerText = string.lower(rawText)
        if string.find(lowerText, "bounty at risk") or string.find(lowerText, "bounty") or string.find(lowerText, "賞金") then
            return "BountyAtRisk"
        else
            return "InCombatNoRisk"
        end
    else
        return "NotInCombat"
    end
end

local FTP2_CombatCache = "NotInCombat"
local FTP2_CombatCacheTime = 0

local function IsInCombatState()
    local now = os.clock()
    if now - FTP2_CombatCacheTime >= 0.5 then
        FTP2_CombatCacheTime = now
        FTP2_CombatCache = GetCombatStatus()
    end
    return FTP2_CombatCache ~= "NotInCombat"
end

-- 換服安全檢查：必須安全且無PVP狀態才能換服
IsSafeToHopCheck = function()
    if not LocalPlayer or not LocalPlayer:IsDescendantOf(Players) then
        return false
    end

    -- 戰鬥中(賞金受威脅)不可換服
    if GetCombatStatus() == "BountyAtRisk" then
        return false
    end

    -- 已開啟PVP時不可換服
    if CheckPVP(LocalPlayer) then
        return false
    end

    return true
end

local function CheckAndNotifyCombatStatus()
    if _G.FTP2_HasTriggeredHop then return end

    local status = GetCombatStatus()
    
    if status == "NotInCombat" then
        _G.FTP2_HasTriggeredHop = true
        task.spawn(function()
            if StartServerHop then StartServerHop() end
        end)
    elseif status == "InCombatNoRisk" then
        _G.FTP2_HasTriggeredHop = true
        task.spawn(function()
            if StartServerHop then StartServerHop() end
        end)
    elseif status == "BountyAtRisk" then
    end
end

local function IsInSafeZone(plr)
    if not plr or not plr.Character then return false end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local placeId = game.PlaceId
    local zones = {}

    if table.find({2753915549, 85211729168715}, placeId) then
        zones = _G.FTP2_SafeZonePositions.World1
    elseif table.find({4442272183, 79091703265657}, placeId) then
        zones = _G.FTP2_SafeZonePositions.World2
    elseif table.find({7449423635, 100117331123089}, placeId) then
        zones = _G.FTP2_SafeZonePositions.World3
    end

    local pos = hrp.Position
    for _, zone in ipairs(zones) do
        if (pos - zone.pos).Magnitude <= zone.radius then
            return true
        end
    end

    return false
end

local function GetLevel(plr)
    if not plr then return nil end
    local obj = (plr:FindFirstChild("Data") and plr.Data:FindFirstChild("Level"))
              or (plr:FindFirstChild("leaderstats") and plr.leaderstats:FindFirstChild("Level"))
    return obj and obj.Value or nil
end

local function IsPlayerAlly(player)
    if not player then return false end
    local main = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("Main")
    if not main then return false end
    
    local allies = main:FindFirstChild("Allies")
    local container = allies and allies:FindFirstChild("Container")
    local subAllies = container and container:FindFirstChild("Allies")
    if not subAllies then return false end

    local frame = subAllies:FindFirstChild("Frame") 
        or (subAllies:FindFirstChild("ScrollingFrame") and subAllies.ScrollingFrame:FindFirstChild("Frame"))

    if not frame then return false end
    return frame:FindFirstChild(player.Name) ~= nil
end

local function IsValidTarget(plr)
    if not plr or plr == LocalPlayer then return false end
    if _G.FTP2_Blacklist[plr] then return false end

    local char = plr.Character
    if not char then return false end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then 
        return false 
    end

    if plr:GetAttribute("IslandRaiding") == true then
        _G.FTP2_Blacklist[plr] = true
        return false
    end

    if char:FindFirstChildOfClass("ForceField") then
        _G.FTP2_Blacklist[plr] = true
        return false
    end

    local combatLockTarget = (plr == _G.FTP2_CurrentTarget) and IsInCombatState()

    if not combatLockTarget then
        if plr:GetAttribute("SafeZone") == true or plr:GetAttribute("InSafeZone") == true then
            _G.FTP2_Blacklist[plr] = true
            return false
        end

        if IsInSafeZone(plr) then
            _G.FTP2_Blacklist[plr] = true
            return false
        end
    end

    if plr:GetAttribute("PvpDisabled") == true then
        _G.FTP2_Blacklist[plr] = true
        return false
    end

    local myTeam = LocalPlayer.Team
    local tgTeam = plr.Team
    if myTeam and tgTeam and myTeam.Name == "Marines" and tgTeam.Name == "Marines" then
        _G.FTP2_Blacklist[plr] = true
        return false
    end

    if IsPlayerAlly(plr) then
        _G.FTP2_Blacklist[plr] = true
        return false
    end

    local myLv = GetLevel(LocalPlayer)
    local tgLv = GetLevel(plr)
    if not myLv or not tgLv or math.abs(myLv - tgLv) > 550 then
        _G.FTP2_Blacklist[plr] = true
        return false
    end

    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myHRP and (myHRP.Position - hrp.Position).Magnitude > 30000 then
        return false
    end

    return true
end

local ValidTargetCache = {}
local ValidTargetCacheTime = 0
local function IsValidTargetFast(plr)
    local now = os.clock()
    if now - ValidTargetCacheTime > 0.15 then
        ValidTargetCacheTime = now
        table.clear(ValidTargetCache)
    end
    if ValidTargetCache[plr] ~= nil then return ValidTargetCache[plr] end
    local v = IsValidTarget(plr)
    ValidTargetCache[plr] = v
    return v
end

local function IsTargetLowHP(plr)
    if not plr then return false end
    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 or hum.MaxHealth <= 0 then return false end
    local percent = (hum.Health / hum.MaxHealth) * 100
    return percent < (_G.FTP2_LowHpLockPercent or 30)
end

local function GetCurrentWorldEntrances()
    local pool = {}
    local placeId = game.PlaceId

    if table.find({2753915549, 85211729168715}, placeId) then
        pool = {
            { Arg = Vector3.new(61163.85, 11.68, 1819.78), Dest = Vector3.new(61164, 5, 1820) },
            { Arg = Vector3.new(3864.68, 6.73, -1926.21), Dest = Vector3.new(3865, 5, -1926) },
            { Arg = Vector3.new(-4607.82, 874.39, -1667.55), Dest = Vector3.new(-4608, 873, -1668) },
            { Arg = Vector3.new(-7894.61, 5547.14, -380.29), Dest = Vector3.new(-7895, 5546, -380) }
        }
    elseif table.find({4442272183, 79091703265657}, placeId) then
        pool = {
            { Arg = Vector3.new(2285, 15, 882), Dest = Vector3.new(2285, 15, 882) },
            { Arg = Vector3.new(-380, 350, 630), Dest = Vector3.new(-380, 350, 630) },
            { Arg = Vector3.new(924, 125, 32882), Dest = Vector3.new(924, 125, 32882) },
            { Arg = Vector3.new(-6491, 116, -107), Dest = Vector3.new(-6491, 116, -107) }
        }
    elseif table.find({7449423635, 100117331123089}, placeId) then
        pool = {
            { Arg = Vector3.new(5678, 1013, -312), Dest = Vector3.new(5678, 1013, -312) },
            { Arg = Vector3.new(-12551, 337, -7507), Dest = Vector3.new(-12551, 337, -7507) },
            { Arg = Vector3.new(-5038, 315, -3135), Dest = Vector3.new(-5038, 315, -3135) },
            { Arg = Vector3.new(-5098, 317, -3179), Dest = Vector3.new(-16813, 58, 305) },
        }
    end
    return pool
end

local function UpdatePositionHistory()
    local now = os.clock()
    local activePlayers = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            activePlayers[plr] = true
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if hrp and hum and hum.Health > 0 then
                if not _G.TargetHistory[plr] then
                    _G.TargetHistory[plr] = {}
                end
                local history = _G.TargetHistory[plr]

                table.insert(history, { time = now, pos = hrp.Position, vel = hrp.AssemblyLinearVelocity })

                while #history > 0 and (now - history[1].time) > _G.FTP2_HistoryWindow do
                    table.remove(history, 1)
                end
            end
        end
    end

    for plr, history in pairs(_G.TargetHistory) do
        if not activePlayers[plr] or not plr:IsDescendantOf(Players) then
            _G.TargetHistory[plr] = nil
        elseif #history == 0 then
            _G.TargetHistory[plr] = nil
        else
            local lastRecord = history[#history]
            if (now - lastRecord.time) > _G.FTP2_ClearTimeout then
                _G.TargetHistory[plr] = nil
            end
        end
    end
end

local function GetPredictedPosition2(plr)
    if not plr or not plr.Character then return nil end

    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local history = _G.TargetHistory[plr]
    local currentPos = hrp.Position
    local currentVel = hrp.AssemblyLinearVelocity

    local ping = 0.04
    pcall(function()
        ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
    end)

    if not history or #history < 3 then
        local t = math.clamp(ping, 0.03, 0.25)
        local pos = currentPos + (currentVel * t)
        if pos.Y < hrp.Position.Y then
            pos = Vector3.new(pos.X, hrp.Position.Y, pos.Z)
        end
        return pos
    end

    local count = #history
    local now = os.clock()

    local totalWeight = 0
    local weightedVel = Vector3.new(0, 0, 0)

    for i = 2, count do
        local prev = history[i - 1]
        local curr = history[i]
        local dt = curr.time - prev.time
        if dt > 0.001 then
            local instVel = (curr.pos - prev.pos) / dt
            local weight = math.exp((curr.time - now) / 0.1)
            weightedVel = weightedVel + (instVel * weight)
            totalWeight = totalWeight + weight
        end
    end

    local historyVel = (totalWeight > 0) and (weightedVel / totalWeight) or currentVel
    local finalVel = historyVel:Lerp(currentVel, 0.3)

    if finalVel.Magnitude > 280 then
        finalVel = finalVel.Unit * 280
    end

    local oldest = history[1]
    local mid = history[math.floor(count / 2)]
    local newest = history[count]

    local dt1 = mid.time - oldest.time
    local dt2 = newest.time - mid.time
    local accel = Vector3.new(0, 0, 0)

    if dt1 > 0.005 and dt2 > 0.005 then
        local v1 = (mid.pos - oldest.pos) / dt1
        local v2 = (newest.pos - mid.pos) / dt2
        accel = (v2 - v1) / ((dt1 + dt2) * 0.5)
    end

    if accel.Magnitude > 150 then
        accel = accel.Unit * 150
    end

    local oldDir = (mid.pos - oldest.pos)
    local newDir = (newest.pos - mid.pos)
    if oldDir.Magnitude > 1 and newDir.Magnitude > 1 then
        local dirDot = math.clamp(oldDir.Unit:Dot(newDir.Unit), 0, 1)
        accel = accel * dirDot
    end

    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local predTime = 0.15

    if myHRP then
        local dist = (currentPos - myHRP.Position).Magnitude
        local flightTime = dist / _G.FTP2_FlySpeed
        predTime = math.clamp((flightTime * 0.55) + ping, 0.04, 0.45)
    end

    local predictedPos = currentPos + (finalVel * predTime) + (0.5 * accel * (predTime ^ 2))

    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Freefall then
            local gravity = workspace.Gravity
            predictedPos = predictedPos - Vector3.new(0, 0.5 * gravity * (predTime ^ 2), 0)
        end
    end

    if predictedPos.Y < hrp.Position.Y then
        predictedPos = Vector3.new(predictedPos.X, hrp.Position.Y, predictedPos.Z)
    end

    return predictedPos
end

local function GetNearestPlayer()
    local nearestPlayer = nil
    local shortestDistance = math.huge
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

    if not myHRP then return nil end

    for _, plr in ipairs(Players:GetPlayers()) do
        if IsValidTargetFast(plr) then
            local tgHRP = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if tgHRP then
                local dist = (tgHRP.Position - myHRP.Position).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    nearestPlayer = plr
                end
            end
        end
    end
    return nearestPlayer
end

local function ClearFTP2FlightComponents()
    if _G.FTP2_LinearVelocity then _G.FTP2_LinearVelocity:Destroy() _G.FTP2_LinearVelocity = nil end
    if _G.FTP2_AntiGravity then _G.FTP2_AntiGravity:Destroy() _G.FTP2_AntiGravity = nil end
    if _G.FTP2_Attachment then _G.FTP2_Attachment:Destroy() _G.FTP2_Attachment = nil end
end

local function SetupFTP2FlightComponents(hrp)
    ClearFTP2FlightComponents()

    local att = Instance.new("Attachment")
    att.Name = "XuHub_FlightAttachment2"
    att.Parent = hrp
    _G.FTP2_Attachment = att

    local lv = Instance.new("LinearVelocity")
    lv.Name = "XuHub_FlightVelocity2"
    lv.MaxForce = math.huge
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    lv.VectorVelocity = Vector3.new(0, 0, 0)
    lv.Attachment0 = att
    lv.Parent = hrp
    _G.FTP2_LinearVelocity = lv

    local totalMass = 0
    local char = hrp.Parent
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and not part.Massless then
                totalMass = totalMass + part:GetMass()
            end
        end
    end

    local vf = Instance.new("VectorForce")
    vf.Name = "XuHub_AntiGravity2"
    vf.ApplyAtCenterOfMass = true
    vf.Attachment0 = att
    vf.Force = Vector3.new(0, totalMass * workspace.Gravity, 0)
    vf.Parent = hrp
    _G.FTP2_AntiGravity = vf
end

local FTP2_OrbitOffset = nil
local FTP2_NextOrbitTime = 0

local function FlyToTargetLogic2(plr)
    if not plr or not plr.Character then return end

    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local tgHRP = plr.Character:FindFirstChild("HumanoidRootPart")

    if not myHRP or not tgHRP then return end

    if os.clock() < _G.FTP2_TeleportPauseUntil then
        if _G.FTP2_LinearVelocity then _G.FTP2_LinearVelocity.VectorVelocity = Vector3.new(0, 0, 0) end
        myHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        return
    end

    local rawTargetPos = GetPredictedPosition2(plr) or tgHRP.Position

    local now = os.clock()
    if not FTP2_OrbitOffset or now >= FTP2_NextOrbitTime then
        local maxRadius = _G.FTP2_OrbitRadius or 50
        local distance = math.random(1, maxRadius)
        local dir = Vector3.new(math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1)
        if dir.Magnitude > 0 then dir = dir.Unit end
        FTP2_OrbitOffset = dir * distance
        FTP2_NextOrbitTime = now + (_G.FTP2_OrbitInterval or 0.016)
    end
    local targetPos = rawTargetPos + FTP2_OrbitOffset

    local dir = targetPos - myHRP.Position

    local flySpeed = _G.FTP2_FlySpeed

    local distToTargetCenter = (rawTargetPos - myHRP.Position).Magnitude
    local directFlightTime = distToTargetCenter / _G.FTP2_FlySpeed
    local bestEntrance = nil
    local bestTotalTime = directFlightTime 
    local teleportPenalty = 1.5 
    local pool = GetCurrentWorldEntrances()

    if distToTargetCenter < (_G.FTP2_NoTeleportRange or 300) then
        pool = {}
    end

    for _, e in ipairs(pool) do
        if _G.FTP2_BlockedEntrances[e.Arg] then continue end

        local destDistToTarget = (e.Dest - rawTargetPos).Magnitude
        local totalTimeViaPortal = (destDistToTarget / _G.FTP2_FlySpeed) + teleportPenalty
        
        if totalTimeViaPortal < bestTotalTime then
            if (distToTargetCenter - destDistToTarget) > 150 then
                bestTotalTime = totalTimeViaPortal
                bestEntrance = e
            end
        end
    end

    if bestEntrance then
        local lastTime = _G.FTP2_LastTeleportTicks[bestEntrance.Arg] or 0
        if os.clock() - lastTime > 4 then
            _G.FTP2_LastTeleportTicks[bestEntrance.Arg] = os.clock()
            _G.FTP2_TeleportPauseUntil = os.clock() + 1.2

            local preDist = (myHRP.Position - bestEntrance.Dest).Magnitude
            
            if _G.FTP2_LinearVelocity then _G.FTP2_LinearVelocity.VectorVelocity = Vector3.new(0, 0, 0) end
            myHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            
            task.spawn(function()
                pcall(function()
                    local commF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
                    commF:InvokeServer("requestEntrance", bestEntrance.Arg)
                end)
            end)

            task.spawn(function()
                task.wait(1.5)
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local postDist = (hrp.Position - bestEntrance.Dest).Magnitude
                    if postDist > 150 and postDist >= preDist * 0.5 then
                        local fails = (_G.FTP2_TeleportFails[bestEntrance.Arg] or 0) + 1
                        _G.FTP2_TeleportFails[bestEntrance.Arg] = fails
                        if fails >= 3 then
                            _G.FTP2_BlockedEntrances[bestEntrance.Arg] = true
                            if WindUI then
                                WindUI:Notify({ Title = "自動列賞", Content = "傳送點 3 次無法到達，已改用其他傳送點", Duration = 3 })
                            end
                        end
                    end
                end
            end)
            return 
        end
    end

    local needSetup = not _G.FTP2_LinearVelocity or _G.FTP2_LinearVelocity.Parent ~= myHRP
    if needSetup then SetupFTP2FlightComponents(myHRP) end

    _G.FTP2_LinearVelocity.VectorVelocity = dir.Unit * flySpeed

    local lookAt = Vector3.new(rawTargetPos.X, myHRP.Position.Y, rawTargetPos.Z)
    if (lookAt - myHRP.Position).Magnitude > 0.1 then
        myHRP.CFrame = CFrame.new(myHRP.Position, lookAt)
    end
end

local function FleeUpLogic()
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then return end

        -- 穿牆：關閉碰撞，避免被建築卡住
        SetCharNoclip(char, true)

        -- 確保飛行組件存在且掛在正確的 hrp 上
        local needSetup = not _G.FTP2_LinearVelocity or _G.FTP2_LinearVelocity.Parent ~= hrp
        if needSetup then
            SetupFTP2FlightComponents(hrp)
        end

        _G.FTP2_LinearVelocity.VectorVelocity = Vector3.new(0, 300, 0)
    end)
end

local function ForceStandUp()
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHum or myHum.Health <= 0 then return end

    if myHum.Sit then
        myHum.Sit = false
        pcall(function() myHum.Jump = true end)
        pcall(function() myHum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        pcall(function() myHum:ChangeState(Enum.HumanoidStateType.Physics) end)
    end

    if myHRP then
        for _, child in ipairs(myHRP:GetChildren()) do
            if child:IsA("Weld") then
                pcall(function() child:Destroy() end)
            elseif child:IsA("Motor6D") then
                local n = string.lower(child.Name)
                if n:find("seat") or n:find("sit") or n:find("vehicle") then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end

local function StartFTPFlight2()
    if _G.FTP2_FlightConn ~= nil then return end 

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    char:WaitForChild("Humanoid", 9e9)
    char:WaitForChild("HumanoidRootPart", 9e9)
    
    while not char.Parent do 
        task.wait() 
    end
    
    local checkHum = char:FindFirstChildOfClass("Humanoid")
    if checkHum and checkHum.Health <= 0 then
        LocalPlayer.CharacterAdded:Wait()
        return StartFTPFlight2()
    end

    if not _G.FTP2_Enabled then return end

    _G.FTP2_Enabled = true
    table.clear(_G.FTP2_LastTeleportTicks) 
    table.clear(_G.FTP2_TeleportFails)
    table.clear(_G.FTP2_BlockedEntrances)
    table.clear(_G.FTP2_Blacklist)
    _G.FTP2_TeleportPauseUntil = 0 
    _G.FTP2_HasTriggeredHop = false
    _G.FTP2_CurrentTarget = nil
    _G.FTP2_TargetLockTime = os.clock()
    _G.FTP2_StartTime = os.clock()
    _G.FTP2_FleeReturnPos = nil
    FTP2_OrbitOffset = nil
    FTP2_NextOrbitTime = 0

    if type(setPlatformStand) == "function" then setPlatformStand(true) end
    
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Physics) end
    if type(_G.SetNoclipState) == "function" then _G.SetNoclipState(true) end

    _G.FTP2_PlayerLeaveConn = Players.PlayerRemoving:Connect(function(plr)
        _G.TargetHistory[plr] = nil
        _G.FTP2_Blacklist[plr] = nil
        if _G.FTP2_CurrentTarget == plr then
            _G.FTP2_CurrentTarget = nil
        end
    end)

    local lastHistoryUpdate = 0
    local lastNoclipScan = 0
    local cachedChar = nil
    local cachedParts = nil

    _G.FTP2_FlightConn = RunService.RenderStepped:Connect(function()
        if not _G.FTP2_Enabled then return end

        local currentChar = LocalPlayer.Character
        local currentHum = currentChar and currentChar:FindFirstChildOfClass("Humanoid")

        ForceStandUp()

        if _G.AutoFlee and currentHum and currentHum.Health > 0 then
            local hpPercent = (currentHum.Health / currentHum.MaxHealth) * 100
            local fleeHP = _G.AutoFleeHP or 30
            if hpPercent <= fleeHP then
                if not _G.FTP2_FleeReturnPos then
                    local fChar = LocalPlayer.Character
                    local fHRP = fChar and fChar:FindFirstChild("HumanoidRootPart")
                    if fHRP then
                        _G.FTP2_FleeReturnPos = fHRP.Position
                    end
                end
                FleeUpLogic()
                return
            end
        end

        if _G.FTP2_FleeReturnPos then
            local fChar = LocalPlayer.Character
            local fHum = fChar and fChar:FindFirstChildOfClass("Humanoid")
            local fHRP = fChar and fChar:FindFirstChild("HumanoidRootPart")
            if fHRP and fHum and fHum.Health > 0 then
                fHRP.CFrame = CFrame.new(_G.FTP2_FleeReturnPos)
                _G.FTP2_FleeReturnPos = nil
                -- 恢復後停止上飛，重新啟用飛行組件給列賞使用
                if _G.FTP2_LinearVelocity then
                    _G.FTP2_LinearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
                end
                SetCharNoclip(fChar, false)
                if WindUI then
                    WindUI:Notify({ Title = "自動列賞", Content = "血量已恢復，傳送回原位置繼續列賞", Duration = 3 })
                end
            elseif not fHRP or not fHum or fHum.Health <= 0 then
                _G.FTP2_FleeReturnPos = nil
            end
        end

        local now = os.clock()
        if now - lastHistoryUpdate >= 0.1 then
            lastHistoryUpdate = now
            UpdatePositionHistory()
        end

        if type(_G.SetNoclipState) == "function" then _G.SetNoclipState(true) end

        pcall(function()
            local myChar = LocalPlayer.Character
            if myChar then
                local myHum = myChar:FindFirstChildOfClass("Humanoid")
                local myHRP = myChar:FindFirstChild("HumanoidRootPart")

                if myChar ~= cachedChar or not cachedParts or now - lastNoclipScan >= 1 then
                    lastNoclipScan = now
                    cachedChar = myChar
                    cachedParts = {}
                    for _, part in ipairs(myChar:GetDescendants()) do
                        if part:IsA("BasePart") then
                            table.insert(cachedParts, part)
                        end
                    end
                end
                for _, part in ipairs(cachedParts) do
                    if part.CanCollide then
                        part.CanCollide = false
                    end
                end

                if myHum and not myHum.PlatformStand then
                    myHum.PlatformStand = true
                end
            end
        end)

        if _G.FTP2_CurrentTarget then
            if not IsValidTargetFast(_G.FTP2_CurrentTarget) then
                _G.FTP2_Blacklist[_G.FTP2_CurrentTarget] = true
                _G.FTP2_CurrentTarget = nil
            end
        end

        local oldTarget = _G.FTP2_CurrentTarget
        local lowHpLock = IsTargetLowHP(oldTarget)

        if lowHpLock then
            _G.FTP2_CurrentTarget = oldTarget
        else
            local nearest = GetNearestPlayer()
            if nearest then
                _G.FTP2_CurrentTarget = nearest
            else
                _G.FTP2_CurrentTarget = nil
            end
        end

        if _G.FTP2_CurrentTarget then
            if _G.FTP2_CurrentTarget ~= oldTarget then
                _G.FTP2_TargetLockTime = os.clock()
            end

            if not lowHpLock and os.clock() - _G.FTP2_TargetLockTime >= _G.FTP2_TimeoutLimit then
                _G.FTP2_Blacklist[_G.FTP2_CurrentTarget] = true
                if WindUI then
                    WindUI:Notify({ Title = "自動列賞", Content = "鎖定時間超過 " .. tostring(_G.FTP2_TimeoutLimit) .. "秒，已跳過玩家: " .. _G.FTP2_CurrentTarget.Name, duration = 3 })
                end
                _G.FTP2_CurrentTarget = nil
                _G.FTP2_TargetLockTime = os.clock()
            end
        else
            _G.FTP2_TargetLockTime = os.clock()
        end

        if _G.FTP2_CurrentTarget then
            FlyToTargetLogic2(_G.FTP2_CurrentTarget)
        else
            FleeUpLogic()

            if os.clock() - _G.FTP2_StartTime >= 5 then
                CheckAndNotifyCombatStatus()
            end
        end
    end)
end

local function StopFTPFlight2()
    _G.FTP2_Enabled = false
    _G.FTP2_TeleportPauseUntil = 0
    _G.FTP2_CurrentTarget = nil
    _G.FTP2_FleeReturnPos = nil
    
    if type(_G.SetNoclipState) == "function" then _G.SetNoclipState(false) end

    if _G.FTP2_FlightConn then 
        _G.FTP2_FlightConn:Disconnect()
        _G.FTP2_FlightConn = nil 
    end

    if _G.FTP2_PlayerLeaveConn then
        _G.FTP2_PlayerLeaveConn:Disconnect()
        _G.FTP2_PlayerLeaveConn = nil
    end

    ClearFTP2FlightComponents()

    if type(setPlatformStand) == "function" then setPlatformStand(false) end
    
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if hum then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end

        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
    end
end

if _G.FTP2_Enabled then
    task.spawn(StartFTPFlight2)
end

--自瞄
local function IsSilentAimEnemy(player)
    if not player or player == LocalPlayer then return false end
    if IsPlayerAlly(player) then return false end
    
    local myTeam = LocalPlayer.Team
    local targetTeam = player.Team
    if myTeam and targetTeam and myTeam.Name == "Marines" and targetTeam.Name == "Marines" then
        return false
    end
    return true
end

local function SilentAim_GetTargetPartAndDist()
    local myChar = LocalPlayer.Character
    if not myChar then return nil, math.huge end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, math.huge end

    if _G.SilentAimTargetMode == "目前鎖定的目標玩家" then
        local targetPlr = _G.FTP2_CurrentTarget
        if targetPlr and targetPlr.Parent and targetPlr.Character then
            if not _G.SilentAimTeamCheck or IsSilentAimEnemy(targetPlr) then
                local char = targetPlr.Character
                local hum = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and root then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    return root, dist
                end
            end
        end
        return nil, math.huge
    end

    local closest = nil
    local shortest = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not _G.SilentAimTeamCheck or IsSilentAimEnemy(player) then
                local char = player.Character
                if IsAlive(char) then
                    local part = char:FindFirstChild("HumanoidRootPart")
                    if part then
                        local dist = (part.Position - myRoot.Position).Magnitude
                        if dist < shortest then
                            closest = part
                            shortest = dist
                        end
                    end
                end
            end
        end
    end

    return closest, shortest
end

if not _G.SilentAimHooked and not disableHook then
    _G.SilentAimHooked = true

    task.spawn(function()
        local MouseModuleInstance = ReplicatedStorage:WaitForChild("Mouse", 5)
        if MouseModuleInstance then
            pcall(function()
                local MouseModule = require(MouseModuleInstance)
                if typeof(MouseModule) == "table" then
                    local realStore = { Hit = rawget(MouseModule, "Hit"), Target = rawget(MouseModule, "Target") }
                    local mmt = getrawmetatable(MouseModule) or {}
                    setreadonly(mmt, false)
                    rawset(MouseModule, "Hit", nil)
                    rawset(MouseModule, "Target", nil)

                    mmt.__index = function(self, key)
                        if key == "Hit" then
                            if _G.SilentAimEnabled and currentSilentAimTargetPos then return CFrame.new(currentSilentAimTargetPos) end
                            return realStore.Hit
                        elseif key == "Target" then
                            if _G.SilentAimEnabled and currentSilentAimTarget then return currentSilentAimTarget end
                            return realStore.Target
                        end
                        return rawget(self, key)
                    end

                    mmt.__newindex = function(self, key, value)
                        if key == "Hit" or key == "Target" then realStore[key] = value else rawset(self, key, value) end
                    end
                    setreadonly(mmt, true)
                    setmetatable(MouseModule, mmt)
                end
            end)
        end
    end)

    local gmt = getrawmetatable(game)
    if gmt then
        setreadonly(gmt, false)
        local oldIndex = gmt.__index
        local mouse = LocalPlayer:GetMouse()

        gmt.__index = newcclosure(function(self, key)
            if not checkcaller() and _G.SilentAimEnabled and currentSilentAimTargetPos and self == mouse then
                local targetPos = currentSilentAimTargetPos
                local camPos = Camera.CFrame.Position
                if key == "Hit" then return CFrame.new(targetPos)
                elseif key == "Target" then return currentSilentAimTarget
                elseif key == "UnitRay" then return Ray.new(camPos, (targetPos - camPos).Unit)
                elseif key == "Origin" then return CFrame.new(camPos)
                elseif key == "Direction" then return (targetPos - camPos).Unit end
            end
            return oldIndex(self, key)
        end)
        setreadonly(gmt, true)
    end
end

if _G.SilentAimLoop then _G.SilentAimLoop:Disconnect() end
_G.SilentAimLoop = RunService.RenderStepped:Connect(function()
    if _G.SilentAimEnabled then
        currentSilentAimTarget, _ = SilentAim_GetTargetPartAndDist()
        currentSilentAimTargetPos = currentSilentAimTarget and currentSilentAimTarget.Position or nil
        _G.SilentAimTargetPos = currentSilentAimTargetPos
    else
        currentSilentAimTarget = nil
        currentSilentAimTargetPos = nil
        _G.SilentAimTargetPos = nil
    end
end)

--Camlock
local camlockWasEnabled = false

RunService.RenderStepped:Connect(function()
    if not _G.CamlockEnabled then
        if camlockWasEnabled then
            camlockWasEnabled = false
            if LocalPlayer.Character then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.LocalTransparencyModifier = 0
                    end
                end
            end
        end
        return
    end
    camlockWasEnabled = true

    if not _G.FTP2_CurrentTarget then return end
    if not _G.FTP2_CurrentTarget.Character then return end
    if not LocalPlayer.Character then return end

    local char = LocalPlayer.Character
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.LocalTransparencyModifier < 1 then
            part.LocalTransparencyModifier = 1
        end
    end

    local camera = Workspace.CurrentCamera
    local targetHRP = _G.FTP2_CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
    local localHead = char:FindFirstChild("Head")

    if targetHRP and localHead then
        local camPos = localHead.Position + localHead.CFrame.LookVector * 1.5
        camera.CFrame = CFrame.new(camPos, targetHRP.Position)
    end
end)

--自動放技能
LocalPlayer.CharacterAdded:Connect(function()
    SkillCoolDownTrack = {}
end)

local function GetMyCharacter()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum.Health > 0 then
            return char
        end
    end
    return nil
end

local function getToolType(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    local tType = tool:GetAttribute("Type") or tool.ToolTip
    if tType == "Fruit" then tType = "Blox Fruit" end
    return tType
end

local function SkillEquipByType(toolType)
    local char = GetMyCharacter()
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end

    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and getToolType(tool) == toolType then
            return tool
        end
    end

    local targetTool = nil
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and getToolType(tool) == toolType then
                targetTool = tool
                break
            end
        end
    end

    if not targetTool then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and getToolType(tool) == toolType then
                targetTool = tool
                break
            end
        end
    end

    if targetTool then
        hum:EquipTool(targetTool)
        task.wait(0.15)
    end
    return targetTool
end

local function SkillPressKey(key, holdTime)
    if not key then return end
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(holdTime or 0.05)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

local function GetAvailableSkills()
    local available = {}
    local currentTime = os.clock()
    local myChar = GetMyCharacter()
    if not myChar then return available end

    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local SkillsFolder = PlayerGui and PlayerGui:FindFirstChild("Main") and PlayerGui.Main:FindFirstChild("Skills")

    for weaponName, weaponData in pairs(_G.AutoSkillWeapons) do
        if weaponData.Enable then
            local toolInstance = nil
            for _, item in ipairs(myChar:GetChildren()) do
                if item:IsA("Tool") and getToolType(item) == weaponName then
                    toolInstance = item
                    break
                end
            end
            if not toolInstance then
                local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
                if backpack then
                    for _, item in ipairs(backpack:GetChildren()) do
                        if item:IsA("Tool") and getToolType(item) == weaponName then
                            toolInstance = item
                            break
                        end
                    end
                end
            end

            if toolInstance then
                local uiFolder = SkillsFolder and SkillsFolder:FindFirstChild(toolInstance.Name)
                for skillName, skillData in pairs(weaponData.Skills) do
                    if skillData.Enable then
                        local cdKey = weaponName .. "_" .. skillName
                        local isReady = false

                        if uiFolder and uiFolder:FindFirstChild(skillName) then
                            local skillGui = uiFolder[skillName]
                            local cdFrame = skillGui:FindFirstChild("Cooldown", true)
                            local lvlFrame = skillGui:FindFirstChild("Level")

                            local reqLevel = lvlFrame and tonumber(lvlFrame.Text:match("%d+")) or 0
                            local currentLevel = toolInstance:FindFirstChild("Level") and toolInstance.Level.Value or 0

                            if cdFrame and cdFrame.Size.X.Scale == 0 and reqLevel <= currentLevel then
                                if currentTime >= (SkillCoolDownTrack[cdKey] or 0) then
                                    isReady = true
                                end
                            end
                        else
                            if currentTime >= (SkillCoolDownTrack[cdKey] or 0) then
                                isReady = true
                            end
                        end

                        if isReady then
                            table.insert(available, {
                                Weapon = weaponName,
                                Skill = skillName,
                                HoldTime = skillData.HoldTime,
                                Cooldown = 1.0,
                                Tool = toolInstance
                            })
                        end
                    end
                end
            end
        end
    end
    return available
end

task.spawn(function()
    while true do
        task.wait(0.1)
        if not _G.AutoSkillMainEnable then continue end

        local targetPart = currentSilentAimTarget
        if not targetPart and _G.FTP2_CurrentTarget and _G.FTP2_CurrentTarget.Character then
            targetPart = _G.FTP2_CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
        end

        local dist = targetPart and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            and (targetPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude or math.huge

        if targetPart and dist <= 80 then
            local available = GetAvailableSkills()
            if #available > 0 then
                local chosen = available[math.random(1, #available)]
                local myChar = GetMyCharacter()
                if myChar then
                    local equipped = SkillEquipByType(chosen.Weapon)
                    if equipped then
                        local cdKey = chosen.Weapon .. "_" .. chosen.Skill
                        SkillCoolDownTrack[cdKey] = os.clock() + chosen.Cooldown + chosen.HoldTime

                        local keyEnum = SkillKeyMap[chosen.Skill]
                        if keyEnum then
                            SkillPressKey(keyEnum, chosen.HoldTime)
                        end
                        task.wait(0.2)
                    end
                end
            else
                task.wait(0.1)
            end
        end
    end
end)

local function HandleSkillDropdown(weaponType, selectedValues)
    for key, data in pairs(_G.AutoSkillWeapons[weaponType].Skills) do
        data.Enable = false
    end
    for k, val in pairs(selectedValues) do
        local skillKey = type(k) == "number" and val or k
        local isEnabled = type(k) == "number" and true or val
        if isEnabled and _G.AutoSkillWeapons[weaponType].Skills[skillKey] then
            _G.AutoSkillWeapons[weaponType].Skills[skillKey].Enable = true
        end
    end
end

--低配模式
_G.SetLowVisualState = function(state)
    _G.LowVisualMode = state
    
    if _G.LowVisualMode then
        WindUI:Notify({ 
            Title = "優化系統", 
            Content = "低配模式已啟動，正在清理地圖並優化效能...", 
            Duration = 5
        })
        
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 1
        
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj:Destroy()
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                obj.Enabled = false
            elseif obj:IsA("PostEffect") or obj:IsA("BloomEffect") or obj:IsA("BlurEffect") or obj:IsA("DepthOfFieldEffect") or obj:IsA("SunRaysEffect") then
                obj.Enabled = false
            end
        end
        
        if not _G.LowVisualConnection then
            _G.LowVisualConnection = Workspace.DescendantAdded:Connect(function(obj)
                if obj:IsA("BasePart") then
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Reflectance = 0
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj:Destroy()
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    obj.Enabled = false
                end
            end)
        end
    else
        if _G.LowVisualConnection then
            _G.LowVisualConnection:Disconnect()
            _G.LowVisualConnection = nil
        end
    end
end

--移除迷霧
_G.ApplyRemoveFog = function()
    local lightingService = game:GetService("Lighting")
    
    local layers = lightingService:FindFirstChild("LightingLayers")
    if layers then layers:Destroy() end
    
    local sky = lightingService:FindFirstChildOfClass("Sky")
    if sky then sky:Destroy() end
    
    lightingService.FogEnd = 9e9
end

-- Anti AFK
local function EnableAntiAFK()
    if _G.AntiAFK_Connection then
        _G.AntiAFK_Connection:Disconnect()
        _G.AntiAFK_Connection = nil
    end

    _G.AntiAFK_Connection = LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)

    if getconnections then
        for _, connection in pairs(getconnections(LocalPlayer.Idled)) do
            if connection.Disable then 
                connection:Disable()
            elseif connection.Disconnect then 
                connection:Disconnect() 
            end
        end
    end
end

local function DisableAntiAFK()
    if _G.AntiAFK_Connection then 
        _G.AntiAFK_Connection:Disconnect()
        _G.AntiAFK_Connection = nil 
    end
end

--Anti Kick
game:GetService("GuiService").ErrorMessageChanged:Connect(function()
    if not _G.AutoRejoinEnabled then return end
    
    local ts = game:GetService("TeleportService")
    ts:Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
end)

--自動隱藏UI
local function startAutoHideTimer()
    task.delay(3, function()
        if _G.AutoHideEnabled then
            Window:Toggle(false)
            WindUI:Notify({ 
                Title = "系統通知", 
                Content = "介面已自動隱藏，可按快捷鍵重新開啟", 
                Duration = 5 
            })
        end
    end)
end

if _G.AutoHideEnabled then
    startAutoHideTimer()
end

----------------------------------------
-- 分頁
----------------------------------------
local Tabs = {
    Config   = Window:Tab({ Title = "配置",  Icon = "wrench"}),
    Skills   = Window:Tab({ Title = "列賞&技能", Icon = "zap"}),
    Settings = Window:Tab({ Title = "畫質&設定", Icon = "settings"}),
    Support  = Window:Tab({ Title = "聯絡支援", Icon = "message-circle"}),
}

----------------------------------------
-- 元件
----------------------------------------
Tabs.Support:Section({ Title = "Discord 聯絡支援" })

Tabs.Support:Paragraph({
    Title = "Banana Cat Hub 支援中心",
    Desc = "如果你需要協助，請加入 Discord 聯絡支援。"
})

Tabs.Support:Button({
    Title = "聯絡支援",
    Icon = "message-circle",
    Desc = "點擊後複製 Discord 邀請連結",
    Callback = function()
        local DiscordSupportUrl = "https://discord.gg/dgh7qJ4wA"
        if setclipboard then
            setclipboard(DiscordSupportUrl)
            WindUI:Notify({
                Title = "聯絡支援",
                Content = "Discord 連結已複製，請貼到瀏覽器開啟",
                Duration = 4
            })
        else
            WindUI:Notify({
                Title = "聯絡支援",
                Content = DiscordSupportUrl,
                Duration = 6
            })
        end
    end
})

Tabs.Config:Section({ Title = "自動換服" })

FilterParagraph = Tabs.Config:Paragraph({
    Title = "當前篩選",
    Desc = BuildFilterText(),
})

Tabs.Config:Dropdown({
    Title = "選擇地區",
    Values = RegionValues,
    Value = _G.ServerRegion,
    Callback = function(v)
        _G.ServerRegion = v
        RefreshFilterParagraph()
        MarkConfigDirty()
    end,
})

Tabs.Config:Button({
    Title = "開始跳服",
    Icon = "arrow-right-left",
    Callback = function(v)
        StartServerHop()
    end,
})

Tabs.Config:Button({
    Title = "停止跳服",
    Icon = "circle-stop",
    Callback = function(v)
        StopServerHop()
    end,
})

Tabs.Config:Section({ Title = "Fast Attack" })

Tabs.Config:Dropdown({
    Title = "選擇攻擊模式",
    Values = { "模式1", "模式2(部分帳號失效可使用)" },
    Value = _G.FastAttackMode,
    Callback = function(v)
        _G.FastAttackMode = v
        MarkConfigDirty()
    end
})

Tabs.Config:Toggle({
    Title = "自動攻擊",
    Value = _G.FastAttack,
    Callback = function(v)
        _G.FastAttack = v
        if _G.FastAttack then
            stopManual()
        else
            startManual()
        end
        MarkConfigDirty()
    end
})

Tabs.Config:Slider({
    Title = "攻擊距離",
    Desc = "設定攻擊距離(已失效)",
    Value = {
        Min = 10,
        Max = 3000,
        Default = _G.AttackDistance
    },
    Callback = function(v)
        _G.AttackDistance = v
        MarkConfigDirty()
    end
})

Tabs.Config:Slider({
    Title = "攻擊速度",
    Desc = "調整攻擊間隔 (秒)",
    Step = 0.05,
    Value = {
        Min = 0.05,
        Max = 2,
        Default = _G.FastAttackSpeed
    },
    Callback = function(v)
        _G.FastAttackSpeed = v
        MarkConfigDirty()
    end
})

Tabs.Config:Section({ Title = "Fruit M1" })

Tabs.Config:Toggle({
    Title = "自動果實 M1",
    Value = _G.FruitsM1Enable,
    Callback = function(v)
        _G.FruitsM1Enable = v
        MarkConfigDirty()
    end
})

Tabs.Config:Slider({
    Title = "果實 M1 延遲",
    Step = 0.01,
    Value = {
        Min = 0.01,
        Max = 0.5,
        Default = _G.FruitsM1DelayValue
    },
    Callback = function(v)
        _G.FruitsM1DelayValue = v
        MarkConfigDirty()
    end
})

Tabs.Config:Section({ Title = "Auto Enabled Config" })

Tabs.Config:Toggle({
    Type = "Checkbox",
    Title = "ESP Players",
    Value = _G.ESP_Master,
    Callback = function(state)
        _G.ESP_Master        = state
        _G.ESP_ShowName      = state
        _G.ESP_ShowLevel     = state
        _G.ESP_ShowPVPStatus = state
        _G.ESP_ShowHealth    = state
        _G.ESP_ShowDistance  = state
        _G.ESP_TeamColor     = state
        
        for _, p in ipairs(Players:GetPlayers()) do
            if state then 
                createESP(p) 
            else 
                removeESP(p) 
            end
        end
        MarkConfigDirty()
    end
})

Tabs.Config:Toggle({
    Title = "顯示玩家射線",
    Value = _G.ESP_ShowTracers,
    Callback = function(state)
        _G.ESP_ShowTracers = state
        if not state then 
            for _, p in ipairs(Players:GetPlayers()) do 
                removeTracer(p) 
            end 
        end
        MarkConfigDirty()
    end
})

Tabs.Config:Slider({
    Title = "ESP字體大小",
    Desc = "調整字體大小",
    Value = {
        Min = 10,
        Max = 32,
        Default = _G.ESP_FontSize
    },
    Callback = function(value)
        _G.ESP_FontSize = value
        MarkConfigDirty()
    end
})

Tabs.Config:Toggle({
    Title = "Auto Enabled PVP",
    Desc = "自動開啟PVP",
    Value = _G.AutoEnablePVP,
    Callback = function(state)
        _G.AutoEnablePVP = state
        MarkConfigDirty()
    end
})

Tabs.Config:Toggle({
    Title = "Auto Buso",
    Desc = "自動開啟武裝色",
    Value = _G.AutoBusoEnabled,
    Callback = function(v)
        _G.AutoBusoEnabled = v
        MarkConfigDirty()
    end
})

Tabs.Config:Toggle({
    Title = "Auto V3",
    Desc = "自動開啟V3",
    Value = _G.AutoV3_Enabled,
    Callback = function(v)
        _G.AutoV3_Enabled = v
        MarkConfigDirty()
    end
})

Tabs.Config:Toggle({
    Title = "Auto V4",
    Desc = "自動開啟V4",
    Value = _G.AutoV4_Enabled,
    Callback = function(v)
        _G.AutoV4_Enabled = v
        MarkConfigDirty()
    end
})

Tabs.Config:Toggle({
    Title = "Auto Ken",
    Desc = "自動開啟見聞色",
    Value = _G.AutoKenEnabled,
    Callback = function(v)
        _G.AutoKenEnabled = v
        MarkConfigDirty()
    end
})

Tabs.Config:Toggle({
    Title = "自動順步(龍族)",
    Desc = "自動順步至最近玩家",
    Value = _G.AutoSoru,
    Callback = function(state)
        _G.AutoSoru = state
        if state then
            StartAutoSoru()
        else
            StopAutoSoru()
        end
        MarkConfigDirty()
    end
})

Tabs.Config:Toggle({
    Title = "開啟碰撞箱",
    Value = _G.Hitbox_Enabled,
    Callback = function(v)
        _G.Hitbox_Enabled = v
        applyHitboxAll()
        MarkConfigDirty()
    end
})

Tabs.Config:Slider({
    Title = "碰撞箱大小",
    Desc = "調整碰撞箱大小",
    Value = { Min = 1, Max = 500, Default = _G.Hitbox_Size },
    Callback = function(v)
        _G.Hitbox_Size = v
        if _G.Hitbox_Enabled then
            applyHitboxAll()
        end
        MarkConfigDirty()
    end
})

Tabs.Config:Toggle({
    Title = "自動逃跑",
    Value = _G.AutoFlee,
    Callback = function(v)
        _G.AutoFlee = v
        if v then 
            StartAutoFlee() 
        else 
            StopAutoFlee() 
        end
        MarkConfigDirty()
    end
})

Tabs.Config:Slider({
    Title = "逃跑血量值 (%)",
    Desc = "血量低於設定值自動往上飛離",
    Value = {
        Min = 1,
        Max = 100,
        Default = _G.AutoFleeHP
    },
    Callback = function(v)
        _G.AutoFleeHP = v
        MarkConfigDirty()
    end
})

Tabs.Config:Toggle({
    Title = "移除玩家動作",
    Value = _G.RemoveAnim,
    Callback = function(v)
        _G.RemoveAnim = v
        if v then 
            StartRemoveAnim() 
        else 
            StopRemoveAnim() 
        end
        MarkConfigDirty()
    end
})

Tabs.Config:Toggle({
    Title = "水上行走",
    Value = _G.WaterWalkEnabled,
    Callback = function(v)
        _G.WaterWalkEnabled = v
        MarkConfigDirty()
    end
})

Tabs.Config:Toggle({
    Title = "移除岩漿",
    Value = _G.RemoveLavaEnabled,
    Callback = function(v)
        _G.RemoveLavaEnabled = v
        MarkConfigDirty()
    end
})

Tabs.Config:Toggle({
    Title = "移除鬼船傷害",
    Value = _G.RemoveGhostShipLavaEnabled,
    Callback = function(v)
        _G.RemoveGhostShipLavaEnabled = v
        MarkConfigDirty()
    end
})

Tabs.Skills:Section({ Title = "自動列賞" })
Tabs.Skills:Dropdown({
    Title = "選擇陣營",
    Values = { "海賊", "海軍" },
    Value = _G.SelectTeam == "Pirates" and "海賊" or "海軍",
    Callback = function(v)
        _G.SelectTeam = v == "海賊" and "Pirates" or "Marines"
        SelectTeam()
        MarkConfigDirty()
    end,
})
Tabs.Skills:Toggle({ 
    Title = "自動列賞", 
    Value = _G.FTP2_Enabled,
    Callback = function(v)
        _G.FTP2_Enabled = v
        if v then
            if _G.FTP_Enabled and type(StopFTPFlight) == "function" then 
                StopFTPFlight()
            end
            StartFTPFlight2()
            if WindUI then 
                WindUI:Notify({ Title = "自動列賞", Content = "已開啟", duration = 3 }) 
            end
        else
            StopFTPFlight2()
            if WindUI then 
                WindUI:Notify({ Title = "自動列賞", Content = "已關閉", duration = 3 }) 
            end
        end
        MarkConfigDirty()
    end
})

Tabs.Skills:Slider({
    Title = "鎖定玩家限時時間",
    Value = {
        Min = 60,
        Max = 300,
        Default = _G.FTP2_TimeoutLimit
    },
    Callback = function(v)
        _G.FTP2_TimeoutLimit = v
        MarkConfigDirty()
    end
})

Tabs.Skills:Button({
    Title = "跳過當前目標玩家",
    Callback = function()
        if _G.FTP2_CurrentTarget then
            local skippedName = _G.FTP2_CurrentTarget.Name
            _G.FTP2_Blacklist[_G.FTP2_CurrentTarget] = true
            _G.FTP2_CurrentTarget = nil
            _G.FTP2_TargetLockTime = os.clock()
            if WindUI then
                WindUI:Notify({ Title = "手動跳過", Content = "已跳過該名目標玩家", duration = 3 })
            end
        else
            if WindUI then
                WindUI:Notify({ Title = "手動跳過", Content = "目前沒有鎖定的目標玩家", duration = 3 })
            end
        end
    end
})

Tabs.Skills:Section({ Title = "自瞄" })

Tabs.Skills:Toggle({
    Title = "開啟自瞄 (技能 & M1)",
    Value = _G.SilentAimEnabled,
    Locked = disableHook,
    LockedTitle = disableHook and ("目前不支援 " .. tostring(executorName) .. " 執行器") or nil,
    Callback = function(v)
        if disableHook then return end
        _G.SilentAimEnabled = v
        MarkConfigDirty()
    end
})

Tabs.Skills:Toggle({
    Title = "畫面鎖定",
    Desc = "供無法使用自瞄的啟動器",
    Value = _G.CamlockEnabled,
    Callback = function(v)
        _G.CamlockEnabled = v
        MarkConfigDirty()
    end
})

Tabs.Skills:Toggle({
    Title = "隊伍檢測(不瞄隊友)",
    Value = _G.SilentAimTeamCheck,
    Callback = function(v)
        _G.SilentAimTeamCheck = v
        MarkConfigDirty()
    end
})

Tabs.Skills:Section({ Title = "使用技能" })

local function GetEnabledWeaponList()
    local list = {}
    for weaponName, data in pairs(_G.AutoSkillWeapons) do
        if data.Enable then
            table.insert(list, weaponName)
        end
    end
    return list
end

local function GetEnabledSkillList(weaponType)
    local list = {}
    local data = _G.AutoSkillWeapons[weaponType]
    if data then
        for skillName, skillData in pairs(data.Skills) do
            if skillData.Enable then
                table.insert(list, skillName)
            end
        end
    end
    return list
end

Tabs.Skills:Toggle({
    Title = "Auto Skills",
    Value = _G.AutoSkillMainEnable,
    Callback = function(v)
        _G.AutoSkillMainEnable = v
        MarkConfigDirty()
    end
})

Tabs.Skills:Dropdown({
    Title = "配置",
    Desc = "Melee,Fruit,Sword,Gun",
    Multi = true,
    Value = GetEnabledWeaponList(),
    Values = {"Melee", "Blox Fruit", "Sword", "Gun"},
    Callback = function(v)
        for k, wData in pairs(_G.AutoSkillWeapons) do 
            wData.Enable = false 
        end
        for k, val in pairs(v) do
            local wName = type(k) == "number" and val or k
            local isEnabled = type(k) == "number" and true or val
            if isEnabled and _G.AutoSkillWeapons[wName] then
                _G.AutoSkillWeapons[wName].Enable = true
            end
        end
        MarkConfigDirty()
    end
})

Tabs.Skills:Space()

Tabs.Skills:Divider()

Tabs.Skills:Space()

Tabs.Skills:Dropdown({
    Title = "拳法(Melee)",
    Multi = true,
    Value = GetEnabledSkillList("Melee"),
    Values = {"Z", "X", "C"},
    Callback = function(v)
        HandleSkillDropdown("Melee", v)
        MarkConfigDirty()
    end
})

Tabs.Skills:Dropdown({
    Title = "果實(Blox Fruit)",
    Multi = true,
    Value = GetEnabledSkillList("Blox Fruit"),
    Values = {"Z", "X", "C", "V", "F"},
    Callback = function(v)
        HandleSkillDropdown("Blox Fruit", v)
        MarkConfigDirty()
    end
})

Tabs.Skills:Dropdown({
    Title = "刀(Sword)",
    Multi = true,
    Value = GetEnabledSkillList("Sword"),
    Values = {"Z", "X"},
    Callback = function(v)
        HandleSkillDropdown("Sword", v)
        MarkConfigDirty()
    end
})

Tabs.Skills:Dropdown({
    Title = "槍(Gun)",
    Multi = true,
    Value = GetEnabledSkillList("Gun"),
    Values = {"Z", "X"},
    Callback = function(v)
        HandleSkillDropdown("Gun", v)
        MarkConfigDirty()
    end
})

Tabs.Settings:Section({ Title = "重置腳本" })

Tabs.Settings:Button({
    Title = "將所有配置恢復初始",
    Icon = "trash-2",
    Desc = "標記為待重置 下次啟動腳本時改為初始設定",
    Callback = function()
        local ok = pcall(function()
            if typeof(isfolder) == "function" and typeof(makefolder) == "function" and not isfolder(ConfigFolder) then
                makefolder(ConfigFolder)
            end
            if typeof(writefile) == "function" then
                writefile(ConfigFile, HttpService:JSONEncode(InitialConfig))
            end
        end)
        if ok then
            ConfigDirty = false
            WindUI:Notify({
                Title = "配置等待重置",
                Content = "下次啟動腳本後將完全生效 當前功能不受影響",
                Duration = 4
            })
        else
            WindUI:Notify({
                Title = "重置失敗",
                Content = "無法儲存設定檔 請確認執行器是否支援檔案寫入",
                Duration = 4
            })
        end
    end
})

Tabs.Settings:Section({ Title = "畫質設定" })

Tabs.Settings:Toggle({
    Title = "突破FPS上限",
    Value = _G.UnlockFPS,
    Callback = function(state)
        _G.UnlockFPS = state

        if _G.UnlockFPS and setfpscap then
            setfpscap(999)
        else
            if setfpscap then
                setfpscap(0)
            end
        end
        MarkConfigDirty()
    end
})

Tabs.Settings:Toggle({
    Title = "低配模式",
    Desc = "大幅優化效能",
    Value = _G.LowVisualMode,
    Callback = function(v)
        _G.SetLowVisualState(v)
        MarkConfigDirty()
    end
})

Tabs.Settings:Toggle({
    Title = "移除迷霧",
    Value = _G.RemoveFogEnabled,
    Callback = function(v)
        _G.RemoveFogEnabled = v
        if v then
            _G.ApplyRemoveFog()
        end
        MarkConfigDirty()
    end
})

Tabs.Settings:Section({ Title = "設定" })

Tabs.Settings:Toggle({ 
    Title = "Anti AFK", 
    Desc = "防止閒置被踢出", 
    Value = _G.AntiAFK_ENABLED,
    Callback = function(v) 
        _G.AntiAFK_ENABLED = v
        if _G.AntiAFK_ENABLED then 
            EnableAntiAFK() 
        else 
            DisableAntiAFK() 
        end
        MarkConfigDirty()
    end
})

Tabs.Settings:Toggle({ 
    Title = "自動重新連接", 
    Desc = "斷線或被踢出時自動重新加入伺服器", 
    Value = _G.AutoRejoinEnabled,
    Callback = function(v)
        _G.AutoRejoinEnabled = v
        MarkConfigDirty()
    end
})

Tabs.Settings:Toggle({ 
    Title = "換服後自動執行",
    Desc = "切換伺服器時自動重新載入",
    Value = _G.AutoExecute,
    Callback = function(v)
        _G.AutoExecute = v
        
        if _G.AutoExecute then
            if queue_on_teleport then
                writefile("AutoBounty.file", "true")
                queue_on_teleport(ScriptLoadstring)
                WindUI:Notify({
                    Title = "通知",
                    Content = "已開啟自動執行",
                    Duration = 3
                })
            else
                WindUI:Notify({
                    Title = "支援錯誤",
                    Content = "你目前的注入器不支援",
                    Duration = 3
                })
            end
        else
            if queue_on_teleport and isfile("AutoBounty.file") then
                delfile("AutoBounty.file")
            end
            WindUI:Notify({
                Title = "通知",
                Content = "已關閉自動執行",
                Duration = 3
            })
        end
        MarkConfigDirty()
    end
})

Tabs.Settings:Dropdown({
    Title = "選擇主題",
    Values = themeList,            
    Value = _G.Theme,            
    Callback = function(state)
        _G.Theme = state             
        WindUI:SetTheme(state)
        MarkConfigDirty()
    end
})

Tabs.Settings:Toggle({
    Title = "自動隱藏 UI",
    Desc = "開啟時將在 3 秒後自動隱藏介面",
    Value = _G.AutoHideEnabled,
    Callback = function(v)
        _G.AutoHideEnabled = v
        if v then
            startAutoHideTimer()
        end
        MarkConfigDirty()
    end
})

Tabs.Settings:Keybind({ 
    Title = "快捷鍵", 
    Desc = "可更改", 
    Value = _G.CurrentKey,
    Callback = function(v)
        _G.CurrentKey = typeof(v) == "EnumItem" and v.Name or tostring(v)
        
        if not _G.KeyDisabled then
            local success, keyCode = pcall(function() return Enum.KeyCode[_G.CurrentKey] end)
            if success then
                Window:SetToggleKey(keyCode)
            end
        end
        MarkConfigDirty()
    end
})

Tabs.Settings:Toggle({
    Title = "停用快捷鍵",
    Desc = "開啟後將禁用快捷鍵",
    Value = _G.KeyDisabled,
    Callback = function(state)
        _G.KeyDisabled = state
        
        if state then
            Window:SetToggleKey(nil)
        else
            local success, keyCode = pcall(function() return Enum.KeyCode[_G.CurrentKey] end)
            if success then
                Window:SetToggleKey(keyCode)
            end
        end
        MarkConfigDirty()
    end
})

--初始化狀態
task.spawn(function()
    task.wait()

    while typeof(EnableAntiAFK) ~= "function" do
        task.wait()
    end

    if _G.AutoExecute then
        if queue_on_teleport then
            if not isfile("AutoBounty.file") then
                writefile("AutoBounty.file", "true")
            end
            queue_on_teleport(ScriptLoadstring)
        end
    else
        if queue_on_teleport and isfile("AutoBounty.file") then
            delfile("AutoBounty.file")
        end
    end

    if _G.LowVisualMode then
        _G.SetLowVisualState(true)
    end

    if _G.RemoveFogEnabled then
        _G.ApplyRemoveFog()
    end

    if setfpscap then
        if _G.UnlockFPS then
            setfpscap(999)
        else
            setfpscap(0)
        end
    end

    if _G.AntiAFK_ENABLED then
        EnableAntiAFK()
    end

end)
