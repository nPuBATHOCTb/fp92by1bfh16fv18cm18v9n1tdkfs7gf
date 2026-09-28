--[[
    ============================================================
      Aurora Legit Bot for BloxStrike v1.0
      Человекоподобный аим · плавное наведение · FOV · visibility
      Aurora UI  ·  RShift — меню
    ============================================================
]]

(function()

-- ============================================================
--  SERVICES
-- ============================================================
local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local RS       = game:GetService("RunService")
local TS       = game:GetService("TweenService")
local SG       = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local WS       = game:GetService("Workspace")
local LP       = Players.LocalPlayer
local Cam      = WS.CurrentCamera

-- CLEANUP
do
    local rem = {}
    for _, svc in ipairs({ game:GetService("CoreGui"), LP:WaitForChild("PlayerGui") }) do
        pcall(function()
            for _, c in ipairs(svc:GetChildren()) do
                if c.Name:sub(1,6) == "LB_" then table.insert(rem, c) end
            end
        end)
    end
    if gethui then
        pcall(function()
            for _, c in ipairs(gethui():GetChildren()) do
                if c.Name:sub(1,6) == "LB_" then table.insert(rem, c) end
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

-- ============================================================
--  THEME
-- ============================================================
local CLR = {
    bg         = Color3.fromRGB(10,16,32),
    panel      = Color3.fromRGB(19,26,46),
    panel_hi   = Color3.fromRGB(26,35,64),
    element    = Color3.fromRGB(31,42,72),
    element_hi = Color3.fromRGB(42,55,87),
    border     = Color3.fromRGB(58,72,112),
    text       = Color3.fromRGB(237,239,247),
    text_dim   = Color3.fromRGB(138,148,184),
    accent1    = Color3.fromRGB(125,211,192),
    accent1_hi = Color3.fromRGB(160,229,212),
    accent1_dk = Color3.fromRGB(75,168,149),
    accent2    = Color3.fromRGB(255,177,92),
    accent2_hi = Color3.fromRGB(255,201,137),
    accent2_dk = Color3.fromRGB(204,138,56),
    green      = Color3.fromRGB(82,214,122),
    red        = Color3.fromRGB(255,107,123),
    yellow     = Color3.fromRGB(255,217,61),
    track      = Color3.fromRGB(38,48,76),
}
local FONT       = Enum.Font.Gotham
local FONT_B     = Enum.Font.GothamBold
local FONT_M     = Enum.Font.GothamMedium
local FONT_BLACK = Enum.Font.GothamBlack

-- ============================================================
--  CONFIG
-- ============================================================
local Config = {
    -- AIMBOT
    enabled     = false,
    aim_key     = Enum.UserInputType.MouseButton2,
    fov         = 150,
    smooth      = 8,          -- 1 = мгновенно, 20 = очень плавно
    bone        = "Head",
    team_check  = true,
    friend_check = true,
    wall_check  = true,
    sticky      = true,
    sticky_time = 0.5,
    humanize    = true,
    humanize_amount = 0.002,
    random_bone = false,
    priority    = "FOV",      -- FOV / Distance / Health

    -- PREDICTION
    prediction  = true,
    pred_amount = 0.12,

    -- TRIGGER
    trigger     = false,
    trigger_key = Enum.KeyCode.E,
    trigger_fov = 4,
    trigger_delay = 60,

    -- VISUAL
    fov_circle  = true,
    fov_color   = Color3.fromRGB(125,211,192),
    crosshair   = false,
    crosshair_style = "Cross",
    crosshair_color = Color3.fromRGB(125,211,192),
    crosshair_size = 8,
    crosshair_gap = 5,
    crosshair_thick = 1,
    crosshair_dot = true,

    watermark   = true,

    -- MENU
    menu_key    = Enum.KeyCode.RightShift,
    blur        = true,
    animations  = true,
}

-- ============================================================
--  STATE
-- ============================================================
local State = {
    open = false, busy = false,
    target = nil, target_plr = nil,
    sticky_target = nil, sticky_part = nil, sticky_time = 0,
    enemies = 0, locked = false, holding = false, trigging = false,
}

-- ============================================================
--  UTIL
-- ============================================================
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
    pcall(function() SG:SetCore("SendNotification", {Title = "Legit Bot", Text = tostring(text), Duration = dur or 3}) end)
end

-- ============================================================
--  BLUR
-- ============================================================
local blurFx = Instance.new("BlurEffect")
blurFx.Name = "LB_Blur"; blurFx.Size = 0; blurFx.Enabled = false
blurFx.Parent = Lighting
local blurTween
local function setBlur(on)
    if blurTween then blurTween:Cancel() end
    blurFx.Enabled = true
    blurTween = TS:Create(blurFx, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = on and 12 or 0})
    blurTween:Play()
    if not on then task.delay(0.4, function() if blurFx.Size < 1 then blurFx.Enabled = false end end) end
end

-- ============================================================
--  TARGETING
-- ============================================================
local function isEnemy(plr)
    if plr == LP then return false end
    if not plr.Parent or not plr.Character then return false end
    if Config.friend_check and LP:IsFriendsWith(plr.UserId) then return false end
    if not Config.team_check then return true end
    if plr.Team and LP.Team and plr.Team == LP.Team then return false end
    if plr.TeamColor and LP.TeamColor and plr.TeamColor == LP.TeamColor
        and plr.TeamColor.Name ~= "White" and plr.TeamColor.Name ~= "Medium stone grey" then
        return false
    end
    return true
end

local function getBonePart(char)
    if not char then return nil end
    if Config.random_bone or Config.bone == "Random" then
        local bones = { "Head", "UpperTorso", "LowerTorso" }
        return char:FindFirstChild(bones[math.random(1, #bones)]) or char:FindFirstChild("Head")
    end
    if Config.bone == "Head" then return char:FindFirstChild("Head") end
    if Config.bone == "Neck" then return char:FindFirstChild("Neck") or char:FindFirstChild("Head") end
    if Config.bone == "Torso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") end
    if Config.bone == "HRP" then return char:FindFirstChild("HumanoidRootPart") end
    return char:FindFirstChild("Head")
end

local function isVisible(part, targetChar)
    if not Config.wall_check then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LP.Character, targetChar }
    local hit = WS:Raycast(Cam.CFrame.Position, part.Position - Cam.CFrame.Position, params)
    return not hit
end

local function predictPosition(part, plr)
    if not Config.prediction then return part.Position end
    local char = plr and plr.Character
    if not char then return part.Position end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return part.Position end
    return part.Position + hrp.AssemblyLinearVelocity * Config.pred_amount
end

local function findTarget(fovOverride)
    local fov = fovOverride or Config.fov
    local center = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)

    -- Sticky
    if Config.sticky and State.sticky_target and State.sticky_target.Parent and State.sticky_target.Character then
        if tick() - State.sticky_time < Config.sticky_time then
            local char = State.sticky_target.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local part = State.sticky_part or getBonePart(char)
                if part and part.Parent then
                    local sp, on = Cam:WorldToViewportPoint(part.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d <= fov then return part, State.sticky_target end
                    end
                end
            end
        end
        State.sticky_target, State.sticky_part = nil, nil
    end

    local best, bestScore, bestPlr = nil, math.huge, nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if not isEnemy(plr) then continue end
        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local part = getBonePart(char)
        if not part then continue end
        local pos = predictPosition(part, plr)
        local sp, on = Cam:WorldToViewportPoint(pos)
        if not on then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d > fov then continue end
        if not isVisible(part, char) then continue end

        local score = d
        if Config.priority == "Distance" then
            local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            score = myHRP and (myHRP.Position - part.Position).Magnitude or 9999
        elseif Config.priority == "Health" then
            score = hum.Health
        end

        if score < bestScore then
            bestScore, best, bestPlr = score, part, plr
        end
    end

    if Config.sticky and bestPlr then
        State.sticky_target = bestPlr
        State.sticky_part = best
        State.sticky_time = tick()
    end
    return best, bestPlr
end

-- ============================================================
--  KEY STATE
-- ============================================================
local aimHeld = false
local aimToggled = false
local trigHeld = false

UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.UserInputType == Config.aim_key then
        if Config.aim_mode == "Toggle" then
            aimToggled = not aimToggled
        else aimHeld = true end
    end
    if i.KeyCode == Config.trigger_key then trigHeld = true end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Config.aim_key and Config.aim_mode == "Hold" then aimHeld = false end
    if i.KeyCode == Config.trigger_key then trigHeld = false end
end)

local function isAimActive()
    if Config.aim_mode == "Toggle" then return aimToggled end
    return aimHeld
end

-- ============================================================
--  AIMBOT LOOP
-- ============================================================
pcall(function() RS:UnbindFromRenderStep("LB_Aim") end)
RS:BindToRenderStep("LB_Aim", Enum.RenderPriority.Camera.Value + 1, function(dt)
    local cnt = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            cnt = cnt + 1
        end
    end
    State.enemies = cnt
    State.holding = isAimActive()

    if not Config.enabled or not isAimActive() then
        State.target = nil; State.locked = false
        return
    end

    local target, plr = findTarget()
    State.target = target
    if not target then State.locked = false; return end

    local pos = predictPosition(target, plr)
    local want = CFrame.new(Cam.CFrame.Position, pos)
    local t = math.clamp((1 / math.max(Config.smooth, 1)) * dt * 60, 0, 1)

    if Config.humanize then
        local j = math.sin(tick() * 3) * Config.humanize_amount
        want = want * CFrame.Angles(j, j * 0.5, 0)
    end

    Cam.CFrame = Cam.CFrame:Lerp(want, t)
    State.locked = true
end)

-- ============================================================
--  TRIGGERBOT
-- ============================================================
local lastTrig = 0
local function fireMouse()
    if mouse1click then mouse1click() return end
    if VirtualInputManager then
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.008)
        vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
end

task.spawn(function()
    while true do
        task.wait(0.01)
        State.trigging = false
        if Config.trigger and trigHeld then
            if tick() - lastTrig >= Config.trigger_delay / 1000 then
                local target = findTarget(Config.trigger_fov)
                if target then
                    fireMouse()
                    lastTrig = tick()
                    State.trigging = true
                end
            end
        end
    end
end)

-- ============================================================
--  VISUALS — FOV Circle + Crosshair + Watermark
-- ============================================================
local visGui = Instance.new("ScreenGui")
visGui.Name = "LB_Vis"; visGui.ResetOnSpawn = false
visGui.IgnoreGuiInset = true; visGui.DisplayOrder = 2147483646
visGui.Parent = PARENT

-- FOV Circle
local fovCircle = nil
if Drawing then
    pcall(function()
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 1
        fovCircle.NumSides = 64
        fovCircle.Filled = false
        fovCircle.Transparency = 0.6
        fovCircle.Visible = false
    end)
end

task.spawn(function()
    while true do
        task.wait(0.05)
        if fovCircle then
            if Config.fov_circle and Config.enabled then
                fovCircle.Visible = true
                fovCircle.Position = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
                fovCircle.Radius = Config.fov
                fovCircle.Color = Config.fov_color
            else
                fovCircle.Visible = false
            end
        end
    end
end)

-- Crosshair
local crossGui = Instance.new("ScreenGui", visGui)
crossGui.Name = "Cross"; crossGui.IgnoreGuiInset = true
crossGui.DisplayOrder = 2147483645; crossGui.ResetOnSpawn = false

local crossHolder = Instance.new("Frame", crossGui)
crossHolder.AnchorPoint = Vector2.new(0.5, 0.5)
crossHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
crossHolder.Size = UDim2.new(0, 100, 0, 100)
crossHolder.BackgroundTransparency = 1

local crossParts = {}
for _, n in ipairs({ "top", "bot", "left", "right", "dot" }) do
    local p = Instance.new("Frame", crossHolder)
    p.Name = n; p.BackgroundColor3 = Config.crosshair_color
    p.BorderSizePixel = 0; p.Visible = false
    crossParts[n] = p
end

local function updateCrosshair()
    crossGui.Enabled = Config.crosshair
    for _, p in pairs(crossParts) do p.Visible = false; p.BackgroundColor3 = Config.crosshair_color end
    if not Config.crosshair then return end
    local sz, th, gap = Config.crosshair_size, Config.crosshair_thick, Config.crosshair_gap
    if Config.crosshair_style == "Cross" then
        crossParts.top.Visible = true; crossParts.top.Size = UDim2.new(0, th, 0, sz); crossParts.top.Position = UDim2.new(0.5, -th/2, 0.5, -sz-gap)
        crossParts.bot.Visible = true; crossParts.bot.Size = UDim2.new(0, th, 0, sz); crossParts.bot.Position = UDim2.new(0.5, -th/2, 0.5, gap)
        crossParts.left.Visible = true; crossParts.left.Size = UDim2.new(0, sz, 0, th); crossParts.left.Position = UDim2.new(0.5, -sz-gap, 0.5, -th/2)
        crossParts.right.Visible = true; crossParts.right.Size = UDim2.new(0, sz, 0, th); crossParts.right.Position = UDim2.new(0.5, gap, 0.5, -th/2)
    elseif Config.crosshair_style == "Dot" then
        crossParts.dot.Visible = true; crossParts.dot.Size = UDim2.new(0, sz, 0, sz); crossParts.dot.Position = UDim2.new(0.5, -sz/2, 0.5, -sz/2)
    elseif Config.crosshair_style == "Circle" then
        for _, s in ipairs({ "top", "bot", "left", "right" }) do crossParts[s].Visible = true; crossParts[s].Size = UDim2.new(0, th, 0, th) end
        crossParts.top.Position = UDim2.new(0.5, -th/2, 0.5, -sz)
        crossParts.bot.Position = UDim2.new(0.5, -th/2, 0.5, sz)
        crossParts.left.Position = UDim2.new(0.5, -sz, 0.5, -th/2)
        crossParts.right.Position = UDim2.new(0.5, sz, 0.5, -th/2)
    end
    if Config.crosshair_dot and Config.crosshair_style ~= "Dot" then
        crossParts.dot.Visible = true; crossParts.dot.Size = UDim2.new(0, 2, 0, 2); crossParts.dot.Position = UDim2.new(0.5, -1, 0.5, -1)
    end
end

-- Watermark
local wmGui = Instance.new("ScreenGui", visGui)
wmGui.Name = "WM"; wmGui.IgnoreGuiInset = true
wmGui.DisplayOrder = 2147483643; wmGui.ResetOnSpawn = false

local wmFrame = Instance.new("Frame", wmGui)
wmFrame.Size = UDim2.new(0, 320, 0, 28); wmFrame.Position = UDim2.new(0, 20, 0, 20)
wmFrame.BackgroundColor3 = CLR.bg; wmFrame.BackgroundTransparency = 0.15
wmFrame.BorderSizePixel = 0; corner(wmFrame, 8)
stroke(wmFrame, CLR.accent1, 1, 0.4)

local wmBrand = Instance.new("Frame", wmFrame)
wmBrand.Size = UDim2.new(0, 14, 0, 14); wmBrand.Position = UDim2.new(0, 10, 0.5, -7)
wmBrand.BackgroundColor3 = CLR.accent1; wmBrand.BorderSizePixel = 0; corner(wmBrand, 4)

local wmLbl = Instance.new("TextLabel", wmFrame)
wmLbl.Size = UDim2.new(0, 120, 1, 0); wmLbl.Position = UDim2.new(0, 30, 0, 0)
wmLbl.BackgroundTransparency = 1; wmLbl.Text = "LEGIT BOT"
wmLbl.TextColor3 = CLR.text; wmLbl.Font = FONT_BLACK; wmLbl.TextSize = 12
wmLbl.TextXAlignment = Enum.TextXAlignment.Left

local wmSep = Instance.new("Frame", wmFrame)
wmSep.Size = UDim2.new(0, 1, 0.5, 0); wmSep.Position = UDim2.new(0, 100, 0.25, 0)
wmSep.BackgroundColor3 = CLR.border; wmSep.BorderSizePixel = 0; wmSep.BackgroundTransparency = 0.4

local wmFps = Instance.new("TextLabel", wmFrame)
wmFps.Size = UDim2.new(0, 60, 1, 0); wmFps.Position = UDim2.new(0, 108, 0, 0)
wmFps.BackgroundTransparency = 1; wmFps.Text = "60 FPS"
wmFps.TextColor3 = CLR.text; wmFps.Font = FONT_M; wmFps.TextSize = 11
wmFps.TextXAlignment = Enum.TextXAlignment.Left

local wmSep2 = Instance.new("Frame", wmFrame)
wmSep2.Size = UDim2.new(0, 1, 0.5, 0); wmSep2.Position = UDim2.new(0, 168, 0.25, 0)
wmSep2.BackgroundColor3 = CLR.border; wmSep2.BorderSizePixel = 0; wmSep2.BackgroundTransparency = 0.4

local wmStatus = Instance.new("TextLabel", wmFrame)
wmStatus.Size = UDim2.new(1, -180, 1, 0); wmStatus.Position = UDim2.new(0, 178, 0, 0)
wmStatus.BackgroundTransparency = 1; wmStatus.Text = "● IDLE"
wmStatus.TextColor3 = CLR.text_dim; wmStatus.Font = FONT_B; wmStatus.TextSize = 11
wmStatus.TextXAlignment = Enum.TextXAlignment.Left

-- ============================================================
--  MENU ROOT
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "LB_Main"; gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 2147483647; gui.Parent = PARENT

local overlay = Instance.new("Frame", gui)
overlay.Size = UDim2.new(1,0,1,0); overlay.BackgroundColor3 = Color3.new(0,0,0)
overlay.BackgroundTransparency = 1; overlay.BorderSizePixel = 0; overlay.Visible = false

local group = Instance.new("CanvasGroup", gui)
group.Size = UDim2.new(0, 720, 0, 520)
group.Position = UDim2.new(0.5, -360, 0.5, -260)
group.BackgroundTransparency = 1; group.GroupTransparency = 1; group.BorderSizePixel = 0

local winScale = Instance.new("UIScale", group); winScale.Scale = 1

local shadow = Instance.new("Frame", group)
shadow.Size = UDim2.new(1,40,1,40); shadow.Position = UDim2.new(0,-20,0,-20)
shadow.BackgroundColor3 = Color3.new(0,0,0); shadow.BackgroundTransparency = 0.45
shadow.BorderSizePixel = 0; shadow.ZIndex = -1; corner(shadow, 24)
local shadowGrad = Instance.new("UIGradient", shadow)
shadowGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.05),
    NumberSequenceKeypoint.new(0.55, 0.85),
    NumberSequenceKeypoint.new(1, 1),
})
shadowGrad.Rotation = 90

local win = Instance.new("Frame", group)
win.Size = UDim2.new(1,0,1,0); win.BackgroundColor3 = CLR.bg
win.BackgroundTransparency = 0.04; win.BorderSizePixel = 0
win.Active = true; win.ClipsDescendants = true
corner(win, 16)
local winStroke = stroke(win, CLR.accent1_dk, 1.5, 0.2)

local topBar = Instance.new("Frame", win)
topBar.Size = UDim2.new(1,0,0,3); topBar.BorderSizePixel = 0
topBar.BackgroundColor3 = CLR.accent1
local topGrad = Instance.new("UIGradient", topBar)
topGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, CLR.accent1),
    ColorSequenceKeypoint.new(0.25, CLR.accent1_hi),
    ColorSequenceKeypoint.new(0.5, CLR.accent2),
    ColorSequenceKeypoint.new(0.75, CLR.accent2_hi),
    ColorSequenceKeypoint.new(1, CLR.accent1),
})
task.spawn(function()
    local t = 0
    while topBar.Parent do
        t = t + 0.015
        topGrad.Offset = Vector2.new(math.sin(t), 0)
        task.wait(0.03)
    end
end)

local header = Instance.new("Frame", win)
header.Size = UDim2.new(1,0,0,60); header.Position = UDim2.new(0,0,0,3)
header.BackgroundColor3 = CLR.panel; header.BackgroundTransparency = 0.05
header.BorderSizePixel = 0; header.ZIndex = 2
local headerGrad = Instance.new("UIGradient", header)
headerGrad.Color = ColorSequence.new(CLR.panel_hi, CLR.panel); headerGrad.Rotation = 90

local brandMark = Instance.new("Frame", header)
brandMark.Size = UDim2.new(0,18,0,18); brandMark.Position = UDim2.new(0,22,0.5,-9)
brandMark.BackgroundColor3 = CLR.accent1; brandMark.BorderSizePixel = 0
corner(brandMark, 5)
local brandGrad = Instance.new("UIGradient", brandMark)
brandGrad.Color = ColorSequence.new(CLR.accent1, CLR.accent2); brandGrad.Rotation = 45
local brandDot = Instance.new("Frame", brandMark)
brandDot.Size = UDim2.new(0,6,0,6); brandDot.Position = UDim2.new(0.5,-3,0.5,-3)
brandDot.BackgroundColor3 = Color3.fromRGB(255,255,255)
brandDot.BorderSizePixel = 0; corner(brandDot, 3)
local brandGlow = Instance.new("UIStroke", brandMark)
brandGlow.Color = CLR.accent2_hi; brandGlow.Thickness = 1.5; brandGlow.Transparency = 0.4
task.spawn(function()
    while brandMark.Parent do
        tween(brandGlow, "Transparency", 0.9, 1.2); task.wait(1.2)
        tween(brandGlow, "Transparency", 0.2, 1.2); task.wait(1.2)
    end
end)

local brandText = Instance.new("TextLabel", header)
brandText.Size = UDim2.new(0,220,0,22); brandText.Position = UDim2.new(0,50,0,10)
brandText.BackgroundTransparency = 1; brandText.Text = "LEGIT BOT"
brandText.TextColor3 = CLR.text; brandText.Font = FONT_BLACK
brandText.TextSize = 20; brandText.TextXAlignment = Enum.TextXAlignment.Left
brandText.TextStrokeTransparency = 0; brandText.TextStrokeColor3 = Color3.new(0,0,0)

local subText = Instance.new("TextLabel", header)
subText.Size = UDim2.new(0,300,0,14); subText.Position = UDim2.new(0,50,0,32)
subText.BackgroundTransparency = 1; subText.Text = "bloxstrike  ·  humanized aim"
subText.TextColor3 = CLR.text_dim; subText.Font = FONT_M
subText.TextSize = 10; subText.TextXAlignment = Enum.TextXAlignment.Left

local statusDot = Instance.new("Frame", header)
statusDot.Size = UDim2.new(0,8,0,8); statusDot.Position = UDim2.new(1,-180,0.5,-4)
statusDot.BackgroundColor3 = CLR.green; statusDot.BorderSizePixel = 0
corner(statusDot, 4)
local statusGlow = Instance.new("UIStroke", statusDot)
statusGlow.Color = CLR.green; statusGlow.Thickness = 2; statusGlow.Transparency = 0.5
task.spawn(function()
    while statusDot.Parent do
        tween(statusGlow, "Transparency", 1, 1.2); task.wait(1.2)
        tween(statusGlow, "Transparency", 0.5, 1.2); task.wait(1.2)
    end
end)
local statusText = Instance.new("TextLabel", header)
statusText.Size = UDim2.new(0,80,0,14); statusText.Position = UDim2.new(1,-166,0.5,-7)
statusText.BackgroundTransparency = 1; statusText.Text = "READY"
statusText.TextColor3 = CLR.green; statusText.Font = FONT_B
statusText.TextSize = 10; statusText.TextXAlignment = Enum.TextXAlignment.Left

local function makeHdrBtn(txt, isClose)
    local b = Instance.new("TextButton", header)
    b.Size = UDim2.new(0,32,0,28); b.BackgroundColor3 = CLR.element
    b.BackgroundTransparency = 0.3; b.BorderSizePixel = 0
    b.Text = txt; b.TextColor3 = CLR.text_dim
    b.Font = FONT_B; b.TextSize = 15; b.AutoButtonColor = false
    corner(b, 8); b.ZIndex = 5
    local bg = b.BackgroundColor3
    b.MouseEnter:Connect(function()
        tween(b, "BackgroundTransparency", 0, 0.12)
        if isClose then tween(b, "BackgroundColor3", CLR.red, 0.12)
        else tween(b, "BackgroundColor3", CLR.accent1, 0.12) end
        b.TextColor3 = CLR.text
    end)
    b.MouseLeave:Connect(function()
        tween(b, "BackgroundTransparency", 0.3, 0.12)
        tween(b, "BackgroundColor3", bg, 0.12); b.TextColor3 = CLR.text_dim
    end)
    return b
end
local closeBtn = makeHdrBtn("×", true); closeBtn.Position = UDim2.new(1,-44,0.5,-14)
local minBtn = makeHdrBtn("–", false); minBtn.Position = UDim2.new(1,-80,0.5,-14)

local function openMenu(instant)
    if State.open or State.busy then return end
    State.busy = true; State.open = true
    group.Visible = true; overlay.Visible = true
    tween(overlay, "BackgroundTransparency", 0.5, 0.2)
    if instant then
        winScale.Scale = 1; group.GroupTransparency = 0; setBlur(true)
        State.busy = false; return
    end
    winScale.Scale = 0.85; group.GroupTransparency = 1
    group.Position = UDim2.new(0.5,-360,0.5,-250)
    tween(winScale, "Scale", 1, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    tween(group, "GroupTransparency", 0, 0.28, Enum.EasingStyle.Quart)
    tween(group, "Position", UDim2.new(0.5,-360,0.5,-260), 0.38, Enum.EasingStyle.Quart)
    setBlur(true)
    task.wait(0.4); State.busy = false
end
local function closeMenu(instant)
    if not State.open or State.busy then return end
    State.busy = true; State.open = false
    tween(overlay, "BackgroundTransparency", 1, 0.2)
    task.delay(0.22, function() overlay.Visible = false end)
    if instant then
        group.GroupTransparency = 1; setBlur(false); State.busy = false; return
    end
    tween(winScale, "Scale", 0.85, 0.26, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    tween(group, "GroupTransparency", 1, 0.24, Enum.EasingStyle.Quart)
    tween(group, "Position", UDim2.new(0.5,-360,0.5,-250), 0.26, Enum.EasingStyle.Quart)
    setBlur(false)
    task.wait(0.3); State.busy = false
end
closeBtn.MouseButton1Click:Connect(function() closeMenu() end)
minBtn.MouseButton1Click:Connect(function() closeMenu() end)

do
    local drag, ds, sp
    header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true; ds = i.Position; sp = group.Position
        end
    end)
    header.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            group.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
end

-- Sidebar
local sidebar = Instance.new("Frame", win)
sidebar.Size = UDim2.new(0,165,1,-63-30); sidebar.Position = UDim2.new(0,12,0,66)
sidebar.BackgroundColor3 = CLR.panel; sidebar.BackgroundTransparency = 0.4
sidebar.BorderSizePixel = 0; sidebar.ZIndex = 2; corner(sidebar, 12)
local sidePad = Instance.new("UIPadding", sidebar)
sidePad.PaddingTop = UDim.new(0,10); sidePad.PaddingBottom = UDim.new(0,10)
sidePad.PaddingLeft = UDim.new(0,8); sidePad.PaddingRight = UDim.new(0,8)
local sideLayout = Instance.new("UIListLayout", sidebar)
sideLayout.Padding = UDim.new(0,4); sideLayout.SortOrder = Enum.SortOrder.LayoutOrder

local content = Instance.new("Frame", win)
content.Size = UDim2.new(1,-190,1,-63-30); content.Position = UDim2.new(0,180,0,66)
content.BackgroundTransparency = 1; content.BorderSizePixel = 0; content.ZIndex = 2

local footer = Instance.new("Frame", win)
footer.Size = UDim2.new(1,0,0,28); footer.Position = UDim2.new(0,0,1,-28)
footer.BackgroundColor3 = CLR.panel; footer.BackgroundTransparency = 0.3
footer.BorderSizePixel = 0; footer.ZIndex = 4
local footerDot = Instance.new("Frame", footer)
footerDot.Size = UDim2.new(0,5,0,5); footerDot.Position = UDim2.new(0,18,0.5,-2.5)
footerDot.BackgroundColor3 = CLR.accent2; footerDot.BorderSizePixel = 0
corner(footerDot, 3)
task.spawn(function()
    while footerDot.Parent do
        tween(footerDot, "BackgroundColor3", CLR.accent1, 1); task.wait(1)
        tween(footerDot, "BackgroundColor3", CLR.accent2, 1); task.wait(1)
    end
end)
local footerText = Instance.new("TextLabel", footer)
footerText.Size = UDim2.new(1,-40,1,0); footerText.Position = UDim2.new(0,30,0,0)
footerText.BackgroundTransparency = 1
footerText.Text = "Legit Bot  ·  humanized  ·  RShift = menu"
footerText.TextColor3 = CLR.text_dim; footerText.Font = FONT_M
footerText.TextSize = 10; footerText.TextXAlignment = Enum.TextXAlignment.Left

local PAGE_LIST = { "Aimbot", "Settings", "Visual", "About" }
local pages = {}; local pageScale = {}
for _, name in ipairs(PAGE_LIST) do
    local sc = Instance.new("ScrollingFrame", content)
    sc.Size = UDim2.new(1,0,1,0); sc.BackgroundTransparency = 1
    sc.BorderSizePixel = 0; sc.ScrollBarThickness = 4
    sc.ScrollBarImageColor3 = CLR.accent1_dk
    sc.CanvasSize = UDim2.new(0,0,0,0); sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sc.Visible = false; sc.ZIndex = 3
    local p = Instance.new("UIPadding", sc)
    p.PaddingTop = UDim.new(0,8); p.PaddingBottom = UDim.new(0,8)
    p.PaddingLeft = UDim.new(0,8); p.PaddingRight = UDim.new(0,8)
    local ll = Instance.new("UIListLayout", sc)
    ll.Padding = UDim.new(0,6); ll.SortOrder = Enum.SortOrder.LayoutOrder
    local ps = Instance.new("UIScale", sc); ps.Scale = 1
    pages[name] = { frame = sc, scale = ps }
end

local function tabIcon(n)
    if n == "Aimbot"  then return "◉" end
    if n == "Settings" then return "⚙" end
    if n == "Visual"   then return "◐" end
    if n == "About"    then return "ℹ" end
    return "•"
end

local tabButtons = {}; local currentTab = nil
local function selectTab(name)
    if currentTab == name then return end
    currentTab = name
    for n, p in pairs(pages) do p.frame.Visible = (n == name) end
    for n, b in pairs(tabButtons) do
        local on = (n == name)
        tween(b.icon, "TextColor3", on and CLR.accent1_hi or CLR.text_dim, 0.18)
        tween(b.label, "TextColor3", on and CLR.text or CLR.text_dim, 0.18)
        tween(b.btn, "BackgroundColor3", on and CLR.element_hi or CLR.element, 0.2)
        tween(b.btn, "BackgroundTransparency", on and 0.1 or 0.6, 0.2)
        tween(b.bar, "BackgroundTransparency", on and 0 or 1, 0.22)
        tween(b.bar, "Size", on and UDim2.new(0,3,0,22) or UDim2.new(0,0,0,22), 0.28, Enum.EasingStyle.Back)
    end
    local ps = pages[name] and pages[name].scale
    if ps then
        ps.Scale = 0.94
        tween(ps, "Scale", 1, 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end
end

for _, name in ipairs(PAGE_LIST) do
    local b = Instance.new("TextButton", sidebar)
    b.Size = UDim2.new(1,0,0,38); b.BackgroundColor3 = CLR.element
    b.BackgroundTransparency = 0.6; b.BorderSizePixel = 0
    b.Text = ""; b.AutoButtonColor = false; b.ZIndex = 4
    corner(b, 9)
    local bar = Instance.new("Frame", b)
    bar.Size = UDim2.new(0,0,0,22); bar.Position = UDim2.new(0,-4,0.5,-11)
    bar.BackgroundColor3 = CLR.accent1; bar.BorderSizePixel = 0
    bar.BackgroundTransparency = 1; corner(bar, 2)
    local icon = Instance.new("TextLabel", b)
    icon.Size = UDim2.new(0,26,1,0); icon.Position = UDim2.new(0,14,0,0)
    icon.BackgroundTransparency = 1; icon.Text = tabIcon(name)
    icon.TextColor3 = CLR.text_dim; icon.Font = FONT_B
    icon.TextSize = 15; icon.ZIndex = 5
    local label = Instance.new("TextLabel", b)
    label.Size = UDim2.new(1,-46,1,0); label.Position = UDim2.new(0,42,0,0)
    label.BackgroundTransparency = 1; label.Text = name
    label.TextColor3 = CLR.text_dim; label.Font = FONT_M
    label.TextSize = 12; label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 5
    b.MouseEnter:Connect(function()
        if currentTab ~= name then
            tween(b, "BackgroundColor3", CLR.element_hi, 0.15)
            tween(b, "BackgroundTransparency", 0.2, 0.15)
        end
    end)
    b.MouseLeave:Connect(function()
        if currentTab ~= name then
            tween(b, "BackgroundColor3", CLR.element, 0.15)
            tween(b, "BackgroundTransparency", 0.6, 0.15)
        end
    end)
    b.MouseButton1Click:Connect(function() selectTab(name) end)
    tabButtons[name] = {btn = b, icon = icon, label = label, bar = bar}
end

-- ============================================================
--  UI COMPONENTS
-- ============================================================
local UI = {}

function UI.section(parent, text)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1,-8,0,26); f.BackgroundTransparency = 1
    local bar = Instance.new("Frame", f)
    bar.Size = UDim2.new(0,3,0,14); bar.Position = UDim2.new(0,0,0,2)
    bar.BackgroundColor3 = CLR.accent1; bar.BorderSizePixel = 0; corner(bar, 2)
    local bg = Instance.new("UIGradient", bar)
    bg.Color = ColorSequence.new(CLR.accent1, CLR.accent2); bg.Rotation = 90
    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1,-12,0,20); lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = string.upper(text); lbl.TextColor3 = CLR.accent1_hi
    lbl.Font = FONT_B; lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local line = Instance.new("Frame", f)
    line.Size = UDim2.new(1,0,0,1); line.Position = UDim2.new(0,0,1,-3)
    line.BackgroundColor3 = CLR.border; line.BorderSizePixel = 0; line.BackgroundTransparency = 0.5
end

function UI.toggle(parent, label, getter, setter)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-8,0,34); row.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,-70,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = label; lbl.TextColor3 = CLR.text; lbl.Font = FONT
    lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local sw = Instance.new("Frame", row)
    sw.Size = UDim2.new(0,46,0,22); sw.Position = UDim2.new(1,-48,0.5,-11)
    sw.BackgroundColor3 = getter() and CLR.accent1 or CLR.track
    sw.BorderSizePixel = 0; corner(sw, 11)
    local swGrad = Instance.new("UIGradient", sw)
    swGrad.Color = ColorSequence.new(CLR.accent1, CLR.accent2)
    swGrad.Enabled = getter()
    local swGlow = Instance.new("UIStroke", sw)
    swGlow.Color = CLR.accent2_hi; swGlow.Thickness = 1.5
    swGlow.Transparency = getter() and 0.5 or 1
    local knob = Instance.new("Frame", sw)
    knob.Size = UDim2.new(0,18,0,18)
    knob.Position = getter() and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
    knob.BackgroundColor3 = Color3.fromRGB(250,250,255)
    knob.BorderSizePixel = 0; corner(knob, 9)
    local knobDot = Instance.new("Frame", knob)
    knobDot.Size = UDim2.new(0,4,0,4); knobDot.Position = UDim2.new(0.5,-2,0.5,-2)
    knobDot.BackgroundColor3 = getter() and CLR.accent1 or CLR.text_dim
    knobDot.BorderSizePixel = 0; corner(knobDot, 2)
    local hit = Instance.new("TextButton", row)
    hit.Size = UDim2.new(1,0,1,0); hit.BackgroundTransparency = 1; hit.Text = ""
    hit.MouseButton1Click:Connect(function()
        local new = not getter()
        setter(new)
        swGrad.Enabled = new
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
    holder.Size = UDim2.new(1,-8,0,44); holder.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", holder)
    lbl.Size = UDim2.new(1,-100,0,14); lbl.BackgroundTransparency = 1
    lbl.Text = label; lbl.TextColor3 = CLR.text; lbl.Font = FONT
    lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local val = Instance.new("TextLabel", holder)
    val.Size = UDim2.new(0,100,0,14); val.Position = UDim2.new(1,-100,0,0)
    val.BackgroundTransparency = 1
    val.Text = fmt and string.format(fmt, getter()) or tostring(getter())
    val.TextColor3 = CLR.accent1_hi; val.Font = FONT_B
    val.TextSize = 12; val.TextXAlignment = Enum.TextXAlignment.Right
    local track = Instance.new("Frame", holder)
    track.Size = UDim2.new(1,0,0,6); track.Position = UDim2.new(0,0,1,-14)
    track.BackgroundColor3 = CLR.track; track.BorderSizePixel = 0; corner(track, 3)
    local rel = math.clamp((getter() - min) / (max - min), 0, 1)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(rel,0,1,0); fill.BorderSizePixel = 0; corner(fill, 3)
    local fg = Instance.new("UIGradient", fill)
    fg.Color = ColorSequence.new(CLR.accent1, CLR.accent2)
    local grab = Instance.new("Frame", track)
    grab.Size = UDim2.new(0,14,0,14)
    grab.Position = UDim2.new(rel,-7,0.5,-7)
    grab.BackgroundColor3 = Color3.fromRGB(250,250,255)
    grab.BorderSizePixel = 0; corner(grab, 7)
    local gg = Instance.new("UIStroke", grab)
    gg.Color = CLR.accent2_hi; gg.Thickness = 1.5; gg.Transparency = 0.4
    local hit = Instance.new("TextButton", holder)
    hit.Size = UDim2.new(1,0,0,26); hit.Position = UDim2.new(0,0,1,-24)
    hit.BackgroundTransparency = 1; hit.Text = ""
    local drag = false
    local bubble = nil
    local function setFromX(x)
        local r = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = min + r * (max - min)
        fill.Size = UDim2.new(r,0,1,0)
        grab.Position = UDim2.new(r,-7,0.5,-7)
        val.Text = fmt and string.format(fmt, v) or tostring(math.floor(v))
        setter(v)
        if bubble then
            bubble.TextLabel.Text = val.Text
            bubble.Position = UDim2.new(r,-22,-1,-4)
        end
    end
    hit.MouseButton1Down:Connect(function()
        drag = true
        bubble = Instance.new("Frame", holder)
        bubble.Size = UDim2.new(0,44,0,20); bubble.BackgroundColor3 = CLR.bg
        bubble.BorderSizePixel = 0; corner(bubble, 6)
        stroke(bubble, CLR.accent1, 1, 0.3)
        local bt = Instance.new("TextLabel", bubble)
        bt.Size = UDim2.new(1,0,1,0); bt.BackgroundTransparency = 1
        bt.Text = val.Text; bt.TextColor3 = CLR.accent1_hi
        bt.Font = FONT_B; bt.TextSize = 11
        bubble.TextLabel = bt
        setFromX(UIS:GetMouseLocation().X)
        tween(grab, "Size", UDim2.new(0,18,0,18), 0.15, Enum.EasingStyle.Back)
        tween(grab, "Position", UDim2.new(grab.Position.X.Scale,-9,0.5,-9), 0.15)
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            setFromX(UIS:GetMouseLocation().X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 and drag then
            drag = false
            if bubble then
                tween(bubble, "BackgroundTransparency", 1, 0.2)
                bubble.TextLabel.TextTransparency = 1
                task.delay(0.25, function() if bubble then bubble:Destroy(); bubble = nil end end)
            end
            tween(grab, "Size", UDim2.new(0,14,0,14), 0.15)
            tween(grab, "Position", UDim2.new(grab.Position.X.Scale,-7,0.5,-7), 0.15)
        end
    end)
end

function UI.selector(parent, options, getter, setter)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-8,0,30); row.BackgroundTransparency = 1
    local layout = Instance.new("UIListLayout", row)
    layout.FillDirection = Enum.FillDirection.Horizontal; layout.Padding = UDim.new(0,4)
    local btns = {}
    for _, opt in ipairs(options) do
        local b = Instance.new("TextButton", row)
        b.Size = UDim2.new(0, 90, 1, 0)
        b.BackgroundColor3 = (getter() == opt) and CLR.accent1 or CLR.element
        b.BorderSizePixel = 0; b.Text = opt; b.TextColor3 = CLR.text
        b.Font = FONT_M; b.TextSize = 11; b.AutoButtonColor = false
        corner(b, 6)
        btns[opt] = b
        b.MouseButton1Click:Connect(function()
            setter(opt)
            for n, bb in pairs(btns) do
                tween(bb, "BackgroundColor3", n == opt and CLR.accent1 or CLR.element, 0.15)
            end
        end)
    end
end

function UI.colorPicker(parent, colors, onPick)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-8,0,32); row.BackgroundTransparency = 1
    local layout = Instance.new("UIListLayout", row)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0,6)
    for _, c in ipairs(colors) do
        local cb = Instance.new("TextButton", row)
        cb.Size = UDim2.new(0,26,1,0); cb.BackgroundColor3 = c
        cb.BorderSizePixel = 0; cb.Text = ""; cb.AutoButtonColor = false
        corner(cb, 8); stroke(cb, CLR.border, 1, 0.4)
        cb.MouseEnter:Connect(function() tween(cb, "Size", UDim2.new(0,30,1,0), 0.12) end)
        cb.MouseLeave:Connect(function() tween(cb, "Size", UDim2.new(0,26,1,0), 0.12) end)
        cb.MouseButton1Click:Connect(function() if onPick then pcall(onPick, c) end end)
    end
end

function UI.label(parent, text, height, color)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1,-8,0,height or 40); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.TextColor3 = color or CLR.text_dim
    lbl.Font = FONT; lbl.TextSize = 11; lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Top
    return lbl
end

-- ============================================================
--  PAGE: AIMBOT
-- ============================================================
do
    local p = pages.Aimbot.frame
    UI.section(p, "Core")
    UI.toggle(p, "Enable Legit Bot", function() return Config.enabled end, function(v) Config.enabled = v end)
    UI.toggle(p, "Team Check", function() return Config.team_check end, function(v) Config.team_check = v end)
    UI.toggle(p, "Friend Check", function() return Config.friend_check end, function(v) Config.friend_check = v end)
    UI.toggle(p, "Wall Check", function() return Config.wall_check end, function(v) Config.wall_check = v end)
    UI.toggle(p, "Sticky Target", function() return Config.sticky end, function(v) Config.sticky = v end)
    UI.toggle(p, "Humanize", function() return Config.humanize end, function(v) Config.humanize = v end)
    UI.toggle(p, "Random Bone", function() return Config.random_bone end, function(v) Config.random_bone = v end)

    UI.section(p, "Sensitivity")
    UI.slider(p, "FOV", 20, 400, function() return Config.fov end,
        function(v) Config.fov = v end, "%.0f px")
    UI.slider(p, "Smooth", 1, 20, function() return Config.smooth end,
        function(v) Config.smooth = v end, "%.1f")
    UI.slider(p, "Humanize Amount", 0, 0.01, function() return Config.humanize_amount end,
        function(v) Config.humanize_amount = v end, "%.4f")

    UI.section(p, "Prediction")
    UI.toggle(p, "Enable Prediction", function() return Config.prediction end,
        function(v) Config.prediction = v end)
    UI.slider(p, "Predict Amount", 0.0, 0.3, function() return Config.pred_amount end,
        function(v) Config.pred_amount = v end, "%.2f s")

    UI.section(p, "Target Bone")
    UI.selector(p, { "Head", "Neck", "Torso", "HRP", "Random" },
        function() return Config.bone end,
        function(v) Config.bone = v end)

    UI.section(p, "Priority")
    UI.selector(p, { "FOV", "Distance", "Health" },
        function() return Config.priority end,
        function(v) Config.priority = v end)

    UI.section(p, "Triggerbot")
    UI.toggle(p, "Enable Trigger", function() return Config.trigger end,
        function(v) Config.trigger = v end)
    UI.slider(p, "Trigger Delay", 30, 400, function() return Config.trigger_delay end,
        function(v) Config.trigger_delay = v end, "%.0f ms")
    UI.slider(p, "Trigger FOV", 1, 30, function() return Config.trigger_fov end,
        function(v) Config.trigger_fov = v end, "%.0f px")
end

-- ============================================================
--  PAGE: SETTINGS
-- ============================================================
do
    local p = pages.Settings.frame
    UI.section(p, "Aim Key")
    UI.label(p, "Aim activates on RMB (hold). Trigger on E.", 30)

    UI.section(p, "Aim Mode")
    UI.selector(p, { "Hold", "Toggle" },
        function() return Config.aim_mode end,
        function(v) Config.aim_mode = v end)

    UI.section(p, "Advanced")
    UI.toggle(p, "Sticky Target", function() return Config.sticky end, function(v) Config.sticky = v end)
    UI.slider(p, "Sticky Duration", 0.1, 2, function() return Config.sticky_time end,
        function(v) Config.sticky_time = v end, "%.2f s")
end

-- ============================================================
--  PAGE: VISUAL
-- ============================================================
do
    local p = pages.Visual.frame
    UI.section(p, "FOV Circle")
    UI.toggle(p, "Show FOV Circle", function() return Config.fov_circle end,
        function(v) Config.fov_circle = v end)
    UI.colorPicker(p, {
        Color3.fromRGB(125,211,192), Color3.fromRGB(255,177,92),
        Color3.fromRGB(200,130,255), Color3.fromRGB(255,90,100),
        Color3.fromRGB(255,255,255),
    }, function(c) Config.fov_color = c end)

    UI.section(p, "Crosshair")
    UI.toggle(p, "Enable Crosshair", function() return Config.crosshair end,
        function(v) Config.crosshair = v; updateCrosshair() end)
    UI.selector(p, { "Cross", "Dot", "Circle" },
        function() return Config.crosshair_style end,
        function(v) Config.crosshair_style = v; updateCrosshair() end)
    UI.slider(p, "Size", 2, 30, function() return Config.crosshair_size end,
        function(v) Config.crosshair_size = v; updateCrosshair() end, "%.0f")
    UI.slider(p, "Gap", 0, 20, function() return Config.crosshair_gap end,
        function(v) Config.crosshair_gap = v; updateCrosshair() end, "%.0f")
    UI.slider(p, "Thickness", 1, 5, function() return Config.crosshair_thick end,
        function(v) Config.crosshair_thick = v; updateCrosshair() end, "%.0f")
    UI.toggle(p, "Center Dot", function() return Config.crosshair_dot end,
        function(v) Config.crosshair_dot = v; updateCrosshair() end)
    UI.colorPicker(p, {
        Color3.fromRGB(125,211,192), Color3.fromRGB(255,177,92),
        Color3.fromRGB(200,130,255), Color3.fromRGB(255,90,100),
        Color3.fromRGB(255,255,255),
    }, function(c) Config.crosshair_color = c; updateCrosshair() end)

    UI.section(p, "Watermark")
    UI.toggle(p, "Show Watermark", function() return Config.watermark end,
        function(v) Config.watermark = v end)
end

-- ============================================================
--  PAGE: ABOUT
-- ============================================================
do
    local p = pages.About.frame
    UI.section(p, "Legit Bot for BloxStrike")
    UI.label(p,
        "Legit Bot v1.0\n" ..
        "Humanized aim assist for BloxStrike.\n\n" ..
        "Features:\n" ..
        "  ◆  Smooth aim with adjustable speed\n" ..
        "  ◆  FOV-limited targeting\n" ..
        "  ◆  Wall check (visibility)\n" ..
        "  ◆  Team / friend check\n" ..
        "  ◆  Sticky target\n" ..
        "  ◆  Humanization (micro-jitter)\n" ..
        "  ◆  Prediction\n" ..
        "  ◆  Triggerbot\n" ..
        "  ◆  Bone selection (Head/Neck/Torso/HRP)\n" ..
        "  ◆  Priority (FOV/Distance/Health)\n" ..
        "  ◆  FOV circle, crosshair, watermark\n\n" ..
        "Controls:\n" ..
        "  RMB — aim (hold)\n" ..
        "  E — triggerbot\n" ..
        "  RShift — menu\n\n" ..
        "Credits:\n" ..
        "  Code: Fox\n" ..
        "  Testing: Jack",
        320
    )
end

-- ============================================================
--  UPDATE LOOPS
-- ============================================================
updateCrosshair()

task.spawn(function()
    local fc, lastFps = 0, tick()
    while wmFrame.Parent do
        fc = fc + 1
        if tick() - lastFps >= 1 then
            wmFps.Text = string.format("%d FPS", fc)
            fc = 0; lastFps = tick()
        end
        wmFrame.Visible = Config.watermark
        if State.locked then
            wmStatus.Text = "● LOCKED"; wmStatus.TextColor3 = CLR.green
        elseif State.holding then
            wmStatus.Text = "● SCAN"; wmStatus.TextColor3 = CLR.yellow
        elseif State.trigging then
            wmStatus.Text = "● TRIG"; wmStatus.TextColor3 = CLR.accent2
        else
            wmStatus.Text = "● IDLE"; wmStatus.TextColor3 = CLR.text_dim
        end
        task.wait(0.15)
    end
end)

-- ============================================================
--  KEYBIND
-- ============================================================
UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Config.menu_key then
        if State.open then closeMenu() else openMenu() end
    end
end)

-- ============================================================
--  BOOT
-- ============================================================
selectTab("Aimbot")
task.wait(0.3)
openMenu()
notif("Legit Bot loaded. RMB = aim, RShift = menu.", 4)

_G.LegitBot = {
    Config = Config,
    State = State,
    open = openMenu,
    close = closeMenu,
    findTarget = findTarget,
}

end)()
