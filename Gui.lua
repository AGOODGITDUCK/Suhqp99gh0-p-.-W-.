-- // LocalScript (PlayerGui or StarterPlayerScripts) //

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Create RemoteEvents if missing
local function makeRemote(name)
    local remote = ReplicatedStorage:FindFirstChild(name)
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = ReplicatedStorage
    end
    return remote
end

local EditPlayerData = makeRemote("EditPlayerData")
local ToggleGui = makeRemote("ToggleGui")
local ServerLog = makeRemote("ServerLog")

-- Create Server Script if missing
if not ServerScriptService:FindFirstChild("PlayerDataHandler") then
    local serverScript = Instance.new("Script")
    serverScript.Name = "PlayerDataHandler"
    serverScript.Source = [[
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local DataStoreService = game:GetService("DataStoreService")
        local PlayerStore = DataStoreService:GetDataStore("PlayerStore")
        local EditPlayerData = ReplicatedStorage:WaitForChild("EditPlayerData")
        local ToggleGui = ReplicatedStorage:WaitForChild("ToggleGui")
        local ServerLog = ReplicatedStorage:WaitForChild("ServerLog")
        local PlayerData = {}

        local function LoadData(player)
            local data
            local success,result = pcall(function()
                return PlayerStore:GetAsync(player.UserId)
            end)
            if success and result then data=result else data={Robux=100,Accessories={},Health=100} end
            PlayerData[player.UserId]=data
            return data
        end

        local function SaveData(player)
            local data = PlayerData[player.UserId]
            if data then
                pcall(function()
                    PlayerStore:SetAsync(player.UserId,data)
                end)
            end
        end

        local function SetupLeaderstats(player,data)
            local leaderstats = Instance.new("Folder")
            leaderstats.Name = "leaderstats"
            leaderstats.Parent = player
            local robux = Instance.new("IntValue")
            robux.Name="Robux"
            robux.Value=data.Robux
            robux.Parent=leaderstats
            local health = Instance.new("IntValue")
            health.Name="Health"
            health.Value=data.Health
            health.Parent=leaderstats
        end

        Players.PlayerAdded:Connect(function(player)
            local data=LoadData(player)
            SetupLeaderstats(player,data)
        end)
        Players.PlayerRemoving:Connect(SaveData)

        EditPlayerData.OnServerEvent:Connect(function(admin,targetId,action,field,value)
            local target = Players:GetPlayerByUserId(targetId)
            local tdata = target and PlayerData[targetId]
            local adata = PlayerData[admin.UserId]

            if action=="edit" then
                if field=="Robux" or field=="Health" then
                    tdata[field]=value
                    if target then
                        local stat=target:FindFirstChild("leaderstats"):FindFirstChild(field)
                        stat.Value=value
                    end
                elseif field=="Accessory" then
                    table.insert(tdata.Accessories,value)
                end
            elseif action=="copy" then
                PlayerData[admin.UserId]=tdata
            elseif action=="replace" then
                local source = Players:FindFirstChild(value)
                if source then
                    PlayerData[targetId]=PlayerData[source.UserId]
                end
            elseif action=="wipe" then
                PlayerData[targetId]={Robux=0,Accessories={},Health=100}
            end
        end)
    ]]
    serverScript.Parent = ServerScriptService
end

-- === GUI Setup ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AdminGui"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(1,0,1,0)
Frame.BackgroundColor3 = Color3.new(0,0,0)
Frame.Parent = ScreenGui

-- Hamburger
local Hamburger = Instance.new("TextButton")
Hamburger.Text="☰"
Hamburger.Size=UDim2.new(0,50,0,50)
Hamburger.Position=UDim2.new(0,10,0,10)
Hamburger.TextScaled=true
Hamburger.Parent=Frame

-- Player list
local PlayerList = Instance.new("Frame")
PlayerList.Size=UDim2.new(0.3,0,0.8,0)
PlayerList.Position=UDim2.new(0.05,0,0.1,0)
PlayerList.BackgroundColor3=Color3.fromRGB(30,30,30)
PlayerList.Parent=Frame
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent=PlayerList

-- Log panel
local LogFrame = Instance.new("Frame")
LogFrame.Size=UDim2.new(0.4,0,0.8,0)
LogFrame.Position=UDim2.new(0.55,0,0.1,0)
LogFrame.BackgroundColor3=Color3.fromRGB(20,20,20)
LogFrame.Visible=false
LogFrame.Parent=Frame
local LogBox = Instance.new("TextLabel")
LogBox.Size=UDim2.new(1,0,1,0)
LogBox.TextXAlignment=Enum.TextXAlignment.Left
LogBox.TextYAlignment=Enum.TextYAlignment.Top
LogBox.TextWrapped=true
LogBox.TextColor3=Color3.new(1,1,1)
LogBox.Text="Logs:\n"
LogBox.Parent=LogFrame

-- Python console panel
local PythonPanel = Instance.new("Frame")
PythonPanel.Size=UDim2.new(0.4,0,0.4,0)
PythonPanel.Position=UDim2.new(0.55,0,0.55,0)
PythonPanel.BackgroundColor3=Color3.fromRGB(15,15,15)
PythonPanel.Visible=false
PythonPanel.Parent=Frame

local PythonInput = Instance.new("TextBox")
PythonInput.Size=UDim2.new(1,0,0.2,0)
PythonInput.Position=UDim2.new(0,0,0.8,0)
PythonInput.PlaceholderText="Enter Python code..."
PythonInput.TextColor3=Color3.new(1,1,1)
PythonInput.BackgroundColor3=Color3.fromRGB(40,40,40)
PythonInput.ClearTextOnFocus=false
PythonInput.Parent=PythonPanel

local PythonOutput = Instance.new("TextLabel")
PythonOutput.Size=UDim2.new(1,0,0.8,0)
PythonOutput.TextXAlignment=Enum.TextXAlignment.Left
PythonOutput.TextYAlignment=Enum.TextYAlignment.Top
PythonOutput.TextWrapped=true
PythonOutput.TextColor3=Color3.new(0,1,0)
PythonOutput.Text="Python Console:\n"
PythonOutput.Parent=PythonPanel

-- Python online execution
PythonInput.FocusLost:Connect(function(enter)
    if enter then
        local code = PythonInput.Text
        local response
        local timestamp = os.date("%X")
        local url = "https://run-python-online.com/api/run"
        local body = HttpService:JSONEncode({code=code})
        local success, result = pcall(function()
            return HttpService:PostAsync(url,body,Enum.HttpContentType.ApplicationJson)
        end)
        if success then
            local data = HttpService:JSONDecode(result)
            response = data.output or data.error or "No output"
        else
            response = "Failed to reach Python API"
        end
        PythonOutput.Text = PythonOutput.Text.."\n["..timestamp.."] "..tostring(response)
        PythonInput.Text=""
    end
end)

-- Player selection & editing
local SelectedTarget = nil
local function AddLog(msg)
    local timestamp = os.date("%X")
    LogBox.Text=LogBox.Text.."\n["..timestamp.."] "..msg
end

local function RefreshPlayers()
    for _,c in ipairs(PlayerList:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    for _,plr in ipairs(Players:GetPlayers()) do
        local btn = Instance.new("TextButton")
        btn.Size=UDim2.new(1,0,0,30)
        btn.Text=plr.Name
        btn.Parent=PlayerList
        btn.MouseButton1Click:Connect(function()
            SelectedTarget=plr
            AddLog("Selected "..plr.Name.." for editing")
        end)
    end
end

Players.PlayerAdded:Connect(RefreshPlayers)
Players.PlayerRemoving:Connect(RefreshPlayers)
RefreshPlayers()

-- Hamburger toggle
Hamburger.MouseButton1Click:Connect(function()
    LogFrame.Visible = not LogFrame.Visible
    PythonPanel.Visible = LogFrame.Visible
    ToggleGui:FireServer(LocalPlayer,LogFrame.Visible)
end)
