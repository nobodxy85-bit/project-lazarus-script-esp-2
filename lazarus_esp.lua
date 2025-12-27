-- ESP ZOMBIES + ESP MYSTERY BOX + ALERTA + PATHFIND CON BEAM (LIVIANO)

-- ===== SERVICIOS =====
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local player = Players.LocalPlayer

-- ===== CONFIG =====
local ALERT_DISTANCE = 20
local enabled = false
local espObjects = {}
local firstTime = true

-- ===== FOLDER BEAM =====
local beamFolder = Instance.new("Folder")
beamFolder.Name = "PathBeam"
beamFolder.Parent = workspace

local attachments = {}
local beams = {}

-- ===== GUI =====
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

local StartText = Instance.new("TextLabel")
StartText.Size = UDim2.new(0, 520, 0, 50)
StartText.Position = UDim2.new(0.5, -260, 0.18, 0)
StartText.BackgroundTransparency = 0.7
StartText.Text = 'Apreta "T" para activar tus poderes'
StartText.TextColor3 = Color3.fromRGB(0,0,0)
StartText.Font = Enum.Font.GothamBold
StartText.TextSize = 20
StartText.Visible = true
StartText.Parent = ScreenGui

-- ===== ESP =====
local function addBox(part, color, transparency)
	if not part:IsA("BasePart") or part:FindFirstChild("ESP_Box") then return end

	local box = Instance.new("BoxHandleAdornment")
	box.Name = "ESP_Box"
	box.Adornee = part
	box.Size = part.Size + Vector3.new(0.15,0.15,0.15)
	box.AlwaysOnTop = true
	box.Transparency = transparency
	box.Color3 = color
	box.Parent = part

	table.insert(espObjects, box)
end

local function createZombieESP(zombie)
	for _, part in ipairs(zombie:GetChildren()) do
		addBox(part, Color3.fromRGB(255,0,0), 0.6)
	end
end

local function createBoxESP(box)
	for _, part in ipairs(box:GetDescendants()) do
		addBox(part, Color3.fromRGB(0,200,255), 0.45)
	end
end

-- ===== LIMPIAR =====
local function clearAll()
	for _, e in ipairs(espObjects) do
		if e then e:Destroy() end
	end
	table.clear(espObjects)

	for _, b in ipairs(beams) do b:Destroy() end
	for _, a in ipairs(attachments) do a:Destroy() end
	table.clear(beams)
	table.clear(attachments)
end

-- ===== PATHFIND BEAM =====
local function clearBeam()
	for _, b in ipairs(beams) do b:Destroy() end
	for _, a in ipairs(attachments) do a:Destroy() end
	table.clear(beams)
	table.clear(attachments)
end

local function drawBeamPath(targetPos)
	clearBeam()

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true
	})

	path:ComputeAsync(hrp.Position, targetPos)
	if path.Status ~= Enum.PathStatus.Success then return end

	local points = path:GetWaypoints()
	if #points < 2 then return end

	for i, wp in ipairs(points) do
		local att = Instance.new("Attachment")
		att.WorldPosition = wp.Position + Vector3.new(0,0.25,0)
		att.Parent = beamFolder
		table.insert(attachments, att)
	end

	for i = 1, #attachments - 1 do
		local beam = Instance.new("Beam")
		beam.Attachment0 = attachments[i]
		beam.Attachment1 = attachments[i + 1]
		beam.FaceCamera = true
		beam.Width0 = 0.22
		beam.Width1 = 0.22
		beam.Color = ColorSequence.new(Color3.fromRGB(0,150,255))
		beam.LightEmission = 1
		beam.Transparency = NumberSequence.new(0)
		beam.Parent = beamFolder

		table.insert(beams, beam)
	end
end

-- ===== CAJA MÁS CERCANA =====
local function getNearestBox()
	local interact = workspace:FindFirstChild("Interact")
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not interact or not hrp then return end

	local nearest, dist = nil, math.huge
	for _, obj in ipairs(interact:GetChildren()) do
		if obj.Name == "MysteryBox" then
			local part = obj:FindFirstChildWhichIsA("BasePart")
			if part then
				local d = (hrp.Position - part.Position).Magnitude
				if d < dist then
					dist = d
					nearest = part
				end
			end
		end
	end
	return nearest
end

-- ===== ACTIVAR ESP =====
local function enableESP()
	local baddies = workspace:FindFirstChild("Baddies")
	if baddies then
		for _, z in ipairs(baddies:GetChildren()) do
			createZombieESP(z)
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
	for _, z in ipairs(baddies:GetChildren()) do
		local root = z:FindFirstChild("HumanoidRootPart")
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

	local box = getNearestBox()
	if box then
		drawBeamPath(box.Position)
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
			enableESP()
		else
			clearAll()
			AlertText.Visible = false
		end
	end
end)
