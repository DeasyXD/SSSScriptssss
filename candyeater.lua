wait(5)

local placeID = game.PlaceId

-- //================================================
-- // -----------------------  BossPortal Finder
-- //================================================
-- if placeID == 121116694547285 then
--     local portal = workspace:FindFirstChild("BossPortal")
--     local prox = portal 
--         and portal:FindFirstChild("TeleportProximity") 
--         and portal.TeleportProximity:FindFirstChild("BossProximityPrompt")
--     if prox then
--         fireproximityprompt(prox)
-- 	else
-- 		fireproximityprompt(workspace.Containers.ShopContainer.Ticket.ProximityPrompt)
-- 		task.wait(2)
-- 		game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Remotes"):WaitForChild("InventoryRemotes"):WaitForChild("UseItem"):FireServer("Ticket")
-- 	end
-- 	return
-- end

--//================================================
--// -----------------------  ALL MAIN FUNCTIONS 
--//================================================

if placeID == 127886236032517 then
	--//========================
	--// Variables
	--//========================

	-- local inp = loadstring(game:HttpGet('https://pastebin.com/raw/dYzQv3d8'))()
	local player = game.Players.LocalPlayer
	local char = player.Character or player.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid")
	local hrp = char:WaitForChild("HumanoidRootPart")
	local workspace = game:GetService("Workspace")

	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local PlayerModule = require(player.PlayerScripts:WaitForChild("PlayerModule"))
	local Controls = PlayerModule:GetControls()

	--//========================
	--// SETUPs
	--//========================
	-- Time buying
	local pausedOnce = false
	local timebuy = math.random(50,70)
	-- Candy setup
	local candyContainer = workspace:WaitForChild("CandyContainer")
	local targetColor = Color3.fromRGB(255, 155, 33)
	local candyCount = 0
	local lastCandy = nil
	local tp_candy = true
	-- ChargeEffect setup
	local delayTime = 2.05
	-- Safe positions
	local safePositions = {
		Vector3.new(17, 145, 362),
		Vector3.new(-21, 145, 357)
	}
	-- Auto-walk
	local Aw = false
	local walkingRight = true
	local moveConn
	-- ULT Detector
	local founded = false

	--//========================
	--// Candy Finder Function
	--//========================
	
	local function findCandyWithColor()
		for _, candy in pairs(candyContainer:GetChildren()) do
			local light = candy:FindFirstChildOfClass("PointLight")
			if light and light.Color == targetColor then
				return candy
			end
		end
		return nil
	end

	--//========================
	--// Teleport Function
	--//========================

	local function teleportToCandy()
		local candy = findCandyWithColor()
		if candy and candy ~= lastCandy then
			lastCandy = candy
			candyCount += 1
			print("Candy collected:", candyCount)

			hrp.CFrame = candy.CFrame + Vector3.new(0, 3, 0)
		-- else
		-- 	if not candy then
		-- 		warn("No candy with the target color found.")
		-- 	end
		end
	end

	--//========================
	--// Teleport Candy Keybind (T)
	--//========================s

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.T then
			tp_candy = not tp_candy
			print(tp_candy and "Teleport ON" or "Teleport OFF")
		end
	end)

	--//========================
	--// ULT DETECTOR
	--//========================

	RunService.Heartbeat:Connect(function()
		local part = workspace:FindFirstChild("ChargeEffect")
		if part then
			founded = true
			print("FOUND IT")
			if founded then
				task.wait(delayTime)
				print("DOGED ! ")
				game:GetService("ReplicatedStorage"):WaitForChild("RollEvent"):FireServer()
			end
		end
	end)

	--//========================
	--// Floating Script
	--//========================


	local pad = Instance.new("Part")
	pad.Name = "FloatPad"
	pad.Anchored = true
	pad.CanCollide = true
	pad.Transparency = 0.5
	pad.Size = Vector3.new(3, 0.2, 3)
	pad.Parent = workspace

	RunService.Heartbeat:Connect(function()
		if hrp and pad then
			pad.CFrame = hrp.CFrame * CFrame.new(0, -3.1, 0)
		end
	end)

	--//========================
	--// Main Run Loop
	--//========================

	RunService.Heartbeat:Connect(function()
		if tp_candy and humanoid.Health >= 50 then
			task.spawn(function()
				teleportToCandy()
				task.wait(1.2)
				local randomPos = safePositions[math.random(1, #safePositions)]
				hrp.CFrame = CFrame.new(randomPos)
			end)
		end


		if candyCount == 110 and not pausedOnce then
			pausedOnce = true
			print("Turning OFF Auto Teleport.. ⌛")

			tp_candy = false
			task.wait(2)
			hrp.CFrame = CFrame.new(Vector3.new(17, 149, 362))

			if not Aw then
				Aw = true
				Controls:Disable()
				print("Auto-Walk ON (temporary) // Controlling disabled.. ❌")
				local basePos = hrp.Position
				local rightPos = basePos + (hrp.CFrame.RightVector * 15)
				local leftPos = basePos + (hrp.CFrame.RightVector * -15)
				humanoid:MoveTo(rightPos)
				moveConn = humanoid.MoveToFinished:Connect(function()
					if not Aw then return end
					if walkingRight then
						humanoid:MoveTo(leftPos)
					else
						humanoid:MoveTo(rightPos)
					end
					walkingRight = not walkingRight
				end)
			end

			task.delay(timebuy, function() -- set time
				print("Turning ON Auto Teleport.. 🟩 // Controlling enabled.. ✅")

				if moveConn then
					moveConn:Disconnect()
					moveConn = nil
				end
				Aw = false
				Controls:Enable()
				humanoid:Move(Vector3.new(0, 0, 0), true)
				
				tp_candy = true
				pausedOnce = false
			end)
		end
		if workspace.HalloweenBoss.BossDecos.TorsoDeco.Transparency == 1 then
			task.wait(2)
			humanoid.Health = 0
		end
	end)
end
