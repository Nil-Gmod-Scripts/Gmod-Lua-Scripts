if SERVER then return end

local center = Vector(0,0,0)
local npcCache, nextScan = {}, 0

-- Convert world pos -> minimap offset
local function worldToMini(vec, yaw, rotate, upp, radius)
    local dx, dy = -(vec.x - center.x) / upp, (vec.y - center.y) / upp
    if rotate then
        local rad = math.rad(yaw + 90)
        local c, s = math.cos(rad), math.sin(rad)
        dx, dy = dx * c - dy * s, dx * s + dy * c
    end
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist > radius - 4 then
        local scale = (radius - 4) / dist
        dx, dy = dx * scale, dy * scale
    end
    return dx, dy
end

-- Circle mask for HUD
local function drawCircleMask(x, y, r)
    render.ClearStencil()
    render.SetStencilEnable(true)
    render.SetStencilWriteMask(255)
    render.SetStencilTestMask(255)
    render.SetStencilReferenceValue(1)
    render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NEVER)
    render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
    render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
    render.SetStencilZFailOperation(STENCILOPERATION_REPLACE)

    cam.Start2D()
        draw.NoTexture()
        surface.SetDrawColor(0, 0, 0, 255)
        local seg = math.max(24, math.floor(r * 0.75))
        local poly = {}
        for i = 0, seg do
            local a = (i / seg) * math.pi * 2
            table.insert(poly, {x = x + math.cos(a) * r, y = y + math.sin(a) * r})
        end
        surface.DrawPoly(poly)
    cam.End2D()

    render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
end

local function endCircleMask() render.SetStencilEnable(false) end

-- NPC scan
local function scanNPCs()
    npcCache = {}
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent:IsNPC() then table.insert(npcCache, ent) end
    end
end

-- Get HUD position
local function getScreenAnchor(size, margin, corner)
    local sw, sh = ScrW(), ScrH()
    local x, y = margin + size/2, margin + size/2
    if corner == 1 then x = sw - margin - size/2
    elseif corner == 2 then y = sh - margin - size/2
    elseif corner == 3 then x = sw - margin - size/2; y = sh - margin - size/2 end
    return x, y
end

hook.Add("HUDPaint", "minimap_hud", function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end

    local size, radius, margin, alpha, rotate, upp, corner = 220, 110, 16, 220, true, 32, 0
    center = lp:GetPos()

    if CurTime() > nextScan then
        nextScan = CurTime() + 0.75
        scanNPCs()
    end

    local cx, cy = getScreenAnchor(size, margin, corner)
    drawCircleMask(cx, cy, radius)

    -- Background
    draw.NoTexture()
    surface.SetDrawColor(20, 20, 28, alpha)
    draw.RoundedBox(1024, cx - radius, cy - radius, size, size, Color(20,20,28,alpha))

    -- Faint cross grid
    surface.SetDrawColor(255, 255, 255, 16)
    surface.DrawLine(cx - radius, cy, cx + radius, cy)
    surface.DrawLine(cx, cy - radius, cx, cy + radius)

    local yaw = lp:EyeAngles().y

    -- Other players
    surface.SetDrawColor(0, 200, 255, 255)
    for _, ply in ipairs(player.GetAll()) do
        if ply ~= lp and ply:Alive() then
            local sx, sy = worldToMini(ply:GetPos(), yaw, rotate, upp, radius)
            surface.DrawRect(cx + sx - 2, cy + sy - 2, 4, 4)
            draw.SimpleTextOutlined(ply:Nick(), "DermaDefaultBold", cx + sx, cy + sy - 10,
                Color(255,255,255,220), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0,0,0,180))
        end
    end

    -- NPCs
    surface.SetDrawColor(255, 180, 0, 255)
    for _, ent in ipairs(npcCache) do
        if IsValid(ent) then
            local sx, sy = worldToMini(ent:GetPos(), yaw, rotate, upp, radius)
            surface.DrawRect(cx + sx - 2, cy + sy - 2, 4, 4)
        end
    end

    -- Player arrow
    local arrowSize = math.floor(math.max(10, size * 0.08))
    local rad, c, s = math.rad(rotate and 0 or -yaw), 0, 0
    c, s = math.cos(rad), math.sin(rad)
    local function rot(dx, dy) return cx + (dx * c - dy * s), cy + (dx * s + dy * c) end
    surface.SetDrawColor(120, 255, 120, 255)
    draw.NoTexture()
    surface.DrawPoly({rot(0, -arrowSize), rot(-arrowSize*0.6, arrowSize*0.8), rot(arrowSize*0.6, arrowSize*0.8)})

    endCircleMask()
end)
