-- gui.lua
local Gui = {}

Gui.State = "PlayerList"   -- "PlayerList", "Editor", "Menu", "Logs"
Gui.SelectedPlayer = nil
Gui.Logs = {}

-- log helper
function Gui:AddLog(msg)
    table.insert(self.Logs, os.date("[%H:%M:%S] ") .. msg)
end

-- draw gui
function Gui:Draw()
    print("\n=== GUI ===")
    print("[☰] Hamburger Menu (type: menu)")

    if self.State == "PlayerList" then
        print("=== Players in this Experience ===")
        for i, plr in ipairs(Players:GetPlayers()) do
            print(i .. ". " .. plr.Name .. " | Robux: " .. plr.Data.Robux)
        end
        print("Select a player number to edit")
    elseif self.State == "Editor" and self.SelectedPlayer then
        local plr = self.SelectedPlayer
        print("=== Editing " .. plr.Name .. " ===")
        print("Robux: " .. plr.Data.Robux)
        print("Accessories: " .. table.concat(plr.Data.Accessories, ", "))
        print("[Back] to player list")
        print("Commands: Robux <number>, AddAccessory <name>, RemoveAccessory <name>")
    elseif self.State == "Menu" then
        print("=== Hamburger Menu ===")
        print("1. View Logs")
        print("2. Back")
    elseif self.State == "Logs" then
        print("=== Action Logs ===")
        for _, msg in ipairs(self.Logs) do
            print(msg)
        end
        print("[Back] to menu")
    end
end

-- handle input
function Gui:HandleInput(input)
    if input == "menu" then
        self.State = "Menu"
        return
    end

    if self.State == "PlayerList" then
        local idx = tonumber(input)
        local list = Players:GetPlayers()
        if idx and list[idx] then
            self.SelectedPlayer = list[idx]
            self.State = "Editor"
        end
    elseif self.State == "Editor" then
        if input == "Back" then
            self.State = "PlayerList"
            self.SelectedPlayer = nil
        else
            local parts = {}
            for word in string.gmatch(input, "[^ ]+") do
                table.insert(parts, word)
            end
            local cmd, value = parts[1], parts[2]
            if cmd == "Robux" then
                self:EditPlayer(self.SelectedPlayer, "Robux", value)
            elseif cmd == "AddAccessory" then
                self:EditPlayer(self.SelectedPlayer, "AddAccessory", value)
            elseif cmd == "RemoveAccessory" then
                self:EditPlayer(self.SelectedPlayer, "RemoveAccessory", value)
            end
        end
    elseif self.State == "Menu" then
        if input == "1" then
            self.State = "Logs"
        elseif input == "2" then
            self.State = "PlayerList"
        end
    elseif self.State == "Logs" then
        if input == "Back" then
            self.State = "Menu"
        end
    end
end

-- edit player data
function Gui:EditPlayer(plr, field, newValue)
    if field == "Robux" then
        plr.Data.Robux = tonumber(newValue) or plr.Data.Robux
        self:AddLog(plr.Name .. " Robux set to " .. plr.Data.Robux)
    elseif field == "AddAccessory" then
        table.insert(plr.Data.Accessories, newValue)
        self:AddLog(plr.Name .. " gained accessory: " .. newValue)
    elseif field == "RemoveAccessory" then
        for i, acc in ipairs(plr.Data.Accessories) do
            if acc == newValue then
                table.remove(plr.Data.Accessories, i)
                self:AddLog(plr.Name .. " lost accessory: " .. newValue)
                break
            end
        end
    end

    -- update avatar in-game
    if Players.UpdateAvatar then
        Players:UpdateAvatar(plr)
    end

    -- save persistently
    if Players.Save then
        Players:Save()
    end
end

return Gui
