-- FAST HOPPER: stable version with auto-retry
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game.Players

local PLACE_ID = game.PlaceId
local HOP_DELAY = 3
_G.StopFastHop = false

local function fastFetch()
    local url =
        "https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/Public?sortOrder=Desc&limit=100"

    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok then return nil end

    local ok2, data = pcall(function()
        return HttpService:JSONDecode(res)
    end)
    if not ok2 then return nil end

    return data.data
end

local function getFastServer()
    local list = fastFetch()

    -- ✅ ถ้า API คืนว่าง → รอแล้ว retry แทนที่จะล้ม
    if not list or #list == 0 then
        warn("[FAST HOPPER] Empty list, retrying...")
        task.wait(0.5)
        return nil
    end

    for _, v in ipairs(list) do
        if tonumber(v.playing) < tonumber(v.maxPlayers)
            and tostring(v.id) ~= tostring(game.JobId)
        then
            return v.id
        end
    end

    return nil
end

local function hopNow()
    local server = getFastServer()
    if server then
        print("[FAST HOPPER] Teleport:", server)
        pcall(function()
            TeleportService:TeleportToPlaceInstance(
                PLACE_ID, server, Players.LocalPlayer
            )
        end)
    else
        print("[FAST HOPPER] No server found this cycle. Retrying...")
    end
end

task.spawn(function()
    while not _G.StopFastHop do
        hopNow()
        task.wait(HOP_DELAY)
    end
end)

print("✅ STABLE FAST HOPPER ACTIVE")
