if CLIENT then
	local settings = {autobhop = false, propbox = false, npcbox = false, npcnametags = false, npccursorlines = false, playerbox = false, playernametags = false, playercursorlines = false, healthbars = false} local actList = {"dance", "robot", "muscle", "zombie", "agree", "disagree", "cheer", "wave", "laugh", "forward", "group", "halt", "salute", "becon", "bow"} local ply = LocalPlayer() local UtilityMenu

	local function DrawBoundingBox(ent, color, ang) cam.IgnoreZ(true) render.DrawWireframeBox(ent:GetPos(), ang or ent:GetAngles(), ent:OBBMins(), ent:OBBMaxs(), color, true) cam.IgnoreZ(false) end
	local function DrawNameTag(ent, name, color) local pos = (ent:EyePos() + Vector(0, 0, 10)):ToScreen() draw.SimpleText(name, "Trebuchet24", pos.x, pos.y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM) end
	local function DrawCursorLines(entities, color, filter) local startPos = ply:GetEyeTrace().HitPos for _, ent in ipairs(entities) do if (not filter or filter(ent)) then render.DrawLine(startPos, ent:EyePos(), color, true) end end end
	local function DrawHealthBar(ent, color)
		local pos = (ent:EyePos() + Vector(0, 0, 10)):ToScreen()
		local health = math.Clamp(ent:Health() / (ent.GetMaxHealth and ent:GetMaxHealth() or 100), 0, 1)
		local w, h = 80, 6
		draw.RoundedBox(8, pos.x - w / 2, pos.y + 8, w, h, Color(0, 0, 0, 180))
		draw.RoundedBox(8, pos.x - w / 2, pos.y + 8, w * health, h, color)
	end
	local function IsAliveAndValid(ent) return ent ~= ply and ent:Alive() end
	local function CreateUtilityMenu() UtilityMenu = vgui.Create("DFrame") UtilityMenu:SetSize(290, 400) UtilityMenu:Center() UtilityMenu:SetTitle("Utility Menu") UtilityMenu:SetVisible(false) UtilityMenu:SetDeleteOnClose(false) local scroll = vgui.Create("DScrollPanel", UtilityMenu) scroll:Dock(FILL) local function AddLabel(text) local lbl = vgui.Create("DLabel", scroll) lbl:SetText(text) lbl:SetFont("DermaDefaultBold") lbl:Dock(TOP) lbl:DockMargin(5, 5, 0, 5) lbl:SizeToContents() end local function AddCheckbox(name, key) local cb = vgui.Create("DCheckBoxLabel", scroll) cb:SetText(name) cb:SetValue(settings[key]) cb:Dock(TOP) cb:DockMargin(5, 0, 0, 5) cb.OnChange = function(_, val) settings[key] = val end cb:SizeToContents() end AddLabel("Utility Options:") for _, opt in ipairs({{"Auto Bhop", "autobhop"}}) do AddCheckbox(opt[1], opt[2]) end AddLabel("Display Options:") for _, opt in ipairs({{"Prop Box", "propbox"}, {"NPC Box", "npcbox"}, {"NPC Name Tags", "npcnametags"}, {"NPC Cursor Lines", "npccursorlines"}, {"Player Box", "playerbox"}, {"Player Name Tags", "playernametags"}, {"Player Cursor Lines", "playercursorlines"}, {"Health Bars", "healthbars"}}) do AddCheckbox(opt[1], opt[2]) end AddLabel("Act Options:") local grid = vgui.Create("DIconLayout", scroll) grid:Dock(TOP) grid:DockMargin(5, 0, 5, 0) grid:SetSpaceX(5) grid:SetSpaceY(5) local bw, bh, spacingX = 50, 30, 5 local buttonsPerRow = math.floor((290 - 10) / (bw + spacingX)) grid:SetTall(math.ceil(#actList / buttonsPerRow) * (bh + spacingX)) for _, act in ipairs(actList) do local btn = grid:Add("DButton") btn:SetSize(bw, bh) btn:SetText(act) btn.DoClick = function() LocalPlayer():ConCommand("act " .. act) end end end

	hook.Add("CreateMove", "AutoBhop", function(cmd) if not settings.autobhop then return end if not LocalPlayer():Alive() then return end if not LocalPlayer():IsOnGround() and cmd:KeyDown(IN_JUMP) then cmd:RemoveKey(IN_JUMP) end end)
	hook.Add("PostDrawOpaqueRenderables", "CustomBox", function() for _, ent in ipairs(ents.GetAll()) do local class = ent:GetClass() if settings.propbox and class:find("^prop_") then DrawBoundingBox(ent, Color(0, 255, 255)) elseif settings.npcbox and class:find("npc_") and ent:Alive() then DrawBoundingBox(ent, Color(255, 0, 0), Angle(0, 0, 0)) end end if settings.playerbox then for _, p in ipairs(player.GetAll()) do if IsAliveAndValid(p) then DrawBoundingBox(p, Color(255, 255, 0), Angle(0, 0, 0)) end end end end)
		hook.Add("HUDPaint", "DrawNameTags", function()
		if settings.npcnametags or settings.healthbars then
			for _, npc in ipairs(ents.FindByClass("npc_*")) do
				if npc:Health() > 0 then
					if settings.npcnametags then
						DrawNameTag(npc, npc.GetName and npc:GetName() or npc:GetClass(), Color(255, 0, 0))
					end
					if settings.healthbars then
						DrawHealthBar(npc, Color(255, 0, 0))
					end
				end
			end
		end
		if settings.playernametags or settings.healthbars then
			for _, p in ipairs(player.GetAll()) do
				if IsAliveAndValid(p) then
					if settings.playernametags then
						DrawNameTag(p, p:Nick(), Color(255, 255, 0))
					end
					if settings.healthbars then
						DrawHealthBar(p, Color(255, 255, 0))
					end
				end
			end
		end
	end)
	hook.Add("PostDrawTranslucentRenderables", "DrawLinesToEntities", function() cam.IgnoreZ(true) if settings.npccursorlines then DrawCursorLines(ents.FindByClass("npc_*"), Color(255, 0, 0), function(npc) return npc:Health() > 0 end) end if settings.playercursorlines then DrawCursorLines(player.GetAll(), Color(255, 255, 0), IsAliveAndValid) end cam.IgnoreZ(false) end)

	CreateUtilityMenu()

	concommand.Add("open_utility_menu", function() UtilityMenu:SetVisible(true) UtilityMenu:MakePopup() end)
end