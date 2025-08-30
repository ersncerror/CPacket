local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CPacket = require(ReplicatedStorage.Shared.CPacket)

local Remote = CPacket.new("TestRemote")

Remote.OnClientEvent:Connect(function()
    
end)