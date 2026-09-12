-- ==========================================
-- 👑 RAJA HUB — UI
-- Main window + Log window.
-- ==========================================

local H = shared.RajaHub
if not H then error("[RajaHub] UI: shared.RajaHub missing.") end

-- Suppress print / warn lokal.
local print = function() end
local warn = function() end

-- Services.
local playersService = H.playersService
local localPlayer = H.localPlayer
local userInputService = H.userInputService

-- ==========================================
-- THEME
-- ==========================================
local THEME = {
	bg = Color3.fromRGB(28, 24, 18),
	panel = Color3.fromRGB(38, 32, 24),
	card = Color3.fromRGB(46, 38, 28),
	accent = Color3.fromRGB(212, 175, 90),
	accentDark = Color3.fromRGB(140, 110, 50),
	text = Color3.fromRGB(235, 225, 205),
	textDim = Color3.fromRGB(160, 150, 130),
	ok = Color3.fromRGB(120, 200, 130),
	fail = Color3.fromRGB(220, 100, 100),
	blue = Color3.fromRGB(90, 140, 200),
	warn = Color3.fromRGB(255, 200, 80),
	glow = Color3.fromRGB(255, 255, 220),
	red = Color3.fromRGB(255, 80, 80),
	green = Color3.fromRGB(100, 255, 120),
}
H.THEME = THEME

-- ==========================================
-- HELPERS — UI BUILDER
-- ==========================================
H.makeBtn = function(parent, text, x, y, w, h, color, textColor)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, w, 0, h)
	btn.Position = UDim2.new(0, x, 0, y)
	btn.BackgroundColor3 = color or THEME.accentDark
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = textColor or THEME.text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.Parent = parent

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 5)
	c.Parent = btn

	return btn
end

H.makeCard = function(parent, title, height)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -6, 0, height)
	card.BackgroundColor3 = THEME.card
	card.BorderSizePixel = 0
	card.Parent = parent

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = card

	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -20, 0, 20)
	t.Position = UDim2.new(0, 10, 0, 6)
	t.BackgroundTransparency = 1
	t.Text = title
	t.TextColor3 = THEME.accent
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Font = Enum.Font.GothamBold
	t.TextSize = 12
	t.Parent = card

	return card
end

H.makeContent = function(parent)
	local cf = Instance.new("ScrollingFrame")
	cf.Size = UDim2.new(1, -20, 1, -84)
	cf.Position = UDim2.new(0, 10, 0, 80)
	cf.BackgroundTransparency = 1
	cf.BorderSizePixel = 0
	cf.CanvasSize = UDim2.new(0, 0, 0, 0)
	cf.AutomaticCanvasSize = Enum.AutomaticSize.Y
	cf.ScrollBarThickness = 4
	cf.Visible = false
	cf.Parent = parent

	local l = Instance.new("UIListLayout")
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Padding = UDim.new(0, 6)
	l.Parent = cf

	return cf
end

-- ==========================================
-- LOG WINDOW
-- ==========================================
local logScreen = Instance.new("ScreenGui")
logScreen.Name = "RajaHub_Logs"
logScreen.ResetOnSpawn = false
logScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() logScreen.Parent = gethui() end)
if not logScreen.Parent then logScreen.Parent = game:GetService("CoreGui") end

local logWin = Instance.new("Frame")
logWin.Size = UDim2.new(0, 400, 0, 200)
logWin.Position = UDim2.new(1, -420, 0, 60)
logWin.BackgroundColor3 = THEME.bg
logWin.BorderSizePixel = 0
logWin.Active = true
logWin.Draggable = true
logWin.Parent = logScreen

local logCorner = Instance.new("UICorner")
logCorner.CornerRadius = UDim.new(0, 8)
logCorner.Parent = logWin

local logTop = Instance.new("Frame")
logTop.Size = UDim2.new(1, 0, 0, 28)
logTop.BackgroundColor3 = THEME.panel
logTop.BorderSizePixel = 0
logTop.Parent = logWin

local logTopCorner = Instance.new("UICorner")
logTopCorner.CornerRadius = UDim.new(0, 8)
logTopCorner.Parent = logTop

local logTitle = Instance.new("TextLabel")
logTitle.Size = UDim2.new(1, -60, 1, 0)
logTitle.Position = UDim2.new(0, 10, 0, 0)
logTitle.BackgroundTransparency = 1
logTitle.Text = "📋 Logs"
logTitle.TextColor3 = THEME.accent
logTitle.TextXAlignment = Enum.TextXAlignment.Left
logTitle.Font = Enum.Font.GothamBold
logTitle.TextSize = 12
logTitle.Parent = logTop

local logMinBtn = Instance.new("TextButton")
logMinBtn.Size = UDim2.new(0, 20, 0, 18)
logMinBtn.Position = UDim2.new(1, -50, 0.5, -9)
logMinBtn.BackgroundColor3 = THEME.accentDark
logMinBtn.BorderSizePixel = 0
logMinBtn.Text = "—"
logMinBtn.TextColor3 = THEME.bg
logMinBtn.Font = Enum.Font.GothamBold
logMinBtn.TextSize = 10
logMinBtn.Parent = logTop

local lmCorner = Instance.new("UICorner")
lmCorner.CornerRadius = UDim.new(0, 3)
lmCorner.Parent = logMinBtn

local logCloseBtn = Instance.new("TextButton")
logCloseBtn.Size = UDim2.new(0, 20, 0, 18)
logCloseBtn.Position = UDim2.new(1, -26, 0.5, -9)
logCloseBtn.BackgroundColor3 = Color3.fromRGB(70, 30, 30)
logCloseBtn.BorderSizePixel = 0
logCloseBtn.Text = "×"
logCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
logCloseBtn.Font = Enum.Font.GothamBold
logCloseBtn.TextSize = 11
logCloseBtn.Parent = logTop

local lcCorner = Instance.new("UICorner")
lcCorner.CornerRadius = UDim.new(0, 3)
lcCorner.Parent = logCloseBtn

local logScroll = Instance.new("ScrollingFrame")
logScroll.Size = UDim2.new(1, -10, 1, -36)
logScroll.Position = UDim2.new(0, 5, 0, 32)
logScroll.BackgroundTransparency = 1
logScroll.BorderSizePixel = 0
logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
logScroll.ScrollBarThickness = 4
logScroll.Parent = logWin

local logLayout = Instance.new("UIListLayout")
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
logLayout.Padding = UDim.new(0, 1)
logLayout.Parent = logScroll

local logPad = Instance.new("UIPadding")
logPad.PaddingTop = UDim.new(0, 2)
logPad.PaddingLeft = UDim.new(0, 4)
logPad.PaddingRight = UDim.new(0, 4)
logPad.PaddingBottom = UDim.new(0, 2)
logPad.Parent = logScroll

H.refreshLogUI = function()
	for _, child in ipairs(logScroll:GetChildren()) do
		if child:IsA("TextLabel") then child:Destroy() end
	end
	for i, line in ipairs(H.logLines) do
		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(1, -6, 0, 14)
		row.BackgroundTransparency = 1
		row.Text = line
		row.TextColor3 = THEME.textDim
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Font = Enum.Font.Code
		row.TextSize = 10
		row.LayoutOrder = i
		row.Parent = logScroll
	end
	task.defer(function()
		logScroll.CanvasPosition = Vector2.new(0, logScroll.AbsoluteCanvasSize.Y)
	end)
end

-- Minimize log.
local logMinimized = false
logMinBtn.MouseButton1Click:Connect(function()
	logMinimized = not logMinimized
	logWin.Size = logMinimized and UDim2.new(0, 400, 0, 32) or UDim2.new(0, 400, 0, 200)
end)

logCloseBtn.MouseButton1Click:Connect(function()
	logWin.Visible = false
end)

H.ui.logWin = logWin

-- ==========================================
-- MAIN WINDOW
-- ==========================================
local mainScreen = Instance.new("ScreenGui")
mainScreen.Name = "RajaHub_Main"
mainScreen.ResetOnSpawn = false
mainScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() mainScreen.Parent = gethui() end)
if not mainScreen.Parent then mainScreen.Parent = game:GetService("CoreGui") end

local mainWin = Instance.new("Frame")
mainWin.Size = UDim2.new(0, 500, 0, 650)
mainWin.Position = UDim2.new(0, 60, 0, 60)
mainWin.BackgroundColor3 = THEME.bg
mainWin.BorderSizePixel = 0
mainWin.Active = true
mainWin.Draggable = true
mainWin.Parent = mainScreen

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainWin

-- Topbar.
local mainTop = Instance.new("Frame")
mainTop.Size = UDim2.new(1, 0, 0, 34)
mainTop.BackgroundColor3 = THEME.panel
mainTop.BorderSizePixel = 0
mainTop.Parent = mainWin

local mtCorner = Instance.new("UICorner")
mtCorner.CornerRadius = UDim.new(0, 8)
mtCorner.Parent = mainTop

local mainTitle = Instance.new("TextLabel")
mainTitle.Size = UDim2.new(1, -70, 1, 0)
mainTitle.Position = UDim2.new(0, 12, 0, 0)
mainTitle.BackgroundTransparency = 1
mainTitle.Text = "👑 Raja Hub"
mainTitle.TextColor3 = THEME.accent
mainTitle.TextXAlignment = Enum.TextXAlignment.Left
mainTitle.Font = Enum.Font.GothamBold
mainTitle.TextSize = 14
mainTitle.Parent = mainTop

local mainMinBtn = Instance.new("TextButton")
mainMinBtn.Size = UDim2.new(0, 24, 0, 22)
mainMinBtn.Position = UDim2.new(1, -60, 0.5, -11)
mainMinBtn.BackgroundColor3 = THEME.accentDark
mainMinBtn.BorderSizePixel = 0
mainMinBtn.Text = "—"
mainMinBtn.TextColor3 = THEME.bg
mainMinBtn.Font = Enum.Font.GothamBold
mainMinBtn.TextSize = 12
mainMinBtn.Parent = mainTop

local mmCorner = Instance.new("UICorner")
mmCorner.CornerRadius = UDim.new(0, 4)
mmCorner.Parent = mainMinBtn

local mainCloseBtn = Instance.new("TextButton")
mainCloseBtn.Size = UDim2.new(0, 24, 0, 22)
mainCloseBtn.Position = UDim2.new(1, -30, 0.5, -11)
mainCloseBtn.BackgroundColor3 = Color3.fromRGB(70, 30, 30)
mainCloseBtn.BorderSizePixel = 0
mainCloseBtn.Text = "×"
mainCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mainCloseBtn.Font = Enum.Font.GothamBold
mainCloseBtn.TextSize = 13
mainCloseBtn.Parent = mainTop

local mcCorner = Instance.new("UICorner")
mcCorner.CornerRadius = UDim.new(0, 4)
mcCorner.Parent = mainCloseBtn

-- Tab bar.
local tabRow = Instance.new("Frame")
tabRow.Size = UDim2.new(1, -20, 0, 32)
tabRow.Position = UDim2.new(0, 10, 0, 42)
tabRow.BackgroundTransparency = 1
tabRow.Parent = mainWin

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = tabRow

local function makeTab(text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.333, -3, 1, 0)
	btn.BackgroundColor3 = THEME.card
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = THEME.text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.Parent = tabRow
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 5)
	c.Parent = btn
	return btn
end

local tabSell = makeTab("💰 Sell")
local tabFarm = makeTab("🌾 Farm")
local tabMod = makeTab("🔧 Mod")

-- Content containers.
local sellContent = H.makeContent(mainWin)
local farmContent = H.makeContent(mainWin)
local modContent = H.makeContent(mainWin)

H.ui.mainWin = mainWin
H.ui.tabSell = tabSell
H.ui.tabFarm = tabFarm
H.ui.tabMod = tabMod
H.ui.sellContent = sellContent
H.ui.farmContent = farmContent
H.ui.modContent = modContent

-- Show tab.
H.ui.showTab = function(which)
	sellContent.Visible = (which == "sell")
	farmContent.Visible = (which == "farm")
	modContent.Visible = (which == "mod")
	tabSell.BackgroundColor3 = (which == "sell") and THEME.accentDark or THEME.card
	tabFarm.BackgroundColor3 = (which == "farm") and THEME.accentDark or THEME.card
	tabMod.BackgroundColor3 = (which == "mod") and THEME.accentDark or THEME.card
end

tabSell.MouseButton1Click:Connect(function() H.ui.showTab("sell") end)
tabFarm.MouseButton1Click:Connect(function() H.ui.showTab("farm") end)
tabMod.MouseButton1Click:Connect(function() H.ui.showTab("mod") end)
H.ui.showTab("sell")

-- Minimize main.
local mainMinimized = false
mainMinBtn.MouseButton1Click:Connect(function()
	mainMinimized = not mainMinimized
	mainWin.Size = mainMinimized and UDim2.new(0, 500, 0, 36) or UDim2.new(0, 500, 0, 650)
end)

mainCloseBtn.MouseButton1Click:Connect(function()
	mainWin.Visible = false
end)

H.log("UI loaded.")
