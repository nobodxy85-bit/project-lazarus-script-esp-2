-- ESP ROJO para zombies (limitado) + ESP AZUL para Mystery Box + alerta + PATH CONTINUO
-- Creador = Nobodxy85-bit

-- ===== SERVICIOS =====
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local player = Players.LocalPlayer

-- ===== CONFIG =====
local ALERT_DISTANCE = 20
local ZOMBIE_ESP_DISTANCE = 120
local enabled = false
local espObjects = {}
local firstTime = true

-- PATH
local pathParts = {}
local currentBox = nil
local lastPathUpdate = 0
local PATH_UPDATE_DELAY = 0.6

-- ===== GUI TEXTO =====
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

-- ===== MENSAJE INICIAL =====
local StartText = Instance.new("TextLabel")
StartText.Size = UDim2.new(0, 520, 0, 50)
StartText.Position = UDim2.new(0.5, -260, 0.18, 0)
StartText.BackgroundTransparency = 0.7
StartText.Text = 'Push "T" to enable HACKS'
StartText.TextColor3 = Color3.fromRGB(0, 0, 0)
StartText.Font = Enum.Font.GothamBold
StartText.TextSize = 20
StartText.Visible = true
StartText.Parent = ScreenGui

-- ===== ESP ZOMBIES =====
local function createZombieESP(model)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
	if not root then return end

	local dist = (hrp.Position - root.Position).Magnitude
	if dist > ZOMBIE_ESP_DISTANCE then return end

	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") and not part:FindFirstChild("ESP_Box") then
			local box = Instance.new("BoxHandleAdornment")
			box.Name = "ESP_Box"
			box.Adornee = part
			box.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
			box.AlwaysOnTop = true
			box.ZIndex = 5
			box.Transparency = 0.6
			box.Color3 = Color3.fromRGB(255, 0, 0)
			box.Parent = part
			table.insert(espObjects, box)
		end
	end
end

-- ===== ESP MYSTERY BOX =====
local function createBoxESP(model)
	currentBox = model -- 🔹 necesario para el path

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and not part:FindFirstChild("ESP_Box") then
			local box = Instance.new("BoxHandleAdornment")
			box.Name = "ESP_Box"
			box.Adornee = part
			box.Size = part.Size + Vector3.new(0.2, 0.2, 0.2)
			box.AlwaysOnTop = true
			box.ZIndex = 10
			box.Transparency = 0.5
			box.Color3 = Color3.fromRGB(0, 200, 255)
			box.Parent = part
			table.insert(espObjects, box)
		end
	end
end

-- ===== LIMPIAR ESP =====
local function removeESP()
	for _, obj in ipairs(espObjects) do
		if obj and obj.Parent then
			obj:Destroy()
		end
	end
	table.clear(espObjects)
end

-- ===== LIMPIAR PATH =====
local function clearPath()
	for _, p in ipairs(pathParts) do
		if p then p:Destroy() end
	end
	table.clear(pathParts)
end

-- ===== PATH CONTINUO A LA CAJA =====
local function drawPathToBox()
	if not currentBox then return end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local target = currentBox:FindFirstChildWhichIsA("BasePart", true)
	if not target then return end

	clearPath()

	local path = PathfindingService:CreatePath()
	path:ComputeAsync(hrp.Position, target.Position)
	if path.Status ~= Enum.PathStatus.Success then return end

	local waypoints = path:GetWaypoints()
	for i = 1, #waypoints - 1 do
		local a = waypoints[i].Position
		local b = waypoints[i + 1].Position
		local dist = (a - b).Magnitude

		local beam = Instance.new("Part")
		beam.Anchored = true
		beam.CanCollide = false
		beam.Material = Enum.Material.Neon
		beam.Color = Color3.fromRGB(0, 200, 255)
		beam.Size = Vector3.new(0.25, 0.25, dist)
		beam.CFrame = CFrame.new(a, b) * CFrame.new(0, 0, -dist / 2)
		beam.Parent = workspace

		table.insert(pathParts, beam)
	end
end

-- ===== ACTIVAR TODO =====
local function enableAllESP()
	local baddies = workspace:FindFirstChild("Baddies")
	if baddies then
		for _, zomb in ipairs(baddies:GetChildren()) do
			createZombieESP(zomb)
		end
	end

	local interact = workspace:FindFirstChild("Interact")
	if interact then
		for _, obj in ipairs(interact:GetChildren()) do
			if obj.Name == "MysteryBox" then
				createBoxESP(obj)
			end
		end
	end
end

-- ===== NUEVOS ZOMBIES =====
local baddies = workspace:FindFirstChild("Baddies")
if baddies then
	baddies.ChildAdded:Connect(function(zomb)
		task.wait(0.4)
		if enabled then
			createZombieESP(zomb)
		end
	end)
end

-- ===== NUEVAS CAJAS =====
local interact = workspace:FindFirstChild("Interact")
if interact then
	interact.ChildAdded:Connect(function(obj)
		task.wait(0.3)
		if enabled and obj.Name == "MysteryBox" then
			createBoxESP(obj)
		end
	end)
end

-- ===== LOOP =====
RunService.RenderStepped:Connect(function()
	if not enabled then
		AlertText.Visible = false
		return
	end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local baddies = workspace:FindFirstChild("Baddies")
	if not hrp or not baddies then return end

	local count = 0

	for _, zomb in ipairs(baddies:GetChildren()) do
		local root = zomb:FindFirstChild("HumanoidRootPart") or zomb:FindFirstChild("Torso")
		if root then
			local dist = (hrp.Position - root.Position).Magnitude
			if dist <= ALERT_DISTANCE then
				count += 1
			end
			if dist > ZOMBIE_ESP_DISTANCE then
				for _, part in ipairs(zomb:GetChildren()) do
					local esp = part:FindFirstChild("ESP_Box")
					if esp then esp:Destroy() end
				end
			end
		end
	end

	if count > 0 then
		AlertText.Text = "⚠ ZOMBIE CERCA (x" .. count .. ")"
		AlertText.Visible = true
	else
		AlertText.Visible = false
	end

	-- PATH
	if currentBox and tick() - lastPathUpdate >= PATH_UPDATE_DELAY then
		lastPathUpdate = tick()
		drawPathToBox()
	end
end)

-- ===== TECLA T =====
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.T then
        enabled = not enabled

        if firstTime then
            StartText.Visible = false
            firstTime = false
        end

        if enabled then
            enableAllESP()
        else
            removeESP()
            AlertText.Visible = false
        end
    end
end)



