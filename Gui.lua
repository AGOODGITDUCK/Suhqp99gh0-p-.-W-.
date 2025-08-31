-- Player Edit Panel
local EditPanel = Instance.new("Frame")
EditPanel.Size = UDim2.new(0.3,0,0.6,0)
EditPanel.Position = UDim2.new(0.35,0,0.2,0)
EditPanel.BackgroundColor3 = Color3.fromRGB(40,40,40)
EditPanel.Visible = false
EditPanel.Parent = Frame

local function MakeLabel(text, y)
	local lbl = Instance.new("TextLabel")
	lbl.Text = text
	lbl.Size = UDim2.new(0.4,0,0,30)
	lbl.Position = UDim2.new(0.05,0,y,0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.new(1,1,1)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = EditPanel
	return lbl
end

local function MakeBox(y)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0.5,0,0,30)
	box.Position = UDim2.new(0.45,0,y,0)
	box.Text = ""
	box.Parent = EditPanel
	return box
end

local RobuxBox, HealthBox, AccessoryBox
MakeLabel("Robux:", 0.05)
RobuxBox = MakeBox(0.05)

MakeLabel("Health:", 0.15)
HealthBox = MakeBox(0.15)

MakeLabel("Accessories:", 0.25)
AccessoryBox = MakeBox(0.25)

-- Save Button
local SaveBtn = Instance.new("TextButton")
SaveBtn.Text = "Save Changes"
SaveBtn.Size = UDim2.new(0.9,0,0,30)
SaveBtn.Position = UDim2.new(0.05,0,0.35,0)
SaveBtn.Parent = EditPanel

-- Wipe Button
local WipeBtn = Instance.new("TextButton")
WipeBtn.Text = "Wipe Player Data"
WipeBtn.Size = UDim2.new(0.9,0,0,30)
WipeBtn.Position = UDim2.new(0.05,0,0.45,0)
WipeBtn.Parent = EditPanel

-- Replace With Bacon Button
local ReplaceBtn = Instance.new("TextButton")
ReplaceBtn.Text = "Replace With Bacon Data"
ReplaceBtn.Size = UDim2.new(0.9,0,0,30)
ReplaceBtn.Position = UDim2.new(0.05,0,0.55,0)
ReplaceBtn.Parent = EditPanel

---------------------------------------------------
-- Refresh Players list with clickable editing
---------------------------------------------------
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
			EditPanel.Visible = true
			LogBox.Text = LogBox.Text .. "Editing: " .. plr.Name .. "\n"

			-- Example defaults (replace with actual server-side values if hooked up)
			RobuxBox.Text = tostring(plr:GetAttribute("Robux") or 0)
			HealthBox.Text = tostring(plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health or 100)
			AccessoryBox.Text = "Accessory1, Accessory2"

			-- Save changes
			SaveBtn.MouseButton1Click:Connect(function()
				LogBox.Text = LogBox.Text .. "Saved edits for " .. plr.Name .. "\n"
				-- Here you’d fire a RemoteEvent to actually apply changes server-side
			end)

			-- Wipe
			WipeBtn.MouseButton1Click:Connect(function()
				LogBox.Text = LogBox.Text .. "Wiped data for " .. plr.Name .. "\n"
			end)

			-- Replace
			ReplaceBtn.MouseButton1Click:Connect(function()
				LogBox.Text = LogBox.Text .. "Replaced " .. plr.Name .. " data with Bacon data\n"
			end)
		end)
	end
end

Players.PlayerAdded:Connect(RefreshPlayers)
Players.PlayerRemoving:Connect(RefreshPlayers)
RefreshPlayers()
