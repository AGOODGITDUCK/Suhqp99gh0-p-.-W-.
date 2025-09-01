local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- ------------------------
-- Create RemoteEvents
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
-- GUI Setup
-- ------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminGui"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local window = Instance.new("Frame")
window.Size = UDim2.new(0, 400, 0, 300)
window.Position = UDim2.new(0.3,0,0.3,0)
window.BackgroundColor3 = Color3.fromRGB(30,30,30)
window.Parent = screenGui
window.Active = true

-- Make draggable
do
    local dragging = false
    local dragStart, startPos
    local function drag(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end

    window.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
        end
    end)
    window.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(drag)
end

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,30)
titleBar.BackgroundColor3 = Color3.fromRGB(50,50,50)
titleBar.Parent = window

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.8,0,1,0)
title.Text = "Admin Panel"
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)
title.Parent = titleBar

-- X button
local xBtn = Instance.new("TextButton")
xBtn.Size = UDim2.new(0.2,0,1,0)
xBtn.Position = UDim2.new(0.8,0,0,0)
xBtn.Text = "X"
xBtn.TextColor3 = Color3.new(1,1,1)
xBtn.BackgroundColor3 = Color3.fromRGB(150,50,50)
xBtn.Parent = titleBar
xBtn.MouseButton1Click:Connect(function() window.Visible = false end)

-- Hamburger menu
local menuBtn = Instance.new("TextButton")
menuBtn.Text = "☰"
menuBtn.Size = UDim2.new(0,30,0,30)
menuBtn.Position = UDim2.new(0.8, -35,0,0)
menuBtn.Parent = titleBar

local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(1,0,0,150)
menuFrame.Position = UDim2.new(0,0,1,0)
menuFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
menuFrame.Visible = false
menuFrame.Parent = window

menuBtn.MouseButton1Click:Connect(function()
    menuFrame.Visible = not menuFrame.Visible
end)

-- Player list
local playerList = Instance.new("ScrollingFrame")
playerList.Size = UDim2.new(0.45,0,0.7,0)
playerList.Position = UDim2.new(0.01,0,0.1,0)
playerList.CanvasSize = UDim2.new(0,0,0,0)
playerList.BackgroundColor3 = Color3.fromRGB(35,35,35)
playerList.BorderSizePixel = 0
playerList.Parent = window

local layout = Instance.new("UIListLayout")
layout.Parent = playerList

-- Player selection
local selectedPlayer
local function refreshPlayers()
    playerList:ClearAllChildren()
    for _, plr in ipairs(Players:GetPlayers()) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0,30)
        btn.Text = plr.Name
        btn.Parent = playerList
        btn.MouseButton1Click:Connect(function()
            selectedPlayer = plr
        end)
    end
end
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()

-- Example action buttons
local robuxBtn = Instance.new("TextButton")
robuxBtn.Text = "Add 100 Robux"
robuxBtn.Size = UDim2.new(0.45,0,0.08,0)
robuxBtn.Position = UDim2.new(0.5,0,0.1,0)
robuxBtn.Parent = window
robuxBtn.MouseButton1Click:Connect(function()
    if selectedPlayer then
        EditEvent:FireServer(selectedPlayer.UserId, {Robux=100}, "edit")
    end
end)
