--local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CPacket = require(ReplicatedStorage.Shared.CPacket)

--local Player = Players:FindFirstChildOfClass("Player") or Players.PlayerAdded:Wait()

local Remote = CPacket.new("TestRemote")

Remote.OnServerEvent:Connect(function()
    
end)
