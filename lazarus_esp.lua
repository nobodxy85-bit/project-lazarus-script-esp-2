
-- ESP ROJO para zombies + ESP AZUL para Mystery Box + alerta de zombies
-- Creador = Nobodxy-bit

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local ALERT_DISTANCE = 20
local enabled = false
local espObjects = {}

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

-- ===== ESP PARA ZOMBIES =====
local function createZombieESP(model)
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

-- ===== ESP PARA MYSTERY BOX =====
local function createBoxESP(model)
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

local function removeESP()
    for _, box in ipairs(espObjects) do
        if box and box.Parent then
            box:Destroy()
        end
    end
    table.clear(espObjects)
end

local function enableAllESP()
    -- ESP para zombies
    local baddies = workspace:FindFirstChild("Baddies")
    if baddies then
        for _, zomb in ipairs(baddies:GetChildren()) do
            createZombieESP(zomb)
        end
    end
    
    -- ESP para Mystery Box (RUTA CORREGIDA)
    local interact = workspace:FindFirstChild("Interact")
    if interact then
        for _, obj in ipairs(interact:GetChildren()) do
            if obj.Name == "MysteryBox" then
                createBoxESP(obj)
            end
        end
    end
end

-- ===== DETECTAR NUEVOS ZOMBIES =====
local baddies = workspace:FindFirstChild("Baddies")
if baddies then
    baddies.ChildAdded:Connect(function(zomb)
        task.wait(0.5)
        if enabled then
            createZombieESP(zomb)
        end
    end)
end

-- ===== DETECTAR NUEVAS CAJAS (RUTA CORREGIDA) =====
local interact = workspace:FindFirstChild("Interact")
if interact then
    interact.ChildAdded:Connect(function(obj)
        task.wait(0.3)
        if enabled and obj.Name == "MysteryBox" then
            createBoxESP(obj)
        end
    end)
end

-- ===== DETECCIÓN DE DISTANCIA DE ZOMBIES =====
RunService.RenderStepped:Connect(function()
    if not enabled then
        AlertText.Visible = false
        return
    end
    
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local baddies = workspace:FindFirstChild("Baddies")
    
    if not hrp or not baddies then
        AlertText.Visible = false
        return
    end
    
    local count = 0
    for _, zomb in ipairs(baddies:GetChildren()) do
        local root = zomb:FindFirstChild("HumanoidRootPart") or zomb:FindFirstChild("Torso")
        if root then
            local dist = (hrp.Position - root.Position).Magnitude
            if dist <= ALERT_DISTANCE then
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
end)

-- ===== TECLA T para activar/desactivar =====
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
