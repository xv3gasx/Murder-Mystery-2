local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

if Lighting:GetAttribute("FoxnameAntiLagApplied") then
    return true
end

Lighting:SetAttribute("FoxnameAntiLagApplied", true)

local Terrain = workspace:FindFirstChildWhichIsA("Terrain")

if Terrain then
    Terrain.WaterWaveSize = 0
    Terrain.WaterWaveSpeed = 0
    Terrain.WaterReflectance = 0
    Terrain.WaterTransparency = 1
end

Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
Lighting.FogStart = 9e9

pcall(function()
    settings().Rendering.QualityLevel = 1
end)

local function OptimizeObject(object)
    if object:IsA("BasePart") then
        object.CastShadow = false
        object.Material = Enum.Material.Plastic
        object.Reflectance = 0

        pcall(function()
            object.BackSurface = Enum.SurfaceType.SmoothNoOutlines
            object.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
            object.FrontSurface = Enum.SurfaceType.SmoothNoOutlines
            object.LeftSurface = Enum.SurfaceType.SmoothNoOutlines
            object.RightSurface = Enum.SurfaceType.SmoothNoOutlines
            object.TopSurface = Enum.SurfaceType.SmoothNoOutlines
        end)
    elseif object:IsA("Decal") then
        object.Transparency = 1
        object.Texture = ""
    elseif object:IsA("ParticleEmitter") or object:IsA("Trail") then
        object.Lifetime = NumberRange.new(0)
    elseif object:IsA("PostEffect") then
        object.Enabled = false
    end
end

for _, object in ipairs(game:GetDescendants()) do
    OptimizeObject(object)
end

workspace.DescendantAdded:Connect(function(object)
    task.defer(function()
        if not object.Parent then
            return
        end

        if object:IsA("ForceField")
            or object:IsA("Sparkles")
            or object:IsA("Smoke")
            or object:IsA("Fire")
            or object:IsA("Beam") then

            RunService.Heartbeat:Wait()

            if object.Parent then
                object:Destroy()
            end

            return
        end

        OptimizeObject(object)
    end)
end)

return true
