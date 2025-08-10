if not istable(settings) then
	settings = {
		autobhop = false, freecam = false, speedometer = false, propbox = false, npcbox = false, npcbone = false, npcnametag = false,
		npchealth = false, npccursorline = false, playerbox = false, playerbone = false, playernametag = false,
		playerhealth = false, playercursorline = false, entitybox = false, entitynametag = false, entitycursorline = false,
		allfilter = ""
	}
end

if not istable(actlist) then
	actlist = {
		"agree", "becon", "bow", "cheer", "dance", "disagree", "forward", "group",
		"halt", "laugh", "muscle", "pers", "robot", "salute", "wave", "zombie"
	}
end

hook.Add("CreateMove", "AutoBhop and FreeCam", function(cmd)
	local ply = LocalPlayer()
	if settings.autobhop and cmd:KeyDown(IN_JUMP) and not ply:IsOnGround() and ply:WaterLevel() <= 1 and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
		cmd:RemoveKey(IN_JUMP)
	elseif settings.freecam and freecamtoggle and not vgui.GetKeyboardFocus() and not gui.IsGameUIVisible() then
		local mousex = cmd:GetMouseX()
		local mousey = cmd:GetMouseY()
		local speed = (input.IsKeyDown(KEY_LSHIFT) and 25 or 10)
		local wishmove = Vector()
		freecamAng.p = math.Clamp(freecamAng.p + mousey * 1.75 * 0.01, -89, 89)
		freecamAng.y = freecamAng.y - mousex * 1.75 * 0.01
		if input.IsKeyDown(KEY_W) then
			wishmove = wishmove + freecamAng:Forward()
		end
		if input.IsKeyDown(KEY_S) then
			wishmove = wishmove - freecamAng:Forward()
		end
		if input.IsKeyDown(KEY_D) then
			wishmove = wishmove + freecamAng:Right()
		end
		if input.IsKeyDown(KEY_A) then
			wishmove = wishmove - freecamAng:Right()
		end
		if input.IsKeyDown(KEY_SPACE) then
			wishmove = wishmove + freecamAng:Up()
		end
		if input.IsKeyDown(KEY_LCONTROL) then
			wishmove = wishmove - freecamAng:Up()
		end
		if wishmove:LengthSqr() > 0 then
			wishmove:Normalize()
			freecamPos = freecamPos + wishmove * speed
		end
		cmd:ClearButtons()
		cmd:ClearMovement()
		cmd:SetViewAngles(frozenPlayerViewAng)
	end
end)

hook.Add("HUDPaint", "DrawSpeedometer", function()
	local ply = LocalPlayer()
	local speed = math.Round(ply:GetVelocity():Length())
	if settings.speedometer and ply:Alive() then
		draw.SimpleText("Speed: " .. speed .. " u/s", "BudgetLabel", ScrW() / 2, ScrH() / 2 + 75, Color(255, 255, 255), TEXT_ALIGN_CENTER)
	end
end)

hook.Add("PostDrawOpaqueRenderables", "DrawEntityVisuals", function()
	local ply = LocalPlayer()
	local allents = ents.GetAll()
	local filter = (settings.allfilter or ""):lower()
	if settings.npcbone or settings.playerbone or settings.entitybox or settings.propbox or settings.npcbox or settings.playerbox then
		for _, ent in ipairs(allents) do
			if IsValid(ent) then
				local class = ent:GetClass():lower()
				local pos = ent:GetPos()
				local ang = ent:GetAngles()
				local obbMins, obbMaxs = ent:OBBMins(), ent:OBBMaxs()
				local bones = ent:GetBoneCount()
				if settings.entitybox and (filter == "" or class:find(filter)) then
					render.DrawWireframeBox(pos, ang, obbMins, obbMaxs, Color(255, 255, 255), false)
				elseif settings.propbox and (class:find("prop_")) then
					render.DrawWireframeBox(pos, ang, obbMins, obbMaxs, Color(0, 255, 255), false)
				elseif settings.npcbox and ent:IsNPC() and ent:Alive() then
					render.DrawWireframeBox(pos, Angle(0, 0, 0), obbMins, obbMaxs, Color(255, 0, 0), false)
				elseif settings.playerbox and ent:IsPlayer() and ent ~= ply and ent:Alive() then
					render.DrawWireframeBox(pos, Angle(0, 0, 0), obbMins, obbMaxs, Color(255, 255, 0), false)
				elseif bones and bones > 0 then
					local origin = pos
					for i = 0, bones - 1 do
						local parent = ent:GetBoneParent(i)
						if parent ~= -1 then
							local bonePos1 = ent:GetBonePosition(i)
							local bonePos2 = ent:GetBonePosition(parent)
							if bonePos1 and bonePos2 and bonePos1:DistToSqr(origin) > 1 and bonePos2:DistToSqr(origin) > 1 then
								if settings.npcbone and ent:IsNPC() and ent:Alive() then
									render.DrawLine(bonePos1, bonePos2, Color(255, 0, 0), false)
								elseif settings.playerbone and ent:IsPlayer() and ent:Alive() and ent ~= ply then
									render.DrawLine(bonePos1, bonePos2, Color(255, 255, 0), false)
								end
							end
						end
					end
				end
			end
		end
	end
end)

hook.Add("HUDPaint", "DrawEntityInfo", function()
	local ply = LocalPlayer()
	local allents = ents.GetAll()
	local filter = (settings.allfilter or ""):lower()
	local npcOffset = settings.npcnametag and -12 or 0
	local playerOffset = settings.playernametag and -12 or 0
	if settings.npchealth or settings.playerhealth or settings.entitynametag or settings.npcnametag or settings.playernametag then
		for _, ent in ipairs(allents) do
			if IsValid(ent) then
				local pos = ent:EyePos():ToScreen()
				if settings.npchealth and ent:IsNPC() and ent:Alive() then
					draw.SimpleText("HP:" .. ent:Health(), "BudgetLabel", pos.x, pos.y, Color(255, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				elseif settings.playerhealth and ent:IsPlayer() and ent ~= ply and ent:Alive() then
					local hp = ent:Health()
					local armor = ent:Armor()
					local text = "HP:" .. hp .. "|AP:" .. armor
					draw.SimpleText(text, "BudgetLabel", pos.x, pos.y, Color(255, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				end
				if settings.npcnametag and ent:IsNPC() and ent:Alive() then
					draw.SimpleText(ent:GetClass(), "BudgetLabel", pos.x, pos.y + npcOffset, Color(255, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				end
				if settings.playernametag and ent:IsPlayer() and ent ~= ply and ent:Alive() then
					draw.SimpleText(ent:Nick(), "BudgetLabel", pos.x, pos.y + playerOffset, Color(255, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
				end
				if settings.entitynametag then
					local class = ent:GetClass():lower()
					if filter == "" or class:find(filter) then
						draw.SimpleText(ent:GetClass(), "BudgetLabel", pos.x, pos.y, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
					end
				end
			end
		end
	end
end)


hook.Add("PostDrawTranslucentRenderables", "DrawCursorLines", function()
	local ply = LocalPlayer()
	local allents = ents.GetAll()
	local eyepos = ply:EyePos()
	local aimvec = ply:GetAimVector()
	local startpos = eyepos + aimvec * 50
	local filter = (settings.allfilter or ""):lower()
	if settings.entitycursorline or settings.npccursorline or settings.playercursorline then
		if ply:Alive() and not ply:ShouldDrawLocalPlayer() then
			for _, ent in ipairs(allents) do
				if IsValid(ent) then
					local class = ent:GetClass():lower()
					local endPos = ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z * 0.75)
					if settings.entitycursorline and (filter == "" or class:find(filter)) then
						render.DrawLine(startpos, endPos, Color(255, 255, 255), false)
					elseif settings.npccursorline and ent:IsNPC() and ent:Alive() then
						render.DrawLine(startpos, endPos, Color(255, 0, 0), false)
					elseif settings.playercursorline and ent:IsPlayer() and ent:Alive() and ent ~= ply then
						render.DrawLine(startpos, endPos, Color(255, 255, 0), false)
					end
				end
			end
		end
	end
end)

hook.Add("PlayerBindPress", "freecamblockkeys", function(ply, bind, pressed)
	if freecamtoggle then
		if string.find(bind, "noclip") or string.find(bind, "impulse 100") or string.find(bind, "impulse 201") then
			return true
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
	frame:SetTitle("Utility Menu V5")
	frame:SetDeleteOnClose(false)
	frame:SetVisible(false)
	tab:Dock(FILL)
	tab:SetFadeTime(0)
	tab:AddSheet("Utility", scrollutility, "icon16/wrench.png")
	tab:AddSheet("Display", scrolldisplay, "icon16/monitor.png")
	createlabel("Miscellaneous Options:", scrollutility)
	createcheckbox("Auto Bhop", scrollutility, "autobhop")
	createcheckbox("Toggle Freecam", scrollutility, "freecam")
	createlabel("Player Gestures:", scrollutility)
	local grid = vgui.Create("DIconLayout", scrollutility)
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
	createlabel("Miscellaneous Options:", scrolldisplay)
	createcheckbox("Speedometer", scrolldisplay, "speedometer")
	createcheckbox("Prop Boxes", scrolldisplay, "propbox")
	createlabel("NPC Options:", scrolldisplay)
	createcheckbox("NPC Boxes", scrolldisplay, "npcbox")
	createcheckbox("NPC Bones", scrolldisplay, "npcbone")
	createcheckbox("NPC Health", scrolldisplay, "npchealth")
	createcheckbox("NPC Nametags", scrolldisplay, "npcnametag")
	createcheckbox("NPC Cursor Lines", scrolldisplay, "npccursorline")
	createlabel("Player Options:", scrolldisplay)
	createcheckbox("Player Boxes", scrolldisplay, "playerbox")
	createcheckbox("Player Bones", scrolldisplay, "playerbone")
	createcheckbox("Player Health", scrolldisplay, "playerhealth")
	createcheckbox("Player Nametags", scrolldisplay, "playernametag")
	createcheckbox("Player Cursor Lines", scrolldisplay, "playercursorline")
	createlabel("Entity Options:", scrolldisplay)
	createcheckbox("Entity Boxes", scrolldisplay, "entitybox")
	createcheckbox("Entity Nametags", scrolldisplay, "entitynametag")
	createcheckbox("Entity Cursor Lines", scrolldisplay, "entitycursorline")
	local searchbox = vgui.Create("DTextEntry", scrolldisplay)
	searchbox:Dock(TOP)
	searchbox:DockMargin(10, 5, 10, 0)
	searchbox:SetPlaceholderText("Filter entities by class (e.g. npc_, prop_)")
	searchbox.OnChange = function(self) settings.allfilter = self:GetValue() or "" end
	return frame
end

concommand.Add("toggle_freecam", function()
	if settings.freecam then
		if freecamtoggle then
			freecamtoggle = false
			hook.Remove("CalcView", "FreecamView")
		else
			local ply = LocalPlayer()
			freecamtoggle = true
			freecamPos, freecamAng = ply:EyePos(), ply:EyeAngles()
			frozenPlayerViewAng = ply:EyeAngles()
			hook.Add("CalcView", "FreecamView", function(_,_,_,fov)
				return {origin = freecamPos, angles = freecamAng, fov = fov, drawviewer = true}
			end)
		end
	end
end)

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