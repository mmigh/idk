-- ==========================================
-- ĐỊNH NGHĨA KHỞI ĐẦU (SỬA LỖI KHAI BÁO)
-- ==========================================
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local lp = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ==========================================
-- 1. TẬP TRUNG TỐI ƯU ÁNH SÁNG, TRỜI SÁNG & XÓA FOG
-- ==========================================
local function applyFullLighting()
    pcall(function()
        Lighting.ClockTime = 14 -- 2 giờ chiều, sáng tự nhiên không bị lóa gắt
        Lighting.GeographicLatitude = 23.5
        Lighting.Brightness = 2 -- Độ sáng vừa đủ nhìn rõ
        Lighting.ExposureCompensation = 0.5 
        
        -- Màu sắc trung tính, triệt tiêu bóng tối hoàn toàn nhưng không bị trắng xóa màn hình
        Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 140) 
        Lighting.Ambient = Color3.fromRGB(140, 140, 140)
        
        Lighting.GlobalShadows = false -- Tắt bóng đổ (Tăng FPS cực mạnh)
        Lighting.FogStart = 999999
        Lighting.FogEnd = 999999
        
        -- Dọn sạch các hiệu ứng Atmosphere gây sương mù dày đặc và Blur làm mờ mắt
        for _, effect in pairs(Lighting:GetChildren()) do
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
-- 2. CHỐNG RUNG CAMERA AN TOÀN (KHÔNG LẮC KHUNG HÌNH)
-- ==========================================
local function fixCameraOffset(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.CameraOffset = Vector3.new(0, 0, 0)
        humanoid:GetPropertyChangedSignal("CameraOffset"):Connect(function()
            humanoid.CameraOffset = Vector3.new(0, 0, 0)
        end)
    end
end

if lp.Character then fixCameraOffset(lp.Character) end
lp.CharacterAdded:Connect(fixCameraOffset)

-- ==========================================
-- 3. FIX LAG SIÊU NHẸ (CHỈ CLIENT)
-- ==========================================
-- Tắt hiệu ứng nước (giảm CPU)
pcall(function()
    local terrain = workspace:FindFirstChild("Terrain")
    if terrain then
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
    end
end)

-- Set chất lượng đồ họa thấp nhất
pcall(function()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end)

-- ==========================================
-- 4. DỌN DẸP HIỆU ỨNG RÁC (CHẠY NGẦM)
-- ==========================================
task.spawn(function()
    while task.wait(5) do
        pcall(function()
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                    v.Enabled = false
                    v.Rate = 0
                elseif v:IsA("Sound") and v.Parent ~= lp.Character then
                    v.Volume = 0
                    v.Playing = false
                end
            end
        end)
    end
end)

-- ==========================================
-- 5. TỐI ƯU CHO MÁY YẾU / KHÓA FPS
-- ==========================================
local targetFPS = 60
local lastTime = tick()
RunService.RenderStepped:Connect(function()
    local currentTime = tick()
    local delta = currentTime - lastTime
    
    if delta < 1/targetFPS then
        task.wait(1/targetFPS - delta)
    end
    
    lastTime = currentTime
end)

-- Giảm simulation radius (tránh load quá nhiều object ở xa)
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            local char = lp.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                sethiddenproperty(lp, "SimulationRadius", 300)
                sethiddenproperty(lp, "MaximumSimulationRadius", 300)
            end
        end)
    end
end)

-- ==========================================
-- 6. HOOK ANTI BAN & CHỐNG AFK
-- ==========================================
lp.Idled:Connect(function()
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end)

local oldNamecall
pcall(function()
    local mt = getrawmetatable(game)
    if not mt then return end
    
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
end)

-- Fake movement nhẹ (tránh anti-cheat phát hiện đứng im)
task.spawn(function()
    while task.wait(10) do
        pcall(function()
            local char = lp.Character
            if char and char:FindFirstChild("Humanoid") then
                if char.Humanoid.MoveDirection.Magnitude < 0.1 then
                    char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.05)
                    char.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
                end
            end
        end)
    end
end)

-- ==========================================
-- 7. TẮT DECAL XA (GIẢM VRAM)
-- ==========================================
task.spawn(function()
    while task.wait(3) do
        pcall(function()
            local char = lp.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Decal") or v:IsA("Texture") then
                    if v.Parent and v.Parent:IsA("BasePart") then
                        local dist = (v.Parent.Position - char.HumanoidRootPart.Position).Magnitude
                        if dist > 150 then
                            v.Transparency = 1
                        else
                            v.Transparency = 0
                        end
                    end
                end
            end
        end)
    end
end)

-- Dọn bộ nhớ rác định kỳ
task.spawn(function()
    while task.wait(60) do
        pcall(collectgarbage, "collect")
    end
end)

print("Đã kích hoạt bản gộp: Siêu mượt, Trời sáng dịu mắt, Không sương mù, Không rung lắc!")
