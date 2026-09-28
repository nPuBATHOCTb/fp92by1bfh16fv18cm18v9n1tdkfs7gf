--[[
    ============================================================
      Aurora Legit Bot v3.1 for BloxStrike
      Aimbot · Trigger · Bhop · Strafer · Anti-Aim · FOV · Viewmodel · ESP
      C=aim  V=trigger  X=bhop  Z=strafer  B=anti-aim  RShift=menu
    ============================================================
]]

(function()

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local RS       = game:GetService("RunService")
local TS       = game:GetService("TweenService")
local SG       = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local WS       = game:GetService("Workspace")
local LP       = Players.LocalPlayer
local Cam      = WS.CurrentCamera
local VIM      = game:GetService("VirtualInputManager")

do
    local rem = {}
    for _, svc in ipairs({ game:GetService("CoreGui"), LP:WaitForChild("PlayerGui") }) do
        pcall(function()
            for _, c in ipairs(svc:GetChildren()) do
                if c.Name:sub(1,7) == "Aurora_" then table.insert(rem, c) end
            end
        end)
    end
    if gethui then
        pcall(function()
            for _, c in ipairs(gethui():GetChildren()) do
                if c.Name:sub(1,7) == "Aurora_" then table.insert(rem, c) end
            end
        end)
    end
    for _, o in ipairs(rem) do pcall(function() o:Destroy() end) end
end

local function getParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    return LP:WaitForChild("PlayerGui")
end
local PARENT = getParent()

local CLR = {
    bg=Color3.fromRGB(10,16,32), panel=Color3.fromRGB(19,26,46),
    panel_hi=Color3.fromRGB(26,35,64), element=Color3.fromRGB(31,42,72),
    element_hi=Color3.fromRGB(42,55,87), border=Color3.fromRGB(58,72,112),
    text=Color3.fromRGB(237,239,247), text_dim=Color3.fromRGB(138,148,184),
    accent1=Color3.fromRGB(125,211,192), accent1_hi=Color3.fromRGB(160,229,212),
    accent1_dk=Color3.fromRGB(75,168,149), accent2=Color3.fromRGB(255,177,92),
    accent2_hi=Color3.fromRGB(255,201,137), accent2_dk=Color3.fromRGB(204,138,56),
    green=Color3.fromRGB(82,214,122), red=Color3.fromRGB(255,107,123),
    yellow=Color3.fromRGB(255,217,61), track=Color3.fromRGB(38,48,76),
}
local FONT       = Enum.Font.Gotham
local FONT_B     = Enum.Font.GothamBold
local FONT_M     = Enum.Font.GothamMedium
local FONT_BLACK = Enum.Font.GothamBlack

local Config = {
    -- AIM
    aim_enabled=false, aim_key=Enum.KeyCode.C, aim_mode="Hold",
    smooth=4, max_fov=500, bone="Head", team_check=true, friend_check=true, max_step=30,

    -- TRIGGER
    trigger_enabled=false, trigger_key=Enum.KeyCode.V, trigger_mode="Hold",
    trigger_delay=60, trigger_fov=30,

    -- BHOP
    bhop_enabled=false, bhop_key=Enum.KeyCode.X, bhop_mode="Auto",

    -- STRAFER
    strafer_enabled=false, strafer_key=Enum.KeyCode.Z,
    strafe_turn_speed=6, strafe_switch_interval=0.15, strafe_min_speed=5,

    -- ANTI-AIM
    aa_enabled=false, aa_key=Enum.KeyCode.B, aa_mode="Jitter",
    aa_speed=15, aa_jitter_amount=45, aa_static_yaw=180,

    -- FOV
    fov_changer=false, fov_value=90,

    -- VIEWMODEL
    vm_enabled=false,
    vm_offset_x=0, vm_offset_y=0, vm_offset_z=0,
    vm_rot_x=0, vm_rot_y=0, vm_rot_z=0,

    -- ESP
    esp_enabled=false, esp_box=true, esp_box_style="Full",
    esp_box_fill_alpha=0.15, esp_name=true, esp_dist=true, esp_hp=true,
    esp_skeleton=false, esp_snapline=false, esp_head_dot=false,
    esp_chams=false, esp_chams_fill_alpha=0.5, esp_offscreen=false,
    esp_max_dist=1000,
    esp_enemy_color=Color3.fromRGB(255,80,80), esp_ally_color=Color3.fromRGB(80,220,120),

    -- VISUAL
    fov_circle=true, fov_color=Color3.fromRGB(125,211,192),
    crosshair=false, crosshair_color=Color3.fromRGB(125,211,192),
    crosshair_size=8, crosshair_gap=5, crosshair_thick=1, crosshair_dot=true,
    watermark=true,

    -- MENU
    menu_key=Enum.KeyCode.RightShift, blur=true,
}

local State = {
    open=false, busy=false, aim_active=false, strafing=false, enemies=0,
    locked=false, trigging=false, bhopping=false, hops=0, hits=0, fps=60,
}

local KeyState = { aim=false, trigger=false, bhop=false, strafer=false, aa=false }

local function corner(p, r)
    local c = Instance.new("UICorner", p); c.CornerRadius = UDim.new(0, r or 8); return c
end
local function stroke(p, c, t, tr)
    local s = Instance.new("UIStroke", p)
    s.Color = c or CLR.border; s.Thickness = t or 1
    s.Transparency = tr or 0.3; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end
local function tween(o, p, tg, ti, st, dir)
    local tw = TS:Create(o, TweenInfo.new(ti or 0.15, st or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), {[p] = tg})
    tw:Play(); return tw
end
local function notif(text, dur)
    pcall(function() SG:SetCore("SendNotification", {Title="Aurora Legit", Text=tostring(text), Duration=dur or 2}) end)
end

-- ============================================================
--  KEYBIND HANDLER
-- ============================================================
RS.RenderStepped:Connect(function()
    local aimDown = UIS:IsKeyDown(Config.aim_key)
    if Config.aim_mode == "Hold" then
        Config.aim_enabled = aimDown
    else
        if aimDown and not KeyState.aim then
            Config.aim_enabled = not Config.aim_enabled; KeyState.aim = true
        elseif not aimDown then KeyState.aim = false end
    end

    local trigDown = UIS:IsKeyDown(Config.trigger_key)
    if Config.trigger_mode == "Hold" then
        Config.trigger_enabled = trigDown
    else
        if trigDown and not KeyState.trigger then
            Config.trigger_enabled = not Config.trigger_enabled
            notif("Trigger: " .. (Config.trigger_enabled and "ON" or "OFF"), 1.5)
            KeyState.trigger = true
        elseif not trigDown then KeyState.trigger = false end
    end

    local bhopDown = UIS:IsKeyDown(Config.bhop_key)
    if bhopDown and not KeyState.bhop then
        Config.bhop_enabled = not Config.bhop_enabled
        notif("Bhop: " .. (Config.bhop_enabled and "ON" or "OFF"), 1.5)
        KeyState.bhop = true
    elseif not bhopDown then KeyState.bhop = false end

    local straferDown = UIS:IsKeyDown(Config.strafer_key)
    if straferDown and not KeyState.strafer then
        Config.strafer_enabled = not Config.strafer_enabled
        notif("Strafer: " .. (Config.strafer_enabled and "ON" or "OFF"), 1.5)
        KeyState.strafer = true
    elseif not straferDown then KeyState.strafer = false end

    local aaDown = UIS:IsKeyDown(Config.aa_key)
    if aaDown and not KeyState.aa then
        Config.aa_enabled = not Config.aa_enabled
        if not Config.aa_enabled then
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local bg = hrp:FindFirstChild("Aurora_AA_BG")
                if bg then bg:Destroy() end
            end
        end
        notif("Anti-Aim: " .. (Config.aa_enabled and "ON" or "OFF"), 1.5)
        KeyState.aa = true
    elseif not aaDown then KeyState.aa = false end
end)

-- ============================================================
--  AIM CORE
-- ============================================================
local MOVE_FN = nil
if mousemoverel then MOVE_FN = mousemoverel
elseif mouse_move_rel then MOVE_FN = mouse_move_rel end

local function getTeam(plr)
    local ok, v = pcall(function() return plr:GetAttribute("Team") end)
    return ok and v or nil
end
local function sameTeam(a, b)
    local ta, tb = getTeam(a), getTeam(b)
    return ta and tb and ta == tb
end
local function isFriend(plr)
    if not Config.friend_check then return false end
    local ok, res = pcall(function() return LP:IsFriendsWith(plr.UserId) end)
    return ok and res
end
local function shouldSkip(plr)
    if plr == LP then return true end
    if Config.team_check and sameTeam(LP, plr) then return true end
    if isFriend(plr) then return true end
    return false
end
local function getBone(plr)
    local ch = plr.Character
    if not ch then return nil end
    if Config.bone == "Torso" then
        return ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso") or ch:FindFirstChild("Head")
    end
    return ch:FindFirstChild("Head")
end
local function findTargetScreen(fov)
    fov = fov or Config.max_fov
    local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
    local best, bestD, bestPos = nil, fov, nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if not shouldSkip(plr) then
            local bone = getBone(plr)
            if bone and bone:IsA("BasePart") then
                local sp, on = Cam:WorldToViewportPoint(bone.Position)
                if on and sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < bestD then bestD = d; best = plr; bestPos = Vector2.new(sp.X, sp.Y) end
                end
            end
        end
    end
    return best, bestPos
end
local function countEnemies()
    local n = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if not shouldSkip(plr) and plr.Character and plr.Character:FindFirstChild("Head") then
            n = n + 1
        end
    end
    return n
end

RS.RenderStepped:Connect(function(dt)
    State.aim_active = Config.aim_enabled and MOVE_FN ~= nil
    State.enemies = countEnemies()
    if not State.aim_active then State.locked = false; return end
    local target, screenPos = findTargetScreen()
    if not target or not screenPos then State.locked = false; return end
    local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
    local dx = screenPos.X - center.X
    local dy = screenPos.Y - center.Y
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist < 3 then State.locked = true; return end
    local speed = math.clamp(dt * 60 / math.max(Config.smooth, 1), 0, 1)
    local moveX = dx * speed
    local moveY = dy * speed
    local maxStep = Config.max_step
    if math.abs(moveX) > maxStep then moveX = maxStep * (moveX > 0 and 1 or -1) end
    if math.abs(moveY) > maxStep then moveY = maxStep * (moveY > 0 and 1 or -1) end
    pcall(MOVE_FN, moveX, moveY)
    State.locked = true
end)

-- ============================================================
--  TRIGGER
-- ============================================================
local lastTrig = 0
local function fireMouse()
    if mouse1click then mouse1click() return end
    if VIM then
        VIM:SendMouseButtonEvent(0,0,0,true,game,0)
        task.wait(0.008)
        VIM:SendMouseButtonEvent(0,0,0,false,game,0)
    end
end
task.spawn(function()
    while true do
        task.wait(0.01)
        State.trigging = false
        if Config.trigger_enabled then
            if tick() - lastTrig >= Config.trigger_delay / 1000 then
                local target = findTargetScreen(Config.trigger_fov)
                if target then
                    fireMouse()
                    State.hits = State.hits + 1
                    lastTrig = tick()
                    State.trigging = true
                end
            end
        end
    end
end)

-- ============================================================
--  BHOP
-- ============================================================
local lastHop = 0
local function tryBhop()
    State.bhopping = false
    if not Config.bhop_enabled then return end
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if Config.bhop_mode == "Auto" then
        if not UIS:IsKeyDown(Enum.KeyCode.Space) then return end
    end
    if tick() - lastHop < 0.06 then return end
    lastHop = tick()
    pcall(function()
        VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        task.wait(0.008)
        VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.008)
        VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end)
    State.bhopping = true
    State.hops = State.hops + 1
end
RS.Heartbeat:Connect(function() pcall(tryBhop) end)

-- ============================================================
--  STRAFER
-- ============================================================
local strafe_state = { side=1, last_switch=0, keys_down={A=false, D=false} }
local function setStrafeKey(key, down)
    if strafe_state.keys_down[key] == down then return end
    strafe_state.keys_down[key] = down
    pcall(function()
        VIM:SendKeyEvent(down, key == "A" and Enum.KeyCode.A or Enum.KeyCode.D, false, game)
    end)
end
local function releaseAllStrafe()
    setStrafeKey("A", false); setStrafeKey("D", false)
end
local function tryAutoStrafer(dt)
    State.strafing = false
    if not Config.strafer_enabled then releaseAllStrafe(); return end
    if State.aim_active and State.locked then releaseAllStrafe(); return end
    local char = LP.Character
    if not char then releaseAllStrafe(); return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then releaseAllStrafe(); return end
    if tick() - strafe_state.last_switch > Config.strafe_switch_interval then
        strafe_state.last_switch = tick()
        strafe_state.side = -strafe_state.side
        if strafe_state.side == 1 then
            setStrafeKey("A", false); setStrafeKey("D", true)
        else
            setStrafeKey("D", false); setStrafeKey("A", true)
        end
    end
    if MOVE_FN then
        local turn = Config.strafe_turn_speed * strafe_state.side * dt * 60
        if turn > 15 then turn = 15 end
        if turn < -15 then turn = -15 end
        pcall(MOVE_FN, turn, 0)
    end
    State.strafing = true
end
RS.RenderStepped:Connect(function(dt) pcall(function() tryAutoStrafer(dt) end) end)

-- ============================================================
--  ANTI-AIM
-- ============================================================
local aa_state = { angle=0, jitter_side=1, last_jitter=0 }
local function tryAntiAim(dt)
    if not Config.aa_enabled then return end
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local bg = hrp:FindFirstChild("Aurora_AA_BG") or Instance.new("BodyGyro", hrp)
    bg.Name = "Aurora_AA_BG"
    bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    bg.P = 1e5

    if Config.aa_mode == "Spin" then
        aa_state.angle = aa_state.angle + Config.aa_speed * dt
        if aa_state.angle > math.pi * 2 then aa_state.angle = aa_state.angle - math.pi * 2 end
        bg.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, aa_state.angle, 0)
    elseif Config.aa_mode == "Jitter" then
        if tick() - aa_state.last_jitter > 0.08 then
            aa_state.last_jitter = tick()
            aa_state.jitter_side = -aa_state.jitter_side
        end
        local offset = math.rad(Config.aa_jitter_amount) * aa_state.jitter_side
        bg.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, offset, 0)
    elseif Config.aa_mode == "Static" then
        bg.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(Config.aa_static_yaw), 0)
    end
end
RS.RenderStepped:Connect(function(dt) pcall(function() tryAntiAim(dt) end) end)

-- ============================================================
--  FOV CHANGER
-- ============================================================
local orig_fov = Cam and Cam.FieldOfView or 70
local function applyFov()
    if not Cam then return end
    if Config.fov_changer then
        Cam.FieldOfView = Config.fov_value
    else
        Cam.FieldOfView = orig_fov
    end
end
RS.RenderStepped:Connect(function() pcall(applyFov) end)

-- ============================================================
--  VIEWMODEL CHANGER
-- ============================================================
local function getViewmodel()
    if not Cam then return nil end
    local vm = Cam:FindFirstChild("Viewmodel") or Cam:FindFirstChild("ViewModel") or Cam:FindFirstChild("Weapon")
    if vm then return vm end
    for _, c in ipairs(Cam:GetChildren()) do
        if c:IsA("Model") and (c.Name:lower():find("weapon") or c.Name:lower():find("arm") or c.Name:lower():find("viewmodel")) then
            return c
        end
    end
    return nil
end
local function updateViewmodel()
    if not Config.vm_enabled then return end
    local vm = getViewmodel()
    if not vm then return end
    for _, part in ipairs(vm:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:GetAttribute("Aurora_BaseCFrame") then
                part:SetAttribute("Aurora_BaseCFrame", part.CFrame)
            end
            local base = part:GetAttribute("Aurora_BaseCFrame")
            if base then
                pcall(function()
                    part.CFrame = base
                        * CFrame.new(Config.vm_offset_x, Config.vm_offset_y, Config.vm_offset_z)
                        * CFrame.Angles(math.rad(Config.vm_rot_x), math.rad(Config.vm_rot_y), math.rad(Config.vm_rot_z))
                end)
            end
        end
    end
end
RS.RenderStepped:Connect(function() pcall(updateViewmodel) end)

-- ============================================================
--  ESP
-- ============================================================
local espGui = Instance.new("ScreenGui")
espGui.Name="Aurora_ESP"; espGui.ResetOnSpawn=false
espGui.IgnoreGuiInset=true; espGui.DisplayOrder=2147483600
espGui.Parent = PARENT

local espPlayers = {}
local function createESP(plr)
    if plr == LP or espPlayers[plr] then return end
    local obj = { box={}, skeleton={} }
    for i=1,4 do
        local f = Instance.new("Frame", espGui)
        f.BackgroundColor3=CLR.red; f.BorderSizePixel=0; f.Visible=false
        obj.box[i]=f
    end
    local fill = Instance.new("Frame", espGui)
    fill.BackgroundColor3=CLR.red; fill.BackgroundTransparency=0.85
    fill.BorderSizePixel=0; fill.Visible=false; obj.fill=fill
    local nameLbl = Instance.new("TextLabel", espGui)
    nameLbl.BackgroundTransparency=1
    nameLbl.TextColor3=Color3.fromRGB(255,255,255)
    nameLbl.TextStrokeTransparency=0; nameLbl.TextStrokeColor3=Color3.new(0,0,0)
    nameLbl.Font=FONT_B; nameLbl.TextSize=12; nameLbl.Text=plr.Name
    nameLbl.TextXAlignment=Enum.TextXAlignment.Center; nameLbl.Visible=false
    obj.name=nameLbl
    local distLbl = Instance.new("TextLabel", espGui)
    distLbl.BackgroundTransparency=1
    distLbl.TextColor3=Color3.fromRGB(210,210,210)
    distLbl.TextStrokeTransparency=0; distLbl.TextStrokeColor3=Color3.new(0,0,0)
    distLbl.Font=FONT_M; distLbl.TextSize=11; distLbl.Text="0 m"
    distLbl.TextXAlignment=Enum.TextXAlignment.Center; distLbl.Visible=false
    obj.dist=distLbl
    local hpBg = Instance.new("Frame", espGui)
    hpBg.BackgroundColor3=Color3.fromRGB(20,20,24); hpBg.BorderSizePixel=0
    hpBg.Visible=false; corner(hpBg,2)
    local hpFill = Instance.new("Frame", hpBg)
    hpFill.Size=UDim2.new(1,0,1,0); hpFill.BackgroundColor3=CLR.green
    hpFill.BorderSizePixel=0; corner(hpFill,2)
    obj.hpBg=hpBg; obj.hpFill=hpFill
    local hdot = Instance.new("Frame", espGui)
    hdot.BackgroundColor3=CLR.red; hdot.BorderSizePixel=0; hdot.Visible=false
    corner(hdot,20); obj.headDot=hdot
    for i=1,10 do
        local l = Instance.new("Frame", espGui)
        l.BackgroundColor3=Color3.fromRGB(255,255,255); l.BorderSizePixel=0
        l.Visible=false; obj.skeleton[i]=l
    end
    local sl = Instance.new("Frame", espGui)
    sl.BackgroundColor3=Color3.fromRGB(255,255,255); sl.BorderSizePixel=0
    sl.Visible=false; obj.snapline=sl
    local arrow = Instance.new("TextLabel", espGui)
    arrow.BackgroundTransparency=1; arrow.Text="▲"; arrow.TextColor3=CLR.red
    arrow.TextSize=24; arrow.Font=FONT_B; arrow.Visible=false
    obj.arrow=arrow
    local hl = Instance.new("Highlight")
    hl.Name="Aurora_Chams"; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillColor=CLR.red; hl.OutlineColor=CLR.red
    hl.FillTransparency=0.5; hl.OutlineTransparency=0
    hl.Enabled=false; hl.Parent=espGui; obj.hl=hl
    espPlayers[plr]=obj
end
local function destroyESP(plr)
    local obj = espPlayers[plr]
    if not obj then return end
    for _,f in ipairs(obj.box) do pcall(function() f:Destroy() end) end
    for _,f in ipairs(obj.skeleton) do pcall(function() f:Destroy() end) end
    pcall(function() obj.name:Destroy() end)
    pcall(function() obj.dist:Destroy() end)
    pcall(function() obj.fill:Destroy() end)
    pcall(function() obj.hpBg:Destroy() end)
    pcall(function() obj.headDot:Destroy() end)
    pcall(function() obj.snapline:Destroy() end)
    pcall(function() obj.arrow:Destroy() end)
    pcall(function() obj.hl:Destroy() end)
    espPlayers[plr]=nil
end
for _,p in ipairs(Players:GetPlayers()) do if p~=LP then createESP(p) end end
Players.PlayerAdded:Connect(function(p) if p~=LP then createESP(p) end end)
Players.PlayerRemoving:Connect(destroyESP)

local function hideESP(obj)
    for _,f in ipairs(obj.box) do f.Visible=false end
    for _,f in ipairs(obj.skeleton) do f.Visible=false end
    obj.name.Visible=false; obj.dist.Visible=false
    obj.fill.Visible=false; obj.hpBg.Visible=false
    obj.headDot.Visible=false; obj.snapline.Visible=false
    obj.arrow.Visible=false; obj.hl.Enabled=false
end
local function findHRP(plr)
    local ch = plr.Character
    return ch and ch:FindFirstChild("HumanoidRootPart")
end
local function getHealth(plr)
    local srcs = {
        function() return plr:GetAttribute("Health") end,
        function() return plr:GetAttribute("HP") end,
        function() return plr:GetAttribute("health") end,
        function() local ch = plr.Character; return ch and ch:GetAttribute("Health") end,
    }
    for _,fn in ipairs(srcs) do
        local ok,v = pcall(fn)
        if ok and type(v)=="number" then return v, 100 end
    end
    return nil, nil
end
local function lineBetween(a, b, thickness)
    local dx=b.X-a.X; local dy=b.Y-a.Y
    local len=math.sqrt(dx*dx+dy*dy)
    return UDim2.new(0,len,0,thickness), math.deg(math.atan2(dy,dx)), UDim2.new(0,a.X,0,a.Y)
end
local function drawSkeleton(obj, plr, color)
    local ch = plr.Character
    if not ch then
        for _,f in ipairs(obj.skeleton) do f.Visible=false end
        return
    end
    local points = {
        head=ch:FindFirstChild("Head"),
        upperTorso=ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso"),
        lowerTorso=ch:FindFirstChild("LowerTorso"),
        leftUpperArm=ch:FindFirstChild("LeftUpperArm"),
        rightUpperArm=ch:FindFirstChild("RightUpperArm"),
        leftLowerArm=ch:FindFirstChild("LeftLowerArm"),
        rightLowerArm=ch:FindFirstChild("RightLowerArm"),
        leftUpperLeg=ch:FindFirstChild("LeftUpperLeg"),
        rightUpperLeg=ch:FindFirstChild("RightUpperLeg"),
        leftLowerLeg=ch:FindFirstChild("LeftLowerLeg"),
        rightLowerLeg=ch:FindFirstChild("RightLowerLeg"),
    }
    local screen = {}
    for k,p in pairs(points) do
        if p and p:IsA("BasePart") then
            local sp,on = Cam:WorldToViewportPoint(p.Position)
            if on and sp.Z>0 then screen[k]=Vector2.new(sp.X, sp.Y) end
        end
    end
    local conns = {
        {"head","upperTorso"},{"upperTorso","lowerTorso"},
        {"upperTorso","leftUpperArm"},{"leftUpperArm","leftLowerArm"},
        {"upperTorso","rightUpperArm"},{"rightUpperArm","rightLowerArm"},
        {"lowerTorso","leftUpperLeg"},{"leftUpperLeg","leftLowerLeg"},
        {"lowerTorso","rightUpperLeg"},{"rightUpperLeg","rightLowerLeg"},
    }
    for i,conn in ipairs(conns) do
        local a,b = screen[conn[1]], screen[conn[2]]
        local f = obj.skeleton[i]
        if a and b then
            local size,rot,pos = lineBetween(a,b,1)
            f.Size=size; f.Rotation=rot; f.Position=pos
            f.BackgroundColor3=color; f.Visible=true
        else f.Visible=false end
    end
end

local function updateESP()
    if not Config.esp_enabled then
        for _,obj in pairs(espPlayers) do hideESP(obj) end
        return
    end
    local vp = Cam.ViewportSize
    if vp.X<100 or vp.Y<100 then
        for _,obj in pairs(espPlayers) do hideESP(obj) end
        return
    end
    local myHRP = findHRP(LP)
    if not myHRP then
        for _,obj in pairs(espPlayers) do hideESP(obj) end
        return
    end
    for plr,obj in pairs(espPlayers) do
        local head = getBone(plr)
        local hrp = findHRP(plr)
        local isAlly = shouldSkip(plr)
        local color = isAlly and Config.esp_ally_color or Config.esp_enemy_color
        if Config.esp_chams and plr.Character then
            obj.hl.Adornee = plr.Character
            obj.hl.FillColor = color; obj.hl.OutlineColor = color
            obj.hl.FillTransparency = Config.esp_chams_fill_alpha
            obj.hl.Enabled = true
        else obj.hl.Enabled = false end

        local canDraw = head and hrp
        local dist = 0
        if canDraw then
            dist = (myHRP.Position - hrp.Position).Magnitude
            if dist > Config.esp_max_dist then canDraw = false end
        end

        if canDraw then
            local topScreen,topOn = Cam:WorldToViewportPoint(head.Position + Vector3.new(0,1,0))
            local botScreen,botOn = Cam:WorldToViewportPoint(hrp.Position - Vector3.new(0,3,0))
            if topOn and botOn and topScreen.Z>0 and botScreen.Z>0 and topScreen.X==topScreen.X then
                local h = math.abs(botScreen.Y - topScreen.Y)
                if h>=2 and h<=5000 then
                    local w = h*0.55
                    local x = topScreen.X - w/2
                    local y = topScreen.Y

                    if Config.esp_box then
                        if Config.esp_box_style=="Full" then
                            obj.box[1].Position=UDim2.new(0,x,0,y); obj.box[1].Size=UDim2.new(0,w,0,1); obj.box[1].BackgroundColor3=color; obj.box[1].Visible=true
                            obj.box[2].Position=UDim2.new(0,x,0,y+h); obj.box[2].Size=UDim2.new(0,w,0,1); obj.box[2].BackgroundColor3=color; obj.box[2].Visible=true
                            obj.box[3].Position=UDim2.new(0,x,0,y); obj.box[3].Size=UDim2.new(0,1,0,h); obj.box[3].BackgroundColor3=color; obj.box[3].Visible=true
                            obj.box[4].Position=UDim2.new(0,x+w,0,y); obj.box[4].Size=UDim2.new(0,1,0,h); obj.box[4].BackgroundColor3=color; obj.box[4].Visible=true
                        elseif Config.esp_box_style=="Corners" then
                            local cLen = math.max(w,h)*0.25
                            obj.box[1].Position=UDim2.new(0,x,0,y); obj.box[1].Size=UDim2.new(0,cLen,0,1); obj.box[1].BackgroundColor3=color; obj.box[1].Visible=true
                            obj.box[2].Position=UDim2.new(0,x,0,y); obj.box[2].Size=UDim2.new(0,1,0,cLen); obj.box[2].BackgroundColor3=color; obj.box[2].Visible=true
                            obj.box[3].Position=UDim2.new(0,x+w-cLen,0,y+h); obj.box[3].Size=UDim2.new(0,cLen,0,1); obj.box[3].BackgroundColor3=color; obj.box[3].Visible=true
                            obj.box[4].Position=UDim2.new(0,x+w,0,y+h-cLen); obj.box[4].Size=UDim2.new(0,1,0,cLen); obj.box[4].BackgroundColor3=color; obj.box[4].Visible=true
                        end
                    else for i=1,4 do obj.box[i].Visible=false end end

                    if Config.esp_box_style=="Fill" then
                        obj.fill.Position=UDim2.new(0,x,0,y); obj.fill.Size=UDim2.new(0,w,0,h)
                        obj.fill.BackgroundColor3=color
                        obj.fill.BackgroundTransparency=1-Config.esp_box_fill_alpha
                        obj.fill.Visible=true
                    else obj.fill.Visible=false end

                    if Config.esp_name then
                        obj.name.Position=UDim2.new(0,topScreen.X-100,0,y-18)
                        obj.name.Size=UDim2.new(0,200,0,14)
                        obj.name.TextColor3=color; obj.name.Visible=true
                    else obj.name.Visible=false end

                    if Config.esp_dist then
                        obj.dist.Position=UDim2.new(0,topScreen.X-100,0,y+h+2)
                        obj.dist.Size=UDim2.new(0,200,0,12)
                        obj.dist.Text=string.format("%d m", math.floor(dist))
                        obj.dist.Visible=true
                    else obj.dist.Visible=false end

                    if Config.esp_hp then
                        local hp,maxHp = getHealth(plr)
                        if hp and maxHp then
                            local frac = math.clamp(hp/maxHp,0,1)
                            obj.hpBg.Position=UDim2.new(0,x-6,0,y)
                            obj.hpBg.Size=UDim2.new(0,3,0,h)
                            obj.hpFill.Size=UDim2.new(1,0,frac,0)
                            obj.hpFill.Position=UDim2.new(0,0,1-frac,0)
                            obj.hpFill.BackgroundColor3=Color3.fromRGB(
                                math.floor(255*(1-frac)+60*frac),
                                math.floor(60+140*frac), 60)
                            obj.hpBg.Visible=true
                        else obj.hpBg.Visible=false end
                    else obj.hpBg.Visible=false end

                    if Config.esp_head_dot then
                        local hsp,hon = Cam:WorldToViewportPoint(head.Position)
                        if hon then
                            obj.headDot.Position=UDim2.new(0,hsp.X-3,0,hsp.Y-3)
                            obj.headDot.Size=UDim2.new(0,6,0,6)
                            obj.headDot.BackgroundColor3=color
                            obj.headDot.Visible=true
                        else obj.headDot.Visible=false end
                    else obj.headDot.Visible=false end

                    if Config.esp_snapline then
                        local from = Vector2.new(vp.X/2, vp.Y)
                        local to = Vector2.new(topScreen.X, y+h)
                        local size,rot,pos = lineBetween(from,to,1)
                        obj.snapline.Size=size; obj.snapline.Rotation=rot
                        obj.snapline.Position=pos; obj.snapline.BackgroundColor3=color
                        obj.snapline.Visible=true
                    else obj.snapline.Visible=false end

                    if Config.esp_skeleton then drawSkeleton(obj,plr,color)
                    else for _,f in ipairs(obj.skeleton) do f.Visible=false end end
                    obj.arrow.Visible=false
                else
                    for i=1,4 do obj.box[i].Visible=false end
                    for _,f in ipairs(obj.skeleton) do f.Visible=false end
                    obj.name.Visible=false; obj.dist.Visible=false
                    obj.fill.Visible=false; obj.hpBg.Visible=false
                    obj.headDot.Visible=false; obj.snapline.Visible=false
                    obj.arrow.Visible=false
                end
            else
                for i=1,4 do obj.box[i].Visible=false end
                for _,f in ipairs(obj.skeleton) do f.Visible=false end
                obj.name.Visible=false; obj.dist.Visible=false
                obj.fill.Visible=false; obj.hpBg.Visible=false
                obj.headDot.Visible=false; obj.snapline.Visible=false
                obj.arrow.Visible=false
            end
        else
            for i=1,4 do obj.box[i].Visible=false end
            for _,f in ipairs(obj.skeleton) do f.Visible=false end
            obj.name.Visible=false; obj.dist.Visible=false
            obj.fill.Visible=false; obj.hpBg.Visible=false
            obj.headDot.Visible=false; obj.snapline.Visible=false
            obj.arrow.Visible=false
        end
    end
end
pcall(function() RS:UnbindFromRenderStep("Aurora_ESP_Update") end)
RS:BindToRenderStep("Aurora_ESP_Update", Enum.RenderPriority.Camera.Value + 10, function()
    pcall(updateESP)
end)

-- ============================================================
--  BLUR
-- ============================================================
local blurFx = Instance.new("BlurEffect")
blurFx.Name="Aurora_Blur"; blurFx.Size=0; blurFx.Enabled=false
blurFx.Parent=Lighting
local blurTween
local function setBlur(on)
    if not Config.blur then blurFx.Enabled=false; return end
    if blurTween then blurTween:Cancel() end
    blurFx.Enabled=true
    blurTween = TS:Create(blurFx, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size=on and 12 or 0})
    blurTween:Play()
    if not on then task.delay(0.4, function() if blurFx.Size<1 then blurFx.Enabled=false end end) end
end

-- ============================================================
--  VISUAL — FOV / CROSSHAIR / WM
-- ============================================================
local visGui = Instance.new("ScreenGui")
visGui.Name="Aurora_Vis"; visGui.ResetOnSpawn=false
visGui.IgnoreGuiInset=true; visGui.DisplayOrder=2147483645
visGui.Parent=PARENT

local fovCircle = nil
if Drawing then
    pcall(function()
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness=1; fovCircle.NumSides=64
        fovCircle.Filled=false; fovCircle.Transparency=0.6
        fovCircle.Visible=false
    end)
end
task.spawn(function()
    while true do
        task.wait(0.05)
        if fovCircle then
            if Config.fov_circle and Config.aim_enabled then
                fovCircle.Visible=true
                fovCircle.Position=Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
                fovCircle.Radius=Config.max_fov
                fovCircle.Color=Config.fov_color
            else fovCircle.Visible=false end
        end
    end
end)

local crossGui = Instance.new("ScreenGui", visGui)
crossGui.Name="Cross"; crossGui.IgnoreGuiInset=true
crossGui.DisplayOrder=2147483644; crossGui.ResetOnSpawn=false
local crossHolder = Instance.new("Frame", crossGui)
crossHolder.AnchorPoint=Vector2.new(0.5,0.5)
crossHolder.Position=UDim2.new(0.5,0,0.5,0)
crossHolder.Size=UDim2.new(0,100,0,100)
crossHolder.BackgroundTransparency=1
local crossParts = {}
for _,n in ipairs({"top","bot","left","right","dot"}) do
    local p = Instance.new("Frame", crossHolder)
    p.Name=n; p.BackgroundColor3=Config.crosshair_color
    p.BorderSizePixel=0; p.Visible=false
    crossParts[n]=p
end
local function updateCrosshair()
    crossGui.Enabled=Config.crosshair
    for _,p in pairs(crossParts) do p.Visible=false; p.BackgroundColor3=Config.crosshair_color end
    if not Config.crosshair then return end
    local sz,th,gap = Config.crosshair_size, Config.crosshair_thick, Config.crosshair_gap
    crossParts.top.Visible=true; crossParts.top.Size=UDim2.new(0,th,0,sz); crossParts.top.Position=UDim2.new(0.5,-th/2,0.5,-sz-gap)
    crossParts.bot.Visible=true; crossParts.bot.Size=UDim2.new(0,th,0,sz); crossParts.bot.Position=UDim2.new(0.5,-th/2,0.5,gap)
    crossParts.left.Visible=true; crossParts.left.Size=UDim2.new(0,sz,0,th); crossParts.left.Position=UDim2.new(0.5,-sz-gap,0.5,-th/2)
    crossParts.right.Visible=true; crossParts.right.Size=UDim2.new(0,sz,0,th); crossParts.right.Position=UDim2.new(0.5,gap,0.5,-th/2)
    if Config.crosshair_dot then
        crossParts.dot.Visible=true; crossParts.dot.Size=UDim2.new(0,2,0,2); crossParts.dot.Position=UDim2.new(0.5,-1,0.5,-1)
    end
end

local wmGui = Instance.new("ScreenGui", visGui)
wmGui.Name="WM"; wmGui.IgnoreGuiInset=true
wmGui.DisplayOrder=2147483643; wmGui.ResetOnSpawn=false
local wmFrame = Instance.new("Frame", wmGui)
wmFrame.Size=UDim2.new(0,340,0,28); wmFrame.Position=UDim2.new(0,20,0,20)
wmFrame.BackgroundColor3=CLR.bg; wmFrame.BackgroundTransparency=0.15
wmFrame.BorderSizePixel=0; corner(wmFrame,8)
stroke(wmFrame, CLR.accent1, 1, 0.4)
local wmBrand = Instance.new("Frame", wmFrame)
wmBrand.Size=UDim2.new(0,14,0,14); wmBrand.Position=UDim2.new(0,10,0.5,-7)
wmBrand.BackgroundColor3=CLR.accent1; wmBrand.BorderSizePixel=0; corner(wmBrand,4)
local wmLbl = Instance.new("TextLabel", wmFrame)
wmLbl.Size=UDim2.new(0,140,1,0); wmLbl.Position=UDim2.new(0,30,0,0)
wmLbl.BackgroundTransparency=1; wmLbl.Text="AURORA LEGIT"
wmLbl.TextColor3=CLR.text; wmLbl.Font=FONT_BLACK; wmLbl.TextSize=12
wmLbl.TextXAlignment=Enum.TextXAlignment.Left
local wmSep = Instance.new("Frame", wmFrame)
wmSep.Size=UDim2.new(0,1,0.5,0); wmSep.Position=UDim2.new(0,120,0.25,0)
wmSep.BackgroundColor3=CLR.border; wmSep.BorderSizePixel=0; wmSep.BackgroundTransparency=0.4
local wmFps = Instance.new("TextLabel", wmFrame)
wmFps.Size=UDim2.new(0,60,1,0); wmFps.Position=UDim2.new(0,128,0,0)
wmFps.BackgroundTransparency=1; wmFps.Text="60 FPS"
wmFps.TextColor3=CLR.text; wmFps.Font=FONT_M; wmFps.TextSize=11
wmFps.TextXAlignment=Enum.TextXAlignment.Left
local wmSep2 = Instance.new("Frame", wmFrame)
wmSep2.Size=UDim2.new(0,1,0.5,0); wmSep2.Position=UDim2.new(0,188,0.25,0)
wmSep2.BackgroundColor3=CLR.border; wmSep2.BorderSizePixel=0; wmSep2.BackgroundTransparency=0.4
local wmStatus = Instance.new("TextLabel", wmFrame)
wmStatus.Size=UDim2.new(1,-200,1,0); wmStatus.Position=UDim2.new(0,198,0,0)
wmStatus.BackgroundTransparency=1; wmStatus.Text="● IDLE"
wmStatus.TextColor3=CLR.text_dim; wmStatus.Font=FONT_B; wmStatus.TextSize=11
wmStatus.TextXAlignment=Enum.TextXAlignment.Left
task.spawn(function()
    local fc, lastFps = 0, tick()
    while wmFrame.Parent do
        fc = fc + 1
        if tick()-lastFps>=1 then State.fps=fc; fc=0; lastFps=tick() end
        wmFrame.Visible = Config.watermark
        wmFps.Text = string.format("%d FPS", State.fps)
        if Config.aa_enabled then
            wmStatus.Text="● AA"; wmStatus.TextColor3=CLR.accent1_hi
        elseif State.strafing then
            wmStatus.Text="● STRAFE"; wmStatus.TextColor3=CLR.accent1_hi
        elseif State.bhopping then
            wmStatus.Text="● HOP"; wmStatus.TextColor3=CLR.accent2_hi
        elseif State.locked then
            wmStatus.Text="● LOCKED"; wmStatus.TextColor3=CLR.green
        elseif State.trigging then
            wmStatus.Text="● TRIG"; wmStatus.TextColor3=CLR.accent2
        elseif State.aim_active then
            wmStatus.Text="● AIM"; wmStatus.TextColor3=CLR.yellow
        else
            wmStatus.Text="● IDLE"; wmStatus.TextColor3=CLR.text_dim
        end
        task.wait(0.1)
    end
end)

-- ============================================================
--  MENU ROOT
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name="Aurora_Main"; gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.DisplayOrder=2147483647; gui.Parent=PARENT

local overlay = Instance.new("Frame", gui)
overlay.Size=UDim2.new(1,0,1,0); overlay.BackgroundColor3=Color3.new(0,0,0)
overlay.BackgroundTransparency=1; overlay.BorderSizePixel=0; overlay.Visible=false

local group = Instance.new("CanvasGroup", gui)
group.Size=UDim2.new(0,860,0,600)
group.Position=UDim2.new(0.5,-430,0.5,-300)
group.BackgroundTransparency=1; group.GroupTransparency=1; group.BorderSizePixel=0
group.Visible=false
local winScale = Instance.new("UIScale", group); winScale.Scale=1

local shadow = Instance.new("Frame", group)
shadow.Size=UDim2.new(1,40,1,40); shadow.Position=UDim2.new(0,-20,0,-20)
shadow.BackgroundColor3=Color3.new(0,0,0); shadow.BackgroundTransparency=0.45
shadow.BorderSizePixel=0; shadow.ZIndex=-1; corner(shadow,24)
local shadowGrad = Instance.new("UIGradient", shadow)
shadowGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,0.05),
    NumberSequenceKeypoint.new(0.55,0.85),
    NumberSequenceKeypoint.new(1,1),
})
shadowGrad.Rotation=90

local win = Instance.new("Frame", group)
win.Size=UDim2.new(1,0,1,0); win.BackgroundColor3=CLR.bg
win.BackgroundTransparency=0.04; win.BorderSizePixel=0
win.Active=true; win.ClipsDescendants=true
corner(win,16)
local winStroke = stroke(win, CLR.accent1_dk, 1.5, 0.2)

local topBar = Instance.new("Frame", win)
topBar.Size=UDim2.new(1,0,0,3); topBar.BorderSizePixel=0
topBar.BackgroundColor3=CLR.accent1
local topGrad = Instance.new("UIGradient", topBar)
topGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,CLR.accent1),
    ColorSequenceKeypoint.new(0.25,CLR.accent1_hi),
    ColorSequenceKeypoint.new(0.5,CLR.accent2),
    ColorSequenceKeypoint.new(0.75,CLR.accent2_hi),
    ColorSequenceKeypoint.new(1,CLR.accent1),
})
task.spawn(function()
    local t=0
    while topBar.Parent do
        t=t+0.015; topGrad.Offset=Vector2.new(math.sin(t),0); task.wait(0.03)
    end
end)

local header = Instance.new("Frame", win)
header.Size=UDim2.new(1,0,0,60); header.Position=UDim2.new(0,0,0,3)
header.BackgroundColor3=CLR.panel; header.BackgroundTransparency=0.05
header.BorderSizePixel=0; header.ZIndex=2
local headerGrad = Instance.new("UIGradient", header)
headerGrad.Color = ColorSequence.new(CLR.panel_hi, CLR.panel); headerGrad.Rotation=90

local brandMark = Instance.new("Frame", header)
brandMark.Size=UDim2.new(0,18,0,18); brandMark.Position=UDim2.new(0,22,0.5,-9)
brandMark.BackgroundColor3=CLR.accent1; brandMark.BorderSizePixel=0; corner(brandMark,5)
local brandGrad = Instance.new("UIGradient", brandMark)
brandGrad.Color=ColorSequence.new(CLR.accent1, CLR.accent2); brandGrad.Rotation=45
local brandDot = Instance.new("Frame", brandMark)
brandDot.Size=UDim2.new(0,6,0,6); brandDot.Position=UDim2.new(0.5,-3,0.5,-3)
brandDot.BackgroundColor3=Color3.fromRGB(255,255,255); brandDot.BorderSizePixel=0; corner(brandDot,3)
local brandGlow = Instance.new("UIStroke", brandMark)
brandGlow.Color=CLR.accent2_hi; brandGlow.Thickness=1.5; brandGlow.Transparency=0.4
task.spawn(function()
    while brandMark.Parent do
        tween(brandGlow, "Transparency", 0.9, 1.2); task.wait(1.2)
        tween(brandGlow, "Transparency", 0.2, 1.2); task.wait(1.2)
    end
end)

local brandText = Instance.new("TextLabel", header)
brandText.Size=UDim2.new(0,220,0,22); brandText.Position=UDim2.new(0,50,0,10)
brandText.BackgroundTransparency=1; brandText.Text="AURORA LEGIT"
brandText.TextColor3=CLR.text; brandText.Font=FONT_BLACK
brandText.TextSize=20; brandText.TextXAlignment=Enum.TextXAlignment.Left
brandText.TextStrokeTransparency=0; brandText.TextStrokeColor3=Color3.new(0,0,0)

local subText = Instance.new("TextLabel", header)
subText.Size=UDim2.new(0,300,0,14); subText.Position=UDim2.new(0,50,0,32)
subText.BackgroundTransparency=1; subText.Text="v3.1  ·  anti-aim  ·  fov  ·  viewmodel"
subText.TextColor3=CLR.text_dim; subText.Font=FONT_M
subText.TextSize=10; subText.TextXAlignment=Enum.TextXAlignment.Left

local statusDot = Instance.new("Frame", header)
statusDot.Size=UDim2.new(0,8,0,8); statusDot.Position=UDim2.new(1,-180,0.5,-4)
statusDot.BackgroundColor3=CLR.green; statusDot.BorderSizePixel=0; corner(statusDot,4)
local statusGlow = Instance.new("UIStroke", statusDot)
statusGlow.Color=CLR.green; statusGlow.Thickness=2; statusGlow.Transparency=0.5
task.spawn(function()
    while statusDot.Parent do
        tween(statusGlow, "Transparency", 1, 1.2); task.wait(1.2)
        tween(statusGlow, "Transparency", 0.5, 1.2); task.wait(1.2)
    end
end)
local statusText = Instance.new("TextLabel", header)
statusText.Size=UDim2.new(0,80,0,14); statusText.Position=UDim2.new(1,-166,0.5,-7)
statusText.BackgroundTransparency=1; statusText.Text="ACTIVE"
statusText.TextColor3=CLR.green; statusText.Font=FONT_B
statusText.TextSize=10; statusText.TextXAlignment=Enum.TextXAlignment.Left

local function makeHdrBtn(txt, isClose)
    local b = Instance.new("TextButton", header)
    b.Size=UDim2.new(0,32,0,28); b.BackgroundColor3=CLR.element
    b.BackgroundTransparency=0.3; b.BorderSizePixel=0
    b.Text=txt; b.TextColor3=CLR.text_dim
    b.Font=FONT_B; b.TextSize=15; b.AutoButtonColor=false
    corner(b,8); b.ZIndex=5
    local bg = b.BackgroundColor3
    b.MouseEnter:Connect(function()
        tween(b, "BackgroundTransparency", 0, 0.12)
        if isClose then tween(b, "BackgroundColor3", CLR.red, 0.12)
        else tween(b, "BackgroundColor3", CLR.accent1, 0.12) end
        b.TextColor3=CLR.text
    end)
    b.MouseLeave:Connect(function()
        tween(b, "BackgroundTransparency", 0.3, 0.12)
        tween(b, "BackgroundColor3", bg, 0.12); b.TextColor3=CLR.text_dim
    end)
    return b
end
local closeBtn = makeHdrBtn("×", true); closeBtn.Position=UDim2.new(1,-44,0.5,-14)
local minBtn = makeHdrBtn("–", false); minBtn.Position=UDim2.new(1,-80,0.5,-14)

local function openMenu(instant)
    if State.open or State.busy then return end
    State.busy=true; State.open=true
    group.Visible=true; overlay.Visible=true
    tween(overlay, "BackgroundTransparency", 0.5, 0.2)
    if instant then
        winScale.Scale=1; group.GroupTransparency=0; setBlur(true)
        State.busy=false; return
    end
    winScale.Scale=0.85; group.GroupTransparency=1
    group.Position=UDim2.new(0.5,-430,0.5,-290)
    tween(winScale, "Scale", 1, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    tween(group, "GroupTransparency", 0, 0.28, Enum.EasingStyle.Quart)
    tween(group, "Position", UDim2.new(0.5,-430,0.5,-300), 0.38, Enum.EasingStyle.Quart)
    setBlur(true)
    task.wait(0.4); State.busy=false
end
local function closeMenu(instant)
    if not State.open or State.busy then return end
    State.busy=true; State.open=false
    tween(overlay, "BackgroundTransparency", 1, 0.2)
    task.delay(0.22, function() overlay.Visible=false end)
    if instant then
        group.GroupTransparency=1; group.Visible=false; setBlur(false); State.busy=false; return
    end
    tween(winScale, "Scale", 0.85, 0.26, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    tween(group, "GroupTransparency", 1, 0.24, Enum.EasingStyle.Quart)
    tween(group, "Position", UDim2.new(0.5,-430,0.5,-290), 0.26, Enum.EasingStyle.Quart)
    setBlur(false)
    task.wait(0.3)
    group.Visible=false
    State.busy=false
end
closeBtn.MouseButton1Click:Connect(function() closeMenu() end)
minBtn.MouseButton1Click:Connect(function() closeMenu() end)

do
    local drag, ds, sp
    header.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true; ds=i.Position; sp=group.Position
        end
    end)
    header.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            group.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
end

local sidebar = Instance.new("Frame", win)
sidebar.Size=UDim2.new(0,180,1,-63-30); sidebar.Position=UDim2.new(0,12,0,66)
sidebar.BackgroundColor3=CLR.panel; sidebar.BackgroundTransparency=0.4
sidebar.BorderSizePixel=0; sidebar.ZIndex=2; corner(sidebar,12)
local sidePad = Instance.new("UIPadding", sidebar)
sidePad.PaddingTop=UDim.new(0,10); sidePad.PaddingBottom=UDim.new(0,10)
sidePad.PaddingLeft=UDim.new(0,8); sidePad.PaddingRight=UDim.new(0,8)
local sideLayout = Instance.new("UIListLayout", sidebar)
sideLayout.Padding=UDim.new(0,4); sideLayout.SortOrder=Enum.SortOrder.LayoutOrder

local content = Instance.new("Frame", win)
content.Size=UDim2.new(1,-206,1,-63-30); content.Position=UDim2.new(0,196,0,66)
content.BackgroundTransparency=1; content.BorderSizePixel=0; content.ZIndex=2

local footer = Instance.new("Frame", win)
footer.Size=UDim2.new(1,0,0,28); footer.Position=UDim2.new(0,0,1,-28)
footer.BackgroundColor3=CLR.panel; footer.BackgroundTransparency=0.3
footer.BorderSizePixel=0; footer.ZIndex=4
local footerDot = Instance.new("Frame", footer)
footerDot.Size=UDim2.new(0,5,0,5); footerDot.Position=UDim2.new(0,18,0.5,-2.5)
footerDot.BackgroundColor3=CLR.accent2; footerDot.BorderSizePixel=0; corner(footerDot,3)
task.spawn(function()
    while footerDot.Parent do
        tween(footerDot, "BackgroundColor3", CLR.accent1, 1); task.wait(1)
        tween(footerDot, "BackgroundColor3", CLR.accent2, 1); task.wait(1)
    end
end)
local footerText = Instance.new("TextLabel", footer)
footerText.Size=UDim2.new(1,-40,1,0); footerText.Position=UDim2.new(0,30,0,0)
footerText.BackgroundTransparency=1
footerText.Text="Aurora Legit v3.1  ·  C=aim  V=trig  X=bhop  Z=strafe  B=AA  RShift=menu"
footerText.TextColor3=CLR.text_dim; footerText.Font=FONT_M
footerText.TextSize=10; footerText.TextXAlignment=Enum.TextXAlignment.Left

local PAGE_LIST = { "Aimbot", "Trigger", "Bhop", "Strafer", "Anti-Aim", "ESP", "Visual", "Binds", "Settings", "About" }
local pages = {}; local pageScale = {}
for _,name in ipairs(PAGE_LIST) do
    local sc = Instance.new("ScrollingFrame", content)
    sc.Size=UDim2.new(1,0,1,0); sc.BackgroundTransparency=1
    sc.BorderSizePixel=0; sc.ScrollBarThickness=4
    sc.ScrollBarImageColor3=CLR.accent1_dk
    sc.CanvasSize=UDim2.new(0,0,0,0); sc.AutomaticCanvasSize=Enum.AutomaticSize.Y
    sc.Visible=false; sc.ZIndex=3
    local p = Instance.new("UIPadding", sc)
    p.PaddingTop=UDim.new(0,8); p.PaddingBottom=UDim.new(0,8)
    p.PaddingLeft=UDim.new(0,8); p.PaddingRight=UDim.new(0,8)
    local ll = Instance.new("UIListLayout", sc)
    ll.Padding=UDim.new(0,6); ll.SortOrder=Enum.SortOrder.LayoutOrder
    local ps = Instance.new("UIScale", sc); ps.Scale=1
    pages[name] = {frame=sc, scale=ps}
end

local function tabIcon(n)
    if n=="Aimbot" then return "◉" end
    if n=="Trigger" then return "⚡" end
    if n=="Bhop" then return "⇧" end
    if n=="Strafer" then return "»" end
    if n=="Anti-Aim" then return "◐" end
    if n=="ESP" then return "◈" end
    if n=="Visual" then return "✦" end
    if n=="Binds" then return "⌨" end
    if n=="Settings" then return "⚙" end
    if n=="About" then return "ℹ" end
    return "•"
end

local tabButtons = {}; local currentTab = nil
local function selectTab(name)
    if currentTab==name then return end
    currentTab=name
    for n,p in pairs(pages) do p.frame.Visible=(n==name) end
    for n,b in pairs(tabButtons) do
        local on = (n==name)
        tween(b.icon, "TextColor3", on and CLR.accent1_hi or CLR.text_dim, 0.18)
        tween(b.label, "TextColor3", on and CLR.text or CLR.text_dim, 0.18)
        tween(b.btn, "BackgroundColor3", on and CLR.element_hi or CLR.element, 0.2)
        tween(b.btn, "BackgroundTransparency", on and 0.1 or 0.6, 0.2)
        tween(b.bar, "BackgroundTransparency", on and 0 or 1, 0.22)
        tween(b.bar, "Size", on and UDim2.new(0,3,0,22) or UDim2.new(0,0,0,22), 0.28, Enum.EasingStyle.Back)
    end
    local ps = pages[name] and pages[name].scale
    if ps then ps.Scale=0.94; tween(ps, "Scale", 1, 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out) end
end

for _,name in ipairs(PAGE_LIST) do
    local b = Instance.new("TextButton", sidebar)
    b.Size=UDim2.new(1,0,0,36); b.BackgroundColor3=CLR.element
    b.BackgroundTransparency=0.6; b.BorderSizePixel=0
    b.Text=""; b.AutoButtonColor=false; b.ZIndex=4
    corner(b,9)
    local bar = Instance.new("Frame", b)
    bar.Size=UDim2.new(0,0,0,22); bar.Position=UDim2.new(0,-4,0.5,-11)
    bar.BackgroundColor3=CLR.accent1; bar.BorderSizePixel=0
    bar.BackgroundTransparency=1; corner(bar,2)
    local icon = Instance.new("TextLabel", b)
    icon.Size=UDim2.new(0,26,1,0); icon.Position=UDim2.new(0,14,0,0)
    icon.BackgroundTransparency=1; icon.Text=tabIcon(name)
    icon.TextColor3=CLR.text_dim; icon.Font=FONT_B
    icon.TextSize=15; icon.ZIndex=5
    local label = Instance.new("TextLabel", b)
    label.Size=UDim2.new(1,-46,1,0); label.Position=UDim2.new(0,42,0,0)
    label.BackgroundTransparency=1; label.Text=name
    label.TextColor3=CLR.text_dim; label.Font=FONT_M
    label.TextSize=12; label.TextXAlignment=Enum.TextXAlignment.Left
    label.ZIndex=5
    b.MouseEnter:Connect(function()
        if currentTab~=name then
            tween(b, "BackgroundColor3", CLR.element_hi, 0.15)
            tween(b, "BackgroundTransparency", 0.2, 0.15)
        end
    end)
    b.MouseLeave:Connect(function()
        if currentTab~=name then
            tween(b, "BackgroundColor3", CLR.element, 0.15)
            tween(b, "BackgroundTransparency", 0.6, 0.15)
        end
    end)
    b.MouseButton1Click:Connect(function() selectTab(name) end)
    tabButtons[name] = {btn=b, icon=icon, label=label, bar=bar}
end

-- UI COMPONENTS
local UI = {}
function UI.section(parent, text)
    local f = Instance.new("Frame", parent)
    f.Size=UDim2.new(1,-8,0,26); f.BackgroundTransparency=1
    local bar = Instance.new("Frame", f)
    bar.Size=UDim2.new(0,3,0,14); bar.Position=UDim2.new(0,0,0,2)
    bar.BackgroundColor3=CLR.accent1; bar.BorderSizePixel=0; corner(bar,2)
    local bg = Instance.new("UIGradient", bar)
    bg.Color=ColorSequence.new(CLR.accent1, CLR.accent2); bg.Rotation=90
    local lbl = Instance.new("TextLabel", f)
    lbl.Size=UDim2.new(1,-12,0,20); lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1
    lbl.Text=string.upper(text); lbl.TextColor3=CLR.accent1_hi
    lbl.Font=FONT_B; lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local line = Instance.new("Frame", f)
    line.Size=UDim2.new(1,0,0,1); line.Position=UDim2.new(0,0,1,-3)
    line.BackgroundColor3=CLR.border; line.BorderSizePixel=0; line.BackgroundTransparency=0.5
end
function UI.toggle(parent, label, getter, setter)
    local row = Instance.new("Frame", parent)
    row.Size=UDim2.new(1,-8,0,34); row.BackgroundTransparency=1
    local lbl = Instance.new("TextLabel", row)
    lbl.Size=UDim2.new(1,-70,1,0); lbl.BackgroundTransparency=1
    lbl.Text=label; lbl.TextColor3=CLR.text; lbl.Font=FONT
    lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local sw = Instance.new("Frame", row)
    sw.Size=UDim2.new(0,46,0,22); sw.Position=UDim2.new(1,-48,0.5,-11)
    sw.BackgroundColor3 = getter() and CLR.accent1 or CLR.track
    sw.BorderSizePixel=0; corner(sw,11)
    local swGrad = Instance.new("UIGradient", sw)
    swGrad.Color=ColorSequence.new(CLR.accent1, CLR.accent2)
    swGrad.Enabled=getter()
    local swGlow = Instance.new("UIStroke", sw)
    swGlow.Color=CLR.accent2_hi; swGlow.Thickness=1.5
    swGlow.Transparency = getter() and 0.5 or 1
    local knob = Instance.new("Frame", sw)
    knob.Size=UDim2.new(0,18,0,18)
    knob.Position = getter() and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
    knob.BackgroundColor3=Color3.fromRGB(250,250,255)
    knob.BorderSizePixel=0; corner(knob,9)
    local knobDot = Instance.new("Frame", knob)
    knobDot.Size=UDim2.new(0,4,0,4); knobDot.Position=UDim2.new(0.5,-2,0.5,-2)
    knobDot.BackgroundColor3 = getter() and CLR.accent1 or CLR.text_dim
    knobDot.BorderSizePixel=0; corner(knobDot,2)
    local hit = Instance.new("TextButton", row)
    hit.Size=UDim2.new(1,0,1,0); hit.BackgroundTransparency=1; hit.Text=""
    hit.MouseButton1Click:Connect(function()
        local new = not getter()
        setter(new)
        swGrad.Enabled=new
        tween(sw, "BackgroundColor3", new and CLR.accent1 or CLR.track, 0.2)
        tween(knob, "Position",
            new and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9),
            0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        tween(swGlow, "Transparency", new and 0.5 or 1, 0.2)
        knobDot.BackgroundColor3 = new and CLR.accent1 or CLR.text_dim
    end)
end
function UI.slider(parent, label, min, max, getter, setter, fmt)
    local holder = Instance.new("Frame", parent)
    holder.Size=UDim2.new(1,-8,0,44); holder.BackgroundTransparency=1
    local lbl = Instance.new("TextLabel", holder)
    lbl.Size=UDim2.new(1,-100,0,14); lbl.BackgroundTransparency=1
    lbl.Text=label; lbl.TextColor3=CLR.text; lbl.Font=FONT
    lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local val = Instance.new("TextLabel", holder)
    val.Size=UDim2.new(0,100,0,14); val.Position=UDim2.new(1,-100,0,0)
    val.BackgroundTransparency=1
    val.Text = fmt and string.format(fmt, getter()) or tostring(getter())
    val.TextColor3=CLR.accent1_hi; val.Font=FONT_B
    val.TextSize=12; val.TextXAlignment=Enum.TextXAlignment.Right
    local track = Instance.new("Frame", holder)
    track.Size=UDim2.new(1,0,0,6); track.Position=UDim2.new(0,0,1,-14)
    track.BackgroundColor3=CLR.track; track.BorderSizePixel=0; corner(track,3)
    local rel = math.clamp((getter()-min)/(max-min), 0, 1)
    local fill = Instance.new("Frame", track)
    fill.Size=UDim2.new(rel,0,1,0); fill.BorderSizePixel=0; corner(fill,3)
    local fg = Instance.new("UIGradient", fill)
    fg.Color=ColorSequence.new(CLR.accent1, CLR.accent2)
    local grab = Instance.new("Frame", track)
    grab.Size=UDim2.new(0,14,0,14)
    grab.Position=UDim2.new(rel,-7,0.5,-7)
    grab.BackgroundColor3=Color3.fromRGB(250,250,255)
    grab.BorderSizePixel=0; corner(grab,7)
    local gg = Instance.new("UIStroke", grab)
    gg.Color=CLR.accent2_hi; gg.Thickness=1.5; gg.Transparency=0.4
    local hit = Instance.new("TextButton", holder)
    hit.Size=UDim2.new(1,0,0,26); hit.Position=UDim2.new(0,0,1,-24)
    hit.BackgroundTransparency=1; hit.Text=""
    local drag = false
    local bubble = nil
    local function setFromX(x)
        local r = math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
        local v = min + r*(max-min)
        fill.Size=UDim2.new(r,0,1,0)
        grab.Position=UDim2.new(r,-7,0.5,-7)
        val.Text = fmt and string.format(fmt, v) or tostring(math.floor(v))
        setter(v)
        if bubble then
            bubble.TextLabel.Text = val.Text
            bubble.Position = UDim2.new(r,-22,-1,-4)
        end
    end
    hit.MouseButton1Down:Connect(function()
        drag=true
        bubble = Instance.new("Frame", holder)
        bubble.Size=UDim2.new(0,44,0,20); bubble.BackgroundColor3=CLR.bg
        bubble.BorderSizePixel=0; corner(bubble,6)
        stroke(bubble, CLR.accent1, 1, 0.3)
        local bt = Instance.new("TextLabel", bubble)
        bt.Size=UDim2.new(1,0,1,0); bt.BackgroundTransparency=1
        bt.Text=val.Text; bt.TextColor3=CLR.accent1_hi
        bt.Font=FONT_B; bt.TextSize=11
        bubble.TextLabel=bt
        setFromX(UIS:GetMouseLocation().X)
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            setFromX(UIS:GetMouseLocation().X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 and drag then
            drag=false
            if bubble then
                tween(bubble, "BackgroundTransparency", 1, 0.2)
                bubble.TextLabel.TextTransparency=1
                task.delay(0.25, function() if bubble then bubble:Destroy(); bubble=nil end end)
            end
        end
    end)
end
function UI.selector(parent, options, getter, setter)
    local row = Instance.new("Frame", parent)
    row.Size=UDim2.new(1,-8,0,30); row.BackgroundTransparency=1
    local layout = Instance.new("UIListLayout", row)
    layout.FillDirection=Enum.FillDirection.Horizontal; layout.Padding=UDim.new(0,4)
    local btns = {}
    for _,opt in ipairs(options) do
        local b = Instance.new("TextButton", row)
        b.Size=UDim2.new(0,80,1,0)
        b.BackgroundColor3 = (getter()==opt) and CLR.accent1 or CLR.element
        b.BorderSizePixel=0; b.Text=opt; b.TextColor3=CLR.text
        b.Font=FONT_M; b.TextSize=11; b.AutoButtonColor=false
        corner(b,6)
        btns[opt]=b
        b.MouseButton1Click:Connect(function()
            setter(opt)
            for n,bb in pairs(btns) do
                tween(bb, "BackgroundColor3", n==opt and CLR.accent1 or CLR.element, 0.15)
            end
        end)
    end
end
function UI.colorPicker(parent, colors, onPick)
    local row = Instance.new("Frame", parent)
    row.Size=UDim2.new(1,-8,0,32); row.BackgroundTransparency=1
    local layout = Instance.new("UIListLayout", row)
    layout.FillDirection=Enum.FillDirection.Horizontal; layout.Padding=UDim.new(0,6)
    for _,c in ipairs(colors) do
        local cb = Instance.new("TextButton", row)
        cb.Size=UDim2.new(0,26,1,0); cb.BackgroundColor3=c
        cb.BorderSizePixel=0; cb.Text=""; cb.AutoButtonColor=false
        corner(cb,8); stroke(cb, CLR.border, 1, 0.4)
        cb.MouseEnter:Connect(function() tween(cb, "Size", UDim2.new(0,30,1,0), 0.12) end)
        cb.MouseLeave:Connect(function() tween(cb, "Size", UDim2.new(0,26,1,0), 0.12) end)
        cb.MouseButton1Click:Connect(function() if onPick then pcall(onPick, c) end end)
    end
end
function UI.label(parent, text, height, color)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size=UDim2.new(1,-8,0,height or 40); lbl.BackgroundTransparency=1
    lbl.Text=text; lbl.TextColor3=color or CLR.text_dim
    lbl.Font=FONT; lbl.TextSize=11; lbl.TextWrapped=true
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.TextYAlignment=Enum.TextYAlignment.Top
    return lbl
end

-- PAGE: AIMBOT
do
    local p = pages.Aimbot.frame
    UI.section(p, "Core")
    UI.toggle(p, "Enable Aimbot", function() return Config.aim_enabled end, function(v) Config.aim_enabled=v end)
    UI.toggle(p, "Team Check", function() return Config.team_check end, function(v) Config.team_check=v end)
    UI.toggle(p, "Friend Check", function() return Config.friend_check end, function(v) Config.friend_check=v end)
    UI.section(p, "Sensitivity")
    UI.slider(p, "Smooth", 1, 20, function() return Config.smooth end, function(v) Config.smooth=v end, "%.0f")
    UI.slider(p, "FOV", 50, 1200, function() return Config.max_fov end, function(v) Config.max_fov=v end, "%.0f px")
    UI.slider(p, "Max Step", 5, 100, function() return Config.max_step end, function(v) Config.max_step=v end, "%.0f px")
    UI.section(p, "Target Bone")
    UI.selector(p, {"Head","Torso"}, function() return Config.bone end, function(v) Config.bone=v end)
    UI.section(p, "Mode")
    UI.selector(p, {"Hold","Toggle"}, function() return Config.aim_mode end, function(v) Config.aim_mode=v end)
    UI.section(p, "Info")
    UI.label(p, "Клавиша C — aim.", 30)
end

-- PAGE: TRIGGER
do
    local p = pages.Trigger.frame
    UI.section(p, "Triggerbot")
    UI.toggle(p, "Enable Trigger", function() return Config.trigger_enabled end, function(v) Config.trigger_enabled=v end)
    UI.slider(p, "Delay", 20, 400, function() return Config.trigger_delay end, function(v) Config.trigger_delay=v end, "%.0f ms")
    UI.slider(p, "Trigger FOV", 5, 200, function() return Config.trigger_fov end, function(v) Config.trigger_fov=v end, "%.0f px")
    UI.section(p, "Mode")
    UI.selector(p, {"Hold","Toggle"}, function() return Config.trigger_mode end, function(v) Config.trigger_mode=v end)
    UI.section(p, "Stats")
    local hitsLbl = UI.label(p, "Shots: 0", 20, CLR.text)
    task.spawn(function()
        while hitsLbl.Parent do
            task.wait(0.3)
            hitsLbl.Text = "Shots: " .. State.hits
        end
    end)
end

-- PAGE: BHOP
do
    local p = pages.Bhop.frame
    UI.section(p, "Auto Bhop")
    UI.toggle(p, "Enable Auto Bhop", function() return Config.bhop_enabled end, function(v) Config.bhop_enabled=v end)
    UI.section(p, "Mode")
    UI.selector(p, {"Auto","Always"}, function() return Config.bhop_mode end, function(v) Config.bhop_mode=v end)
    UI.section(p, "Info")
    UI.label(p, "Клавиша X — toggle bhop.", 30)
    UI.section(p, "Stats")
    local hopsLbl = UI.label(p, "Hops: 0", 20, CLR.text)
    task.spawn(function()
        while hopsLbl.Parent do
            task.wait(0.2)
            hopsLbl.Text = "Hops: " .. State.hops
        end
    end)
end

-- PAGE: STRAFER
do
    local p = pages.Strafer.frame
    UI.section(p, "Auto Strafer")
    UI.toggle(p, "Enable Auto Strafer", function() return Config.strafer_enabled end, function(v) Config.strafer_enabled=v end)
    UI.section(p, "Settings")
    UI.slider(p, "Turn Speed", 1, 20, function() return Config.strafe_turn_speed end, function(v) Config.strafe_turn_speed=v end, "%.1f")
    UI.slider(p, "Switch Interval", 0.05, 0.5, function() return Config.strafe_switch_interval end, function(v) Config.strafe_switch_interval=v end, "%.2f s")
    UI.slider(p, "Min Speed", 1, 30, function() return Config.strafe_min_speed end, function(v) Config.strafe_min_speed=v end, "%.0f")
    UI.section(p, "Info")
    UI.label(p, "Клавиша Z — toggle strafer.", 30)
    UI.section(p, "Status")
    local statLbl = UI.label(p, "Idle", 20, CLR.text)
    task.spawn(function()
        while statLbl.Parent do
            task.wait(0.15)
            if State.strafing then
                statLbl.Text = "● STRAFING " .. (strafe_state.side==1 and "→ D" or "← A")
                statLbl.TextColor3 = CLR.accent1_hi
            else
                statLbl.Text = "Idle"; statLbl.TextColor3 = CLR.text_dim
            end
        end
    end)
end

-- PAGE: ANTI-AIM
do
    local p = pages["Anti-Aim"].frame
    UI.section(p, "Anti-Aim")
    UI.toggle(p, "Enable Anti-Aim", function() return Config.aa_enabled end, function(v) Config.aa_enabled=v end)
    UI.section(p, "Mode")
    UI.selector(p, {"Jitter","Spin","Static"}, function() return Config.aa_mode end, function(v) Config.aa_mode=v end)
    UI.section(p, "Settings")
    UI.slider(p, "Spin Speed", 1, 60, function() return Config.aa_speed end, function(v) Config.aa_speed=v end, "%.0f")
    UI.slider(p, "Jitter Amount", 10, 180, function() return Config.aa_jitter_amount end, function(v) Config.aa_jitter_amount=v end, "%.0f°")
    UI.slider(p, "Static Yaw", 0, 360, function() return Config.aa_static_yaw end, function(v) Config.aa_static_yaw=v end, "%.0f°")
    UI.section(p, "Info")
    UI.label(p,
        "Клавиша B — toggle anti-aim.\n\n" ..
        "Jitter — быстро дёргает модель влево/вправо.\n" ..
        "Spin — модель плавно крутится.\n" ..
        "Static — модель смотрит в одну сторону.\n\n" ..
        "Работает локально — видно только тебе.",
        120
    )
end

-- PAGE: ESP
do
    local p = pages.ESP.frame
    UI.section(p, "ESP Toggle")
    UI.toggle(p, "Enable ESP", function() return Config.esp_enabled end, function(v) Config.esp_enabled=v end)
    UI.section(p, "Elements")
    UI.toggle(p, "Box", function() return Config.esp_box end, function(v) Config.esp_box=v end)
    UI.toggle(p, "Name", function() return Config.esp_name end, function(v) Config.esp_name=v end)
    UI.toggle(p, "Distance", function() return Config.esp_dist end, function(v) Config.esp_dist=v end)
    UI.toggle(p, "Health Bar", function() return Config.esp_hp end, function(v) Config.esp_hp=v end)
    UI.toggle(p, "Skeleton", function() return Config.esp_skeleton end, function(v) Config.esp_skeleton=v end)
    UI.toggle(p, "Snapline", function() return Config.esp_snapline end, function(v) Config.esp_snapline=v end)
    UI.toggle(p, "Head Dot", function() return Config.esp_head_dot end, function(v) Config.esp_head_dot=v end)
    UI.toggle(p, "Offscreen Arrows", function() return Config.esp_offscreen end, function(v) Config.esp_offscreen=v end)
    UI.toggle(p, "Chams", function() return Config.esp_chams end, function(v) Config.esp_chams=v end)
    UI.section(p, "Box Style")
    UI.selector(p, {"Full","Corners","Fill"}, function() return Config.esp_box_style end, function(v) Config.esp_box_style=v end)
    UI.section(p, "Settings")
    UI.slider(p, "Max Distance", 100, 3000, function() return Config.esp_max_dist end, function(v) Config.esp_max_dist=v end, "%.0f m")
    UI.slider(p, "Chams Alpha", 0, 1, function() return Config.esp_chams_fill_alpha end, function(v) Config.esp_chams_fill_alpha=v end, "%.2f")
    UI.slider(p, "Fill Alpha", 0, 1, function() return Config.esp_box_fill_alpha end, function(v) Config.esp_box_fill_alpha=v end, "%.2f")
    UI.section(p, "Colors")
    UI.label(p, "Enemy:", 16, CLR.text)
    UI.colorPicker(p, {
        Color3.fromRGB(255,80,80), Color3.fromRGB(255,177,92),
        Color3.fromRGB(255,107,123), Color3.fromRGB(255,217,61),
        Color3.fromRGB(255,255,255),
    }, function(c) Config.esp_enemy_color=c end)
    UI.label(p, "Ally:", 16, CLR.text)
    UI.colorPicker(p, {
        Color3.fromRGB(80,220,120), Color3.fromRGB(125,211,192),
        Color3.fromRGB(160,229,212), Color3.fromRGB(200,130,255),
        Color3.fromRGB(255,255,255),
    }, function(c) Config.esp_ally_color=c end)
end

-- PAGE: VISUAL
do
    local p = pages.Visual.frame
    UI.section(p, "FOV Circle")
    UI.toggle(p, "Show FOV", function() return Config.fov_circle end, function(v) Config.fov_circle=v end)
    UI.colorPicker(p, {
        Color3.fromRGB(125,211,192), Color3.fromRGB(255,177,92),
        Color3.fromRGB(200,130,255), Color3.fromRGB(255,107,123),
        Color3.fromRGB(255,255,255),
    }, function(c) Config.fov_color=c end)

    UI.section(p, "FOV Changer")
    UI.toggle(p, "Enable FOV Changer", function() return Config.fov_changer end,
        function(v) Config.fov_changer=v; applyFov() end)
    UI.slider(p, "FOV Value", 20, 140, function() return Config.fov_value end,
        function(v) Config.fov_value=v; applyFov() end, "%.0f°")

    UI.section(p, "Viewmodel")
    UI.toggle(p, "Enable Viewmodel", function() return Config.vm_enabled end,
        function(v) Config.vm_enabled=v end)
    UI.slider(p, "Offset X", -5, 5, function() return Config.vm_offset_x end,
        function(v) Config.vm_offset_x=v end, "%.2f")
    UI.slider(p, "Offset Y", -5, 5, function() return Config.vm_offset_y end,
        function(v) Config.vm_offset_y=v end, "%.2f")
    UI.slider(p, "Offset Z", -5, 5, function() return Config.vm_offset_z end,
        function(v) Config.vm_offset_z=v end, "%.2f")
    UI.slider(p, "Rot X", -180, 180, function() return Config.vm_rot_x end,
        function(v) Config.vm_rot_x=v end, "%.0f°")
    UI.slider(p, "Rot Y", -180, 180, function() return Config.vm_rot_y end,
        function(v) Config.vm_rot_y=v end, "%.0f°")
    UI.slider(p, "Rot Z", -180, 180, function() return Config.vm_rot_z end,
        function(v) Config.vm_rot_z=v end, "%.0f°")

    UI.section(p, "Crosshair")
    UI.toggle(p, "Enable Crosshair", function() return Config.crosshair end,
        function(v) Config.crosshair=v; updateCrosshair() end)
    UI.slider(p, "Size", 2, 30, function() return Config.crosshair_size end,
        function(v) Config.crosshair_size=v; updateCrosshair() end, "%.0f")
    UI.slider(p, "Gap", 0, 20, function() return Config.crosshair_gap end,
        function(v) Config.crosshair_gap=v; updateCrosshair() end, "%.0f")
    UI.slider(p, "Thickness", 1, 5, function() return Config.crosshair_thick end,
        function(v) Config.crosshair_thick=v; updateCrosshair() end, "%.0f")
    UI.toggle(p, "Dot", function() return Config.crosshair_dot end,
        function(v) Config.crosshair_dot=v; updateCrosshair() end)

    UI.section(p, "Watermark")
    UI.toggle(p, "Show Watermark", function() return Config.watermark end, function(v) Config.watermark=v end)
end

-- PAGE: BINDS
local bindRows = {}
do
    local p = pages.Binds.frame
    UI.section(p, "Active Keybinds")

    local function makeBindRow(label, keyGetter, modeGetter, statusGetter)
        local row = Instance.new("Frame", p)
        row.Size=UDim2.new(1,-8,0,52)
        row.BackgroundColor3=CLR.element; row.BorderSizePixel=0; corner(row,8)
        local pad = Instance.new("UIPadding", row)
        pad.PaddingTop=UDim.new(0,8); pad.PaddingBottom=UDim.new(0,8)
        pad.PaddingLeft=UDim.new(0,10); pad.PaddingRight=UDim.new(0,10)

        local keyBox = Instance.new("Frame", row)
        keyBox.Size=UDim2.new(0,80,0,26); keyBox.Position=UDim2.new(0,0,0,0)
        keyBox.BackgroundColor3=CLR.accent1_dk; keyBox.BorderSizePixel=0
        corner(keyBox,6)
        local keyStroke = Instance.new("UIStroke", keyBox)
        keyStroke.Color=CLR.accent1_hi; keyStroke.Thickness=1.5; keyStroke.Transparency=0.3
        local keyLbl = Instance.new("TextLabel", keyBox)
        keyLbl.Size=UDim2.new(1,0,1,0); keyLbl.BackgroundTransparency=1
        keyLbl.Text="?"; keyLbl.TextColor3=CLR.text
        keyLbl.Font=FONT_BLACK; keyLbl.TextSize=13

        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Size=UDim2.new(1,-220,0,16); nameLbl.Position=UDim2.new(0,92,0,0)
        nameLbl.BackgroundTransparency=1; nameLbl.Text=label
        nameLbl.TextColor3=CLR.text; nameLbl.Font=FONT_B; nameLbl.TextSize=13
        nameLbl.TextXAlignment=Enum.TextXAlignment.Left

        local modeLbl = Instance.new("TextLabel", row)
        modeLbl.Size=UDim2.new(1,-220,0,12); modeLbl.Position=UDim2.new(0,92,0,18)
        modeLbl.BackgroundTransparency=1; modeLbl.Text="?"
        modeLbl.TextColor3=CLR.text_dim; modeLbl.Font=FONT_M; modeLbl.TextSize=10
        modeLbl.TextXAlignment=Enum.TextXAlignment.Left

        local statBox = Instance.new("Frame", row)
        statBox.Size=UDim2.new(0,80,0,24); statBox.Position=UDim2.new(1,-80,0.5,-12)
        statBox.BackgroundColor3=CLR.track; statBox.BorderSizePixel=0
        corner(statBox,6)
        local statStroke = Instance.new("UIStroke", statBox)
        statStroke.Color=CLR.border; statStroke.Thickness=1; statStroke.Transparency=0.5
        local statLbl = Instance.new("TextLabel", statBox)
        statLbl.Size=UDim2.new(1,0,1,0); statLbl.BackgroundTransparency=1
        statLbl.Text="OFF"; statLbl.TextColor3=CLR.text_dim
        statLbl.Font=FONT_BLACK; statLbl.TextSize=11

        table.insert(bindRows, {
            keyLbl=keyLbl, modeLbl=modeLbl, statLbl=statLbl,
            statBox=statBox, statStroke=statStroke,
            keyGetter=keyGetter, modeGetter=modeGetter, statusGetter=statusGetter,
        })
    end

    makeBindRow("Aimbot", function() return Config.aim_key end, function() return Config.aim_mode end, function() return Config.aim_enabled end)
    makeBindRow("Trigger", function() return Config.trigger_key end, function() return Config.trigger_mode end, function() return Config.trigger_enabled end)
    makeBindRow("Bhop", function() return Config.bhop_key end, function() return "Toggle" end, function() return Config.bhop_enabled end)
    makeBindRow("Strafer", function() return Config.strafer_key end, function() return "Toggle" end, function() return Config.strafer_enabled end)
    makeBindRow("Anti-Aim", function() return Config.aa_key end, function() return "Toggle" end, function() return Config.aa_enabled end)
    makeBindRow("Menu", function() return Config.menu_key end, function() return "Toggle" end, function() return State.open end)

    task.spawn(function()
        while pages.Binds.frame.Parent do
            task.wait(0.15)
            for _,r in ipairs(bindRows) do
                local k = r.keyGetter()
                r.keyLbl.Text = tostring(k):gsub("Enum.KeyCode.", "")
                r.modeLbl.Text = r.modeGetter()
                local active = r.statusGetter()
                if active then
                    r.statLbl.Text="ON"; r.statLbl.TextColor3=CLR.green
                    r.statBox.BackgroundColor3=CLR.green
                    r.statBox.BackgroundTransparency=0.7
                    r.statStroke.Color=CLR.green
                else
                    r.statLbl.Text="OFF"; r.statLbl.TextColor3=CLR.text_dim
                    r.statBox.BackgroundColor3=CLR.track
                    r.statBox.BackgroundTransparency=0
                    r.statStroke.Color=CLR.border
                end
            end
        end
    end)
end

-- PAGE: SETTINGS
do
    local p = pages.Settings.frame
    UI.section(p, "Menu")
    UI.toggle(p, "Blur", function() return Config.blur end, function(v) Config.blur=v end)
    UI.section(p, "Live Status")
    local statLbl = UI.label(p, "", 140, CLR.text)
    task.spawn(function()
        while statLbl.Parent do
            task.wait(0.3)
            statLbl.Text = string.format(
                "  Enemies: %d\n  Locked: %s\n  Aim: %s\n  Trigger: %s\n  Bhop: %s\n  Strafer: %s\n  Anti-Aim: %s\n  Team: %s | Friend: %s",
                State.enemies,
                State.locked and "YES" or "NO",
                Config.aim_enabled and "ON" or "OFF",
                Config.trigger_enabled and "ON" or "OFF",
                Config.bhop_enabled and "ON" or "OFF",
                Config.strafer_enabled and "ON" or "OFF",
                Config.aa_enabled and "ON" or "OFF",
                Config.team_check and "ON" or "OFF",
                Config.friend_check and "ON" or "OFF"
            )
        end
    end)
end

-- PAGE: ABOUT
do
    local p = pages.About.frame
    UI.section(p, "Aurora Legit Bot v3.1")
    UI.label(p,
        "Клавиши:\n" ..
        "  C — Aimbot\n" ..
        "  V — Trigger\n" ..
        "  X — Bhop\n" ..
        "  Z — Strafer\n" ..
        "  B — Anti-Aim\n" ..
        "  RShift — Menu\n\n" ..
        "Фичи:\n" ..
        "  Aimbot, Trigger, Bhop, Strafer\n" ..
        "  Anti-Aim (Jitter/Spin/Static)\n" ..
        "  FOV Changer, Viewmodel Changer\n" ..
        "  ESP (расширенный), Binds вкладка\n\n" ..
        "Credits: Fox + Jack · 2026",
        280
    )
end

updateCrosshair()

UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Config.menu_key then
        if State.open then closeMenu() else openMenu() end
    end
end)

selectTab("Aimbot")
task.wait(0.3)
openMenu()
notif("Aurora Legit v3.1 loaded.", 4)

_G.AuroraLegit = { Config=Config, State=State, open=openMenu, close=closeMenu }

end)()
