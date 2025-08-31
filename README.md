# 📦 CPacket - Roblox 远程网络库
很酷的网络远程库！

>[!NOTE]
>本库更多~抄袭~借鉴的是Suphi的[Packet](https://devforum.roblox.com/t/packet-networking-library/3573907)网络库\
>此库为个人练习，欢迎指正我的问题和使用我编写的库。
>>（他的教程也很不错！各位Roblox脚本师有兴趣可以去看看。）

## ℹ️ 介绍
提供一些Roblox官方API不具有的功能，例：
| 功能 | 完成 |
| ---- | ---- |
| 将n次远程处理为一次| ✔ |
| RemoteFunction 超时未响应直接断开 |❌|
| 防DDoS功能| ❌|
| 压缩数据，减少网络负载| ❌|
| ~用起来非常简单！~| ✔|
> 有部分功能还没做完（

## 📖 使用
>[!IMPORTANT]
>服务器必须至少调用(require)一次该库才能运行。

#
让我们以服务器为例，创建一个`Script`，并创建一个新的远程。

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CPacket = require(ReplicatedStorage.CPacket)

local NewRemote = CPacket.new("Test")
```
现在我们已经创建了一个远程，我们可以通过`OnServerEvent`来接受客户端的远程。

```luau
local NewRemote = CPacket.new("Test")

NewRemote.OnServerEvent:Connect(function(Player, ...)
    print(Player.Name, ...)
end)
```

让我们在客户端上创建一个`LocalScript`，并写入相同的代码。*（除了OnServerEvent，这个要改成OnClientEvent）*\
现在，我们的客户端也可以接受来自服务器的远程。是时候让两端互相发送内容了。

我们可以通过使用`:Fire()`或`:FireClient()`(仅限服务器)来发送远程。
`:Fire()`可以被双方调用，若你在客户端上运行了该方法，这将会发送远程至服务器；(也就是`:FireServer()`)
若你在服务器上调用了此方法，这将会发送远程至所有客户端。（也就是`:FireAllClients()`）

```luau
-- Client Side
NewRemote:Fire("Hello Server!")

-- Server Side
NewRemote.OnServerEvent:Connect(function(Player, ...)
    print(Player.Name, ...) -- Roblox, Hello Server!
end)
```
这就是关于本库的基础内容了，其他功能还仍在开发，有兴趣可以[前往下载](https://github.com/ersncerror/CPacket/releases)使用。
