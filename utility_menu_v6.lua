if not settings then
	settings = {}
end

if not istable(actlist) then
	actlist = {
		"agree", "becon", "bow", "cheer", "dance", "disagree", "forward", "group",
		"halt", "laugh", "muscle", "pers", "robot", "salute", "wave", "zombie"
	}
end

hook.Add("CreateMove", "autobhop", function(cmd)
	local ply = LocalPlayer()
	if settings.autobhop and cmd:KeyDown(IN_JUMP) and not ply:IsOnGround() and ply:WaterLevel() <= 1 and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
		cmd:RemoveKey(IN_JUMP)
	end
end)

hook.Add("HUDPaint", "drawclientinfo", function()
	local ply = LocalPlayer()
		local sw, sh = ScrW(), ScrH()
	if settings.clientinfo and ply:Alive() then
		draw.SimpleText("Speed:" .. math.Round(ply:GetVelocity():Length()) .. "u/s", "BudgetLabel", sw / 2, sh / 2 + 75, Color(255, 255, 255), TEXT_ALIGN_CENTER)
		draw.SimpleText("FPS:" .. math.floor(1 / FrameTime()), "BudgetLabel", sw / 2, sh / 2 + 87, Color(255, 255, 255), TEXT_ALIGN_CENTER)
	end
end)

hook.Add("PostDrawOpaqueRenderables", "drawentityboxes", function()
	if settings.propbox or settings.npcbox or settings.playerbox then
		for _, ent in ipairs(ents.GetAll()) do
			if IsValid(ent) then
				local pos = ent:GetPos()
				local obbmins, obbmaxs = ent:OBBMins(), ent:OBBMaxs()
				if settings.propbox and ent:GetClass():lower():find("prop_") then
					render.DrawWireframeBox(pos, ent:GetAngles(), obbmins, obbmaxs, Color(0, 255, 255), false)
				elseif ent:Alive() then
					if settings.npcbox and ent:IsNPC() then
						render.DrawWireframeBox(pos, Angle(0, 0, 0), obbmins, obbmaxs, Color(255, 0, 0), false)
					elseif settings.playerbox and ent:IsPlayer() and ent ~= LocalPlayer() then
						render.DrawWireframeBox(pos, Angle(0, 0, 0), obbmins, obbmaxs, Color(255, 255, 0), false)
					end
				end
			end
		end
	end
end)

hook.Add("HUDPaint", "drawentityinfo", function()
	if settings.npcinfo or settings.playerinfo then
		for _, ent in ipairs(ents.GetAll()) do
			if IsValid(ent) and ent:Alive() then
				local pos = ent:EyePos():ToScreen()
				local health = ent:Health()
				if settings.npcinfo and ent:IsNPC() then
					draw.SimpleText(ent:GetClass(), "BudgetLabel", pos.x, pos.y + -12, Color(255, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
					draw.SimpleText("HP:" .. health, "BudgetLabel", pos.x, pos.y, Color(255, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				elseif settings.playerinfo and ent:IsPlayer() and ent ~= LocalPlayer() then
					draw.SimpleText(ent:Nick(), "BudgetLabel", pos.x, pos.y + -12, Color(255, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
					if ent:Armor() > 0 then
						draw.SimpleText("HP:" .. health .. "|AP:" .. ent:Armor(), "BudgetLabel", pos.x, pos.y, Color(255, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
					else
						draw.SimpleText("HP:" .. health, "BudgetLabel", pos.x, pos.y, Color(255, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
					end
				end
			end
		end
	end
end)

hook.Add("PostDrawTranslucentRenderables", "DrawCursorLines", function()
	local ply = LocalPlayer()
	local startpos = ply:EyePos() + ply:GetAimVector() * 50
	if settings.npcline or settings.playerline then
		if ply:Alive() and not ply:ShouldDrawLocalPlayer() then
			for _, ent in ipairs(ents.GetAll()) do
				if IsValid(ent) and ent:Alive() then
					local endpos = ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z * 0.75)
					if settings.npcline and ent:IsNPC() then
						render.DrawLine(startpos, endpos, Color(255, 0, 0), false)
					elseif settings.playerline and ent:IsPlayer() and ent ~= ply then
						render.DrawLine(startpos, endpos, Color(255, 255, 0), false)
					end
				end
			end
		end
	end
end)

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

local function createcheckbox(text, parent, key)
	local checkbox = vgui.Create("DCheckBoxLabel", parent)
	checkbox:SetText(text)
	checkbox:SetFont("DermaDefault")
	checkbox:SetTextColor(color_white)
	checkbox:SetValue(settings[key] and true or false)
	checkbox:Dock(TOP)
	checkbox:SizeToContents()
	checkbox:DockMargin(10, 5, 0, 0)
	checkbox.OnChange = function(self, val) settings[key] = val and true or false end
	return checkbox
end

local function createactgrid(parent, actlist)
	local grid = vgui.Create("DIconLayout", parent)
	grid:Dock(TOP)
	grid:SetSpaceX(5)
	grid:SetSpaceY(5)
	grid:CenterHorizontal()
	grid:DockMargin(9, 5, 0, 0)
	for _, act in ipairs(actlist) do
		local button = grid:Add("DButton")
		button:SetText(act:sub(1,1):upper() .. act:sub(2):lower())
		button:SetSize(60, 30)
		button.DoClick = function() RunConsoleCommand("act", act) end
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
	createlabel("Player Gestures:", scrollutility)
	createactgrid(scrollutility, actlist)
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