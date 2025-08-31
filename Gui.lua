-- Gui.lua contents (upload this to GitHub, then your loader will work)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TestGui"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Black Background
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(1,0,1,0)
Frame.BackgroundColor3 = Color3.new(0,0,0)
Frame.Parent = ScreenGui

-- Hamburger Button
local Hamburger = Instance.new("TextButton")
Hamburger.Text = "☰"
Hamburger.Size = UDim2.new(0,50,0,50)
Hamburger.Position = UDim2.new(0,10,0,10)
Hamburger.Parent = Frame

-- Player List
local PlayerList = Instance.new("Frame")
PlayerList.Size = UDim2.new(0.3,0,0.8,0)
PlayerList.Position = UDim2.new(0.05,0,0.1,0)
PlayerList.BackgroundColor3 = Color3.fromRGB(30,30,30)
PlayerList.Parent = Frame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = PlayerList

-- Log Panel
local LogFrame = Instance.new("Frame")
LogFrame.Size = UDim2.new(0.4,0,0.8,0)
LogFrame.Position = UDim2.new(0.55,0,0.1,0)
LogFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
LogFrame.Visible = false
LogFrame.Parent = Frame

local LogBox = Instance.new("TextLabel")
LogBox.Size = UDim2.new(1,0,1,0)
LogBox.Text = "Logs:\n"
LogBox.TextColor3 = Color3.new(1,1,1)
LogBox.TextXAlignment = Enum.TextXAlignment.Left
LogBox.TextYAlignment = Enum.TextYAlignment.Top
LogBox.TextWrapped = true
LogBox.TextScaled = false
LogBox.Parent = LogFrame

-- Python Console (webpage iframe style simulation)
local PythonConsole = Instance.new("TextLabel")
PythonConsole.Size = UDim2.new(0.9,0,0.5,0)
PythonConsole.Position = UDim2.new(0.05,0,0.45,0)
PythonConsole.BackgroundColor3 = Color3.fromRGB(10,10,10)
PythonConsole.TextColor3 = Color3.new(0,1,0)
PythonConsole.TextXAlignment = Enum.TextXAlignment.Left
PythonConsole.TextYAlignment = Enum.TextYAlignment.Top
PythonConsole.TextWrapped = true
PythonConsole.TextScaled = false
PythonConsole.Text = "Python Console (placeholder)\nGo to: https://run-python-online.com"
PythonConsole.Visible = false
PythonConsole.Parent = Frame

-- Toggle panels
Hamburger.MouseButton1Click:Connect(function()
	LogFrame.Visible = not LogFrame.Visible
	PythonConsole.Visible = not PythonConsole.Visible
end)

-- Refresh Player List
local function RefreshPlayers()
	for _,c in ipairs(PlayerList:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for _,plr in ipairs(Players:GetPlayers()) do
		local btn = Instance.new("TextButton")
		btn.Text = plr.Name
		btn.Size = UDim2.new(1,0,0,30)
		btn.Parent = PlayerList

		btn.MouseButton1Click:Connect(function()
			LogBox.Text = LogBox.Text .. "Selected: " .. plr.Name .. "\n"
		end)
	end
end

Players.PlayerAdded:Connect(RefreshPlayers)
Players.PlayerRemoving:Connect(RefreshPlayers)
RefreshPlayers()

