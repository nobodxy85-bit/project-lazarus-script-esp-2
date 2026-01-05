getgenv().ESP_ZOMBIES_SOURCE = [==[
-- ESP ZOMBIES + ESP MYSTERY BOX + ALERTA + PERSISTENCIA
-- Creator = Nobodxy85-bit
-- Mejorado con persistencia entre servidores

-- ===== PERSISTENCIA TIPO NAMELESS =====
getgenv().ESP_ZOMBIES_SOURCE = getgenv().ESP_ZOMBIES_SOURCE or [[
--[[ SCRIPT INSERTADO AUTOMÁTICAMENTE ]]
]]  -- NO BORRAR

getgenv().ESP_ZOMBIES_EXECUTED = getgenv().ESP_ZOMBIES_EXECUTED or false

if getgenv().ESP_ZOMBIES_EXECUTED then
	warn("ESP Zombies ya estaba ejecutado (nameless style)")
	return
end
getgenv().ESP_ZOMBIES_EXECUTED = true


-- ===== VERIFICAR SI YA EXISTE =====
if _G.ESP_ZOMBIES_LOADED then
	warn("ESP Script ya está cargado. Usa el botón existente.")
	return
end
_G.ESP_ZOMBIES_LOADED = true
_G.ESP_ZOMBIES_CONFIG.scriptLoaded = true

-- ===== SERVICIOS =====
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer

-- ===== CONFIG =====
local ALERT_DISTANCE = 20
local enabled = _G.ESP_ZOMBIES_CONFIG.espEnabled
local aimbotEnabled = _G.ESP_ZOMBIES_CONFIG.aimbotEnabled
local firstTimeKeyboard = _G.ESP_ZOMBIES_CONFIG.firstTimeKeyboard
local Camera = workspace.CurrentCamera
local AIM_FOV = 30
local SMOOTHNESS = 0.15

-- caches
local espObjects = {}
local cachedZombies = {}
local cachedBoxes = {}

-- connections
local zombieAddedConnection

-- ===== FUNCIÓN DE AUTO-RECARGA =====
local function setupAutoReload()
	if not queue_on_teleport then
		warn("queue_on_teleport no disponible")
		return
	end

	player.OnTeleport:Connect(function(state)
		if state == Enum.TeleportState.Started then
			-- Guardar estados
			_G.ESP_ZOMBIES_CONFIG.espEnabled = enabled
			_G.ESP_ZOMBIES_CONFIG.aimbotEnabled = aimbotEnabled
			_G.ESP_ZOMBIES_CONFIG.firstTimeKeyboard = firstTimeKeyboard

			queue_on_teleport([[
				repeat task.wait() until game:IsLoaded()
				task.wait(1)

				if getgenv().ESP_ZOMBIES_SOURCE then
					loadstring(getgenv().ESP_ZOMBIES_SOURCE)()
				end
			]])
		end
	end)
end

-- ===== GUI =====
local ScreenGui = player:FindFirstChild("PlayerGui"):FindFirstChild("ESP_GUI")

-- Si ya existe la GUI, la reutilizamos
if not ScreenGui then
	ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "ESP_GUI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Parent = player:WaitForChild("PlayerGui")
else
	-- Limpiar elementos antiguos si existen
	ScreenGui:ClearAllChildren()
end

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

-- BOTÓN CIRCULAR
local CircleButton = Instance.new("TextButton")
CircleButton.Size = UDim2.new(0, 80, 0, 80)
CircleButton.Position = UDim2.new(0.5, -40, 0.10, 0)
CircleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
CircleButton.BackgroundTransparency = 0.3
CircleButton.Text = "⚙️"
CircleButton.TextSize = 35
CircleButton.Font = Enum.Font.GothamBold
CircleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CircleButton.Parent = ScreenGui

-- Hacer el botón circular
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = CircleButton

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Thickness = 3
UIStroke.Parent = CircleButton

-- Hacer el botón arrastrable
local dragging = false
local dragInput, dragStart, startPos

CircleButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = CircleButton.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

CircleButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		CircleButton.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

-- MENU MÓVIL
local MobileMenu = Instance.new("Frame")
MobileMenu.Size = UDim2.new(0, 280, 0, 260)
MobileMenu.Position = UDim2.new(0.5, -140, 0.5, -130)
MobileMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MobileMenu.BackgroundTransparency = 0.1
MobileMenu.BorderSizePixel = 0
MobileMenu.Visible = false
MobileMenu.Parent = ScreenGui

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(0, 15)
MenuCorner.Parent = MobileMenu

local MenuStroke = Instance.new("UIStroke")
MenuStroke.Color = Color3.fromRGB(255, 255, 255)
MenuStroke.Thickness = 2
MenuStroke.Parent = MobileMenu

-- TÍTULO DEL MENÚ
local MenuTitle = Instance.new("TextLabel")
MenuTitle.Size = UDim2.new(1, 0, 0, 40)
MenuTitle.Position = UDim2.new(0, 0, 0, 0)
MenuTitle.BackgroundTransparency = 1
MenuTitle.Text = "MENU DE CONTROL"
MenuTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
MenuTitle.Font = Enum.Font.GothamBold
MenuTitle.TextSize = 18
MenuTitle.Parent = MobileMenu

-- BOTÓN ESP
local ESPButton = Instance.new("TextButton")
ESPButton.Size = UDim2.new(0, 240, 0, 50)
ESPButton.Position = UDim2.new(0.5, -120, 0, 55)
ESPButton.BackgroundColor3 = enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
ESPButton.Text = enabled and "ESP: ON" or "ESP: OFF"
ESPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPButton.Font = Enum.Font.GothamBold
ESPButton.TextSize = 20
ESPButton.Parent = MobileMenu

local ESPCorner = Instance.new("UICorner")
ESPCorner.CornerRadius = UDim.new(0, 10)
ESPCorner.Parent = ESPButton

-- BOTÓN AIMBOT
local AimbotButton = Instance.new("TextButton")
AimbotButton.Size = UDim2.new(0, 240, 0, 50)
AimbotButton.Position = UDim2.new(0.5, -120, 0, 115)
AimbotButton.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
AimbotButton.Text = aimbotEnabled and "AIMBOT: ON" or "AIMBOT: OFF"
AimbotButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AimbotButton.Font = Enum.Font.GothamBold
AimbotButton.TextSize = 20
AimbotButton.Parent = MobileMenu

local AimbotCorner = Instance.new("UICorner")
AimbotCorner.CornerRadius = UDim.new(0, 10)
AimbotCorner.Parent = AimbotButton

-- BOTÓN SERVER HOP (NUEVO)
local ServerHopButton = Instance.new("TextButton")
ServerHopButton.Size = UDim2.new(0, 240, 0, 50)
ServerHopButton.Position = UDim2.new(0.5, -120, 0, 175)
ServerHopButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
ServerHopButton.Text = "🔄 CAMBIAR SERVER"
ServerHopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ServerHopButton.Font = Enum.Font.GothamBold
ServerHopButton.TextSize = 18
ServerHopButton.Parent = MobileMenu

local ServerHopCorner = Instance.new("UICorner")
ServerHopCorner.CornerRadius = UDim.new(0, 10)
ServerHopCorner.Parent = ServerHopButton

-- TEXTO DE BIENVENIDA (ABAJO, NO TAPA EL ENGRANAJE)
local WelcomeText = Instance.new("TextLabel")
WelcomeText.Size = UDim2.new(0, 400, 0, 35)
WelcomeText.Position = UDim2.new(0.5, -200, 0.85, 0)
WelcomeText.BackgroundTransparency = 0.3
WelcomeText.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
WelcomeText.Text = "Creator = Nobodxy85-bit  :D"
WelcomeText.TextColor3 = Color3.fromRGB(255, 255, 255)
WelcomeText.TextTransparency = 0
WelcomeText.Font = Enum.Font.GothamBold
WelcomeText.TextSize = 18
WelcomeText.Visible = true
WelcomeText.Parent = ScreenGui

local WelcomeCorner = Instance.new("UICorner")
WelcomeCorner.CornerRadius = UDim.new(0, 10)
WelcomeCorner.Parent = WelcomeText

-- TEXTO DE ESTADO (ABAJO)
local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(0, 300, 0, 35)
StatusText.Position = UDim2.new(0.5, -150, 0.92, 0)
StatusText.BackgroundTransparency = 0.5
StatusText.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusText.Font = Enum.Font.GothamBold
StatusText.TextSize = 18
StatusText.Visible = false
StatusText.Parent = ScreenGui

-- Fade del texto de bienvenida al inicio
task.spawn(function()
	task.wait(3)
	local steps = 30
	for i = 0, steps do
		WelcomeText.TextTransparency = i / steps
		WelcomeText.BackgroundTransparency = 0.3 + (0.7 * (i / steps))
		task.wait(2 / steps)
	end
	WelcomeText.Visible = false
end)

-- ===== FUNCION FADE =====
local function fadeOut(label, duration)
	local steps = 30
	for i = 0, steps do
		label.TextTransparency = i / steps
		task.wait(duration / steps)
	end
	label.Visible = false
end

-- ===== FUNCION MOSTRAR ESTADO =====
local function showStatus(text, color)
	StatusText.Text = text
	StatusText.TextColor3 = color
	StatusText.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	StatusText.Visible = true
	StatusText.TextTransparency = 0
	StatusText.BackgroundTransparency = 0.5
	
	task.spawn(function()
		task.wait(2)
		fadeOut(StatusText, 1)
	end)
end

-- ===== FUNCIÓN SERVER HOP =====
local function serverHop()
	showStatus("🔄 Buscando servidor...", Color3.fromRGB(100, 150, 255))
	
	-- Guardar estado antes de cambiar
	_G.ESP_ZOMBIES_CONFIG.espEnabled = enabled
	_G.ESP_ZOMBIES_CONFIG.aimbotEnabled = aimbotEnabled
	_G.ESP_ZOMBIES_CONFIG.firstTimeKeyboard = firstTimeKeyboard
	
	local success, errorMsg = pcall(function()
		local servers = {}
		local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
		local body = game:GetService("HttpService"):JSONDecode(req)
		
		if body and body.data then
			for i, v in next, body.data do
				if v.id ~= game.JobId and v.playing < v.maxPlayers then
					table.insert(servers, v.id)
				end
			end
		end
		
		if #servers > 0 then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], player)
		else
			showStatus("❌ No hay servidores disponibles", Color3.fromRGB(255, 0, 0))
		end
	end)
	
	if not success then
		showStatus("❌ Error al cambiar servidor", Color3.fromRGB(255, 0, 0))
		warn("Server Hop Error:", errorMsg)
	end
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

-- ===== ESP (SOLO BORDES) =====
local function addOutline(part, color)
	if not part:IsA("BasePart") or part:FindFirstChild("ESP_Highlight") then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.Adornee = part
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.OutlineColor = color
	highlight.Parent = part

	table.insert(espObjects, highlight)
end

local function createZombieESP(zombie)
	if cachedZombies[zombie] then return end
	cachedZombies[zombie] = true

	for _, part in ipairs(zombie:GetChildren()) do
		if part:IsA("BasePart") then
			addOutline(part, Color3.fromRGB(255, 0, 0))
		end
	end
end

local function createBoxESP(box)
	if cachedBoxes[box] then return end
	cachedBoxes[box] = true

	for _, part in ipairs(box:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "Part" then
			addOutline(part, Color3.fromRGB(0, 200, 255))
		end
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

	for _, z in ipairs(baddies:GetChildren()) do
		createZombieESP(z)
	end

	zombieAddedConnection = baddies.ChildAdded:Connect(function(zombie)
		task.wait(0.1)
		if enabled then
			createZombieESP(zombie)
		end
	end)

	local interact = workspace:FindFirstChild("Interact")
	if interact then
		for _, obj in ipairs(interact:GetChildren()) do
			if obj.Name == "MysteryBox" then
				createBoxESP(obj)
			end
		end
	end
end

-- ===== TOGGLE ESP =====
local function toggleESP(fromKeyboard)
	enabled = not enabled
	_G.ESP_ZOMBIES_CONFIG.espEnabled = enabled

	if fromKeyboard and firstTimeKeyboard then
		CircleButton.Visible = false
		firstTimeKeyboard = false
		_G.ESP_ZOMBIES_CONFIG.firstTimeKeyboard = false
	end

	if enabled then
		enableESP()
		showStatus("ESP | ENABLE", Color3.fromRGB(0, 255, 0))
		ESPButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		ESPButton.Text = "ESP: ON"
	else
		clearAll()
		AlertText.Visible = false
		showStatus("ESP | DISABLE", Color3.fromRGB(255, 0, 0))
		ESPButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		ESPButton.Text = "ESP: OFF"
	end
end

-- ===== TOGGLE AIMBOT =====
local function toggleAimbot()
	aimbotEnabled = not aimbotEnabled
	_G.ESP_ZOMBIES_CONFIG.aimbotEnabled = aimbotEnabled
	
	if aimbotEnabled then
		showStatus("AIMBOT | ENABLE", Color3.fromRGB(0, 255, 0))
		AimbotButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		AimbotButton.Text = "AIMBOT: ON"
	else
		showStatus("AIMBOT | DISABLE", Color3.fromRGB(255, 0, 0))
		AimbotButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		AimbotButton.Text = "AIMBOT: OFF"
	end
end

-- ===== EVENTOS BOTONES =====
CircleButton.MouseButton1Click:Connect(function()
	MobileMenu.Visible = not MobileMenu.Visible
	
	if MobileMenu.Visible then
		CircleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		UIStroke.Color = Color3.fromRGB(0, 200, 255)
	else
		CircleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		UIStroke.Color = Color3.fromRGB(255, 255, 255)
	end
end)

ESPButton.MouseButton1Click:Connect(function()
	toggleESP(false)
end)

AimbotButton.MouseButton1Click:Connect(function()
	toggleAimbot()
end)

ServerHopButton.MouseButton1Click:Connect(function()
	serverHop()
end)

-- ===== BUCLE PRINCIPAL =====
local renderConnection = RunService.RenderStepped:Connect(function()
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

	-- ===== AIMBOT CON SUAVIZADO =====
	if aimbotEnabled then
		local head = getClosestZombieToCursor()
		if head then
			local targetCFrame = CFrame.new(Camera.CFrame.Position, head.Position)
			Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, SMOOTHNESS)
		end
	end
end)

-- ===== CONTROLES DE TECLADO (PC) =====
local inputConnection = UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end

	if input.KeyCode == Enum.KeyCode.T then
		toggleESP(true)
	end

	if input.KeyCode == Enum.KeyCode.C then
		toggleAimbot()
	end
	
	if input.KeyCode == Enum.KeyCode.H then
		serverHop()
	end
end)

-- ===== LIMPIEZA AL SALIR DEL JUEGO =====
local function cleanup()
	if renderConnection then renderConnection:Disconnect() end
	if inputConnection then inputConnection:Disconnect() end
	clearAll()
	_G.ESP_ZOMBIES_LOADED = nil
end

game:GetService("CoreGui").DescendantRemoving:Connect(function(obj)
	if obj == ScreenGui then
		cleanup()
	end
end)

-- ===== ACTIVAR PERSISTENCIA =====
setupAutoReload()

-- ===== AUTO REACTIVAR =====
task.spawn(function()
	task.wait(1)
	if _G.ESP_ZOMBIES_CONFIG.espEnabled then
		enableESP()
	end
end)

print("✅ ESP Script con persistencia cargado!")
print("📌 Controles:")
print("   T = Toggle ESP")
print("   C = Toggle Aimbot")
print("   H = Server Hop")
print("   Botón 🔄 = Cambiar servidor")

]==]
