-- Khai báo các Service hệ thống
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

-- ====================================================================
-- 1. TỰ ĐỘNG TỐI ƯU GIẢM 80% ĐỒ HỌA & XÓA HIỆU ỨNG NẶNG
-- ====================================================================
for _, v in pairs(game:GetDescendants()) do
    pcall(function()
        if v:IsA("Trail") or v:IsA("Beam") or v:IsA("Explosion") then
            v:Destroy()
        elseif v:IsA("ParticleEmitter") then
            v.Enabled = false
            v.LightEmission = 0
            v.Rate = v.Rate * 0.2
            v.Lifetime = NumberRange.new(0.1)
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 0.6
        elseif v:IsA("MeshPart") or v:IsA("UnionOperation") or v:IsA("Part") then
            if v.Name ~= "Head" and v.Name ~= "HumanoidRootPart" then
                v.Material = Enum.Material.SmoothPlastic
                v.CastShadow = false
                v.Reflectance = 0
            end
        end
    end)
end

-- ====================================================================
-- 2. CẤU HÌNH LIGHTING (ÁNH SÁNG) NHẸ & BẬT FULL BRIGHT (SÁNG ĐÊM)
-- ====================================================================
pcall(function()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1e10
    Lighting.Brightness = 1
    Lighting.ClockTime = 14
    Lighting.EnvironmentDiffuseScale = 0.1
    Lighting.EnvironmentSpecularScale = 0.1
    Lighting.OutdoorAmbient = Color3.fromRGB(110, 110, 110)
    
    -- Bật Full Bright tự động giúp nhìn rõ mọi ngóc ngách
    Lighting.Ambient = Color3.new(1, 1, 1)
    Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
    Lighting.ColorShift_Top = Color3.new(1, 1, 1)

    -- Xóa sương mù mặc định của game (Sky Fog)
    if Lighting:FindFirstChild("LightingLayers") then Lighting.LightingLayers:Destroy() end
    if Lighting:FindFirstChild("SeaTerrorCC") then Lighting.SeaTerrorCC:Destroy() end
    if Lighting:FindFirstChild("FantasySky") then Lighting.FantasySky:Destroy() end

    -- Tắt các hiệu ứng hình ảnh nâng cao gây lag
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("BloomEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("SunRaysEffect") then
            effect.Enabled = false
        end
    end
end)

-- ====================================================================
-- 3. TỐI ƯU CẤU HÌNH ĐỊA HÌNH TERRAIN VÀ CHẤT LƯỢNG ĐỒ HỌA ROBLOX
-- ====================================================================
if Terrain then
    pcall(function()
        Terrain.WaterWaveSize = 0.2
        Terrain.WaterWaveSpeed = 0.5
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0.9
    end)
end

pcall(function()
    -- Đặt chất lượng hiển thị hệ thống về mức thấp để tăng FPS tối đa
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level02
    
    -- Kích hoạt chế độ Low CPU (Giảm tải vi xử lý)
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    setfpscap(30) -- Giới hạn FPS ở mức 30 để máy không bị nóng/quá tải CPU
end)

-- ====================================================================
-- 4. TỰ ĐỘNG HIỂN THỊ BẢNG ĐẾM FPS Ở GÓC TRÁI MÀN HÌNH
-- ====================================================================
local fpsGui = Instance.new("ScreenGui")
fpsGui.Name = "FPS_Display_80"

-- Thử đưa vào CoreGui, nếu dùng Exploit không hỗ trợ sẽ tự chuyển vào PlayerGui
local success, err = pcall(function() fpsGui.Parent = game.CoreGui end)
if not success then 
    fpsGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") 
end

local fpsLabel = Instance.new("TextLabel", fpsGui)
fpsLabel.Position = UDim2.new(0, 10, 0, 40) -- Đẩy xuống một chút để không đè nút menu mặc định của Roblox
fpsLabel.Size = UDim2.new(0, 120, 0, 30)
fpsLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
fpsLabel.BackgroundTransparency = 0.4
fpsLabel.TextColor3 = Color3.new(1, 1, 1)
fpsLabel.Font = Enum.Font.Code
fpsLabel.TextSize = 18
fpsLabel.Text = "FPS: ..."
fpsLabel.TextXAlignment = Enum.TextXAlignment.Center

local lastTime = tick()
local frames = 0

RunService.RenderStepped:Connect(function()
    frames += 1
    if tick() - lastTime >= 1 then
        fpsLabel.Text = "FPS: " .. frames
        frames = 0
        lastTime = tick()
    end
end)
