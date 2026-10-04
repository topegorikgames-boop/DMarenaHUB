--[[
    DM Arena Hub - MOBILE EDITION
    Подходит для: Delta, Codex, Arceus X, Fluxus, Hydrogen, Vega X, Ronin
    Управление: плавающие кнопки на экране
]]

-- =============================================================================
-- СЕРВИСЫ
-- =============================================================================
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local GuiService       = game:GetService("GuiService")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

-- Безопасный доступ к PlayerGui (важно для мобильных экзекуторов)
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- =============================================================================
-- НАСТРОЙКИ
-- =============================================================================
local AimbotSettings = {
    Enabled   = false,
    TeamCheck = false,
    FOV       = 250,
    Smoothing = 0.18,
    Visible   = true,
    HitChance = 0.95,
}

local ESPSettings = {
    Enabled       = true,
    ShowBox       = true,
    ShowName      = true,
    ShowHP        = true,
    ShowDistance  = false,
    ShowFOVCircle = true,
    RainbowESP    = false,
}

local SpeedEnabled    = false
local NormalWalkSpeed = 16
local BoostSpeed      = 28

local totalShots, totalHits = 0, 0
local accuracy = 0

-- =============================================================================
-- ТЕМА
-- =============================================================================
local Theme = {
    Background    = Color3.fromRGB(20,  20,  26),
    Background2   = Color3.fromRGB(30,  30,  40),
    Accent        = Color3.fromRGB(0,   170, 100),
    AccentDark    = Color3.fromRGB(0,   120, 70),
    Danger        = Color3.fromRGB(220, 60,  60),
    Text          = Color3.fromRGB(235, 235, 245),
    SecondaryText = Color3.fromRGB(190, 190, 210),
    Divider       = Color3.fromRGB(55,  55,  70),
    ToggleOff     = Color3.fromRGB(70,  70,  85),
}

-- =============================================================================
-- SAFE AREA (учёт выреза/чёлки)
-- =============================================================================
local guiInset = GuiService:GetGuiInset()
local topInset = guiInset.Y
local leftInset = guiInset.X

-- =============================================================================
-- FOV КРУГ
-- =============================================================================
local FOVring = Drawing.new("Circle")
FOVring.Visible      = true
FOVring.Thickness    = 2
FOVring.Radius       = AimbotSettings.FOV
FOVring.Transparency = 1
FOVring.Color        = Color3.fromRGB(255, 128, 128)
FOVring.Position     = Camera.ViewportSize / 2
FOVring.Filled       = false
FOVring.NumSides     = 60

-- =============================================================================
-- ВОДЯНОЙ ЗНАК
-- =============================================================================
local watermarkBg = Drawing.new("Square")
watermarkBg.Visible      = true
watermarkBg.Position     = Vector2.new(Camera.ViewportSize.X - 175, topInset + 5)
watermarkBg.Size         = Vector2.new(140, 55)
watermarkBg.Thickness    = 1
watermarkBg.Filled       = true
watermarkBg.Color        = Color3.fromRGB(0, 0, 0)
watermarkBg.Transparency = 0.7

local watermark = Drawing.new("Text")
watermark.Visible      = true
watermark.Position     = Vector2.new(Camera.ViewportSize.X - 165, topInset + 10)
watermark.Size         = 20
watermark.Center       = false
watermark.Outline      = true
watermark.OutlineColor = Color3.fromRGB(0,0,0)
watermark.Color        = Color3.fromRGB(180, 180, 180)
watermark.Text         = "lin4ik | MOBILE"
watermark.Font         = Drawing.Fonts.Monospace

local fpsText = Drawing.new("Text")
fpsText.Visible      = true
fpsText.Position     = Vector2.new(Camera.ViewportSize.X - 165, topInset + 32)
fpsText.Size         = 15
fpsText.Center       = false
fpsText.Outline      = true
fpsText.OutlineColor = Color3.fromRGB(0,0,0)
fpsText.Color        = Color3.fromRGB(150, 150, 150)
fpsText.Text         = "FPS: 60"
fpsText.Font         = Drawing.Fonts.Monospace

-- =============================================================================
-- СВОЙ HP
-- =============================================================================
local selfHPText = Drawing.new("Text")
selfHPText.Visible      = true
selfHPText.Center       = true
selfHPText.Outline      = true
selfHPText.OutlineColor = Color3.fromRGB(0,0,0)
selfHPText.Color        = Color3.fromRGB(220, 220, 220)
selfHPText.Size         = 24
selfHPText.Font         = Drawing.Fonts.Monospace

-- =============================================================================
-- УВЕДОМЛЕНИЯ (мобильный тост)
-- =============================================================================
local notifText = Drawing.new("Text")
notifText.Visible      = false
notifText.Center       = true
notifText.Outline      = true
notifText.OutlineColor = Color3.fromRGB(0,0,0)
notifText.Color        = Color3.fromRGB(255, 255, 255)
notifText.Size         = 22
notifText.Font         = Drawing.Fonts.Monospace
notifText.Position     = Vector2.new(Camera.ViewportSize.X / 2, topInset + 100)

local notifToken = 0
local function notify(text, color)
    notifText.Text    = text
    notifText.Color   = color or Color3.fromRGB(255, 255, 255)
    notifText.Visible = true
    notifToken += 1
    local myToken = notifToken
    task.delay(1.5, function()
        if notifToken == myToken then
            notifText.Visible = false
        end
    end)
end

-- =============================================================================
-- РАДУЖНАЯ АНИМАЦИЯ + FPS
-- =============================================================================
local rainbowTime = 0
RunService.RenderStepped:Connect(function(delta)
    rainbowTime += delta * 1.2
    fpsText.Text = "FPS: " .. math.floor(1 / delta + 0.5)

    if ESPSettings.RainbowESP then
        local color = Color3.fromHSV(rainbowTime % 1, 1, 1)
        watermark.Color = color
        for _, data in pairs(espElements or {}) do
            data.nameTag.Color = color
            data.healthText.Color = color
            for _, line in ipairs(data.lines) do line.Color = color end
        end
    end
end)

-- Обновление позиций UI при повороте экрана
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    FOVring.Position     = Camera.ViewportSize / 2
    watermarkBg.Position = Vector2.new(Camera.ViewportSize.X - 175, topInset + 5)
    watermark.Position   = Vector2.new(Camera.ViewportSize.X - 165, topInset + 10)
    fpsText.Position     = Vector2.new(Camera.ViewportSize.X - 165, topInset + 32)
    notifText.Position   = Vector2.new(Camera.ViewportSize.X / 2, topInset + 100)
end)

-- =============================================================================
-- СВОЙ HP
-- =============================================================================
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then selfHPText.Visible = false return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local head     = char:FindFirstChild("Head")

    if humanoid and head then
        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2.8, 0))
        if onScreen then
            local hpPerc = math.clamp(math.floor(humanoid.Health / humanoid.MaxHealth * 100 + 0.5), 0, 100)
            selfHPText.Text = hpPerc .. "%"
            selfHPText.Position = Vector2.new(screenPos.X, screenPos.Y - 30)
            selfHPText.Visible = true
            selfHPText.Color = hpPerc > 70 and Color3.fromRGB(100, 220, 140)
                or hpPerc > 30 and Color3.fromRGB(220, 180, 60)
                or Color3.fromRGB(220, 60, 60)
        else
            selfHPText.Visible = false
        end
    else
        selfHPText.Visible = false
    end
end)

-- =============================================================================
-- AIMBOT ЛОГИКА
-- =============================================================================
local function isVisible(targetPart)
    if not AimbotSettings.Visible then return true end
    local origin = Camera.CFrame.Position
    local dir    = (targetPart.Position - origin).Unit * 1000
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = workspace:Raycast(origin, dir, params)
    return result and result.Instance and result.Instance:IsDescendantOf(targetPart.Parent)
end

local function getClosest()
    local target, mag = nil, math.huge
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character then
            local head = v.Character:FindFirstChild("Head")
            local hum  = v.Character:FindFirstChildOfClass("Humanoid")
            local hrp  = v.Character:FindFirstChild("HumanoidRootPart")

            if head and hum and hrp and hum.Health > 0 then
                if AimbotSettings.TeamCheck and v.Team == LocalPlayer.Team then
                    continue
                end
                local headPos = head.Position
                local closestPoint = Ray.new(Camera.CFrame.Position, Camera.CFrame.LookVector * 5000):ClosestPoint(headPos)
                local distToRay = (headPos - closestPoint).Magnitude
                if distToRay < mag then
                    mag, target = distToRay, v
                end
            end
        end
    end
    return target
end

local function updateLearning(success)
    totalShots += 1
    if success then totalHits += 1 end
    accuracy = totalShots > 0 and (totalHits / totalShots) or 0
    if accuracy < 0.3 then
        AimbotSettings.FOV = math.min(600, AimbotSettings.FOV + 10)
        AimbotSettings.Smoothing = math.max(0.05, AimbotSettings.Smoothing - 0.01)
    elseif accuracy > 0.7 then
        AimbotSettings.Smoothing = math.min(1, AimbotSettings.Smoothing + 0.01)
    end
    FOVring.Radius = AimbotSettings.FOV
end

-- Аимбот теперь на ТОГГЛЕ (не hold) — так удобнее на мобиле
RunService.RenderStepped:Connect(function()
    if not AimbotSettings.Enabled then return end

    local cam = Camera
    local screenCenter = cam.ViewportSize / 2

    local target = getClosest()
    if not target or not target.Character then return end

    local head = target.Character:FindFirstChild("Head")
    if not head then return end

    local headPos = head.Position
    local ssHead, onScreen = cam:WorldToViewportPoint(headPos)
    local screenHead = Vector2.new(ssHead.X, ssHead.Y)

    if onScreen and (screenHead - screenCenter).Magnitude < AimbotSettings.FOV then
        if not isVisible(head) then return end
        local targetCFrame = CFrame.new(cam.CFrame.Position, headPos)
        cam.CFrame = cam.CFrame:Lerp(targetCFrame, AimbotSettings.Smoothing)
        local hitChance = math.random() < AimbotSettings.HitChance
        updateLearning(hitChance)
    end
end)

-- =============================================================================
-- ESP
-- =============================================================================
local espElements = {}

local function createESP(player)
    if player == LocalPlayer or espElements[player] then return end

    local esp = {}

    esp.nameTag = Drawing.new("Text")
    esp.nameTag.Visible = false
    esp.nameTag.Center  = true
    esp.nameTag.Outline = true
    esp.nameTag.Size    = 15
    esp.nameTag.Color   = Color3.fromRGB(230, 230, 230)
    esp.nameTag.Text    = player.Name
    esp.nameTag.Font    = Drawing.Fonts.Monospace

    esp.healthText = Drawing.new("Text")
    esp.healthText.Visible = false
    esp.healthText.Outline = true
    esp.healthText.Size    = 14
    esp.healthText.Color   = Color3.fromRGB(180, 180, 180)
    esp.healthText.Font    = Drawing.Fonts.Monospace

    esp.distText = Drawing.new("Text")
    esp.distText.Visible = false
    esp.distText.Center  = true
    esp.distText.Outline = true
    esp.distText.Size    = 13
    esp.distText.Color   = Color3.fromRGB(160, 200, 255)
    esp.distText.Font    = Drawing.Fonts.Monospace

    esp.lines = {}
    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Visible      = false
        line.Thickness    = 1.5
        line.Transparency = 1
        line.Color        = Color3.fromRGB(200, 200, 200)
        table.insert(esp.lines, line)
    end

    espElements[player] = esp
end

local function hideESPData(data)
    data.nameTag.Visible    = false
    data.healthText.Visible = false
    data.distText.Visible   = false
    for _, ln in ipairs(data.lines) do ln.Visible = false end
end

local function updateESP()
    if not ESPSettings.Enabled then
        for _, data in pairs(espElements) do hideESPData(data) end
        FOVring.Visible = ESPSettings.ShowFOVCircle
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        local data = espElements[player]
        if not data then continue end

        if player.Character then
            local hrp  = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")
            local hum  = player.Character:FindFirstChildOfClass("Humanoid")

            if hrp and head and hum and hum.Health > 0 then
                local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local top    = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.6, 0))
                    local bottom = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                    local height = math.abs(top.Y - bottom.Y)
                    local width  = height * 0.55

                    local left  = Vector2.new(rootPos.X - width/2, top.Y)
                    local right = Vector2.new(rootPos.X + width/2, top.Y)
                    local bl    = Vector2.new(left.X,  bottom.Y)
                    local br    = Vector2.new(right.X, bottom.Y)

                    if ESPSettings.ShowBox then
                        local c = ESPSettings.RainbowESP
                            and Color3.fromHSV((tick() * 0.8) % 1, 1, 1)
                            or Color3.fromRGB(200, 200, 200)
                        for _, ln in ipairs(data.lines) do ln.Color = c end
                        data.lines[1].From = left;  data.lines[1].To = right; data.lines[1].Visible = true
                        data.lines[2].From = right; data.lines[2].To = br;    data.lines[2].Visible = true
                        data.lines[3].From = br;    data.lines[3].To = bl;    data.lines[3].Visible = true
                        data.lines[4].From = bl;    data.lines[4].To = left;  data.lines[4].Visible = true
                    else
                        for _, ln in ipairs(data.lines) do ln.Visible = false end
                    end

                    data.nameTag.Visible = ESPSettings.ShowName
                    if ESPSettings.ShowName then
                        data.nameTag.Position = Vector2.new(rootPos.X, top.Y - 22)
                        if not ESPSettings.RainbowESP then
                            data.nameTag.Color = Color3.fromRGB(230, 230, 230)
                        end
                    end

                    if ESPSettings.ShowHP then
                        local hpPerc = math.clamp(math.floor(hum.Health / hum.MaxHealth * 100), 0, 100)
                        data.healthText.Text = hpPerc .. "%"
                        if not ESPSettings.RainbowESP then
                            data.healthText.Color = hpPerc > 70 and Color3.fromRGB(100, 220, 140)
                                or hpPerc > 30 and Color3.fromRGB(220, 180, 60)
                                or Color3.fromRGB(220, 60, 60)
                        end
                        data.healthText.Position = Vector2.new(right.X + 6, rootPos.Y - 10)
                        data.healthText.Visible = true
                    else
                        data.healthText.Visible = false
                    end

                    if ESPSettings.ShowDistance and LocalPlayer.Character then
                        local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if myHrp then
                            local dist = math.floor((myHrp.Position - hrp.Position).Magnitude)
                            data.distText.Text = "[" .. dist .. "m]"
                            data.distText.Position = Vector2.new(rootPos.X, bottom.Y + 4)
                            data.distText.Visible = true
                        end
                    else
                        data.distText.Visible = false
                    end
                else
                    hideESPData(data)
                end
            else
                hideESPData(data)
            end
        else
            hideESPData(data)
        end
    end

    FOVring.Visible = ESPSettings.ShowFOVCircle
end

for _, plr in pairs(Players:GetPlayers()) do createESP(plr) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(plr)
    local d = espElements[plr]
    if d then
        d.nameTag:Remove()
        d.healthText:Remove()
        d.distText:Remove()
        for _, ln in ipairs(d.lines) do ln:Remove() end
        espElements[plr] = nil
    end
end)
RunService.RenderStepped:Connect(updateESP)

-- =============================================================================
-- МОБИЛЬНАЯ GUI
-- =============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name          = "DMArenaMobile"
screenGui.ResetOnSpawn  = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent        = PlayerGui

-- =============================================================================
-- ПЛАВАЮЩАЯ КНОПКА ОТКРЫТИЯ МЕНЮ (FAB)
-- =============================================================================
local fab = Instance.new("TextButton")
fab.Name             = "FAB"
fab.Size             = UDim2.new(0, 56, 0, 56)
fab.Position         = UDim2.new(0, leftInset + 14, 0.35, 0)
fab.BackgroundColor3 = Theme.Accent
fab.Text             = "☰"
fab.TextColor3       = Color3.new(1,1,1)
fab.TextSize         = 28
fab.Font             = Enum.Font.GothamBold
fab.AutoButtonColor  = false
fab.BorderSizePixel  = 0
fab.Parent           = screenGui
Instance.new("UICorner", fab).CornerRadius = UDim.new(1)

local fabStroke = Instance.new("UIStroke", fab)
fabStroke.Color = Color3.fromRGB(255,255,255)
fabStroke.Transparency = 0.7
fabStroke.Thickness = 2

-- Перетаскивание FAB по экрану
local fabDragging = false
local fabDragStart, fabStartPos, fabMoved
fab.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        fabDragging  = true
        fabMoved     = false
        fabDragStart = input.Position
        fabStartPos  = fab.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if fabDragging and (input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - fabDragStart
        if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
            fabMoved = true
        end
        fab.Position = UDim2.new(
            fabStartPos.X.Scale, fabStartPos.X.Offset + delta.X,
            fabStartPos.Y.Scale, fabStartPos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        fabDragging = false
    end
end)
fab.MouseButton1Click:Connect(function()
    if fabMoved then return end
    screenGui:FindFirstChild("MainFrame").Visible = not screenGui:FindFirstChild("MainFrame").Visible
end)

-- =============================================================================
-- КНОПКИ AIMBOT И SPEED (плавающие, справа)
-- =============================================================================
local function makeActionButton(text, yPos, color, onClick)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, 60, 0, 60)
    btn.Position         = UDim2.new(1, -74, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text             = text
    btn.TextColor3       = Color3.new(1,1,1)
    btn.TextSize         = 22
    btn.Font             = Enum.Font.GothamBold
    btn.AutoButtonColor  = false
    btn.BorderSizePixel  = 0
    btn.Parent           = screenGui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(255,255,255)
    stroke.Transparency = 0.7
    stroke.Thickness = 2

    local dragging, dragStart, startPos, moved
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, moved = true, false
            dragStart = input.Position
            startPos  = btn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then moved = true end
            btn.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if dragging and not moved then
                onClick()
            end
            dragging = false
        end
    end)
    return btn
end

local aimBtn = makeActionButton("◎", topInset + 150, Color3.fromRGB(180, 60, 60), function()
    AimbotSettings.Enabled = not AimbotSettings.Enabled
    aimBtn.BackgroundColor3 = AimbotSettings.Enabled and Theme.Accent or Color3.fromRGB(180, 60, 60)
    notify(AimbotSettings.Enabled and "Aimbot: ON" or "Aimbot: OFF")
end)

local speedBtn = makeActionButton("»", topInset + 220, Color3.fromRGB(60, 100, 180), function()
    SpeedEnabled = not SpeedEnabled
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if SpeedEnabled then
                NormalWalkSpeed = hum.WalkSpeed
                hum.WalkSpeed = BoostSpeed
            else
                hum.WalkSpeed = NormalWalkSpeed
            end
        end
    end
    speedBtn.BackgroundColor3 = SpeedEnabled and Theme.Accent or Color3.fromRGB(60, 100, 180)
    notify(SpeedEnabled and "Speed: ON" or "Speed: OFF")
end)

-- =============================================================================
-- ГЛАВНОЕ МЕНЮ
-- =============================================================================
local mainFrame = Instance.new("Frame")
mainFrame.Name             = "MainFrame"
mainFrame.Size             = UDim2.new(0, 300, 0, 460)
mainFrame.Position         = UDim2.new(0.5, -150, 0.5, -230)
mainFrame.BackgroundColor3 = Theme.Background
mainFrame.BorderSizePixel  = 0
mainFrame.Visible          = false
mainFrame.Parent           = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Theme.Accent
mainStroke.Transparency = 0.4
mainStroke.Thickness = 1.5

local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Theme.Background2
titleBar.BorderSizePixel  = 0
titleBar.Parent           = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 16)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size             = UDim2.new(1, -70, 1, 0)
titleLabel.Position         = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text             = "lin4ik MOBILE"
titleLabel.TextColor3       = Theme.Text
titleLabel.TextSize         = 19
titleLabel.Font             = Enum.Font.GothamBold
titleLabel.TextXAlignment   = Enum.TextXAlignment.Left
titleLabel.Parent           = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0, 36, 0, 36)
closeBtn.Position         = UDim2.new(1, -44, 0.5, -18)
closeBtn.BackgroundColor3 = Theme.Danger
closeBtn.Text             = "✕"
closeBtn.TextColor3       = Color3.new(1,1,1)
closeBtn.TextSize         = 18
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.AutoButtonColor  = false
closeBtn.BorderSizePixel  = 0
closeBtn.Parent           = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1)
closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

-- Перетаскивание меню (тач)
local mDrag, mDragStart, mStartPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        mDrag = true
        mDragStart = input.Position
        mStartPos = mainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if mDrag and (input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - mDragStart
        mainFrame.Position = UDim2.new(
            mStartPos.X.Scale, mStartPos.X.Offset + delta.X,
            mStartPos.Y.Scale, mStartPos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        mDrag = false
    end
end)

-- ВКЛАДКИ
local tabBar = Instance.new("Frame")
tabBar.Size             = UDim2.new(1, -20, 0, 42)
tabBar.Position         = UDim2.new(0, 10, 0, 56)
tabBar.BackgroundTransparency = 1
tabBar.Parent           = mainFrame

local tabNames   = {"ESP", "AIM", "BINDS"}
local tabButtons = {}
local contentFrames = {}

for i, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1/#tabNames, -4, 1, 0)
    btn.Position         = UDim2.new((i-1)/#tabNames, 2, 0, 0)
    btn.BackgroundColor3 = (i == 1) and Theme.Accent or Theme.ToggleOff
    btn.Text             = name
    btn.TextColor3       = Theme.Text
    btn.TextSize         = 16
    btn.Font             = Enum.Font.GothamBold
    btn.BorderSizePixel  = 0
    btn.AutoButtonColor  = false
    btn.Parent           = tabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    tabButtons[name] = btn

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size                 = UDim2.new(1, -20, 1, -110)
    scroll.Position             = UDim2.new(0, 10, 0, 106)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel      = 0
    scroll.ScrollBarThickness   = 4
    scroll.ScrollBarImageColor3 = Theme.Accent
    scroll.CanvasSize           = UDim2.new(0, 0, 0, 600)
    scroll.Visible              = (i == 1)
    scroll.Parent               = mainFrame
    contentFrames[name]         = scroll
end

for name, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        for _, c in pairs(contentFrames) do c.Visible = false end
        contentFrames[name].Visible = true
        for _, b in pairs(tabButtons) do b.BackgroundColor3 = Theme.ToggleOff end
        btn.BackgroundColor3 = Theme.Accent
    end)
end

-- =============================================================================
-- СОЗДАНИЕ ТОГГЛА (mobile friendly — большие кнопки)
-- =============================================================================
local function createToggle(parent, name, initial, callback, yPos)
    local cont = Instance.new("Frame")
    cont.Size                 = UDim2.new(1, -10, 0, 52)
    cont.Position             = UDim2.new(0, 5, 0, yPos)
    cont.BackgroundColor3     = Theme.Background2
    cont.BorderSizePixel      = 0
    cont.Parent               = parent
    Instance.new("UICorner", cont).CornerRadius = UDim.new(0, 10)

    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(0.65, 0, 1, 0)
    lbl.Position         = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text             = name
    lbl.TextColor3       = Theme.Text
    lbl.TextSize         = 16
    lbl.Font             = Enum.Font.GothamSemibold
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Parent           = cont

    local bg = Instance.new("Frame")
    bg.Size             = UDim2.new(0, 58, 0, 30)
    bg.Position         = UDim2.new(1, -74, 0.5, -15)
    bg.BackgroundColor3 = initial and Theme.Accent or Theme.ToggleOff
    bg.BorderSizePixel  = 0
    bg.Parent           = cont
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1)

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 24, 0, 24)
    knob.Position         = initial and UDim2.new(0, 30, 0.5, -12) or UDim2.new(0, 4, 0.5, -12)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel  = 0
    knob.Parent           = bg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1)

    local btn = Instance.new("TextButton")
    btn.Size                 = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text                 = ""
    btn.Parent               = cont

    local state = initial
    btn.MouseButton1Click:Connect(function()
        state = not state
        bg.BackgroundColor3 = state and Theme.Accent or Theme.ToggleOff
        knob:TweenPosition(
            state and UDim2.new(0, 30, 0.5, -12) or UDim2.new(0, 4, 0.5, -12),
            "Out", "Quad", 0.15, true
        )
        callback(state)
    end)
end

-- =============================================================================
-- СОЗДАНИЕ СЛАЙДЕРА (mobile friendly)
-- =============================================================================
local function createSlider(parent, name, min, max, initial, callback, yPos)
    local cont = Instance.new("Frame")
    cont.Size                 = UDim2.new(1, -10, 0, 66)
    cont.Position             = UDim2.new(0, 5, 0, yPos)
    cont.BackgroundColor3     = Theme.Background2
    cont.BorderSizePixel      = 0
    cont.Parent               = parent
    Instance.new("UICorner", cont).CornerRadius = UDim.new(0, 10)

    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, -20, 0, 22)
    lbl.Position         = UDim2.new(0, 14, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text             = name .. ": " .. tostring(initial)
    lbl.TextColor3       = Theme.Text
    lbl.TextSize         = 15
    lbl.Font             = Enum.Font.GothamSemibold
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Parent           = cont

    local sliderBg = Instance.new("Frame")
    sliderBg.Size             = UDim2.new(1, -28, 0, 12)
    sliderBg.Position         = UDim2.new(0, 14, 0, 38)
    sliderBg.BackgroundColor3 = Theme.ToggleOff
    sliderBg.BorderSizePixel  = 0
    sliderBg.Parent           = cont
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1)

    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new((initial - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel  = 0
    fill.Parent           = sliderBg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1)

    -- Невидимая большая область для удобного тапа пальцем
    local touchArea = Instance.new("TextButton")
    touchArea.Size             = UDim2.new(1, 0, 0, 30)
    touchArea.Position         = UDim2.new(0, 0, 0.5, -15)
    touchArea.BackgroundTransparency = 1
    touchArea.Text             = ""
    touchArea.Parent           = sliderBg

    local dragging = false
    local function updateFromX(x)
        local rel = math.clamp((x - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * rel + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text  = name .. ": " .. tostring(val)
        callback(val)
    end

    touchArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement) then
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- =============================================================================
-- ЗАПОЛНЕНИЕ ВКЛАДОК
-- =============================================================================
local yESP = 5
createToggle(contentFrames["ESP"], "ESP Enabled",     ESPSettings.Enabled,       function(v) ESPSettings.Enabled = v end, yESP) yESP += 58
createToggle(contentFrames["ESP"], "Show Box",        ESPSettings.ShowBox,       function(v) ESPSettings.ShowBox = v end, yESP) yESP += 58
createToggle(contentFrames["ESP"], "Show Name",       ESPSettings.ShowName,      function(v) ESPSettings.ShowName = v end, yESP) yESP += 58
createToggle(contentFrames["ESP"], "Show HP %",       ESPSettings.ShowHP,        function(v) ESPSettings.ShowHP = v end, yESP) yESP += 58
createToggle(contentFrames["ESP"], "Show Distance",   ESPSettings.ShowDistance,  function(v) ESPSettings.ShowDistance = v end, yESP) yESP += 58
createToggle(contentFrames["ESP"], "Show FOV Circle", ESPSettings.ShowFOVCircle, function(v)
    ESPSettings.ShowFOVCircle = v
    FOVring.Visible = v
end, yESP) yESP += 58
createToggle(contentFrames["ESP"], "Rainbow ESP",     ESPSettings.RainbowESP,    function(v) ESPSettings.RainbowESP = v end, yESP) yESP += 58

local yAIM = 5
createToggle(contentFrames["AIM"], "Aimbot Enabled", AimbotSettings.Enabled,   function(v)
    AimbotSettings.Enabled = v
    aimBtn.BackgroundColor3 = v and Theme.Accent or Color3.fromRGB(180, 60, 60)
end, yAIM) yAIM += 58
createToggle(contentFrames["AIM"], "Team Check",     AimbotSettings.TeamCheck, function(v) AimbotSettings.TeamCheck = v end, yAIM) yAIM += 58
createToggle(contentFrames["AIM"], "Visible Only",   AimbotSettings.Visible,   function(v) AimbotSettings.Visible = v end, yAIM) yAIM += 58

createSlider(contentFrames["AIM"], "FOV",       50, 800, AimbotSettings.FOV, function(v)
    AimbotSettings.FOV = v
    FOVring.Radius = v
end, yAIM) yAIM += 72

createSlider(contentFrames["AIM"], "Smoothing", 1, 100, math.floor(AimbotSettings.Smoothing * 100), function(v)
    AimbotSettings.Smoothing = v / 100
end, yAIM) yAIM += 72

-- Вкладка биндов (для тех, у кого есть блютус-клавиатура)
local bindsContent = contentFrames["BINDS"]
local bindY = 5
local listeningFor = nil
local Binds = {
    OpenMenu = Enum.KeyCode.M,
    Aimbot   = Enum.KeyCode.E,
    Speed    = Enum.KeyCode.V,
}

local function createBindRow(name, defaultKey)
    local frame = Instance.new("Frame")
    frame.Size                 = UDim2.new(1, -10, 0, 52)
    frame.Position             = UDim2.new(0, 5, 0, bindY)
    frame.BackgroundColor3     = Theme.Background2
    frame.BorderSizePixel      = 0
    frame.Parent               = bindsContent
    frame.Name                 = name
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(0.55, 0, 1, 0)
    lbl.Position         = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text             = name
    lbl.TextColor3       = Theme.Text
    lbl.TextSize         = 15
    lbl.Font             = Enum.Font.GothamSemibold
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Parent           = frame

    local keyBtn = Instance.new("TextButton")
    keyBtn.Size             = UDim2.new(0, 110, 0, 36)
    keyBtn.Position         = UDim2.new(1, -124, 0.5, -18)
    keyBtn.BackgroundColor3 = Theme.Accent
    keyBtn.Text             = UserInputService:GetStringForKeyCode(defaultKey) or "None"
    keyBtn.TextColor3       = Color3.new(1,1,1)
    keyBtn.TextSize         = 14
    keyBtn.Font             = Enum.Font.GothamBold
    keyBtn.AutoButtonColor  = false
    keyBtn.BorderSizePixel  = 0
    keyBtn.Parent           = frame
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 8)

    keyBtn.MouseButton1Click:Connect(function()
        if listeningFor then return end
        listeningFor = name
        keyBtn.Text = "..."
        keyBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    end)

    bindY += 58
end

createBindRow("OpenMenu", Binds.OpenMenu)
createBindRow("Aimbot",   Binds.Aimbot)
createBindRow("Speed",    Binds.Speed)

-- =============================================================================
-- ГЛОБАЛЬНЫЙ ОБРАБОТЧИК КЛАВИАТУРЫ (для блютус-клавиатур)
-- =============================================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if listeningFor then
        local key = input.KeyCode
        if key ~= Enum.KeyCode.Unknown then
            if key == Enum.KeyCode.Backspace then
                Binds[listeningFor] = nil
            else
                Binds[listeningFor] = key
            end
            for _, child in ipairs(bindsContent:GetChildren()) do
                if child.Name == listeningFor then
                    local btn = child:FindFirstChildWhichIsA("TextButton")
                    if btn then
                        btn.Text = UserInputService:GetStringForKeyCode(Binds[listeningFor]) or "None"
                        btn.BackgroundColor3 = Theme.Accent
                    end
                end
            end
            listeningFor = nil
        end
        return
    end

    if input.KeyCode == Binds.OpenMenu then
        mainFrame.Visible = not mainFrame.Visible
    end
    if input.KeyCode == Binds.Speed then
        SpeedEnabled = not SpeedEnabled
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                if SpeedEnabled then
                    NormalWalkSpeed = hum.WalkSpeed
                    hum.WalkSpeed = BoostSpeed
                else
                    hum.WalkSpeed = NormalWalkSpeed
                end
            end
        end
        speedBtn.BackgroundColor3 = SpeedEnabled and Theme.Accent or Color3.fromRGB(60, 100, 180)
        notify(SpeedEnabled and "Speed: ON" or "Speed: OFF")
    end
end)

-- Сохранение скорости при респавне
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if SpeedEnabled then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = BoostSpeed end
    end
end)

-- =============================================================================
-- СТАРТ
-- =============================================================================
notify("lin4ik MOBILE загружено!", Color3.fromRGB(100, 220, 140))
task.delay(2, function()
    notify("Тапни ☰ слева", Color3.fromRGB(200, 200, 255))
end)
task.delay(4, function()
    notify("◎ = аимбот, » = скорость", Color3.fromRGB(200, 200, 255))
end)

print("[DM Arena MOBILE] Загружено | FAB слева, aim/speed справа")