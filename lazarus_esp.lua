-- ESP ZOMBIES OPTIMIZADO + VIP SYSTEM
-- Creator = Nobodxy85-bit
-- Versión sin noclip y sin persistencia

-- ===== VIP SYSTEM =====
local VIP_USER_IDS = {
	10214014023
}

-- ===== SERVICIOS =====
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer

-- ===== VERIFICAR VIP =====
local isVIP = table.find(VIP_USER_IDS, player.UserId) ~= nil

-- ===== CONFIG =====
local config = {
	ALERT_DISTANCE = 20,
	AIM_FOV = 30,
	SMOOTHNESS = 0.15,
	MIN_SPEED = 16,
	MAX_SPEED = 200,
	SPEED_INCREMENT = 5,
	FREEZE_DURATION = 5,
	FREEZE_COOLDOWN = 0
}

local enabled = false
local aimbotEnabled = false
local speedHackEnabled = false
local speedValue = 16
local killCount = 0
local showKills = false
local firstTimeKeyboard = true

-- Zombie Freeze variables
local freezeActive = false
local freezeCooldown = false
local freezeCooldownTime = 0

local Camera = workspace.CurrentCamera

-- ===== CACHES (OPTIMIZACIÓN) =====
local espObjects = {}
local cachedZombies = {}
local cachedBoxes = {}
local connections = {}

-- ===== GUI =====
local PlayerGui = player:WaitForChild("PlayerGui")
local ScreenGui = PlayerGui:FindFirstChild("ESP_GUI") or Instance.new("ScreenGui")
ScreenGui.Name = "ESP_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- ===== KILL COUNTER MEJORADO =====
local KillCounterFrame = ScreenGui:FindFirstChild("KillCounterFrame")
if not KillCounterFrame then
	KillCounterFrame = Instance.new("Frame")
	KillCounterFrame.Name = "KillCounterFrame"
	KillCounterFrame.Size = UDim2.new(0, 200, 0, 60)
	KillCounterFrame.Position = UDim2.new(0.5, -100, 0.015, 0)
	KillCounterFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	KillCounterFrame.BackgroundTransparency = 0.2
	KillCounterFrame.BorderSizePixel = 0
	KillCounterFrame.Visible = false
	KillCounterFrame.Parent = ScreenGui

	local FrameCorner = Instance.new("UICorner")
	FrameCorner.CornerRadius = UDim.new(0, 12)
	FrameCorner.Parent = KillCounterFrame

	local FrameStroke = Instance.new("UIStroke")
	FrameStroke.Color = Color3.fromRGB(255, 215, 0)
	FrameStroke.Thickness = 2
	FrameStroke.Transparency = 0.3
	FrameStroke.Parent = KillCounterFrame

	-- Gradiente
	local Gradient = Instance.new("UIGradient")
	Gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 25)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 15))
	}
	Gradient.Rotation = 90
	Gradient.Parent = KillCounterFrame

	-- Kill Icon
	local KillIcon = Instance.new("TextLabel")
	KillIcon.Name = "KillIcon"
	KillIcon.Size = UDim2.new(0, 35, 0, 35)
	KillIcon.Position = UDim2.new(0, 10, 0.5, -17.5)
	KillIcon.BackgroundTransparency = 1
	KillIcon.Text = "💀"
	KillIcon.TextColor3 = Color3.fromRGB(255, 80, 80)
	KillIcon.Font = Enum.Font.GothamBold
	KillIcon.TextSize = 28
	KillIcon.Parent = KillCounterFrame

	-- Kill Count
	local KillCount = Instance.new("TextLabel")
	KillCount.Name = "KillCount"
	KillCount.Size = UDim2.new(0, 145, 0, 30)
	KillCount.Position = UDim2.new(0, 50, 0, 5)
	KillCount.BackgroundTransparency = 1
	KillCount.Text = "0"
	KillCount.TextColor3 = Color3.fromRGB(255, 255, 255)
	KillCount.Font = Enum.Font.GothamBold
	KillCount.TextSize = 32
	KillCount.TextXAlignment = Enum.TextXAlignment.Left
	KillCount.TextStrokeTransparency = 0.5
	KillCount.Parent = KillCounterFrame

	-- Kill Label
	local KillLabel = Instance.new("TextLabel")
	KillLabel.Name = "KillLabel"
	KillLabel.Size = UDim2.new(0, 145, 0, 20)
	KillLabel.Position = UDim2.new(0, 50, 0, 35)
	KillLabel.BackgroundTransparency = 1
	KillLabel.Text = "KILLS"
	KillLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	KillLabel.Font = Enum.Font.GothamBold
	KillLabel.TextSize = 14
	KillLabel.TextXAlignment = Enum.TextXAlignment.Left
	KillLabel.TextTransparency = 0.3
	KillLabel.Parent = KillCounterFrame
end

-- Actualizar contador con animación optimizada
local lastKillTime = 0
local function updateKillCounter()
	if not KillCounterFrame then return end
	
	local killCountLabel = KillCounterFrame:FindFirstChild("KillCount")
	local killIcon = KillCounterFrame:FindFirstChild("KillIcon")
	local frameStroke = KillCounterFrame:FindFirstChild("UIStroke")
	
	if killCountLabel then
		killCountLabel.Text = tostring(killCount)
		
		-- Animación optimizada (solo si pasó suficiente tiempo)
		local currentTime = tick()
		if currentTime - lastKillTime > 0.1 then
			lastKillTime = currentTime
			task.spawn(function()
				-- Pulso en número
				killCountLabel.TextSize = 36
				if killIcon then killIcon.TextSize = 32 end
				if frameStroke then frameStroke.Transparency = 0 end
				
				task.wait(0.08)
				
				killCountLabel.TextSize = 32
				if killIcon then killIcon.TextSize = 28 end
				if frameStroke then frameStroke.Transparency = 0.3 end
			end)
		end
	end
end

-- ===== INFO HUD (VIP) =====
local InfoHUD
if isVIP then
	InfoHUD = Instance.new("Frame")
	InfoHUD.Name = "InfoHUD"
	InfoHUD.Size = UDim2.new(0, 220, 0, 150)
	InfoHUD.Position = UDim2.new(0.015, 0, 0.12, 0)
	InfoHUD.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	InfoHUD.BackgroundTransparency = 0.2
	InfoHUD.BorderSizePixel = 0
	InfoHUD.Visible = false
	InfoHUD.Parent = ScreenGui

	local HUDCorner = Instance.new("UICorner")
	HUDCorner.CornerRadius = UDim.new(0, 12)
	HUDCorner.Parent = InfoHUD

	local HUDStroke = Instance.new("UIStroke")
	HUDStroke.Color = Color3.fromRGB(100, 150, 255)
	HUDStroke.Thickness = 2
	HUDStroke.Transparency = 0.3
	HUDStroke.Parent = InfoHUD

	-- Título
	local HUDTitle = Instance.new("TextLabel")
	HUDTitle.Size = UDim2.new(1, -20, 0, 25)
	HUDTitle.Position = UDim2.new(0, 10, 0, 5)
	HUDTitle.BackgroundTransparency = 1
	HUDTitle.Text = "📊 INFO HUD"
	HUDTitle.TextColor3 = Color3.fromRGB(100, 150, 255)
	HUDTitle.Font = Enum.Font.GothamBold
	HUDTitle.TextSize = 16
	HUDTitle.TextXAlignment = Enum.TextXAlignment.Left
	HUDTitle.Parent = InfoHUD

	-- Ronda
	local RoundLabel = Instance.new("TextLabel")
	RoundLabel.Name = "RoundLabel"
	RoundLabel.Size = UDim2.new(1, -20, 0, 20)
	RoundLabel.Position = UDim2.new(0, 10, 0, 35)
	RoundLabel.BackgroundTransparency = 1
	RoundLabel.Text = "🎯 RONDA: --"
	RoundLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	RoundLabel.Font = Enum.Font.GothamBold
	RoundLabel.TextSize = 14
	RoundLabel.TextXAlignment = Enum.TextXAlignment.Left
	RoundLabel.Parent = InfoHUD

	-- Zombies vivos
	local ZombiesLabel = Instance.new("TextLabel")
	ZombiesLabel.Name = "ZombiesLabel"
	ZombiesLabel.Size = UDim2.new(1, -20, 0, 20)
	ZombiesLabel.Position = UDim2.new(0, 10, 0, 60)
	ZombiesLabel.BackgroundTransparency = 1
	ZombiesLabel.Text = "💀 ZOMBIES: 0"
	ZombiesLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	ZombiesLabel.Font = Enum.Font.GothamBold
	ZombiesLabel.TextSize = 14
	ZombiesLabel.TextXAlignment = Enum.TextXAlignment.Left
	ZombiesLabel.Parent = InfoHUD

	-- Velocidad actual
	local SpeedLabel = Instance.new("TextLabel")
	SpeedLabel.Name = "SpeedLabel"
	SpeedLabel.Size = UDim2.new(1, -20, 0, 20)
	SpeedLabel.Position = UDim2.new(0, 10, 0, 85)
	SpeedLabel.BackgroundTransparency = 1
	SpeedLabel.Text = "⚡ VELOCIDAD: 16"
	SpeedLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
	SpeedLabel.Font = Enum.Font.GothamBold
	SpeedLabel.TextSize = 14
	SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
	SpeedLabel.Parent = InfoHUD

	-- Freeze Cooldown
	local FreezeLabel = Instance.new("TextLabel")
	FreezeLabel.Name = "FreezeLabel"
	FreezeLabel.Size = UDim2.new(1, -20, 0, 20)
	FreezeLabel.Position = UDim2.new(0, 10, 0, 110)
	FreezeLabel.BackgroundTransparency = 1
	FreezeLabel.Text = "❄️ FREEZE: LISTO"
	FreezeLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	FreezeLabel.Font = Enum.Font.GothamBold
	FreezeLabel.TextSize = 14
	FreezeLabel.TextXAlignment = Enum.TextXAlignment.Left
	FreezeLabel.Parent = InfoHUD
end

-- Función para actualizar Info HUD
local function updateInfoHUD()
	if not InfoHUD then return end
	
	local roundLabel = InfoHUD:FindFirstChild("RoundLabel")
	local zombiesLabel = InfoHUD:FindFirstChild("ZombiesLabel")
	local speedLabelHUD = InfoHUD:FindFirstChild("SpeedLabel")
	local freezeLabel = InfoHUD:FindFirstChild("FreezeLabel")
	
	-- Actualizar ronda (buscar en workspace)
	if roundLabel then
		local roundValue = workspace:FindFirstChild("RoundValue") or workspace:FindFirstChild("Round")
		if roundValue and roundValue:IsA("IntValue") then
			roundLabel.Text = "🎯 RONDA: " .. roundValue.Value
		else
			roundLabel.Text = "🎯 RONDA: --"
		end
	end
	
	-- Actualizar zombies vivos
	if zombiesLabel then
		local baddies = workspace:FindFirstChild("Baddies")
		local count = baddies and #baddies:GetChildren() or 0
		zombiesLabel.Text = "💀 ZOMBIES: " .. count
	end
	
	-- Actualizar velocidad
	if speedLabelHUD then
		local char = player.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		local currentSpeed = humanoid and math.floor(humanoid.WalkSpeed) or 16
		speedLabelHUD.Text = "⚡ VELOCIDAD: " .. currentSpeed
	end
	
	-- Actualizar freeze cooldown
	if freezeLabel then
		if freezeActive then
			freezeLabel.Text = "❄️ FREEZE: ACTIVO"
			freezeLabel.TextColor3 = Color3.fromRGB(100, 255, 255)
		elseif freezeCooldown then
			local timeLeft = math.ceil(freezeCooldownTime - tick())
			freezeLabel.Text = "❄️ FREEZE: " .. timeLeft .. "s"
			freezeLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
		else
			freezeLabel.Text = "❄️ FREEZE: LISTO"
			freezeLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
		end
	end
end

local currentTPOption = 1
local TPOptions = {"SIN TP", "PACK-A-PUNCH", "MYSTERY BOX"}

local TPSelectorLabel
if isVIP then
	TPSelectorLabel = Instance.new("TextLabel")
	TPSelectorLabel.Name = "TPSelectorLabel"
	TPSelectorLabel.Size = UDim2.new(0, 220, 0, 35)
	TPSelectorLabel.Position = UDim2.new(0.015, 0, 0.25, 0)
	TPSelectorLabel.BackgroundTransparency = 1
	TPSelectorLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	TPSelectorLabel.Font = Enum.Font.GothamBold
	TPSelectorLabel.TextSize = 20
	TPSelectorLabel.TextStrokeTransparency = 0.3
	TPSelectorLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	TPSelectorLabel.TextXAlignment = Enum.TextXAlignment.Left
	TPSelectorLabel.Visible = false
	TPSelectorLabel.Parent = ScreenGui
end

local function updateTPSelector()
	if TPSelectorLabel then
		TPSelectorLabel.Text = "📍 " .. TPOptions[currentTPOption]
	end
end

-- ===== OTROS ELEMENTOS GUI =====
local AlertText = Instance.new("TextLabel")
AlertText.Name = "AlertText"
AlertText.Size = UDim2.new(0, 360, 0, 50)
AlertText.Position = UDim2.new(0.5, -180, 0.12, 0)
AlertText.BackgroundTransparency = 1
AlertText.TextColor3 = Color3.fromRGB(255, 0, 0)
AlertText.Font = Enum.Font.GothamBold
AlertText.TextSize = 30
AlertText.TextStrokeTransparency = 0.3
AlertText.Visible = false
AlertText.Parent = ScreenGui

local CircleButton = Instance.new("TextButton")
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

-- Botón arrastrable (optimizado)
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

connections.drag = UserInputService.InputChanged:Connect(function(input)
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

-- Función helper para crear botones
local function createButton(name, text, position, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0, 240, 0, 50)
	button.Position = position
	button.BackgroundColor3 = color
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 20
	button.Parent = MobileMenu
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	
	return button
end

-- Crear botones del menú
local MenuTitle = Instance.new("TextLabel")
MenuTitle.Size = UDim2.new(1, 0, 0, 40)
MenuTitle.BackgroundTransparency = 1
MenuTitle.Text = "MENU DE CONTROL"
MenuTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
MenuTitle.Font = Enum.Font.GothamBold
MenuTitle.TextSize = 18
MenuTitle.Parent = MobileMenu

local ESPButton = createButton("ESPButton", enabled and "ESP: ON" or "ESP: OFF", 
	UDim2.new(0.5, -120, 0, 55), 
	enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))

local AimbotButton = createButton("AimbotButton", aimbotEnabled and "AIMBOT: ON" or "AIMBOT: OFF",
	UDim2.new(0.5, -120, 0, 115),
	aimbotEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))

local SpeedButton = createButton("SpeedButton", speedHackEnabled and "SPEED: ON" or "SPEED: OFF",
	UDim2.new(0.5, -120, 0, 175),
	speedHackEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))

local ServerHopButton = createButton("ServerHopButton", "🔄 CAMBIAR SERVER",
	UDim2.new(0.5, -120, 0, 295),
	Color3.fromRGB(100, 100, 255))

-- Speed slider
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(0, 240, 0, 25)
SpeedLabel.Position = UDim2.new(0.5, -120, 0, 235)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Velocidad: " .. speedValue
SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.TextSize = 16
SpeedLabel.Parent = MobileMenu

local SliderBG = Instance.new("Frame")
SliderBG.Size = UDim2.new(0, 240, 0, 10)
SliderBG.Position = UDim2.new(0.5, -120, 0, 268)
SliderBG.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
SliderBG.BorderSizePixel = 0
SliderBG.Parent = MobileMenu

local SliderCorner = Instance.new("UICorner")
SliderCorner.CornerRadius = UDim.new(0, 5)
SliderCorner.Parent = SliderBG

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new((speedValue - config.MIN_SPEED) / (config.MAX_SPEED - config.MIN_SPEED), 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderBG

local FillCorner = Instance.new("UICorner")
FillCorner.CornerRadius = UDim.new(0, 5)
FillCorner.Parent = SliderFill

local SliderButton = Instance.new("TextButton")
SliderButton.Size = UDim2.new(0, 20, 0, 20)
SliderButton.Position = UDim2.new((speedValue - config.MIN_SPEED) / (config.MAX_SPEED - config.MIN_SPEED), -10, 0.5, -10)
SliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderButton.BorderSizePixel = 0
SliderButton.Text = ""
SliderButton.Parent = SliderBG

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(1, 0)
ButtonCorner.Parent = SliderButton

-- Texto de bienvenida
local WelcomeText = Instance.new("TextLabel")
WelcomeText.Size = UDim2.new(0, 400, 0, 35)
WelcomeText.Position = UDim2.new(0.5, -200, 0.85, 0)
WelcomeText.BackgroundTransparency = 0.3
WelcomeText.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
WelcomeText.Text = isVIP and "Creator = Nobodxy85-bit  :D | 👑 VIP" or "Creator = Nobodxy85-bit  :D"
WelcomeText.TextColor3 = isVIP and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255)
WelcomeText.Font = Enum.Font.GothamBold
WelcomeText.TextSize = 18
WelcomeText.Parent = ScreenGui

local WelcomeCorner = Instance.new("UICorner")
WelcomeCorner.CornerRadius = UDim.new(0, 10)
WelcomeCorner.Parent = WelcomeText

task.spawn(function()
	task.wait(3)
	for i = 0, 30 do
		WelcomeText.TextTransparency = i / 30
		WelcomeText.BackgroundTransparency = 0.3 + (0.7 * (i / 30))
		task.wait(0.067)
	end
	WelcomeText.Visible = false
end)

-- Status text
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

-- ===== FUNCIONES OPTIMIZADAS =====
local function showStatus(text, color)
	if not StatusText then return end
	StatusText.Text = text
	StatusText.TextColor3 = color
	StatusText.Visible = true
	StatusText.TextTransparency = 0
	StatusText.BackgroundTransparency = 0.5
	
	task.delay(2, function()
		for i = 0, 30 do
			if StatusText then
				StatusText.TextTransparency = i / 30
				task.wait(0.033)
			end
		end
		if StatusText then StatusText.Visible = false end
	end)
end

local function cycleTPOption()
	currentTPOption = currentTPOption % #TPOptions + 1
	updateTPSelector()
	showStatus("TP: " .. TPOptions[currentTPOption], Color3.fromRGB(255, 215, 0))
end

local function executeTP()
	if currentTPOption == 1 then
		showStatus("❌ Sin TP seleccionado", Color3.fromRGB(255, 100, 0))
		return
	end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		showStatus("❌ No se encontró tu personaje", Color3.fromRGB(255, 0, 0))
		return
	end

	local interact = workspace:FindFirstChild("Interact")
	if not interact then
		showStatus("❌ No se encontró Interact", Color3.fromRGB(255, 0, 0))
		return
	end

	local targetName = currentTPOption == 2 and "Pack-A-Punch" or "MysteryBox"
	local target = interact:FindFirstChild(targetName)
	
	if not target then
		showStatus("❌ No se encontró " .. targetName, Color3.fromRGB(255, 0, 0))
		return
	end

	local targetPart = target:FindFirstChildWhichIsA("BasePart")
	if targetPart then
		hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 5)
		showStatus("✅ TP a " .. targetName, Color3.fromRGB(0, 255, 0))
	end
end

local function serverHop()
	showStatus("🔄 Buscando servidor...", Color3.fromRGB(100, 150, 255))
	
	pcall(function()
		local servers = {}
		local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
		local body = game:GetService("HttpService"):JSONDecode(req)
		
		if body and body.data then
			for _, v in ipairs(body.data) do
				if v.id ~= game.JobId and v.playing < v.maxPlayers then
					table.insert(servers, v.id)
				end
			end
		end
		
		if #servers > 0 then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(#servers)], player)
		else
			showStatus("❌ No hay servidores", Color3.fromRGB(255, 0, 0))
		end
	end)
end

-- ===== ESP OPTIMIZADO CON DISTANCIA =====
local function getDistanceColor(distance)
	if distance > 30 then
		return Color3.fromRGB(0, 255, 0) -- Verde = Lejos
	elseif distance > 15 then
		return Color3.fromRGB(255, 255, 0) -- Amarillo = Medio
	else
		return Color3.fromRGB(255, 0, 0) -- Rojo = Cerca
	end
end

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

local function addDistanceLabel(zombie)
	if zombie:FindFirstChild("ESP_Distance") then return end
	
	local head = zombie:FindFirstChild("Head")
	if not head then return end
	
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "ESP_Distance"
	billboardGui.Adornee = head
	billboardGui.Size = UDim2.new(0, 100, 0, 40)
	billboardGui.StudsOffset = Vector3.new(0, 2, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.Parent = head
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 16
	textLabel.TextStrokeTransparency = 0.5
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.Parent = billboardGui
	
	table.insert(espObjects, billboardGui)
end

local function createZombieESP(zombie)
	if cachedZombies[zombie] then return end
	cachedZombies[zombie] = true

	for _, part in ipairs(zombie:GetChildren()) do
		if part:IsA("BasePart") then
			addOutline(part, Color3.fromRGB(255, 0, 0))
		end
	end
	
	-- Agregar label de distancia
	addDistanceLabel(zombie)
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

-- Actualizar colores de ESP según distancia
local lastESPUpdate = 0
local function updateESPColors()
	local currentTime = tick()
	if currentTime - lastESPUpdate < 0.5 then return end
	lastESPUpdate = currentTime
	
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local baddies = workspace:FindFirstChild("Baddies")
	if not baddies then return end
	
	for _, zombie in ipairs(baddies:GetChildren()) do
		local zombieHRP = zombie:FindFirstChild("HumanoidRootPart")
		local head = zombie:FindFirstChild("Head")
		
		if zombieHRP and head then
			local distance = (hrp.Position - zombieHRP.Position).Magnitude
			local color = getDistanceColor(distance)
			
			-- Actualizar color del ESP
			for _, part in ipairs(zombie:GetChildren()) do
				if part:IsA("BasePart") then
					local highlight = part:FindFirstChild("ESP_Highlight")
					if highlight then
						highlight.OutlineColor = color
					end
				end
			end
			
			-- Actualizar texto de distancia
			local distanceGUI = head:FindFirstChild("ESP_Distance")
			if distanceGUI then
				local textLabel = distanceGUI:FindFirstChildOfClass("TextLabel")
				if textLabel then
					textLabel.Text = math.floor(distance) .. "m"
					textLabel.TextColor3 = color
				end
			end
		end
	end
end

local function clearAll()
	for _, obj in ipairs(espObjects) do
		if obj then pcall(function() obj:Destroy() end) end
	end
	table.clear(espObjects)
	table.clear(cachedZombies)
	table.clear(cachedBoxes)
end

local function enableESP()
	local baddies = workspace:FindFirstChild("Baddies")
	if not baddies then return end

	for _, z in ipairs(baddies:GetChildren()) do
		createZombieESP(z)
	end

	connections.zombieAdded = baddies.ChildAdded:Connect(function(zombie)
		task.wait(0.1)
		if enabled then createZombieESP(zombie) end
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

-- ===== ZOMBIE FREEZE SYSTEM (VIP) =====
local frozenZombies = {}

local function freezeZombies()
	if not isVIP then
		showStatus("❌ FREEZE es solo VIP", Color3.fromRGB(255, 0, 0))
		return
	end
	
	if freezeCooldown then
		local timeLeft = math.ceil(freezeCooldownTime - tick())
		showStatus("❄️ Cooldown: " .. timeLeft .. "s", Color3.fromRGB(255, 150, 100))
		return
	end
	
	if freezeActive then
		showStatus("❄️ Freeze ya está activo", Color3.fromRGB(100, 200, 255))
		return
	end
	
	local baddies = workspace:FindFirstChild("Baddies")
	if not baddies then
		showStatus("❌ No hay zombies", Color3.fromRGB(255, 0, 0))
		return
	end
	
	freezeActive = true
	local frozenCount = 0
	
	-- Congelar todos los zombies
	for _, zombie in ipairs(baddies:GetChildren()) do
		local humanoid = zombie:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			-- Guardar velocidad original
			frozenZombies[zombie] = humanoid.WalkSpeed
			
			-- Congelar
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			
			-- Efecto visual de hielo
			for _, part in ipairs(zombie:GetChildren()) do
				if part:IsA("BasePart") then
					local ice = Instance.new("SelectionBox")
					ice.Name = "IceEffect"
					ice.Adornee = part
					ice.LineThickness = 0.05
					ice.Color3 = Color3.fromRGB(100, 200, 255)
					ice.Parent = part
				end
			end
			
			frozenCount = frozenCount + 1
		end
	end
	
	showStatus("❄️ " .. frozenCount .. " ZOMBIES CONGELADOS", Color3.fromRGB(100, 255, 255))
	
	-- Descongelar después de 5 segundos
	task.delay(config.FREEZE_DURATION, function()
		for zombie, originalSpeed in pairs(frozenZombies) do
			if zombie and zombie.Parent then
				local humanoid = zombie:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = originalSpeed
					humanoid.JumpPower = 50
				end
				
				-- Remover efecto visual
				for _, part in ipairs(zombie:GetChildren()) do
					if part:IsA("BasePart") then
						local ice = part:FindFirstChild("IceEffect")
						if ice then ice:Destroy() end
					end
				end
			end
		end
		
		table.clear(frozenZombies)
		freezeActive = false
		showStatus("🔥 Zombies descongelados", Color3.fromRGB(255, 150, 100))
		
		-- Iniciar cooldown
		freezeCooldown = true
		freezeCooldownTime = tick() + config.FREEZE_COOLDOWN
		
		task.delay(config.FREEZE_COOLDOWN, function()
			freezeCooldown = false
			showStatus("❄️ Freeze listo de nuevo", Color3.fromRGB(100, 255, 150))
		end)
	end)
end

-- ===== KILL COUNTER SYSTEM OPTIMIZADO =====
local function setupKillCounter()
	local baddies = workspace:FindFirstChild("Baddies")
	if not baddies then return end

	local function connectZombie(zombie)
		local humanoid = zombie:FindFirstChildOfClass("Humanoid")
		if humanoid and not humanoid:GetAttribute("KillTracked") then
			humanoid:SetAttribute("KillTracked", true)
			humanoid.Died:Connect(function()
				if isVIP and showKills then
					killCount = killCount + 1
					updateKillCounter()
				end
			end)
		end
	end

	for _, zombie in ipairs(baddies:GetChildren()) do
		connectZombie(zombie)
	end

	connections.killCounter = baddies.ChildAdded:Connect(function(zombie)
		task.wait(0.1)
		connectZombie(zombie)
	end)
end

-- ===== SPEED HACK OPTIMIZADO =====
local function applySpeed()
	local char = player.Character
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = speedValue
		end
	end
end

connections.speed = RunService.Heartbeat:Connect(function()
	if speedHackEnabled then
		applySpeed()
	end
end)

player.CharacterAdded:Connect(function()
	if speedHackEnabled then
		task.wait(1)
		applySpeed()
	end
end)

local function toggleSpeedHack()
	speedHackEnabled = not speedHackEnabled
	
	if speedHackEnabled then
		applySpeed()
		showStatus("SPEED HACK | ON", Color3.fromRGB(0, 255, 0))
		SpeedButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		SpeedButton.Text = "SPEED: ON"
	else
		local char = player.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = 16
			end
		end
		showStatus("SPEED HACK | OFF", Color3.fromRGB(255, 0, 0))
		SpeedButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		SpeedButton.Text = "SPEED: OFF"
	end
end

local function updateSlider(value)
	speedValue = math.clamp(value, config.MIN_SPEED, config.MAX_SPEED)
	
	local percent = (speedValue - config.MIN_SPEED) / (config.MAX_SPEED - config.MIN_SPEED)
	SliderFill.Size = UDim2.new(percent, 0, 1, 0)
	SliderButton.Position = UDim2.new(percent, -10, 0.5, -10)
	SpeedLabel.Text = "Velocidad: " .. math.floor(speedValue)
	
	if speedHackEnabled then applySpeed() end
end

-- Slider dragging optimizado
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

connections.sliderDrag = UserInputService.InputChanged:Connect(function(input)
	if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local percent = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
		updateSlider(config.MIN_SPEED + (percent * (config.MAX_SPEED - config.MIN_SPEED)))
	end
end)

SliderBG.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local percent = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
		updateSlider(config.MIN_SPEED + (percent * (config.MAX_SPEED - config.MIN_SPEED)))
	end
end)

-- ===== AIMBOT OPTIMIZADO =====
local function getClosestZombieToCursor()
	local shortest = math.huge
	local closest = nil
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

-- ===== TOGGLE FUNCTIONS =====
local function toggleESP(fromKeyboard)
	enabled = not enabled

	if fromKeyboard and firstTimeKeyboard then
		CircleButton.Visible = false
		firstTimeKeyboard = false
	end

	if enabled then
		enableESP()
		if isVIP then
			showKills = true
			KillCounterFrame.Visible = true
			InfoHUD.Visible = true
			updateKillCounter()
		end
		showStatus("ESP | ENABLE", Color3.fromRGB(0, 255, 0))
		ESPButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		ESPButton.Text = "ESP: ON"
	else
		clearAll()
		AlertText.Visible = false
		if isVIP then
			showKills = false
			KillCounterFrame.Visible = false
			InfoHUD.Visible = false
		end
		showStatus("ESP | DISABLE", Color3.fromRGB(255, 0, 0))
		ESPButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		ESPButton.Text = "ESP: OFF"
	end
end

local function toggleAimbot()
	aimbotEnabled = not aimbotEnabled
	
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
	CircleButton.BackgroundColor3 = MobileMenu.Visible and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(50, 50, 50)
	UIStroke.Color = MobileMenu.Visible and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(255, 255, 255)
end)

ESPButton.MouseButton1Click:Connect(function() toggleESP(false) end)
AimbotButton.MouseButton1Click:Connect(function() toggleAimbot() end)
SpeedButton.MouseButton1Click:Connect(function() toggleSpeedHack() end)
ServerHopButton.MouseButton1Click:Connect(function() serverHop() end)

-- ===== BUCLE PRINCIPAL OPTIMIZADO =====
local lastAlertCheck = 0
local lastHUDUpdate = 0
connections.render = RunService.RenderStepped:Connect(function()
	local currentTime = tick()
	
	-- Actualizar Info HUD (cada 0.5 segundos)
	if isVIP and InfoHUD and InfoHUD.Visible and currentTime - lastHUDUpdate > 0.5 then
		lastHUDUpdate = currentTime
		updateInfoHUD()
	end
	
	-- Actualizar colores ESP según distancia
	if enabled then
		updateESPColors()
	end
	
	-- Alerta zombies (cada 0.2 segundos)
	if enabled and currentTime - lastAlertCheck > 0.2 then
		lastAlertCheck = currentTime
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local baddies = workspace:FindFirstChild("Baddies")

		if hrp and baddies then
			local count = 0
			for _, z in ipairs(baddies:GetChildren()) do
				local root = z:FindFirstChild("HumanoidRootPart")
				local humanoid = z:FindFirstChildOfClass("Humanoid")

				if root and humanoid and humanoid.Health > 0 then
					if (hrp.Position - root.Position).Magnitude <= config.ALERT_DISTANCE then
						count = count + 1
					end
				end
			end

			AlertText.Visible = count > 0
			if count > 0 then
				AlertText.Text = "⚠ ZOMBIE CERCA (x" .. count .. ")"
			end
		end
	end

	-- Aimbot
	if aimbotEnabled then
		local head = getClosestZombieToCursor()
		if head then
			local targetCFrame = CFrame.new(Camera.CFrame.Position, head.Position)
			Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, config.SMOOTHNESS)
		end
	end
end)

-- ===== CONTROLES DE TECLADO =====
connections.input = UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end

	local key = input.KeyCode
	
	if key == Enum.KeyCode.T then
		toggleESP(true)
	elseif key == Enum.KeyCode.C then
		toggleAimbot()
	elseif key == Enum.KeyCode.H then
		serverHop()
	elseif key == Enum.KeyCode.E then
		toggleSpeedHack()
	elseif key == Enum.KeyCode.K or key == Enum.KeyCode.Equals then
		if speedValue < config.MAX_SPEED then
			updateSlider(speedValue + config.SPEED_INCREMENT)
			showStatus("Velocidad: " .. math.floor(speedValue), Color3.fromRGB(0, 200, 255))
		end
	elseif key == Enum.KeyCode.L then
		if speedValue > config.MIN_SPEED then
			updateSlider(speedValue - config.SPEED_INCREMENT)
			showStatus("Velocidad: " .. math.floor(speedValue), Color3.fromRGB(0, 200, 255))
		end
	elseif key == Enum.KeyCode.M then
		if isVIP then
			showStatus("👑 VIP ACTIVO | ID: " .. player.UserId, Color3.fromRGB(255, 215, 0))
			print("👑 Eres VIP\n📌 Y = Cambiar TP\n📌 Z = Ejecutar TP\n📌 X = Zombie Freeze\n📌 V = Toggle Info HUD")
		else
			showStatus("❌ NO ERES VIP | Tu ID: " .. player.UserId, Color3.fromRGB(255, 0, 0))
			print("❌ Tu UserID es: " .. player.UserId)
		end
	elseif isVIP then
		if key == Enum.KeyCode.Y then
			cycleTPOption()
			if TPSelectorLabel then
				TPSelectorLabel.Visible = true
				task.delay(3, function()
					if TPSelectorLabel then TPSelectorLabel.Visible = false end
				end)
			end
		elseif key == Enum.KeyCode.Z then
			executeTP()
		elseif key == Enum.KeyCode.X then
			freezeZombies()
		elseif key == Enum.KeyCode.V then
			if InfoHUD then
				InfoHUD.Visible = not InfoHUD.Visible
				showStatus(InfoHUD.Visible and "📊 Info HUD: ON" or "📊 Info HUD: OFF", 
					InfoHUD.Visible and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(255, 100, 100))
			end
		end
	end
end)

-- ===== LIMPIEZA =====
local function cleanup()
	for name, conn in pairs(connections) do
		if conn then pcall(function() conn:Disconnect() end) end
	end
	clearAll()
end

Players.PlayerRemoving:Connect(function(plr)
	if plr == player then cleanup() end
end)

-- ===== INICIALIZACIÓN =====
setupKillCounter()

print("✅ ESP Script OPTIMIZADO cargado!")
print("📌 T = ESP con Distancia | C = Aimbot | E = Speed | H = Server Hop")
print("📌 K = Velocidad+ | L = Velocidad-")
if isVIP then
	print("👑 VIP FEATURES:")
	print("   Y = Cambiar TP | Z = Ejecutar TP")
	print("   X = Zombie Freeze (5s - CD 15s)")
	print("   V = Toggle Info HUD")
	print("   📊 Kill Counter automático con ESP")
	print("👑 VIP ACTIVO | ID: " .. player.UserId)
else
	print("📌 M = Verificar VIP")
end
