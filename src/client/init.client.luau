local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CPacket = require(ReplicatedStorage.Shared.CPacket)

local Remote = CPacket.new("TestRemote")

while task.wait(1) do
	Remote:Fire("Hello World! From Client!")
end