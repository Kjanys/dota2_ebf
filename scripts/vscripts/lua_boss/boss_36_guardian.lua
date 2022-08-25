function create_shield_particle(keys)

	local origin = keys.caster:GetAbsOrigin()
	local size = Vector(300,300,0)
	keys.caster.shield_particle = ParticleManager:CreateParticle("particles/demon_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW  , keys.caster)
    ParticleManager:SetParticleControl(keys.caster.shield_particle, 0, origin)
    ParticleManager:SetParticleControl(keys.caster.shield_particle, 1, size)
    ParticleManager:SetParticleControl(keys.caster.shield_particle, 6, origin)
    ParticleManager:SetParticleControl(keys.caster.shield_particle, 10, origin)
end

function creation(keys)
	local caster = keys.caster
	caster.Charge = 1000
	caster.weak = false
	create_shield_particle(keys)
	keys.ability:ApplyDataDrivenModifier( caster, caster, "invincible", {} )
    caster.have_shield = true

	Timers:CreateTimer( 0.03, function()
		if caster:IsAlive() == true then
			caster:SetMana(caster.Charge)
			return 0.03
		end
	end)

    if GetMapName() == "epic_boss_fight_impossible" then
        caster:SetMaxHealth(100000000) 
    elseif GetMapName() == "epic_boss_fight_challenger" then
        caster:SetMaxHealth(15000000) 
    elseif  GetMapName() == "epic_boss_fight_hard" then
        caster:SetMaxHealth(60000000) 
    elseif GetMapName() == "epic_boss_fight_boss_master" then
        caster:SetMaxHealth(4000000) 
    else
        caster:SetMaxHealth(3000000) 
    end


    --local difficulty_multiplier = (PlayerResource:GetTeamPlayerCount() / 7)^0.2 --tester
	local difficulty_multiplier = (TeamCount() / 7)^0.2
    caster.MaxEHP = difficulty_multiplier*caster:GetMaxHealth()
    
    caster:SetBaseDamageMin(difficulty_multiplier*caster:GetBaseDamageMin())
    caster:SetBaseDamageMax(difficulty_multiplier*caster:GetBaseDamageMax())
    caster:SetPhysicalArmorBaseValue(difficulty_multiplier*caster:GetPhysicalArmorBaseValue())
    caster.EHP_MULT = 1 
    caster:SetMaxHealth(200000)
        caster:SetHealth(200000)
        local EHP_MULT = (caster.MaxEHP/200000)
        caster.EHP_MULT = EHP_MULT
        caster:SetBaseHealthRegen(caster:GetBaseHealthRegen()/EHP_MULT)
        caster:AddNewModifier(caster, caster, "bossHealthRescale",{})

    Timers:CreateTimer( 0.1, function()
        
	
		if caster:IsAlive() == true then
			if caster.weak == false then
				if caster.Charge <= 0 then
					caster.weak = true
					caster.Charge = 0
					ParticleManager:DestroyParticle( caster.shield_particle, true)
					caster:RemoveModifierByName( "invincible" )
                    caster.have_shield = false
				else
					caster.Charge = caster.Charge - 5
				end
			else
				if caster.Charge < caster:GetMaxMana() then
					caster.Charge = caster.Charge + 10
				else
					caster.weak = false
                    caster.have_shield = true
					create_shield_particle(keys)
					keys.ability:ApplyDataDrivenModifier( caster, caster, "invincible", {} )
				end
			end
			return 0.1
		end
	end)
end


function flaming_fist(keys)

    -- Inheritted variables
    local caster = keys.caster
    caster.Charge = caster.Charge - 200
	if caster.Charge < 0 then caster.Charge = 0 end
    local targetPoint = keys.target_points[1]
    local ability = keys.ability
    local radius = 1000
    local attack_interval = 0.05
    local casterModifierName = "modifier_sleight_of_fist_caster_datadriven"
    local particleSlashName = "particles/units/heroes/hero_ember_spirit/ember_spirit_sleightoffist_tgt.vpcf"
    local particleTrailName = "particles/units/heroes/hero_ember_spirit/ember_spirit_sleightoffist_trail.vpcf"
    local slashSound = "Hero_EmberSpirit.SleightOfFist.Damage"
    
    -- Targeting variables
    local targetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
    local targetType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
    local targetFlag = DOTA_UNIT_TARGET_FLAG_NO_INVIS
    local unitOrder = FIND_ANY_ORDER
    
    -- Necessary varaibles
    local counter = 0
    caster.sleight_of_fist_active = true
    local origin = caster:GetAbsOrigin()
    
    local units = FindUnitsInRadius(
        caster:GetTeamNumber(), targetPoint, caster, radius, targetTeam,
        targetType, targetFlag, unitOrder, false
    )
    
    for _, target in pairs( units ) do
        counter = counter + 1
        Timers:CreateTimer( counter * attack_interval, function()
                -- Only jump to it if it's alive
                if target:IsAlive() then
                    -- Create trail particles
                    local trailFxIndex = ParticleManager:CreateParticle( particleTrailName, PATTACH_CUSTOMORIGIN, target )
                    ParticleManager:SetParticleControl( trailFxIndex, 0, target:GetAbsOrigin() )
                    ParticleManager:SetParticleControl( trailFxIndex, 1, caster:GetAbsOrigin() )
                    
                    Timers:CreateTimer( 0.1, function()
                            ParticleManager:DestroyParticle( trailFxIndex, false )
                            ParticleManager:ReleaseParticleIndex( trailFxIndex )
                            return nil
                        end
                    )
                    
                    -- Move hero there
                    FindClearSpaceForUnit( caster, target:GetAbsOrigin(), false )
                    
                    caster:PerformAttack( target, true, false, true, false )
                    
                    -- Slash particles
                    local slashFxIndex = ParticleManager:CreateParticle( particleSlashName, PATTACH_ABSORIGIN_FOLLOW, target )
                    StartSoundEvent( slashSound, caster )
                    
                    Timers:CreateTimer( 0.1, function()
                            ParticleManager:DestroyParticle( slashFxIndex, false )
                            ParticleManager:ReleaseParticleIndex( slashFxIndex )
                            StopSoundEvent( slashSound, caster )
                            return nil
                        end
                    )
                    
                end
                return nil
            end
        )
    end
    
    -- Return caster to origin position
    Timers:CreateTimer( ( counter + 1 ) * attack_interval, function()
            FindClearSpaceForUnit( caster, origin, false )
            caster:RemoveModifierByName( casterModifierName )
            caster.sleight_of_fist_active = false
            return nil
        end
    )
end

function hell_on_earth(keys)
	local caster = keys.caster
    keys.ability:StartCooldown(5)
	caster.Charge = caster.Charge - 50
	local damage = 100000
	
	if caster.Charge < 0 then caster.Charge = 0 end
	local created_projectile = 0
	local fv = caster:GetForwardVector()
	local rv = caster:GetRightVector()
	local origin = caster:GetAbsOrigin()
	local total_projectile = 120
	local distance = 1500
	local position = origin + fv*distance
	local shift = -8
	if caster.hell_grow == nil then caster.hell_grow = false end

	if caster.hell_grow == true then
		caster.hell_grow = false
		distance = 0
		position = origin
		shift = 8
	else
		caster.hell_grow = true
	end

    Timers:CreateTimer(0.09, function()
        created_projectile = created_projectile + 1
        createAOEDamage(keys,"particles/doom_ring.vpcf",position,250,damage,DAMAGE_TYPE_MAGICAL,2.1,"soundevents/game_sounds_heroes/game_sounds_nevermore.vsndevts",1.5)
        angle = (created_projectile*1200)/total_projectile
       	position = GetGroundPosition(RotatePosition(Vector(0,0,0), QAngle(0,angle,0), fv) * distance + origin,nil)

        distance = distance +shift
        if created_projectile <=total_projectile then
            return 0.09
        end
    end)
end

function createAOEDamage(keys,particlesname,location,size,damage,damage_type,duration,sound,delay)
	if delay == nil then delay = 0 end

    if duration == nil then
        duration = 3
    end
    if damage == nil then
        damage = 5000
    end
    if size == nil then
        size = 250
    end
    if damage_type == nil then
        damage_type = DAMAGE_TYPE_MAGICAL
    end
    if sound ~= nil then
        StartSoundEventFromPosition(sound,location)
    end

    local AOE_effect = ParticleManager:CreateParticle(particlesname, PATTACH_ABSORIGIN  , keys.caster)
    ParticleManager:SetParticleControl(AOE_effect, 0, location)
    ParticleManager:SetParticleControl(AOE_effect, 1, location)
    Timers:CreateTimer(duration,function()
        ParticleManager:DestroyParticle(AOE_effect, true)
    end)
    Timers:CreateTimer(delay, function()
	    local nearbyUnits = FindUnitsInRadius(keys.caster:GetTeam(),
	                                  location,
	                                  nil,
	                                  size,
	                                  DOTA_UNIT_TARGET_TEAM_ENEMY,
	                                  DOTA_UNIT_TARGET_ALL,
	                                  DOTA_UNIT_TARGET_FLAG_NONE,
	                                  FIND_ANY_ORDER,
	                                  false)
        if GetMapName() == "epic_boss_fight_challenger" or GetMapName() == "epic_boss_fight_impossible" then
            nearbyUnits = FindUnitsInRadius(keys.caster:GetTeam(),
                                      location,
                                      nil,
                                      size,
                                      DOTA_UNIT_TARGET_TEAM_ENEMY,
                                      DOTA_UNIT_TARGET_ALL,
                                      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                                      FIND_ANY_ORDER,
                                      false)
        end 
	    for _,unit in pairs(nearbyUnits) do
	        if unit ~= keys.caster then
	                if unit:GetUnitName()~="npc_dota_courier" and unit:GetUnitName()~="npc_dota_flying_courier" then
	                    local damageTableAoe = {victim = unit,
	                                attacker = keys.caster,
	                                damage = damage,
	                                damage_type = damage_type,
	                                }
	                    ApplyDamage(damageTableAoe)
	                end
	        end
	    end
	end)
end