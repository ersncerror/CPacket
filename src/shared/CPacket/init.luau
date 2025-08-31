local RunService = game:GetService("RunService")

local Signal = require(script.Classes.Signal)

local RemoteLimit = 0
local LastRemoteHandle = 0

local RemoteCounter = 0

local RemoteEvent: RemoteEvent

local Remotes = {}
local Queue = {}

local Classes = {}
Classes.__index = Classes

------------------------
-- [ Private Functions ]
------------------------

local function ProcessRemoteFire()
	if RemoteLimit <= 0 or os.clock() - LastRemoteHandle < RemoteLimit then
		return
	end

	LastRemoteHandle = os.clock()

	local ToAll = {}
	local ToClient = {}

	debug.profilebegin("Process Remote Fire")

	for RemoteName, ListOfRemotes in Queue do
		for Index, Remote: RemoteData in ListOfRemotes do
			if Remote.Player then
				ToClient[Remote.Player] = ToClient[Remote.Player] or {}
				ToClient[Remote.Player][RemoteName] = ToClient[Remote.Player][RemoteName] or {}

				table.insert(ToClient[Remote.Player][RemoteName], Remote.Parameters)
			else
				ToAll[RemoteName] = ToAll[RemoteName] or {}

				table.insert(ToAll[RemoteName], Remote)
			end

			ListOfRemotes[Index] = nil
		end

		Queue[RemoteName] = nil
	end

	if RunService:IsServer() then
		if next(ToAll) then
			RemoteEvent:FireAllClients(ToAll)
		end

		if next(ToClient) then
			for Player, Packages in ToClient do
				RemoteEvent:FireClient(Player, Packages)
			end
		end
	else
		if next(ToAll) then
			RemoteEvent:FireServer(ToAll)
		end
	end

	debug.profileend()
end

------------------------
-- [ Public Functions ]
------------------------

-- Constructor
function Classes.new(RemoteName: string)
	local Remote = Remotes[RemoteName]

	if Remote then
		return Remote
	end

	Remote = {
		Name = RemoteName,
	}

	if RunService:IsServer() then
		local ThisRemoteId = tostring(RemoteCounter)

		Remote.Id = ThisRemoteId
		Remote.OnServerEvent = Signal.new() :: Signal.Signal

		Remotes[ThisRemoteId] = Remote
		RemoteEvent:SetAttribute(RemoteName, ThisRemoteId)

		RemoteCounter += 1
	else
		Remote.Id = RemoteEvent:GetAttribute(RemoteName)
		Remote.OnClientEvent = Signal.new() :: Signal.Signal

		if Remote.Id then
			Remotes[Remote.Id] = Remote
		end
	end

	Remotes[RemoteName] = Remote

	return setmetatable(Remote, Classes) :: BaseRemote
end

-- Fire remote to all clients or server, based on the side who called this method.
-- If you called this method on client, this will fire to the server.
-- Else this will fire to all clients.
function Classes:Fire(...)
	Queue[self.Id] = Queue[self.Id] or {}

	table.insert(Queue[self.Id], { ... })
end

-- Fire remote to a client, server side only.
function Classes:FireClient(player: Player, ...)
	if not RunService:IsServer() then
		error("You can't use FireClient on client.")
	end

	if not player.Parent then
		return
	end

	Queue[self.Id] = Queue[self.Id] or {}

	table.insert(Queue[self.Id], { Player = player, Parameters = { ... } })
end

------------------------
-- [ Initialize ]
------------------------

if RunService:IsServer() then
	RemoteEvent = Instance.new("RemoteEvent")
	RemoteEvent.Parent = script

	RemoteEvent.OnServerEvent:Connect(function(Player, Package)
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
	end)
elseif RunService:IsClient() then
	RemoteEvent = script:WaitForChild("RemoteEvent")

	RemoteEvent.OnClientEvent:Connect(function(Package)
		debug.profilebegin("Unpack server remote")

		for RemoteName, ListOfRemotes in Package do
			for _, Parameters in ListOfRemotes do
				if not Remotes[RemoteName] then
					warn(`Remote {RemoteName} was not found.`)
					return
				end

				Remotes[RemoteName].OnServerEvent:Fire(table.unpack(Parameters))
			end
		end

		debug.profileend()
	end)
end

RunService.Heartbeat:Connect(ProcessRemoteFire)

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
