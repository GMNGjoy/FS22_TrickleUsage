--[[
    Author: GMNGjoy
    Mod name: Trickle Usage
    Version: 1.0.0.0
    Date: July 2024
    Contact: http://modding.gmngjoy.com
    Discord: @gmngjoy
]]

TrickleUsage = {
    _modDirectory = g_currentModDirectory,
    _modName = g_currentModName,
    showDebug = false,
    seedScale = 0.5,
    sprayScale = 0.25,
}

function TrickleUsage:init()
    TrickleUsage.readSettings()
end

function TrickleUsage:resetFlag()
    for k, vehicle in pairs(g_currentMission.vehicles) do
        if vehicle and vehicle.trickle_set then
            vehicle.trickle_set = false
        end
    end
end

function TrickleUsage:isTractor(vehicle)
    return vehicle.typeName == "tractor"
end


function TrickleUsage:update(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    for k, vehicle in pairs(g_currentMission.vehicles) do
        if vehicle and not vehicle.trickle_set then
            if type(vehicle) == "table" and vehicle.rootVehicle and not self:isTractor(vehicle) then
                if SpecializationUtil.hasSpecialization(SowingMachine, vehicle.specializations) and vehicle.spec_sowingMachine then
                    vehicle.trickle_set = true
                    vehicle.spec_sowingMachine.seedUsageScale = self.seedScale

                    if TrickleUsage.showDebug then
                        printf("]] ---- vehicle: %s", vehicle:getName())
                        printf("]  ----    type: %s", vehicle.typeName)
                        printf("]  -- seedusage: %s", vehicle.spec_sowingMachine.seedUsageScale)
                    else
                        printf("[TrickleUsage] Vehicle: %s | Udated seed usage: %s", vehicle.rootVehicle:getName(), self.seedScale)
                    end
                end

                if SpecializationUtil.hasSpecialization(Sprayer, vehicle.specializations) and vehicle.spec_sprayer then
                    vehicle.trickle_set = true
                    vehicle.spec_sprayer.usageScale.default = self.sprayScale

                    if TrickleUsage.showDebug then
                        printf("]] ---- vehicle: %s", vehicle.i3dFilename)
                        printf("]  ----    type: %s", vehicle.typeName)
                        printf("]  - sprayusage: %s", vehicle.spec_sprayer.usageScale.default)
                    else
                        printf("[TrickleUsage] Vehicle: %s | Updated sprayer usage: %s", vehicle:getName(), self.sprayScale)
                    end
                end
            end
        end
    end
end

-- initialize the mod by reading / creating the settings file
FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents, TrickleUsage.init);

-- setup the listener
addModEventListener(TrickleUsage);


