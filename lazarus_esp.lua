-- ===== GUARDAR CÓDIGO FUENTE PARA PERSISTENCIA =====
getgenv().ESP_ZOMBIES_SOURCE = [==[
-- ESP ZOMBIES + ESP MYSTERY BOX + ALERTA + PERSISTENCIA + SPEED HACK + VIP SYSTEM
-- Creator = Nobodxy85-bit
-- Mejorado con sistema VIP y funciones exclusivas

-- ===== PERSISTENCIA TIPO NAMELESS =====
if not getgenv().ESP_ZOMBIES_CONFIG then
	getgenv().ESP_ZOMBIES_CONFIG = {
		espEnabled = false,
		aimbotEnabled = false,
		speedHackEnabled = false,
		speedValue = 16,
		firstTimeKeyboard = true,
		scriptLoaded = false,
		killCount = 0,
		showKills = false
	}
end

-- ===== VERIFICAR SI YA EXISTE EN ESTE SERVIDOR =====
if _G.ESP_ZOMBIES_LOADED then
	warn("⚠️ ESP Script ya está cargado en este servidor.")
	warn("✅ Usa el botón de engranaje ⚙️ para controlar el ESP")
	return
end
_G.ESP_ZOMBIES_LOADED = true

-- ===== SISTEMA VIP (SOLO FUNCIONA CON M EN PC) =====
local VIP_USER_IDS = {
	10214014023 -- Para obtener tu ID: print(game.Players.LocalPlayer.UserId)
}

-- ===== SERVICIOS =====
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer

-- ===== VERIFICAR SI ES VIP =====
local isVIP = false
for _, id in ipairs(VIP_USER_IDS) do
	if player.UserId == id then
		isVIP = true
		break
	end
end

-- ===== CONFIG =====
local ALERT_DISTANCE = 20
local enabled = getgenv().ESP_ZOMBIES_CONFIG.espEnabled
local aimbotEnabled = getgenv().ESP_ZOMBIES_CONFIG.aimbotEnabled
local speedHackEnabled = getgenv().ESP_ZOMBIES_CONFIG.speedHackEnabled
local speedValue = getgenv().ESP_ZOMBIES_CONFIG.speedValue
local firstTimeKeyboard = getgenv().ESP_ZOMBIES_CONFIG.firstTimeKeyboard
local killCount = getgenv().ESP_ZOMBIES_CONFIG.killCount
local showKills = getgenv().ESP_ZOMBIES_CONFIG.showKills
local Camera = workspace.CurrentCamera
local AIM_FOV = 30
local SMOOTHNESS = 0.15

-- Configuración Speed Hack
local MIN_SPEED = 16
local MAX_SPEED = 200
local SPEED_INCREMENT = 5

-- caches
local espObjects = {}
local cachedZombies = {}
local cachedBoxes = {}

-- connections
local zombieAddedConnection
local renderConnection
local inputConnection
local speedConnection
local killCounterConnection

-- ===== FUNCIÓN DE AUTO-RECARGA =====
local function setupAutoReload()
	local queue =
		queue_on_teleport
		or (syn and syn.queue_on_teleport)
		or (fluxus and fluxus.queue_on_teleport)

	if not queue then
		warn("⚠️ queue_on_teleport no disponible - persistencia desactivada")
		return
	end

	player.OnTeleport:Connect(function(state)
		if state ~= Enum.TeleportState.Started then
			return
		end

		print("🔄 Guardando estado para el próximo servidor...")

		-- Guardar configuración
		getgenv().ESP_ZOMBIES_CONFIG.espEnabled = enabled
		getgenv().ESP_ZOMBIES_CONFIG.aimbotEnabled = aimbotEnabled
		getgenv().ESP_ZOMBIES_CONFIG.speedHackEnabled = speedHackEnabled
		getgenv().ESP_ZOMBIES_CONFIG.speedValue = speedValue
		getgenv().ESP_ZOMBIES_CONFIG.firstTimeKeyboard = firstTimeKeyboard
		getgenv().ESP_ZOMBIES_CONFIG.killCount = killCount
		getgenv().ESP_ZOMBIES_CONFIG.showKills = showKills

		-- Código que se ejecutará EN EL NUEVO SERVER
		local code = [[
			repeat task.wait() until game:IsLoaded()
			task.wait(1)

			-- limpiar flags viejas del server anterior
			_G.ESP_ZOMBIES_LOADED = nil

			if getgenv().ESP_ZOMBIES_SOURCE then
				print("🔄 Recargando ESP persistente...")
				loadstring(getgenv().ESP_ZOMBIES_SOURCE)()
				print("✅ ESP recargado correctamente")
			else
				warn("❌ ESP_ZOMBIES_SOURCE no encontrado")
			end
		]]

		queue(code)
	end)
end

-- ===== GUI =====
local PlayerGui = player:WaitForChild("PlayerGui")
local ScreenGui = PlayerGui:FindFirstChild("ESP_GUI")

-- Si ya existe la GUI, la reutilizamos
if not ScreenGui then
	ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "ESP_GUI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Parent = PlayerGui
	print("🎨 GUI creada por primera vez")
else
	print("🎨 GUI encontrada - reutilizando")
end

-- ===== KILL COUNTER (SOLO PC) =====
local KillCounterLabel = ScreenGui:FindFirstChild("KillCounterLabel")
if not KillCounterLabel then
	KillCounterLabel = Instance.new("TextLabel")
	KillCounterLabel.Name = "KillCounterLabel"
	KillCounterLabel.Size = UDim2.new(0, 200, 0, 60)
	KillCounterLabel.Position = UDim2.new(0.5, -100, 0.02, 0)
	KillCounterLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	KillCounterLabel.BackgroundTransparency = 0.3
	KillCounterLabel.BorderSizePixel = 0
	KillCounterLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	KillCounterLabel.Font = Enum.Font.GothamBold
	KillCounterLabel.TextSize = 28
	KillCounterLabel.Visible = false
	KillCounterLabel.Parent = ScreenGui

	local KillCorner = Instance.new("UICorner")
	KillCorner.CornerRadius = UDim.new(0, 12)
	KillCorner.Parent = KillCounterLabel

	local KillStroke = Instance.new("UIStroke")
	KillStroke.Color = Color3.fromRGB(255, 215, 0)
	KillStroke.Thickness = 3
	KillStroke.Parent = KillCounterLabel
end

-- Actualizar texto del contador
local function updateKillCounter()
	if KillCounterLabel then
		KillCounterLabel.Text = "💀 KILLS: " .. killCount
	end
end

-- ===== VIP MENU (SOLO PC) =====
local VIPMenu = ScreenGui:FindFirstChild("VIPMenu")
if not VIPMenu and isVIP then
	VIPMenu = Instance.new("Frame")
	VIPMenu.Name = "VIPMenu"
	VIPMenu.Size = UDim2.new(0, 250, 0, 200)
	VIPMenu.Position = UDim2.new(0.02, 0, 0.3, 0)
	VIPMenu.BackgroundColor3 = Color3.fromRGB(40, 0, 60)
	VIPMenu.BackgroundTransparency = 0.1
	VIPMenu.BorderSizePixel = 0
	VIPMenu.Visible = false
	VIPMenu.Parent = ScreenGui

	local VIPCorner = Instance.new("UICorner")
	VIPCorner.CornerRadius = UDim.new(0, 15)
	VIPCorner.Parent = VIPMenu

	local VIPStroke = Instance.new("UIStroke")
	VIPStroke.Color = Color3.fromRGB(255, 0, 255)
	VIPStroke.Thickness = 3
	VIPStroke.Parent = VIPMenu

	-- Título VIP
	local VIPTitle = Instance.new("TextLabel")
	VIPTitle.Name = "VIPTitle"
	VIPTitle.Size = UDim2.new(1, 0, 0, 40)
	VIPTitle.Position = UDim2.new(0, 0, 0, 0)
	VIPTitle.BackgroundTransparency = 1
	VIPTitle.Text = "👑 VIP MENU"
	VIPTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	VIPTitle.Font = Enum.Font.GothamBold
	VIPTitle.TextSize = 20
	VIPTitle.Parent = VIPMenu

	-- Botón TP Mystery Box
	local TPMysteryButton = Instance.new("TextButton")
	TPMysteryButton.Name = "TPMysteryButton"
	TPMysteryButton.Size = UDim2.new(0, 220, 0, 40)
	TPMysteryButton.Position = UDim2.new(0.5, -110, 0, 50)
	TPMysteryButton.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
	TPMysteryButton.Text = "📦 TP Mystery Box"
	TPMysteryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	TPMysteryButton.Font = Enum.Font.GothamBold
	TPMysteryButton.TextSize = 16
	TPMysteryButton.Parent = VIPMenu

	local TPMysteryCorner = Instance.new("UICorner")
	TPMysteryCorner.CornerRadius = UDim.new(0, 10)
	TPMysteryCorner.Parent = TPMysteryButton

	-- Botón TP Pack-a-Punch
	local TPPackButton = Instance.new("TextButton")
	TPPackButton.Name = "TPPackButton"
	TPPackButton.Size = UDim2.new(0, 220, 0, 40)
	TPPackButton.Position = UDim2.new(0.5, -110, 0, 100)
	TPPackButton.BackgroundColor3 = Color3.fromRGB(200, 0, 200)
	TPPackButton.Text = "⚡ TP Pack-a-Punch"
	TPPackButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	TPPackButton.Font = Enum.Font.GothamBold
	TPPackButton.TextSize = 16
	TPPackButton.Parent = VIPMenu

	local TPPackCorner = Instance.new("UICorner")
	TPPackCorner.CornerRadius = UDim.new(0, 10)
	TPPackCorner.Parent = TPPackButton

	-- Botón Reset Kills
	local ResetKillsButton = Instance.new("TextButton")
	ResetKillsButton.Name = "ResetKillsButton"
	ResetKillsButton.Size = UDim2.new(0, 220, 0, 40)
	ResetKillsButton.Position = UDim2.new(0.5, -110, 0, 150)
	ResetKillsButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
	ResetKillsButton.Text = "🔄 Reset Kills"
	ResetKillsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	ResetKillsButton.Font = Enum.Font.GothamBold
	ResetKillsButton.TextSize = 16
	ResetKillsButton.Parent = VIPMenu

	local ResetKillsCorner = Instance.new("UICorner")
	ResetKillsCorner.CornerRadius = UDim.new(0, 10)
	ResetKillsCorner.Parent = ResetKillsButton

	-- ===== FUNCIONES VIP =====
	
	-- TP a Mystery Box
	TPMysteryButton.MouseButton1Click:Connect(function()
		local interact = workspace:FindFirstChild("Interact")
		if not interact then
			warn("❌ No se encontró la carpeta Interact")
			return
		end

		local mysteryBox = interact:FindFirstChild("MysteryBox")
		if not mysteryBox then
			warn("❌ No se encontró Mystery Box")
			return
		end

		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then
			warn("❌ No se encontró tu personaje")
			return
		end

		-- Buscar la parte principal del Mystery Box
		local targetPart = mysteryBox:FindFirstChild("Part") or mysteryBox:FindFirstChildWhichIsA("BasePart")
		if targetPart then
			hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 5)
			print("✅ Teleportado a Mystery Box")
		else
			warn("❌ No se encontró la parte del Mystery Box")
		end
	end)

	-- TP a Pack-a-Punch
	TPPackButton.MouseButton1Click:Connect(function()
		local interact = workspace:FindFirstChild("Interact")
		if not interact then
			warn("❌ No se encontró la carpeta Interact")
			return
		end

		local packAPunch = interact:FindFirstChild("Pack-A-Punch")
		if not packAPunch then
			warn("❌ No se encontró Pack-a-Punch")
			return
		end

		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then
			warn("❌ No se encontró tu personaje")
			return
		end

		-- Buscar la parte principal del Pack-a-Punch
		local targetPart = packAPunch:FindFirstChild("Part") or packAPunch:FindFirstChildWhichIsA("BasePart")
		if targetPart then
			hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 5)
			print("✅ Teleportado a Pack-a-Punch")
		else
			warn("❌ No se encontró la parte del Pack-a-Punch")
		end
	end)

	-- Reset Kills
	ResetKillsButton.MouseButton1Click:Connect(function()
		killCount = 0
		getgenv().ESP_ZOMBIES_CONFIG.killCount = 0
		updateKillCounter()
		print("🔄 Contador de kills reseteado")
	end)
end

-- ALERTA
local AlertText = ScreenGui:FindFirstChild("AlertText")
if not AlertText then
	AlertText = Instance.new("TextLabel")
	AlertText.Name = "AlertText"
	AlertText.Size = UDim2.new(0, 360, 0, 50)
	AlertText.Position = UDim2.new(0.5, -180, 0.12, 0)
	AlertText.BackgroundTransparency = 1
	AlertText.TextColor3 = Color3.fromRGB(255, 0, 0)
	AlertText.Font = Enum.Font.GothamBold
	AlertText.TextSize = 30
	AlertText.Visible = false
	AlertText.Parent = ScreenGui
end

-- BOTÓN CIRCULAR
local CircleButton = ScreenGui:FindFirstChild("CircleButton")
if not CircleButton then
	CircleButton = Instance.new("TextButton")
	CircleButton.Name = "CircleButton"
	CircleButton.Size = UDim2.new(0, 80, 0, 80)
	CircleButton.Position = UDim2.new(0.5, -40, 0.10, 0)
	CircleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	CircleButton.BackgroundTransparency = 0.3
	CircleButton.Text = "⚙️"
	CircleButton.TextSize = 35
	CircleButton.Font = Enum.Font.GothamBold
	CircleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	CircleButton.Parent = ScreenGui

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(1, 0)
	UICorner.Parent = CircleButton

	local UIStroke = Instance.new("UIStroke")
	UIStroke.Color = Color3.fromRGB(255, 255, 255)
	UIStroke.Thickness = 3
	UIStroke.Parent = CircleButton
end

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
local MobileMenu = ScreenGui:FindFirstChild("MobileMenu")
if not MobileMenu then
	MobileMenu = Instance.new("Frame")
	MobileMenu.Name = "MobileMenu"
	MobileMenu.Size = UDim2.new(0, 280, 0, 380)
	MobileMenu.Position = UDim2.new(0.5, -140, 0.5, -190)
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
else
	-- Actualizar tamaño del menú existente
	MobileMenu.Size = UDim2.new(0, 280, 0, 380)
	MobileMenu.Position = UDim2.new(0.5, -140, 0.5, -190)
end

-- TÍTULO DEL MENÚ
local MenuTitle = MobileMenu:FindFirstChild("MenuTitle")
if not MenuTitle then
	MenuTitle = Instance.new("TextLabel")
	MenuTitle.Name = "MenuTitle"
	MenuTitle.Size = UDim2.new(1, 0, 0, 40)
	MenuTitle.Position = UDim2.new(0, 0, 0, 0)
	MenuTitle.BackgroundTransparency = 1
	MenuTitle.Text = "MENU DE CONTROL"
	MenuTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	MenuTitle.Font = Enum.Font.GothamBold
	MenuTitle.TextSize = 18
	MenuTitle.Parent = MobileMenu
end

-- BOTÓN ESP
local ESPButton = MobileMenu:FindFirstChild("ESPButton")
if not ESPButton then
	ESPButton = Instance.new("TextButton")
	ESPButton.Name = "ESPButton"
	ESPButton.Size = UDim2.new(0, 240, 0, 50)
	ESPButton.Position = UDim2.new(0.5, -120, 0, 55)
	ESPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	ESPButton.Font = Enum.Font.GothamBold
	ESPButton.TextSize = 20
	ESPButton.Parent = MobileMenu

	local ESPCorner = Instance.new("UICorner")
	ESPCorner.CornerRadius = UDim.new(0, 10)
	ESPCorner.Parent = ESPButton
end

-- Actualizar estado visual del botón ESP
ESPButton.BackgroundColor3 = enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
ESPButton.Text = enabled and "ESP: ON" or "ESP: OFF"

-- BOTÓN AIMBOT
local AimbotButton = MobileMenu:FindFirstChild("AimbotButton")
if not AimbotButton then
	AimbotButton = Instance.new("TextButton")
	AimbotButton.Name = "AimbotButton"
	AimbotButton.Size = UDim2.new(0, 240, 0, 50)
	AimbotButton.Position = UDim2.new(0.5, -120, 0, 115)
	AimbotButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	AimbotButton.Font = Enum.Font.GothamBold
	AimbotButton.TextSize = 20
	AimbotButton.Parent = MobileMenu

	local AimbotCorner = Instance.new("UICorner")
	AimbotCorner.CornerRadius = UDim.new(0, 10)
	AimbotCorner.Parent = AimbotButton
end

-- Actualizar estado visual del botón Aimbot
AimbotButton.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
AimbotButton.Text = aimbotEnabled and "AIMBOT: ON" or "AIMBOT: OFF"

-- ===== SPEED HACK CONTROLS =====

-- BOTÓN SPEED HACK
local SpeedButton = MobileMenu:FindFirstChild("SpeedButton")
if not SpeedButton then
	SpeedButton = Instance.new("TextButton")
	SpeedButton.Name = "SpeedButton"
	SpeedButton.Size = UDim2.new(0, 240, 0, 50)
	SpeedButton.Position = UDim2.new(0.5, -120, 0, 175)
	SpeedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	SpeedButton.Font = Enum.Font.GothamBold
	SpeedButton.TextSize = 20
	SpeedButton.Parent = MobileMenu

	local SpeedCorner = Instance.new("UICorner")
	SpeedCorner.CornerRadius = UDim.new(0, 10)
	SpeedCorner.Parent = SpeedButton
end

-- Actualizar estado visual del botón Speed
SpeedButton.BackgroundColor3 = speedHackEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
SpeedButton.Text = speedHackEnabled and "SPEED: ON" or "SPEED: OFF"

-- LABEL SPEED VALUE
local SpeedLabel = MobileMenu:FindFirstChild("SpeedLabel")
if not SpeedLabel then
	SpeedLabel = Instance.new("TextLabel")
	SpeedLabel.Name = "SpeedLabel"
	SpeedLabel.Size = UDim2.new(0, 240, 0, 25)
	SpeedLabel.Position = UDim2.new(0.5, -120, 0, 235)
	SpeedLabel.BackgroundTransparency = 1
	SpeedLabel.Text = "Velocidad: " .. speedValue
	SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	SpeedLabel.Font = Enum.Font.GothamBold
	SpeedLabel.TextSize = 16
	SpeedLabel.Parent = MobileMenu
end

-- SPEED SLIDER BACKGROUND
local SliderBG = MobileMenu:FindFirstChild("SliderBG")
if not SliderBG then
	SliderBG = Instance.new("Frame")
	SliderBG.Name = "SliderBG"
	SliderBG.Size = UDim2.new(0, 240, 0, 10)
	SliderBG.Position = UDim2.new(0.5, -120, 0, 268)
	SliderBG.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	SliderBG.BorderSizePixel = 0
	SliderBG.Parent = MobileMenu

	local SliderCorner = Instance.new("UICorner")
	SliderCorner.CornerRadius = UDim.new(0, 5)
	SliderCorner.Parent = SliderBG
end

-- SPEED SLIDER FILL
local SliderFill = SliderBG:FindFirstChild("SliderFill")
if not SliderFill then
	SliderFill = Instance.new("Frame")
	SliderFill.Name = "SliderFill"
	SliderFill.Size = UDim2.new((speedValue - MIN_SPEED) / (MAX_SPEED - MIN_SPEED), 0, 1, 0)
	SliderFill.Position = UDim2.new(0, 0, 0, 0)
	SliderFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	SliderFill.BorderSizePixel = 0
	SliderFill.Parent = SliderBG

	local FillCorner = Instance.new("UICorner")
	FillCorner.CornerRadius = UDim.new(0, 5)
	FillCorner.Parent = SliderFill
end

-- SPEED SLIDER BUTTON
local SliderButton = SliderBG:FindFirstChild("SliderButton")
if not SliderButton then
	SliderButton = Instance.new("TextButton")
	SliderButton.Name = "SliderButton"
	SliderButton.Size = UDim2.new(0, 20, 0, 20)
	SliderButton.Position = UDim2.new((speedValue - MIN_SPEED) / (MAX_SPEED - MIN_SPEED), -10, 0.5, -10)
	SliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SliderButton.BorderSizePixel = 0
	SliderButton.Text = ""
	SliderButton.Parent = SliderBG

	local ButtonCorner = Instance.new("UICorner")
	ButtonCorner.CornerRadius = UDim.new(1, 0)
	ButtonCorner.Parent = SliderButton
end

-- Función para actualizar el slider
local function updateSlider(value)
	speedValue = math.clamp(value, MIN_SPEED, MAX_SPEED)
	getgenv().ESP_ZOMBIES_CONFIG.speedValue = speedValue
	
	local percent = (speedValue - MIN_SPEED) / (MAX_SPEED - MIN_SPEED)
	SliderFill.Size = UDim2.new(percent, 0, 1, 0)
	SliderButton.Position = UDim2.new(percent, -10, 0.5, -10)
	SpeedLabel.Text = "Velocidad: " .. math.floor(speedValue)
	
	-- Actualizar velocidad si está activado
	if speedHackEnabled then
		local char = player.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = speedValue
			end
		end
	end
end

-- Hacer el slider arrastrable
local sliderDragging = false

SliderButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliderDragging = true
	end
end)

SliderButton.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliderDragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local mousePos = input.Position.X
		local sliderPos = SliderBG.AbsolutePosition.X
		local sliderSize = SliderBG.AbsoluteSize.X
		
		local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
		local newSpeed = MIN_SPEED + (percent * (MAX_SPEED - MIN_SPEED))
		
		updateSlider(newSpeed)
	end
end)

-- Click en la barra para cambiar velocidad
SliderBG.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local mousePos = input.Position.X
		local sliderPos = SliderBG.AbsolutePosition.X
		local sliderSize = SliderBG.AbsoluteSize.X
		
		local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
		local newSpeed = MIN_SPEED + (percent * (MAX_SPEED - MIN_SPEED))
		
		updateSlider(newSpeed)
	end
end)

-- BOTÓN SERVER HOP
local ServerHopButton = MobileMenu:FindFirstChild("ServerHopButton")
if not ServerHopButton then
	ServerHopButton = Instance.new("TextButton")
	ServerHopButton.Name = "ServerHopButton"
	ServerHopButton.Size = UDim2.new(0, 240, 0, 50)
	ServerHopButton.Position = UDim2.new(0.5, -120, 0, 295)
	ServerHopButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
	ServerHopButton.Text = "🔄 CAMBIAR SERVER"
	ServerHopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	ServerHopButton.Font = Enum.Font.GothamBold
	ServerHopButton.TextSize = 18
	ServerHopButton.Parent = MobileMenu

	local ServerHopCorner = Instance.new("UICorner")
	ServerHopCorner.CornerRadius = UDim.new(0, 10)
	ServerHopCorner.Parent = ServerHopButton
else
	-- Actualizar posición del botón existente
	ServerHopButton.Position = UDim2.new(0.5, -120, 0, 295)
end

-- TEXTO DE BIENVENIDA
local WelcomeText = ScreenGui:FindFirstChild("WelcomeText")
if not WelcomeText then
	WelcomeText = Instance.new("TextLabel")
	WelcomeText.Name = "WelcomeText"
	WelcomeText.Size = UDim2.new(0, 400, 0, 35)
	WelcomeText.Position = UDim2.new(0.5, -200, 0.85, 0)
	WelcomeText.BackgroundTransparency = 0.3
	WelcomeText.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	WelcomeText.Text = isVIP and "Creator = Nobodxy85-bit  :D | 👑 VIP" or "Creator = Nobodxy85-bit  :D"
	WelcomeText.TextColor3 = isVIP and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255)
	WelcomeText.TextTransparency = 0
	WelcomeText.Font = Enum.Font.GothamBold
	WelcomeText.TextSize = 18
	WelcomeText.Visible = true
	WelcomeText.Parent = ScreenGui

	local WelcomeCorner = Instance.new("UICorner")
	WelcomeCorner.CornerRadius = UDim.new(0, 10)
	WelcomeCorner.Parent = WelcomeText

	-- Fade del texto de bienvenida
	task.spawn(function()
		task.wait(3)
		local steps = 30
		for i = 0, steps do
			if WelcomeText then
				WelcomeText.TextTransparency = i / steps
				WelcomeText.BackgroundTransparency = 0.3 + (0.7 * (i / steps))
				task.wait(2 / steps)
			end
		end
		if WelcomeText then
			WelcomeText.Visible = false
		end
	end)
end

-- TEXTO DE ESTADO
local StatusText = ScreenGui:FindFirstChild("StatusText")
if not StatusText then
	StatusText = Instance.new("TextLabel")
	StatusText.Name = "StatusText"
	StatusText.Size = UDim2.new(0, 300, 0, 35)
	StatusText.Position = UDim2.new(0.5, -150, 0.92, 0)
	StatusText.BackgroundTransparency = 0.5
	StatusText.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
	StatusText.Font = Enum.Font.GothamBold
	StatusText.TextSize = 18
	StatusText.Visible = false
	StatusText.Parent = ScreenGui
end

-- ===== FUNCION FADE =====
local function fadeOut(label, duration)
	local steps = 30
	for i = 0, steps do
		if label then
			label.TextTransparency = i / steps
			task.wait(duration / steps)
		end
	end
	if label then
		label.Visible = false
	end
end

-- ===== FUNCION MOSTRAR ESTADO =====
local function showStatus(text, color)
	if not StatusText then return end
	
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
	getgenv().ESP_ZOMBIES_CONFIG.espEnabled = enabled
	getgenv().ESP_ZOMBIES_CONFIG.aimbotEnabled = aimbotEnabled
	getgenv().ESP_ZOMBIES_CONFIG.speedHackEnabled = speedHackEnabled
	getgenv().ESP_ZOMBIES_CONFIG.speedValue = speedValue
	getgenv().ESP_ZOMBIES_CONFIG.firstTimeKeyboard = firstTimeKeyboard
	getgenv().ESP_ZOMBIES_CONFIG.killCount = killCount
	getgenv().ESP_ZOMBIES_CONFIG.showKills = showKills
	
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

-- ===== SPEED HACK FUNCTIONS =====
local function applySpeed()
    local char = player.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").WalkSpeed = speedValue
    end
end

-- Esto fuerza la velocidad en cada frame para que el juego no la baje
if speedConnection then speedConnection:Disconnect() end
speedConnection = RunService.Heartbeat:Connect(function()
    if speedHackEnabled then
        applySpeed()
    end
end)

-- Esto asegura que funcione cuando mueras y reaparezcas
player.CharacterAdded:Connect(function()
    if speedHackEnabled then
        task.wait(1) -- Espera a que el server cargue el personaje
        applySpeed()
    end
end)

local function toggleSpeedHack()
    speedHackEnabled = not speedHackEnabled
    getgenv().ESP_ZOMBIES_CONFIG.speedHackEnabled = speedHackEnabled
    
    if speedHackEnabled then
        applySpeed()
        showStatus("SPEED HACK | ON", Color3.fromRGB(0, 255, 0))
        SpeedButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        SpeedButton.Text = "SPEED: ON"
    else
        local char = player.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
        end
        showStatus("SPEED HACK | OFF", Color3.fromRGB(255, 0, 0))
        SpeedButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        SpeedButton.Text = "SPEED: OFF"
    end
end

local function increaseSpeed()
	if speedValue < MAX_SPEED then
		updateSlider(speedValue + SPEED_INCREMENT)
		showStatus("Velocidad: " .. math.floor(speedValue), Color3.fromRGB(0, 200, 255))
	end
end

local function decreaseSpeed()
	if speedValue > MIN_SPEED then
		updateSlider(speedValue - SPEED_INCREMENT)
		showStatus("Velocidad: " .. math.floor(speedValue), Color3.fromRGB(0, 200, 255))
	end
end

-- ===== KILL COUNTER SYSTEM =====
local function setupKillCounter()
	local baddies = workspace:FindFirstChild("Baddies")
	if not baddies then return end

	-- Monitorear la salud de los zombies
	for _, zombie in ipairs(baddies:GetChildren()) do
		local humanoid = zombie:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				if isVIP and showKills then
					killCount = killCount + 1
					getgenv().ESP_ZOMBIES_CONFIG.killCount = killCount
					updateKillCounter()
				end
			end)
		end
	end

	-- Monitorear nuevos zombies
	baddies.ChildAdded:Connect(function(zombie)
		task.wait(0.1)
		local humanoid = zombie:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				if isVIP and showKills then
					killCount = killCount + 1
					getgenv().ESP_ZOMBIES_CONFIG.killCount = killCount
					updateKillCounter()
				end
			end)
		end
	end)
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
	getgenv().ESP_ZOMBIES_CONFIG.espEnabled = enabled

	if fromKeyboard and firstTimeKeyboard then
		CircleButton.Visible = false
		firstTimeKeyboard = false
		getgenv().ESP_ZOMBIES_CONFIG.firstTimeKeyboard = false
	end

	if enabled then
		enableESP()
		-- Activar kill counter solo para VIP cuando se activa ESP
		if isVIP then
			showKills = true
			getgenv().ESP_ZOMBIES_CONFIG.showKills = true
			KillCounterLabel.Visible = true
			updateKillCounter()
		end
		showStatus("ESP | ENABLE", Color3.fromRGB(0, 255, 0))
		ESPButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		ESPButton.Text = "ESP: ON"
	else
		clearAll()
		AlertText.Visible = false
		-- Desactivar kill counter cuando se desactiva ESP
		if isVIP then
			showKills = false
			getgenv().ESP_ZOMBIES_CONFIG.showKills = false
			KillCounterLabel.Visible = false
		end
		showStatus("ESP | DISABLE", Color3.fromRGB(255, 0, 0))
		ESPButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		ESPButton.Text = "ESP: OFF"
	end
end

-- ===== TOGGLE AIMBOT =====
local function toggleAimbot()
	aimbotEnabled = not aimbotEnabled
	getgenv().ESP_ZOMBIES_CONFIG.aimbotEnabled = aimbotEnabled
	
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
		CircleButton:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(0, 200, 255)
	else
		CircleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		CircleButton:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(255, 255, 255)
	end
end)

ESPButton.MouseButton1Click:Connect(function()
	toggleESP(false)
end)

AimbotButton.MouseButton1Click:Connect(function()
	toggleAimbot()
end)

SpeedButton.MouseButton1Click:Connect(function()
	toggleSpeedHack()
end)

ServerHopButton.MouseButton1Click:Connect(function()
	serverHop()
end)

-- ===== BUCLE PRINCIPAL =====
renderConnection = RunService.RenderStepped:Connect(function()
	-- ===== ALERTA ZOMBIES =====
	if not enabled then
		if AlertText then AlertText.Visible = false end
	else
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local baddies = workspace:FindFirstChild("Baddies")

		if hrp and baddies and AlertText then
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
inputConnection = UserInputService.InputBegan:Connect(function(input, gp)
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
	
	if input.KeyCode == Enum.KeyCode.E then
		toggleSpeedHack()
	end
	
	-- Control de velocidad con + y -
	if input.KeyCode == Enum.KeyCode.Equals or input.KeyCode == Enum.KeyCode.K then
		increaseSpeed()
	end
	
	if input.KeyCode == Enum.KeyCode.L then
		decreaseSpeed()
	end

	-- ===== M PARA VERIFICAR SI ERES VIP =====
	if input.KeyCode == Enum.KeyCode.M then
		if isVIP then
			if VIPMenu then
				VIPMenu.Visible = not VIPMenu.Visible
				if VIPMenu.Visible then
					showStatus("👑 VIP MENU ABIERTO", Color3.fromRGB(255, 215, 0))
				else
					showStatus("👑 VIP MENU CERRADO", Color3.fromRGB(200, 200, 200))
				end
			end
		else
			showStatus("❌ NO ERES VIP | Tu ID: " .. player.UserId, Color3.fromRGB(255, 0, 0))
			print("❌ Tu UserID es: " .. player.UserId)
			print("⚠️ Agrega este ID a VIP_USER_IDS en el script para activar VIP")
		end
	end
end)

-- ===== LIMPIEZA SOLO CUANDO SE CIERRE ROBLOX =====
local function cleanup()
	print("🧹 Limpiando conexiones del ESP...")
	if renderConnection then renderConnection:Disconnect() end
	if inputConnection then inputConnection:Disconnect() end
	if zombieAddedConnection then zombieAddedConnection:Disconnect() end
	if speedConnection then speedConnection:Disconnect() end
	if killCounterConnection then killCounterConnection:Disconnect() end
	clearAll()
end

-- Solo limpiar cuando el jugador se va del juego completamente
Players.PlayerRemoving:Connect(function(plr)
	if plr == player then
		cleanup()
	end
end)

-- ===== ACTIVAR PERSISTENCIA =====
setupAutoReload()

-- ===== SETUP KILL COUNTER =====
setupKillCounter()

-- ===== AUTO REACTIVAR SI ESTABA ENCENDIDO =====
task.spawn(function()
	task.wait(1)
	if getgenv().ESP_ZOMBIES_CONFIG.espEnabled then
		print("🔄 Reactivando ESP automáticamente...")
		enableESP()
		if isVIP then
			showKills = true
			KillCounterLabel.Visible = true
			updateKillCounter()
		end
		showStatus("ESP | AUTO-ACTIVADO", Color3.fromRGB(0, 255, 0))
	end
	
	if getgenv().ESP_ZOMBIES_CONFIG.speedHackEnabled then
		print("🔄 Reactivando Speed Hack automáticamente...")
		toggleSpeedHack()
	end
end)

print("✅ ESP Script con persistencia, Speed Hack y VIP System cargado!")
print("📌 Controles:")
print("   T = Toggle ESP" .. (isVIP and " + Kill Counter 💀" or ""))
print("   C = Toggle Aimbot")
print("   E = Toggle Speed Hack")
print("   K = Aumentar Velocidad")
print("   L = Disminuir Velocidad")
print("   H = Server Hop")
print("   M = Verificar VIP Status")
if isVIP then
	print("   📦 TP Mystery Box (👑 VIP MENU)")
	print("   ⚡ TP Pack-a-Punch (👑 VIP MENU)")
	print("   🎯 Tu UserID: " .. player.UserId .. " ✅ VIP ACTIVO")
	print("   💀 Kill Counter se activa automáticamente con ESP")
else
	print("   ⚠️ No eres VIP - Presiona M para ver tu UserID")
end
print("   Botón ⚙️ = Abrir menú")
print("   Botón 🔄 = Cambiar servidor")
print("🔒 La GUI permanecerá visible incluso al morir")
]==]

loadstring(getgenv().ESP_ZOMBIES_SOURCE)()
