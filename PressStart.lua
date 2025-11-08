local GuiService = game:GetService('GuiService');
local VirtualInputManager = game:GetService('VirtualInputManager');
local bt = game:GetService("Players").LocalPlayer.PlayerGui.bossInterface.TextButton

getgenv().firesignal = function(button)
    if not button then return end;
    GuiService.SelectedObject = button;

    VirtualInputManager:SendKeyEvent(true, 'Return', false, game)
    task.wait(.1);
    VirtualInputManager:SendKeyEvent(false, 'Return', false, game)

    task.wait(.5)
    GuiService.SelectedObject = nil;
end;

firesignal(bt)
