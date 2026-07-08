-- =========================================================================
-- SYSTEM CONFIGURATION (GHI ĐÈ PHIÊN BẢN 1.2)
-- =========================================================================
local CURRENT_VERSION = 1.2
_G.ActiveLagReducerVersion = CURRENT_VERSION -- Kích hoạt lệnh tự hủy của bản 1.1

local isScriptActive = true
print("[!] ĐÃ THỰC THI BẢN VÁ v" .. CURRENT_VERSION .. " - CHẾ ĐỘ XOÁ TẬN GỐC (HARD DESTROY)")

-- =========================================================================
-- HARD DESTROY LOGIC (CƯỠNG BỨC XOÁ BỎ)
-- =========================================================================
local function hardKillEffect(object)
    if not isScriptActive then return end
    
    pcall(function()
        -- Danh sách các loại đối tượng đồ hoạ gây lag nặng nhất
        if object:IsA("ParticleEmitter") 
        or object:IsA("Trail") 
        or object:IsA("Beam") 
        or object:IsA("Fire") 
        or object:IsA("Smoke") 
        or object:IsA("Sparkles") 
        or object:IsA("Explosion") then
            
            -- Thay vì tắt (Enabled = false) không hiệu quả, ta XOÁ HẲN ra khỏi bộ nhớ game
            object:Destroy()
        end
        
        -- Xử lý các khối 3D, Mesh mô phỏng chiêu thức phóng ra
        if object:IsA("BasePart") or object:IsA("MeshPart") or object:IsA("SpecialMesh") then
            local nameLower = object.Name:lower()
            local parentNameLower = (object.Parent and object.Parent.Name or ""):lower()
            
            -- Lọc chính xác các từ khoá liên quan đến chiêu thức/hiệu ứng
            if nameLower:find("effect") or nameLower:find("vfx") or nameLower:find("hit")
            or parentNameLower:find("skill") or parentNameLower:find("vfx") or nameLower:find("spell") 
            or nameLower:find("projectile") or nameLower:find("slash") then
                
                object:Destroy() -- Cắt bỏ hoàn toàn quá trình Render của Card đồ hoạ
            end
        end
    end)
end

-- =========================================================================
-- QUÉT TOÀN DIỆN VÀ THEO DÕI LIÊN TỤC
-- =========================================================================
local regionsToScan = {
    workspace,
    game:GetService("ReplicatedStorage"),
    game:GetService("Lighting") -- Một số game giấu hiệu ứng trong Lighting rồi nhân bản ra
}

local localPlayer = game:GetService("Players").LocalPlayer
if localPlayer then
    local camera = workspace.CurrentCamera or localPlayer:FindFirstChild("Camera")
    if camera then table.insert(regionsToScan, camera) end
    
    -- Quét cả các hiệu ứng dính trên người nhân vật (gây lag khi di chuyển/vận công)
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    if character then table.insert(regionsToScan, character) end
end

-- Bắt đầu thực thi vòng quét
for _, folder in ipairs(regionsToScan) do
    -- 1. Quét sạch các hiệu ứng đang tồn tại
    for _, desc in ipairs(folder:GetDescendants()) do
        hardKillEffect(desc)
    end
    
    -- 2. Đón đầu và tiêu diệt ngay khi chiêu thức vừa xuất hiện
    folder.DescendantAdded:Connect(function(newObject)
        if _G.ActiveLagReducerVersion ~= CURRENT_VERSION then 
            isScriptActive = false -- Tự động nhường chỗ nếu có bản 1.3
            return 
        end
        
        -- Dùng lập trình bất đồng bộ (Fast Defer) để xóa ngay khi object vừa được nạp vào game
        task.defer(function()
            hardKillEffect(newObject)
        end)
    end)
end

print("[+] Bản vá v" .. CURRENT_VERSION .. " đã chạy ngầm. Hãy thử tung chiêu để kiểm tra.")
