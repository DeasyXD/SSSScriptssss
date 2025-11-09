-- Config
local PlaceID = tostring(game.PlaceId)
local RECENT_FILE = "NotSameServers.json"
local MAX_RECENT = 5             -- เก็บล่าสุดกี่เซิร์ฟ
local MAX_PAGES = 5              -- ดึงกี่หน้าก่อนยอมแพ้
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

-- load recent list (as strings)
local recent = {}
local ok, data = pcall(function()
    return readfile(RECENT_FILE)
end)
if ok and data then
    local suc, decoded = pcall(function() return HttpService:JSONDecode(data) end)
    if suc and type(decoded) == "table" then
        for _, v in ipairs(decoded) do
            table.insert(recent, tostring(v))
        end
    end
end

-- ensure recent is a table
if type(recent) ~= "table" then recent = {} end

-- helper: check in recent
local function isRecent(id)
    id = tostring(id)
    for _, v in ipairs(recent) do
        if tostring(v) == id then return true end
    end
    return false
end

-- helper: push into recent (rolling)
local function pushRecent(id)
    id = tostring(id)
    table.insert(recent, 1, id) -- insert front
    -- trim
    while #recent > MAX_RECENT do
        table.remove(recent)
    end
    -- save
    pcall(function()
        writefile(RECENT_FILE, HttpService:JSONEncode(recent))
    end)
end

-- main: find candidate servers not in recent and with space
local function findCandidateServer()
    local cursor = nil
    local pages = 0
    local candidates = {}

    while pages < MAX_PAGES do
        pages = pages + 1
        local url = "https://games.roblox.com/v1/games/" .. PlaceID .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor then
            url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
        end

        local ok, res = pcall(function() return game:HttpGet(url) end)
        if not ok or not res then
            break
        end

        local suc, tbl = pcall(function() return HttpService:JSONDecode(res) end)
        if not suc or type(tbl) ~= "table" or type(tbl.data) ~= "table" then
            break
        end

        -- iterate servers
        for _, v in ipairs(tbl.data) do
            if type(v) == "table" then
                local id = tostring(v.id)
                local playing = tonumber(v.playing) or 0
                local maxP = tonumber(v.maxPlayers) or 0
                -- available and not in recent and not current server
                if maxP > playing and (not isRecent(id)) and id ~= tostring(game.JobId) then
                    table.insert(candidates, id)
                end
            end
        end

        -- if we found candidates, stop early
        if #candidates > 0 then break end

        -- move to next page if exists
        if tbl.nextPageCursor and tbl.nextPageCursor ~= "" and tbl.nextPageCursor ~= "null" then
            cursor = tbl.nextPageCursor
        else
            break
        end
    end

    -- if no candidates found, as fallback take any server (not current) from the last page scanned
    if #candidates == 0 then
        -- try to take any server from last fetched page that isn't recent or current (relaxed: ignore recent)
        -- make a fresh try: get page 1
        local ok2, res2 = pcall(function()
            return game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceID .. "/servers/Public?sortOrder=Asc&limit=100")
        end)
        if ok2 and res2 then
            local suc2, tbl2 = pcall(function() return HttpService:JSONDecode(res2) end)
            if suc2 and type(tbl2) == "table" and type(tbl2.data) == "table" then
                for _, v in ipairs(tbl2.data) do
                    local id = tostring(v.id)
                    local playing = tonumber(v.playing) or 0
                    local maxP = tonumber(v.maxPlayers) or 0
                    if maxP > playing and id ~= tostring(game.JobId) then
                        table.insert(candidates, id)
                    end
                end
            end
        end
    end

    -- return random candidate or nil
    if #candidates > 0 then
        math.randomseed(tick() + os.time())
        return candidates[math.random(1, #candidates)]
    end
    return nil
end

-- Teleport logic (single attempt)
local function tryTeleportToNewServer()
    local serverId = findCandidateServer()
    if not serverId then
        warn("ไม่พบเซิร์ฟเวอร์ที่เหมาะสม (หรือ error เยอะ) ยกเลิกการเทเลพอร์ตครั้งนี้")
        return false
    end

    -- register it to recent first (so re-run won't pick same immediately)
    pushRecent(serverId)

    -- attempt teleport
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(tonumber(PlaceID), serverId, Players.LocalPlayer)
    end)
    if not ok then
        warn("Teleport failed:", err)
        return false
    end
    return true
end

-- Example usage: loop trying every X seconds until teleport success
spawn(function()
    while task.wait(2) do
        local success = pcall(tryTeleportToNewServer)
        if success then
            break
        end
        -- wait a bit before retrying to avoid hammering API
        task.wait(3)
    end
end)
