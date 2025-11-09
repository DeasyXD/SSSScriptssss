-- Server Hopper: hop ไปเรื่อยๆ แบบสุ่ม (อนุญาตให้ซ้ำ)
-- ใช้ใน executor/สภาพแวดล้อมที่อนุญาต HttpGet (หรือใน Client ที่เปิดให้ใช้)
-- ปรับค่าได้: HOP_DELAY (วินาที) และ MAX_PAGES (ดึงกี่หน้า)

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local PlaceID = tostring(game.PlaceId)
local CurrentJobId = tostring(game.JobId)

-- config
_G.StopServerHopper = _G.StopServerHopper or false
local HOP_DELAY = 4        -- รอหลัง teleport ก่อนวนใหม่ (วินาที) (ลด/เพิ่มได้)
local PAGE_LIMIT = 3       -- จะดึงได้กี่หน้าก่อนยอมแพ้ (แต่ละหน้า up to 100 servers)
local API_BASE = "https://games.roblox.com/v1/games/"

local function fetchServerPage(cursor)
    local url = API_BASE .. PlaceID .. "/servers/Public?sortOrder=Asc&limit=100"
    if cursor and cursor ~= "" then
        url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
    end
    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok or not res then
        return nil
    end
    local suc, tbl = pcall(function() return HttpService:JSONDecode(res) end)
    if not suc or type(tbl) ~= "table" then
        return nil
    end
    return tbl
end

local function gatherAvailableServers()
    local servers = {}
    local cursor = nil
    local pages = 0

    while pages < PAGE_LIMIT do
        if _G.StopServerHopper then break end
        local tbl = fetchServerPage(cursor)
        if not tbl then break end

        -- เก็บเซิร์ฟที่มีที่ว่างและไม่ใช่เซิร์ฟปัจจุบัน
        if type(tbl.data) == "table" then
            for _, v in ipairs(tbl.data) do
                if type(v) == "table" then
                    local id = tostring(v.id)
                    local playing = tonumber(v.playing) or 0
                    local maxP = tonumber(v.maxPlayers) or 0
                    if maxP > playing and id ~= CurrentJobId then
                        table.insert(servers, id)
                    end
                end
            end
        end

        -- next page?
        if tbl.nextPageCursor and tbl.nextPageCursor ~= "" and tbl.nextPageCursor ~= "null" then
            cursor = tbl.nextPageCursor
            pages = pages + 1
        else
            break
        end
    end

    return servers
end

local function pickAndTeleport(servers)
    if not servers or #servers == 0 then
        return false, "no servers found"
    end
    math.randomseed(tick() + os.time())
    local pick = servers[math.random(1, #servers)]
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(tonumber(PlaceID), pick, Players.LocalPlayer)
    end)
    if ok then
        return true
    else
        return false, err
    end
end

-- main loop: จะทำงานไปเรื่อย ๆ จน _G.StopServerHopper = true
spawn(function()
    while not _G.StopServerHopper do
        -- ดึง candidate servers
        local servers = gatherAvailableServers()

        -- ถ้าไม่เจอ ให้รอแล้วลองใหม่ช้าๆ
        if #servers == 0 then
            warn("[Hopper] No servers found, retry after delay")
            task.wait(math.max(HOP_DELAY, 5))
        else
            local ok, err = pickAndTeleport(servers)
            if not ok then
                warn("[Hopper] Teleport failed:", err)
                -- รอแล้วลองต่อ
                task.wait(math.max(HOP_DELAY, 3))
            else
                -- ถ้า teleport สำเร็จ โปรเซสจะเปลี่ยนเซสชันไปแล้ว (รันโค้ดที่เหลืออาจไม่ทัน)
                -- แต่ถ้า teleport ไม่เกิด (เช่นพยายามแต่โดนบล็อก), เราจะรอแล้ววนต่อ
                task.wait(HOP_DELAY)
            end
        end
    end
    print("[Hopper] Stopped by _G.StopServerHopper flag")
end)
