local Players = game:GetService("Players")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BlackOverlay"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Full black background
local blackFrame = Instance.new("Frame")
blackFrame.Size = UDim2.fromScale(1, 1)
blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
blackFrame.BorderSizePixel = 0
blackFrame.Parent = screenGui

-- White button to list players
local listButton = Instance.new("TextButton")
listButton.Size = UDim2.new(0, 200, 0, 50)
listButton.Position = UDim2.new(0.5, -100, 0.05, 0)
listButton.BackgroundColor3 = Color3.new(1, 1, 1)
listButton.TextColor3 = Color3.new(0, 0, 0)
listButton.Text = "List Players"
listButton.Parent = blackFrame

-- ScrollingFrame for player list
local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Size = UDim2.new(0.4, 0, 0.6, 0)
playerListFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
playerListFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
playerListFrame.BorderSizePixel = 0
playerListFrame.CanvasSize = UDim2.new(0,0,0,0)
playerListFrame.Parent = blackFrame

-- Info box
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(0.4, 0, 0.6, 0)
infoLabel.Position = UDim2.new(0.55, 0, 0.15, 0)
infoLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
infoLabel.TextColor3 = Color3.new(1, 1, 1)
infoLabel.TextWrapped = true
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Text = "Select a player..."
infoLabel.Parent = blackFrame

-- Function to display player info
local function showPlayerInfo(plr)
    local info = {}
    table.insert(info, "Name: " .. plr.Name)
    table.insert(info, "DisplayName: " .. plr.DisplayName)
    table.insert(info, "UserId: " .. plr.UserId)

    -- Accessories (if character loaded)
    if plr.Character then
        local accs = {}
        for _, acc in ipairs(plr.Character:GetChildren()) do
            if acc:IsA("Accessory") then
                table.insert(accs, acc.Name)
            end
        end
        if #accs > 0 then
            table.insert(info, "Accessories: " .. table.concat(accs, ", "))
        else
            table.insert(info, "Accessories: None")
        end
    end

    infoLabel.Text = table.concat(info, "\n")
end

-- Function to list players
local function refreshPlayerList()
    playerListFrame:ClearAllChildren()
    local y = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 30)
        btn.Position = UDim2.new(0, 5, 0, y)
        btn.BackgroundColor3 = Color3.new(1, 1, 1)
        btn.TextColor3 = Color3.new(0, 0, 0)
        btn.Text = plr.Name
        btn.Parent = playerListFrame

        btn.MouseButton1Click:Connect(function()
            showPlayerInfo(plr)
        end)

        y = y + 35
    end
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, y)
end

-- Refresh when button clicked
listButton.MouseButton1Click:Connect(refreshPlayerList)

-- Auto update when players join/leave
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)
