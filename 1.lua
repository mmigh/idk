-- ==========================================
-- ĐỊNH NGHĨA KHỞI ĐẦU
-- ==========================================
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ==========================================
-- 1. TỐI ƯU ÁNH SÁNG & XÓA FOG
-- ==========================================
local function applyFullLighting()
    pcall(function()
        Lighting.ClockTime = 14
        Lighting.GeographicLatitude = 23.5
        Lighting.Brightness = 2
        Lighting.ExposureCompensation = 0.5 
        Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 140) 
        Lighting.Ambient = Color3.fromRGB(140, 140, 140)
        Lighting.GlobalShadows = false
        Lighting.FogStart = 999999
        Lighting.FogEnd = 999999
        
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("Atmosphere") or effect:IsA("BlurEffect") or effect:IsA("DepthOfFieldEffect") then
                effect:Destroy()
            elseif effect:IsA("ColorCorrectionEffect") then
                effect.Brightness = 0
                effect.Contrast = 0
                effect.Saturation = 0
                effect.TintColor = Color3.fromRGB(255, 255, 255)
            end
        end
    end)
end

applyFullLighting()
Lighting.Changed:Connect(applyFullLighting)

-- ==========================================
-- 2. CHỐNG RUNG LẮC CAMERA TUYỆT ĐỐI (CẬP NHẬT)
-- ==========================================
local function fixCameraOffset(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        -- Cách 1: Khóa Offset của Humanoid
        humanoid.CameraOffset = Vector3.new(0, 0, 0)
        humanoid:GetPropertyChangedSignal("CameraOffset"):Connect(function()
            humanoid.CameraOffset = Vector3.new(0, 0, 0)
        end)
    end
end

if lp.Character then fixCameraOffset(lp.Character) end
lp.CharacterAdded:Connect(fixCameraOffset)

-- Cách 2: Chặn script của Game cố tình làm lắc CurrentCamera bằng RenderStepped
RunService.RenderStepped:Connect(function()
    pcall(function()
        if camera and camera.CameraSubject then
            -- Nếu game đổi kiểu camera sang Scriptable để tự lắc, ta ép nó về Custom (mặc định)
            if camera.CameraType == Enum.CameraType.Scriptable then
                camera.CameraType = Enum.CameraType.Custom
            end
        end
    end)
end)

-- ==========================================
-- 3. TỐI ƯU HIỆU ỨNG (CLIENT)
-- ==========================================
pcall(function()
    local terrain = workspace:FindFirstChild("Terrain")
    if terrain then
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
    end
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end)

local function cleanObject(v)
    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
        v.Enabled = false
        v.Rate = 0
    elseif v:IsA("Sound") and v.Parent ~= lp.Character then
        v.Volume = 0
        v.Playing = false
    elseif v:IsA("Decal") or v:IsA("Texture") then
        v:Destroy()
    end
end

for _, v in ipairs(workspace:GetDescendants()) do
    cleanObject(v)
end

workspace.DescendantAdded:Connect(function(v)
    pcall(cleanObject, v)
end)

-- ==========================================
-- 4. TỐI ƯU SIMULATION RADIUS
-- ==========================================
task.spawn(function()
    while task.wait(5) do
        pcall(function()
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                sethiddenproperty(lp, "SimulationRadius", 300)
                sethiddenproperty(lp, "MaximumSimulationRadius", 300)
            end
        end)
    end
end)

-- ==========================================
-- 5. ANTI-BAN (HOOK NAME CALL)
-- ==========================================
local oldNamecall
pcall(function()
    local mt = getrawmetatable(game)
    if mt then
        oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" and self.Name == "TeleportDetect" then
                return
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end
end)

-- Dọn bộ nhớ rác định kỳ
task.spawn(function()
    while task.wait(120) do
        pcall(collectgarbage, "collect")
    end
end)
