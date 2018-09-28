
local GUI_ID_MagicMenu_spells_list = tes3ui.registerID("MagicMenu_spells_list")
local GUI_ID_MenuMagic = tes3ui.registerID("MenuMagic")

local GUI_ID_UIEXP_MagicMenu_SchoolFilters = tes3ui.registerID("UIEXP_MagicMenu_SchoolFilters")

local common = require("UI Expansion.common")

----------------------------------------------------------------------------------------------------
-- Spell List: Filtering and Searching
----------------------------------------------------------------------------------------------------

local function searchSubList(titleElement, listElement, isSpellFilter)
	-- Gather a list of all the columns/rows so we don't have to keep creating tables later.
	local columnElements = {}
	for i, element in ipairs(listElement.children) do
		table.insert(columnElements, element.children)
	end

	-- Go through and compare each element in listElement to our filter.
	local matchCount = 0
	for i, nameElement in ipairs(columnElements[1]) do
		local filterObject = nameElement:getPropertyObject(isSpellFilter and "MagicMenu_Spell" or "MagicMenu_object")
		local filter = common.magicFilter:triggerFilter({ text = filterObject.name, effects = (isSpellFilter and filterObject.effects or filterObject.enchantment.effects) })
		
		if (filter) then
			matchCount = matchCount + 1
		end

		-- If we don't have a first hit already, set it now.
		if (isSpellFilter and firstSearchResult == nil and filter) then
			firstSearchResult = nameElement
		end

		-- If the state changed, change the element visibility in all columns.
		if (filter ~= nameElement.visible) then
			for _, column in ipairs(columnElements) do
				column[i].visible = filter
			end
		end
	end

	-- Hide associated elements if there aren't any results.
	if (matchCount > 0) then
		titleElement.visible = true
		listElement.visible = true
		return true
	else
		titleElement.visible = false
		listElement.visible = false
		return false
	end
end

local function searchSpellsList()
	-- Filter all of our sub groups.
	local elements = tes3ui.findMenu(GUI_ID_MenuMagic):findChild(GUI_ID_MagicMenu_spells_list).widget.contentPane.children
	local hasMatchingPowers = searchSubList(elements[1], elements[2], true)
	local hasMatchingSpells = searchSubList(elements[4], elements[5], true)
	local hasMatchingItems = searchSubList(elements[7], elements[8], false)

	-- Figure out dividers.
	elements[3].visible = (hasMatchingPowers and hasMatchingSpells)
	elements[6].visible = (hasMatchingSpells and hasMatchingItems or (not hasMatchingSpells and hasMatchingPowers and hasMatchingItems))
	
	if (spellsListSearchText and common.config.selectSpellsOnSearch and firstSearchResult) then
		firstSearchResult:triggerEvent("mouseClick")
	end
end

local magicFilters = common.createFilterInterface({
	createSearchBar = true,
	createIcons = true,
	createButtons = false,
	useIcons = true,
	onFilterChanged = searchSpellsList,
})
common.magicFilter = magicFilters

local function getEffectsContainsSchool(effects, school)
	for i = 1, #effects do
		if (effects[i].object.school == school) then
			return true
		end
	end
	return false
end

magicFilters:addFilter({
	key = "alteration",
	callback = function(e) return getEffectsContainsSchool(e.effects, tes3.magicSchool.alteration) end,
	tooltip = {
		text = "Filter to alteration effects",
		helpText = {
			"Click to filter to spells, powers, or items that use alteration effects.",
		},
	},
	icon = "icons/ui_exp/magic_alteration.tga",
})

magicFilters:addFilter({
	key = "conjuration",
	callback = function(e) return getEffectsContainsSchool(e.effects, tes3.magicSchool.conjuration) end,
	tooltip = {
		text = "Filter to conjuration effects",
		helpText = {
			"Click to filter to spells, powers, or items that use conjuration effects.",
		},
	},
	icon = "icons/ui_exp/magic_conjuration.tga",
})

magicFilters:addFilter({
	key = "destruction",
	callback = function(e) return getEffectsContainsSchool(e.effects, tes3.magicSchool.destruction) end,
	tooltip = {
		text = "Filter to destruction effects",
		helpText = {
			"Click to filter to spells, powers, or items that use destruction effects.",
		},
	},
	icon = "icons/ui_exp/magic_destruction.tga",
})

magicFilters:addFilter({
	key = "illusion",
	callback = function(e) return getEffectsContainsSchool(e.effects, tes3.magicSchool.illusion) end,
	tooltip = {
		text = "Filter to illusion effects",
		helpText = {
			"Click to filter to spells, powers, or items that use illusion effects.",
		},
	},
	icon = "icons/ui_exp/magic_illusion.tga",
})

magicFilters:addFilter({
	key = "mysticism",
	callback = function(e) return getEffectsContainsSchool(e.effects, tes3.magicSchool.mysticism) end,
	tooltip = {
		text = "Filter to mysticism effects",
		helpText = {
			"Click to filter to spells, powers, or items that use mysticism effects.",
		},
	},
	icon = "icons/ui_exp/magic_mysticism.tga",
})

magicFilters:addFilter({
	key = "restoration",
	callback = function(e) return getEffectsContainsSchool(e.effects, tes3.magicSchool.restoration) end,
	tooltip = {
		text = "Filter to restoration effects",
		helpText = {
			"Click to filter to spells, powers, or items that use restoration effects.",
		},
	},
	icon = "icons/ui_exp/magic_restoration.tga",
})

local function onMenuMagicActivated(e)
	if (not e.newlyCreated) then
		return
	end

	local spellsList = e.element:findChild(GUI_ID_MagicMenu_spells_list)

	-- Make the parent block order from top to bottom.
	local spellsListParent = spellsList.parent
	spellsListParent.flowDirection = "top_to_bottom"

	-- Make a consistent container and move it to the top of the block.
	local filterBlock = spellsListParent:createBlock({ id = "UIEXP:MagicMenu:FilterBlock" })
	filterBlock.flowDirection = "left_to_right"
	filterBlock.widthProportional = 1.0
	filterBlock.autoHeight = true
	filterBlock.paddingLeft = 4
	filterBlock.paddingRight = 4
	spellsListParent:reorderChildren(0, -1, 1)

	-- Actually create our filter elements.
	magicFilters:createElements(filterBlock)
end
event.register("uiActivated", onMenuMagicActivated, { filter = "MenuMagic" } )

local function onEnterMenuMode(e)
	magicFilters:clearFilter()
	
	if (common.config.autoSelectInput == "Magic") then
		magicFilters:focusSearchBar()
	end
end
event.register("menuEnter", onEnterMenuMode, { filter = "MenuInventory" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuMagic" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuMap" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuStat" })
