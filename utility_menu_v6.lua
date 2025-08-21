if SERVER then return end

hook.Remove("Think", "updatecache")
hook.Remove("CreateMove", "autobhop and freecam")
hook.Remove("PlayerBindPress", "freecamblockkeys")
hook.Remove("PostDrawOpaqueRenderables", "drawentityboxes")
hook.Remove("PostDrawTranslucentRenderables", "drawcursorlines")
hook.Remove("HUDPaint", "drawinfo")

concommand.Remove("open_utility_menu")
concommand.Remove("toggle_freecam")

if not globalvalues then
	globalvalues = {
		scriptran = false,
		freecamtoggle = false,
		freecampos = Vector(0, 0, 0),
		freecamang = Angle(0, 0, 0),
		frozenplayerviewang = Angle(0, 0, 0),
		lastupdate = 0
	}
end

if not globalvalues.scriptran then
	globalvalues.scriptran = true
	print()
	print("Run 'open_utility_menu' to open the menu!")
	print()
end

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
		white = Color(255, 255, 255), cyan = Color(0, 255, 255), red = Color(255, 0, 0),
		yellow = Color(255, 255, 0), green = Color(0, 255, 0), black = Color(0, 0, 0)
	}
end

if not entitycaches then
	entitycaches = {players = {}, npcs = {}, props = {}}
end

local function updatecache()
	entitycaches.players = {}
	entitycaches.npcs = {}
	entitycaches.props = {}
	local ply = LocalPlayer()
	for _, ent in ipairs(ents.GetAll()) do
		if IsValid(ent) then
			local class = ent:GetClass():lower()
			if class:find("prop_") then
				table.insert(entitycaches.props, ent)
			elseif ent:IsNPC() then
				table.insert(entitycaches.npcs, ent)
			elseif ent:IsPlayer() and ent ~= ply then
				table.insert(entitycaches.players, ent)
			end
		end
	end
end

hook.Add("Think", "updatecache", function()
	if CurTime() - globalvalues.lastupdate > 0.5 then
		updatecache()
		globalvalues.lastupdate = CurTime()
	end
end)

hook.Add("CreateMove", "autobhop and freecam", function(cmd)
	local ply = LocalPlayer()
	if settings.autobhop and cmd:KeyDown(IN_JUMP) and not ply:IsOnGround() and ply:WaterLevel() <= 1 and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
		cmd:RemoveKey(IN_JUMP)
	elseif settings.freecam and globalvalues.freecamtoggle and not vgui.GetKeyboardFocus() and not gui.IsGameUIVisible() then
		local mousex, mousey = cmd:GetMouseX(), cmd:GetMouseY()
		local speed = (input.IsKeyDown(KEY_LSHIFT) and 25 or 10)
		local wishmove = Vector()
		local pitchsens = GetConVar("m_pitch"):GetFloat()
		local yawsens = GetConVar("m_yaw"):GetFloat()
		globalvalues.freecamang.p = math.Clamp(globalvalues.freecamang.p + mousey * pitchsens, -89, 89)
		globalvalues.freecamang.y = globalvalues.freecamang.y - mousex * yawsens
		if input.IsKeyDown(KEY_W) then wishmove = wishmove + globalvalues.freecamang:Forward() end
		if input.IsKeyDown(KEY_S) then wishmove = wishmove - globalvalues.freecamang:Forward() end
		if input.IsKeyDown(KEY_D) then wishmove = wishmove + globalvalues.freecamang:Right() end
		if input.IsKeyDown(KEY_A) then wishmove = wishmove - globalvalues.freecamang:Right() end
		if input.IsKeyDown(KEY_SPACE) then wishmove = wishmove + globalvalues.freecamang:Up() end
		if input.IsKeyDown(KEY_LCONTROL) then wishmove = wishmove - globalvalues.freecamang:Up()end
		if wishmove:LengthSqr() > 0 then
			wishmove:Normalize()
			globalvalues.freecampos = globalvalues.freecampos + wishmove * speed
		end
		cmd:ClearButtons()
		cmd:ClearMovement()
		cmd:SetViewAngles(globalvalues.frozenplayerviewang)
	end
end)

hook.Add("PlayerBindPress", "freecamblockkeys", function(ply, bind, pressed)
	if globalvalues.freecamtoggle then
		if string.find(bind, "noclip") or string.find(bind, "impulse 100") or string.find(bind, "impulse 201") then
			return true
		end
	end
end)

hook.Add("PostDrawOpaqueRenderables", "drawentityboxes", function()
	local ply = LocalPlayer()
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
				render.DrawWireframeBox(ent:GetPos(), Angle(0, 0, 0), ent:OBBMins(), ent:OBBMaxs(), colors.red, false)
			end
		end
	end
	if settings.playerbox then
		for _, ent in ipairs(entitycaches.players or {}) do
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
		for _, ent in ipairs(entitycaches.npcs or {}) do
			if IsValid(ent) and ent:Alive() then
				local endpos = ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z * 0.75)
				render.DrawLine(startpos, endpos, colors.red, false)
			end
		end
	end
	if settings.playerline then
		for _, ent in ipairs(entitycaches.players or {}) do
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
		for _, ent in ipairs(entitycaches.npcs or {}) do
			if IsValid(ent) and ent:Alive() then
				local pos = ent:EyePos():ToScreen()
				draw.SimpleText(ent:GetClass(), "BudgetLabel", pos.x, pos.y - 12, colors.red, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				draw.SimpleText("HP:" .. ent:Health(), "BudgetLabel", pos.x, pos.y, colors.red, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			end
		end
	end
	if settings.playerinfo then
		for _, ent in ipairs(entitycaches.players or {}) do
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
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		local sizeLevels = {150, 200, 250, 300, 400}
		local scaleLevels = {25, 50, 75, 100, 125}
		local sizeIndex = math.Clamp(cookie.GetNumber("mapsize", 3), 1, #sizeLevels)
		local scaleIndex = math.Clamp(cookie.GetNumber("mapscale", 3), 1, #scaleLevels)
		local posIndex = math.Clamp(cookie.GetNumber("mappos", 1), 1, 4)
		local size  = sizeLevels[sizeIndex]
		local scale = scaleLevels[scaleIndex]
		local radius = size / 2
		local screenW, screenH = ScrW(), ScrH()
		local corners = {
			{x = 16 + radius, y = 16 + radius}, {x = screenW - 16 - radius, y = 16 + radius},
			{x = 16 + radius, y = screenH - 16 - radius}, {x = screenW - 16 - radius, y = screenH - 16 - radius}
		}
		local cx, cy = corners[posIndex].x, corners[posIndex].y
		local yaw = ply:EyeAngles().y
		draw.NoTexture()
		surface.SetDrawColor(0, 0, 0, 225)
		surface.DrawRect(cx - radius, cy - radius, radius * 2, radius * 2)
		for _, ent in ipairs(entitycaches.players or {}) do
			if IsValid(ent) and ent ~= ply and ent:Alive() then
				local sx, sy = worldtomini(ent:GetPos(), yaw, scale, radius)
				surface.SetDrawColor(255, 255, 0)
				surface.DrawRect(cx + sx - 1, cy + sy - 1, 4, 4)
				draw.SimpleText(ent:Nick(), "BudgetLabel", cx + sx, cy + sy - 0.5, colors.yellow, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			end
		end
		for _, ent in ipairs(entitycaches.npcs or {}) do
			if IsValid(ent) and ent:Alive() then
				local sx, sy = worldtomini(ent:GetPos(), yaw, scale, radius)
				surface.SetDrawColor(255, 0, 0)
				surface.DrawRect(cx + sx - 1, cy + sy - 1, 4, 4)
			end
		end
		local arrowSize = 4
		surface.SetDrawColor(0, 255, 0)
		surface.DrawLine(cx, cy - arrowSize, cx - arrowSize, cy + arrowSize)
		surface.DrawLine(cx, cy - arrowSize, cx + arrowSize, cy + arrowSize)
		surface.DrawLine(cx - arrowSize, cy + arrowSize, cx + arrowSize, cy + arrowSize)
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

local function createmessage(text, parent)
	local label = vgui.Create("DLabel", parent)
	label:SetText(text)
	label:SetFont("DermaDefault")
	label:SetTextColor(colors.white)
	label:SetWrap(true)
	label:SetAutoStretchVertical(true)
	label:Dock(TOP)
	label:DockMargin(10, 5, 0, 0)
	label:SetWidth(parent:GetWide() - 20)
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
	local scrollinfo = vgui.Create("DScrollPanel", tab)
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
	tab:AddSheet("Info", scrollinfo, "icon16/book.png")
	tab:AddSheet("Utility", scrollutility, "icon16/wrench.png")
	tab:AddSheet("Display", scrolldisplay, "icon16/monitor.png")
	tab:AddSheet("Settings", scrollsettings, "icon16/cog.png")
	createlabel("Welcome!", scrollinfo)
	createmessage("This lua script was made for me and a friend and mainly for me. it adds a lot of fun and useful features like a mini-map and ESP.", scrollinfo)
	createmessage("Go NUTS!", scrollinfo)
	createlabel("Miscellaneous Options:", scrollutility)
	createcheckbox("Auto Bhop", "autobhop",  scrollutility)
	createcheckbox("Toggle Freecam", "freecam", scrollutility)
	createlabel("Player Gestures:", scrollutility)
	createbuttongrid(acts, function(act) RunConsoleCommand("act", act) end, scrollutility)
	createlabel("Miscellaneous Options:", scrolldisplay)
	createcheckbox("Draw Client Info", "clientinfo",  scrolldisplay)
	createcheckbox("Draw Prop Boxes", "propbox", scrolldisplay)
	createcheckbox("Show Minimap", "minimap", scrolldisplay)
	createlabel("NPC Options:", scrolldisplay)
	createcheckbox("Draw NPC Boxes", "npcbox", scrolldisplay)
	createcheckbox("Draw NPC Lines", "npcline", scrolldisplay)
	createcheckbox("Draw NPC Info", "npcinfo", scrolldisplay)
	createlabel("Player Options:", scrolldisplay)
	createcheckbox("Draw Player Boxes", "playerbox", scrolldisplay)
	createcheckbox("Draw Player Lines", "playerline", scrolldisplay)
	createcheckbox("Draw Player Info", "playerinfo", scrolldisplay)
	createlabel("Map Settings:", scrollsettings)
	createslider("Map Size:", 1, 5, "mapsize", scrollsettings)
	createslider("Map Scale:", 1, 5, "mapscale", scrollsettings)
	createslider("Map Pos:", 1, 4, "mappos", scrollsettings)
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
		else
			local ply = LocalPlayer()
			globalvalues.freecamtoggle = true
			globalvalues.freecampos, globalvalues.freecamang = ply:EyePos(), ply:EyeAngles()
			globalvalues.frozenplayerviewang = ply:EyeAngles()
			hook.Add("CalcView", "freecamview", function(_,_,_,fov)
				return {origin = globalvalues.freecampos, angles = globalvalues.freecamang, fov = fov, drawviewer = true}
			end)
		end
	end
end)