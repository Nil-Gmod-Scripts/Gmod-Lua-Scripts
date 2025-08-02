if CLIENT then

	-- #$%#$% LOCALS #$%#$%

	local actList = {"agree", "becon", "bow", "cheer", "dance", "disagree", "forward", "group", "halt", "laugh", "muscle", "robot", "salute", "wave", "zombie"}
	local freecamtoggle, freecamPos, freecamAng, frozenPlayerViewAng = false, Vector(0, 0, 0), Angle(0, 0, 0), Angle(0, 0, 0)
	local freecamSettings = {sensitivity = 1.75, speed = 10, fastSpeed = 25}
	local utilityMenu = nil

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
		local ply = LocalPlayer()
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
		local ply = LocalPlayer()
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
		return {
			autobhop = cookie.GetNumber("utility_autobhop", 0) == 1,
			propbox = cookie.GetNumber("utility_propbox", 0) == 1,
			npcbox = cookie.GetNumber("utility_npcbox", 0) == 1,
			playerbox = cookie.GetNumber("utility_playerbox", 0) == 1,
			speedometer = cookie.GetNumber("utility_speedometer", 0) == 1,
			npcnametag = cookie.GetNumber("utility_npcnametag", 0) == 1,
			npccursorline = cookie.GetNumber("utility_npccursorline", 0) == 1,
			playernametag = cookie.GetNumber("utility_playernametag", 0) == 1,
			playercursorline = cookie.GetNumber("utility_playercursorline", 0) == 1,
			playerbones = cookie.GetNumber("utility_playerbones", 0) == 1,
			npcbones = cookie.GetNumber("utility_npcbones", 0) == 1,
			npchighlight = cookie.GetNumber("utility_npchighlight", 0) == 1,
			prophighlight = cookie.GetNumber("utility_prophighlight", 0) == 1,
			playerhighlight = cookie.GetNumber("utility_playerhighlight", 0) == 1,
			highlight_opacity = cookie.GetNumber("utility_highlight_opacity", 100)
		}
	end

	local function getColors()
		return {
			prop = Color(cookie.GetNumber("utility_prop_r", 0), cookie.GetNumber("utility_prop_g", 255), cookie.GetNumber("utility_prop_b", 255)),
			npc = Color(cookie.GetNumber("utility_npc_r", 255), cookie.GetNumber("utility_npc_g", 0), cookie.GetNumber("utility_npc_b", 0)),
			npcnametag = Color(cookie.GetNumber("utility_npc_r", 255), cookie.GetNumber("utility_npc_g", 0), cookie.GetNumber("utility_npc_b", 0)),
			player = Color(cookie.GetNumber("utility_player_r", 255), cookie.GetNumber("utility_player_g", 255), cookie.GetNumber("utility_player_b", 0)),
			playernametag = Color(cookie.GetNumber("utility_player_r", 255), cookie.GetNumber("utility_player_g", 255), cookie.GetNumber("utility_player_b", 0))
		}
	end

	-- #$%#$% HOOKS #$%#$%

	hook.Add("CreateMove", "bhop and freecam", function(cmd)
		local settings = getsettings()
		local ply = LocalPlayer()
		if settings.autobhop then
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
		local settings = getsettings()
		local ply = LocalPlayer()
		if settings.speedometer then
			local speed = math.Round(ply:GetVelocity():Length())
			if ply:Alive() then
				draw.SimpleText("Speed: " .. speed .. " u/s", "BudgetLabel", ScrW() / 2 - 45, ScrH() / 2 + 75, Color(255, 255, 255), TEXT_ALIGN_LEFT)
			end
		end
	end)

	hook.Add("PostDrawOpaqueRenderables", "box", function()
		local colors = getColors()
		local settings = getsettings()
		local ply = LocalPlayer()
		if settings.propbox then
			for _, ent in ipairs(ents.FindByClass("prop_*")) do
				box(ent, colors.prop)
			end
		end
		if settings.npcbox then
			for _, npc in ipairs(ents.FindByClass("npc_*")) do
				if npc:Alive() then
					box(npc, colors.npc, Angle(0, 0, 0))
				end
			end
		end
		if settings.playerbox then
			for _, ply in ipairs(player.GetAll()) do
				if ply ~= LocalPlayer() and ply:Alive() then
					box(ply, colors.player, Angle(0, 0, 0))
				end
			end
		end
	end)

	hook.Add("HUDPaint", "nametag", function()
		local colors = getColors()
		local settings = getsettings()
		local ply = LocalPlayer()
		if settings.npcnametag then
			for _, npc in ipairs(ents.FindByClass("npc_*")) do
				if npc:Alive() then
					nametag(npc, npc.PrintName or npc:GetClass(), colors.npcnametag)
				end
			end
		end
		if settings.playernametag then
			for _, ply in ipairs(player.GetAll()) do
				if ply ~= LocalPlayer() and ply:Alive() then
					nametag(ply, ply:Nick(), colors.playernametag)
				end
			end
		end
	end)

	hook.Add("PostDrawTranslucentRenderables", "cursorline", function()
		local colors = getColors()
		local settings = getsettings()
		local ply = LocalPlayer()
		if ply:Alive() and not ply:ShouldDrawLocalPlayer() then
			if settings.npccursorline then
				local npcs = {}
				for _, npc in ipairs(ents.FindByClass("npc_*")) do
					if npc:Alive() then
						table.insert(npcs, npc)
					end
				end
				cursorline(npcs, colors.npc)
			end
			if settings.playercursorline then
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
		local colors = getColors()
		local settings = getsettings()
		local ply = LocalPlayer()
		if settings.npcbones then
			for _, npc in ipairs(ents.FindByClass("npc_*")) do
				if npc:Alive() then
					drawBones(npc, colors.npc)
				end
			end
		end
		if settings.playerbones then
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

	local highlightMat = CreateMaterial("HighlightMat", "UnlitGeneric", {
		["$basetexture"] = "models/debug/debugwhite",
		["$ignorez"] = "1",
		["$model"] = "1",
		["$nocull"] = "1",
		["$translucent"] = "1"
	})

	hook.Add("PostDrawOpaqueRenderables", "DrawHighlightedEntities", function()
		local colors = getColors()
		local settings = getsettings()
		for _, ent in ipairs(ents.GetAll()) do
			if not IsValid(ent) or ent == LocalPlayer() then continue end
			if not ent.DrawModel then continue end
			local class = ent:GetClass()
			local color = nil
			local alpha = settings.highlight_opacity
			if settings.npchighlight and string.find(class, "npc_") then
				color = Color(colors.npc.r, colors.npc.g, colors.npc.b, alpha)
			elseif settings.playerhighlight and ent:IsPlayer() then
				color = Color(colors.player.r, colors.player.g, colors.player.b, alpha)
			elseif settings.prophighlight and string.find(class, "prop_") then
				color = Color(colors.prop.r, colors.prop.g, colors.prop.b, alpha)
			end
			if color then
				cam.IgnoreZ(true)
				render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
				render.SetBlend(color.a / 255)
				render.MaterialOverride(highlightMat)
				ent:DrawModel()
				render.MaterialOverride()
				render.SetColorModulation(1, 1, 1)
				render.SetBlend(1)
				cam.IgnoreZ(false)
				ent:SetNoDraw(true)
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

	local function createcheckbox(text, parent, settingKey)
		local checkbox = vgui.Create("DCheckBoxLabel", parent)
		checkbox:SetText(text)
		checkbox:SetFont("DermaDefault")
		checkbox:SetTextColor(color_white)
		checkbox:SetValue(cookie.GetNumber("utility_" .. settingKey, 0))
		checkbox:SizeToContents()
		checkbox:Dock(TOP)
		checkbox:DockMargin(10, 5, 0, 0)
		checkbox.OnChange = function(_, val)
			cookie.Set("utility_" .. settingKey, val and "1" or "0")
		end
		return checkbox
	end

	local function createSlider(text, parent, settingKey, min, max, default)
		local slider = vgui.Create("DNumSlider", parent)
		slider:Dock(TOP)
		slider:DockMargin(10, 5, 0, 0)
		slider:SetTall(15)
		slider:SetMin(min)
		slider:SetMax(max)
		slider:SetDecimals(0)
		slider:SetValue(cookie.GetNumber("utility_" .. settingKey, default))
		slider:SetText(text)
		slider.Label:SetTextColor(Color(255, 255, 255))
		slider.TextArea:SetTextColor(Color(255, 255, 255))
		slider.OnValueChanged = function(self, val)
			cookie.Set("utility_" .. settingKey, math.Clamp(math.Round(val), min, max))
		end
		return slider
	end

	local function createMenu()
		local frame = vgui.Create("DFrame")
		local tab = vgui.Create("DPropertySheet", frame)
		local scrollutility = vgui.Create("DScrollPanel", tab)
		local scrolldisplay = vgui.Create("DScrollPanel", tab)
		local scrollact = vgui.Create("DScrollPanel", tab)
		local scrollsettings = vgui.Create("DScrollPanel", tab)
		frame.OnClose = function(self)
			gui.EnableScreenClicker(false)
		end
		frame:SetSize(301, 425)
		frame:Center()
		frame:SetTitle("Utility Menu")
		frame:SetDeleteOnClose(false)
		frame:SetVisible(false)
		tab:Dock(FILL)
		tab:SetFadeTime(0)
		createlabel("Miscellaneous Options:", scrollutility)
		createcheckbox("Auto Bhop", scrollutility, "autobhop")
		createlabel("Miscellaneous Options:", scrolldisplay)
		createcheckbox("Speedometer", scrolldisplay, "speedometer")
		createlabel("Prop Options:", scrolldisplay)
		createcheckbox("Prop Box", scrolldisplay, "propbox")
		createcheckbox("Prop Highlight", scrolldisplay, "prophighlight")
		createlabel("NPC Options:", scrolldisplay)
		createcheckbox("NPC Box", scrolldisplay, "npcbox")
		createcheckbox("NPC Bones", scrolldisplay, "npcbones")
		createcheckbox("NPC Highlight", scrolldisplay, "npchighlight")
		createcheckbox("NPC Nametag", scrolldisplay, "npcnametag")
		createcheckbox("NPC Cursor Line", scrolldisplay, "npccursorline")
		createlabel("Player Options:", scrolldisplay)
		createcheckbox("Player Box", scrolldisplay, "playerbox")
		createcheckbox("Player Bones", scrolldisplay, "playerbones")
		createcheckbox("Player Highlight", scrolldisplay, "playerhighlight")
		createcheckbox("Player Nametag", scrolldisplay, "playernametag")
		createcheckbox("Player Cursor Line", scrolldisplay, "playercursorline")
		createlabel("Highlight Opacity:", scrollsettings)
		createSlider("Highlight Opacity", scrollsettings, "highlight_opacity", 0, 255, 100)
		createlabel("Prop Colors:", scrollsettings)
		createSlider("Red", scrollsettings, "prop_r", 0, 255, 0)
		createSlider("Green", scrollsettings, "prop_g", 0, 255, 255)
		createSlider("Blue", scrollsettings, "prop_b", 0, 255, 255)
		createlabel("NPC Colors:", scrollsettings)
		createSlider("Red", scrollsettings, "npc_r", 0, 255, 255)
		createSlider("Green", scrollsettings, "npc_g", 0, 255, 0)
		createSlider("Blue", scrollsettings, "npc_b", 0, 255, 0)
		createlabel("Player Colors:", scrollsettings)
		createSlider("Red", scrollsettings, "player_r", 0, 255, 255)
		createSlider("Green", scrollsettings, "player_g", 0, 255, 255)
		createSlider("Blue", scrollsettings, "player_b", 0, 255, 0)
		createlabel("Player Gestures:", scrollact)
		local grid = vgui.Create("DIconLayout", scrollact)
		grid:Dock(TOP)
		grid:SetSpaceX(5)
		grid:SetSpaceY(5)
		grid:CenterHorizontal()
		grid:DockMargin(10, 5, 0, 0)
		for _, act in ipairs(actList) do
			local button = grid:Add("DButton")
			button:SetText(act:sub(1,1):upper() .. act:sub(2):lower())
			button:SetSize(60, 30)
			button.DoClick = function()
				RunConsoleCommand("act", act)
			end
		end
		tab:AddSheet("Utility", scrollutility, "icon16/wrench.png")
		tab:AddSheet("Display", scrolldisplay, "icon16/monitor.png")
		tab:AddSheet("Act", scrollact, "icon16/user.png")
		tab:AddSheet("Settings", scrollsettings, "icon16/cog.png")
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