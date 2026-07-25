local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Controller = {}

local AntiFlingConnection = nil
local OriginalCollision = setmetatable({}, {
    __mode = "k",
})

function Controller:Enable()
    if AntiFlingConnection then
        return
    end

    AntiFlingConnection = RunService.Stepped:Connect(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, object in ipairs(player.Character:GetDescendants()) do
                    if object:IsA("BasePart") then
                        if OriginalCollision[object] == nil then
                            OriginalCollision[object] = object.CanCollide
                        end

                        object.CanCollide = false
                    end
                end
            end
        end
    end)
end

function Controller:Disable()
    if AntiFlingConnection then
        AntiFlingConnection:Disconnect()
        AntiFlingConnection = nil
    end

    for part, originalCanCollide in pairs(OriginalCollision) do
        if part and part.Parent then
            part.CanCollide = originalCanCollide
        end

        OriginalCollision[part] = nil
    end
end

function Controller:SetEnabled(enabled)
    if enabled then
        self:Enable()
    else
        self:Disable()
    end
end

function Controller:IsEnabled()
    return AntiFlingConnection ~= nil
end

return Controller
