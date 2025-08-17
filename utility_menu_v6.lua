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

local ply = LocalPlayer()

hook.Add("CreateMove", "autobhop", function(cmd)
	if settings.autobhop and cmd:KeyDown(IN_JUMP) and not ply:IsOnGround() and ply:WaterLevel() <= 1 and ply:GetMoveType() ~= MOVETYPE_NOCLIP and ply:Alive() then
		cmd:RemoveKey(IN_JUMP)
	end
end)

hook.Add("HUDPaint", "drawclientinfo", function()
	if settings.clientinfo and ply:Alive() then
		local sw, sh = ScrW(), ScrH()
		draw.SimpleText("Speed:" .. math.Round(ply:GetVelocity():Length()) .. "u/s", "BudgetLabel", sw / 2, sh / 2 + 75, colors.white, TEXT_ALIGN_CENTER)
		draw.SimpleText("FPS:" .. math.floor(1 / FrameTime()), "BudgetLabel", sw / 2, sh / 2 + 87, colors.white, TEXT_ALIGN_CENTER)
	end
end)

hook.Add("PostDrawOpaqueRenderables", "drawentityboxes", function()
	if settings.propbox or settings.npcbox or settings.playerbox then
		for _, ent in ipairs(ents.GetAll()) do
			if IsValid(ent) and ply:GetPos():Distance(ent:GetPos()) <= 5000 then
				local pos = ent:GetPos()
				local omin, omax = ent:OBBMins(), ent:OBBMaxs()
				if settings.propbox and ent:GetClass():lower():find("prop_") then
					render.DrawWireframeBox(pos, ent:GetAngles(), omin, omax, colors.cyan, false)
				elseif ent:Alive() then
					if settings.npcbox and ent:IsNPC() then
						render.DrawWireframeBox(pos, Angle(0, 0, 0), omin, omax, colors.red, false)
					elseif settings.playerbox and ent:IsPlayer() and ent ~= ply then
						render.DrawWireframeBox(pos, Angle(0, 0, 0), omin, omax, colors.yellow, false)
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
					draw.SimpleText(ent:GetClass(), "BudgetLabel", pos.x, pos.y + -12, colors.red, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
					draw.SimpleText("HP:" .. health, "BudgetLabel", pos.x, pos.y, colors.red, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				elseif settings.playerinfo and ent:IsPlayer() and ent ~= ply then
					draw.SimpleText(ent:Nick(), "BudgetLabel", pos.x, pos.y + -12, colors.yellow, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
					if ent:Armor() > 0 then
						draw.SimpleText("HP:" .. health .. "|AP:" .. ent:Armor(), "BudgetLabel", pos.x, pos.y, colors.yellow, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
					else
						draw.SimpleText("HP:" .. health, "BudgetLabel", pos.x, pos.y, colors.yellow, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
					end
				end
			end
		end
	end
end)

hook.Add("PostDrawTranslucentRenderables", "DrawCursorLines", function()
	if settings.npcline or settings.playerline then
		local startpos = ply:EyePos() + ply:GetAimVector() * 50
		for _, ent in ipairs(ents.GetAll()) do
			if IsValid(ent) and ply:Alive() and not ply:ShouldDrawLocalPlayer() then
				local endpos = ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z * 0.75)
				if ent:Alive() and ply:GetPos():Distance(ent:GetPos()) <= 5000 then
					if settings.npcline and ent:IsNPC() then
						render.DrawLine(startpos, endpos, colors.red, false)
					elseif settings.playerline and ent:IsPlayer() and ent ~= ply then
						render.DrawLine(startpos, endpos, colors.yellow, false)
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