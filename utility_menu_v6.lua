if SERVER then return end

hook.Remove("Think", "updatecache")
hook.Remove("CreateMove", "autobhopandfreecam")
hook.Remove("PlayerBindPress", "freecamblockkeys")
hook.Remove("PostDrawOpaqueRenderables", "drawentityboxes")
hook.Remove("PostDrawTranslucentRenderables", "drawcursorlines")
hook.Remove("HUDPaint", "drawinfo")
hook.Remove("HUDPaint", "eyeangleupdater")
hook.Remove("CalcView", "fixedcamera")
hook.Remove("Think", "flashlightspam")
concommand.Remove("open_utility_menu")
concommand.Remove("toggle_freecam")

globalvalues = globalvalues or {
	scriptran = false, freecamtoggle = false, freecampos = Vector(0, 0, 0), freecamang = Angle(0, 0, 0), frozenplayerviewang = Angle(0, 0, 0), lastupdate = 0
}

entitycaches = entitycaches or {players = {}, npcs = {}, props = {}}

acts = acts or {
	"agree", "becon", "bow", "cheer", "dance", "disagree", "forward", "group", "halt", "laugh", "muscle", "pers", "robot", "salute", "wave", "zombie"
}

colors = colors or {
	white = Color(255, 255, 255), cyan = Color(0, 255, 255), yellow = Color(255, 255, 0), green = Color(0, 255, 0), black = Color(0, 0, 0), purple = Color(180, 0, 180),
	red = Color(255, 0, 0), green = Color(0, 255, 0), blue = Color(0, 0, 255)
}

entitycolors = entitycolors or {prop = colors.blue, npc = colors.white, player = colors.white}

settings = settings or {}

if not globalvalues.scriptran then
	globalvalues.scriptran = true
	print("\nRun 'open_utility_menu' to open the menu!\n")
end

local function updatecache()
	for _, t in pairs(entitycaches) do table.Empty(t) end
	for _, ent in ipairs(ents.GetAll()) do
		if ent:GetClass():lower():find("prop_") then
			table.insert(entitycaches.props, ent)
		elseif ent:IsNPC() then
			table.insert(entitycaches.npcs, ent)
		elseif ent:IsPlayer() and ent ~= LocalPlayer() then
			table.insert(entitycaches.players, ent)
		end
	end
end

local function minimap(pos, yaw, scale, radius)
	local delta, angle = pos - EyePos(), math.rad(-yaw - 90)
	local x, y = -(delta.x * math.cos(angle) - delta.y * math.sin(angle)), delta.x * math.sin(angle) + delta.y * math.cos(angle)
	x, y = x / scale, y / scale
	x, y = math.Clamp(x, -radius, radius), math.Clamp(y, -radius, radius)
	return x, y
end

hook.Add("HUDPaint", "eyeangleupdater", function()
	local _ = EyeAngles()
end)

hook.Add("Think", "updatecache", function()
	if CurTime() - globalvalues.lastupdate > 0.1 then
		updatecache()
		globalvalues.lastupdate = CurTime()
	end
end)

hook.Add("CreateMove", "freecam", function(cmd)
	local wishmove, basespeed = Vector(), cookie.GetNumber("basespeed", 3)
	local freecam_sensitivity = 0.015
	local mousex, mousey = cmd:GetMouseX() * freecam_sensitivity, cmd:GetMouseY() * freecam_sensitivity
	local speed = input.IsKeyDown(KEY_LSHIFT) and basespeed * 10 or basespeed
	if not settings.freecam and globalvalues.freecamtoggle then
		globalvalues.freecamtoggle = false
		hook.Remove("CalcView", "freecamview")
		hook.Remove("PlayerBindPress", "freecamblockkeys")
	end
	if settings.freecam and globalvalues.freecamtoggle and not vgui.GetKeyboardFocus() and not gui.IsGameUIVisible() then
		globalvalues.freecamang.p = math.Clamp(globalvalues.freecamang.p + mousey, -89, 89)
		globalvalues.freecamang.y = globalvalues.freecamang.y - mousex
		cmd:SetViewAngles(globalvalues.frozenplayerviewang)
		if input.IsKeyDown(KEY_W) then wishmove = wishmove + globalvalues.freecamang:Forward() end
		if input.IsKeyDown(KEY_S) then wishmove = wishmove - globalvalues.freecamang:Forward() end
		if input.IsKeyDown(KEY_D) then wishmove = wishmove + globalvalues.freecamang:Right() end
		if input.IsKeyDown(KEY_A) then wishmove = wishmove - globalvalues.freecamang:Right() end
		if input.IsKeyDown(KEY_SPACE) then wishmove = wishmove + globalvalues.freecamang:Up() end
		if input.IsKeyDown(KEY_LCONTROL) then wishmove = wishmove - globalvalues.freecamang:Up() end
		if wishmove:LengthSqr() > 0 then
			wishmove:Normalize()
			globalvalues.freecampos = globalvalues.freecampos + wishmove * speed
		end
		hook.Add("PlayerBindPress", "freecamblockkeys", function(ply, bind, pressed)
			if string.find(bind, "toggle_freecam") or string.find(bind, "messagemode") or string.find(bind, "+showscores") or string.find(bind, "open_utility_menu") or string.find(bind, "kill") then
				return false
			end
			return true
		end)
	end
end)

hook.Add("CreateMove", "autobhop", function(cmd)
    local ply = LocalPlayer()
	if settings.autobhop and cmd:KeyDown(IN_JUMP) and not ply:IsOnGround() and ply:WaterLevel() <= 1 and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
		cmd:RemoveKey(IN_JUMP)
	end
end)

hook.Add("Think", "flashlightspam", function()
	if settings.flashlightspam and input.IsKeyDown(KEY_F) and not vgui.GetKeyboardFocus() and not gui.IsGameUIVisible() then
		RunConsoleCommand("impulse", "100")
	end
end)

hook.Add("PostDrawOpaqueRenderables", "drawentityboxes", function()
	if not (settings.propbox or settings.npcbox or settings.playerbox) then return end
	if settings.propbox then
		for _, ent in ipairs(entitycaches.props or {}) do
			if IsValid(ent) then
				render.DrawWireframeBox(ent:GetPos(), ent:GetAngles(), ent:OBBMins(), ent:OBBMaxs(), entitycolors.prop, false)
			end
		end
	end
	if settings.npcbox then
		for _, ent in ipairs(entitycaches.npcs or {}) do
			if IsValid(ent) and ent:Alive() then
				render.DrawWireframeBox(ent:GetPos(), Angle(0, 0, 0), ent:OBBMins(), ent:OBBMaxs(), entitycolors.npc, false)
			end
		end
	end
	if settings.playerbox then
		for _, ent in ipairs(entitycaches.players or {}) do
			if IsValid(ent) and ent:Alive() then
				render.DrawWireframeBox(ent:GetPos(), Angle(0, 0, 0), ent:OBBMins(), ent:OBBMaxs(), entitycolors.player, false)
			end
		end
	end
end)

hook.Add("PostDrawTranslucentRenderables", "drawcursorlines", function()
	local ply = LocalPlayer()
	if not (settings.npcline or settings.playerline) and not ply:Alive() and ply:ShouldDrawLocalPlayer() then return end
	local startpos = ply:EyePos() + ply:GetAimVector() * 50
	if settings.npcline then
		for _, ent in ipairs(entitycaches.npcs or {}) do
			if IsValid(ent) and ent:Alive() then
				local endpos = ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z * 0.75)
				render.DrawLine(startpos, endpos, entitycolors.npc, false)
			end
		end
	end
	if settings.playerline then
		for _, ent in ipairs(entitycaches.players or {}) do
			if IsValid(ent) and ent:Alive() then
				local endpos = ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z * 0.75)
				render.DrawLine(startpos, endpos, entitycolors.player, false)
			end
		end
	end
end)

hook.Add("HUDPaint", "drawinfo", function()
	local ply = LocalPlayer()
	local sw, sh = ScrW(), ScrH()
	local fps = math.floor(1 / FrameTime())
	local infodisplay = cookie.GetNumber("infodisplay", 1)
	if not (settings.clientinfo or settings.npcinfo or settings.playerinfo or settings.minimap) then return end
	if settings.clientinfo and ply:Alive() then
		if infodisplay == 3 then infodisplayoffset = 75 else infodisplayoffset = 87 end
		if infodisplay == 1 or infodisplay == 2 then
			draw.SimpleText("Speed:" .. math.Round(ply:GetVelocity():Length()) .. "u/s", "BudgetLabel", sw / 2, sh / 2 + 75, colors.white, TEXT_ALIGN_CENTER)
		end
		if infodisplay == 1 or infodisplay == 3 then
			draw.SimpleText("FPS:" .. fps, "BudgetLabel", sw / 2, sh / 2 + infodisplayoffset, Color(255 - math.min(fps / 60, 1) * 255, math.min(fps / 60, 1) * 255, 0), TEXT_ALIGN_CENTER)
		end
	end
	if settings.npcinfo then
		for _, ent in ipairs(entitycaches.npcs or {}) do
			if IsValid(ent) and ent:Alive() then
				local pos = ent:LocalToWorld(Vector(0, 0, ent:OBBMaxs().z)):ToScreen()
				local npchealthcolor = Color(255 - (ent:Health() / (ent:GetMaxHealth() or 100) * 255), (ent:Health() / (ent:GetMaxHealth() or 100)) * 255, 0)
				draw.SimpleText(ent:GetClass(), "BudgetLabel", pos.x, pos.y - 12, entitycolors.npc, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				draw.SimpleText("HP:" .. ent:Health(), "BudgetLabel", pos.x, pos.y, npchealthcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			end
		end
	end
	if settings.playerinfo then
		for _, ent in ipairs(entitycaches.players or {}) do
			if IsValid(ent) and ent:Alive() then
				local pos = ent:LocalToWorld(Vector(0, 0, ent:OBBMaxs().z)):ToScreen()
				local statustext = ""
				local playerhealthcolor = Color(255 - (ent:Health() / (ent:GetMaxHealth() or 100) * 255), (ent:Health() / (ent:GetMaxHealth() or 100)) * 255, 0)
				local text = "HP:" .. ent:Health()
				local playerinfodisplay = cookie.GetNumber("playerinfodisplay", 1)
				if ent:Armor() > 0 then text = text .. "|AP:" .. ent:Armor() end
				statustext = ent:VoiceVolume() > 0.01 and "*speaking*" or ent:IsTyping() and "*typing*" or ""
				statuscolor = ent:VoiceVolume() > 0.01 and colors.cyan or ent:IsTyping() and colors.yellow or entitycolors.player
				nametagcolor = playerinfodisplay == 2 and statuscolor or entitycolors.player
				playerinfodisplayoffset = playerinfodisplay == 3 and 0 or 12
				if playerinfodisplay == 1 then
					draw.SimpleText(statustext, "BudgetLabel", pos.x, pos.y - 24, statuscolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				end
				if playerinfodisplay == 1  or playerinfodisplay == 2 or playerinfodisplay == 3 or playerinfodisplay == 4 then
					draw.SimpleText(ent:Nick(), "BudgetLabel", pos.x, pos.y - playerinfodisplayoffset, nametagcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				end
				if playerinfodisplay == 1 or playerinfodisplay == 2 or playerinfodisplay == 3 then
					draw.SimpleText(text, "BudgetLabel", pos.x, pos.y, playerhealthcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				end
			end
		end
	end
	if settings.minimap then
		local sizevalues = {150, 200, 250, 300, 400}
		local scalevalues = {25, 50, 75, 100, 125}
		local size = sizevalues[cookie.GetNumber("mapsize", 1)]
		local scale = scalevalues[cookie.GetNumber("mapscale", 1)]
		local posindex = cookie.GetNumber("mappos", 1)
		local radius = size / 2
		local corners = {{x = 16 + radius, y = 16 + radius}, {x = sw - 16 - radius, y = 16 + radius}, {x = 16 + radius, y = sh - 16 - radius}, {x = sw - 16 - radius, y = sh - 16 - radius}}
		local cx, cy = corners[posindex].x, corners[posindex].y
		local yaw = EyeAngles().y
		surface.SetDrawColor(0, 0, 0, 225)
		surface.DrawRect(cx - radius, cy - radius, radius * 2, radius * 2)
		for _, ent in ipairs(entitycaches.npcs or {}) do
			if IsValid(ent) and ent:Alive() then
				local sx, sy = minimap(ent:GetPos(), yaw, scale, radius)
				surface.SetDrawColor(colors.red)
				surface.DrawRect(cx + sx - 2, cy + sy - 2, 4, 4)
			end
		end
		for _, ent in ipairs(entitycaches.players or {}) do
			if IsValid(ent) and ent ~= ply and ent:Alive() then
				local sx, sy = minimap(ent:GetPos(), yaw, scale, radius)
				surface.SetDrawColor(entitycolors.player)
				surface.DrawRect(cx + sx - 2, cy + sy - 2, 4, 4)
				draw.SimpleText(ent:Nick(), "BudgetLabel", cx + sx, cy + sy, entitycolors.player, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			end
		end
		surface.SetDrawColor(colors.green)
		surface.DrawLine(cx, cy - 4, cx - 4, cy + 4)
		surface.DrawLine(cx, cy - 4, cx + 4, cy + 4)
		surface.DrawLine(cx - 4, cy + 4, cx + 4, cy + 4)
	end
end)

hook.Add("CalcView", "fixedcamera", function(ply, pos, angles, fov)
	local playermeta = FindMetaTable("Player")
	if not (settings.noshake or settings.norecoil) then return end
	if settings.noshake then
		if not (globalvalues.freecamtoggle or ply:ShouldDrawLocalPlayer() or ply:InVehicle()) then
			angles.r = 0
			return {origin = pos, angles = angles, fov = cookie.GetNumber("noshakefov", 120)}
		end
	end
	if settings.norecoil then
		playermeta.seteyeangles = function(self, angle)
			if string.find(string.lower(debug.getinfo(2).short_src), "/weapons/") then return end
			self:_originalseteyeangles(angle)
		end
	else
		playermeta._originalseteyeangles = playermeta.seteyeangles
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

local function createcheckbox(text, key, parent)
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

local function createButtonGrid(list, onClick, parent)
	local grid = vgui.Create("DIconLayout", parent)
	grid:Dock(TOP)
	grid:SetSpaceX(5)
	grid:SetSpaceY(5)
	grid:CenterHorizontal()
	grid:DockMargin(9, 5, 0, 0)
	for _, item in ipairs(list) do
		local btn = grid:Add("DButton")
		btn:SetText(item:sub(1, 1):upper() .. item:sub(2):lower())
		btn:SetSize(60, 30)
		btn.DoClick = function() onClick(item) end
	end
	return grid
end

local function createSlider(label, min, max, key, parent)
	local slider = vgui.Create("DNumSlider", parent)
	slider:SetText(label)
	slider.Label:SetFont("DermaDefault")
	slider.Label:SetTextColor(colors.white)
	slider:Dock(TOP)
	slider:DockMargin(10, 5, 0, 0)
	slider:SetTall(15)
	slider:SetMin(min)
	slider:SetMax(max)
	slider:SetDecimals(0)
	local saved = cookie.GetNumber(key, min)
	slider:SetValue(saved)
	function slider:OnValueChanged(val)
		local roundval = math.Round(val)
		slider:SetValue(roundval)
		cookie.Set(key, roundval)
	end
	return slider
end

local function createMenu()
	local frame = vgui.Create("DFrame")
	local tab = vgui.Create("DPropertySheet", frame)
	local scrollutility = vgui.Create("DScrollPanel", tab)
	local scrolldisplay = vgui.Create("DScrollPanel", tab)
	local scrollsettings = vgui.Create("DScrollPanel", tab)
	frame:SetSize(300, 400)
	frame:Center()
	frame:SetTitle("Utility Menu V6")
	frame:SetDeleteOnClose(false)
	frame:SetVisible(false)
	tab:Dock(FILL)
	tab:SetFadeTime(0)
	tab:AddSheet("Utility", scrollutility, "icon16/wrench.png")
	tab:AddSheet("Display", scrolldisplay, "icon16/monitor.png")
	tab:AddSheet("Settings", scrollsettings, "icon16/cog.png")
	createlabel("Miscellaneous options:", scrollutility)
	createcheckbox("Toggle auto bhop", "autobhop", scrollutility)
	createcheckbox("Toggle flashlight spam", "flashlightspam", scrollutility)
	createcheckbox("Toggle freecam", "freecam", scrollutility)
	createcheckbox("Toggle no recoil", "norecoil", scrollutility)
	createlabel("Player gestures:", scrollutility)
	createButtonGrid(acts, function(act) RunConsoleCommand("act", act) end, scrollutility)
	createlabel("Miscellaneous options:", scrolldisplay)
	createcheckbox("Draw client info", "clientinfo", scrolldisplay)
	createcheckbox("Draw prop boxes", "propbox", scrolldisplay)
	createcheckbox("Show minimap", "minimap", scrolldisplay)
	createcheckbox("Toggle no shake", "noshake", scrolldisplay)
	createlabel("NPC options:", scrolldisplay)
	createcheckbox("Draw NPC boxes", "npcbox", scrolldisplay)
	createcheckbox("Draw NPC info", "npcinfo", scrolldisplay)
	createcheckbox("Draw NPC lines", "npcline", scrolldisplay)
	createlabel("Player Options:", scrolldisplay)
	createcheckbox("Draw player boxes", "playerbox", scrolldisplay)
	createcheckbox("Draw player info", "playerinfo", scrolldisplay)
	createcheckbox("Draw player lines", "playerline", scrolldisplay)
	createlabel("Freecam settings:", scrollsettings)
	createSlider("Speed:", 1, 50, "basespeed", scrollsettings)
	createlabel("Client info settings:", scrollsettings)
	createSlider("Info:", 1, 3, "infodisplay", scrollsettings)
	createlabel("Map settings:", scrollsettings)
	createSlider("Pos:", 1, 4, "mappos", scrollsettings)
	createSlider("Scale:", 1, 5, "mapscale", scrollsettings)
	createSlider("Size:", 1, 5, "mapsize", scrollsettings)
	createlabel("No shake:", scrollsettings)
	createSlider("FOV", 80, 170, "noshakefov", scrollsettings)
	createlabel("Player info settings:", scrollsettings)
	createSlider("Info:", 1, 4, "playerinfodisplay", scrollsettings)
	return frame
end

concommand.Add("open_utility_menu", function()
	if IsValid(utilitymenu) then
		utilitymenu:SetVisible(true)
		utilitymenu:MakePopup()
	else
		utilitymenu = createMenu()
		utilitymenu:SetVisible(true)
		utilitymenu:MakePopup()
	end
end)

concommand.Add("toggle_freecam", function()
	local ply = LocalPlayer()
	if not settings.freecam then return end
	if globalvalues.freecamtoggle then
		globalvalues.freecamtoggle = false
		hook.Remove("CalcView", "freecamview")
		hook.Remove("PlayerBindPress", "freecamblockkeys")
	else
		globalvalues.freecamtoggle = true
		globalvalues.freecampos = EyePos()
		globalvalues.freecamang = Angle(EyeAngles().p, EyeAngles().y, 0)
        globalvalues.frozenplayerviewang = ply:EyeAngles()
		hook.Add("CalcView", "freecamview", function(_, _, _, fov)
			return {origin = globalvalues.freecampos, angles = globalvalues.freecamang, fov = fov, drawviewer = true}
		end)
	end
end)