-- ======================================================
-- ESP ZOMBIES + ESP CAJA + PATHFIND + ALERTA (REDISEÑO)
-- ======================================================

-- ===== SERVICIOS =====
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ===== CONFIG =====
local ALERT_DISTANCE = 20
local ZOMBIE_ESP_DISTANCE = 120
local PATH_UPDATE_DELAY = 0.6
local ESP_UPDATE_DELAY = 0.4

-- ===== ESTADO =====
local enabled = false
local zombieESP = {}   -- [zombie] = {adornments}
local boxESP = {}
local pathParts = {}
local currentBox = nil
local lastPath = 0
local lastESP = 0

-- ======================================================
-- GUI ALERTA
-- ======================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local AlertText = Instance.new("TextLabel")
AlertText.Size = UDim2.new(0, 360, 0, 50)
AlertText.Position = UDim2.new(0.5, -180, 0.12, 0)
AlertText.BackgroundTransparency = 1
AlertText.TextColor3 = Color3.fromRGB(255, 0, 0)
AlertText.Font = Enum.Font.GothamBold
AlertText.TextSize = 30
AlertText.Visible = false
AlertText.Parent = ScreenGui

-- ======================================================
-- UTILIDADES
-- ======================================================
local function clearTable(t)
	for _, v in pairs(t) do
		if typeof(v) == "table" then
			for _, o in ipairs(v) do
				if o then o:Destroy() end
			end
		elseif typeof(v) == "Instance" then
			v:Destroy()
		end
	end
	table.clear(t)
end

local function clearPath()
	clearTable(pathParts)
end

-- ======================================================
-- ESP ZOMBIES (ROJO - LIMPIO)
-- ======================================================
local function removeZombieESP(zombie)
	if zombieESP[zombie] then
		for _, box in ipairs(zombieESP[zombie]) do
			if box then box:Destroy() end
		end
		zombieESP[zombie] = nil
	end
end

local function createZombieESP(zombie)
	if zombieESP[zombie] then return end

	local humanoid = zombie:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local partsESP = {}

	for _, part in ipairs(zombie:GetDescendants()) do
		if part:IsA("BasePart") then
			local box = Instance.new("BoxHandleAdornment")
			box.Adornee = part
			box.Size = part.Size + Vector3.new(0.1,0.1,0.1)
			box.AlwaysOnTop = true
			box.ZIndex = 10
			box.Transparency = 0.5
			box.Color3 = Color3.fromRGB(255,0,0)
			box.Parent = camera
			table.insert(partsESP, box)
		end
	end

	zombieESP[zombie] = partsESP

	-- 🔥 LIMPIEZA AUTOMÁTICA AL MORIR
	humanoid.Died:Once(function()
		removeZombieESP(zombie)
	end)

	zombie.AncestryChanged:Connect(function(_, parent)
		if not parent then
			removeZombieESP(zombie)
		end
	end)
end

-- ======================================================
-- ESP MYSTERY BOX (AZUL)
-- ======================================================
local function clearBoxESP()
	clearTable(boxESP)
	currentBox = nil
	clearPath()
end

local function createBoxESP(boxModel)
	clearBoxESP()
	currentBox = boxModel

	for _, part in ipairs(boxModel:GetDescendants()) do
		if part:IsA("BasePart") then
			local box = Instance.new("BoxHandleAdornment")
			box.Adornee = part
			box.Size = part.Size + Vector3.new(0.2,0.2,0.2)
			box.AlwaysOnTop = true
			box.ZIndex = 12
			box.Transparency = 0.4
			box.Color3 = Color3.fromRGB(0,200,255)
			box.Parent = camera
			table.insert(boxESP, box)
		end
	end

	boxModel.AncestryChanged:Connect(function(_, parent)
		if not parent then
			clearBoxESP()
		end
	end)
end

-- ======================================================
-- PATHFIND A LA CAJA
-- ======================================================
local function drawPath()
	if not currentBox then return end
	clearPath()

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local target = currentBox:FindFirstChildWhichIsA("BasePart", true)
	if not target then return end

	local path = PathfindingService:CreatePath()
	path:ComputeAsync(hrp.Position, target.Position)
	if path.Status ~= Enum.PathStatus.Success then return end

	for _, wp in ipairs(path:GetWaypoints()) do
		local p = Instance.new("Part")
		p.Size = Vector3.new(0.4,0.4,0.4)
		p.Shape = Enum.PartType.Ball
		p.Anchored = true
		p.CanCollide = false
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(0,200,255)
		p.Position = wp.Position + Vector3.new(0,0.2,0)
		p.Parent = workspace
		table.insert(pathParts, p)
	end
end

-- ======================================================
-- LOOP PRINCIPAL (OPTIMIZADO)
-- ======================================================
RunService.Heartbeat:Connect(function()
	if not enabled then return end

	local now = tick()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local baddies = workspace:FindFirstChild("Baddies")
	if not hrp or not baddies then return end

	-- ===== ESP ZOMBIES POR DISTANCIA =====
	if now - lastESP >= ESP_UPDATE_DELAY then
		lastESP = now

		for _, z in ipairs(baddies:GetChildren()) do
			local root = z:FindFirstChild("HumanoidRootPart")
			if root then
				local dist = (hrp.Position - root.Position).Magnitude
				if dist <= ZOMBIE_ESP_DISTANCE then
					createZombieESP(z)
				else
					removeZombieESP(z)
				end
			end
		end
	end

	-- ===== ALERTA =====
	local count = 0
	for _, z in ipairs(baddies:GetChildren()) do
		local root = z:FindFirstChild("HumanoidRootPart")
		if root and (hrp.Position - root.Position).Magnitude <= ALERT_DISTANCE then
			count += 1
		end
	end

	AlertText.Visible = count > 0
	if count > 0 then
		AlertText.Text = "⚠ ZOMBIE CERCA (x"..count..")"
	end

	-- ===== PATH =====
	if currentBox and now - lastPath >= PATH_UPDATE_DELAY then
		lastPath = now
		drawPath()
	end
end)

-- ======================================================
-- TECLAS
-- ======================================================
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end

	if input.KeyCode == Enum.KeyCode.T then
		enabled = not enabled
		if not enabled then
			clearTable(zombieESP)
			clearBoxESP()
			AlertText.Visible = false
		end
	end

	-- PANIC
	if input.KeyCode == Enum.KeyCode.X then
		clearTable(zombieESP)
		clearBoxESP()
		clearPath()
		ScreenGui:Destroy()
		script:Destroy()
	end
end)
