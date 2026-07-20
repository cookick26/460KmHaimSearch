local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- 실시간 설정 변수
local Settings = {
    FOV = 55,
    MULTIPLIER = 12, -- 초기 속도 배수 (첫 번째 코드와 동일)
    Enabled = true,
    AimKey = Enum.KeyCode.P,
    ToggleKey = Enum.KeyCode.Insert
}

local UiVisible = true -- 초기 UI 상태 (켜짐)

----------------------------------------------------------------                
-- 1. FOV 시각화 원(Drawing) 설정
----------------------------------------------------------------
local FovCircle = Drawing.new("Circle")
FovCircle.Color = Color3.fromRGB(105, 12, 12)
FovCircle.Thickness = 3
FovCircle.NumSides = 64
FovCircle.Filled = false
FovCircle.Transparency = 0.5
FovCircle.Visible = UiVisible

----------------------------------------------------------------                
-- 2. GUI 생성 (FOV 및 에임 강도 조절용 UI)
----------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimSettingsUI"
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 220, 0, 140)

-- [추가] UI의 중심점을 정중앙(0.5, 0.5)으로 설정합니다.
Frame.AnchorPoint = Vector2.new(0.5, 0.5) 

-- [수정] 화면 전체 가로(X)의 50%, 세로(Y)의 50% 위치(즉, 정중앙)에 배치합니다.
Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true 
Frame.Visible = UiVisible
Frame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = " Cookick Hub "
Title.TextColor3 = Color3.fromRGB(105, 12, 12)
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Center
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = Frame

-- 공통 슬라이더 생성 함수
local function createSlider(text, min, max, default, posY, callback)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, posY)
    label.Text = text .. " : " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(105, 12, 12)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.SourceSans
    label.TextSize = 16
    label.Parent = Frame

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -20, 0, 8)
    sliderBg.Position = UDim2.new(0, 10, 0, posY + 22)
    sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = Frame

    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(0, 16, 0, 16)
    sliderBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    sliderBtn.Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0)
    sliderBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    sliderBtn.Text = ""
    sliderBtn.Parent = sliderBg

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(1, 0)
    btnCorner.Parent = sliderBtn

    local dragging = false
    sliderBtn.MouseButton1Down:Connect(function() dragging = true end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    RunService.RenderStepped:Connect(function()
        if dragging and UiVisible then
            local mouseX = UserInputService:GetMouseLocation().X
            local relativeX = mouseX - sliderBg.AbsolutePosition.X
            local percent = math.clamp(relativeX / sliderBg.AbsoluteSize.X, 0, 1)
            sliderBtn.Position = UDim2.new(percent, 0, 0.5, 0)
            
            local value = math.floor(min + (percent * (max - min)))
            label.Text = text .. " : " .. tostring(value)
            callback(value)
        end
    end)
end

-- 1. FOV 슬라이더 생성 (위치 Y: 35)
createSlider("FOV SIZE", 10, 300, Settings.FOV, 35, function(val)
    Settings.FOV = val
end)

-- 2. [신규] MULTIPLIER 슬라이더 생성 (위치 Y: 85, 범위 1 ~ 20)
createSlider("AIMLOCK", 1, 20, Settings.MULTIPLIER, 85, function(val)
    Settings.MULTIPLIER = val
end)

----------------------------------------------------------------                
-- 3. Insert 키 입력 감지 (UI & FOV 토글)
----------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Settings.ToggleKey then
        UiVisible = not UiVisible
        Frame.Visible = UiVisible       
        FovCircle.Visible = UiVisible   
    end
end)

----------------------------------------------------------------                
-- 4. 에임봇 로직
----------------------------------------------------------------
local function getClosest()
    local target = nil
    local shortestDist = Settings.FOV 
    local mousePos = UserInputService:GetMouseLocation()

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local head = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("UpperTorso")
            
            if head and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        target = pos
                    end
                end
            end
        end
    end
    return target
end

RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    
    FovCircle.Position = mousePos
    FovCircle.Radius = Settings.FOV
    
    if UserInputService:IsKeyDown(Settings.AimKey) then
        local targetPos = getClosest()
        if targetPos then
            -- 실시간으로 바뀐 Settings.MULTIPLIER 배수가 적용됩니다.
            local diffX = (targetPos.X - mousePos.X) * Settings.MULTIPLIER
            local diffY = (targetPos.Y - mousePos.Y) * Settings.MULTIPLIER
            
            mousemoverel(diffX, diffY)
        end
    end
end)
