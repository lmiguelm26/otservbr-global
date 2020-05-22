local function givePlayerItem(player, item, slot)
	local ret = player:addItemEx(item, false, sot)
	if not ret then
		player:addItemEx(item, false, INDEX_WHEREEVER, 0)
	end
end

local function getFirstItems(player)
	local firstItems = {
		slots = {
			[CONST_SLOT_HEAD] = Game.createItem(2461),
			[CONST_SLOT_ARMOR] = Game.createItem(2651),
			[CONST_SLOT_LEGS] = Game.createItem(2649),
			[CONST_SLOT_FEET] = Game.createItem(2643)
		}
	}

	for slot, item in pairs(firstItems.slots) do
		givePlayerItem(player, item, slot)
	end
end

local function removeItems(player)
	local itemIds = {
		{id = 2379},
		{id = 2456},
		{id = 2512},
		{id = 23719},
		{id = 23721},
		{id = 23771}
	}
	for i = 1, #itemIds do
		if player:removeItem(itemIds[i].id, 1) then
			player:removeItem(itemIds[i].id, 1)
		end
	end
end

local dawnportVocationTrial = MoveEvent()

function dawnportVocationTrial.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	local vocation = DawnportTable[item.actionid]
	if vocation then
		local getVocation = player:getVocation()
		if getVocation and getVocation:getId() == vocation.first.id or getVocation:getId() == vocation.second.id then
			return true
		end

		local centerPosition = Position(32065, 31891, 5)
		if centerPosition:getDistance(fromPosition) < centerPosition:getDistance(position) then
			if player:getLevel() <= 7 then
				player:setVocation(Vocation(vocation.first.id))
			elseif player:getLevel() >= 8 then
				player:setVocation(Vocation(vocation.second.id))
			end
			if player:getSex() == PLAYERSEX_MALE then
				player:setOutfit({
					lookBody = vocation.outfit.lookBody,
					lookAddons = vocation.outfit.lookAddons,
					lookTypeName = vocation.outfit.lookTypeName,
					lookType = vocation.outfit.lookTypeEx,
					lookHead = vocation.outfit.lookHead,
					lookMount = vocation.outfit.lookMount,
					lookLegs = vocation.outfit.lookLegs,
					lookFeet = vocation.outfit.lookFeet
				})
			else
				player:setOutfit({
					lookBody = vocation.outfit.lookBody,
					lookAddons = vocation.outfit.lookAddons,
					lookTypeName = vocation.outfit.lookTypeName,
					lookType = vocation.outfit.lookTypeFm,
					lookHead = vocation.outfit.lookHead,
					lookMount = vocation.outfit.lookMount,
					lookLegs = vocation.outfit.lookLegs,
					lookFeet = vocation.outfit.lookFeet
				})
			end
			if getVocation and getVocation:getId() == VOCATION.ID.NONE then
				player:sendTutorial(vocation.tutorial)
				getFirstItems(player)
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "As this is the first time you try out a vocation, the Guild has kitted you out. " .. vocation.firstMessage)
			elseif player:getStorageValue(vocation.storage) == -1 and getVocation:getId() ~= VOCATION.ID.NONE then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("As this is your first time as a \z
				".. vocation.name ..', you received a few extra items. ' .. vocation.firstMessage))
				player:setStorageValue(vocation.storage, 1)
				player:sendTutorial(vocation.tutorial)
			elseif player:getStorageValue(vocation.storage) >= 1 then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You have received the weapons of a \z
				".. vocation.name ..', you received a few extra items. ' .. vocation.firstMessage))
			end
			removeItems(player)

			for i = 1, #vocation.skills do
				if player:getMagicLevel() ~= nil then
					if player:getMagicLevel() > vocation.limits[1] then
						local resultId = db.storeQuery("SELECT `id` FROM `players` WHERE `name` = \z
						" .. db.escapeString(player:getName():lower()))
						local accountId = result.getDataInt(resultId, "id")
						player:remove()
						db.query("UPDATE `players` SET `maglevel` = '0', `manaspent` = '0', `skill_fist` = '10', \z
						`skill_fist_tries` = '0', `skill_club` = '10', `skill_club_tries` = '0', `skill_sword` = '10', \z
						`skill_sword_tries` = '0', `skill_axe` = '10', `skill_axe_tries` = '0', `skill_dist` = '10', \z
						`skill_dist_tries` = '0', `skill_shielding` = '10', `skill_shielding_tries` = '0', \z
						`skill_fishing` = '10', `skill_fishing_tries` = '0' WHERE `players`.`id` = " .. accountId)
						return true
					end
				end

				if player:getSkillLevel(vocation.skills[i]) > vocation.limits[2] then
					local resultId = db.storeQuery("SELECT `id` FROM `players` WHERE `name` = \z
					" .. db.escapeString(player:getName():lower()))
					local accountId = result.getDataInt(resultId, "id")
					player:remove()
					db.query("UPDATE `players` SET `maglevel` = '0', `manaspent` = '0', `skill_fist` = '10', \z
					`skill_fist_tries` = '0', `skill_club` = '10', `skill_club_tries` = '0', `skill_sword` = '10', \z
					`skill_sword_tries` = '0', `skill_axe` = '10', `skill_axe_tries` = '0', `skill_dist` = '10', \z
					`skill_dist_tries` = '0', `skill_shielding` = '10', `skill_shielding_tries` = '0', \z
					`skill_fishing` = '10', `skill_fishing_tries` = '0' WHERE `players`.`id` = " .. accountId)
					return true
				end
			end

			local backpack = player:getSlotItem(CONST_SLOT_BACKPACK)
			for slot, info in pairs(vocation.items) do
				local extra
				if slot > CONST_SLOT_AMMO then
					extra = true
				else
					local equipped = player:getSlotItem(slot)
					if equipped then
						equipped:moveTo(backpack)
					end
				end

				local giveItem = true
				if info.limit and info.limitStorage then
					local given = math.max(player:getStorageValue(info.limitStorage), 0)
					if given >= info.limit then
						giveItem = false
					else
						player:setStorageValue(info.limitStorage, given + 1)
					end
				end

				if giveItem then
					if extra then
						player:addItemEx(Game.createItem(info[1], info[2]), false, INDEX_WHEREEVER, 0)
					else
						local ret = player:addItem(info[1], info[2], false, 1, slot)
						if not ret then
							player:addItemEx(Game.createItem(info[1], info[2]), false, slot)
						end
					end
				end
			end

			-- Set town from tutorial island to dawnport (Oressa temple)
			if player:getTown() == Town(TOWNS_LIST.DAWNPORT_TUTORIAL) then
				player:setTown(Town(TOWNS_LIST.DAWNPORT))
			end
			player:getPosition():sendMagicEffect(CONST_ME_BLOCKHIT)
		end
	end
	return true
end

for key = 40001, 40004 do
	dawnportVocationTrial:aid(key)
end

dawnportVocationTrial:register()