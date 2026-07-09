-- ==========================================
-- ĐỊNH NGHĨA KHỞI ĐẦU
-- ==========================================
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

-- Khai báo các biến lưu trữ kết nối (Event Connections) để quản lý Disconnect
local lightingConnection = nil
local cameraOffsetConnection = nil

-- ==========================================
-- 1. TỐI ƯU ÁNH SÁNG & XÓA FOG (DISCONNECT/RECONNECT)
-- ==========================================
local function applyFullLighting()
    -- Ngắt kết nối ngay lập tức để tránh vòng lặp vô hạn khi thay đổi thuộc tính bên dưới
    if lightingConnection then
        lightingConnection:Disconnect()
        lightingConnection = nil
    end

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

    -- Kết nối lại sau khi đã cập nhật xong toàn bộ thuộc tính
    lightingConnection = Lighting.Changed:Connect(applyFullLighting)
end

-- Chạy thiết lập ánh sáng lần đầu
applyFullLighting()

-- ==========================================
-- 2. CHỐNG RUNG LẮC CAMERA TUYỆT ĐỐI (TỐI ƯU HÓA)
-- ==========================================
local function fixCameraOffset(character)
    -- Dọn dẹp kết nối cũ nếu có nhân vật mới spawn
    if cameraOffsetConnection then
        cameraOffsetConnection:Disconnect()
        cameraOffsetConnection = nil
    end

    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.CameraOffset = Vector3.new(0, 0, 0)
        
        -- Áp dụng Disconnect/Reconnect cho sự kiện thay đổi Offset
        cameraOffsetConnection = humanoid:GetPropertyChangedSignal("CameraOffset"):Connect(function()
            if cameraOffsetConnection then
                cameraOffsetConnection:Disconnect()
                cameraOffsetConnection = nil
            end
            
            humanoid.CameraOffset = Vector3.new(0, 0, 0)
            
            cameraOffsetConnection = humanoid:GetPropertyChangedSignal("CameraOffset"):Connect(arguments.callee or function() end) -- Sử dụng hàm ẩn danh bọc lại hoặc gọi lại chính logic này
        end)
    end
end

if lp.Character then fixCameraOffset(lp.Character) end
lp.CharacterAdded:Connect(fixCameraOffset)

-- Chuyển từ RenderStepped sang vòng lặp task.wait(1) để giảm tải hoàn toàn CPU khi xử lý Camera
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local camera = workspace.CurrentCamera
            if camera and camera.CameraSubject then
                if camera.CameraType == Enum.CameraType.Scriptable then
                    camera.CameraType = Enum.CameraType.Custom
                end
            end
        end)
    end
end)

-- ==========================================
-- 3. TỐI ƯU HIỆU ỨNG (CLIENT - AN TOÀN KHI TREO LÂU)
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
        -- Thay vì dùng Destroy() dễ làm crash script gốc của game, ẩn nó đi bằng thuộc tính Transparency là an toàn nhất khi treo AFK
        v.Transparency = 1
    end
end

-- Dọn dẹp map hiện tại
for _, v in ipairs(workspace:GetDescendants()) do
    cleanObject(v)
end

-- Lắng nghe các vật thể mới được sinh ra
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

-- Dọn bộ nhớ rác định kỳ (Rút ngắn thời gian xuống 30 giây để tối ưu triệt để lượng RAM bị leak)
task.spawn(function()
    while task.wait(30) do
        pcall(function()
            collectgarbage("collect")
        end)
    end
end)
