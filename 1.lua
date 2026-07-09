-- ==========================================
-- ĐỊNH NGHĨA KHỞI ĐẦU
-- ==========================================
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

-- ==========================================
-- 1 & 2. HOOK METATABLE - TỐI ƯU TỐC ĐỘ (MICRO-OPTIMIZATION)
-- ==========================================
pcall(function()
    local mt = getrawmetatable(game)
    local oldNewIndex = mt.__newindex
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    
    -- Sắp xếp điều kiện thông dụng lên trước để giảm thiểu tối đa overhead cho game
    mt.__newindex = newcclosure(function(self, idx, val)
        if idx == "CameraOffset" and self:IsA("Humanoid") then
            return -- Thoát nhanh cho thuộc tính Camera, chống rung lắc tuyệt đối
        elseif self == Lighting and (idx == "ClockTime" or idx == "FogStart" or idx == "FogEnd" or idx == "GlobalShadows" or idx == "Brightness") then
            return -- Đóng băng các thông số ánh sáng tối ưu
        end
        return oldNewIndex(self, idx, val)
    end)
    
    -- Chặn các hàm gửi từ Game (Anti-Ban)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and self.Name == "TeleportDetect" then
            return
        end
        return oldNamecall(self, ...)
    end)
    
    setreadonly(mt, true)
end)

-- Thiết lập cứng cấu hình ban đầu một lần duy nhất trước khi bị Metatable khóa lại
pcall(function()
    Lighting.ClockTime = 14
    Lighting.Brightness = 2
    Lighting.GlobalShadows = false
    Lighting.FogStart = 999999
    Lighting.FogEnd = 999999
    Lighting.ExposureCompensation = 0.5 
    Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 140) 
    Lighting.Ambient = Color3.fromRGB(140, 140, 140)
    
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

-- Cấu hình Camera ban đầu cho Nhân vật
local function setupCameraAndCharacter(character)
    pcall(function()
        local humanoid = character:WaitForChild("Humanoid", 5)
        if humanoid then
            humanoid.CameraOffset = Vector3.new(0, 0, 0)
        end
        local camera = workspace.CurrentCamera
        if camera then
            camera.CameraType = Enum.CameraType.Custom
        end
    end)
end

if lp.Character then setupCameraAndCharacter(lp.Character) end
lp.CharacterAdded:Connect(setupCameraAndCharacter)

-- ==========================================
-- 3. TỐI ƯU HIỆU ỨNG & QUẢN LÝ KẾT NỐI (ANTI-LEAK RAM)
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
        v.Transparency = 1
    end
end

-- Dọn dẹp map hiện tại lúc thực thi script
for _, v in ipairs(workspace:GetDescendants()) do
    cleanObject(v)
end

-- Quản lý kết nối sự kiện dọn dẹp để có thể ngắt kết nối khi chuyển map
local descendantConnection
descendantConnection = workspace.DescendantAdded:Connect(function(v)
    local success = pcall(cleanObject, v)
    if not success and not workspace then
        if descendantConnection then
            descendantConnection:Disconnect()
            descendantConnection = nil
        end
    end
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
-- 5. DỌN BỘ NHỚ RÁC ĐỊNH KỲ
-- ==========================================
task.spawn(function()
    while task.wait(30) do
        pcall(collectgarbage, "collect")
    end
end)
