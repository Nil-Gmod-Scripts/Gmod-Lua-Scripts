if CLIENT then
	local settings = {autobhop = false, speedometer = false, propbox = false, npcbox = false, playerbox = false, npcnametags = false, playernametags = false, npccursorlines = false, playercursorlines = false, playerbones = false, npcbones = false,}

	local actList = {"dance", "robot", "muscle", "zombie", "agree", "disagree", "cheer", "wave", "laugh", "forward", "group", "halt", "salute", "becon", "bow"}

	for k in pairs(settings) do settings[k] = cookie.GetNumber("utility_" .. k, 0) == 1 end

	local util = {}

	function util.DrawBoundingBox(ent, color, ang)
		cam.IgnoreZ(true)
		render.DrawWireframeBox(ent:GetPos(), ang or ent:GetAngles(), ent:OBBMins(), ent:OBBMaxs(), color, true)
		cam.IgnoreZ(false)
	end

	function util.DrawNameTag(ent, name, color)
		local tagPos = ent:EyePos() + Vector(0, 0, 10)
		local screenPos = tagPos:ToScreen()
		draw.SimpleText(name, "BudgetLabel", screenPos.x, screenPos.y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
	end

	function util.DrawCursorLines(entities, color, filter)
		local ply = LocalPlayer()
		local screenX = ScrW() / 2
		local screenY = ScrH() / 2
		local dir = gui.ScreenToVector(screenX, screenY)
		local startPos = ply:EyePos() + dir * 50
		for _, ent in ipairs(entities) do
			if not filter or filter(ent) then
				render.DrawLine(startPos, ent:EyePos(), color, true)
			end
		end
	end

	function util.DrawBoneLines(ent, color)
		render.SetColorMaterial()
		local n = ent:GetBoneCount()
		local origin = ent:GetPos()
		local positions = {}
		for i = 0, n - 1 do
			positions[i] = ent:GetBonePosition(i)
		end
		for i = 0, n - 1 do
			local parent = ent:GetBoneParent(i)
			local pos, parentPos = positions[i], positions[parent]
			if pos and parentPos and pos:Distance(origin) > 1 and parentPos:Distance(origin) > 1 then
				cam.IgnoreZ(true)
				render.DrawLine(pos, parentPos, color, true)
				cam.IgnoreZ(false)
			end
		end
	end

	hook.Add("PostDrawOpaqueRenderables", "CustomBox", function()
		if settings.propbox then
			for _, ent in ipairs(ents.GetAll()) do
				if ent:GetClass():find("^prop_") then
					util.DrawBoundingBox(ent, Color(0, 255, 255))
				end
			end
		end
		if settings.npcbox then
			for _, ent in ipairs(ents.FindByClass("npc_*")) do
				if ent:Alive() then
					util.DrawBoundingBox(ent, Color(255, 0, 0), Angle(0, 0, 0))
				end
			end
		end
		if settings.playerbox then
			for _, ply in ipairs(player.GetAll()) do
				if ply ~= LocalPlayer() and ply:Alive() then
					util.DrawBoundingBox(ply, Color(255, 255, 0), Angle(0, 0, 0))
				end
			end
		end
	end)

	hook.Add("PostDrawOpaqueRenderables", "DrawBones", function()
		if not (settings.playerbones or settings.npcbones) then return end
		if settings.npcbones then
			for _, npc in ipairs(ents.FindByClass("npc_*")) do
				if IsValid(npc) and npc:Health() > 0 then
					util.DrawBoneLines(npc, Color(255, 0, 0))
				end
			end
		end
		if settings.playerbones then
			for _, ply in ipairs(player.GetAll()) do
				if ply ~= LocalPlayer() and ply:Alive() then
					util.DrawBoneLines(ply, Color(255, 255, 0))
				end
			end
		end
	end)

	hook.Add("PostDrawTranslucentRenderables", "DrawLinesToEntities", function()
		local ply = LocalPlayer()
		if not IsValid(ply) or not ply:Alive() or ply:ShouldDrawLocalPlayer() then return end
		cam.IgnoreZ(true)
		if settings.npccursorlines then
			util.DrawCursorLines(ents.FindByClass("npc_*"), Color(255, 0, 0), function(npc) return npc:Health() > 0 end)
		end
		if settings.playercursorlines then
			util.DrawCursorLines(player.GetAll(), Color(255, 255, 0), function(p) return p ~= ply and p:Alive() end)
		end
		cam.IgnoreZ(false)
	end)

	hook.Add("CreateMove", "CustomMovementControls", function(cmd)
		local ply = LocalPlayer()
		if ply:Alive() and settings.autobhop and ply:GetMoveType() ~= MOVETYPE_NOCLIP and ply:WaterLevel() < 2 then
			if not ply:IsOnGround() and cmd:KeyDown(IN_JUMP) then
				cmd:RemoveKey(IN_JUMP)
			end
		end
	end)

	hook.Add("HUDPaint", "ShowPlayerSpeed", function()
		local ply = LocalPlayer()
		if IsValid(ply) and ply:Alive() and settings.speedometer and not ply:ShouldDrawLocalPlayer() then
			draw.SimpleText(("Speed: %d u/s"):format(math.Round(ply:GetVelocity():Length())), "BudgetLabel", 600, 450, Color(255, 255, 0), TEXT_ALIGN_LEFT)
		end
	end)

	hook.Add("HUDPaint", "DrawNameTags", function()
		if settings.npcnametags then
			for _, npc in ipairs(ents.FindByClass("npc_*")) do
				if npc:Health() > 0 then
					local npcName = npc.GetName and npc:GetName() or npc:GetClass()
					util.DrawNameTag(npc, npcName, Color(255, 0, 0))
				end
			end
		end
		if settings.playernametags then
			for _, ply in ipairs(player.GetAll()) do
				if ply ~= LocalPlayer() and ply:Alive() then
					util.DrawNameTag(ply, ply:Nick(), Color(255, 255, 0))
				end
			end
		end
	end)

	local utilityMenu

	local function createLabel(parent, text, font, color)
		local label = vgui.Create("DLabel", parent)
		label:SetText(text)
		label:SetFont(font or "DermaDefaultBold")
		label:SetTextColor(color or color_white)
		label:Dock(TOP)
		label:DockMargin(10, 5, 0, 5)
		label:SizeToContents()
		return label
	end

	local function createCheckbox(parent, name, key)
		local check = vgui.Create("DCheckBoxLabel", parent)
		check:SetText(name)
		check:SetValue(settings[key])
		check:Dock(TOP)
		check:DockMargin(15, 0, 0, 5)
		check:SetTextColor(color_white)
		check.OnChange = function(_, val)
			settings[key] = val
			cookie.Set("utility_" .. key, val and "1" or "0")
		end
		return check
	end

	local function CreateUtilityMenu()
		utilityMenu = vgui.Create("DFrame")
		utilityMenu:SetSize(300, 400)
		utilityMenu:Center()
		utilityMenu:SetTitle("Utility Menu")
		utilityMenu:SetVisible(false)
		utilityMenu:SetDeleteOnClose(false)

		local tabs = vgui.Create("DPropertySheet", utilityMenu)
		tabs:Dock(FILL)
		tabs:SetFadeTime(0)

		local utilityPanel = vgui.Create("DPanel")
		utilityPanel:Dock(FILL)
		utilityPanel.Paint = nil
		local scrollUtility = vgui.Create("DScrollPanel", utilityPanel)
		scrollUtility:Dock(FILL)

		createLabel(scrollUtility, "Miscellaneous")
		createCheckbox(scrollUtility, "Auto Bhop", "autobhop")

		local displayPanel = vgui.Create("DPanel")
		displayPanel:Dock(FILL)
		displayPanel.Paint = nil
		local scrollDisplay = vgui.Create("DScrollPanel", displayPanel)
		scrollDisplay:Dock(FILL)

		createLabel(scrollDisplay, "Miscellaneous")
		createCheckbox(scrollDisplay, "Speedometer", "speedometer")
		createCheckbox(scrollDisplay, "Prop Box", "propbox")

		createLabel(scrollDisplay, "NPC Options")
		createCheckbox(scrollDisplay, "NPC Box", "npcbox")
		createCheckbox(scrollDisplay, "NPC Bones", "npcbones")
		createCheckbox(scrollDisplay, "NPC Nametags", "npcnametags")
		createCheckbox(scrollDisplay, "NPC Cursor Lines", "npccursorlines")

		createLabel(scrollDisplay, "Player Options")
		createCheckbox(scrollDisplay, "Player Box", "playerbox")
		createCheckbox(scrollDisplay, "Player Bones", "playerbones")
		createCheckbox(scrollDisplay, "Player Nametags", "playernametags")
		createCheckbox(scrollDisplay, "Player Cursor Lines", "playercursorlines")

		local actPanel = vgui.Create("DPanel")
		actPanel:Dock(FILL)
		actPanel.Paint = nil
		local scrollAct = vgui.Create("DScrollPanel", actPanel)
		scrollAct:Dock(FILL)

		createLabel(scrollAct, "Player Gestures")
		local grid = vgui.Create("DIconLayout", scrollAct)
		grid:Dock(TOP)
		grid:SetSpaceX(5)
		grid:SetSpaceY(5)
		grid:DockMargin(10, 0, 10, 0)

		for _, act in ipairs(actList) do
			local btn = grid:Add("DButton")
			btn:SetText(act:sub(1,1):upper() .. act:sub(2))
			btn:SetSize(50, 30)
			btn.DoClick = function()
				RunConsoleCommand("act", act)
			end
		end

		tabs:AddSheet(" Utility", utilityPanel, "icon16/wrench.png")
		tabs:AddSheet(" Display", displayPanel, "icon16/monitor.png")
		tabs:AddSheet(" Act", actPanel, "icon16/user.png")
	end

	concommand.Add("open_utility_menu", function()
		if not IsValid(utilityMenu) then CreateUtilityMenu() end
		utilityMenu:SetVisible(true)
		utilityMenu:MakePopup()
	end)
end