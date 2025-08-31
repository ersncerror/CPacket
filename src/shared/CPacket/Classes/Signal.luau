--[[
	这个库具有其他功能！！！
	不要把这个当roblox的那种Remote使用！！！
]]

local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

local CacheLimit = 128

local FuncCall = task.spawn

-- FuncCall 应指定一个task库的函数，例如task.spawn或task.defer

-- 链接至信号，若信号具有缓存将会立即触发，若Once为true那么缓存只会触发一次。
local function ConnectToSignal(SignalToConnect: PrivateSignal, Object: PrivateConnection, Once: boolean?)
	local This = {}
	This.Object = Object
	This.Once = Once

	if SignalToConnect._ConnectionLists.Object then
		This.Next = SignalToConnect._ConnectionLists

		SignalToConnect._ConnectionLists.Previous = This
	end

	SignalToConnect._ConnectionLists = This

	if #SignalToConnect._Cached > 0 and not SignalToConnect._ClearingCaches then
		SignalToConnect._ClearingCaches = true

		if Once == true then
			local Cache = next(SignalToConnect)

			SignalToConnect:Fire(table.unpack(Cache))
			table.remove(SignalToConnect._Cached, 1)
		else 
			for i, Cache in SignalToConnect._Cached do
				SignalToConnect:Fire(table.unpack(Cache))
				SignalToConnect._Cached[i] = nil
			end
		end

		SignalToConnect._ClearingCaches = false
	end

end

function Connection.new(func)
	local self = {
		_Connected = true,
		_Func = func,
	}

	return setmetatable(self, Connection)
end

-- 断开链接，在下次本链接连接的信号触发时将会被摧毁。
function Connection:Disconnect()
	self._Connected = false
end

-- 摧毁链接，这应该只由Signal库来调用。
function Connection:_Destroy()
	for i, _ in self do
		self[i] = nil
	end

	self = setmetatable(self, {})
end

function Signal.new()
	local self = {
		_ConnectionLists = {},
		_Cached = {},
		_CacheDropped = 0,
		_NextCacheDropWarn = 1,
		_ClearingCaches = false,
	}

	return setmetatable(self, Signal)
end

-- 触发信号活动。
-- 注：已断开的链接只有在信号触发时才能被摧毁。
function Signal:Fire(...)
	local Connect = self._ConnectionLists :: LinkedConnect

	if not next(Connect) then
		if #self._Cached + 1 > CacheLimit then
			self._CacheDropped += 1
			
			if self._CacheDropped >= self._NextCacheDropWarn then
				self._NextCacheDropWarn *= 2
				error(`Did you forgot to connect signal? {self._CacheDropped} event has been dropped.`, 3)
			end

			return
		end
		table.insert(self._Cached, { ... })
		return
	end

	self._CacheDropped = 0

	while Connect do
		if not next(Connect) then
			break
		end

		local ToDestroy

		if not Connect.Object._Connected then
			local OldConnect = Connect

			if not OldConnect.Previous and OldConnect.Next then
				OldConnect.Next.Previous = nil
				self._ConnectionLists = OldConnect.Next
				ToDestroy = OldConnect
			end

			OldConnect.Object:_Destroy()

			OldConnect.Previous = nil
			OldConnect.Once = nil
			OldConnect.Object = nil
		else
			if Connect.Once then
				FuncCall(Connect.Object._Func, ...)
				Connect.Object:Disconnect()
			else
				FuncCall(Connect.Object._Func, ...)
			end
		end

		Connect = Connect.Next

		if ToDestroy then
			ToDestroy.Next = nil
		end
	end
end

-- 暂停当前线程直到本信号触发。
function Signal:Wait()
	local NewConnect = Connection.new(coroutine.running())

	ConnectToSignal(self, NewConnect, true)

	return coroutine.yield()
end

-- 在下一次信号触发后自动断开链接。
function Signal:Once(func)
	local NewConnect = Connection.new(func)

	ConnectToSignal(self, NewConnect, true)
end

-- 链接函数至信号，信号被触发时将会调用函数。
-- 注：链接会
function Signal:Connect(func): Connection
	-- Returns a connection, when signal is triggered, function will be called.

	local NewConnect = Connection.new(func)

	ConnectToSignal(self, NewConnect)

	return NewConnect
end

function Signal:Destroy()
	for i, _ in self do
		self[i] = nil
	end

	self = setmetatable(self, {})
end

--------------------
-- [ PUBLIC TYPES ]
--------------------

export type Connection = {
	-- [ Methods ]
	Disconnect: (self: Connection) -> (),
	_Destroy: (self: Connection) -> (),
}

export type Signal<T...> = {
	-- [ Properties ]
	_Cached: { { any } },

	-- [ Methods ]
	Fire: (self: Signal<T...>, T...) -> (),
	Wait: (self: Signal<T...>) -> (),
	Once: (self: Signal<T...>, func: any) -> (),
	Connect: (self: Signal<T...>, func: any) -> Connection,
	Destroy: (self: Signal<T...>) -> (),
}

---------------------
-- [ PRIVATE TYPES ]
---------------------

type LinkedConnect = {
	-- [ Properties ]
	Previous: LinkedConnect,
	Next: LinkedConnect,
	Object: PrivateConnection,
	Once: boolean?,
}

type PrivateConnection = {
	-- [ Properties ]
	_Func: any, -- function

	-- [ Methods ]
	Disconnect: (self: Connection) -> (),
	_Destroy: (self: Connection) -> (),
}

type PrivateSignal = {
	-- [ Properties ]
	_ConnectionLists: { LinkedConnect },
	_Cached: { { any } },
	_CacheDropped: number,
	_NextCacheDropWarn: number,
	_ClearingCaches: boolean,

	-- [ Methods ]
	Fire: (self: Signal<T...>, T...) -> (),
	Wait: (self: Signal<T...>) -> (),
	Once: (self: Signal<T...>, func: any) -> (),
	Connect: (self: Signal<T...>, func: any) -> Connection,
	Destroy: (self: Signal<T...>) -> (),
}

return Signal