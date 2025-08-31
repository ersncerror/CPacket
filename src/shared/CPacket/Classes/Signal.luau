local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

function Connection.new(func)
	local self = {
		_Connected = true,
		_Func = func,
	}

	return setmetatable(self, Connection)
end

function Connection:Disconnect()
	self._Connected = false
end

-- Destroys the connection, this should only run by the signal library.
function Connection:_Destroy()
	for i, _ in self do
		self[i] = nil
	end

	self = setmetatable(self, {})
end

function Signal.new(): Signal
	local self = {
		_ConnectionLists = {},
	}

	return setmetatable(self, Signal)
end

-- Fires the signal, the connections will be triggered.
-- Note that disconnected connects will not be destroy until next signal fired.
-- (LOL BAD CODE???)
function Signal:Fire(...)

	local Connect = self._ConnectionLists

	while Connect do
		if not next(Connect) then
			break
		end

		if not Connect.Object._Connected then
			Connect.Previous.Next = Connect.Next

			Connect.Object:_Destroy()

			for i, _ in Connect do
				Connect[i] = nil
			end
		else
			if Connect.Once then
				task.spawn(Connect.Object._Func, ...)
				Connect.Object:Disconnect()
			else
				task.spawn(Connect.Object._Func, ...)
			end
		end

		Connect = Connect.Next
	end
end

function Signal:Wait()
	local NewConnect = Connection.new(coroutine.running())

	if not self._ConnectionLists.Object then
		local This = {}
		This.Object = NewConnect
		This.Previous = This
		This.Once = true

		self._ConnectionLists = This
	else
		local This = {}
		This.Object = NewConnect
		This.Previous = self._ConnectionLists
		This.Once = true

		self._ConnectionLists.Next = This
		self._ConnectionLists = This
	end

    return coroutine.yield()
end

function Signal:Once(func)
	local NewConnect = Connection.new(func)

	if not self._ConnectionLists.Object then
		local This = {}
		This.Object = NewConnect
		This.Previous = This
		This.Once = true

		self._ConnectionLists = This
	else
		local This = {}
		This.Object = NewConnect
		This.Previous = self._ConnectionLists
		This.Once = true

		self._ConnectionLists.Next = This
		self._ConnectionLists = This
	end
end

function Signal:Connect(func): Connection
	-- Returns a connection, when signal is triggered, function will be called.

	local NewConnect = Connection.new(func)

	if not self._ConnectionLists.Object then
		local This = {}
		This.Object = NewConnect
		This.Previous = This

		self._ConnectionLists = This
	else
		local This = {}
		This.Object = NewConnect
		This.Previous = self._ConnectionLists

		self._ConnectionLists.Next = This
		self._ConnectionLists = This
	end

	return NewConnect
end

function Signal:Destroy()
	for i, _ in self do
		self[i] = nil
	end

	self = setmetatable(self, {})
end

-------------
-- [ TYPES ]
-------------

export type Connection = {
	Disconnect: (self: Connection) -> (),
	_Destroy: (self: Connection) -> ()
}

export type Signal<T...> = {
	Fire: (self: Signal<T...>, T...) -> (),
	Wait: (self: Signal<T...>) -> (),
	Once: (self: Signal<T...>, func: any ) -> (),
	Connect: (self: Signal<T...>, func: any) -> (Connection),
	Destroy: (self: Signal<T...>) -> ()
}

return Signal
