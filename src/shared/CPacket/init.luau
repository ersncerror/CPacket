local RunService = game:GetService("RunService")

local Signal = require(script.Classes.Signal)

local RemoteCounter = 0

local RemoteEvent: RemoteEvent

local Remotes = {}
local Queue = {}

local PlayerQueues

local Classes = {}
Classes.__index = Classes

------------------------
-- [ Private Functions ]
------------------------

local function OnServerReceived(Player: Player, Package: { any })
	debug.profilebegin("Unpack client remote")

	for RemoteName, ListOfRemotes in Package do
		for _, Parameters in ListOfRemotes do
			if not Remotes[RemoteName] then
				warn(`{Player.Name} fired a remote ({RemoteName}) that is not found. This remote has been dropped.`)
				return
			end

			Remotes[RemoteName].OnServerEvent:Fire(table.unpack(Parameters))
		end
	end

	debug.profileend()
end

local function OnClientReceived(Package: { any })
	debug.profilebegin("Unpack server remote")

	for RemoteName, ListOfRemotes in Package do
		for _, Parameters in ListOfRemotes do
			if not Remotes[RemoteName] then
				warn(`Remote {RemoteName} was not found.`)
				return
			end

			Remotes[RemoteName].OnClientEvent:Fire(table.unpack(Parameters))
		end
	end

	debug.profileend()
end

------------------------
-- [ Public Functions ]
------------------------

-- 创建一个新远程。
function Classes.new(RemoteName: string)
	local Remote = Remotes[RemoteName]

	if Remote then
		return Remote
	end

	Remote = {
		Name = RemoteName,
		Type = "Event",
	}

	if RunService:IsServer() then
		local ThisRemoteId = tostring(RemoteCounter)

		Remote.Id = ThisRemoteId
		Remote.OnServerEvent = Signal.new()

		Remotes[ThisRemoteId] = Remote
		RemoteEvent:SetAttribute(RemoteName, ThisRemoteId)

		RemoteCounter += 1
	else
		Remote.Id = RemoteEvent:GetAttribute(RemoteName)
		Remote.OnClientEvent = Signal.new()

		if Remote.Id then
			Remotes[Remote.Id] = Remote
		end
	end

	Remotes[RemoteName] = Remote

	return setmetatable(Remote, Classes) :: BaseRemote
end

-- 向所有客户端或服务器发送远程，这取决于你在哪端上调用了此函数。
-- 若你在客户端上调用了此函数，那么将会向服务器发送远程。
-- 服务器则是向所有客户端发送远程。
function Classes:Fire(...)
	Queue[self.Id] = Queue[self.Id] or {}

	table.insert(Queue[self.Id], { ... })
end

-- 向客户端发送远程，仅限服务器。
function Classes:FireClient(player: Player, ...)
	if not RunService:IsServer() then
		error("You can't use FireClient on client.")
	end

	if not player.Parent then
		return
	end

	PlayerQueues[player] = PlayerQueues[player] or {}
	PlayerQueues[player][self.Id] = PlayerQueues[player][self.Id] or {}

	table.insert(PlayerQueues[player][self.Id], { ... })
end

-- 更改远程类型至RemoteFunction
function Classes:ChangeToResponse()
	if self.Type == "Response" then
		return
	end

	self.Type = "Response"

	if RunService:IsServer() then
		self.OnServerEvent = nil
		self.OnServerInvoke = false
	else
		self.OnClientEvent = nil
		self.OnClientInvoke = false
	end
end

------------------------
-- [ Initialize ]
------------------------

if RunService:IsServer() then
	PlayerQueues = {}

	RemoteEvent = Instance.new("RemoteEvent")
	RemoteEvent.Parent = script

	RemoteEvent.OnServerEvent:Connect(OnServerReceived)

	RunService.Heartbeat:Connect(function()
		if next(PlayerQueues) then
			for player: Player, remotes in PlayerQueues do
				RemoteEvent:FireClient(player, remotes)
			end

			table.clear(PlayerQueues)
		end

		if next(Queue) then
			RemoteEvent:FireAllClients(Queue)

			table.clear(Queue)
		end
	end)
elseif RunService:IsClient() then
	RemoteEvent = script:WaitForChild("RemoteEvent")

	RemoteEvent.OnClientEvent:Connect(OnClientReceived)

	RunService.Heartbeat:Connect(function()
		if next(Queue) then
			RemoteEvent:FireServer(Queue)

			table.clear(Queue)
		end
	end)
end

export type RemoteData = {
	Parameters: { any },
	Player: Player?,
}

export type BaseRemote<T...> = {
	-- [ Base Properties ]
	Id: string,
	Name: string,

	-- [ Methods ]
	FireClient: (self: BaseRemote<T...>, player: Player, T...) -> (),
	Fire: (self: BaseRemote<T...>, T...) -> (),

	-- [ Signals ]
	OnServerEvent: Signal.Signal?,
	OnClientEvent: Signal.Signal?,
}

return Classes
