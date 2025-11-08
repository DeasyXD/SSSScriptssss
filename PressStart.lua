local Signals = {"Activated", "MouseButton1Down","MouseButton1Up","MouseButton1Click", "MouseButton2Down", "MouseButton2Click"}
-- local button = game:GetService("Players").LocalPlayer.PlayerGui.bossInterface.TextButton
-- local hb = game:GetService("Players").LocalPlayer.PlayerGui.bossInterface.Hitbox

for _,v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.bossInterface:GetChildren()) do
    if v.Name == "TextButton" then
        for i,sig in pairs(Signals) do
            firesignal(v[sig])
            mouse1click(v)
        end
    end
end
