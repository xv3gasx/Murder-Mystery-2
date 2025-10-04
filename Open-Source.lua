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
    Draggable = true
})

local InfoTab = Window:Tab({ Title = "Info", Icon = "info" })
local ESP_Tab = Window:Tab({ Title = "ESP", Icon = "app-window" })
local TP_Tab  = Window:Tab({ Title = "TP", Icon = "zap" })
local Local_Tab = Window:Tab({ Title = "Local Player", Icon = "user" })

local HttpService = game:GetService("HttpService")

InfoTab:Divider()
InfoTab:Section({ 
    Title = "Discord",
    TextXAlignment = "Center",
    TextSize = 17,
})
InfoTab:Divider()

local InviteCode = "2AzTHFhkGd"
local DiscordAPI = "https://discord.com/api/v10/invites/" .. InviteCode .. "?with_counts=true&with_expiration=true"

local function LoadDiscordInfo()
    local success, result = pcall(function()
        return HttpService:JSONDecode(WindUI.Creator.Request({
            Url = DiscordAPI,
            Method = "GET",
            Headers = {
                ["User-Agent"] = "RobloxBot/1.0",
                ["Accept"] = "application/json"
            }
        }).Body)
    end)

    if success and result and result.guild then
        local DiscordInfo = InfoTab:Paragraph({
            Title = result.guild.name,
            Desc = ' <font color="#52525b"></font> Member Count : ' .. tostring(result.approximate_member_count) ..
                '\n <font color="#16a34a"></font> Online Count : ' .. tostring(result.approximate_presence_count),
            Image = "https://cdn.discordapp.com/icons/" .. result.guild.id .. "/" .. result.guild.icon .. ".png?size=1024",
            ImageSize = 42,
        })

        InfoTab:Button({
            Title = "Update Info",
            Callback = function()
                local updated, updatedResult = pcall(function()
                    return HttpService:JSONDecode(WindUI.Creator.Request({
                        Url = DiscordAPI,
                        Method = "GET",
                    }).Body)
                end)

                if updated and updatedResult and updatedResult.guild then
                    DiscordInfo:SetDesc(
                        ' <font color="#52525b">â€¢</font> Member Count : ' .. tostring(updatedResult.approximate_member_count) ..
                        '\n <font color="#16a34a">â€¢</font> Online Count : ' .. tostring(updatedResult.approximate_presence_count)
                    )
                end
            end
        })

        InfoTab:Button({
            Title = "Copy Discord Invite",
            Callback = function()
                setclipboard("https://discord.gg/" .. InviteCode)
            end
        })
    else
        InfoTab:Paragraph({
            Title = "Error fetching Discord Info",
            Desc = HttpService:JSONEncode(result),
            Image = "triangle-alert",
            ImageSize = 26,
            Color = "Red",
        })
    end
end

LoadDiscordInfo()

InfoTab:Divider()
InfoTab:Section({ 
    Title = "Developers",
    TextXAlignment = "Center",
    TextSize = 17,
})
InfoTab:Divider()

local Owner = InfoTab:Paragraph({
    Title = "v3gas",
    Desc = "Owner of the script",
    Image = "https://cdn.discordapp.com/attachments/1333321395291160606/1423986592523092008/new_logo.jpg?ex=68e24e5c&is=68e0fcdc&hm=6aef019e9877c32cf5495931f2e174357982d40b788f8a2efad591cffee2a9b8&",
    ImageSize = 30,
    Thumbnail = "",
    ThumbnailSize = 0,
    Locked = false,
})
local Owner = InfoTab:Paragraph({
    Title = "CÃ¡o Mod",
    Desc = "Helped for script",
    Image = "rbxassetid://113523692909987",
    ImageSize = 30,
    Thumbnail = "",
    ThumbnailSize = 0,
    Locked = false,
})

local Players, RunService, UIS, Camera = game:GetService("Players"), game:GetService("RunService"), game:GetService("UserInputService"), workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

_G.ESPEnabled, _G.GunESPEnabled, _G.InfiniteJumpEnabled, _G.NoclipEnabled = false, false, false, false
_G.WalkSpeedValue = 16

local function safeNewDrawing(class, props)
    local ok, obj = pcall(Drawing.new, class)
    if not ok then return nil end
    for k,v in pairs(props or {}) do pcall(function() obj[k] = v end) end
    return obj
end

local function worldToScreen(pos)
    local ok, sp, onScreen = pcall(Camera.WorldToViewportPoint, Camera, pos)
    return ok and Vector2.new(sp.X, sp.Y), onScreen
end

local ROLE_COLORS = { Murderer=Color3.fromRGB(255,0,0), Sheriff=Color3.fromRGB(0,0,255), Innocent=Color3.fromRGB(0,255,0) }

local function detectRole(p)
    local role = "Innocent"
    local function check(container)
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                if tool.Name=="Knife" then return "Murderer"
                elseif tool.Name=="Gun" then return "Sheriff" end
            end
        end
    end
    if p.Backpack then role = check(p.Backpack) or role end
    if p.Character then role = check(p.Character) or role end
    return role
end

local ESP = {}
local function hideESP(d) 
    if d.Box then d.Box.Visible=false end
    if d.Line then d.Line.Visible=false end
    if d.NameTag then d.NameTag.Visible=false end
    if d.Highlight then d.Highlight.Enabled=false end
end

local function createPlayerESP(p)
    if p == LocalPlayer or ESP[p] then return end
    local data = {
        Line=safeNewDrawing("Line",{Thickness=3,Visible=false}),
        Box=safeNewDrawing("Square",{Thickness=1,Filled=false,Visible=false}),
        NameTag=safeNewDrawing("Text",{Size=16,Center=true,Outline=true,Visible=false,Text=p.Name}),
        Highlight=Instance.new("Highlight")
    }
    data.Highlight.Name, data.Highlight.FillTransparency, data.Highlight.OutlineTransparency = "ESP_Highlight", 0, 0.5
    data.Highlight.DepthMode, data.Highlight.Enabled = Enum.HighlightDepthMode.AlwaysOnTop, false
    ESP[p] = data

    p.CharacterAdded:Connect(function(c) data.Highlight.Parent, data.Highlight.Adornee = c,c end)
    if p.Character then data.Highlight.Parent, data.Highlight.Adornee = p.Character,p.Character end
end

local function destroyPlayerESP(p)
    local d = ESP[p] if not d then return end
    for _,obj in pairs(d) do if typeof(obj)=="Instance" then obj:Destroy() else obj:Remove() end end
    ESP[p] = nil
end

Players.PlayerAdded:Connect(createPlayerESP)
Players.PlayerRemoving:Connect(destroyPlayerESP)
for _,p in ipairs(Players:GetPlayers()) do createPlayerESP(p) end

local gunLine, gunBox = safeNewDrawing("Line",{Thickness=3,Visible=false}), safeNewDrawing("Square",{Thickness=1,Filled=false,Visible=false})
local currentGun=nil

task.spawn(function()
    while true do
        currentGun=nil
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name=="GunDrop" then currentGun=obj break end
        end
        task.wait(0.25)
    end
end)

local function teleportToGun()
    local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and currentGun then hrp.CFrame=currentGun.CFrame+Vector3.new(0,3,0) end
end

local function teleportBehind(t)
    if not t or not t.Character then return end
    local hrp=t.Character:FindFirstChild("HumanoidRootPart")
    local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and myHRP then myHRP.CFrame=CFrame.new(hrp.Position-hrp.CFrame.LookVector*8,hrp.Position) end
end

local function findRole(toolName)
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and ((p.Backpack:FindFirstChild(toolName)) or (p.Character and p.Character:FindFirstChild(toolName))) then return p end
    end
end

local function setWalkSpeed()
    local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.WalkSpeed~=_G.WalkSpeedValue then hum.WalkSpeed=_G.WalkSpeedValue end
end
LocalPlayer.CharacterAdded:Connect(function() task.wait(0.5) setWalkSpeed() end)
if LocalPlayer.Character then setWalkSpeed() end

UIS.JumpRequest:Connect(function()
    if _G.InfiniteJumpEnabled then
        local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Stepped:Connect(function()
    if _G.NoclipEnabled then
        for _,part in ipairs(LocalPlayer.Character and LocalPlayer.Character:GetDescendants() or {}) do
            if part:IsA("BasePart") then part.CanCollide=false end
        end
    end
end)

TP_Tab:Button({Title="Gun TP", Callback=teleportToGun})
TP_Tab:Button({Title="Teleport to Murderer", Callback=function() local m=findRole("Knife") if m then teleportBehind(m) else WindUI:Notify({Title="Error",Content="No murderer",Duration=3,Icon="x"}) end end})
TP_Tab:Button({Title="Teleport to Sheriff", Callback=function() local s=findRole("Gun") if s then teleportBehind(s) else WindUI:Notify({Title="Error",Content="No sheriff",Duration=3,Icon="x"}) end end})

ESP_Tab:Toggle({Title="Player ESP", Default=false, Callback=function(state) _G.ESPEnabled=state end})
ESP_Tab:Toggle({Title="Gun ESP", Default=false, Callback=function(state) _G.GunESPEnabled=state end})

Local_Tab:Slider({Title="WalkSpeed", Step=1, Value={Min=16,Max=100,Default=16}, Callback=function(val) _G.WalkSpeedValue=val setWalkSpeed() end})
Local_Tab:Toggle({Title="Infinite Jump", Default=false, Callback=function(s) _G.InfiniteJumpEnabled=s end})
Local_Tab:Toggle({Title="Noclip", Default=false, Callback=function(s) _G.NoclipEnabled=s end})

RunService.RenderStepped:Connect(function()
    for p,d in pairs(ESP) do
        local char,role = p.Character, detectRole(p)
        local hrp,hum,head = char and char:FindFirstChild("HumanoidRootPart"), char and char:FindFirstChildOfClass("Humanoid"), char and char:FindFirstChild("Head")
        if not (_G.ESPEnabled and char and hrp and hum and hum.Health>0) then hideESP(d) else
            d.Highlight.FillColor,d.Highlight.Enabled=ROLE_COLORS[role],true
            if head then
                local top,on1 = worldToScreen(head.Position+Vector3.new(0,0.5,0))
                local bottom,on2 = worldToScreen(hrp.Position-Vector3.new(0,2.5,0))
                if on1 and on2 then
                    local h,w=math.abs(top.Y-bottom.Y),math.abs(top.Y-bottom.Y)/2
                    d.Box.Position,d.Box.Size,d.Box.Color,d.Box.Visible=Vector2.new(top.X-w/2,top.Y),Vector2.new(w,h),ROLE_COLORS[role],true
                    d.NameTag.Position,d.NameTag.Color,d.NameTag.Visible=top-Vector2.new(0,15),(role=="Innocent" and Color3.new(0,0,0) or ROLE_COLORS[role]),role~="Innocent"
                    d.Line.From,d.Line.To,d.Line.Color,d.Line.Visible=Vector2.new(Camera.ViewportSize.X/2,0),top,ROLE_COLORS[role],true
                else hideESP(d) end
            end
        end
    end

    if _G.GunESPEnabled and currentGun then
        local pos,on=Camera:WorldToViewportPoint(currentGun.Position)
        if on then
            gunBox.Position,gunBox.Size,gunBox.Color,gunBox.Visible=Vector2.new(pos.X-12,pos.Y-12),Vector2.new(24,24),Color3.fromRGB(255,255,0),true
            gunLine.From,gunLine.To,gunLine.Color,gunLine.Visible=Vector2.new(Camera.ViewportSize.X/2,0),Vector2.new(pos.X,pos.Y),Color3.fromRGB(255,255,0),true
        else gunBox.Visible,gunLine.Visible=false,false end
    else gunBox.Visible,gunLine.Visible=false,false end
end)
