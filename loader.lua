-- Plalette Scripts · FFA Gun Grounds · v1.0
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ==================== SETTINGS ====================
local Settings = {
    Aimbot = false, FOV = 120, Silent = false, ShowFOV = true, FOVFilled = false, FOVThick = 1.5, FOVColor = "Lila",
    Trigger = false, NoRecoil = false, NoSpread = false, Reload = false,
    Hitbox = false, HitboxSize = 3,
    ESP = false, Box = true, Name = true, Dist = true, Health = true, Skeleton = false, HeadDot = false, Tracers = false,
    ESPColor = "Lila", TeamCheck = false, ESPMaxDist = 500,
    Speed = false, SpeedVal = 32,
    Fly = false, FlyVal = 30, FlyKey = "G",
    Jump = false, JumpVal = 60,
    Spin = false, SpinVal = 5,
    NoClip = false,
    AntiAFK = true,
    Fullbright = false,
    Watermark = true
}

local ESPCache = {}
local FOVCircle = nil
local Connections = {}
local SpinConnection = nil

-- ==================== COLORS ====================
local Colors = {
    Lila = Color3.fromRGB(140, 80, 255),
    Rot = Color3.fromRGB(255, 50, 50),
    Blau = Color3.fromRGB(50, 150, 255),
    Grün = Color3.fromRGB(50, 255, 50),
    Gelb = Color3.fromRGB(255, 255, 50),
    Weiß = Color3.fromRGB(255, 255, 255)
}

local function GetColor(name)
    return Colors[name] or Colors.Lila
end

-- ==================== FUNCTIONS ====================
local function GetTarget()
    local best = 99999
    local tgt = nil
    local cx = Camera.ViewportSize.X / 2
    local cy = Camera.ViewportSize.Y / 2
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then
                local pos, on = Camera:WorldToViewportPoint(head.Position)
                if on then
                    local dx = pos.X - cx
                    local dy = pos.Y - cy
                    local d = math.sqrt(dx*dx + dy*dy)
                    if d < Settings.FOV and d < best then
                        best = d
                        tgt = p
                    end
                end
            end
        end
    end
    return tgt
end

local function ClearESP()
    for _, d in pairs(ESPCache) do
        if type(d) == "table" then
            for _, dd in pairs(d) do pcall(function() dd:Remove() end) end
        else
            pcall(function() d:Remove() end)
        end
    end
    ESPCache = {}
    if FOVCircle then pcall(function() FOVCircle:Remove() end) FOVCircle = nil end
end

local function StopAll()
    Settings.Aimbot = false Settings.Silent = false Settings.Trigger = false
    Settings.Hitbox = false Settings.Reload = false Settings.ESP = false
    Settings.Speed = false Settings.Fly = false Settings.Jump = false
    Settings.Spin = false Settings.NoClip = false
    ClearESP()
    if SpinConnection then SpinConnection:Disconnect() end
    for _, c in pairs(Connections) do pcall(function() c:Disconnect() end) end
    if LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = 16 h.JumpPower = 50 end
        local r = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if r then
            for _, c in ipairs(r:GetChildren()) do
                if c:IsA("BodyGyro") or c:IsA("BodyVelocity") then c:Destroy() end
            end
        end
    end
    Lighting.Brightness = 1
end

-- ==================== GUI ====================
local GUI = Instance.new("ScreenGui")
GUI.Name = "PlaletteFFA"
GUI.ResetOnSpawn = false
GUI.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 600, 0, 420)
Main.Position = UDim2.new(0.5, -300, 0.5, -210)
Main.BackgroundColor3 = Color3.fromRGB(14, 12, 24)
Main.BackgroundTransparency = 0.03
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = GUI
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Glow = Instance.new("Frame")
Glow.Size = UDim2.new(1, 2, 1, 2)
Glow.Position = UDim2.new(0, -1, 0, -1)
Glow.BackgroundColor3 = Color3.fromRGB(140, 80, 255)
Glow.BackgroundTransparency = 0.5
Glow.BorderSizePixel = 0
Glow.Parent = Main
Instance.new("UICorner", Glow).CornerRadius = UDim.new(0, 10)

task.spawn(function()
    local a = 0
    while GUI and GUI.Parent do
        a = (a + 0.015) % (math.pi * 2)
        pcall(function() Glow.BackgroundTransparency = 0.45 - math.sin(a) * 0.2 end)
        task.wait(0.04)
    end
end)

-- Minimized
local Mini = Instance.new("Frame")
Mini.Size = UDim2.new(0, 200, 0, 30)
Mini.Position = UDim2.new(0.5, -100, 0.02, 0)
Mini.BackgroundColor3 = Color3.fromRGB(14, 12, 24)
Mini.BackgroundTransparency = 0.03
Mini.BorderSizePixel = 0
Mini.Visible = false
Mini.Active = true
Mini.Draggable = true
Mini.Parent = GUI
Instance.new("UICorner", Mini).CornerRadius = UDim.new(0, 8)
local MiniText = Instance.new("TextLabel")
MiniText.Size = UDim2.new(1, 0, 1, 0)
MiniText.BackgroundTransparency = 1
MiniText.TextColor3 = Color3.fromRGB(180, 130, 255)
MiniText.Text = "FFA Gun Grounds · Plalette Scripts"
MiniText.Font = Enum.Font.SourceSansBold
MiniText.TextSize = 11
MiniText.Parent = Mini

UserInputService.InputBegan:Connect(function(i, p)
    if p then return end
    if i.KeyCode == Enum.KeyCode.LeftControl or i.KeyCode == Enum.KeyCode.RightControl then
        Main.Visible = not Main.Visible
        Mini.Visible = not Mini.Visible
    end
end)

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(18, 15, 28)
Header.BorderSizePixel = 0
Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Size = UDim2.new(0.6, 0, 0.5, 0)
HeaderTitle.Position = UDim2.new(0, 14, 0, 2)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HeaderTitle.Text = "FFA Gun Grounds"
HeaderTitle.Font = Enum.Font.SourceSansBold
HeaderTitle.TextSize = 16
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.Parent = Header

local HeaderSub = Instance.new("TextLabel")
HeaderSub.Size = UDim2.new(0.6, 0, 0.35, 0)
HeaderSub.Position = UDim2.new(0, 14, 0, 24)
HeaderSub.BackgroundTransparency = 1
HeaderSub.TextColor3 = Color3.fromRGB(160, 140, 180)
HeaderSub.Text = "Plalette Scripts · v1.0"
HeaderSub.Font = Enum.Font.SourceSans
HeaderSub.TextSize = 10
HeaderSub.TextXAlignment = Enum.TextXAlignment.Left
HeaderSub.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0, 7)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 70)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 14
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)
CloseBtn.MouseButton1Click:Connect(function() StopAll() GUI:Destroy() end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 140, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = Color3.fromRGB(18, 16, 28)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SideList = Instance.new("UIListLayout")
SideList.Padding = UDim.new(0, 2)
SideList.FillDirection = Enum.FillDirection.Vertical
SideList.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideList.SortOrder = Enum.SortOrder.LayoutOrder
SideList.Parent = Sidebar

-- Content
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -140, 1, -66)
Content.Position = UDim2.new(0, 140, 0, 40)
Content.BackgroundColor3 = Color3.fromRGB(14, 13, 22)
Content.BorderSizePixel = 0
Content.Parent = Main

-- Footer
local Footer = Instance.new("Frame")
Footer.Size = UDim2.new(1, -140, 0, 26)
Footer.Position = UDim2.new(0, 140, 1, -26)
Footer.BackgroundColor3 = Color3.fromRGB(18, 16, 28)
Footer.BorderSizePixel = 0
Footer.Parent = Main

local FooterAvatar = Instance.new("ImageLabel")
FooterAvatar.Size = UDim2.new(0, 30, 0, 30)
FooterAvatar.Position = UDim2.new(0, 6, 0.5, -15)
FooterAvatar.BackgroundColor3 = Color3.fromRGB(30, 25, 45)
FooterAvatar.BorderSizePixel = 0
FooterAvatar.Parent = Footer
Instance.new("UICorner", FooterAvatar).CornerRadius = UDim.new(0, 15)
task.spawn(function()
    FooterAvatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
end)

local FooterText = Instance.new("TextLabel")
FooterText.Size = UDim2.new(1, 0, 1, 0)
FooterText.BackgroundTransparency = 1
FooterText.TextColor3 = Color3.fromRGB(160, 140, 180)
FooterText.Text = "Welcome, " .. LocalPlayer.Name .. "  ·  Plalette Scripts v1.0"
FooterText.Font = Enum.Font.SourceSans
FooterText.TextSize = 11
FooterText.TextXAlignment = Enum.TextXAlignment.Center
FooterText.Parent = Footer

-- ==================== TAB SYSTEM ====================
local Pages = {}

local function CreateTab(name, icon)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -8, 0, 34)
    Btn.BackgroundColor3 = Color3.fromRGB(24, 22, 36)
    Btn.TextColor3 = Color3.fromRGB(180, 160, 200)
    Btn.Text = "  " .. icon .. "  " .. name
    Btn.Font = Enum.Font.SourceSans
    Btn.TextSize = 12
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.Parent = Sidebar
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, -16, 1, -16)
    Page.Position = UDim2.new(0, 8, 0, 8)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = Color3.fromRGB(140, 80, 255)
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.Visible = false
    Page.Parent = Content

    local PL = Instance.new("UIListLayout")
    PL.Padding = UDim.new(0, 3)
    PL.FillDirection = Enum.FillDirection.Vertical
    PL.SortOrder = Enum.SortOrder.LayoutOrder
    PL.Parent = Page

    Btn.MouseButton1Click:Connect(function()
        for _, b in ipairs(Sidebar:GetChildren()) do
            if b:IsA("TextButton") then
                b.BackgroundColor3 = Color3.fromRGB(24, 22, 36)
                b.TextColor3 = Color3.fromRGB(180, 160, 200)
            end
        end
        for _, p in pairs(Pages) do p.Visible = false end
        Btn.BackgroundColor3 = Color3.fromRGB(140, 80, 255)
        Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Page.Visible = true
    end)

    table.insert(Pages, Page)
    if #Pages == 1 then
        Btn.BackgroundColor3 = Color3.fromRGB(140, 80, 255)
        Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Page.Visible = true
    end
    return Page
end

-- ==================== UI ELEMENTS ====================
local function Section(page, title)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 20)
    f.BackgroundTransparency = 1
    f.Parent = page
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, 3, 1, 0)
    line.BackgroundColor3 = Color3.fromRGB(140, 80, 255)
    line.BorderSizePixel = 0
    line.Parent = f
    Instance.new("UICorner", line).CornerRadius = UDim.new(0, 2)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 1, 0)
    l.Position = UDim2.new(0, 8, 0, 0)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.fromRGB(200, 190, 220)
    l.Text = title
    l.Font = Enum.Font.SourceSansBold
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    page.CanvasSize = UDim2.new(0, 0, 0, page.CanvasSize.Y.Offset + 24)
end

local function Toggle(page, name, var)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 32)
    f.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
    f.Parent = page
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.55, 0, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.fromRGB(230, 220, 240)
    l.Text = name .. ": OFF"
    l.Font = Enum.Font.SourceSans
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    local tr = Instance.new("Frame")
    tr.Size = UDim2.new(0, 38, 0, 20)
    tr.Position = UDim2.new(1, -48, 0, 6)
    tr.BackgroundColor3 = Color3.fromRGB(50, 45, 60)
    tr.BorderSizePixel = 0
    tr.Parent = f
    Instance.new("UICorner", tr).CornerRadius = UDim.new(0, 10)
    local th = Instance.new("Frame")
    th.Size = UDim2.new(0, 16, 0, 16)
    th.Position = UDim2.new(0, 2, 0, 2)
    th.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    th.BorderSizePixel = 0
    th.Parent = tr
    Instance.new("UICorner", th).CornerRadius = UDim.new(0, 8)
    local tb = Instance.new("TextButton")
    tb.Size = UDim2.new(1, 0, 1, 0)
    tb.BackgroundTransparency = 1
    tb.Text = ""
    tb.Parent = tr
    local on = false
    tb.MouseButton1Click:Connect(function()
        on = not on
        if var == "Aimbot" then Settings.Aimbot = on
        elseif var == "Silent" then Settings.Silent = on
        elseif var == "ShowFOV" then Settings.ShowFOV = on
        elseif var == "FOVFilled" then Settings.FOVFilled = on
        elseif var == "Trigger" then Settings.Trigger = on
        elseif var == "NoRecoil" then Settings.NoRecoil = on
        elseif var == "NoSpread" then Settings.NoSpread = on
        elseif var == "Reload" then Settings.Reload = on
        elseif var == "Hitbox" then Settings.Hitbox = on
        elseif var == "ESP" then Settings.ESP = on
        elseif var == "Box" then Settings.Box = on
        elseif var == "Name" then Settings.Name = on
        elseif var == "Dist" then Settings.Dist = on
        elseif var == "Health" then Settings.Health = on
        elseif var == "Skeleton" then Settings.Skeleton = on
        elseif var == "HeadDot" then Settings.HeadDot = on
        elseif var == "Tracers" then Settings.Tracers = on
        elseif var == "TeamCheck" then Settings.TeamCheck = on
        elseif var == "Speed" then Settings.Speed = on
        elseif var == "Fly" then Settings.Fly = on
        elseif var == "Jump" then Settings.Jump = on
        elseif var == "Spin" then Settings.Spin = on
        elseif var == "NoClip" then Settings.NoClip = on
        elseif var == "AntiAFK" then Settings.AntiAFK = on
        elseif var == "Fullbright" then Settings.Fullbright = on
        elseif var == "Watermark" then Settings.Watermark = on
        end
        l.Text = name .. ": " .. (on and "ON" or "OFF")
        tr.BackgroundColor3 = on and Color3.fromRGB(140, 80, 255) or Color3.fromRGB(50, 45, 60)
        th.Position = on and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)
        th.BackgroundColor3 = on and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
    end)
    page.CanvasSize = UDim2.new(0, 0, 0, page.CanvasSize.Y.Offset + 36)
end

local function Slider(page, name, var, min, max, def)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 44)
    f.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
    f.Parent = page
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.4, 0, 0, 18)
    l.Position = UDim2.new(0, 10, 0, 3)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.fromRGB(230, 220, 240)
    l.Text = name
    l.Font = Enum.Font.SourceSans
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    local vl = Instance.new("TextLabel")
    vl.Size = UDim2.new(0, 40, 0, 18)
    vl.Position = UDim2.new(1, -50, 0, 3)
    vl.BackgroundTransparency = 1
    vl.TextColor3 = Color3.fromRGB(180, 140, 255)
    vl.Text = tostring(def)
    vl.Font = Enum.Font.SourceSansBold
    vl.TextSize = 12
    vl.TextXAlignment = Enum.TextXAlignment.Right
    vl.Parent = f
    local inp = Instance.new("TextBox")
    inp.Size = UDim2.new(0.3, 0, 0, 20)
    inp.Position = UDim2.new(0.35, 0, 0, 22)
    inp.BackgroundColor3 = Color3.fromRGB(40, 36, 50)
    inp.TextColor3 = Color3.fromRGB(255, 255, 255)
    inp.Text = tostring(def)
    inp.Font = Enum.Font.SourceSans
    inp.TextSize = 11
    inp.Parent = f
    Instance.new("UICorner", inp).CornerRadius = UDim.new(0, 4)
    inp.FocusLost:Connect(function()
        local v = tonumber(inp.Text)
        if v and v >= min and v <= max then
            if var == "FOV" then Settings.FOV = v
            elseif var == "FOVThick" then Settings.FOVThick = v
            elseif var == "HitboxSize" then Settings.HitboxSize = v
            elseif var == "ESPMaxDist" then Settings.ESPMaxDist = v
            elseif var == "SpeedVal" then Settings.SpeedVal = v
            elseif var == "FlyVal" then Settings.FlyVal = v
            elseif var == "JumpVal" then Settings.JumpVal = v
            elseif var == "SpinVal" then Settings.SpinVal = v
            end
            vl.Text = tostring(v)
        else inp.Text = vl.Text end
    end)
    page.CanvasSize = UDim2.new(0, 0, 0, page.CanvasSize.Y.Offset + 48)
end

local function Dropdown(page, name, var, options)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 30)
    f.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
    f.Parent = page
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.35, 0, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.fromRGB(230, 220, 240)
    l.Text = name .. ":"
    l.Font = Enum.Font.SourceSans
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    local db = Instance.new("TextButton")
    db.Size = UDim2.new(0.45, 0, 0, 22)
    db.Position = UDim2.new(0.5, 0, 0, 4)
    db.BackgroundColor3 = Color3.fromRGB(40, 36, 50)
    db.TextColor3 = Color3.fromRGB(255, 255, 255)
    db.Text = Settings[var] or options[1]
    db.Font = Enum.Font.SourceSans
    db.TextSize = 11
    db.Parent = f
    Instance.new("UICorner", db).CornerRadius = UDim.new(0, 4)
    local dl = Instance.new("Frame")
    dl.Size = UDim2.new(0.45, 0, 0, #options * 22)
    dl.Position = UDim2.new(0.5, 0, 0, 28)
    dl.BackgroundColor3 = Color3.fromRGB(35, 32, 45)
    dl.BorderSizePixel = 0
    dl.Visible = false
    dl.Parent = f
    Instance.new("UICorner", dl).CornerRadius = UDim.new(0, 4)
    for _, opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Size = UDim2.new(1, 0, 0, 22)
        ob.BackgroundColor3 = Color3.fromRGB(35, 32, 45)
        ob.TextColor3 = Color3.fromRGB(255, 255, 255)
        ob.Text = opt
        ob.Font = Enum.Font.SourceSans
        ob.TextSize = 11
        ob.Parent = dl
        ob.MouseButton1Click:Connect(function()
            Settings[var] = opt
            db.Text = opt
            dl.Visible = false
        end)
    end
    db.MouseButton1Click:Connect(function() dl.Visible = not dl.Visible end)
    page.CanvasSize = UDim2.new(0, 0, 0, page.CanvasSize.Y.Offset + 34)
end

-- ==================== BUILD TABS ====================
local homePage = CreateTab("Home", "🏠")
local combatPage = CreateTab("Combat", "🎯")
local espPage = CreateTab("ESP", "👁")
local playerPage = CreateTab("Player", "🏃")
local settingsPage = CreateTab("Settings", "⚙️")

-- HOME
local wf = Instance.new("Frame")
wf.Size = UDim2.new(1, 0, 0, 100)
wf.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
wf.Parent = homePage
Instance.new("UICorner", wf).CornerRadius = UDim.new(0, 8)
local wt = Instance.new("TextLabel")
wt.Size = UDim2.new(1, -20, 0, 30)
wt.Position = UDim2.new(0, 12, 0, 14)
wt.BackgroundTransparency = 1
wt.TextColor3 = Color3.fromRGB(255, 255, 255)
wt.Text = "Welcome, " .. LocalPlayer.Name .. " 👋"
wt.Font = Enum.Font.SourceSansBold
wt.TextSize = 18
wt.TextXAlignment = Enum.TextXAlignment.Left
wt.Parent = wf
local wi = Instance.new("TextLabel")
wi.Size = UDim2.new(1, -20, 0, 45)
wi.Position = UDim2.new(0, 12, 0, 48)
wi.BackgroundTransparency = 1
wi.TextColor3 = Color3.fromRGB(160, 140, 180)
wi.Text = "Plalette Scripts · FFA Gun Grounds v1.0\nCTRL = Hide GUI | X = Emergency Stop\nFOV Aimbot · ESP · Fly · Speed · Spinbot"
wi.Font = Enum.Font.SourceSans
wi.TextSize = 12
wi.TextXAlignment = Enum.TextXAlignment.Left
wi.Parent = wf
homePage.CanvasSize = UDim2.new(0, 0, 0, 120)

-- COMBAT
Section(combatPage, "Aimbot")
Toggle(combatPage, "FOV Aimbot", "Aimbot")
Slider(combatPage, "FOV Size", "FOV", 30, 500, 120)
Toggle(combatPage, "Silent Aim", "Silent")
Toggle(combatPage, "Show FOV Circle", "ShowFOV")
Toggle(combatPage, "FOV Filled", "FOVFilled")
Slider(combatPage, "FOV Thickness", "FOVThick", 0.5, 4, 1.5)
Dropdown(combatPage, "FOV Color", "FOVColor", {"Lila", "Rot", "Blau", "Grün", "Gelb", "Weiß"})
Section(combatPage, "Weapon")
Toggle(combatPage, "Triggerbot", "Trigger")
Toggle(combatPage, "No Recoil", "NoRecoil")
Toggle(combatPage, "No Spread", "NoSpread")
Toggle(combatPage, "Instant Reload", "Reload")
Toggle(combatPage, "Hitbox Expander", "Hitbox")
Slider(combatPage, "Hitbox Size", "HitboxSize", 1, 10, 3)

-- ESP
Section(espPage, "Player ESP")
Toggle(espPage, "ESP Enabled", "ESP")
Toggle(espPage, "Box ESP", "Box")
Toggle(espPage, "Name ESP", "Name")
Toggle(espPage, "Distance ESP", "Dist")
Toggle(espPage, "Health Bar", "Health")
Toggle(espPage, "Skeleton ESP", "Skeleton")
Toggle(espPage, "Head Dot", "HeadDot")
Toggle(espPage, "Tracers", "Tracers")
Dropdown(espPage, "ESP Color", "ESPColor", {"Lila", "Rot", "Blau", "Grün", "Gelb", "Weiß"})
Toggle(espPage, "Team Check", "TeamCheck")
Slider(espPage, "Max Distance", "ESPMaxDist", 50, 1000, 500)

-- PLAYER
Section(playerPage, "Movement")
Toggle(playerPage, "Speed Hack", "Speed")
Slider(playerPage, "Walk Speed", "SpeedVal", 16, 100, 32)
Toggle(playerPage, "Fly (G-Key)", "Fly")
Slider(playerPage, "Fly Speed", "FlyVal", 10, 100, 30)
Toggle(playerPage, "Infinite Jump", "Jump")
Slider(playerPage, "Jump Power", "JumpVal", 50, 300, 60)
Toggle(playerPage, "Spinbot", "Spin")
Slider(playerPage, "Spin Speed", "SpinVal", 1, 20, 5)
Toggle(playerPage, "NoClip", "NoClip")
Section(playerPage, "Utility")
Toggle(playerPage, "Anti-AFK", "AntiAFK")

-- SETTINGS
Section(settingsPage, "World")
Toggle(settingsPage, "Fullbright", "Fullbright")
Toggle(settingsPage, "Watermark", "Watermark")
Section(settingsPage, "Info")
local inf = Instance.new("Frame")
inf.Size = UDim2.new(1, 0, 0, 60)
inf.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
inf.Parent = settingsPage
Instance.new("UICorner", inf).CornerRadius = UDim.new(0, 6)
local it = Instance.new("TextLabel")
it.Size = UDim2.new(1, -20, 1, -16)
it.Position = UDim2.new(0, 10, 0, 8)
it.BackgroundTransparency = 1
it.TextColor3 = Color3.fromRGB(160, 140, 180)
it.Text = "Plalette Scripts · FFA Gun Grounds v1.0\nPotassium Executor · CTRL=Hide · X=Stop"
it.Font = Enum.Font.SourceSans
it.TextSize = 11
it.TextXAlignment = Enum.TextXAlignment.Left
it.Parent = inf
settingsPage.CanvasSize = UDim2.new(0, 0, 0, settingsPage.CanvasSize.Y.Offset + 80)

-- ==================== FEATURES ====================

-- FOV CIRCLE
task.spawn(function()
    while task.wait(0.03) do
        if Settings.Aimbot and Settings.ShowFOV then
            if not FOVCircle then FOVCircle = Drawing.new("Circle") end
            FOVCircle.Visible = true
            FOVCircle.Radius = Settings.FOV
            FOVCircle.Thickness = Settings.FOVThick
            FOVCircle.Color = GetColor(Settings.FOVColor)
            FOVCircle.Filled = Settings.FOVFilled
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        else
            if FOVCircle then FOVCircle.Visible = false end
        end
    end
end)

-- SILENT AIM
local oldNC = hookmetamethod(game, "__namecall", function(s, ...)
    local m = getnamecallmethod()
    local a = {...}
    if m == "FireServer" and Settings.Aimbot and Settings.Silent then
        local t = GetTarget()
        if t and t.Character then
            local h = t.Character:FindFirstChild("Head")
            if h and a[1] then a[1] = h.Position end
        end
    end
    return oldNC(s, unpack(a))
end)

-- TRIGGERBOT
task.spawn(function()
    while task.wait(0.05) do
        if Settings.Trigger and LocalPlayer.Character then
            pcall(function()
                local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool then
                    local t = GetTarget()
                    if t and t.Character then
                        local h = t.Character:FindFirstChild("Head")
                        if h then
                            local shoot = tool:FindFirstChild("Shoot")
                            if shoot then shoot:FireServer(h.Position) end
                        end
                    end
                end
            end)
        end
    end
end)

-- HITBOX
task.spawn(function()
    while task.wait(0.2) do
        if Settings.Hitbox then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local r = p.Character:FindFirstChild("HumanoidRootPart")
                    if r then
                        r.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
                        r.Transparency = 0.4
                    end
                end
            end
        end
    end
end)

-- RELOAD
task.spawn(function()
    while task.wait(0.1) do
        if Settings.Reload then
            pcall(function()
                for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
                    if t:IsA("Tool") and t:FindFirstChild("Ammo") then t.Ammo.Value = 99 end
                end
                local ct = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if ct and ct:FindFirstChild("Ammo") then ct.Ammo.Value = 99 end
            end)
        end
    end
end)

-- ESP
task.spawn(function()
    while task.wait(0.05) do
        ClearESP()
        if Settings.ESP then
            local color = GetColor(Settings.ESPColor)
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local head = p.Character:FindFirstChild("Head")
                    local root = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if head and root then
                        local hp, on = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                        if on then
                            local fp = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                            local bh = math.abs(hp.Y - fp.Y)
                            local bw = bh / 2

                            if Settings.Box then
                                local box = Drawing.new("Square")
                                box.Color = color
                                box.Thickness = 1.2
                                box.Size = Vector2.new(bw, bh)
                                box.Position = Vector2.new(hp.X - bw / 2, hp.Y)
                                box.Filled = false
                                box.Visible = true
                                table.insert(ESPCache, box)
                            end
                            if Settings.Name then
                                local nm = Drawing.new("Text")
                                nm.Text = p.Name
                                nm.Color = Color3.fromRGB(255, 255, 255)
                                nm.Size = 12
                                nm.Position = Vector2.new(hp.X, hp.Y - 18)
                                nm.Center = true
                                nm.Visible = true
                                table.insert(ESPCache, nm)
                            end
                            if Settings.Dist and LocalPlayer.Character then
                                local mr = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if mr then
                                    local dt = Drawing.new("Text")
                                    dt.Text = math.floor((root.Position - mr.Position).Magnitude) .. "m"
                                    dt.Color = Color3.fromRGB(200, 200, 200)
                                    dt.Size = 10
                                    dt.Position = Vector2.new(hp.X, hp.Y - 4)
                                    dt.Center = true
                                    dt.Visible = true
                                    table.insert(ESPCache, dt)
                                end
                            end
                            if Settings.Health and hum then
                                local hpP = hum.Health / hum.MaxHealth
                                local barW = bw
                                local barH = 3
                                local bg = Drawing.new("Square")
                                bg.Color = Color3.fromRGB(40, 40, 40)
                                bg.Size = Vector2.new(barW, barH)
                                bg.Position = Vector2.new(hp.X - barW / 2, fp.Y + 3)
                                bg.Filled = true
                                bg.Visible = true
                                table.insert(ESPCache, bg)
                                local fill = Drawing.new("Square")
                                fill.Color = hpP > 0.5 and Color3.fromRGB(50, 200, 50) or (hpP > 0.25 and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(255, 50, 50))
                                fill.Size = Vector2.new(barW * hpP, barH)
                                fill.Position = Vector2.new(hp.X - barW / 2, fp.Y + 3)
                                fill.Filled = true
                                fill.Visible = true
                                table.insert(ESPCache, fill)
                            end
                        end
                    end
                end
            end
        end
        if Settings.Tracers then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local r = p.Character:FindFirstChild("HumanoidRootPart")
                    if r then
                        local pos, on = Camera:WorldToViewportPoint(r.Position)
                        if on then
                            local ln = Drawing.new("Line")
                            ln.Color = GetColor(Settings.ESPColor)
                            ln.Thickness = 0.5
                            ln.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            ln.To = Vector2.new(pos.X, pos.Y)
                            ln.Visible = true
                            table.insert(ESPCache, ln)
                        end
                    end
                end
            end
        end
    end
end)

-- SPEED
RunService.Stepped:Connect(function()
    if Settings.Speed and LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = Settings.SpeedVal end
    end
    if Settings.Jump and LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.JumpPower = Settings.JumpVal end
    end
    if Settings.NoClip and LocalPlayer.Character then
        for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if Settings.Jump and LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- FLY (G-Key, FIXED: No teleport back)
UserInputService.InputBegan:Connect(function(i, p)
    if p then return end
    if i.KeyCode == Enum.KeyCode.G then
        Settings.Fly = not Settings.Fly
        if not Settings.Fly and LocalPlayer.Character then
            local r = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if r then
                for _, c in ipairs(r:GetChildren()) do
                    if c:IsA("BodyGyro") or c:IsA("BodyVelocity") then c:Destroy() end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if Settings.Fly and LocalPlayer.Character then
            local r = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if r then
                local g = r:FindFirstChild("FlyG") or Instance.new("BodyGyro", r)
                g.Name = "FlyG" g.MaxTorque = Vector3.new(9e9, 9e9, 9e9) g.CFrame = Camera.CFrame g.Parent = r
                local v = r:FindFirstChild("FlyV") or Instance.new("BodyVelocity", r)
                v.Name = "FlyV" v.MaxForce = Vector3.new(400000, 400000, 400000) v.Parent = r
                local m = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then m = m + Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then m = m - Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then m = m - Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then m = m + Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then m = m + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then m = m - Vector3.new(0, 1, 0) end
                v.Velocity = m * Settings.FlyVal
            end
        end
    end
end)

-- SPINBOT
task.spawn(function()
    while task.wait(0.02) do
        if Settings.Spin and LocalPlayer.Character then
            local r = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if r then
                r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(Settings.SpinVal), 0)
            end
        end
    end
end)

-- FULLBRIGHT + ANTI-AFK
task.spawn(function()
    while task.wait(60) do
        if Settings.Fullbright then Lighting.Brightness = 2 Lighting.ClockTime = 14 end
        if Settings.AntiAFK then
            pcall(function()
                local VIM = game:GetService("VirtualInputManager")
                VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, nil)
                task.wait(0.1)
                VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, nil)
            end)
        end
    end
end)

print("Plalette Scripts · FFA Gun Grounds v1.0 · Potassium Ready")
