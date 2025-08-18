if SERVER then return end

local freecamtoggle = false
local freecampos = Vector(0, 0, 0)
local freecamang = Angle(0, 0, 0)
local frozenplayerviewang = Angle(0, 0, 0)
hook.Remove("CalcView", "FreecamView")
local lastUpdate = 0

if not settings then
	settings = {}
end

if not acts then
	acts = {
		"agree", "becon", "bow", "cheer", "dance", "disagree", "forward", "group",
		"halt", "laugh", "muscle", "pers", "robot", "salute", "wave", "zombie"
	}
end

if not colors then
	colors = {
		white = Color(255, 255, 255), cyan = Color(0, 255, 255),
		red = Color(255, 0, 0), yellow = Color(255, 255, 0)
	}
end

if not entitycache then
	entitycache = {players = {}, npcs = {}, props = {}}
end

local function updatecache()
	entitycache.players = {}
	entitycache.npcs = {}
	entitycache.props = {}
	local plypos = LocalPlayer():GetPos()
	for _, ent in ipairs(ents.GetAll()) do
		if IsValid(ent) then
			if ent:IsPlayer() and ent ~= LocalPlayer() then
				table.insert(entitycache.players, ent)
			elseif ent:IsNPC() then
				table.insert(entitycache.npcs, ent)
			elseif ent:GetClass():lower():find("prop_") then
				table.insert(entitycache.props, ent)
			end
		end
	end
end

hook.Add("Think", "updatecache", function()
	if CurTime() - lastupdate > 0.5 then
		updatecache()
		lastupdate = CurTime()
	end
end)

hook.Add("CreateMove", "autobhop and freecam", function(cmd)
	local ply = LocalPlayer()
	if settings.autobhop and cmd:KeyDown(IN_JUMP) and not ply:IsOnGround() and ply:WaterLevel() <= 1 and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
		cmd:RemoveKey(IN_JUMP)
	elseif settings.freecam and freecamtoggle and not vgui.GetKeyboardFocus() and not gui.IsGameUIVisible() then
		local mousex, mousey = cmd:GetMouseX(), cmd:GetMouseY()
		local speed = (input.IsKeyDown(KEY_LSHIFT) and 25 or 10)
		local wishmove = Vector()
		local pitchsens = GetConVar("m_pitch"):GetFloat()
		local yawsens = GetConVar("m_yaw"):GetFloat()
		freecamang.p = math.Clamp(freecamang.p + mousey * pitchsens, -89, 89)
		freecamang.y = freecamang.y - mousex * yawsens
		if input.IsKeyDown(KEY_W) then wishmove = wishmove + freecamang:Forward() end
		if input.IsKeyDown(KEY_S) then wishmove = wishmove - freecamang:Forward() end
		if input.IsKeyDown(KEY_D) then wishmove = wishmove + freecamang:Right() end
		if input.IsKeyDown(KEY_A) then wishmove = wishmove - freecamang:Right() end
		if input.IsKeyDown(KEY_SPACE) then wishmove = wishmove + freecamang:Up() end
		if input.IsKeyDown(KEY_LCONTROL) then wishmove = wishmove - freecamang:Up()end
		if wishmove:LengthSqr() > 0 then
			wishmove:Normalize()
			freecampos = freecampos + wishmove * speed
		end
		cmd:ClearButtons()
		cmd:ClearMovement()
		cmd:SetViewAngles(frozenplayerviewang)
	end
end)

hook.Add("PlayerBindPress", "freecamblockkeys", function(ply, bind, pressed)
	if freecamtoggle then
		if string.find(bind, "noclip") or string.find(bind, "impulse 100") or string.find(bind, "impulse 201") then
			return true
		end
	end
end)

hook.Add("PostDrawOpaqueRenderables", "drawentityboxes", function()
	local ply = LocalPlayer()
	if settings.propbox then
		for _, ent in ipairs(entitycache.props or {}) do
			if IsValid(ent) then
				render.DrawWireframeBox(ent:GetPos(), ent:GetAngles(), ent:OBBMins(), ent:OBBMaxs(), colors.cyan, false)
			end
		end
	end
	if settings.npcbox then
		for _, ent in ipairs(entitycache.npcs or {}) do
			if IsValid(ent) and ent:Alive() then
				render.DrawWireframeBox(ent:GetPos(), Angle(0, 0, 0), ent:OBBMins(), ent:OBBMaxs(), colors.red, false)
			end
		end
	end
	if settings.playerbox then
		for _, ent in ipairs(entitycache.players or {}) do
			if IsValid(ent) and ent:Alive() then
				render.DrawWireframeBox(ent:GetPos(), Angle(0, 0, 0), ent:OBBMins(), ent:OBBMaxs(), colors.yellow, false)
			end
		end
	end
end)

hook.Add("PostDrawTranslucentRenderables", "drawcursorlines", function()
	local ply = LocalPlayer()
	if not ply:Alive() or ply:ShouldDrawLocalPlayer() then return end
	local startpos = ply:EyePos() + ply:GetAimVector() * 50
	if settings.npcline then
		for _, ent in ipairs(entitycache.npcs or {}) do
			if IsValid(ent) and ent:Alive() then
				local endpos = ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z * 0.75)
				render.DrawLine(startpos, endpos, colors.red, false)
			end
		end
	end
	if settings.playerline then
		for _, ent in ipairs(entitycache.players or {}) do
			if IsValid(ent) and ent:Alive() then
				local endpos = ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z * 0.75)
				render.DrawLine(startpos, endpos, colors.yellow, false)
			end
		end
	end
end)

hook.Add("HUDPaint", "drawinfo", function()
	local ply = LocalPlayer()
	if settings.clientinfo and ply:Alive() then
		local sw, sh = ScrW(), ScrH()
		draw.SimpleText("Speed:" .. math.Round(ply:GetVelocity():Length()) .. "u/s", "BudgetLabel", sw / 2, sh / 2 + 75, colors.white, TEXT_ALIGN_CENTER)
		draw.SimpleText("FPS:" .. math.floor(1 / FrameTime()), "BudgetLabel", sw / 2, sh / 2 + 87, colors.white, TEXT_ALIGN_CENTER)
	end
	if settings.npcinfo then
		for _, ent in ipairs(entitycache.npcs or {}) do
			if IsValid(ent) and ent:Alive() then
				local pos = ent:EyePos():ToScreen()
				draw.SimpleText(ent:GetClass(), "BudgetLabel", pos.x, pos.y - 12, colors.red, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				draw.SimpleText("HP:" .. ent:Health(), "BudgetLabel", pos.x, pos.y, colors.red, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			end
		end
	end
	if settings.playerinfo then
		for _, ent in ipairs(entitycache.players or {}) do
			if IsValid(ent) and ent:Alive() then
				local pos = ent:EyePos():ToScreen()
				draw.SimpleText(ent:Nick(), "BudgetLabel", pos.x, pos.y - 12, colors.yellow, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				local text = "HP:" .. ent:Health()
				if ent:Armor() > 0 then text = text .. "|AP:" .. ent:Armor() end
				draw.SimpleText(text, "BudgetLabel", pos.x, pos.y, colors.yellow, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			end
		end
	end
	if settings.minimap then
		local function worldToMini(pos, yaw, scale, radius)
			local ply = LocalPlayer()
			local delta = pos - ply:GetPos()
			local angle = math.rad(-yaw - 90)
			local x = -(delta.x * math.cos(angle) - delta.y * math.sin(angle))
			local y = delta.x * math.sin(angle) + delta.y * math.cos(angle)
			x = x / scale
			y = y / scale
			local dist = math.sqrt(x * x + y * y)
			if dist > radius then
				local factor = radius / dist
				x = x * factor
				y = y * factor
			end
			return x, y
		end
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		local size, radius, scale = 220, 110, 32
		local cx, cy = size / 2 + 16, size / 2 + 16
		local yaw = ply:EyeAngles().y
		draw.NoTexture()
		surface.SetDrawColor(0, 0, 0, 220)
		local segments = 64
		local poly = {}
		for i = 0, segments do
			local a = (i / segments) * math.pi * 2
			table.insert(poly, {x = cx + math.cos(a) * radius, y = cy + math.sin(a) * radius})
		end
		surface.DrawPoly(poly)
		for _, ent in ipairs(entitycache.players or {}) do
			if IsValid(ent) and ent ~= ply and ent:Alive() then
				local sx, sy = worldToMini(ent:GetPos(), yaw, scale, radius)
				surface.SetDrawColor(255, 255, 0)
				surface.DrawRect(cx + sx - 2, cy + sy - 2, 4, 4)
				draw.SimpleText(ent:Nick(), "BudgetLabel", cx + sx, cy + sy - 5, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			end
		end
		for _, ent in ipairs(entitycache.npcs or {}) do
			if IsValid(ent) and ent:Alive() then
				local sx, sy = worldToMini(ent:GetPos(), yaw, scale, radius)
				surface.SetDrawColor(255, 0, 0)
				surface.DrawRect(cx + sx - 2, cy + sy - 2, 4, 4)
			end
		end
		local arrowSize = 4
		surface.SetDrawColor(120, 255, 120, 255)
		surface.DrawLine(cx, cy - arrowSize, cx - arrowSize, cy + arrowSize)
		surface.DrawLine(cx, cy - arrowSize, cx + arrowSize, cy + arrowSize)
	end
end)

local function createlabel(text, parent)
	local label = vgui.Create("DLabel", parent)
	label:SetText(text)
	label:SetFont("DermaDefaultBold")
	label:SetTextColor(colors.white)
	label:SizeToContents()
	label:Dock(TOP)
	label:DockMargin(5, 5, 0, 0)
	return label
end

local function createcheckbox(text, parent, key)
	local checkbox = vgui.Create("DCheckBoxLabel", parent)
	checkbox:SetText(text)
	checkbox:SetFont("DermaDefault")
	checkbox:SetTextColor(colors.white)
	checkbox:SetValue(settings[key] and true or false)
	checkbox:Dock(TOP)
	checkbox:SizeToContents()
	checkbox:DockMargin(10, 5, 0, 0)
	checkbox.OnChange = function(self, val) settings[key] = val and true or false end
	return checkbox
end

local function createButtonGrid(parent, list, onClick)
	local grid = vgui.Create("DIconLayout", parent)
	grid:Dock(TOP)
	grid:SetSpaceX(5)
	grid:SetSpaceY(5)
	grid:CenterHorizontal()
	grid:DockMargin(9, 5, 0, 0)
	for _, item in ipairs(list) do
		local btn = grid:Add("DButton")
		btn:SetText(item:sub(1,1):upper() .. item:sub(2):lower())
		btn:SetSize(60, 30)
		btn.DoClick = function() onClick(item) end
	end
	return grid
end

local function createmenu()
	local frame = vgui.Create("DFrame")
	local tab = vgui.Create("DPropertySheet", frame)
	local scrollutility = vgui.Create("DScrollPanel", tab)
	local scrolldisplay = vgui.Create("DScrollPanel", tab)
	frame:SetSize(300, 400)
	frame:Center()
	frame:SetTitle("Utility Menu V6")
	frame:SetDeleteOnClose(false)
	frame:SetVisible(false)
	tab:Dock(FILL)
	tab:SetFadeTime(0)
	tab:AddSheet("Utility", scrollutility, "icon16/wrench.png")
	tab:AddSheet("Display", scrolldisplay, "icon16/monitor.png")
	createlabel("Miscellaneous Options:", scrollutility)
	createcheckbox("Auto Bhop", scrollutility, "autobhop")
	createcheckbox("Toggle Freecam", scrollutility, "freecam")
	createcheckbox("Show Minimap", scrollutility, "minimap")
	createlabel("Player Gestures:", scrollutility)
	createButtonGrid(scrollutility, acts, function(act) RunConsoleCommand("act", act) end)
	createlabel("Miscellaneous Options:", scrolldisplay)
	createcheckbox("Draw Client Info", scrolldisplay, "clientinfo")
	createcheckbox("Draw Prop Boxes", scrolldisplay, "propbox")
	createlabel("NPC Options:", scrolldisplay)
	createcheckbox("Draw NPC Boxes", scrolldisplay, "npcbox")
	createcheckbox("Draw NPC Lines", scrolldisplay, "npcline")
	createcheckbox("Draw NPC Info", scrolldisplay, "npcinfo")
	createlabel("Player Options:", scrolldisplay)
	createcheckbox("Draw Player Boxes", scrolldisplay, "playerbox")
	createcheckbox("Draw Player Lines", scrolldisplay, "playerline")
	createcheckbox("Draw Player Info", scrolldisplay, "playerinfo")
	return frame
end

concommand.Remove("open_utility_menu")
concommand.Add("open_utility_menu", function()
	if IsValid(utilitymenu) then
		utilitymenu:SetVisible(true)
		utilitymenu:MakePopup()
	else
		utilitymenu = createmenu()
		utilitymenu:SetVisible(true)
		utilitymenu:MakePopup()
	end
end)

concommand.Remove("toggle_freecam")
concommand.Add("toggle_freecam", function()
	if settings.freecam then
		if freecamtoggle then
			freecamtoggle = false
			hook.Remove("CalcView", "FreecamView")
		else
			local ply = LocalPlayer()
			freecamtoggle = true
			freecampos, freecamang = ply:EyePos(), ply:EyeAngles()
			frozenplayerviewang = ply:EyeAngles()
			hook.Add("CalcView", "FreecamView", function(_,_,_,fov)
				return {origin = freecampos, angles = freecamang, fov = fov, drawviewer = true}
			end)
		end
	end
end)