if SERVER then return end

hook.Remove("Think", "updatecache")
hook.Remove("CreateMove", "autobhopandfreecam")
hook.Remove("PlayerBindPress", "freecamblockkeys")
hook.Remove("PostDrawOpaqueRenderables", "drawentityboxes")
hook.Remove("PostDrawTranslucentRenderables", "drawcursorlines")
hook.Remove("HUDPaint", "drawinfo")
hook.Remove("CalcView", "noshake")

concommand.Remove("open_utility_menu")
concommand.Remove("toggle_freecam")

globalvalues = globalvalues or {
	scriptran = false, freecamtoggle = false, freecampos = Vector(0, 0, 0), freecamang = Angle(0, 0, 0),
	frozenplayerviewang = Angle(0, 0, 0), lastupdate = 0
}

entitycaches = entitycaches or {players = {}, npcs = {}, props = {}}

settings = settings or {}

if not globalvalues.scriptran then
	globalvalues.scriptran = true
	print("\nRun 'open_utility_menu' to open the menu!\n")
end

acts = acts or {
	"agree", "becon", "bow", "cheer", "dance", "disagree", "forward", "group",
	"halt", "laugh", "muscle", "pers", "robot", "salute", "wave", "zombie"
}

colors = colors or {
	white = Color(255, 255, 255), cyan = Color(0, 255, 255), red = Color(255, 0, 0), yellow = Color(255, 255, 0),
	green = Color(0, 255, 0), black = Color(0, 0, 0), purple = Color(180, 0, 180)
}

local function updatecache()
	for _, t in pairs(entitycaches) do
		table.Empty(t)
	end
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

hook.Add("Think", "updatecache", function()
	if CurTime() - globalvalues.lastupdate > 0.1 then
		updatecache()
		globalvalues.lastupdate = CurTime()
	end
end)

hook.Add("CreateMove", "autobhopandfreecam", function(cmd)
	local ply = LocalPlayer()
	local wishmove = Vector()
	local basespeed = math.Clamp(cookie.GetNumber("basespeed", 3), 1, 50)
	if settings.autobhop or settings.freecam then
		if settings.autobhop and cmd:KeyDown(IN_JUMP) and not ply:IsOnGround() and ply:WaterLevel() <= 1 and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
			cmd:RemoveKey(IN_JUMP)
		elseif settings.freecam and globalvalues.freecamtoggle and not vgui.GetKeyboardFocus() and not gui.IsGameUIVisible() then
			globalvalues.freecamang.p = math.Clamp(globalvalues.freecamang.p + cmd:GetMouseY() * GetConVar("m_pitch"):GetFloat(), -89, 89)
			globalvalues.freecamang.y = globalvalues.freecamang.y - cmd:GetMouseX() * GetConVar("m_yaw"):GetFloat()
			if input.IsKeyDown(KEY_W) then wishmove = wishmove + globalvalues.freecamang:Forward() end
			if input.IsKeyDown(KEY_S) then wishmove = wishmove - globalvalues.freecamang:Forward() end
			if input.IsKeyDown(KEY_D) then wishmove = wishmove + globalvalues.freecamang:Right() end
			if input.IsKeyDown(KEY_A) then wishmove = wishmove - globalvalues.freecamang:Right() end
			if input.IsKeyDown(KEY_SPACE) then wishmove = wishmove + globalvalues.freecamang:Up() end
			if input.IsKeyDown(KEY_LCONTROL) then wishmove = wishmove - globalvalues.freecamang:Up()end
			if wishmove:LengthSqr() > 0 then
				wishmove:Normalize()
				globalvalues.freecampos = globalvalues.freecampos + wishmove * (input.IsKeyDown(KEY_LSHIFT) and basespeed * 10 or basespeed)
			end
			cmd:SetViewAngles(globalvalues.frozenplayerviewang)
			hook.Add("PlayerBindPress", "freecamblockkeys", function(ply, bind, pressed)
				if string.find(bind, "toggle_freecam") or string.find(bind, "messagemode") or string.find(bind, "+showscores") or string.find(bind, "open_utility_menu") then
					return false
				end
				return true
			end)
		end
	end
	if not settings.freecam and globalvalues.freecamtoggle then
		globalvalues.freecamtoggle = false
		hook.Remove("CalcView", "freecamview")
		hook.Remove("PlayerBindPress", "freecamblockkeys")
	end
end)

hook.Add("PostDrawOpaqueRenderables", "drawentityboxes", function()
	local ply = LocalPlayer()
	if settings.propbox or settings.npcbox or settings.playerbox then
		if settings.propbox then
			for _, ent in ipairs(entitycaches.props or {}) do
				if IsValid(ent) then
					render.DrawWireframeBox(ent:GetPos(), ent:GetAngles(), ent:OBBMins(), ent:OBBMaxs(), colors.cyan, false)
				end
			end
		end
		if settings.npcbox then
			for _, ent in ipairs(entitycaches.npcs or {}) do
				if IsValid(ent) and ent:Alive() then
					render.DrawWireframeBox(ent:GetPos(), Angle(0, 0, 0), ent:OBBMins(), ent:OBBMaxs(), colors.white, false)
				end
			end
		end
		if settings.playerbox then
			for _, ent in ipairs(entitycaches.players or {}) do
				if IsValid(ent) and ent:Alive() then
					render.DrawWireframeBox(ent:GetPos(), Angle(0, 0, 0), ent:OBBMins(), ent:OBBMaxs(), colors.white, false)
				end
			end
		end
	end
end)

hook.Add("PostDrawTranslucentRenderables", "drawcursorlines", function()
	local ply = LocalPlayer()
	local startpos = ply:EyePos() + ply:GetAimVector() * 50
	if settings.npcline or settings.playerline then
		if ply:Alive() and not ply:ShouldDrawLocalPlayer() then
			if settings.npcline then
				for _, ent in ipairs(entitycaches.npcs or {}) do
					if IsValid(ent) and ent:Alive() then
						local endpos = ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z * 0.75)
						render.DrawLine(startpos, endpos, colors.white, false)
					end
				end
			end
			if settings.playerline then
				for _, ent in ipairs(entitycaches.players or {}) do
					if IsValid(ent) and ent:Alive() then
						local endpos = ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z * 0.75)
						render.DrawLine(startpos, endpos, colors.white, false)
					end
				end
			end
		end
	end
end)

hook.Add("HUDPaint", "drawinfo", function()
	local ply = LocalPlayer()
	local sw = ScrW()
	local sh = ScrH()
	if settings.clientinfo or settings.npcinfo or settings.playerinfo or settings.minimap then
		if settings.clientinfo and ply:Alive() then
			local fps = math.floor(1 / FrameTime())
			draw.SimpleText("Speed:" .. math.Round(ply:GetVelocity():Length()) .. "u/s", "BudgetLabel", sw / 2, sh / 2 + 75, colors.white, TEXT_ALIGN_CENTER)
			draw.SimpleText("FPS:" .. fps, "BudgetLabel", sw / 2, sh / 2 + 87, Color(255 - math.min(fps / 60, 1) * 255, math.min(fps / 60, 1) * 255, 0), TEXT_ALIGN_CENTER)
		end
		if settings.npcinfo then
			for _, ent in ipairs(entitycaches.npcs or {}) do
				if IsValid(ent) and ent:Alive() then
					local pos = ent:LocalToWorld(Vector(0, 0, ent:OBBMaxs().z)):ToScreen()
					local hp = ent:Health()
					draw.SimpleText(ent:GetClass(), "BudgetLabel", pos.x, pos.y - 12, colors.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
					draw.SimpleText("HP:" .. hp, "BudgetLabel", pos.x, pos.y, Color(255 - (hp * 2.55), hp * 2.55, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				end
			end
		end
		if settings.playerinfo then
			for _, ent in ipairs(entitycaches.players or {}) do
				if IsValid(ent) and ent:Alive() then
					local pos = ent:LocalToWorld(Vector(0, 0, ent:OBBMaxs().z)):ToScreen()
					local hp = ent:Health()
					local text = "HP:" .. hp
					if ent:Armor() > 0 then text = text .. "|AP:" .. ent:Armor() end
					draw.SimpleText(ent:Nick(), "BudgetLabel", pos.x, pos.y - 12, colors.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
					draw.SimpleText(text, "BudgetLabel", pos.x, pos.y, Color(255 - (hp * 2.55), hp * 2.55, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				end
			end
		end
		if settings.minimap then
			local size  = ({150, 200, 250, 300, 400})[math.Clamp(cookie.GetNumber("mapsize", 1), 1, 5)]
			local scale = ({25, 50, 75, 100, 125})[math.Clamp(cookie.GetNumber("mapscale", 1), 1, 5)]
			local posindex = math.Clamp(cookie.GetNumber("mappos", 1), 1, 4)
			local radius = size / 2
			local cx, cy = (function(corners, i) return corners[i].x, corners[i].y end)({
				{x = 16 + radius, y = 16 + radius}, {x = sw - 16 - radius, y = 16 + radius},
				{x = 16 + radius, y = sh - 16 - radius}, {x = sw - 16 - radius, y = sh - 16 - radius}
			}, posindex)
			local yaw = EyeAngles().y
			local function worldtomini(pos, yaw, scale, radius)
				local delta = pos - EyePos()
				local angle = math.rad(-yaw - 90)
				local x = -(delta.x * math.cos(angle) - delta.y * math.sin(angle))
				local y =  delta.x * math.sin(angle) + delta.y * math.cos(angle)
				x = x / scale
				y = y / scale
				x = math.Clamp(x, -radius, radius)
				y = math.Clamp(y, -radius, radius)
				return x, y
			end
			surface.SetDrawColor(0, 0, 0, 225)
			surface.DrawRect(cx - radius, cy - radius, radius * 2, radius * 2)
			for _, ent in ipairs(entitycaches.npcs or {}) do
				if IsValid(ent) and ent:Alive() then
					local sx, sy = worldtomini(ent:GetPos(), yaw, scale, radius)
					surface.SetDrawColor(255, 0, 0)
					surface.DrawRect(cx + sx - 2, cy + sy - 2, 4, 4)
				end
			end
			for _, ent in ipairs(entitycaches.players or {}) do
				if IsValid(ent) and ent ~= ply and ent:Alive() then
					local sx, sy = worldtomini(ent:GetPos(), yaw, scale, radius)
					surface.SetDrawColor(255, 255, 255)
					surface.DrawRect(cx + sx - 2, cy + sy - 2, 4, 4)
					draw.SimpleText(ent:Nick(), "BudgetLabel", cx + sx, cy + sy, colors.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				end
			end
			surface.SetDrawColor(0, 255, 0)
			surface.DrawLine(cx, cy - 4, cx - 4, cy + 4)
			surface.DrawLine(cx, cy - 4, cx + 4, cy + 4)
			surface.DrawLine(cx - 4, cy + 4, cx + 4, cy + 4)
		end
	end
end)

hook.Add("CalcView", "noshake", function(ply, pos, angles, fov)
	local noshakefov = math.Clamp(cookie.GetNumber("noshakefov", 120), 80, 170)
	local angs = ply:EyeAngles()
	if settings.noshake and not ply:ShouldDrawLocalPlayer() and not ply:InVehicle() and not globalvalues.freecamtoggle then
		angs.r = 0
		return {origin = pos, angles = angs, fov = noshakefov}
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

local function createbuttongrid(list, onClick, parent)
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

function createslider(label, min, max, key, parent)
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
		local roundedVal = math.Round(val)
		slider:SetValue(roundedVal)
		cookie.Set(key, roundedVal)
	end
	return slider
end

local function createmenu()
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
	createcheckbox("Auto bhop", "autobhop",  scrollutility)
	createcheckbox("Toggle freecam", "freecam", scrollutility)
	createcheckbox("Toggle no shake", "noshake", scrollutility)
	createlabel("Player gestures:", scrollutility)
	createbuttongrid(acts, function(act) RunConsoleCommand("act", act) end, scrollutility)
	createlabel("Miscellaneous options:", scrolldisplay)
	createcheckbox("Draw client info", "clientinfo",  scrolldisplay)
	createcheckbox("Show minimap", "minimap", scrolldisplay)
	createcheckbox("Draw prop boxes", "propbox", scrolldisplay)
	createlabel("NPC options:", scrolldisplay)
	createcheckbox("Draw NPC boxes", "npcbox", scrolldisplay)
	createcheckbox("Draw NPC lines", "npcline", scrolldisplay)
	createcheckbox("Draw NPC info", "npcinfo", scrolldisplay)
	createlabel("Player Options:", scrolldisplay)
	createcheckbox("Draw player boxes", "playerbox", scrolldisplay)
	createcheckbox("Draw player lines", "playerline", scrolldisplay)
	createcheckbox("Draw player info", "playerinfo", scrolldisplay)
	createlabel("Free cam:", scrollsettings)
	createslider("Speed:", 1, 50, "basespeed", scrollsettings)
	createlabel("No shake:", scrollsettings)
	createslider("FOV", 80, 170, "noshakefov", scrollsettings)
	createlabel("Map settings:", scrollsettings)
	createslider("Size:", 1, 5, "mapsize", scrollsettings)
	createslider("Scale:", 1, 5, "mapscale", scrollsettings)
	createslider("Pos:", 1, 4, "mappos", scrollsettings)
	return frame
end

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

concommand.Add("toggle_freecam", function()
	if settings.freecam then
		if globalvalues.freecamtoggle then
			globalvalues.freecamtoggle = false
			hook.Remove("CalcView", "freecamview")
			hook.Remove("PlayerBindPress", "freecamblockkeys")
		else
			globalvalues.freecamtoggle = true
			globalvalues.freecampos = LocalPlayer():EyePos()
			globalvalues.freecamang = LocalPlayer():EyeAngles()
			globalvalues.frozenplayerviewang = LocalPlayer():EyeAngles()
			hook.Add("CalcView", "freecamview", function(_ , _, _, fov)
				return {origin = globalvalues.freecampos, angles = globalvalues.freecamang, fov = fov, drawviewer = true}
			end)
		end
	end
end)