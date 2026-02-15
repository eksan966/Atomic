local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

function gradient(text, startColor, endColor)
    local result = ""
    local chars = {}
    
    for uchar in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(chars, uchar)
    end
    
    local length = #chars
    
    for i = 1, length do
        local t = (i - 1) / math.max(length - 1, 1)
        local r = startColor.R + (endColor.R - startColor.R) * t
        local g = startColor.G + (endColor.G - startColor.G) * t
        local b = startColor.B + (endColor.B - startColor.B) * t
        
        result = result .. string.format('<font color="rgb(%d,%d,%d)">%s</font>', 
            math.floor(r * 255), 
            math.floor(g * 255), 
            math.floor(b * 255), 
            chars[i])
    end
    
    return result
end

local Window = WindUI:CreateWindow({
    Title = gradient("Atomic   ", Color3.fromHex("#00DBDE"), Color3.fromHex("#FC00FF")), 
    Author = gradient("街头生活", Color3.fromHex("#00FF87"), Color3.fromHex("#60EFFF")),
    IconThemed = true,
    Folder = "Atomic",
    Size = UDim2.fromOffset(150, 100),
     Transparent = getgenv() and getgenv().TransparencyEnabled or false,
     Theme = "Dark",
     Resizable = true,
     SideBarWidth = 150,
     BackgroundImageTransparency = 0.8,
     HideSearchBar = true,
     ScrollBarEnabled = true,
     User = {
         Enabled = true,
         Anonymous = false,
         Callback = function()
             currentThemeIndex = currentThemeIndex + 1
             if currentThemeIndex > #themes then
                 currentThemeIndex = 1
             end
             
             local newTheme = themes[currentThemeIndex]
             WindUI:SetTheme(newTheme)
         end,
     },
 })


    
Window:EditOpenButton({
    Title = "[Atomic]",
    CornerRadius = UDim.new(0,8),
    StrokeThickness = 4,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHex("1E3A8A")),
        ColorSequenceKeypoint.new(0.5, Color3.fromHex("118AB2")), 
        ColorSequenceKeypoint.new(1, Color3.fromHex("06D6A0")) 
    }),
    Draggable = true,
})
Window:Tag({
    Title = "付费版",
    Radius = 5,
    Color = Color3.fromHex("#FFB347"),
})
Window:SetToggleKey(Enum.KeyCode.F, true)

_G.WalkSpeedValue = 16
_G.SpeedEnabled = false
_G.TpToNearest = false
_G.MeleeAuraEnabled = false
_G.AutoInteract = false
_G.AuraRange = 18

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")

local function isInSafeZone(player)
    if not player or not player.Character then return true end
    local char = player.Character

    if char:FindFirstChildOfClass("ForceField") then
        return true
    end

    if char:GetAttribute("InSafeZone") or player:GetAttribute("InSafeZone") then
        return true
    end
    if char:GetAttribute("SafeZone") or player:GetAttribute("SafeZone") then
        return true
    end

    local hum = char:FindFirstChild("Humanoid")
    if hum and hum.MaxHealth <= 0 then
        return true
    end

    return false
end

local PPS = game:GetService("ProximityPromptService")
PPS.PromptShown:Connect(function(prompt)
    if _G.AutoInteract then
        prompt.HoldDuration = 0
        task.spawn(function()
            task.wait(0.1)
            if fireproximityprompt then
                fireproximityprompt(prompt)
            else
                prompt:InputHoldBegin()
                task.wait()
                prompt:InputHoldEnd()
            end
        end)
    end
end)

local Main = Window:Tab({ Title = "暴力功能", Icon = "triangle" })
Main:Section({Title = "反作弊绕过（等抱起后就可以关闭这个功能了）"})
Main:Toggle({
    Title = "绕过拉回检测",
    Default = false,
    Callback = function(enabled)
        _G.TpToNearest = enabled
        _G.MeleeAuraEnabled = enabled
        _G.AutoInteract = enabled
        
        if not enabled then return end
        
        local function getNearestPlayer()
            local closestPlayer = nil
            local shortestDistance = math.huge
            
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local hum = player.Character:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        if isInSafeZone(player) then
                            continue
                        end

                        local dist = (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                        if dist < shortestDistance then
                            closestPlayer = player
                            shortestDistance = dist
                        end
                    end
                end
            end
            return closestPlayer
        end
        
        task.spawn(function()
            while _G.TpToNearest or _G.MeleeAuraEnabled do
                task.wait(0.1)
                
                if isInSafeZone(LocalPlayer) then
                end

                local target = getNearestPlayer()
                if not target or not target.Character then continue end
                
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
                
                local root = char.HumanoidRootPart
                local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local tHum = target.Character:FindFirstChild("Humanoid")
                
                if tRoot and tHum then
                    local distance = (root.Position - tRoot.Position).Magnitude

                    if _G.TpToNearest then
                        root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3)
                    end

                    if _G.MeleeAuraEnabled and distance <= _G.AuraRange then
                        CombatEvent:FireServer("Hit", tHum, tRoot)
                    end
                end
            end
        end)
    end
})

Main:Section({Title = "杀戮光环"})

Main:Toggle({
    Title = "愤怒机器人",
    Default = false,
    Callback = function(enabled)
        if not enabled then
            _G.AngryBotEnabled = false
            return
        end
        
        _G.AngryBotEnabled = true
        
        local Players = game:GetService("Players")
        local lp = Players.LocalPlayer
        local Camera = workspace.CurrentCamera
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Workspace = game:GetService("Workspace")
        local Remotes = ReplicatedStorage.Modules.GunFramework.Remotes
        local ReloadRemote = Remotes:WaitForChild("Reload")
        local UpdateRemote = Remotes:WaitForChild("Update")
        local ShootRemote = nil
        for _, v in pairs(Remotes:GetChildren()) do
            if string.match(v.Name, "^%x%x%x%x%x%x%x%x%-") then 
                ShootRemote = v 
                break 
            end
        end
        local function RefreshSecurityValues()
            for _, v in pairs(getgc()) do
                if type(v) == "function" and islclosure(v) then
                    local ups = debug.getupvalues(v)
                    if ups[3] == ShootRemote then
                        _G.G_Code = ups[4]
                        _G.G_Token = ups[6]
                        _G.G_Remote = ShootRemote
                        return true
                    end
                end
            end
            return false
        end
        RefreshSecurityValues()
        UpdateRemote.OnClientEvent:Connect(function(mode, val)
            if mode == "Token" then
                _G.G_Token = val
            end
        end)
        local function psd(tl)
            local s = Instance.new("Sound")
            s.Volume = 1
            s.Parent = Camera
            local sn = tl and tl:FindFirstChild("Hold") and tl.Hold:FindFirstChild("Sounds") and tl.Hold.Sounds:FindFirstChild("Shoot")
            s.SoundId = sn and sn.SoundId or "rbxassetid://88387457337661"
            s:Play()
            game:GetService("Debris"):AddItem(s, 3)
        end
        local function bmk(st, ed)
            local p1 = Instance.new("Part")
            p1.Anchored, p1.CanCollide, p1.Transparency = true, false, 1
            p1.Size, p1.Position, p1.Parent = Vector3.new(0.1, 0.1, 0.1), st, Workspace
            
            local p2 = Instance.new("Part")
            p2.Anchored, p2.CanCollide, p2.Transparency = true, false, 1
            p2.Size, p2.Position, p2.Parent = Vector3.new(0.1, 0.1, 0.1), ed, Workspace
            
            local at1, at2 = Instance.new("Attachment", p1), Instance.new("Attachment", p2)
            
            local bm1 = Instance.new("Beam")
            bm1.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(75, 0, 130)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(138, 43, 226)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 112))
            })
            bm1.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.1), NumberSequenceKeypoint.new(1, 0.3)})
            bm1.Width0, bm1.Width1, bm1.Texture, bm1.TextureSpeed = 0.6, 0.6, "rbxassetid://446111271", 1.5
            bm1.TextureMode, bm1.TextureLength, bm1.Brightness, bm1.LightEmission = Enum.TextureMode.Wrap, 2, 2, 0.4
            bm1.FaceCamera, bm1.Attachment0, bm1.Attachment1, bm1.Parent = true, at1, at2, p1
            
            local bm2 = Instance.new("Beam")
            bm2.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 130, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 180, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 150, 255))
            })
            bm2.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.5, 0.4), NumberSequenceKeypoint.new(1, 0.7)})
            bm2.Width0, bm2.Width1, bm2.Texture, bm2.TextureSpeed = 0.25, 0.25, "rbxassetid://446111271", 2.2
            bm2.TextureMode, bm2.TextureLength, bm2.Brightness, bm2.LightEmission = Enum.TextureMode.Wrap, 1.5, 3, 1
            bm2.FaceCamera, bm2.Attachment0, bm2.Attachment1, bm2.Parent = true, at1, at2, p1
            
            task.delay(math.random(8, 18) / 10, function()
                for i = 0, 1, 0.08 do
                    if not p1.Parent then break end
                    bm1.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, i * 0.6), NumberSequenceKeypoint.new(0.5, 0.1 + i * 0.5), NumberSequenceKeypoint.new(1, 0.3 + i * 0.7)})
                    bm2.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2 + i * 0.6), NumberSequenceKeypoint.new(0.5, 0.4 + i * 0.5), NumberSequenceKeypoint.new(1, 0.7 + i * 0.3)})
                    task.wait(0.02)
                end
                p1:Destroy()
                p2:Destroy()
            end)
        end
        local function getBestTarget()
            local closestDist, targetHead = math.huge, nil
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= lp and p.Character and p.Character:FindFirstChild("Head") then
                    local char = p.Character
                    local sfObj = char:FindFirstChild("SafeField")
                    local isSafe = sfObj and sfObj:IsA("ValueBase") and sfObj.Value == true
                    local hasForceField = char:FindFirstChildOfClass("ForceField")
                    if not isSafe and not hasForceField then
                        local head = char.Head
                        local dist = (head.Position - Camera.CFrame.Position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            targetHead = head
                        end
                    end
                end
            end
            return targetHead
        end
        local function shootSequence()
            local tool = lp.Character and lp.Character:FindFirstChildOfClass("Tool")
            if not tool then return end
            local ammo = tool:GetAttribute("Ammo_Server")
            if ammo and ammo <= 0 then
                local Event = game:GetService("ReplicatedStorage").Remotes.GunBuy
                Event:FireServer(
                    "Pistol Ammo",
                    50
                )
                ReloadRemote:FireServer()
                local t = 0
                while tool:GetAttribute("Ammo_Server") == 0 and t < 20 do
                    task.wait(0.1)
                    t = t + 1
                    if not lp.Character:FindFirstChild(tool.Name) then break end
                end
                return 
            end
        
            local gunId = tool:GetAttribute("Id")
            local target = getBestTarget()
            if target and gunId and _G.G_Code and _G.G_Token and _G.G_Remote then
                local origin = Camera.CFrame.Position
                local direction = (target.Position - origin).Unit
                Remotes.Fire:FireServer(_G.G_Code, origin, direction)
                _G.G_Remote:FireServer(
                    _G.G_Code,
                    gunId,
                    target,
                    direction,
                    nil,
                    _G.G_Token
                )
                bmk(origin, target.Position)
                psd(tool)
            else
                if not _G.G_Token or not _G.G_Code then 
                    RefreshSecurityValues() 
                end
            end
        end
        
        while _G.AngryBotEnabled and task.wait(0.05) do
            shootSequence()
        end
    end
})

Main:Toggle({
    Title = "近战杀戮光环",
    Default = false,
    Callback = function(enabled)
        _G.MeleeAuraEnabled = enabled
        if not enabled then return end
        
        local Players = game:GetService("Players")
        local LP = Players.LocalPlayer
        local Event = game:GetService("ReplicatedStorage").Remotes.Combat
        
        task.spawn(function()
            while _G.MeleeAuraEnabled do
                task.wait(0.2)
                local char = LP.Character
                if not char then continue end
                
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root then continue end

                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character and p.Character:FindFirstChild("Humanoid") then
                        local tRoot = p.Character:FindFirstChild("HumanoidRootPart")
                        local hum = p.Character.Humanoid
                        if tRoot and (tRoot.Position - root.Position).Magnitude <= 18 and hum.Health > 0 then
                            Event:FireServer("Hit", hum, tRoot)
                            break
                        end
                    end
                end
            end
        end)
    end
})

Main:Toggle({
    Title = "推人光环",
    Default = false,
    Callback = function(enabled)
        _G.PushAuraEnabled = enabled
        if not enabled then return end
        
        local Players = game:GetService("Players")
        local CombatEvent = game:GetService("ReplicatedStorage").Remotes.Combat
        local LP = Players.LocalPlayer
        
        task.spawn(function()
            while _G.PushAuraEnabled do
                task.wait(0.3)
                local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if not myRoot then continue end
                
                local count = 0
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        local hum = p.Character:FindFirstChild("Humanoid")
                        local root = p.Character:FindFirstChild("HumanoidRootPart")
                        
                        if hum and root and hum.Health > 0 then
                            if (myRoot.Position - root.Position).Magnitude <= 20 then
                                CombatEvent:FireServer("Push", hum)
                                count = count + 1
                            end
                        end
                    end
                    if count > 5 then break end 
                end
            end
        end)
    end
})

Main:Toggle({
    Title = "踩踏光环",
    Default = false,
    Callback = function(enabled)
        _G.StompAuraEnabled = enabled
        if not enabled then return end
        
        local CombatEvent = game:GetService("ReplicatedStorage").Remotes.Combat
        task.spawn(function()
            while _G.StompAuraEnabled do
                task.wait(0.5)
                local lp = game:GetService("Players").LocalPlayer
                local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if not myRoot then continue end

                for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
                    if p ~= lp and p.Character then
                        local hum = p.Character:FindFirstChild("Humanoid")
                        local root = p.Character:FindFirstChild("HumanoidRootPart")
                        if hum and root and hum.Health <= 5 and (myRoot.Position - root.Position).Magnitude <= 15 then
                            CombatEvent:FireServer("Stomp", hum, hum)
                        end
                    end
                end
            end
        end)
    end
})

Main:Toggle({
    Title = "仿安全区",
    Default = false,
    Callback = function(enabled)
        _G.AntiSafeZoneEnabled = enabled
        if not enabled then return end
        
        local Event = game:GetService("ReplicatedStorage").Remotes.ZoneRemote
        task.spawn(function()
            while _G.AntiSafeZoneEnabled do
                firesignal(Event.OnClientEvent, "SafeEnter", "Car")
                task.wait(1)
            end
        end)
    end
})
Main:Section({Title = "短信轰炸"})

local spammingAll = false

Main:Toggle({
    Title = "短信轰炸",
    Default = false,
    Callback = function(state)
        spammingAll = state
        
        if state then
            task.spawn(function()
                while spammingAll do
                    local Players = game:GetService("Players")
                    local Remote = game:GetService("ReplicatedStorage").Remotes.Phone
                    
                    for _, player in ipairs(Players:GetPlayers()) do
                        if not spammingAll then break end
                        if player ~= Players.LocalPlayer then
                            Remote:FireServer("SendPrivateMessage", "Atomic ON Top", player)
                            task.wait(0.3) 
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

Main:Toggle({
    Title = "公开短信轰炸",
    Default = false,
    Callback = function(enabled)
        _G.GlobalSpam = enabled
        
        if enabled then
            task.spawn(function()
                while _G.GlobalSpam do
                    local Event = game:GetService("ReplicatedStorage").Remotes.Phone
                    Event:FireServer("SendMessage", "Atomic ON Top")
                    
                    task.wait(0.1) 
                end
            end)
        end
    end
})
local PlayerTab = Window:Tab({ Title = "玩家功能", Icon = "user" })

PlayerTab:Section({Title = "玩家功能"})

PlayerTab:Toggle({
    Title = "无限体力",
    Default = false,
    Callback = function(enabled)
        if not enabled then
            _G.InfiniteStaminaEnabled = false
            return
        end
        
        _G.InfiniteStaminaEnabled = true
        local lp = game:GetService("Players").LocalPlayer
        
        while _G.InfiniteStaminaEnabled and task.wait(0.1) do
            if lp.Data and lp.Data.Stamina then
                lp.Data.Stamina.Value = 9e9
            end
        end
    end
})

PlayerTab:Toggle({
    Title = "防安全区",
    Default = false,
    Callback = function(enabled)
        if not enabled then
            _G.AntiSafeZoneEnabled = false
            return
        end
        
        _G.AntiSafeZoneEnabled = true
        local Event = game:GetService("ReplicatedStorage").Remotes.ZoneRemote
        
        while _G.AntiSafeZoneEnabled and task.wait(0.1) do
            firesignal(Event.OnClientEvent, "SafeEnter", "Car")
        end
    end
})

PlayerTab:Section({Title = "移动增强"})



PlayerTab:Slider({
    Title = "移动速度数值",
    Value = {
        Min = 16,
        Max = 200,
        Default = 16,
    },
    Callback = function(Value)
        _G.WalkSpeedValue = Value
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") and _G.SpeedEnabled then
            char.Humanoid.WalkSpeed = Value
        end
    end
})

PlayerTab:Toggle({
    Title = "加速开关",
    Default = false,
    Callback = function(enabled)
        _G.SpeedEnabled = enabled
        
        if not enabled then
            local char = game.Players.LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = 16
            end
            return
        end
        
        task.spawn(function()
            while _G.SpeedEnabled do
                local char = game.Players.LocalPlayer.Character
                local hum = char and char:FindFirstChild("Humanoid")
                if hum then
                    if hum.WalkSpeed ~= _G.WalkSpeedValue then
                        hum.WalkSpeed = _G.WalkSpeedValue
                    end
                end
                task.wait(0.1)
            end
        end)
    end
})





local RemoteBuyTab = Window:Tab({ Title = "远程购买", Icon = "package" })

RemoteBuyTab:Section({Title = "远程购买子弹"})

_G.SelectedAmmo = "手枪子弹"

RemoteBuyTab:Dropdown({
    Title = "选择子弹类型",
    Values = { "手枪子弹", "步枪子弹", "冲锋枪子弹", "霰弹枪子弹" },
    Value = "手枪子弹",
    Callback = function(option)
        _G.SelectedAmmo = option
    end
})

RemoteBuyTab:Button({
    Title = "购买子弹",
    Callback = function()
        local Event = game:GetService("ReplicatedStorage").Remotes.GunBuy
        if _G.SelectedAmmo == "手枪子弹" then
            Event:FireServer("Pistol Ammo", 50)
        elseif _G.SelectedAmmo == "步枪子弹" then
            Event:FireServer("Rifle Ammo", 100)
        elseif _G.SelectedAmmo == "冲锋枪子弹" then
            Event:FireServer("SMG Ammo", 100)
        elseif _G.SelectedAmmo == "霰弹枪子弹" then
            Event:FireServer("Shotgun Ammo", 100)
        end
    end
})

RemoteBuyTab:Section({Title = "远程购买枪械"})

_G.SelectedGun = "AK-12"

RemoteBuyTab:Dropdown({
    Title = "选择枪械",
    Values = { 
        "AK-12", "AK-47", "AKS-74U", "AR手枪", "AUG", 
        "双管G17", "德拉科", "法玛斯", "G36C", "格洛克17", 
        "格洛克19X", "格洛克切换", "蜜獾", "M&P9", 
        "MP5", "Mac", "马卡洛夫", "微型乌兹", "军用防弹衣", 
        "佩伦", "鲁格", "霰弹枪", "SPAS", "TSR-15", 
        "Tec-9", "汤普森", "UMP", "维克多" 
    },
    Value = "AK-12",
    Callback = function(option)
        _G.SelectedGun = option
    end
})

RemoteBuyTab:Button({
    Title = "购买枪械",
    Callback = function()
        local Event = game:GetService("ReplicatedStorage").Remotes.GunBuy
        if _G.SelectedGun == "AK-12" then
            Event:FireServer("AK-12", 5000)
        elseif _G.SelectedGun == "AK-47" then
            Event:FireServer("AK-47", 6500)
        elseif _G.SelectedGun == "AKS-74U" then
            Event:FireServer("AKS-74U", 8500)
        elseif _G.SelectedGun == "AR手枪" then
            Event:FireServer("ARPistol", 5000)
        elseif _G.SelectedGun == "AUG" then
            Event:FireServer("AUG", 5000)
        elseif _G.SelectedGun == "双管G17" then
            Event:FireServer("BinaryG17", 7000)
        elseif _G.SelectedGun == "德拉科" then
            Event:FireServer("Draco", 5200)
        elseif _G.SelectedGun == "法玛斯" then
            Event:FireServer("Famas", 8000)
        elseif _G.SelectedGun == "G36C" then
            Event:FireServer("G36C", 4000)
        elseif _G.SelectedGun == "格洛克17" then
            Event:FireServer("Glock17", 1200)
        elseif _G.SelectedGun == "格洛克19X" then
            Event:FireServer("Glock19X", 5000)
        elseif _G.SelectedGun == "格洛克切换" then
            Event:FireServer("GlockSwitch", 5400)
        elseif _G.SelectedGun == "蜜獾" then
            Event:FireServer("HoneyBadger", 5500)
        elseif _G.SelectedGun == "M&P9" then
            Event:FireServer("M&P9", 2500)
        elseif _G.SelectedGun == "MP5" then
            Event:FireServer("MP5", 7500)
        elseif _G.SelectedGun == "Mac" then
            Event:FireServer("Mac", 3000)
        elseif _G.SelectedGun == "马卡洛夫" then
            Event:FireServer("Makarov", 1000)
        elseif _G.SelectedGun == "微型乌兹" then
            Event:FireServer("Micro Uzi", 7500)
        elseif _G.SelectedGun == "军用防弹衣" then
            Event:FireServer("Military Vest", 3000)
        elseif _G.SelectedGun == "佩伦" then
            Event:FireServer("Perun", 5000)
        elseif _G.SelectedGun == "鲁格" then
            Event:FireServer("Ruger", 800)
        elseif _G.SelectedGun == "霰弹枪" then
            Event:FireServer("Shotgun", 5000)
        elseif _G.SelectedGun == "SPAS" then
            Event:FireServer("Spas", 4500)
        elseif _G.SelectedGun == "TSR-15" then
            Event:FireServer("TSR-15", 8000)
        elseif _G.SelectedGun == "Tec-9" then
            Event:FireServer("Tec-9", 3500)
        elseif _G.SelectedGun == "汤普森" then
            Event:FireServer("Thompson", 4000)
        elseif _G.SelectedGun == "UMP" then
            Event:FireServer("UMP", 4800)
        elseif _G.SelectedGun == "维克多" then
            Event:FireServer("Vector", 7000)
        end
    end
})

