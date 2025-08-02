if CLIENT then

	-- #$%#$% LOCALS #$%#$%

	local actList = {"dance", "robot", "muscle", "zombie", "agree", "disagree", "cheer", "wave", "laugh", "forward", "group", "halt", "salute", "becon", "bow"}
	local freecamtoggle, freecamPos, freecamAng, frozenPlayerViewAng = false, Vector(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0)
	local colors = {prop = Color(0, 255, 255), npc = Color(255, 0, 0), player = Color(255, 255, 0)}
	local freecamSettings = {sensitivity = 1.75, speed = 10, fastSpeed = 25}
	local utilityMenu, ply = nil, LocalPlayer()

	-- #$%#$% FUNCTIONS #$%#$%

	local function box(ent, color, ang)
		cam.IgnoreZ(true)
		render.DrawWireframeBox(ent:GetPos(), ang or ent:GetAngles(), ent:OBBMins(), ent:OBBMaxs(), color, true)
		cam.IgnoreZ(false)
	end

	local function nametag(ent, name, color)
		local pos = ent:EyePos():ToScreen()
		draw.SimpleText(name, "BudgetLabel", pos.x, pos.y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
	end

	local function cursorline(entities, color)
		local dir = gui.ScreenToVector(ScrW() / 2, ScrH() / 2)
		local startPos = ply:EyePos() + dir * 100
		for _, ent in ipairs(entities) do
			cam.IgnoreZ(true)
			render.DrawLine(startPos, ent:EyePos(), color, true)
			cam.IgnoreZ(false)
		end
	end

	local function drawBones(ent, color)
		local origin = ent:GetPos()
		local bones = ent:GetBoneCount()
		for i = 0, bones - 1 do
			local bonePos1 = ent:GetBonePosition(i)
			local parent = ent:GetBoneParent(i)
			if parent ~= -1 then
				local bonePos2 = ent:GetBonePosition(parent)
				if bonePos1 and bonePos2 and bonePos1:Distance(origin) > 1 and bonePos2:Distance(origin) > 1 then
					cam.IgnoreZ(true)
					render.DrawLine(bonePos1, bonePos2, color, true)
					cam.IgnoreZ(false)
				end
			end
		end
	end

	local function enablefreecam()
		freecamtoggle = true
		freecamPos, freecamAng = ply:EyePos(), ply:EyeAngles()
		frozenPlayerViewAng = ply:EyeAngles()
		hook.Add("CalcView", "FreecamView", function(_,_,_,fov)
			return {origin = freecamPos, angles = freecamAng, fov = fov, drawviewer = true}
		end)
	end

	local function disablefreecam()
		freecamtoggle = false
		hook.Remove("CalcView", "FreecamView")
	end
	
	local function getsettings()
		return {autobhop = cookie.GetNumber("utility_autobhop", 0) == 1, propbox = cookie.GetNumber("utility_propbox", 0) == 1, npcbox = cookie.GetNumber("utility_npcbox", 0) == 1, playerbox = cookie.GetNumber("utility_playerbox", 0) == 1, speedometer = cookie.GetNumber("utility_speedometer", 0) == 1, npcnametag = cookie.GetNumber("utility_npcnametag", 0) == 1, npccursorline = cookie.GetNumber("utility_npccursorline", 0) == 1, playernametag = cookie.GetNumber("utility_playernametag", 0) == 1, playercursorline = cookie.GetNumber("utility_playercursorline", 0) == 1, playerbones = cookie.GetNumber("utility_playerbones", 0) == 1, npcbones = cookie.GetNumber("utility_npcbones", 0) == 1}
	end

	-- #$%#$% HOOKS #$%#$%

	hook.Add("CreateMove", "bhop and freecam", function(cmd)
		if getsettings().autobhop then
			if cmd:KeyDown(IN_JUMP) and not (ply:IsOnGround() or ply:WaterLevel() > 1 or ply:GetMoveType() == MOVETYPE_NOCLIP) then
				cmd:RemoveKey(IN_JUMP)
			end
		end
		if freecamtoggle and not vgui.GetKeyboardFocus() and not gui.IsGameUIVisible() then
			local mouseX = cmd:GetMouseX()
			local mouseY = cmd:GetMouseY()
			local speed = (input.IsKeyDown(KEY_LSHIFT) and freecamSettings.fastSpeed or freecamSettings.speed)
			local wishMove = Vector()
			freecamAng.p = math.Clamp(freecamAng.p + mouseY * freecamSettings.sensitivity * 0.01, -89, 89)
			freecamAng.y = freecamAng.y - mouseX * freecamSettings.sensitivity * 0.01
			freecamAng.r = 0
			if input.IsKeyDown(KEY_W) then wishMove = wishMove + freecamAng:Forward() end
			if input.IsKeyDown(KEY_S) then wishMove = wishMove - freecamAng:Forward() end
			if input.IsKeyDown(KEY_D) then wishMove = wishMove + freecamAng:Right() end
			if input.IsKeyDown(KEY_A) then wishMove = wishMove - freecamAng:Right() end
			if input.IsKeyDown(KEY_SPACE) then wishMove = wishMove + freecamAng:Up() end
			if input.IsKeyDown(KEY_LCONTROL) then wishMove = wishMove - freecamAng:Up() end
			if wishMove:LengthSqr() > 0 then
				wishMove:Normalize()
				freecamPos = freecamPos + wishMove * speed
			end
			cmd:ClearButtons()
			cmd:ClearMovement()
			cmd:SetViewAngles(frozenPlayerViewAng)
		end
	end)

	hook.Add("HUDPaint", "speedometer", function()
		if getsettings().speedometer then
			local speed = math.Round(ply:GetVelocity():Length())
			if ply:Alive() then
				draw.SimpleText("Speed: " .. speed .. " u/s", "BudgetLabel", ScrW() / 2 - 45, ScrH() / 2 + 75, colors.player, TEXT_ALIGN_LEFT)
			end
		end
	end)

	hook.Add("PostDrawOpaqueRenderables", "box", function()
		if getsettings().propbox then
			for _, ent in ipairs(ents.FindByClass("prop_*")) do
				box(ent, colors.prop)
			end
		end
		if getsettings().npcbox then
			for _, npc in ipairs(ents.FindByClass("npc_*")) do
				if npc:Alive() then
					box(npc, colors.npc, Angle(0, 0, 0))
				end
			end
		end
		if getsettings().playerbox then
			for _, ply in ipairs(player.GetAll()) do
				if ply ~= LocalPlayer() and ply:Alive() then
					box(ply, colors.player, Angle(0, 0, 0))
				end
			end
		end
	end)

	hook.Add("HUDPaint", "nametag", function()
		if getsettings().npcnametag then
			for _, npc in ipairs(ents.FindByClass("npc_*")) do
				if npc:Alive() then
					nametag(npc, npc.PrintName or npc:GetClass(), colors.npc)
				end
			end
		end
		if getsettings().playernametag then
			for _, ply in ipairs(player.GetAll()) do
				if ply ~= LocalPlayer() and ply:Alive() then
					nametag(ply, ply:Nick(), colors.player)
				end
			end
		end
	end)

	hook.Add("PostDrawTranslucentRenderables", "cursorline", function()
		if ply:Alive() and not ply:ShouldDrawLocalPlayer() then
			if getsettings().npccursorline then
				local npcs = {}
				for _, npc in ipairs(ents.FindByClass("npc_*")) do
					if npc:Alive() then
						table.insert(npcs, npc)
					end
				end
				cursorline(npcs, colors.npc)
			end
			if getsettings().playercursorline then
				local players = {}
				for _, ply in ipairs(player.GetAll()) do
					if ply ~= LocalPlayer() and ply:Alive() then
						table.insert(players, ply)
					end
				end
				cursorline(players, colors.player)
			end
		end
	end)

	hook.Add("PostDrawTranslucentRenderables", "bones", function()
		if getsettings().npcbones then
			for _, npc in ipairs(ents.FindByClass("npc_*")) do
				if npc:Alive() then
					drawBones(npc, colors.npc)
				end
			end
		end
		if getsettings().playerbones then
			for _, ply in ipairs(player.GetAll()) do
				if ply ~= LocalPlayer() and ply:Alive() then
					drawBones(ply, colors.player)
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

	-- #$%#$% MENU #$%#$%

	local function createLabel(text, parent)
		local label = vgui.Create("DLabel", parent)
		label:SetText(text)
		label:SetFont("DermaDefaultBold")
		label:SetTextColor(color_white)
		label:SizeToContents()
		label:Dock(TOP)
		label:DockMargin(5, 5, 5, 0)
		return label
	end

	local function createCheckbox(text, parent, settingKey)
		local checkbox = vgui.Create("DCheckBoxLabel", parent)
		checkbox:SetText(text)
		checkbox:SetFont("DermaDefault")
		checkbox:SetTextColor(color_white)
		checkbox:SetValue(cookie.GetNumber("utility_" .. settingKey, 0))
		checkbox:SizeToContents()
		checkbox:Dock(TOP)
		checkbox:DockMargin(5, 5, 5, 0)
		checkbox.OnChange = function(_, val)
			cookie.Set("utility_" .. settingKey, val and "1" or "0")
		end
		return checkbox
	end

	local function createMenu()
		local frame = vgui.Create("DFrame")
		local tab = vgui.Create("DPropertySheet", frame)
		local scrollUtility = vgui.Create("DScrollPanel", tab)
		local scrollDisplay = vgui.Create("DScrollPanel", tab)
		local scrollAct = vgui.Create("DScrollPanel", tab)

		frame.OnClose = function(self)
			gui.EnableScreenClicker(false)
		end

		frame:SetSize(300, 400)
		frame:Center()
		frame:SetTitle("Utility Menu")
		frame:SetDeleteOnClose(false)
		frame:SetVisible(false)

		tab:Dock(FILL)
		tab:SetFadeTime(0)

		createLabel("Miscellaneous Options:", scrollUtility)
		createCheckbox("Auto Bhop", scrollUtility, "autobhop")
		createLabel("Miscellaneous Options:", scrollDisplay)
		createCheckbox("Speedometer", scrollDisplay, "speedometer")
		createCheckbox("Prop Box", scrollDisplay, "propbox")
		createLabel("NPC Options:", scrollDisplay)
		createCheckbox("NPC Box", scrollDisplay, "npcbox")
		createCheckbox("NPC Bones", scrollDisplay, "npcbones")
		createCheckbox("NPC Nametag", scrollDisplay, "npcnametag")
		createCheckbox("NPC Cursor Line", scrollDisplay, "npccursorline")
		createLabel("Player Options:", scrollDisplay)
		createCheckbox("Player Box", scrollDisplay, "playerbox")
		createCheckbox("Player Bones", scrollDisplay, "playerbones")
		createCheckbox("Player Nametag", scrollDisplay, "playernametag")
		createCheckbox("Player Cursor Line", scrollDisplay, "playercursorline")
		createLabel("Player Gestures:", scrollAct)

		local grid = vgui.Create("DIconLayout", scrollAct)
		grid:Dock(TOP)
		grid:SetSpaceX(5)
		grid:SetSpaceY(5)
		grid:DockMargin(5, 5, 5, 0)
		for _, act in ipairs(actList) do
			local button = grid:Add("DButton")
			button:SetText(act:sub(1,1):upper() .. act:sub(2))
			button:SetSize(60, 30)
			button.DoClick = function()
				RunConsoleCommand("act", act)
			end
		end

		tab:AddSheet("Utility", scrollUtility, "icon16/wrench.png")
		tab:AddSheet("Display", scrollDisplay, "icon16/monitor.png")
		tab:AddSheet("Act", scrollAct, "icon16/user.png")

		return frame
	end

	-- #$%#$% COMMANDS #$%#$%

	concommand.Add("open_utility_menu", function()
		if IsValid(_G.utilityMenu) then
			_G.utilityMenu:SetVisible(true)
			gui.EnableScreenClicker(true)
		else
			_G.utilityMenu = createMenu()
			_G.utilityMenu:SetVisible(true)
			gui.EnableScreenClicker(true)
		end
	end)

	concommand.Add("toggle_freecam", function()
		if freecamtoggle then
			disablefreecam()
		else
			enablefreecam()
		end
	end)
end