local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Controller = {}
local Enabled = false
local Connections = {}

local OriginalCollision = setmetatable({}, {
    __mode = "k",
})

local function AddConnection(connection)
    Connections[#Connections + 1] = connection
    return connection
end

local function TrackPart(part)
    if not part:IsA("BasePart") then
        return
    end

    if OriginalCollision[part] == nil then
        OriginalCollision[part] = part.CanCollide
    end

    part.CanCollide = false
end

local function TrackCharacter(character)
    for _, object in ipairs(character:GetDescendants()) do
        TrackPart(object)
    end

    AddConnection(character.DescendantAdded:Connect(function(object)
        if Enabled then
            TrackPart(object)
        end
    end))
end

local function TrackPlayer(player)
    if player == LocalPlayer then
        return
    end

    if player.Character then
        TrackCharacter(player.Character)
    end

    AddConnection(player.CharacterAdded:Connect(function(character)
        if Enabled then
            TrackCharacter(character)
        end
    end))
end

local function DisconnectAll()
    for index = #Connections, 1, -1 do
        local connection = Connections[index]
        Connections[index] = nil

        if connection then
            connection:Disconnect()
        end
    end
end

local function RestoreCollision()
    for part, originalCanCollide in pairs(OriginalCollision) do
        if part and part.Parent then
            part.CanCollide = originalCanCollide
        end

        OriginalCollision[part] = nil
    end
end

function Controller:Enable()
    if Enabled then
        return
    end

    Enabled = true

    for _, player in ipairs(Players:GetPlayers()) do
        TrackPlayer(player)
    end

    AddConnection(Players.PlayerAdded:Connect(function(player)
        if Enabled then
            TrackPlayer(player)
        end
    end))

    AddConnection(RunService.Stepped:Connect(function()
        if not Enabled then
            return
        end

        for part in pairs(OriginalCollision) do
            if part and part.Parent then
                part.CanCollide = false
            else
                OriginalCollision[part] = nil
            end
        end
    end))
end

function Controller:Disable()
    if not Enabled then
        return
    end

    Enabled = false
    DisconnectAll()
    RestoreCollision()
end

function Controller:SetEnabled(value)
    if value then
        self:Enable()
    else
        self:Disable()
    end
end

function Controller:IsEnabled()
    return Enabled
end

return Controller
