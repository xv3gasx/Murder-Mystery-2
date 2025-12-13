-- Scripti çalıştıranı oyundan atar (bakımda)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if LocalPlayer then
    LocalPlayer:Kick("Script şu anda bakımda.")
end