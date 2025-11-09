-- FAST HOPPER: ultra-minimal, ultra-fast, no history, no page-loop
-- Hop ASAP ไปเรื่อยๆ (ซ้ำเซิร์ฟได้) โดยใช้ API หน้าเดียวที่เร็วที่สุด

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game.Players

local PLACE_ID = game.PlaceId
local HOP_DELAY = 2         -- ปรับเวลาหน่วงระหว่าง hop
_G.StopFastHop = false       -- ถ้าอยากหยุด: _G.StopFastHop = true

local function fastFetch()
    -- เราใช้จุดนี้เพียงครั้งเดียวต่อหนึ่ง hop
    local url = "https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/Public?sortOrder=Desc&limit=100"

    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok then return nil end

    local ok2, data = pcall(function()
        return HttpService:JSONDecode(res)
    end)
    if not ok2 or type(data) ~= "table" then return nil end

    return data.data
end

local function getFastServer()
    local list = fastFetch()
    if not list then return nil end

    for _, v in ipairs(list) do
        if tonumber(v.playing) < tonumber(v.maxPlayers) and tostring(v.id) ~= tostring(game.JobId) then
            return v.id   -- หยิบตัวแรกที่ว่าง แล้วจบ ไม่ต้องวนหนัก
        end
    end

    return nil
end

local function hopNow()
    local server = getFastServer()
    if server then
        print("[FAST HOPPER] Teleporting to:", server)
        pcall(function()
            TeleportService:TeleportToPlaceInstance(PLACE_ID, server, Players.LocalPlayer)
        end)
    else
        warn("[FAST HOPPER] No server found this cycle")
    end
end

task.spawn(function()
    while not _G.StopFastHop do
        hopNow()
        task.wait(HOP_DELAY)
    end
end)

print("✅ FAST HOPPER ENABLED (Stop with: _G.StopFastHop = true)")
