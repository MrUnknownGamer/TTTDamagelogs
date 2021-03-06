
if SERVER then
	Damagelog:EventHook("EntityTakeDamage")
else
	Damagelog:AddFilter("Show damage", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("Team Damage", Color(255, 40, 40))
	Damagelog:AddColor("Damage", Color(0, 0, 0))
end

local event = {}

event.Type = "DMG"
event.IsDamage = true

function event:EntityTakeDamage(ent, dmginfo)

	local att = dmginfo:GetAttacker()
	if not (ent.IsGhost and ent:IsGhost()) and ent:IsPlayer() and (IsValid(att) and att:IsPlayer()) and ent != att then
		local damages = dmginfo:GetDamage()
		if math.floor(damages) > 0 then
			local tbl = { 
				[1] = ent:Nick(), 
				[2] = ent:GetRole(), 
				[3] = att:Nick(), 
				[4] = att:GetRole(), 
				[5] = math.Round(damages), 
				[6] = Damagelog:WeaponFromDmg(dmginfo), 
				[7] = ent:SteamID(), 
				[8] = att:SteamID() 
			}
			if Damagelog:IsTeamkill(tbl[2], tbl[4]) then
				tbl.icon = { "icon16/exclamation.png" }
			elseif Damagelog.Time then
				local found_dmg = false
				for k,v in pairs(Damagelog.DamageTable) do
					if type(v) == "table" and Damagelog.events[v.id] and Damagelog.events[v.id].IsDamage then
						if v.time >= Damagelog.Time - 10 and v.time <= Damagelog.Time then
							found_dmg = true
							break
						end
					end
				end
				if not found_dmg then
					local first
					local shoots = {}
					for k,v in pairs(Damagelog.ShootTables[Damagelog.CurrentRound] or {}) do
						if k >= Damagelog.Time - 10 and k <= Damagelog.Time then
							shoots[k] = v
						end
					end	
					for k,v in pairs(shoots) do
						if not first or k < first  then
							first = k
						end
					end
					if shoots[first] then
						for k,v in pairs(shoots[first]) do
							if v[1] == ent:Nick() then
								tbl.icon = { "icon16/exclamation.png", "The victim may have shot first (see the damage information section for more info)!" }
							end
						end
					end
				end
			end
			self.CallEvent(tbl)
		end
	end
	
end

function event:ToString(tbl)

	local weapon = Damagelog.weapon_table[tbl[6]] or tbl[6]
	local str
	if weapon then
		str = string.format("%s [%s] has damaged %s [%s] for %s HP with %s", tbl[3], Damagelog:StrRole(tbl[4]), tbl[1], Damagelog:StrRole(tbl[2]), tbl[5], weapon) 
	else
		str = string.format("%s [%s] has damaged %s [%s] for %s HP with an unknown weapon", tbl[3], Damagelog:StrRole(tbl[4]), tbl[1], Damagelog:StrRole(tbl[2]), tbl[5]) 
	end
	return str
	
end

function event:IsAllowed(tbl)
	return Damagelog.filter_settings["Show damage"]
end

function event:Highlight(line, tbl, text)
	if table.HasValue(Damagelog.Highlighted, tbl[1]) or table.HasValue(Damagelog.Highlighted, tbl[3]) then
		return true
	end
	return false
end

function event:GetColor(tbl)
	
	if Damagelog:IsTeamkill(tbl[2], tbl[4]) then
		return Damagelog:GetColor("Team Damage")
	else
		return Damagelog:GetColor("Damage")
	end
	
end

function event:RightClick(line, tbl, text)

	line:ShowTooLong(true)
	line:ShowCopy(true, { tbl[3], tbl[8] }, { tbl[1], tbl[7] })
	line:ShowDamageInfos(tbl[3], tbl[1])
	
end

Damagelog:AddEvent(event)
