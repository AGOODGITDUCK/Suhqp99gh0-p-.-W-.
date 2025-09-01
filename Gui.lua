--[[ 
Place this in StarterPlayerScripts (or StarterPlayerGui).
It will create:
 - GUI
 - RemoteEvents in ReplicatedStorage
 - ServerScript in ServerScriptService
 - Full data editing system
]]--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local LocalPlayer = Players.LocalPlayer

-- === Ensure RemoteEvents & ServerScript exist ===
local folder = ReplicatedStorage:FindFirstChild("AdminEvents")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "AdminEvents"
	folder.Parent = ReplicatedStorage
end

local editEvent = folder:FindFirstChild("EditPlayerData")
if not editEvent then
	editEvent = Instance.new("RemoteEvent")
	editEvent.Name = "EditPlayerData"
	editEvent.Parent = folder
end

local ensureScript = ServerScriptService:FindFirstChild("AdminDataHandler")
if not ensureScript then
	local src = Instance.new("Script")
	src.Name = "AdminDataHandler"
	src.Source = [[
		local Players = game:GetService("Players")
		local DataStoreService = game:GetService("DataStoreService")
		local PlayerDataStore = DataStoreService:GetDataStore("PlayerDataV1")
		local Events = game.ReplicatedStorage:WaitForChild("AdminEvents")
		local EditEvent = Events:WaitForChild("EditPlayerData")

		local function loadData(player)
			local data = {Robux=0, Health=100, Accessories={}}
			local ok, saved = pcall(function()
				return PlayerDataStore:GetAsync(player.UserId)
			end)
			if ok and saved then data = saved end
			player:SetAttribute("Robux", data.Robux)
			player:SetAttribute("Health", data.Health)
			player:SetAttribute("Accessories", table.concat(data.Accessories, ","))
		end

		local function saveData(player)
			local data = {
				Robux = player:GetAttribute("Robux") or 0,
				Health = player:GetAttribute("Health") or 100,
				Accessories = {}
			}
			local accStr = player:GetAttribute("Accessories")
			if accStr and accStr ~= "" then
				for acc in string.gmatch(accStr, "([^,]+)") do
					table.insert(data.Accessories, acc)
				end
			end
			pcall(function()
				PlayerDataStore:SetAsync(player.UserId, data)
			end)
		end

		Players.PlayerAdded:Connect(loadData)
		Players.PlayerRemoving:Connect(saveData)

		EditEvent.OnServerEvent:Connect(function(admin, targetUserId, newData, action)
			-- Replace YOUR userId here!
			if admin.UserId ~= 123456789 then return end

			local target = Players:GetPlayerByUserId(targetUserId)
			if not target then return end

			if action == "edit" then
				if newData.Robux then target:SetAttribute("Robux", tonumber(newData.Robux)) end
				if newData.Health then target:SetAttribute("Health", tonumber(newData.Health)) end
				if newData.Accessories then target:SetAttribute("Accessories", newData.Accessories) end
			elseif action == "wipe" then
				target:SetAttribute("Robux", 0)
				target:SetAttribute("Health", 100)
				target:SetAttribute("Accessories", "")
			elseif action == "bacon" then
				target:SetAttribute("Robux", 0)
				target:SetAttribute("Health", 100)
				target:SetAttribute("Accessories", "BaconHair")
			end
		end)
	]]
	src.Parent = ServerScriptService
end

-- === GUI CREATION ===
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "AdminGui"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0.3,0,0.6,0)
Frame.Position = UDim2.new(0.35,0,0.2,0)
Frame.BackgroundColor3 = Color3.fromRGB(20,20,20)

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1,0,0.1,0)
Title.Text = "Admin Data Panel"
Title.BackgroundColor3 = Color3.fromRGB(40,40,40)
Title.TextColor3 = Color3.new(1,1,1)

local PlayerList = Instance.new("ScrollingFrame", Frame)
PlayerList.Size = UDim2.new(1,0,0.4,0)
PlayerList.Position = UDim2.new(0,0,0.1,0)
PlayerList.CanvasSize = UDim2.new(0,0,0,0)

local RobuxBox = Instance.new("TextBox", Frame)
RobuxBox.PlaceholderText = "Robux"
RobuxBox.Size = UDim2.new(1,0,0.08,0)
RobuxBox.Position = UDim2.new(0,0,0.52,0)

local HealthBox = Instance.new("TextBox", Frame)
HealthBox.PlaceholderText = "Health"
HealthBox.Size = UDim2.new(1,0,0.08,0)
HealthBox.Position = UDim2.new(0,0,0.61,0)

local AccBox = Instance.new("TextBox", Frame)
AccBox.PlaceholderText = "Accessories (comma)"
AccBox.Size = UDim2.new(1,0,0.08,0)
AccBox.Position = UDim2.new(0,0,0.70,0)

local SaveBtn = Instance.new("TextButton", Frame)
SaveBtn.Text = "Save"
SaveBtn.Size = UDim2.new(0.33,0,0.08,0)
SaveBtn.Position = UDim2.new(0,0,0.8,0)

local WipeBtn = Instance.new("TextButton", Frame)
WipeBtn.Text = "Wipe"
WipeBtn.Size = UDim2.new(0.33,0,0.08,0)
WipeBtn.Position = UDim2.new(0.34,0,0.8,0)

local BaconBtn = Instance.new("TextButton", Frame)
BaconBtn.Text = "Baconize"
BaconBtn.Size = UDim2.new(0.33,0,0.08,0)
BaconBtn.Position = UDim2.new(0.67,0,0.8,0)

-- === Logic ===
local selectedPlayer = nil
local function refreshPlayers()
	PlayerList:ClearAllChildren()
	local y = 0
	for _,p in ipairs(Players:GetPlayers()) do
		local btn = Instance.new("TextButton", PlayerList)
		btn.Size = UDim2.new(1,0,0,30)
		btn.Position = UDim2.new(0,0,0,y)
		btn.Text = p.Name
		btn.MouseButton1Click:Connect(function()
			selectedPlayer = p
			RobuxBox.Text = tostring(p:GetAttribute("Robux") or 0)
			HealthBox.Text = tostring(p:GetAttribute("Health") or 100)
			AccBox.Text = p:GetAttribute("Accessories") or ""
		end)
		y = y + 30
	end
	PlayerList.CanvasSize = UDim2.new(0,0,0,y)
end

Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()

SaveBtn.MouseButton1Click:Connect(function()
	if selectedPlayer then
		editEvent:FireServer(selectedPlayer.UserId, {
			Robux = RobuxBox.Text,
			Health = HealthBox.Text,
			Accessories = AccBox.Text
		}, "edit")
	end
end)

WipeBtn.MouseButton1Click:Connect(function()
	if selectedPlayer then
		editEvent:FireServer(selectedPlayer.UserId, {}, "wipe")
	end
end)

BaconBtn.MouseButton1Click:Connect(function()
	if selectedPlayer then
		editEvent:FireServer(selectedPlayer.UserId, {}, "bacon")
	end
end)
