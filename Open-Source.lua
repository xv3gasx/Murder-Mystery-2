
local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not ok or not WindUI then return warn("WindUI load failed") end

WindUI:Notify({
    Title = "Load Successful",
    Content = "Join Discord For More Scripts/Updates",
    Duration = 3,
    Icon = "swords",
})

local Window = WindUI:CreateWindow({
    Title = "Murder Mystery 2 Script",
    Author = "by: x.v3gas.x",
    Theme = "Dark",
    Size = UDim2.fromOffset(540, 390),
    Folder = "GUI",
    AutoScale = false
})

Window:EditOpenButton({
    Title = "Open Menu",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

local InfoTab = Window:Tab({ Title = "Info", Icon = "info" })
local Main_Tab = Window:Tab({ Title = "Main", Icon = "target" })
local ESP_Tab = Window:Tab({ Title = "ESP", Icon = "app-window" })
local TP_Tab  = Window:Tab({ Title = "TP", Icon = "zap" })
local Local_Tab = Window:Tab({ Title = "Local Player", Icon = "user" })
local HttpService = game:GetService("HttpService")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

_G.ESPEnabled = false
_G.GunESPEnabled = false
_G.WalkSpeedValue = 16
_G.InfiniteJumpEnabled = false
_G.NoclipEnabled = false
_G.KillMurdererEnabled = false
_G.KnifeAuraEnabled = false
_G.KnifeAuraRange   = 500
_G.KnifeAuraDelay   = 0.3

local function safeNewDrawing(class, props)
    local ok, obj = pcall(function() return Drawing and Drawing.new(class) end)
    if not ok or not obj then return nil end
    if props then
        for k,v in pairs(props) do
            pcall(function() obj[k] = v end)
        end
    end
    return obj
end

local function worldToScreen(pos)
    local ok, sp, onScreen = pcall(function() return Camera:WorldToViewportPoint(pos) end)
    if not ok or not sp then return Vector2.new(0,0), false end
    return Vector2.new(sp.X, sp.Y), onScreen
end

local ROLE_COLORS = { Murderer=Color3.fromRGB(255,0,0), Sheriff=Color3.fromRGB(0,0,255), Innocent=Color3.fromRGB(0,255,0) }

local function detectRole(player)
    local role = "Innocent"
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        if backpack:FindFirstChild("Knife") then role = "Murderer"
        elseif backpack:FindFirstChild("Gun") then role = "Sheriff" end
    end
    local char = player.Character
    if char then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                if tool.Name == "Knife" then role = "Murderer"
                elseif tool.Name == "Gun" then role = "Sheriff" end
            end
        end
    end
    return role
end

local ESP = {}
local function createPlayerESP(player)
    if player == LocalPlayer or ESP[player] then return end
    local line = safeNewDrawing("Line",{Thickness=3,Visible=false})
    local box  = safeNewDrawing("Square",{Thickness=1,Filled=false,Visible=false})
    local nameTag = safeNewDrawing("Text",{Size=16,Center=true,Outline=true,Visible=false,Text=player.Name})
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillTransparency = 0
    highlight.OutlineTransparency = 0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    ESP[player] = {Line=line, Box=box, NameTag=nameTag, Highlight=highlight}
    player.CharacterAdded:Connect(function(char)
        if highlight then
            highlight.Parent = char
            highlight.Adornee = char
        end
    end)
    if player.Character then
        if highlight then
            highlight.Parent = player.Character
            highlight.Adornee = player.Character
        end
    end
end

local function destroyPlayerESP(player)
    local data = ESP[player]
    if not data then return end
    if data.Line then pcall(function() data.Line:Remove() end) end
    if data.Box then pcall(function() data.Box:Remove() end) end
    if data.NameTag then pcall(function() data.NameTag:Remove() end) end
    if data.Highlight then pcall(function() data.Highlight:Destroy() end) end
    ESP[player] = nil
end

Players.PlayerAdded:Connect(createPlayerESP)
Players.PlayerRemoving:Connect(destroyPlayerESP)
for _,p in pairs(Players:GetPlayers()) do createPlayerESP(p) end

local gunLine = safeNewDrawing("Line",{Thickness=3,Visible=false})
local gunBox  = safeNewDrawing("Square",{Thickness=1,Filled=false,Visible=false})
local currentGun = nil

task.spawn(function()
    while true do
        currentGun = nil
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name=="GunDrop" then currentGun=obj break end
        end
        task.wait(0.5)
    end
end)

local function teleportToGun()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and currentGun then
        if currentGun:IsA("BasePart") then
            hrp.CFrame = currentGun.CFrame + Vector3.new(0,3,0)
        elseif currentGun.PrimaryPart then
            hrp.CFrame = currentGun.PrimaryPart.CFrame + Vector3.new(0,3,0)
        end
    end
end

local function teleportBehind(target)
    if not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and myHRP then
        myHRP.CFrame = CFrame.new(hrp.Position - hrp.CFrame.LookVector*8, hrp.Position)
    end
end

local function getSheriff()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local bp = p:FindFirstChild("Backpack")
            local hasGun = (bp and bp:FindFirstChild("Gun")) or (p.Character and p.Character:FindFirstChild("Gun"))
            if hasGun then return p end
        end
    end
    return nil
end

local function getMurderer()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local bp = p:FindFirstChild("Backpack")
            local hasKnife = (bp and bp:FindFirstChild("Knife")) or (p.Character and p.Character:FindFirstChild("Knife"))
            if hasKnife then return p end
        end
    end
    return nil
end

local function setWalkSpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.WalkSpeed ~= _G.WalkSpeedValue then hum.WalkSpeed=_G.WalkSpeedValue end
end
LocalPlayer.CharacterAdded:Connect(function() task.wait(0.5) setWalkSpeed() end)
if LocalPlayer.Character then setWalkSpeed() end

UserInputService.JumpRequest:Connect(function()
    if _G.InfiniteJumpEnabled then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Stepped:Connect(function()
    if _G.NoclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide=false end
            end
        end
    end
end)

TP_Tab:Button({Title="Gun TP", Callback=teleportToGun})
TP_Tab:Button({Title="Teleport to Murderer", Callback=function()
    local m=getMurderer()
    if m then teleportBehind(m) else WindUI:Notify({Title="Error",Content="No murderer detected",Duration=3,Icon="x"}) end
end})
TP_Tab:Button({Title="Teleport to Sheriff", Callback=function()
    local s=getSheriff()
    if s then teleportBehind(s) else WindUI:Notify({Title="Error",Content="No sheriff detected",Duration=3,Icon="x"}) end
end})

ESP_Tab:Toggle({Title="Player ESP", Default=false, Callback=function(state) _G.ESPEnabled=state end})
ESP_Tab:Toggle({Title="Gun ESP", Default=false, Callback=function(state) _G.GunESPEnabled=state end})

Local_Tab:Slider({Title="WalkSpeed", Step=1, Value={Min=16,Max=100,Default=16}, Callback=function(val) _G.WalkSpeedValue=val setWalkSpeed() end})
Local_Tab:Toggle({Title="Infinite Jump", Default=false, Callback=function(state) _G.InfiniteJumpEnabled=state end})
Local_Tab:Toggle({Title="Noclip", Default=false, Callback=function(state) _G.NoclipEnabled=state end})

RunService.RenderStepped:Connect(function()
    for player,data in pairs(ESP) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local head = char and char:FindFirstChild("Head")
        if not _G.ESPEnabled or not (char and hrp and hum and hum.Health>0) then
            if data.Box then data.Box.Visible=false end
            if data.Line then data.Line.Visible=false end
            if data.NameTag then data.NameTag.Visible=false end
            if data.Highlight then data.Highlight.Enabled=false end
        else
            local role = detectRole(player)
            if data.Highlight then
                data.Highlight.FillColor = ROLE_COLORS[role] or ROLE_COLORS.Innocent
                data.Highlight.Enabled = true
            end
            if head and hrp then
                local top2D, onTop = worldToScreen(head.Position+Vector3.new(0,0.5,0))
                local bottom2D, onBottom = worldToScreen(hrp.Position-Vector3.new(0,2.5,0))
                if onTop and onBottom then
                    local height = math.abs(top2D.Y-bottom2D.Y)
                    local width = height/2
                    if data.Box then
                        data.Box.Position = Vector2.new(top2D.X-width/2, top2D.Y)
                        data.Box.Size = Vector2.new(width, height)
                        data.Box.Color = ROLE_COLORS[role] or ROLE_COLORS.Innocent
                        data.Box.Visible = true
                    end
                    if data.NameTag then
                        data.NameTag.Position = top2D - Vector2.new(0,15)
                        data.NameTag.Color = (role=="Innocent") and Color3.fromRGB(0,0,0) or (ROLE_COLORS[role] or ROLE_COLORS.Innocent)
                        data.NameTag.Visible = (role~="Innocent")
                    end
                    if data.Line then
                        data.Line.From = Vector2.new(Camera.ViewportSize.X/2,0)
                        data.Line.To = Vector2.new(top2D.X, top2D.Y)
                        data.Line.Color = ROLE_COLORS[role] or ROLE_COLORS.Innocent
                        data.Line.Visible = true
                    end
                else
                    if data.Box then data.Box.Visible=false end
                    if data.NameTag then data.NameTag.Visible=false end
                    if data.Line then data.Line.Visible=false end
                end
            end
        end
    end

    if _G.GunESPEnabled and currentGun then
        local pos3, onScreen = pcall(function() return Camera:WorldToViewportPoint(currentGun.Position) end)
        -- `pcall` above returns ok, Vector3, bool so handle accordingly
        local ok, screenVec, visible = pos3, nil, nil
        if ok then
            screenVec = select(2, Camera:WorldToViewportPoint(currentGun.Position))
            visible = select(3, Camera:WorldToViewportPoint(currentGun.Position))
        end
        
        local vec, vis = Camera:WorldToViewportPoint((currentGun.Position or (currentGun.PrimaryPart and currentGun.PrimaryPart.Position) or Vector3.new()))
        if vis then
            if gunBox then gunBox.Position=Vector2.new(vec.X-12,vec.Y-12); gunBox.Size=Vector2.new(24,24); gunBox.Color=Color3.fromRGB(255,255,0); gunBox.Visible=true end
            if gunLine then gunLine.From=Vector2.new(Camera.ViewportSize.X/2,0); gunLine.To=Vector2.new(vec.X,vec.Y); gunLine.Color=Color3.fromRGB(255,255,0); gunLine.Visible=true end
        else
            if gunBox then gunBox.Visible=false end
            if gunLine then gunLine.Visible=false end
        end
    else
        if gunBox then gunBox.Visible=false end
        if gunLine then gunLine.Visible=false end
    end
end)

Main_Tab:Toggle({
    Title = "Kill Murderer(need a gun)",
    Default = false,
    Callback = function(state)
        _G.KillMurdererEnabled = state

        if state then
            task.spawn(function()
                while _G.KillMurdererEnabled do
                    task.wait(0.1)
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("Gun") then
                        local murderer = getMurderer()
                        if murderer and murderer.Character and murderer.Character:FindFirstChild("Head") then
                            local headPos = murderer.Character.Head.Position
                            local args = {
                                1,
                                Vector3.new(headPos.X, headPos.Y, headPos.Z),
                                "AH2"
                            }

                            local gun = char:FindFirstChild("Gun")
                            if gun and gun:FindFirstChild("KnifeLocal") and gun.KnifeLocal:FindFirstChild("CreateBeam") then
                                local createBeam = gun.KnifeLocal:FindFirstChild("CreateBeam")
                                local rf = createBeam and createBeam:FindFirstChild("RemoteFunction")
                                if rf then
                                    pcall(function()
                                        rf:InvokeServer(unpack(args))
                                    end)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
})

local AimConfig = {
    Murderer = false,
    Sheriff = false,
    FOV = 150
}

local Camera = workspace.CurrentCamera
local LocalPlayer = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.NumSides = 64
fovCircle.Radius = AimConfig.FOV
fovCircle.Filled = false
fovCircle.Color = Color3.fromRGB(255, 50, 50)
fovCircle.Visible = false

RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end)

local function isVisible(targetPart)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist

    local rayResult = workspace:Raycast(origin, direction, rayParams)
    if not rayResult then return true end
    return rayResult.Instance:IsDescendantOf(targetPart.Parent)
end

local function getClosest(roleName)
    local closest, minDist = nil, math.huge
    for _, p in pairs(game:GetService("Players"):GetPlayers()) do
        if p ~= LocalPlayer and detectRole(p) == roleName then
            local char = p.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 and isVisible(hrp) then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if dist < AimConfig.FOV and dist < minDist then
                        minDist = dist
                        closest = hrp
                    end
                end
            end
        end
    end
    return closest
end

Main_Tab:Toggle({
    Title = "Aim at Murderer",
    Default = false,
    Callback = function(state)
        if state and AimConfig.Sheriff then
            WindUI:Notify({
                Title = "Warning",
                Content = "If you enabled Aim at Sheriff, please disable it to avoid bugs",
                Duration = 4,
                Icon = "alert-circle"
            })
        end
        AimConfig.Murderer = state
        if state then AimConfig.Sheriff = false end
        fovCircle.Visible = (AimConfig.Murderer or AimConfig.Sheriff)
    end
})

Main_Tab:Toggle({
    Title = "Aim at Sheriff",
    Default = false,
    Callback = function(state)
        if state and AimConfig.Murderer then
            WindUI:Notify({
                Title = "Warning",
                Content = "If you enabled Aim at Murderer, please disable it to avoid bugs",
                Duration = 4,
                Icon = "alert-circle"
            })
        end
        AimConfig.Sheriff = state
        if state then AimConfig.Murderer = false end
        fovCircle.Visible = (AimConfig.Murderer or AimConfig.Sheriff)
    end
})

RunService.RenderStepped:Connect(function()
    if not (AimConfig.Murderer or AimConfig.Sheriff) then 
        fovCircle.Visible = false 
        return 
    end

    fovCircle.Visible = true
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local target
    if AimConfig.Murderer then
        target = getClosest("Murderer")
    elseif AimConfig.Sheriff then
        target = getClosest("Sheriff")
    end

    if target then
        local newCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        Camera.CFrame = Camera.CFrame:Lerp(newCFrame, 0.22)
        hrp.CFrame = CFrame.new(hrp.Position, target.Position)
    end
end)

-- Knife Aura (Main_Tab içine yapıştır)
do
    -- helper: equip knife if available (returns true if equipped/found)
    local function ensureKnifeEquipped()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return false end
        local tool = (char and char:FindFirstChild("Knife")) or (LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild("Knife"))
        if tool then
            pcall(function() hum:EquipTool(tool) end)
            return true
        end
        return false
    end

    local function smoothMoveToPosition(targetPos, stopDistance)
        stopDistance = stopDistance or 3
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        local maxSteps = 60
        for i = 1, maxSteps do
            if not _G.KnifeAuraEnabled then return false end
            local currentPos = hrp.Position
            local dist = (currentPos - targetPos).Magnitude
            if dist <= stopDistance then return true end
            local lerpAlpha = 0.25 -- smoothness (smaller = smoother/slower)
            local newCFrame = hrp.CFrame:Lerp(CFrame.new(targetPos + Vector3.new(0,1,0)), lerpAlpha)
            pcall(function() hrp.CFrame = newCFrame end)
            task.wait(0.03)
        end
        -- final snap
        pcall(function() hrp.CFrame = CFrame.new(targetPos + Vector3.new(0,1,0)) end)
        return true
    end

    Main_Tab:Toggle({
        Title = "Kill Aura(For Murderers)",
        Default = false,
        Callback = function(state)
            _G.KnifeAuraEnabled = state
            if state then
                task.spawn(function()
                    -- quick check: require knife present at start
                    if not ensureKnifeEquipped() then
                        WindUI:Notify({Title="Kill Aura", Content="Knife not found in Backpack!", Duration=3, Icon="x"})
                        _G.KnifeAuraEnabled = false
                        return
                    end

                    while _G.KnifeAuraEnabled do
                        task.wait(0.05)
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if not hrp then task.wait(0.4) continue end

                        -- gather valid targets within range
                        local targets = {}
                        for _,p in pairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Character then
                                local otherHRP = p.Character:FindFirstChild("HumanoidRootPart")
                                local otherHum = p.Character:FindFirstChildOfClass("Humanoid")
                                if otherHRP and otherHum and otherHum.Health > 0 then
                                    local dist = (hrp.Position - otherHRP.Position).Magnitude
                                    if dist <= (_G.KnifeAuraRange or 500) then
                                        table.insert(targets, {player = p, dist = dist})
                                    end
                                end
                            end
                        end

                        if #targets == 0 then
                            task.wait(0.5)
                            continue
                        end

                        table.sort(targets, function(a,b) return a.dist < b.dist end)

                        for _,t in ipairs(targets) do
                            if not _G.KnifeAuraEnabled then break end
                            local tgt = t.player
                            if not (tgt and tgt.Character) then continue end
                            local tgtHRP = tgt.Character:FindFirstChild("HumanoidRootPart")
                            local tgtHum = tgt.Character:FindFirstChildOfClass("Humanoid")
                            if not (tgtHRP and tgtHum and tgtHum.Health > 0) then continue end

                            -- ensure knife equipped before moving
                            if not ensureKnifeEquipped() then
                                WindUI:Notify({Title="Knife Aura", Content="Knife lost. Stopping.", Duration=3, Icon="x"})
                                _G.KnifeAuraEnabled = false
                                break
                            end

                            -- smooth move close to the target (enter them)
                            smoothMoveToPosition(tgtHRP.Position, 1.5)

                            -- keep inside/near target until they die or timeout
                            local startT = tick()
                            local timeout = 6 -- seconds max per target
                            while _G.KnifeAuraEnabled and tgt.Character and tgt.Character:FindFirstChildOfClass("Humanoid") and tgt.Character:FindFirstChildOfClass("Humanoid").Health > 0 and (tick() - startT) < timeout do
                                pcall(function()
                                    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                    if myHRP and tgtHRP then
                                        -- snap inside target position to ensure hits
                                        myHRP.CFrame = CFrame.new(tgtHRP.Position)
                                    end
                                end)
                                task.wait(0.06)
                            end

                            if not _G.KnifeAuraEnabled then break end
                            task.wait(_G.KnifeAuraDelay or 0.3)
                        end

                        task.wait(0.2)
                    end
                end)
            end
        end
    })
end
