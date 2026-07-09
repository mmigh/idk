-- =========================================================================
-- SYSTEM CONFIGURATION (GHI ĐÈ PHIÊN BẢN 2.1.0 - OPTIMIZED CONNECTION POOL)
-- =========================================================================
local CURRENT_VERSION = 2.1
_G.ActiveLagReducerVersion = CURRENT_VERSION

local isScriptActive = true
print("[!] ĐÃ THỰC THI BẢN VÁ v" .. CURRENT_VERSION .. " - TỐI ƯU HÓA LUAU CONNECTION POOL (.CHANGED)")

-- 1. Bảng băm tối cao: Quét TẤT CẢ các Class có khả năng hiển thị hiệu ứng hình ảnh
local TARGET_CLASSES = {
    ["ParticleEmitter"] = true, ["Trail"] = true, ["Beam"] = true, 
    ["Fire"] = true, ["Smoke"] = true, ["Sparkles"] = true, ["Explosion"] = true,
    ["Decal"] = true, ["Texture"] = true, ["Highlight"] = true,
    ["Part"] = true, ["MeshPart"] = true, ["SpecialMesh"] = true, 
    ["WedgePart"] = true, ["CornerWedgePart"] = true, ["TrussPart"] = true,
    ["CylinderPart"] = true,
    ["LineHandleAdornment"] = true, ["BoxHandleAdornment"] = true, 
    ["ConeHandleAdornment"] = true, ["CylinderHandleAdornment"] = true,
    ["AnimationTrack"] = true, ["Animator"] = true, ["Animation"] = true
}

-- 2. Bộ từ khóa bao quát toàn bộ các thuật ngữ đặt tên VFX trong engine Roblox
local UNIVERSAL_KEYWORDS = {
    "effect", "vfx", "hit", "skill", "spell", "projectile", "slash", "swing",
    "beam", "blast", "laser", "light", "spark", "thunder", "fire", "aura", 
    "muzzle", "explode", "explosion", "flash", "bullet", "fx", "particle",
    "glow", "shime", "impact", "magical", "energy", "cleave", "burst"
}

-- =========================================================================
-- CORE PROCESS LOGIC (TRIỆT TIÊU HÌNH ẢNH TOÀN DIỆN)
-- =========================================================================
local function forceKillVisual(object)
    if not object or not object.ClassName or not TARGET_CLASSES[object.ClassName] then return end

    pcall(function()
        -- NHÓM 1: Xóa hoàn toàn hệ thống Animation
        if object:IsA("AnimationTrack") then
            object:Stop(0) object:Destroy() return
        elseif object:IsA("Animator") or object:IsA("Animation") then
            object:Destroy() return
        end

        -- NHÓM 2: Hạt đồ họa thuần túy, Khói, Vòng sáng, Vụ nổ -> Xóa sổ vĩnh viễn
        if object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam") 
        or object:IsA("Fire") or object:IsA("Smoke") or object:IsA("Sparkles") 
        or object:IsA("Explosion") or object:IsA("Decal") or object:IsA("Texture") 
        or object:IsA("Highlight") then
            object:Destroy()
            return
        end
        
        -- NHÓM 3: Các tia đạn vẽ bằng Adornment -> Ép ẩn ngay
        if object:IsA("HandleAdornment") then
            object.Visible = false
            return
        end

        -- NHÓM 4: Khối vật lý 3D -> Ép tàng hình khởi tạo
        if object:IsA("BasePart") then
            local isVFX = false
            
            if object.Material == Enum.Material.Neon or object.Transparency >= 0.4 then
                isVFX = true
            else
                local txt = (object.Name .. "\0" .. (object.Parent and object.Parent.Name or "")):lower()
                for _, kw in ipairs(UNIVERSAL_KEYWORDS) do
                    if txt:find(kw, 1, true) then isVFX = true break end
                end
            end
            
            if isVFX then
                object.Transparency = 1
                object.Material = Enum.Material.SmoothPlastic
                local mesh = object:FindFirstChildOfClass("SpecialMesh")
                if mesh then mesh.Scale = Vector3.new(0, 0, 0) end
            end
        end
    end)
end

-- =========================================================================
-- PASSIVE PROPERTY LOCK (GỘP SỰ KIỆN .CHANGED TỐI ƯU HÓA KẾT NỐI BỘ NHỚ)
-- =========================================================================
local function bindPropertyLock(object)
    if not isScriptActive then return end
    
    if object:IsA("HandleAdornment") then
        object:GetPropertyChangedSignal("Visible"):Connect(function()
            if isScriptActive and object.Visible then object.Visible = false end
        end)
        
    elseif object:IsA("BasePart") then
        -- Gộp 2 luồng lắng nghe thành 1 cổng duy nhất dựa trên giải pháp tối ưu của bạn
        object.Changed:Connect(function(prop)
            if not isScriptActive then return end
            
            if prop == "Transparency" then
                if object.Transparency < 1 and (object.Material == Enum.Material.Neon or object.Transparency >= 0.4) then
                    object.Transparency = 1
                end
            elseif prop == "Material" then
                if object.Material == Enum.Material.Neon then
                    object.Material = Enum.Material.SmoothPlastic
                end
            end
        end)
    end
end

-- =========================================================================
-- ĐÁNH CHẶN TOÀN BỘ KHO CHỨA (REPLICATEDSTORAGE)
-- =========================================================================
local function purgeAllStorage()
    local repStorage = game:GetService("ReplicatedStorage")
    
    for _, desc in ipairs(repStorage:GetDescendants()) do
        forceKillVisual(desc)
        pcall(bindPropertyLock, desc)
    end
    
    repStorage.DescendantAdded:Connect(function(newObj)
        if _G.ActiveLagReducerVersion ~= CURRENT_VERSION then return end
        forceKillVisual(newObj)
        pcall(bindPropertyLock, newObj)
    end)
end

task.spawn(purgeAllStorage)

-- =========================================================================
-- ĐĂNG KÝ VÙNG QUÉT KHÔNG LAG CHO WORKSPACE VÀ CAMERA (EVENT-DRIVEN)
-- =========================================================================
local regionsToScan = {workspace, game:GetService("Lighting")}
local camera = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")
if camera then table.insert(regionsToScan, camera) end

local localPlayer = game:GetService("Players").LocalPlayer

for _, folder in ipairs(regionsToScan) do
    for _, desc in ipairs(folder:GetDescendants()) do
        if not (localPlayer and localPlayer.Character and desc:IsDescendingFrom(localPlayer.Character)) then
            forceKillVisual(desc)
            pcall(bindPropertyLock, desc)
        end
    end
    
    folder.DescendantAdded:Connect(function(newObject)
        if _G.ActiveLagReducerVersion ~= CURRENT_VERSION then isScriptActive = false return end
        if localPlayer and localPlayer.Character and newObject:IsDescendingFrom(localPlayer.Character) then return end
        
        forceKillVisual(newObject)
        pcall(bindPropertyLock, newObject)
    end)
end

print("[+] Bản vá v" .. CURRENT_VERSION .. " đã hoàn thành tối ưu hóa cấu trúc Luau connection. RAM và CPU hoạt động mượt mà!")
