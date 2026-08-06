local StarterGui = game:GetService("StarterGui")

local message = "Foxname Murder Mystery 2 script has been shut down because of Luraph deobfuscation cases. We will be back when we are safe again. For more information: discord.gg/v8ZPq4y2nD"

for _ = 1, 10 do
    local success = pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Foxname Murder Mystery 2",
            Text = message,
            Duration = 30
        })
    end)

    if success then
        break
    end

    task.wait(1)
end
