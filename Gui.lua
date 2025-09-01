-- Single LocalScript: Admin GUI (put in StarterPlayerScripts)
-- Creates server handler, remote events, GUI, draggable window, logs, and script-creator.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Admin user id to allow actions on server (we embed the installing player's id as admin)
local ALLOW_ADMIN_USERID = LocalPlayer.UserId

-- ------------------------
-- Create Replicated Remotes
-- ------------------------
local function ensureFolder(name)
    local f = ReplicatedStorage:FindFirstChild(name)
    if not f then
        f = Instance.new("Folder")
        f.Name = name
        f.Parent = ReplicatedStorage
    end
    return f
end

local adminFolder = ensureFolder("AdminEvents")

local function ensureRemote(folder, name)
    local r = folder:FindFirstChild(name)
    if not r then
        r = Instance.new("RemoteEvent")
        r.Name = name
        r.Parent = folder
    end
    return r
end

local EditEvent = ensureRemote(adminFolder, "EditPlayerData")
local CreateScriptEvent = ensureRemote(adminFolder, "CreateScript")

-- ------------------------
-- Create Server Script (with embedded admin id)
-- ------------------------
if not ServerScriptService:FindFirstChild("AdminDataHandler") then
    local adminId = ALLOW_ADMIN_USERID
    local serverSource = [[
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local PlayerDataStore = DataStoreService:GetDataStore("AdminPlayerDataV1")
local eventsFolder = game:GetService("ReplicatedStorage"):WaitForChild("AdminEvents")
local EditEvent = eventsFolder:WaitForChild("EditPlayerData")
local CreateScriptEvent = eventsFolder:WaitForChild("CreateScript")

local ADMIN_USER_ID = ]] .. tostring(adminId) .. [[

-- In-memory cache for player data
local PlayerData = {}

local function LoadDataFor(player)
    local default = {Robux = 0, Health = 100, Accessories = {}}
    local ok, data = pcall(function()
        return PlayerDataStore:GetAsync("Player_" .. player.UserId)
    end)
    if ok and data then
        PlayerData[player.UserId] = data
    else
        PlayerData[player.UserId] = default
    end

    -- create leaderstats for visible replication (Robux and Health)
    if not player:FindFirstChild("leaderstats") then
        local folder = Instance.new("Folder")
        folder.Name = "leaderstats"
        folder.Parent = player

        local robux = Instance.new("IntValue")
        robux.Name = "Robux"
        robux.Value = PlayerData[player.UserId].Robux or 0
        robux.Parent = folder

        local health = Instance.new("IntValue")
        health.Name = "Health"
        health.Value = PlayerData[player.UserId].Health or 100
        health.Parent = folder
    else
        local ls = player.leaderstats
        if ls:FindFirstChild("Robux") then
            ls.Robux.Value = PlayerData[player.UserId].Robux or 0
        end
        if ls:FindFirstChild("Health") then
            ls.Health.Value = PlayerData[player.UserId].Health or 100
        end
    end
end

local function SaveDataFor(player)
    local data = PlayerData[player.UserId]
    if data then
        -- read the latest from leaderstats if present
        local ls = player:FindFirstChild("leaderstats")
        if ls then
            if ls:FindFirstChild("Robux") then data.Robux = ls.Robux.Value end
            if ls:FindFirstChild("Health") then data.Health = ls.Health.Value end
        end
        -- Accessories are stored in data.Accessories
        pcall(function()
            PlayerDataStore:SetAsync("Player_" .. player.UserId, data)
        end)
    end
    PlayerData[player.UserId] = nil
end

Players.PlayerAdded:Connect(function(p)
    LoadDataFor(p)
end)

Players.PlayerRemoving:Connect(function(p)
    SaveDataFor(p)
end)

-- Admin action handler
EditEvent.OnServerEvent:Connect(function(admin, targetUserId, payload, action)
    -- restrict to allowed admin user id
    if not admin or admin.UserId ~= ADMIN_USER_ID then
        warn("Unauthorized admin call from", admin and admin.Name or "Unknown")
        return
    end

    local target = Players:GetPlayerByUserId(targetUserId)
    if not target then
        warn("Target not in server:", targetUserId)
        return
    end

    local tdata = PlayerData[target.UserId]
    if not tdata then
        -- try load if not present
        local ok, data = pcall(function()
            return PlayerDataStore:GetAsync("Player_" .. target.UserId)
        end)
        tdata = ok and data or {Robux = 0, Health = 100, Accessories = {}}
        PlayerData[target.UserId] = tdata
    end

    -- ACTIONS: edit, wipe, bacon, copy, replace
    if action == "edit" then
        if payload.Robux ~= nil then
            tdata.Robux = tonumber(payload.Robux) or 0
            if target:FindFirstChild("leaderstats") and target.leaderstats:FindFirstChild("Robux") then
                target.leaderstats.Robux.Value = tdata.Robux
            end
        end
        if payload.Health ~= nil then
            tdata.Health = tonumber(payload.Health) or 100
            if target:FindFirstChild("leaderstats") and target.leaderstats:FindFirstChild("Health") then
                target.leaderstats.Health.Value = tdata.Health
            end
        end
        if payload.Accessories ~= nil then
            -- payload.Accessories expected as comma-separated string
            local accs = {}
            for acc in string.gmatch(payload.Accessories, "([^,]+)") do
                acc = acc:gsub("^%s*(.-)%s*$", "%1") -- trim
                if acc ~= "" then table.insert(accs, acc) end
            end
            tdata.Accessories = accs
        end
    elseif action == "wipe" then
        tdata.Robux = 0
        tdata.Health = 100
        tdata.Accessories = {}
        if target:FindFirstChild("leaderstats") then
            if target.leaderstats:FindFirstChild("Robux") then target.leaderstats.Robux.Value = 0 end
            if target.leaderstats:FindFirstChild("Health") then target.leaderstats.Health.Value = 100 end
        end
    elseif action == "bacon" then
        tdata.Robux = 0
        tdata.Health = 100
        tdata.Accessories = {"BaconHair"}
        if target:FindFirstChild("leaderstats") then
            if target.leaderstats:FindFirstChild("Robux") then target.leaderstats.Robux.Value = 0 end
            if target.leaderstats:FindFirstChild("Health") then target.leaderstats.Health.Value = 100 end
        end
    elseif action == "copy" then
        -- payload should contain sourceUserId
        local sourceId = tonumber(payload.SourceUserId)
        if sourceId then
            local sourceData
            local ok, sdata = pcall(function()
                return PlayerDataStore:GetAsync("Player_" .. sourceId)
            end)
            if ok then
                sourceData = sdata
            end
            if sourceData then
                PlayerData[admin.UserId] = sourceData
            end
        end
    elseif action == "replace" then
        -- payload.SourceUserId provided - replace target with that data
        local sourceId = tonumber(payload.SourceUserId)
        if sourceId then
            local ok, sdata = pcall(function()
                return PlayerDataStore:GetAsync("Player_" .. sourceId)
            end)
            if ok and sdata then
                PlayerData[target.UserId] = sdata
                -- apply to leaderstats if present
                if target:FindFirstChild("leaderstats") then
                    if target.leaderstats:FindFirstChild("Robux") then target.leaderstats.Robux.Value = sdata.Robux or 0 end
                    if target.leaderstats:FindFirstChild("Health") then target.leaderstats.Health.Value = sdata.Health or 100 end
                end
            end
        end
    end

    -- Save immediately to DataStore for persistence
    pcall(function()
        PlayerDataStore:SetAsync("Player_" .. target.UserId, PlayerData[target.UserId])
    end)
end)

-- CreateScript handler
CreateScriptEvent.OnServerEvent:Connect(function(admin, scriptName, code)
    if not admin or admin.UserId ~= ADMIN_USER_ID then
        warn("Unauthorized create script attempt from", admin and admin.Name or "Unknown")
        return
    end
    local s = Instance.new("Script")
    s.Name = tostring(scriptName ~= "" and scriptName or "NewScript")
    s.Source = tostring(code or "")
    s.Parent = game:GetService("ServerScriptService")
end)
]]
    local serverScript = Instance.new("Script")
    serverScript.Name = "AdminDataHandler"
    serverScript.Source = serverSource
    serverScript.Parent = ServerScriptService
end

-- ------------------------
-- GUI: build main window (draggable)
-- ------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminGui"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local window = Instance.new("Frame")
window.Name = "AdminWindow"
window.Size = UDim2.new(0.34, 0, 0.62, 0)
window.Position = UDim2.new(0.33, 0, 0.19, 0)
window.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
window.Parent = screenGui
window.Active = true

-- Title and X button
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0.10, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(35,35,35)
titleBar.Parent = window

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.7,0,1,0)
title.Position = UDim2.new(0,0,0,0)
title.BackgroundTransparency = 1
title.Text = "Admin Data Panel"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextScaled = false
title.Font = Enum.Font.SourceSansBold
title.Parent = titleBar

local xBtn = Instance.new("TextButton")
xBtn.Name = "Close"
xBtn.Size = UDim2.new(0.08,0,0.8,0)
xBtn.Position = UDim2.new(0.92,0,0.1,0)
xBtn.Text = "X"
xBtn.TextColor3 = Color3.new(1,1,1)
xBtn.BackgroundColor3 = Color3.fromRGB(170,50,50)
xBtn.Parent = titleBar

xBtn.MouseButton1Click:Connect(function()
    window.Visible = false
end)

-- Make window draggable
do
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local inputConn = nil

    local function onInputChanged(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging and dragStart and startPos then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(
                math.clamp(startPos.X.Scale + delta.X / workspace.CurrentCamera.ViewportSize.X, 0, 1),
                startPos.X.Offset + delta.X,
                math.clamp(startPos.Y.Scale + delta.Y / workspace.CurrentCamera.ViewportSize.Y, 0, 1),
                startPos.Y.Offset + delta.Y
            )
        end
    end

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
            inputConn = UserInputService.InputChanged:Connect(onInputChanged)
        end
    end)

    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            dragStart = nil
            startPos = nil
            if inputConn then inputConn:Disconnect() inputConn = nil end
        end
    end)
end

-- ------------------------
-- Left panel: player list (scrolling)
-- ------------------------
local playerList = Instance.new("ScrollingFrame")
playerList.Name = "PlayerList"
playerList.Size = UDim2.new(0.48,0,0.78,0)
playerList.Position = UDim2.new(0.01,0,0.11,0)
playerList.CanvasSize = UDim2.new(0,0,0,0)
playerList.BackgroundColor3 = Color3.fromRGB(30,30,30)
playerList.BorderSizePixel = 0
playerList.Parent = window

local playerListLayout = Instance.new("UIListLayout")
playerListLayout.Parent = playerList
playerListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- ------------------------
-- Right panel: edit fields & buttons
-- ------------------------
local robuxBox = Instance.new("TextBox")
robuxBox.PlaceholderText = "Robux (number)"
robuxBox.Size = UDim2.new(0.48,0,0.08,0)
robuxBox.Position = UDim2.new(0.50,0,0.12,0)
robuxBox.Parent = window

local healthBox = Instance.new("TextBox")
healthBox.PlaceholderText = "Health (number)"
healthBox.Size = UDim2.new(0.48,0,0.08,0)
healthBox.Position = UDim2.new(0.50,0,0.21,0)
healthBox.Parent = window

local accBox = Instance.new("TextBox")
accBox.PlaceholderText = "Accessories (comma separated)"
accBox.Size = UDim2.new(0.48,0,0.08,0)
accBox.Position = UDim2.new(0.50,0,0.30,0)
accBox.Parent = window

local saveBtn = Instance.new("TextButton")
saveBtn.Text = "Save"
saveBtn.Size = UDim2.new(0.3,0,0.08,0)
saveBtn.Position = UDim2.new(0.50,0,0.42,0)
saveBtn.Parent = window

local wipeBtn = Instance.new("TextButton")
wipeBtn.Text = "Wipe"
wipeBtn.Size = UDim2.new(0.3,0,0.08,0)
wipeBtn.Position = UDim2.new(0.82,0,0.42,0)
wipeBtn.Parent = window

local baconBtn = Instance.new("TextButton")
baconBtn.Text = "Baconize"
baconBtn.Size = UDim2.new(0.3,0,0.08,0)
baconBtn.Position = UDim2.new(0.50,0,0.52,0)
baconBtn.Parent = window

-- ------------------------
-- Hamburger menu (slide-down)
-- ------------------------
local menuBtn = Instance.new("TextButton")
menuBtn.Text = "☰"
menuBtn.Size = UDim2.new(0.06,0,0.08,0)
menuBtn.Position = UDim2.new(0.44,0,0.01,0)
menuBtn.Parent = titleBar

local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(1,0,0.45,0)
menuFrame.Position = UDim2.new(0,0,1,0)
menuFrame.BackgroundColor3 = Color3.fromRGB(28,28,28)
menuFrame.Parent = window
menuFrame.Visible = false

local logsLabel = Instance.new("TextLabel")
logsLabel.Size = UDim2.new(1,0,0.08,0)
logsLabel.Position = UDim2.new(0,0,0,0)
logsLabel.Text = "Change Logs"
logsLabel.TextColor3 = Color3.new(1,1,1)
logsLabel.BackgroundColor3 = Color3.fromRGB(45,45,45)
logsLabel.Parent = menuFrame

local logsFrame = Instance.new("ScrollingFrame")
logsFrame.Size = UDim2.new(1,0,0.48,0)
logsFrame.Position = UDim2.new(0,0,0.08,0)
logsFrame.CanvasSize = UDim2.new(0,0,0,0)
logsFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
logsFrame.Parent = menuFrame

local logsLayout = Instance.new("UIListLayout")
logsLayout.Parent = logsFrame

local scriptTitle = Instance.new("TextLabel")
scriptTitle.Size = UDim2.new(1,0,0.06,0)
scriptTitle.Position = UDim2.new(0,0,0.58,0)
scriptTitle.Text = "Create Server Script"
scriptTitle.BackgroundColor3 = Color3.fromRGB(45,45,45)
scriptTitle.TextColor3 = Color3.new(1,1,1)
scriptTitle.Parent = menuFrame

local scriptNameBox = Instance.new("TextBox")
scriptNameBox.PlaceholderText = "Script name (optional)"
scriptNameBox.Size = UDim2.new(1,0,0.12,0)
scriptNameBox.Position = UDim2.new(0,0,0.64,0)
scriptNameBox.Parent = menuFrame

local scriptBox = Instance.new("TextBox")
scriptBox.PlaceholderText = "-- Paste Lua server script source here"
scriptBox.MultiLine = true
scriptBox.Size = UDim2.new(1,0,0.24,0)
scriptBox.Position = UDim2.new(0,0,0.76,0)
scriptBox.TextWrapped = true
scriptBox.Parent = menuFrame

local submitScriptBtn = Instance.new("TextButton")
submitScriptBtn.Text = "Submit Script to ServerScriptService"
submitScriptBtn.Size = UDim2.new(1,0,0.08,0)
submitScriptBtn.Position = UDim2.new(0,0,1, - (0.08 * window.AbsoluteSize.Y / window.AbsoluteSize.Y))
submitScriptBtn.Parent = menuFrame

menuBtn.MouseButton1Click:Connect(function()
    menuFrame.Visible = not menuFrame.Visible
end)

-- ------------------------
-- Logging helper
-- ------------------------
local logsCount = 0
local function logChange(text)
    logsCount = logsCount + 1
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,0,18)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = ("[%s] %s"):format(os.date("%X"), tostring(text))
    label.Parent = logsFrame
    logsFrame.CanvasSize = UDim2.new(0,0,0, logsCount * 18)
end

-- ------------------------
-- Player list population
-- ------------------------
local selectedPlayer = nil

local function refreshPlayerList()
    playerList:ClearAllChildren()
    logsCount = logsCount -- no change
    local y = 0
    for _, p in ipairs(Players:GetPlayers()) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0,28)
        btn.Position = UDim2.new(0,0,0,y)
        btn.Text = p.Name
        btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Parent = playerList

        btn.MouseButton1Click:Connect(function()
            selectedPlayer = p
            -- try reading leaderstats for visible values
            local ls = p:FindFirstChild("leaderstats")
            if ls and ls:FindFirstChild("Robux") then
                robuxBox.Text = tostring(ls.Robux.Value)
            else
                robuxBox.Text = tostring(p:GetAttribute("Robux") or 0)
            end
            if ls and ls:FindFirstChild("Health") then
                healthBox.Text = tostring(ls.Health.Value)
            else
                healthBox.Text = tostring(p:GetAttribute("Health") or 100)
            end
            accBox.Text = p:GetAttribute("Accessories") or ""
            logChange("Selected player: "..p.Name)
        end)

        y = y + 28
    end
    playerList.CanvasSize = UDim2.new(0,0,0,y)
end

Players.PlayerAdded:Connect(function() 
    refreshPlayerList() 
end)
Players.PlayerRemoving:Connect(function() 
    refreshPlayerList() 
end)
refreshPlayerList()

-- ------------------------
-- Button actions (fire server)
-- ------------------------
saveBtn.MouseButton1Click:Connect(function()
    if not selectedPlayer then return end
    local payload = {
        Robux = tonumber(robuxBox.Text) or 0,
        Health = tonumber(healthBox.Text) or 100,
        Accessories = tostring(accBox.Text or "")
    }
    EditEvent:FireServer(selectedPlayer.UserId, payload, "edit")
    logChange("Edited "..selectedPlayer.Name.." | R:"..payload.Robux.." H:"..payload.Health.." A:"..payload.Accessories)
end)

wipeBtn.MouseButton1Click:Connect(function()
    if not selectedPlayer then return end
    EditEvent:FireServer(selectedPlayer.UserId, {}, "wipe")
    logChange("Wiped "..selectedPlayer.Name.."'s data")
end)

baconBtn.MouseButton1Click:Connect(function()
    if not selectedPlayer then return end
    EditEvent:FireServer(selectedPlayer.UserId, {}, "bacon")
    logChange("Baconized "..selectedPlayer.Name)
end)

-- Script submit button sends code to server to create a Script
submitScriptBtn.MouseButton1Click:Connect(function()
    local name = scriptNameBox.Text
    local code = scriptBox.Text
    if code and code:match("%S") then
        CreateScriptEvent:FireServer(name, code)
        logChange("Submitted script '"..(name ~= "" and name or "Unnamed").."' to ServerScriptService")
        scriptBox.Text = ""
        scriptNameBox.Text = ""
    else
        logChange("Script submission failed: no code")
    end
end)
