-- ==========================================
-- 👑 RAJA HUB — SELL
-- Sell ke merchant + Lock items + Threshold mode.
-- ==========================================

local H = shared.RajaHub
if not H then error("[RajaHub] Sell: shared.RajaHub missing.") end

-- Suppress print / warn lokal.
local print = function() end
local warn = function() end

local THEME = H.THEME
local S = H.S

-- ==========================================
-- SELL CORE
-- ==========================================
H.sellWithSwap = function()
	H.log("Starting sell...")
	local hrp = H.getHrp()
	if not hrp then H.log("❌ No HRP") return false end
	local originalPos = hrp.Position

	local merchant = H.findNearestMerchant(originalPos)
	if not merchant then H.log("❌ No merchant") return false end
	H.log("Merchant: " .. merchant.name)

	H.teleportLocal(merchant.pos)
	task.wait(H.AFTER_TP_WAIT)

	H.log("Equip Sell Pan (id=" .. S.sellPanIndex .. ")")
	pcall(function()
		H.equipPan:InvokeServer(tostring(S.sellPanIndex))
	end)
	task.wait(H.EQUIP_WAIT)

	H.log("Firing SellAll...")
	local sellOk, sellErr = pcall(function()
		H.sellAll:InvokeServer()
	end)
	if not sellOk then H.log("❌ SellAll: " .. tostring(sellErr)) end
	task.wait(H.SELL_WAIT)

	H.log("Equip Farm Pan (id=" .. S.farmPanIndex .. ")")
	pcall(function()
		H.equipPan:InvokeServer(tostring(S.farmPanIndex))
	end)
	task.wait(H.EQUIP_WAIT)

	H.teleportLocal(originalPos)
	task.wait(H.AFTER_TP_WAIT)

	H.log("✅ Sell done")
	return true
end

-- ==========================================
-- LOCK CORE
-- ==========================================
H.lockOre = function(ore)
	if not ore or not ore.Parent then return false end
	pcall(function()
		H.toggleLock:FireServer(ore)
	end)
	return true
end

H.lockAllOresByName = function(names, label)
	H.log("Locking: " .. (label or "") .. " (" .. #names .. " names)")
	local total = 0
	for _, name in ipairs(names) do
		local ores = H.findAllToolsByName(name)
		for _, ore in ipairs(ores) do
			H.lockOre(ore)
			total = total + 1
			task.wait(H.LOCK_DELAY)
		end
	end
	H.log("✅ Locked " .. total .. " ores")
	return total
end

H.lockSelected = function()
	local list = {}
	for name in pairs(S.selectedItems) do
		if S.selectedItems[name] then table.insert(list, name) end
	end
	return H.lockAllOresByName(list, "selected")
end

H.lockByRarity = function(rarityName)
	local list = H.RARITY[rarityName]
	if not list then return 0 end
	return H.lockAllOresByName(list, rarityName)
end

H.unlockAllItems = function()
	H.log("Unlocking all...")
	pcall(function()
		H.unlockAll:FireServer()
	end)
	task.wait(H.UNLOCK_WAIT)
	H.getInventory()
	H.log("✅ Unlock done")
end

-- Auto-lock via DescendantAdded.
H.onOreAdded = function(ore)
	if not S.autoLockEnabled then return end
	if not ore:IsA("Tool") then return end
	local name = ore.Name
	if not H.ITEM_RARITY[name] then return end
	if not S.selectedItems[name] then return end
	task.wait(0.3)
	if not ore.Parent then return end
	H.log("🔒 New ore: " .. name)
	H.lockOre(ore)
end

H.startAutoLockHook = function()
	if S.descendantConn then return end
	local bp = H.localPlayer:FindFirstChild("BackpackTwo")
	if not bp then H.log("❌ BackpackTwo not found") return end
	S.descendantConn = bp.DescendantAdded:Connect(H.onOreAdded)

	local list = {}
	for name in pairs(S.selectedItems) do
		if S.selectedItems[name] then table.insert(list, name) end
	end
	H.log("🔁 Auto-lock ON (" .. #list .. " ore types)")
	H.lockAllOresByName(list, "initial")
end

H.stopAutoLockHook = function()
	if S.descendantConn then
		S.descendantConn:Disconnect()
		S.descendantConn = nil
		H.log("🔁 Auto-lock OFF")
	end
end

-- ==========================================
-- UI — SELL CARD
-- ==========================================
local sellCard = H.makeCard(H.ui.sellContent, "💰 Sell", 220)
sellCard.LayoutOrder = 1

local currentPanLbl = Instance.new("TextLabel")
currentPanLbl.Size = UDim2.new(1, -20, 0, 16)
currentPanLbl.Position = UDim2.new(0, 10, 0, 28)
currentPanLbl.BackgroundTransparency = 1
currentPanLbl.Text = "Current pan: -"
currentPanLbl.TextColor3 = THEME.text
currentPanLbl.TextXAlignment = Enum.TextXAlignment.Left
currentPanLbl.Font = Enum.Font.Code
currentPanLbl.TextSize = 10
currentPanLbl.Parent = sellCard

local inventoryLbl = Instance.new("TextLabel")
inventoryLbl.Size = UDim2.new(1, -20, 0, 16)
inventoryLbl.Position = UDim2.new(0, 10, 0, 44)
inventoryLbl.BackgroundTransparency = 1
inventoryLbl.Text = "Inventory: -/-"
inventoryLbl.TextColor3 = THEME.text
inventoryLbl.TextXAlignment = Enum.TextXAlignment.Left
inventoryLbl.Font = Enum.Font.Code
inventoryLbl.TextSize = 10
inventoryLbl.Parent = sellCard

local sellNowBtn = H.makeBtn(sellCard, "💰 SELL NOW", 10, 68, 460, 30, THEME.blue)
local autoSellBtn = H.makeBtn(sellCard, "🔁 AUTO SELL: OFF", 10, 104, 460, 30, THEME.accentDark)

local threshLbl = Instance.new("TextLabel")
threshLbl.Size = UDim2.new(0, 140, 0, 20)
threshLbl.Position = UDim2.new(0, 10, 0, 140)
threshLbl.BackgroundTransparency = 1
threshLbl.Text = "Auto Sell Threshold:"
threshLbl.TextColor3 = THEME.textDim
threshLbl.TextXAlignment = Enum.TextXAlignment.Left
threshLbl.Font = Enum.Font.Gotham
threshLbl.TextSize = 10
threshLbl.Parent = sellCard

local threshInput = Instance.new("TextBox")
threshInput.Size = UDim2.new(0, 80, 0, 24)
threshInput.Position = UDim2.new(0, 150, 0, 138)
threshInput.BackgroundColor3 = THEME.bg
threshInput.BorderSizePixel = 0
threshInput.TextColor3 = THEME.text
threshInput.Text = tostring(S.thresholdValue)
threshInput.Font = Enum.Font.Code
threshInput.TextSize = 12
threshInput.Parent = sellCard

local tic = Instance.new("UICorner")
tic.CornerRadius = UDim.new(0, 4)
tic.Parent = threshInput

local sellPanLbl = Instance.new("TextLabel")
sellPanLbl.Size = UDim2.new(0, 100, 0, 20)
sellPanLbl.Position = UDim2.new(0, 10, 0, 170)
sellPanLbl.BackgroundTransparency = 1
sellPanLbl.Text = "Sell Pan ID:"
sellPanLbl.TextColor3 = THEME.textDim
sellPanLbl.TextXAlignment = Enum.TextXAlignment.Left
sellPanLbl.Font = Enum.Font.Gotham
sellPanLbl.TextSize = 10
sellPanLbl.Parent = sellCard

local sellPanInput = Instance.new("TextBox")
sellPanInput.Size = UDim2.new(0, 80, 0, 24)
sellPanInput.Position = UDim2.new(0, 100, 0, 168)
sellPanInput.BackgroundColor3 = THEME.bg
sellPanInput.BorderSizePixel = 0
sellPanInput.TextColor3 = THEME.text
sellPanInput.Text = S.sellPanIndex
sellPanInput.Font = Enum.Font.Code
sellPanInput.TextSize = 12
sellPanInput.Parent = sellCard

local spc = Instance.new("UICorner")
spc.CornerRadius = UDim.new(0, 4)
spc.Parent = sellPanInput

local farmPanLbl = Instance.new("TextLabel")
farmPanLbl.Size = UDim2.new(0, 100, 0, 20)
farmPanLbl.Position = UDim2.new(0, 200, 0, 170)
farmPanLbl.BackgroundTransparency = 1
farmPanLbl.Text = "Farm Pan ID:"
farmPanLbl.TextColor3 = THEME.textDim
farmPanLbl.TextXAlignment = Enum.TextXAlignment.Left
farmPanLbl.Font = Enum.Font.Gotham
farmPanLbl.TextSize = 10
farmPanLbl.Parent = sellCard

local farmPanInput = Instance.new("TextBox")
farmPanInput.Size = UDim2.new(0, 80, 0, 24)
farmPanInput.Position = UDim2.new(0, 290, 0, 168)
farmPanInput.BackgroundColor3 = THEME.bg
farmPanInput.BorderSizePixel = 0
farmPanInput.TextColor3 = THEME.text
farmPanInput.Text = S.farmPanIndex
farmPanInput.Font = Enum.Font.Code
farmPanInput.TextSize = 12
farmPanInput.Parent = sellCard

local fpc = Instance.new("UICorner")
fpc.CornerRadius = UDim.new(0, 4)
fpc.Parent = farmPanInput

H.ui.currentPanLbl = currentPanLbl
H.ui.inventoryLbl = inventoryLbl
H.ui.autoSellBtn = autoSellBtn
H.ui.sellPanInput = sellPanInput
H.ui.farmPanInput = farmPanInput
H.ui.threshInput = threshInput

sellPanInput:GetPropertyChangedSignal("Text"):Connect(function()
	S.sellPanIndex = sellPanInput.Text
	pcall(H.savePanSettings)
end)

farmPanInput:GetPropertyChangedSignal("Text"):Connect(function()
	S.farmPanIndex = farmPanInput.Text
	pcall(H.savePanSettings)
end)

threshInput:GetPropertyChangedSignal("Text"):Connect(function()
	local n = tonumber(threshInput.Text)
	if n then
		S.thresholdValue = n
		pcall(H.savePanSettings)
	end
end)

-- ==========================================
-- UI — LOCK CARD
-- ==========================================
local lockCard = H.makeCard(H.ui.sellContent, "🔒 Lock Items", 440)
lockCard.LayoutOrder = 2

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(0, 340, 0, 26)
searchBox.Position = UDim2.new(0, 10, 0, 28)
searchBox.BackgroundColor3 = THEME.bg
searchBox.BorderSizePixel = 0
searchBox.TextColor3 = THEME.text
searchBox.PlaceholderText = "🔍 Search item..."
searchBox.PlaceholderColor3 = THEME.textDim
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 11
searchBox.Parent = lockCard

local sbc = Instance.new("UICorner")
sbc.CornerRadius = UDim.new(0, 5)
sbc.Parent = searchBox

local selectAllBtn = H.makeBtn(lockCard, "Select All", 360, 28, 110, 26, THEME.blue)

local listScroll = Instance.new("ScrollingFrame")
listScroll.Size = UDim2.new(1, -20, 0, 180)
listScroll.Position = UDim2.new(0, 10, 0, 62)
listScroll.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
listScroll.BorderSizePixel = 0
listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
listScroll.ScrollBarThickness = 4
listScroll.Parent = lockCard

local lsc = Instance.new("UICorner")
lsc.CornerRadius = UDim.new(0, 6)
lsc.Parent = listScroll

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = listScroll

local listPad = Instance.new("UIPadding")
listPad.PaddingTop = UDim.new(0, 4)
listPad.PaddingLeft = UDim.new(0, 4)
listPad.PaddingRight = UDim.new(0, 4)
listPad.PaddingBottom = UDim.new(0, 4)
listPad.Parent = listScroll

local lockBtn = H.makeBtn(lockCard, "🔒 LOCK", 10, 250, 225, 30, THEME.ok, THEME.bg)
local unlockBtn = H.makeBtn(lockCard, "🔓 Unlock All", 245, 250, 225, 30, THEME.fail)

local lockRarityTitle = Instance.new("TextLabel")
lockRarityTitle.Size = UDim2.new(1, -20, 0, 18)
lockRarityTitle.Position = UDim2.new(0, 10, 0, 288)
lockRarityTitle.BackgroundTransparency = 1
lockRarityTitle.Text = "Lock by Rarity:"
lockRarityTitle.TextColor3 = THEME.accent
lockRarityTitle.TextXAlignment = Enum.TextXAlignment.Left
lockRarityTitle.Font = Enum.Font.GothamBold
lockRarityTitle.TextSize = 11
lockRarityTitle.Parent = lockCard

local rarityRow1 = Instance.new("Frame")
rarityRow1.Size = UDim2.new(1, -20, 0, 26)
rarityRow1.Position = UDim2.new(0, 10, 0, 308)
rarityRow1.BackgroundTransparency = 1
rarityRow1.Parent = lockCard

local r1L = Instance.new("UIListLayout")
r1L.FillDirection = Enum.FillDirection.Horizontal
r1L.Padding = UDim.new(0, 4)
r1L.Parent = rarityRow1

local rarityRow2 = Instance.new("Frame")
rarityRow2.Size = UDim2.new(1, -20, 0, 26)
rarityRow2.Position = UDim2.new(0, 10, 0, 338)
rarityRow2.BackgroundTransparency = 1
rarityRow2.Parent = lockCard

local r2L = Instance.new("UIListLayout")
r2L.FillDirection = Enum.FillDirection.Horizontal
r2L.Padding = UDim.new(0, 4)
r2L.Parent = rarityRow2

local rarityColors = {
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(120, 200, 130),
	Rare = Color3.fromRGB(90, 140, 200),
	Epic = Color3.fromRGB(180, 120, 255),
	Legendary = Color3.fromRGB(255, 200, 80),
	Mythic = Color3.fromRGB(255, 120, 120),
	Exotic = Color3.fromRGB(255, 100, 255),
}

local RARITY_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Exotic" }

for i, rarity in ipairs(RARITY_ORDER) do
	local parentRow = (i <= 4) and rarityRow1 or rarityRow2
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 111, 1, 0)
	btn.BackgroundColor3 = rarityColors[rarity] or THEME.accentDark
	btn.BorderSizePixel = 0
	btn.Text = rarity
	btn.TextColor3 = THEME.bg
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.Parent = parentRow

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 5)
	c.Parent = btn

	btn.MouseButton1Click:Connect(function()
		if S.sellTesting then return end
		S.sellTesting = true
		task.spawn(function()
			H.lockByRarity(rarity)
			S.sellTesting = false
		end)
	end)
end

local autoLockBtn = H.makeBtn(lockCard, "🔒 AUTO-LOCK: OFF", 10, 372, 460, 32, THEME.fail)

local autoLockGlow = Instance.new("Frame")
autoLockGlow.Size = UDim2.new(1, 4, 1, 4)
autoLockGlow.Position = UDim2.new(0, -2, 0, -2)
autoLockGlow.BackgroundTransparency = 1
autoLockGlow.BorderSizePixel = 2
autoLockGlow.BorderColor3 = THEME.glow
autoLockGlow.Visible = false
autoLockGlow.ZIndex = 0
autoLockGlow.Parent = autoLockBtn

local alc = Instance.new("UICorner")
alc.CornerRadius = UDim.new(0, 6)
alc.Parent = autoLockGlow

local statsLbl = Instance.new("TextLabel")
statsLbl.Size = UDim2.new(1, -20, 0, 16)
statsLbl.Position = UDim2.new(0, 10, 0, 410)
statsLbl.BackgroundTransparency = 1
statsLbl.Text = "Selected: 0"
statsLbl.TextColor3 = THEME.textDim
statsLbl.TextXAlignment = Enum.TextXAlignment.Left
statsLbl.Font = Enum.Font.Code
statsLbl.TextSize = 10
statsLbl.Parent = lockCard

H.ui.statsLbl = statsLbl

-- ==========================================
-- ITEM ROWS
-- ==========================================
local itemRows = {}

local function updateRowVisual(name)
	local r = itemRows[name]
	if not r then return end
	if S.selectedItems[name] then
		r.check.Text = "☑"
		r.check.TextColor3 = THEME.ok
	else
		r.check.Text = "☐"
		r.check.TextColor3 = THEME.textDim
	end
end

local function updateStats()
	local selCount = 0
	for _ in pairs(S.selectedItems) do selCount = selCount + 1 end
	local shown = 0
	for _, r in pairs(itemRows) do
		if r.row.Visible then shown = shown + 1 end
	end
	statsLbl.Text = "Selected: " .. selCount .. " | Showing: " .. shown
end

H.updateStats = updateStats
H.updateRowVisual = updateRowVisual

local function refreshList()
	local search = S.searchFilter:lower()
	local shown = 0
	for name, r in pairs(itemRows) do
		local visible = (search == "" or name:lower():find(search, 1, true))
		r.row.Visible = visible
		if visible then
			shown = shown + 1
			r.row.LayoutOrder = shown
		end
		updateRowVisual(name)
	end
	updateStats()
end

local function createRow(name)
	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, -8, 0, 24)
	row.BackgroundColor3 = THEME.card
	row.BorderSizePixel = 0
	row.Text = ""
	row.AutoButtonColor = true
	row.Parent = listScroll

	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 4)
	rc.Parent = row

	local checkLbl = Instance.new("TextLabel")
	checkLbl.Size = UDim2.new(0, 22, 1, 0)
	checkLbl.Position = UDim2.new(0, 4, 0, 0)
	checkLbl.BackgroundTransparency = 1
	checkLbl.Text = "☐"
	checkLbl.TextColor3 = THEME.textDim
	checkLbl.Font = Enum.Font.GothamBold
	checkLbl.TextSize = 13
	checkLbl.Parent = row

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, -100, 1, 0)
	nameLbl.Position = UDim2.new(0, 26, 0, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = name
	nameLbl.TextColor3 = THEME.text
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Font = Enum.Font.Gotham
	nameLbl.TextSize = 11
	nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
	nameLbl.Parent = row

	local rarityLbl = Instance.new("TextLabel")
	rarityLbl.Size = UDim2.new(0, 70, 1, 0)
	rarityLbl.Position = UDim2.new(1, -74, 0, 0)
	rarityLbl.BackgroundTransparency = 1
	rarityLbl.Text = H.ITEM_RARITY[name] or "?"
	rarityLbl.TextColor3 = rarityColors[H.ITEM_RARITY[name]] or THEME.textDim
	rarityLbl.TextXAlignment = Enum.TextXAlignment.Right
	rarityLbl.Font = Enum.Font.Code
	rarityLbl.TextSize = 9
	rarityLbl.Parent = row

	row.MouseButton1Click:Connect(function()
		if S.selectedItems[name] then
			S.selectedItems[name] = nil
		else
			S.selectedItems[name] = true
		end
		pcall(H.saveSelection)
		updateRowVisual(name)
		updateStats()
	end)

	itemRows[name] = { row = row, check = checkLbl }
end

for _, name in ipairs(H.ALL_ITEMS) do
	createRow(name)
end
refreshList()

-- Select all.
local selectAllState = false
selectAllBtn.MouseButton1Click:Connect(function()
	selectAllState = not selectAllState
	local search = S.searchFilter:lower()
	if selectAllState then
		for _, name in ipairs(H.ALL_ITEMS) do
			if search == "" or name:lower():find(search, 1, true) then
				S.selectedItems[name] = true
			end
		end
		selectAllBtn.Text = "Deselect All"
		selectAllBtn.BackgroundColor3 = THEME.fail
	else
		for _, name in ipairs(H.ALL_ITEMS) do
			if search == "" or name:lower():find(search, 1, true) then
				S.selectedItems[name] = nil
			end
		end
		selectAllBtn.Text = "Select All"
		selectAllBtn.BackgroundColor3 = THEME.blue
	end
	pcall(H.saveSelection)
	for name, _ in pairs(itemRows) do updateRowVisual(name) end
	updateStats()
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	S.searchFilter = searchBox.Text
	refreshList()
end)

-- ==========================================
-- HANDLERS
-- ==========================================
sellNowBtn.MouseButton1Click:Connect(function()
	if S.sellTesting then return end
	S.sellTesting = true
	task.spawn(function()
		H.sellWithSwap()
		S.sellTesting = false
	end)
end)

-- Auto sell: threshold-based.
autoSellBtn.MouseButton1Click:Connect(function()
	if S.sellAutoRunning then
		S.sellAutoRunning = false
		autoSellBtn.Text = "🔁 AUTO SELL: OFF"
		autoSellBtn.BackgroundColor3 = THEME.accentDark
		autoSellBtn.TextColor3 = THEME.text
		H.log("Auto sell OFF")
	else
		S.sellAutoRunning = true
		autoSellBtn.Text = "🔁 AUTO SELL: ON"
		autoSellBtn.BackgroundColor3 = THEME.ok
		autoSellBtn.TextColor3 = THEME.bg
		H.log("Auto sell ON (threshold=" .. S.thresholdValue .. ")")
		task.spawn(function()
			while S.sellAutoRunning and S.running do
				task.wait(H.INVENTORY_CHECK_INTERVAL)
				local cur, max = H.getInventoryCount()
				if cur and max and cur >= S.thresholdValue then
					H.log("Inventory " .. cur .. "/" .. max .. " ≥ threshold " .. S.thresholdValue .. " — selling")
					H.sellWithSwap()
					task.wait(2)
				end
			end
		end)
	end
end)

lockBtn.MouseButton1Click:Connect(function()
	if S.sellTesting then return end
	S.sellTesting = true
	task.spawn(function()
		H.lockSelected()
		S.sellTesting = false
	end)
end)

unlockBtn.MouseButton1Click:Connect(function()
	if S.sellTesting then return end
	S.sellTesting = true
	task.spawn(function()
		H.unlockAllItems()
		S.sellTesting = false
	end)
end)

autoLockBtn.MouseButton1Click:Connect(function()
	S.autoLockEnabled = not S.autoLockEnabled
	if S.autoLockEnabled then
		autoLockBtn.Text = "🔒 AUTO-LOCK: ON"
		autoLockBtn.BackgroundColor3 = THEME.ok
		autoLockBtn.TextColor3 = THEME.bg
		autoLockGlow.Visible = true
		H.startAutoLockHook()
	else
		autoLockBtn.Text = "🔒 AUTO-LOCK: OFF"
		autoLockBtn.BackgroundColor3 = THEME.fail
		autoLockBtn.TextColor3 = THEME.text
		autoLockGlow.Visible = false
		H.stopAutoLockHook()
	end
end)

-- ==========================================
-- LIVE UPDATE — CURRENT PAN + INVENTORY
-- ==========================================
task.spawn(function()
	while S.running do
		local pan = H.getCurrentPan()
		if pan then
			currentPanLbl.Text = "Current pan: " .. pan.Name
			currentPanLbl.TextColor3 = THEME.ok
		else
			currentPanLbl.Text = "Current pan: (none)"
			currentPanLbl.TextColor3 = THEME.textDim
		end
		local cur, max = H.getInventoryCount()
		if cur and max then
			inventoryLbl.Text = "Inventory: " .. cur .. " / " .. max
			if cur >= S.thresholdValue then
				inventoryLbl.TextColor3 = THEME.warn
			else
				inventoryLbl.TextColor3 = THEME.text
			end
		else
			inventoryLbl.Text = "Inventory: -/-"
			inventoryLbl.TextColor3 = THEME.textDim
		end
		task.wait(1)
	end
end)

H.log("Sell loaded.")
