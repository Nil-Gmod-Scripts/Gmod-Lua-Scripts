
-- #$%#$% SETTINGS #$%#$%

if not istable(settings) then
	settings = {
		propbox = false,
		npcbox = false,
		playerbox = false,
		npcnametag = false,
		playernametag = false,
		speedometer = false,
		autobhop = false,
		npccursorline = false,
		playercursorline = false
	}
end

-- #$%#$% HOOKS #$%#$%

hook.Add("PostDrawOpaqueRenderables", "DrawEntityBoxes", function()
	local allents = ents.GetAll()
	local ply = LocalPlayer()
	if settings.propbox then
		for _, ent in ipairs(allents) do
			if ent:GetClass():find("prop_physics") or ent:GetClass():find("prop_dynamic") then
				render.DrawWireframeBox(ent:GetPos(), ent:GetAngles(), ent:OBBMins(), ent:OBBMaxs(), Color(0, 255, 255), false)
			end
		end
	end
	if settings.npcbox then
		for _, ent in ipairs(allents) do
			if ent:IsNPC() and ent:Alive() then
				render.DrawWireframeBox(ent:GetPos(), Angle(0, 0, 0), ent:OBBMins(), ent:OBBMaxs(), Color(255, 0, 0), false)
			end
		end
	end
	if settings.playerbox then
		for _, ent in ipairs(allents) do
			if ent:IsPlayer() and ent ~= ply and ent:Alive() then
				render.DrawWireframeBox(ent:GetPos(), Angle(0, 0, 0), ent:OBBMins(), ent:OBBMaxs(), Color(255, 255, 0), false)
			end
		end
	end
end)

hook.Add("HUDPaint", "DrawNametags", function()
	local allents = ents.GetAll()
	local ply = LocalPlayer()
	if settings.npcnametag then
		for _, ent in ipairs(allents) do
			if ent:IsNPC() and ent:Alive() then
				local pos = ent:EyePos():ToScreen()
				draw.SimpleText(ent:GetClass(), "BudgetLabel", pos.x, pos.y, Color(255, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			end
		end
	end
	if settings.playernametag then
		for _, ent in ipairs(allents) do
			if ent:IsPlayer() and ent ~= ply and ent:Alive() then
				local pos = ent:EyePos():ToScreen()
				draw.SimpleText(ent:Nick(), "BudgetLabel", pos.x, pos.y, Color(255, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			end
		end
	end
end)

hook.Add("HUDPaint", "DrawSpeedometer", function()
	local ply = LocalPlayer()
	local speed = math.Round(ply:GetVelocity():Length())
	if settings.speedometer and ply:Alive() then
		draw.SimpleText("Speed: " .. speed .. " u/s", "BudgetLabel", ScrW() / 2 - 45, ScrH() / 2 + 75, Color(255, 255, 255), TEXT_ALIGN_LEFT)
	end
end)

hook.Add("CreateMove", "AutoBhop", function(cmd)
	local ply = LocalPlayer()
	if settings.autobhop and cmd:KeyDown(IN_JUMP) and not ply:IsOnGround() and ply:WaterLevel() <= 1 and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
		cmd:RemoveKey(IN_JUMP)
	end
end)

hook.Add("PostDrawTranslucentRenderables", "DrawCursorLines", function()
	local allents = ents.GetAll()
	local ply = LocalPlayer()
	local eyepos = ply:EyePos()
	local aimvec = ply:GetAimVector()
	local startpos = eyepos + aimvec * 50
	if settings.npccursorline then
		for _, ent in ipairs(allents) do
			if ent:IsNPC() and ent:Alive() then
				local endPos = ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z * 0.75)
				render.DrawLine(startpos, endPos, Color(255, 0, 0), false)
			end
		end
	end
	if settings.playercursorline then 
		for _, ent in ipairs(allents) do
			if ent:IsPlayer() and ent:Alive() and ent ~= ply then
				local endPos = ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z * 0.75)
				render.DrawLine(startpos, endPos, Color(255, 255, 0), false)
			end
		end
	end
end)

-- #$%#$% MENU #$%#$%

local function createlabel(text, parent)
	local label = vgui.Create("DLabel", parent)
	label:SetText(text)
	label:SetFont("DermaDefaultBold")
	label:SetTextColor(color_white)
	label:SizeToContents()
	label:Dock(TOP)
	label:DockMargin(5, 5, 0, 0)
	return label
end

local function createcheckbox(text, parent, setting)
	local checkbox = vgui.Create("DCheckBoxLabel", parent)
	checkbox:SetText(text)
	checkbox:SetFont("DermaDefault")
	checkbox:SetTextColor(color_white)
	checkbox:SetValue(settings[setting] and true or false)
	checkbox:SizeToContents()
	checkbox:Dock(TOP)
	checkbox:DockMargin(10, 5, 0, 0)
	checkbox.OnChange = function(self, val) settings[setting] = val and true or false end
	return checkbox
end

local function createmenu()
	local frame = vgui.Create("DFrame")
	local tab = vgui.Create("DPropertySheet", frame)
	local scrollutility = vgui.Create("DScrollPanel", tab)
	local scrolldisplay = vgui.Create("DScrollPanel", tab)
	frame:SetSize(300, 400)
	frame:Center()
	frame:SetTitle("Utility Menu")
	frame:SetDeleteOnClose(false)
	frame:SetVisible(false)
	frame.OnClose = function(self) gui.EnableScreenClicker(false) end
	tab:Dock(FILL)
	tab:SetFadeTime(0)
	tab:AddSheet("Utility", scrollutility, "icon16/wrench.png")
	tab:AddSheet("Display", scrolldisplay, "icon16/monitor.png")
	createlabel("Miscellaneous Options:", scrollutility)
	createcheckbox("Auto Bhop", scrollutility, "autobhop")
	createlabel("Miscellaneous Options:", scrolldisplay)
	createcheckbox("Speedometer", scrolldisplay, "speedometer")
	createcheckbox("Prop Box", scrolldisplay, "propbox")
	createlabel("NPC Options:", scrolldisplay)
	createcheckbox("NPC Box", scrolldisplay, "npcbox")
	createcheckbox("NPC Nametag", scrolldisplay, "npcnametag")
	createcheckbox("NPC Cursor Line", scrolldisplay, "npccursorline")
	createlabel("Player Options:", scrolldisplay)
	createcheckbox("Player Box", scrolldisplay, "playerbox")
	createcheckbox("Player Nametag", scrolldisplay, "playernametag")
	createcheckbox("Player Cursor Line", scrolldisplay, "playercursorline")
	return frame
end

-- #$%#$% COMMANDS #$%#$%

concommand.Add("open_utility_menu", function()
	if IsValid(utilitymenu) then
		utilitymenu:SetVisible(true)
		gui.EnableScreenClicker(true)
	else
		utilitymenu = createmenu()
		utilitymenu:SetVisible(true)
		gui.EnableScreenClicker(true)
	end
end)