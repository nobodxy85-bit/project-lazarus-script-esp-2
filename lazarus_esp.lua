-- ESP ZOMBIES + ESP MYSTERY BOX + ALERTA + PATHFIND AZUL (ACTUALIZA CADA FRAME)

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
local pathLines = {}

-- ===== GUI ALERTA =====
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

-- ===== FUNCIONES ESP =====
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
    for _, part in ipairs(zombie:GetChildren()) do
        addBox(part, Color3.fromRGB(255, 0, 0), 0.6)
    end
end

local function createMysteryESP(box)
    for _, part in ipairs(box:GetDescendants()) do
        addBox(part, Color3.fromRGB(0, 200, 255), 0.45)
    end
end

local function clearAll()
    for _, obj in ipairs(espObjects) do
        if obj then obj:Destroy() end
    end
    for _, line in ipairs(pathLines) do
        if line then line:Destroy() end
    end
    table.clear(espObjects)
    table.clear(pathLines)
end

-- ===== PATHFIND AZUL =====
local function drawPath(targetPos)
    -- limpiar path anterior
    for _, l in ipairs(pathLines) do
        l:Destroy()
    end
    table.clear(pathLines)

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

    local waypoints = path:GetWaypoints()
    for i = 1, #waypoints - 1 do
        local p0 = waypoints[i].Position
        local p1 = waypoints[i + 1].Position
        local dist = (p0 - p1).Magnitude

        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(0, 150, 255) -- 🔵 AZUL
        part.Size = Vector3.new(0.22, 0.22, dist)
        part.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
        part.Parent = workspace

        table.insert(pathLines, part)
    end
end

-- ===== MYSTERY BOX MÁS CERCANA =====
local function getNearestMysteryBox()
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
                createMysteryESP(obj)
            end
        end
    end
end

-- ===== ALERTA + PATH (CADA FRAME) =====
RunService.RenderStepped:Connect(function()
    if not enabled then
        AlertText.Visible = false
        return
    end

    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local baddies = workspace:FindFirstChild("Baddies")
    if not hrp or not baddies then return end

    -- alerta zombies
    local count = 0
    for _, z in ipairs(baddies:GetChildren()) do
        local root = z:FindFirstChild("HumanoidRootPart")
        if root and (hrp.Position - root.Position).Magnitude <= ALERT_DISTANCE then
            count += 1
        end
    end

    if count > 0 then
        AlertText.Text = "⚠ ZOMBIE CERCA (x" .. count .. ")"
        AlertText.Visible = true
    else
        AlertText.Visible = false
    end

    -- path a la caja
    local box = getNearestMysteryBox()
    if box then
        drawPath(box.Position) -- 🔁 cada frame
    end
end)

-- ===== TECLA T =====
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.T then
        enabled = not enabled
        if enabled then
            enableESP()
        else
            clearAll()
            AlertText.Visible = false
        end
    end
end)
