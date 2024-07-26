TrickleUsage.SETTINGS = {}
TrickleUsage.CONTROLS = {}

TrickleUsage.menuItems = {
	'seedScale',
	'sprayScale',
}

TrickleUsage.SETTINGS.seedScale = {
	['default'] = 0.5,
	['values'] = {0.05, 0.10, 0.15, 0.2, 0.25, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 2.0},
	['strings'] = {
		"5%",
		"10%",
		"15%",
		"20%",
		"25%",
		"30%",
		"40%",
		"50%",
		"60%",
		"70%",
		"80%",
		"90%",
		"100% (".. g_i18n:getText("configuration_valueDefault") ..")",
		"110%",
		"120%",
		"130%",
		"140%",
		"150%",
        "200%"
	}
}

TrickleUsage.SETTINGS.sprayScale = {
	['default'] = 0.25,
	['values'] = {0.05, 0.10, 0.15, 0.2, 0.25, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 2.0},
	['strings'] = {
		"5%",
		"10%",
		"15%",
		"20%",
		"25%",
		"30%",
		"40%",
		"50%",
		"60%",
		"70%",
		"80%",
		"90%",
		"100% (".. g_i18n:getText("configuration_valueDefault") ..")",
		"110%",
		"120%",
		"130%",
		"140%",
		"150%",
        "200%"
	}
}

-- HELPER FUNCTIONS
function TrickleUsage.setValue(id, value)
	TrickleUsage[id] = value
end

function TrickleUsage.getValue(id)
	return TrickleUsage[id]
end

function TrickleUsage.getStateIndex(id, value)
	local value = value or TrickleUsage.getValue(id)
	local values = TrickleUsage.SETTINGS[id].values
	if type(value) == 'number' then
		local index = TrickleUsage.SETTINGS[id].default
		local initialdiff = math.huge
		for i, v in pairs(values) do
			local currentdiff = math.abs(v - value)
			if currentdiff < initialdiff then
				initialdiff = currentdiff
				index = i
			end
		end
		return index
	else
		for i, v in pairs(values) do
			if value == v then
				return i
			end
		end
	end
	print(id .. " USING DEFAULT")
	return TrickleUsage.SETTINGS[id].default
end

-- READ/WRITE SETTINGS
function TrickleUsage.writeSettings()

	if not g_currentMission.missionInfo or not g_currentMission.missionInfo.savegameDirectory then
		return
	end

	local key = "trickleUsage"
	local userSettingsFile = g_currentMission.missionInfo.savegameDirectory .. "/TrickleUsage.xml"
	-- local userSettingsFile = Utils.getFilename("modSettings/TrickleUsage.xml", getUserProfileAppPath())

	local xmlFile = createXMLFile("settings", userSettingsFile, key)
	if xmlFile ~= 0 then

		local function setXmlValue(id)

			if TrickleUsage.SETTINGS[id].serverOnly and g_server == nil then
				return
			end

			local xmlValueKey = "trickleUsage." .. id .. "#value"
			local value = TrickleUsage.getValue(id)
			if type(value) == 'number' then
				setXMLFloat(xmlFile, xmlValueKey, value)
			elseif type(value) == 'boolean' then
				setXMLBool(xmlFile, xmlValueKey, value)
			end
		end

		for _, id in pairs(TrickleUsage.menuItems) do
			setXmlValue(id)
		end

		saveXMLFile(xmlFile)
		delete(xmlFile)
		TrickleUsage:resetFlag()
	end
end

function TrickleUsage.readSettings()

	if not g_currentMission.missionInfo or not g_currentMission.missionInfo.savegameDirectory then
		return
	end

	local userSettingsFile = g_currentMission.missionInfo.savegameDirectory .. "/TrickleUsage.xml"

	if not fileExists(userSettingsFile) then
		print("CREATING user settings file: "..userSettingsFile)
		TrickleUsage.writeSettings()
		return
	end

	local xmlFile = loadXMLFile("trickleUsage", userSettingsFile)
	if xmlFile ~= 0 then

		local function getXmlValue(id)
			local setting = TrickleUsage.SETTINGS[id]
			if setting then
				local xmlValueKey = "trickleUsage." .. id .. "#value"
				local value = TrickleUsage.getValue(id)
				if hasXMLProperty(xmlFile, xmlValueKey) then

					if type(value) == 'number' then
						value = getXMLFloat(xmlFile, xmlValueKey) or value
					elseif type(value) == 'boolean' then
						value = getXMLBool(xmlFile, xmlValueKey) or false
					end

					if g_server == nil and type(value) == 'number' then
						-- print("CLIENT - restrict to closest value")
						value = setting.values[TrickleUsage.getStateIndex(id, value)]
					end
					TrickleUsage.setValue(id, value)

				end
			end
		end

		print("TrickleUsage SETTINGS")
		for _, id in pairs(TrickleUsage.menuItems) do
			getXmlValue(id)
			print("  " .. tostring(id) .. ": " .. tostring(TrickleUsage[id]))
		end

		delete(xmlFile)
	end

end

function TrickleUsage:onMenuOptionChanged(state, menuOption)

	local id = menuOption.id
	local setting = TrickleUsage.SETTINGS
	local value = setting[id].values[state]

	if value ~= nil then
		TrickleUsage.setValue(id, value)
	end

	TrickleUsage.writeSettings()
end

-- APPEND GERNERAL MAIN MENU SETTINGS PAGE
local inGameMenu = g_gui.screenControllers[InGameMenu]
local settingsGeneral = inGameMenu.pageSettingsGeneral
function TrickleUsage.addMenuOption(id)

	local callback = "onMenuOptionChanged"
	local i18n_title = "setting_trickleUsage_" .. id
	local i18n_tooltip = "toolTip_trickleUsage_" .. id
	local options = TrickleUsage.SETTINGS[id].strings

	local original = settingsGeneral.checkAutoHelp
	local menuOption = original:clone(settingsGeneral.boxLayout)
	menuOption.target = TrickleUsage
	menuOption.id = id

	menuOption:setCallback("onClickCallback", callback)
	menuOption:setDisabled(false)

	local setting = menuOption.elements[4]
	local toolTip = menuOption.elements[6]

	setting:setText(g_i18n:getText(i18n_title))
	toolTip:setText(g_i18n:getText(i18n_tooltip))
	menuOption:setTexts({unpack(options)})
	menuOption:setState(TrickleUsage.getStateIndex(id))

	TrickleUsage.CONTROLS[id] = menuOption

	return menuOption
end

local title = TextElement.new()
title:applyProfile("settingsMenuSubtitle", true)
title:setText(g_i18n:getText("menu_trickleUsage_TITLE"))
settingsGeneral.boxLayout:addElement(title)
for _, id in pairs(TrickleUsage.menuItems) do
	TrickleUsage.addMenuOption(id)
end
settingsGeneral.boxLayout:invalidateLayout()


--ENABLE/DISABLE OPTIONS FOR CLIENTS
InGameMenuGeneralSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuGeneralSettingsFrame.onFrameOpen, function()

	local isAdmin = g_currentMission:getIsServer() or g_currentMission.isMasterUser

	for _, id in pairs(TrickleUsage.menuItems) do

		local menuOption = TrickleUsage.CONTROLS[id]
		menuOption:setState(TrickleUsage.getStateIndex(id))

		if TrickleUsage.SETTINGS[id].disabled then
			menuOption:setDisabled(true)
		elseif TrickleUsage.SETTINGS[id].serverOnly and g_server == nil then
			menuOption:setDisabled(not isAdmin)
		else

			local permission = TrickleUsage.SETTINGS[id].permission
			local hasPermission = g_currentMission:getHasPlayerPermission(permission)

			local canChange = isAdmin or hasPermission or false
			menuOption:setDisabled(not canChange)

		end

	end

end)

-- hook into the savegame controller to make sure the TrickleUsage.xml file gets written.
SavegameController.onSaveComplete = Utils.appendedFunction(SavegameController.onSaveComplete, TrickleUsage.writeSettings)