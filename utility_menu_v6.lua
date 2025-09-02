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

globalvalues = globalvalues or {scriptran = false, freecamtoggle = false, freecampos = Vector(0, 0, 0), freecamang = Angle(0, 0, 0), frozenplayerviewang = Angle(0, 0, 0), lastupdate = 0}

entitycaches = entitycaches or {players = {}, npcs = {}, props = {}}

local acts = {"agree", "becon", "bow", "cheer", "dance", "disagree", "forward", "group", "halt", "laugh", "muscle", "pers", "robot", "salute", "wave", "zombie"}

local colors = {white = Color(255, 255, 255), cyan = Color(0, 255, 255), red = Color(255, 0, 0), yellow = Color(255, 255, 0), green = Color(0, 255, 0), black = Color(0, 0, 0), purple = Color(180, 0, 180)}

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

hook.Add("Think", "updatecache", function()
	if CurTime() - globalvalues.lastupdate > 0.1 then
		updatecache()
		globalvalues.lastupdate = CurTime()
	end
end)

hook.Add("CreateMove", "autobhopandfreecam", function(cmd)
	local ply = LocalPlayer()
	local wishmove, basespeed = Vector(), math.Clamp(cookie.GetNumber("basespeed", 3), 1, 50)
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
			if input.IsKeyDown(KEY_LCONTROL) then wishmove = wishmove - globalvalues.freecamang:Up() end
			if wishmove:LengthSqr() > 0 then
				wishmove:Normalize()
				local speed = input.IsKeyDown(KEY_LSHIFT) and basespeed * 10 or basespeed
				globalvalues.freecampos = globalvalues.freecampos + wishmove * speed
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
	if (settings.npcline or settings.playerline) and ply:Alive() and not ply:ShouldDrawLocalPlayer() then
		local startpos = ply:EyePos() + ply:GetAimVector() * 50
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
end)

hook.Add("HUDPaint", "drawinfo", function()
	local ply = LocalPlayer()
	local sw, sh = ScrW(), ScrH()
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
					local hp, maxhp = ent:Health(), ent:GetMaxHealth()
					draw.SimpleText(ent:GetClass(), "BudgetLabel", pos.x, pos.y - 12, colors.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
					draw.SimpleText("HP:" .. hp, "BudgetLabel", pos.x, pos.y, Color(255 - (hp / (maxhp or 100) * 255), (hp / (maxhp or 100)) * 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				end
			end
		end
		if settings.playerinfo then
			for _, ent in ipairs(entitycaches.players or {}) do
				if IsValid(ent) and ent:Alive() then
					local pos = ent:LocalToWorld(Vector(0, 0, ent:OBBMaxs().z)):ToScreen()
					local hp, text = ent:Health(), "HP:" .. hp
					if ent:Armor() > 0 then text = text .. "|AP:" .. ent:Armor() end
					draw.SimpleText(ent:Nick(), "BudgetLabel", pos.x, pos.y - 12, colors.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
					draw.SimpleText(text, "BudgetLabel", pos.x, pos.y, Color(255 - (hp / (ent:GetMaxHealth() or 100) * 255), (hp / (ent:GetMaxHealth() or 100)) * 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				end
			end
		end
		if settings.minimap then
			local sizeValues = {150, 200, 250, 300, 400}
			local scaleValues = {25, 50, 75, 100, 125}
			local size = sizeValues[math.Clamp(cookie.GetNumber("mapsize", 1), 1, 5)]
			local scale = scaleValues[math.Clamp(cookie.GetNumber("mapscale", 1), 1, 5)]
			local posIndex = math.Clamp(cookie.GetNumber("mappos", 1), 1, 4)
			local radius = size / 2
			local corners = {{x = 16 + radius, y = 16 + radius}, {x = sw - 16 - radius, y = 16 + radius}, {x = 16 + radius, y = sh - 16 - radius}, {x = sw - 16 - radius, y = sh - 16 - radius}}
			local cx, cy = corners[posIndex].x, corners[posIndex].y
			local yaw = EyeAngles().y
			surface.SetDrawColor(0, 0, 0, 225)
			surface.DrawRect(cx - radius, cy - radius, radius * 2, radius * 2)
			for _, ent in ipairs(entitycaches.npcs or {}) do
				if IsValid(ent) and ent:Alive() then
					local sx, sy = minimap(ent:GetPos(), yaw, scale, radius)
					surface.SetDrawColor(255, 0, 0)
					surface.DrawRect(cx + sx - 2, cy + sy - 2, 4, 4)
				end
			end
			for _, ent in ipairs(entitycaches.players or {}) do
				if IsValid(ent) and ent ~= ply and ent:Alive() then
					local sx, sy = minimap(ent:GetPos(), yaw, scale, radius)
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
	if settings.noshake and not ply:ShouldDrawLocalPlayer() and not ply:InVehicle() then
		local noshakefov, angs = math.Clamp(cookie.GetNumber("noshakefov", 120), 80, 170), ply:EyeAngles()
		angs.r = 0
		return {origin = pos, angles = angs, fov = noshakefov}
	end
end)

local function createLabel(text, parent)
	local label = vgui.Create("DLabel", parent)
	label:SetText(text)
	label:SetFont("DermaDefaultBold")
	label:SetTextColor(colors.white)
	label:SizeToContents()
	label:Dock(TOP)
	label:DockMargin(5, 5, 0, 0)
	return label
end

local function createCheckbox(text, key, parent)
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
		btn:SetText(item:sub(1,1):upper() .. item:sub(2):lower())
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
		local roundedVal = math.Round(val)
		slider:SetValue(roundedVal)
		cookie.Set(key, roundedVal)
	end
	return slider
end

local function createMenu()
	local frame = vgui.Create("DFrame")
	local tab = vgui.Create("DPropertySheet", frame)
	local scrollUtility = vgui.Create("DScrollPanel", tab)
	local scrollDisplay = vgui.Create("DScrollPanel", tab)
	local scrollSettings = vgui.Create("DScrollPanel", tab)
	frame:SetSize(300, 400)
	frame:Center()
	frame:SetTitle("Utility Menu V6")
	frame:SetDeleteOnClose(false)
	frame:SetVisible(false)
	tab:Dock(FILL)
	tab:SetFadeTime(0)
	tab:AddSheet("Utility", scrollUtility, "icon16/wrench.png")
	tab:AddSheet("Display", scrollDisplay, "icon16/monitor.png")
	tab:AddSheet("Settings", scrollSettings, "icon16/cog.png")
	createLabel("Miscellaneous options:", scrollUtility)
	createCheckbox("Auto bhop", "autobhop", scrollUtility)
	createCheckbox("Toggle freecam", "freecam", scrollUtility)
	createCheckbox("Toggle no shake", "noshake", scrollUtility)
	createLabel("Player gestures:", scrollUtility)
	createButtonGrid(acts, function(act) RunConsoleCommand("act", act) end, scrollUtility)
	createLabel("Miscellaneous options:", scrollDisplay)
	createCheckbox("Draw client info", "clientinfo", scrollDisplay)
	createCheckbox("Show minimap", "minimap", scrollDisplay)
	createCheckbox("Draw prop boxes", "propbox", scrollDisplay)
	createLabel("NPC options:", scrollDisplay)
	createCheckbox("Draw NPC boxes", "npcbox", scrollDisplay)
	createCheckbox("Draw NPC lines", "npcline", scrollDisplay)
	createCheckbox("Draw NPC info", "npcinfo", scrollDisplay)
	createLabel("Player Options:", scrollDisplay)
	createCheckbox("Draw player boxes", "playerbox", scrollDisplay)
	createCheckbox("Draw player lines", "playerline", scrollDisplay)
	createCheckbox("Draw player info", "playerinfo", scrollDisplay)
	createLabel("Free cam:", scrollSettings)
	createSlider("Speed:", 1, 50, "basespeed", scrollSettings)
	createLabel("No shake:", scrollSettings)
	createSlider("FOV", 80, 170, "noshakefov", scrollSettings)
	createLabel("Map settings:", scrollSettings)
	createSlider("Size:", 1, 5, "mapsize", scrollSettings)
	createSlider("Scale:", 1, 5, "mapscale", scrollSettings)
	createSlider("Pos:", 1, 4, "mappos", scrollSettings)
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
	if settings.freecam then
		if globalvalues.freecamtoggle then
			globalvalues.freecamtoggle = false
			hook.Remove("CalcView", "freecamview")
			hook.Remove("PlayerBindPress", "freecamblockkeys")
		else
			globalvalues.freecamtoggle = true
			globalvalues.freecampos = ply:EyePos()
			globalvalues.freecamang = ply:EyeAngles()
			globalvalues.frozenplayerviewang = ply:EyeAngles()
			hook.Add("CalcView", "freecamview", function(_, _, _, fov)
				return {origin = globalvalues.freecampos, angles = globalvalues.freecamang, fov = fov, drawviewer = true}
			end)
		end
	end
end)