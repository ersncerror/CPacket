local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CPacket = require(ReplicatedStorage.Shared.CPacket)

local Remote = CPacket.new("TestRemote")

Remote.OnClientEvent:Connect(function(...)
	print(...)
end)

while task.wait(1) do
	Remote:Fire("Hello World! From Client!")
end