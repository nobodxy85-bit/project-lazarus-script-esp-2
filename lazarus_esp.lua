-- ESP ZOMBIES + ESP MYSTERY BOX + ALERTA
-- Creator = Nobodxy85-bit
-- ===== SERVICIOS =====
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ===== CONFIG =====
local ALERT_DISTANCE = 20
local enabled = false
local firstTime = true
local Camera = workspace.CurrentCamera
local aimbotEnabled = false
local AIM_FOV = 30 -- radio en pixeles (más bajo = más preciso)

-- caches
local espObjects = {}
local cachedZombies = {}
local cachedBoxes = {}

-- connections
local zombieAddedConnection

-- ===== GUI =====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- ALERTA
local AlertText = Instance.new("TextLabel")
AlertText.Size = UDim2.new(0, 360, 0, 50)
AlertText.Position = UDim2.new(0.5, -180, 0.12, 0)
AlertText.BackgroundTransparency = 1
AlertText.TextColor3 = Color3.fromRGB(255, 0, 0)
AlertText.Font = Enum.Font.GothamBold
AlertText.TextSize = 30
AlertText.Visible = false
AlertText.Parent = ScreenGui

-- TEXTO INICIAL (MAS ARRIBA)
local StartText = Instance.new("TextLabel")
StartText.Size = UDim2.new(0, 520, 0, 40)
StartText.Position = UDim2.new(0.5, -260, 0.10, 0)
StartText.BackgroundTransparency = 0.7
StartText.Text = 'Push "T" to enable HACKS'
StartText.TextColor3 = Color3.fromRGB(0, 0, 0)
StartText.Font = Enum.Font.GothamBold
StartText.TextSize = 20
StartText.Parent = ScreenGui

-- TEXTO ENABLED (FADE) - NEGRO FORZADO
local EnabledText = Instance.new("TextLabel")
EnabledText.Size = StartText.Size
EnabledText.Position = StartText.Position
EnabledText.BackgroundTransparency = 0.7
EnabledText.Text = "Creator = Nobodxy85-bit  :D"

EnabledText.TextColor3 = Color3.new(255, 255, 255) -- NEGRO REAL
EnabledText.TextTransparency = 0.9

EnabledText.TextStrokeTransparency = 0.7 
EnabledText.RichText = false

EnabledText.Font = Enum.Font.GothamBold
EnabledText.TextSize = 20
EnabledText.Visible = false
EnabledText.Parent = ScreenGui

-- ===== FUNCION FADE =====
local function fadeOut(label, duration)
	local steps = 30
	for i = 0, steps do
		label.TextTransparency = i / steps
		task.wait(duration / steps)
	end
	label.Visible = false
end

local function getClosestZombieToCursor()
	local baddies = workspace:FindFirstChild("Baddies")
	if not baddies then return end

	local closest, shortest = nil, AIM_FOV
	local mousePos = UserInputService:GetMouseLocation()

	for _, z in ipairs(baddies:GetChildren()) do
		local hrp = z:FindFirstChild("HumanoidRootPart")
		if hrp then
			local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
			if onScreen then
				local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
				if dist < shortest then
					shortest = dist
					closest = hrp
				end
			end
		end
	end

	return closest
end

local function getClosestZombieToCursor()
	local closest = nil
	local shortest = math.huge
	local mousePos = UserInputService:GetMouseLocation()

	local baddies = workspace:FindFirstChild("Baddies")
	if not baddies then return end

	for _, z in ipairs(baddies:GetChildren()) do
		local head = z:FindFirstChild("Head")
		local humanoid = z:FindFirstChildOfClass("Humanoid")

		if head and humanoid and humanoid.Health > 0 then
			local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
			if onScreen then
				local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
				if dist < shortest then
					shortest = dist
					closest = head
				end
			end
		end
	end

	return closest
end

-- ===== ESP =====
local function addBox(part, color, transparency)
	if not part:IsA("BasePart") or part:FindFirstChild("ESP_Box") then return end

	local box = Instance.new("BoxHandleAdornment")
	box.Name = "ESP_Box"
	box.Adornee = part
	box.Size = part.Size + Vector3.new(0.15, 0.15, 0.15)
	box.AlwaysOnTop = true
	box.ZIndex = 10
	box.Transparency = transparency
	box.Color3 = color
	box.Parent = part

	table.insert(espObjects, box)
end

local function createZombieESP(zombie)
	if cachedZombies[zombie] then return end
	cachedZombies[zombie] = true

	for _, part in ipairs(zombie:GetChildren()) do
		addBox(part, Color3.fromRGB(255, 0, 0), 0.6)
	end
end

local function createBoxESP(box)
	if cachedBoxes[box] then return end
	cachedBoxes[box] = true

	for _, part in ipairs(box:GetDescendants()) do
		addBox(part, Color3.fromRGB(0, 200, 255), 0.45)
	end
end

-- ===== LIMPIAR =====
local function clearAll()
	for _, obj in ipairs(espObjects) do
		if obj then obj:Destroy() end
	end

	if zombieAddedConnection then
		zombieAddedConnection:Disconnect()
		zombieAddedConnection = nil
	end

	table.clear(espObjects)
	table.clear(cachedZombies)
	table.clear(cachedBoxes)
end

-- ===== ACTIVAR ESP =====
local function enableESP()
	local baddies = workspace:FindFirstChild("Baddies")
	if not baddies then return end

	-- zombies actuales
	for _, z in ipairs(baddies:GetChildren()) do
		createZombieESP(z)
	end

	-- zombies nuevos
	zombieAddedConnection = baddies.ChildAdded:Connect(function(zombie)
		task.wait(0.1)
		if enabled then
			createZombieESP(zombie)
		end
	end)

	-- mystery box
	local interact = workspace:FindFirstChild("Interact")
	if interact then
		for _, obj in ipairs(interact:GetChildren()) do
			if obj.Name == "MysteryBox" then
				createBoxESP(obj)
			end
		end
	end
end

RunService.RenderStepped:Connect(function()
	-- ===== ALERTA ZOMBIES =====
	if not enabled then
		AlertText.Visible = false
	else
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local baddies = workspace:FindFirstChild("Baddies")

		if hrp and baddies then
			local count = 0

			for _, z in ipairs(baddies:GetChildren()) do
				local root = z:FindFirstChild("HumanoidRootPart")
				local humanoid = z:FindFirstChildOfClass("Humanoid")

				if root and humanoid and humanoid.Health > 0 then
					if (hrp.Position - root.Position).Magnitude <= ALERT_DISTANCE then
						count += 1
					end
				end
			end

			if count > 0 then
				AlertText.Text = "⚠ ZOMBIE CERCA (x" .. count .. ")"
				AlertText.Visible = true
			else
				AlertText.Visible = false
			end
		end
	end

	-- ===== AIMBOT (CABEZA) =====
	if aimbotEnabled then
		local head = getClosestZombieToCursor()
		if head then
			Camera.CFrame = CFrame.new(
				Camera.CFrame.Position,
				head.Position
			)
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end

	-- ===== TECLA T (ESP) =====
	if input.KeyCode == Enum.KeyCode.T then
		enabled = not enabled

		if firstTime then
			StartText.Visible = false
			EnabledText.Visible = true
			EnabledText.TextTransparency = 0

			task.spawn(function()
				task.wait(3)
				fadeOut(EnabledText, 2)
			end)

			firstTime = false
		end

		if enabled then
			enableESP()
		else
			clearAll()
			AlertText.Visible = false
		end
	end

	-- ===== TECLA C (AIMBOT) =====
	if input.KeyCode == Enum.KeyCode.C then
		aimbotEnabled = not aimbotEnabled
	end
end)




