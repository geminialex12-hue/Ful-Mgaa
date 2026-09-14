--[[
    ============================================================
    dadadovich visual suite v1.5  (combat build)
    team: dadka | created: 14.07.2026
    target: Delta Executor (PC / Android / iOS) — Roblox
    new: Silent Aim, Hitbox Expander, Rapid Fire, Auto Reload,
         WalkSpeed, JumpPower, Infinite Jump, Fly, Noclip, Anti-AFK
    fix: menu opens ONLY via "d" button (no 3-finger trigger)
    ============================================================
]]

print("=== [dadadovich] start v1.5 ===")

--=========================================================
-- SERVICES
--=========================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local Workspace        = game:GetService("Workspace")
local StarterGui       = game:GetService("StarterGui")
local VirtualUser      = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
print("[dadadovich] services ok")

local function safeSet(obj, prop, val)
    local ok, err = pcall(function() obj[prop] = val end)
    if not ok then warn("[dadadovich] safeSet:", prop, err) end
    return ok
end

--=========================================================
-- GUI PARENT
--=========================================================
local guiParent = CoreGui
do
    local ok = pcall(function()
        local t = Instance.new("Folder")
        t.Parent = CoreGui
        t:Destroy()
    end)
    if not ok then
        guiParent = LocalPlayer:WaitForChild("PlayerGui", 10)
        print("[dadadovich] fallback PlayerGui")
    end
end

--=========================================================
-- PLATFORM
--=========================================================
local Platform = {}
Platform.isTouch   = UserInputService.TouchEnabled
Platform.isMobile  = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
Platform.isPC      = UserInputService.KeyboardEnabled and UserInputService.MouseEnabled
if Platform.isTouch and not UserInputService.MouseEnabled then Platform.isMobile = true end

local viewport = Camera.ViewportSize
print(("[dadadovich] mobile=%s vp=%dx%d"):format(tostring(Platform.isMobile), viewport.X, viewport.Y))

--=========================================================
-- CONFIG
--=========================================================
local Config = {
    ESP = {
        Enabled = true, ShowFill = true, ShowDistance = true,
        ShowWeapon = true, ShowName = true, TeamCheck = false,
        FillColor = Color3.fromRGB(130, 60, 255), FillAlpha = 0.35, MaxDist = 1500,
    },
    GFX = {
        Enabled = true, ClockTime = 17.5, Bloom = 0.6,
        Saturation = 0.18, Contrast = 0.25,
    },
    GUI = { GlassAlpha = 0.25 },

    Combat = {
        SilentAim       = false,
        SilentFOV       = 120,
        SilentSmooth    = 0.35,
        SilentMethod    = "mouse",  -- mouse / camera / click
        HitboxExpand    = false,
        HitboxSize      = 8,
        RapidFire       = false,
        RapidDelay      = 0.05,
        AutoReload      = false,
        AutoShoot       = false,
    },

    Movement = {
        WalkSpeed       = 16,
        JumpPower       = 50,
        InfiniteJump    = false,
        Fly             = false,
        FlySpeed        = 60,
        Noclip          = false,
        AntiAFK         = true,
    },
}

--=========================================================
-- SCREEN
--=========================================================
local screen = Instance.new("ScreenGui")
safeSet(screen, "Name",           "d_"..tostring(math.random(1e6,9e6)))
safeSet(screen, "ResetOnSpawn",   false)
safeSet(screen, "IgnoreGuiInset", true)
safeSet(screen, "ZIndexBehavior", Enum.ZIndexBehavior.Sibling)
safeSet(screen, "DisplayOrder",   999)
screen.Parent = guiParent
print("[dadadovich] ScreenGui created")

local function corner(parent, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = parent
    return c
end
local function stroke(parent, col, t)
    local s = Instance.new("UIStroke")
    s.Color = col or Color3.fromRGB(180,150,255)
    s.Thickness = 1; s.Transparency = t or 0.5
    s.Parent = parent
    return s
end

--=========================================================
-- MAIN WINDOW
--=========================================================
local WINDOW_W = math.min(viewport.X - 20, Platform.isMobile and 400 or 600)
local WINDOW_H = math.min(viewport.Y - 60, Platform.isMobile and 500 or 440)

local main = Instance.new("Frame")
main.Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H)
main.Position = UDim2.new(0.5, -WINDOW_W/2, 0.5, -WINDOW_H/2)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
main.BackgroundTransparency = Config.GUI.GlassAlpha
main.BorderSizePixel = 0
main.Active = true
main.Visible = false   -- стартуем скрытым, открываем кнопкой "d"
main.Parent = screen
corner(main, 14)
stroke(main, Color3.fromRGB(180,150,255), 0.45)

-- Toggle button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, Platform.isMobile and 60 or 46, 0, Platform.isMobile and 60 or 46)
toggleBtn.Position = Platform.isMobile and UDim2.new(0, 12, 0.5, -30) or UDim2.new(0, 20, 0.5, -23)
toggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
toggleBtn.BackgroundTransparency = 0.15
toggleBtn.Text = "d"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = Platform.isMobile and 26 or 20
toggleBtn.TextColor3 = Color3.fromRGB(200, 170, 255)
toggleBtn.BorderSizePixel = 0
toggleBtn.Active = true
toggleBtn.Parent = screen
corner(toggleBtn, 14)
stroke(toggleBtn, Color3.fromRGB(180,150,255), 0.4)

toggleBtn.MouseButton1Click:Connect(function()
    main.Visible = not main.Visible
end)
-- долгий тап тоже открывает (страховка если клик не сработал)
do
    local holdStart
    toggleBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then holdStart = tick() end
    end)
    toggleBtn.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch and holdStart and tick() - holdStart > 0.2 then
            main.Visible = not main.Visible
        end
    end)
end

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 40)
title.Position = UDim2.new(0, 14, 0, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = Platform.isMobile and 16 or 18
title.TextColor3 = Color3.fromRGB(220, 200, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "dadadovich  •  v1.5  •  dadka"
title.Active = true
title.Parent = main

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, Platform.isMobile and 40 or 30, 0, Platform.isMobile and 40 or 30)
closeBtn.Position = UDim2.new(1, -(Platform.isMobile and 50 or 40), 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 40)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = Platform.isMobile and 18 or 14
closeBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
closeBtn.BorderSizePixel = 0
closeBtn.Active = true
closeBtn.Parent = main
corner(closeBtn, 8)
closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

--=========================================================
-- TABS LAYOUT
--=========================================================
local isPortrait = viewport.Y >= viewport.X
local useHorizontalTabs = Platform.isMobile and isPortrait

local tabs = Instance.new("Frame")
tabs.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
tabs.BackgroundTransparency = 0.35
tabs.BorderSizePixel = 0
tabs.ClipsDescendants = true
tabs.Parent = main
corner(tabs, 10)

local content = Instance.new("Frame")
content.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
content.BackgroundTransparency = 0.35
content.BorderSizePixel = 0
content.ClipsDescendants = true
content.Parent = main
corner(content, 10)

if useHorizontalTabs then
    tabs.Size = UDim2.new(1, -24, 0, 52)
    tabs.Position = UDim2.new(0, 12, 0, 52)
    content.Size = UDim2.new(1, -24, 1, -116)
    content.Position = UDim2.new(0, 12, 0, 110)
else
    tabs.Size = UDim2.new(0, 150, 1, -60)
    tabs.Position = UDim2.new(0, 12, 0, 52)
    content.Size = UDim2.new(1, -178, 1, -60)
    content.Position = UDim2.new(0, 170, 0, 52)
end

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, 0)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = content

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 10); pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10)
pad.Parent = scroll

--=========================================================
-- HELPERS
--=========================================================
local BTN_H = Platform.isMobile and 42 or 32

local function makeButton(text, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, BTN_H)
    b.BackgroundColor3 = Color3.fromRGB(45, 45, 62)
    b.BackgroundTransparency = 0.15
    b.BorderSizePixel = 0
    b.Font = Enum.Font.Gotham
    b.TextSize = Platform.isMobile and 15 or 14
    b.TextColor3 = Color3.fromRGB(230, 230, 245)
    b.Text = text
    b.Active = true
    b.Selectable = false
    b.Parent = scroll
    corner(b, 8)
    stroke(b, Color3.fromRGB(120,100,180), 0.7)
    b.MouseButton1Click:Connect(function()
        local ok, err = pcall(cb)
        if not ok then warn("[dadadovich] button err:", err) end
    end)
    return b
end

local function makeToggle(label, initial, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, BTN_H)
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    b.BackgroundTransparency = 0.15
    b.BorderSizePixel = 0
    b.Font = Enum.Font.Gotham
    b.TextSize = Platform.isMobile and 14 or 13
    b.TextColor3 = Color3.fromRGB(230, 230, 245)
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.Text = "  "..label.." : "..(initial and "ON" or "OFF")
    b.Active = true
    b.Selectable = false
    b.Parent = scroll
    corner(b, 8)
    local state = initial
    b.MouseButton1Click:Connect(function()
        state = not state
        b.Text = "  "..label.." : "..(state and "ON" or "OFF")
        pcall(cb, state)
    end)
    return b
end

local function makeSlider(label, minV, maxV, initial, cb)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, Platform.isMobile and 56 or 42)
    holder.BackgroundTransparency = 1
    holder.Parent = scroll

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = Platform.isMobile and 14 or 13
    lbl.TextColor3 = Color3.fromRGB(210, 200, 240)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = label.."  ["..tostring(initial).."]"
    lbl.Parent = holder

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, Platform.isMobile and 14 or 8)
    bar.Position = UDim2.new(0, 0, 0, Platform.isMobile and 30 or 24)
    bar.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    bar.BorderSizePixel = 0
    bar.Active = true
    bar.Parent = holder
    corner(bar, 4)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((initial - minV)/(maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    corner(fill, 4)

    local knobSize = Platform.isMobile and 22 or 16
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, knobSize, 0, knobSize)
    knob.Position = UDim2.new((initial - minV)/(maxV - minV), 0, 0.5, 0)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = Color3.fromRGB(200, 170, 255)
    knob.BorderSizePixel = 0
    knob.Parent = bar
    corner(knob, 100)

    local dragging = false
    local function setFromX(absX)
        local rel = math.clamp((absX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = minV + rel * (maxV - minV)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        lbl.Text = label.."  ["..string.format("%.2f", v).."]"
        pcall(cb, v)
    end

    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; setFromX(i.Position.X)
        end
    end)
    bar.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then setFromX(i.Position.X) end
    end)
    bar.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.Touch
        or i.UserInputType == Enum.UserInputType.MouseMovement) then setFromX(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch
        or i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    return holder
end

--=========================================================
-- WINDOW DRAG
--=========================================================
do
    local dragging, dragStart, startPos
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            local vX = Camera.ViewportSize.X
            local vY = Camera.ViewportSize.Y
            local newX = math.clamp(startPos.X.Offset + delta.X, -WINDOW_W/2, vX - WINDOW_W/2)
            local newY = math.clamp(startPos.Y.Offset + delta.Y, -WINDOW_H/2, vY - WINDOW_H/2)
            main.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

--=========================================================
-- ESP
--=========================================================
local ESP = { cache = {} }
local espFolder = Instance.new("Folder")
espFolder.Name   = "d_"..tostring(math.random(1e6,9e6))
espFolder.Parent = guiParent

local function getWeaponName(plr)
    local char = plr.Character
    if char then for _, c in ipairs(char:GetChildren()) do if c:IsA("Tool") then return c.Name end end end
    local bp = plr:FindFirstChildOfClass("Backpack")
    if bp then local t = bp:FindFirstChildOfClass("Tool"); if t then return t.Name end end
    return nil
end

local function isEnemy(plr)
    if plr == LocalPlayer then return false end
    if Config.ESP.TeamCheck and plr.Team == LocalPlayer.Team then return false end
    return true
end

function ESP.create(plr)
    if ESP.cache[plr] then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "b_"..tostring(math.random(1e6,9e6))
    bb.Size = UDim2.new(0, 220, 0, 100)
    bb.StudsOffset = Vector3.new(0, 3.4, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = Config.ESP.MaxDist
    bb.Parent = espFolder

    local fill = Instance.new("BoxHandleAdornment")
    fill.Size = Vector3.new(2, 2, 1)
    fill.Transparency = 1 - Config.ESP.FillAlpha
    fill.Color3 = Config.ESP.FillColor
    fill.AlwaysOnTop = true
    fill.ZIndex = 5
    fill.Parent = espFolder

    local dl = Instance.new("TextLabel")
    dl.BackgroundTransparency = 1
    dl.Size = UDim2.new(1, 0, 0, 20)
    dl.Position = UDim2.new(0, 0, 1, -22)
    dl.Font = Enum.Font.Code
    dl.TextSize = 15
    dl.TextColor3 = Color3.fromRGB(255,255,255)
    dl.TextStrokeTransparency = 0
    dl.Text = "[0 studs]"
    dl.Parent = bb

    local il = Instance.new("TextLabel")
    il.BackgroundTransparency = 1
    il.Size = UDim2.new(1, 0, 0, 20)
    il.Position = UDim2.new(0, 0, 0, 0)
    il.Font = Enum.Font.GothamBold
    il.TextSize = 16
    il.TextColor3 = Color3.fromRGB(200, 150, 255)
    il.TextStrokeTransparency = 0
    il.Text = plr.Name
    il.Parent = bb

    local wl = Instance.new("TextLabel")
    wl.BackgroundTransparency = 1
    wl.Size = UDim2.new(1, 0, 0, 18)
    wl.Position = UDim2.new(0, 0, 0, 20)
    wl.Font = Enum.Font.Code
    wl.TextSize = 14
    wl.TextColor3 = Color3.fromRGB(255, 220, 120)
    wl.TextStrokeTransparency = 0
    wl.Text = ""
    wl.Parent = bb

    ESP.cache[plr] = { billboard=bb, fill=fill, distLabel=dl, infoLabel=il, weaponLabel=wl }
end

function ESP.remove(plr)
    local d = ESP.cache[plr]
    if not d then return end
    for _, o in pairs(d) do if typeof(o) == "Instance" then o:Destroy() end end
    ESP.cache[plr] = nil
end

RunService.RenderStepped:Connect(function()
    if not Config.ESP.Enabled then return end
    for plr, d in pairs(ESP.cache) do
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        if hrp and isEnemy(plr) then
            d.billboard.Adornee = head or hrp
            d.fill.Adornee = hrp
            d.fill.Size = hrp.Size + Vector3.new(0.3,0.3,0.3)
            d.fill.Transparency = Config.ESP.ShowFill and (1-Config.ESP.FillAlpha) or 1
            d.fill.Color3 = Config.ESP.FillColor
            local dist = math.floor((Camera.CFrame.Position - hrp.Position).Magnitude)
            d.distLabel.Visible = Config.ESP.ShowDistance
            d.distLabel.Text = "["..dist.." studs]"
            d.infoLabel.Visible = Config.ESP.ShowName
            d.infoLabel.Text = plr.Name
            if Config.ESP.ShowWeapon then
                local w = getWeaponName(plr)
                d.weaponLabel.Text = w and ("[ "..w.." ]") or ""
                d.weaponLabel.Visible = w ~= nil
            end
        else
            d.billboard.Adornee = nil
            d.fill.Adornee = nil
        end
    end
end)

local function hookPlayer(plr)
    if plr ~= LocalPlayer then ESP.create(plr) end
    plr.CharacterAdded:Connect(function() if plr ~= LocalPlayer then ESP.create(plr) end end)
    plr.CharacterRemoving:Connect(function() ESP.remove(plr) end)
end
for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
Players.PlayerAdded:Connect(hookPlayer)
Players.PlayerRemoving:Connect(ESP.remove)

--=========================================================
-- GFX
--=========================================================
local function mk(class, props, parent)
    local i = Instance.new(class)
    for k,v in pairs(props) do i[k] = v end
    i.Parent = parent or Lighting
    return i
end

local function applyGFX()
    if not Config.GFX.Enabled then return end
    for _, c in ipairs(Lighting:GetChildren()) do
        if c:IsA("PostEffect") or c:IsA("Sky") or c:IsA("Atmosphere") or c:IsA("Clouds") then c:Destroy() end
    end
    Lighting.Ambient = Color3.fromRGB(75, 75, 95)
    Lighting.OutdoorAmbient = Color3.fromRGB(95, 95, 125)
    Lighting.Brightness = 2.5
    Lighting.ClockTime = Config.GFX.ClockTime
    Lighting.ExposureCompensation = 0.2
    Lighting.GlobalShadows = true
    Lighting.FogEnd = 100000
    Lighting.FogStart = 8000
    mk("Atmosphere", { Density=0.35, Offset=0.25,
        Color=Color3.fromRGB(200,190,220), Decay=Color3.fromRGB(120,130,180),
        Glare=0.25, Haze=1.8 })
    mk("Sky", {
        SkyboxBk="rbxassetid://159454299", SkyboxDn="rbxassetid://159454296",
        SkyboxFt="rbxassetid://159454293", SkyboxLf="rbxassetid://159454286",
        SkyboxRt="rbxassetid://159454300", SkyboxUp="rbxassetid://159454288",
        SunAngularSize=2, MoonAngularSize=2, StarCount=2500 })
    mk("Clouds", { Cover=0.5, Density=0.4 })
    mk("BloomEffect", { Intensity=Config.GFX.Bloom, Size=20, Threshold=0.95 })
    mk("ColorCorrectionEffect", { Brightness=0, Contrast=Config.GFX.Contrast,
        Saturation=Config.GFX.Saturation, TintColor=Color3.fromRGB(255,245,230) })
end
pcall(applyGFX)

--=========================================================
-- COMBAT MODULE — Silent Aim / Hitbox / Rapid Fire
--=========================================================

-- хранилище оригинальных размеров хитбоксов
local origSizes = {}
-- оригинальные размеры тел
local origBodySizes = {}

local Combat = {}

--=========================================================
-- HITBOX EXPANDER
--=========================================================
function Combat.updateHitbox()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if not origBodySizes[hrp] then origBodySizes[hrp] = hrp.Size end
                    if Config.Combat.HitboxExpand then
                        hrp.Size = Vector3.new(Config.Combat.HitboxSize, Config.Combat.HitboxSize, Config.Combat.HitboxSize)
                        hrp.Transparency = 0.7
                        hrp.CanCollide = false
                        hrp.Massless = true
                    else
                        hrp.Size = origBodySizes[hrp]
                        hrp.Transparency = 1
                        hrp.CanCollide = false
                    end
                end
            end
        end
    end
end

-- следим за новыми персонажами
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function() task.wait(0.5); pcall(Combat.updateHitbox) end)
end)
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        plr.CharacterAdded:Connect(function() task.wait(0.5); pcall(Combat.updateHitbox) end)
    end
end

--=========================================================
-- SILENT AIM
--=========================================================
-- Ищем ближайшего врага в FOV
function Combat.getTarget()
    local best, bestDist = nil, math.huge
    local camPos = Camera.CFrame.Position
    local mousePos = UserInputService:GetMouseLocation()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and (not Config.ESP.TeamCheck or plr.Team ~= LocalPlayer.Team) then
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and head and humanoid and humanoid.Health > 0 then
                local targetPart = Config.Combat.HitboxExpand and hrp or head
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dx = screenPos.X - mousePos.X
                    local dy = screenPos.Y - mousePos.Y
                    local screenDist = math.sqrt(dx*dx + dy*dy)
                    if screenDist <= Config.Combat.SilentFOV and screenDist < bestDist then
                        bestDist = screenDist
                        best = { plr = plr, part = targetPart }
                    end
                end
            end
        end
    end
    return best
end

-- Hook CFrame для silent aim (мышь/камера наводится на цель)
local oldIndex, oldNewIndex
local mt = getrawmetatable and getrawmetatable(game)
if mt then
    local canReadonly = type(setreadonly) == "function"
    if canReadonly then pcall(setreadonly, mt, false) end
    oldIndex = mt.__index
    oldNewIndex = mt.__newindex

    pcall(function()
        mt.__index = newcclosure(function(self, key)
            if Config.Combat.SilentAim and key == "Hit" and self == Workspace then
                local target = Combat.getTarget()
                if target and target.part then
                    return target.part.CFrame
                end
            end
            if Config.Combat.SilentAim and key == "Target" and self == Workspace then
                local target = Combat.getTarget()
                if target and target.part then
                    return target.part
                end
            end
            return oldIndex(self, key)
        end)
    end)
    if canReadonly then pcall(setreadonly, mt, true) end
end

--=========================================================
-- AUTO SHOOT (клик за игрока)
--=========================================================
task.spawn(function()
    while true do
        task.wait(Config.Combat.RapidDelay)
        if Config.Combat.RapidFire then
            local target = Combat.getTarget()
            if target and target.part then
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                end)
            end
        end
    end
end)

--=========================================================
-- AUTO RELOAD
--=========================================================
task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.Combat.AutoReload then
            local char = LocalPlayer.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    local reloaded = pcall(function() tool:Activate() end)
                end
            end
        end
    end
end)

--=========================================================
-- MOVEMENT MODULE
--=========================================================
local Movement = {}

function Movement.applyWalkSpeed()
    local char = LocalPlayer.Character
    local h = char and char:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = Config.Movement.WalkSpeed end
end

function Movement.applyJumpPower()
    local char = LocalPlayer.Character
    local h = char and char:FindFirstChildOfClass("Humanoid")
    if h then h.JumpPower = Config.Movement.JumpPower; h.UseJumpPower = true end
end

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Config.Movement.InfiniteJump then
        local char = LocalPlayer.Character
        local h = char and char:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    if Config.Movement.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if Config.Movement.Noclip then
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
            end
        end
    end
end)

-- Fly
local flyBodyVel, flyBodyGyro, flyConn
function Movement.setFly(state)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if state then
        flyBodyVel = Instance.new("BodyVelocity")
        flyBodyVel.MaxForce = Vector3.new(1e6,1e6,1e6)
        flyBodyVel.Velocity = Vector3.new(0,0,0)
        flyBodyVel.Parent = hrp
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(1e6,1e6,1e6)
        flyBodyGyro.P = 1000
        flyBodyGyro.Parent = hrp

        flyConn = RunService.RenderStepped:Connect(function()
            if not Config.Movement.Fly then return end
            local dir = Vector3.new(0,0,0)
            local camCF = Camera.CFrame
            local speed = Config.Movement.FlySpeed
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            flyBodyVel.Velocity = dir * speed
            flyBodyGyro.CFrame = camCF
        end)
    else
        if flyConn then flyConn:Disconnect(); flyConn = nil end
        if flyBodyVel then flyBodyVel:Destroy(); flyBodyVel = nil end
        if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
    end
end

--=========================================================
-- TAB BUILDERS
--=========================================================
local tabButtons = {}

local function clearContent()
    for _, c in ipairs(scroll:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
    end
end

local function buildESP()
    clearContent()
    makeToggle("ESP Enabled",         Config.ESP.Enabled,       function(v) Config.ESP.Enabled = v end)
    makeToggle("Показывать заливку",  Config.ESP.ShowFill,      function(v) Config.ESP.ShowFill = v end)
    makeToggle("Показывать дистанцию",Config.ESP.ShowDistance,  function(v) Config.ESP.ShowDistance = v end)
    makeToggle("Показывать оружие",   Config.ESP.ShowWeapon,    function(v) Config.ESP.ShowWeapon = v end)
    makeToggle("Показывать имя",      Config.ESP.ShowName,      function(v) Config.ESP.ShowName = v end)
    makeToggle("Team Check",          Config.ESP.TeamCheck,     function(v) Config.ESP.TeamCheck = v end)
    makeSlider("Прозрачность", 0, 1, Config.ESP.FillAlpha, function(v) Config.ESP.FillAlpha = v end)
    makeSlider("Дистанция", 100, 3000, Config.ESP.MaxDist, function(v)
        Config.ESP.MaxDist = v
        for _, d in pairs(ESP.cache) do d.billboard.MaxDistance = v end
    end)
    makeButton("Цвет: фиолет", function() Config.ESP.FillColor = Color3.fromRGB(130,60,255) end)
    makeButton("Цвет: неон",   function() Config.ESP.FillColor = Color3.fromRGB(0,255,200)  end)
    makeButton("Цвет: кровь",  function() Config.ESP.FillColor = Color3.fromRGB(255,30,60)  end)
    makeButton("Цвет: белый",  function() Config.ESP.FillColor = Color3.fromRGB(255,255,255)end)
end

local function buildCombat()
    clearContent()

    -- Silent Aim
    makeToggle("Silent Aim", Config.Combat.SilentAim, function(v) Config.Combat.SilentAim = v end)
    makeSlider("Silent FOV", 10, 500, Config.Combat.SilentFOV, function(v) Config.Combat.SilentFOV = v end)
    makeSlider("Silent Smooth", 0, 1, Config.Combat.SilentSmooth, function(v) Config.Combat.SilentSmooth = v end)

    -- Hitbox
    makeToggle("Hitbox Expander", Config.Combat.HitboxExpand, function(v)
        Config.Combat.HitboxExpand = v
        pcall(Combat.updateHitbox)
    end)
    makeSlider("Hitbox Size", 2, 30, Config.Combat.HitboxSize, function(v)
        Config.Combat.HitboxSize = v
        pcall(Combat.updateHitbox)
    end)

    -- Rapid Fire
    makeToggle("Rapid Fire", Config.Combat.RapidFire, function(v) Config.Combat.RapidFire = v end)
    makeSlider("Rapid Delay", 0.01, 0.5, Config.Combat.RapidDelay, function(v) Config.Combat.RapidDelay = v end)

    -- Auto Reload
    makeToggle("Auto Reload", Config.Combat.AutoReload, function(v) Config.Combat.AutoReload = v end)

    -- Combat presets
    makeButton("Пресет: ЛЕГИТ", function()
        Config.Combat.SilentAim = false
        Config.Combat.HitboxExpand = false
        Config.Combat.RapidFire = false
        pcall(Combat.updateHitbox)
        pcall(buildCombat)
    end)
    makeButton("Пресет: АГРЕССИВ", function()
        Config.Combat.SilentAim = true
        Config.Combat.HitboxExpand = true
        Config.Combat.HitboxSize = 6
        Config.Combat.RapidFire = true
        Config.Combat.RapidDelay = 0.05
        pcall(Combat.updateHitbox)
        pcall(buildCombat)
    end)
    makeButton("Пресет: РАЗНОС", function()
        Config.Combat.SilentAim = true
        Config.Combat.SilentFOV = 250
        Config.Combat.HitboxExpand = true
        Config.Combat.HitboxSize = 15
        Config.Combat.RapidFire = true
        Config.Combat.RapidDelay = 0.02
        Config.Combat.AutoReload = true
        pcall(Combat.updateHitbox)
        pcall(buildCombat)
    end)
end

local function buildMovement()
    clearContent()
    makeSlider("WalkSpeed", 16, 300, Config.Movement.WalkSpeed, function(v)
        Config.Movement.WalkSpeed = v
        pcall(Movement.applyWalkSpeed)
    end)
    makeSlider("JumpPower", 50, 500, Config.Movement.JumpPower, function(v)
        Config.Movement.JumpPower = v
        pcall(Movement.applyJumpPower)
    end)
    makeToggle("Infinite Jump", Config.Movement.InfiniteJump, function(v) Config.Movement.InfiniteJump = v end)
    makeToggle("Noclip",        Config.Movement.Noclip,        function(v) Config.Movement.Noclip = v end)
    makeToggle("Anti-AFK",      Config.Movement.AntiAFK,       function(v) Config.Movement.AntiAFK = v end)
    makeToggle("Fly",           Config.Movement.Fly,           function(v)
        Config.Movement.Fly = v
        pcall(Movement.setFly, v)
    end)
    makeSlider("Fly Speed", 20, 300, Config.Movement.FlySpeed, function(v) Config.Movement.FlySpeed = v end)

    makeButton("Применить Walk/Jump", function()
        pcall(Movement.applyWalkSpeed); pcall(Movement.applyJumpPower)
    end)

    -- авто-применение при респавне
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        pcall(Movement.applyWalkSpeed)
        pcall(Movement.applyJumpPower)
        pcall(Combat.updateHitbox)
    end)
end

local function buildGFX()
    clearContent()
    makeToggle("GFX Enabled", Config.GFX.Enabled, function(v) Config.GFX.Enabled = v; if v then applyGFX() end end)
    makeSlider("Время суток", 0, 24, Config.GFX.ClockTime, function(v)
        Config.GFX.ClockTime = v; Lighting.ClockTime = v
    end)
    makeSlider("Bloom", 0, 2, Config.GFX.Bloom, function(v)
        local b = Lighting:FindFirstChildOfClass("BloomEffect"); if b then b.Intensity = v end
        Config.GFX.Bloom = v
    end)
    makeSlider("Насыщенность", -1, 1, Config.GFX.Saturation, function(v)
        local c = Lighting:FindFirstChildOfClass("ColorCorrectionEffect"); if c then c.Saturation = v end
        Config.GFX.Saturation = v
    end)
    makeSlider("Контраст", -1, 1, Config.GFX.Contrast, function(v)
        local c = Lighting:FindFirstChildOfClass("ColorCorrectionEffect"); if c then c.Contrast = v end
        Config.GFX.Contrast = v
    end)
    makeButton("Перезагрузить GFX", applyGFX)
    makeButton("Убрать пост-эффекты", function()
        for _, c in ipairs(Lighting:GetChildren()) do if c:IsA("PostEffect") then c:Destroy() end end
    end)
end

local function buildLocal()
    clearContent()
    local function info(t)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 22)
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.Code
        l.TextSize = 13
        l.TextColor3 = Color3.fromRGB(200, 200, 220)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = t
        l.Parent = scroll
    end
    info("Игрок: "..LocalPlayer.Name)
    info("UserID: "..LocalPlayer.UserId)
    info("Мобайл: "..tostring(Platform.isMobile))

    makeButton("Покрасить себя", function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Color = Config.ESP.FillColor end
        end
    end)
    makeButton("Радужный персонаж", function()
        task.spawn(function()
            local t = 0
            while LocalPlayer.Character do
                t = t + 0.02
                local col = Color3.fromHSV((t % 1), 0.9, 1)
                for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Color = col end
                end
                RunService.Heartbeat:Wait()
            end
        end)
    end)
    makeButton("Respawn", function()
        if LocalPlayer.Character then
            local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if h then h.Health = 0 end
        end
    end)
end

--=========================================================
-- TABS INIT
--=========================================================
local tabContainer = tabs
if useHorizontalTabs then
    local ts = Instance.new("ScrollingFrame")
    ts.Size = UDim2.new(1, -16, 1, -16)
    ts.Position = UDim2.new(0, 8, 0, 8)
    ts.BackgroundTransparency = 1
    ts.BorderSizePixel = 0
    ts.ScrollBarThickness = 0
    ts.ScrollingDirection = Enum.ScrollingDirection.X
    ts.CanvasSize = UDim2.new(0, 0, 0, 0)
    ts.AutomaticCanvasSize = Enum.AutomaticSize.X
    ts.Parent = tabs
    local hL = Instance.new("UIListLayout")
    hL.FillDirection = Enum.FillDirection.Horizontal
    hL.Padding = UDim.new(0, 6)
    hL.SortOrder = Enum.SortOrder.LayoutOrder
    hL.Parent = ts
    tabContainer = ts
else
    local ts = Instance.new("ScrollingFrame")
    ts.Size = UDim2.new(1, 0, 1, 0)
    ts.BackgroundTransparency = 1
    ts.BorderSizePixel = 0
    ts.ScrollBarThickness = 3
    ts.CanvasSize = UDim2.new(0, 0, 0, 0)
    ts.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ts.Parent = tabs
    local vL = Instance.new("UIListLayout")
    vL.Padding = UDim.new(0, 6)
    vL.SortOrder = Enum.SortOrder.LayoutOrder
    vL.Parent = ts
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, 6); p.PaddingLeft = UDim.new(0, 6)
    p.PaddingRight = UDim.new(0, 6); p.PaddingBottom = UDim.new(0, 6)
    p.Parent = ts
    tabContainer = ts
end

local tabDefs = {
    {"ESP",      buildESP},
    {"Бой",      buildCombat},
    {"Движение", buildMovement},
    {"Графика",  buildGFX},
    {"Персонаж", buildLocal},
}

for i, def in ipairs(tabDefs) do
    local name, builder = def[1], def[2]
    local b = Instance.new("TextButton")
    if useHorizontalTabs then
        b.Size = UDim2.new(0, 90, 1, 0)
    else
        b.Size = UDim2.new(1, 0, 0, Platform.isMobile and 44 or 34)
    end
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    b.BackgroundTransparency = 0.15
    b.BorderSizePixel = 0
    b.Font = Enum.Font.Gotham
    b.TextSize = Platform.isMobile and 15 or 14
    b.TextColor3 = Color3.fromRGB(220, 220, 240)
    b.Text = name
    b.Active = true
    b.Selectable = false
    b.Parent = tabContainer
    corner(b, 8)
    tabButtons[name] = b
    b.MouseButton1Click:Connect(function()
        for _, bb in pairs(tabButtons) do
            bb.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        end
        b.BackgroundColor3 = Color3.fromRGB(90, 60, 150)
        local ok, err = pcall(builder)
        if not ok then warn("[dadadovich] tab err:", err) end
    end)
end

tabButtons["ESP"].BackgroundColor3 = Color3.fromRGB(90, 60, 150)
pcall(buildESP)

print("[dadadovich] v1.5 READY")

--=========================================================
-- PC HOTKEYS (только PC)
--=========================================================
if Platform.isPC then
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            main.Visible = not main.Visible
        elseif input.KeyCode == Enum.KeyCode.RightShift then
            Config.ESP.Enabled = not Config.ESP.Enabled
        end
    end)
end

--=========================================================
-- NOTIFY
--=========================================================
task.spawn(function()
    for i = 1, 5 do
        local ok = pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "dadadovich v1.5",
                Text = "loaded • combat ready • dadka",
                Duration = 4,
            })
        end)
        if ok then break end
        task.wait(0.5)
    end
end)

print("[dadadovich] v1.5 loaded • team dadka • ready")
