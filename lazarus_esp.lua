-- ====================================================================
-- ESP ZOMBIES + ESP MYSTERY BOX + PATHFIND + ALERTA
-- ESTO ES UN SCRIPT NO DISEÑADO PARA MOLESTAR SIMPLEMENTE ES EDUCATIVO
-- Creador = Nobodxy
-- ====================================================================

-- ===== SERVICIOS =====
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local player = Players.LocalPlayer

-- ===== CONFIG =====
local ALERT_DISTANCE = 20
local ZOMBIE_ESP_DISTANCE = 120

-- ===== ESTADO =====
local enabled = false
local espObjects = {}
local pathParts = {}
local currentBox = nil

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
local function clearPath()
	for _, p in ipairs(pathParts) do
		if p then p:Destroy() end
	end
	table.clear(pathParts)
end

local function removeESP()
	for _, obj in ipairs(espObjects) do
		if obj and obj.Parent then
			obj:Destroy()
		end
	end
	table.clear(espObjects)
	clearPath()
	currentBox = nil
end

-- ======================================================
-- ESP ZOMBIES (ROJO CON LÍMITE)
-- ======================================================
local function createZombieESP(zomb)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local root = zomb:FindFirstChild("HumanoidRootPart") or zomb:FindFirstChild("Torso")
	if not root then return end

	if (hrp.Position - root.Position).Magnitude > ZOMBIE_ESP_DISTANCE then
		return
	end

	for _, part in ipairs(zomb:GetChildren()) do
		if part:IsA("BasePart") and not part:FindFirstChild("ESP_Box") then
			local box = Instance.new("BoxHandleAdornment")
			box.Name = "ESP_Box"
			box.Adornee = part
			box.Size = part.Size + Vector3.new(0.1,0.1,0.1)
			box.AlwaysOnTop = true
			box.Transparency = 0.6
			box.Color3 = Color3.fromRGB(255,0,0)
			box.Parent = part
			table.insert(espObjects, box)
		end
	end
end

-- ======================================================
-- ESP MYSTERY BOX (AZUL)
-- ======================================================
local function createBoxESP(boxModel)
	for _, part in ipairs(boxModel:GetDescendants()) do
		if part:IsA("BasePart") and not part:FindFirstChild("ESP_Box") then
			local box = Instance.new("BoxHandleAdornment")
			box.Name = "ESP_Box"
			box.Adornee = part
			box.Size = part.Size + Vector3.new(0.2,0.2,0.2)
			box.AlwaysOnTop = true
			box.Transparency = 0.5
			box.Color3 = Color3.fromRGB(0,200,255)
			box.Parent = part
			table.insert(espObjects, box)
		end
	end
end

-- ======================================================
-- PATHFIND A LA CAJA
-- ======================================================
local function drawPathToBox(boxModel)
	clearPath()

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local target = boxModel.PrimaryPart
		or boxModel:FindFirstChildWhichIsA("BasePart", true)
	if not target then return end

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true
	})

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
-- ACTIVAR ESP
-- ======================================================
local function enableAllESP()
	-- Zombies
	local baddies = workspace:FindFirstChild("Baddies")
	if baddies then
		for _, z in ipairs(baddies:GetChildren()) do
			createZombieESP(z)
		end
	end

	-- Mystery Box (ruta que dijiste)
	local interact = workspace:FindFirstChild("Interact")
	if interact then
		for _, obj in ipairs(interact:GetChildren()) do
			if obj.Name == "MysteryBox" then
				currentBox = obj
				createBoxESP(obj)
			end
		end
	end
end

-- ======================================================
-- EVENTOS DINÁMICOS
-- ======================================================
local baddies = workspace:FindFirstChild("Baddies")
if baddies then
	baddies.ChildAdded:Connect(function(z)
		task.wait(0.3)
		if enabled then
			createZombieESP(z)
		end
	end)
end

local interact = workspace:FindFirstChild("Interact")
if interact then
	interact.ChildAdded:Connect(function(obj)
		task.wait(0.2)
		if enabled and obj.Name == "MysteryBox" then
			currentBox = obj
			createBoxESP(obj)
		end
	end)
end

-- ======================================================
-- LOOP PRINCIPAL
-- ======================================================
RunService.RenderStepped:Connect(function()
	if not enabled then
		AlertText.Visible = false
		clearPath()
		return
	end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local baddies = workspace:FindFirstChild("Baddies")
	if not hrp or not baddies then return end

	-- Limpieza ESP lejanos
	for _, z in ipairs(baddies:GetChildren()) do
		local root = z:FindFirstChild("HumanoidRootPart") or z:FindFirstChild("Torso")
		if root and (hrp.Position - root.Position).Magnitude > ZOMBIE_ESP_DISTANCE then
			for _, p in ipairs(z:GetChildren()) do
				local esp = p:FindFirstChild("ESP_Box")
				if esp then esp:Destroy() end
			end
		end
	end

	-- Alerta
	local count = 0
	for _, z in ipairs(baddies:GetChildren()) do
		local root = z:FindFirstChild("HumanoidRootPart") or z:FindFirstChild("Torso")
		if root and (hrp.Position - root.Position).Magnitude <= ALERT_DISTANCE then
			count += 1
		end
	end

	if count > 0 then
		AlertText.Text = "⚠ ZOMBIE CERCA (x"..count..")"
		AlertText.Visible = true
	else
		AlertText.Visible = false
	end

	-- Path a la caja
	if currentBox then
		drawPathToBox(currentBox)
	end
end)

-- ======================================================
-- TECLA T
-- ======================================================
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.T then
		enabled = not enabled
		if enabled then
			enableAllESP()
		else
			removeESP()
			AlertText.Visible = false
		end
	end
end)
