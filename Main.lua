-- ==========================================
-- 👑 RAJA HUB — MAIN
-- Entry point. Load semua module.
-- ==========================================

-- Base URL GitHub.
local BASE_URL = "https://raw.githubusercontent.com/famaxx21/Raja-HUB-Prospecting/main/"

-- Anti double-load.
if shared.RajaHub and shared.RajaHub._loaded then
	warn("[RajaHub] Already loaded. Skipping.")
	return
end

shared.RajaHub = shared.RajaHub or {}
shared.RajaHub._loaded = false

-- Fetch helper.
local function fetch(name)
	local url = BASE_URL .. name
	local ok, src = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok or not src or src == "" then
		return nil, "Failed to fetch: " .. name
	end
	local fn, err = loadstring(src, "@RajaHub/" .. name)
	if not fn then
		return nil, "Compile error (" .. name .. "): " .. tostring(err)
	end
	local ok2, err2 = pcall(fn)
	if not ok2 then
		return nil, "Runtime error (" .. name .. "): " .. tostring(err2)
	end
	return true
end

-- Load order.
local MODULES = {
	"Core.lua",
	"UI.lua",
	"Sell.lua",
	"Farm.lua",
	"Mod.lua",
}

for _, name in ipairs(MODULES) do
	local ok, err = fetch(name)
	if not ok then
		warn("[RajaHub] " .. tostring(err))
		return
	end
end

shared.RajaHub._loaded = true

-- Log entry (kalau Core udah siap).
if shared.RajaHub.log then
	shared.RajaHub.log("👑 Raja Hub loaded successfully.")
end
