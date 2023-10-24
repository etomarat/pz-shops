require "shop-window"
local _internal = require "shop-shared"

local CONTEXT_HANDLER = {}

---@param worldObject IsoObject
function CONTEXT_HANDLER.browseStore(worldObjects, playerObj, worldObject, storeObj, ignoreCapacityCheck)
    if not storeObj then
        if not (_internal.isAdminHostDebug()) then print(" ERROR: non-admin accessed context menu meant for assigning shops.") return end
    end
    storeWindow:onBrowse(storeObj, worldObject, playerObj, ignoreCapacityCheck)
end


function CONTEXT_HANDLER.generateContextMenu(playerID, context, worldObjects)
    local playerObj = getSpecificPlayer(playerID)
    local square

    for _,v in ipairs(worldObjects) do square = v:getSquare() end
    if not square then return end

    if (math.abs(playerObj:getX()-square:getX())>2) or (math.abs(playerObj:getY()-square:getY())>2) then return end

    local validObjects = {}
    local validObjectCount = 0

    for i=0,square:getObjects():size()-1 do
        ---@type IsoObject
        local object = square:getObjects():get(i)
        if object and (not instanceof(object, "IsoWorldInventoryObject")) then

            local objStoreID = object:getModData().storeObjID
            if objStoreID then
                local storeObj = CLIENT_STORES[objStoreID]
                if not storeObj then
                    local x, y, z, worldObjName = self.worldObject:getX(), self.worldObject:getY(), self.worldObject:getZ(), _internal.getWorldObjectName(self.worldObject)
                    sendClientCommand("shop", "checkMapObject", { storeID=objStoreID, x=x, y=y, z=z, worldObjName=worldObjName })
                end
            end

            if object:getModData().storeObjID or (_internal.isAdminHostDebug()) then
                validObjects[object] = CLIENT_STORES[object:getModData().storeObjID] or false
                validObjectCount = validObjectCount+1
            end
        end
    end

    local currentMenu = context
    if validObjectCount > 0 then
        if validObjectCount>1 then
            local mainMenu = context:addOptionOnTop(getText("ContextMenu_STORES"), worldObjects, nil)
            local subMenu = ISContextMenu:getNew(context)
            context:addSubMenu(mainMenu, subMenu)
            currentMenu = subMenu
        end

        for worldObject,storeObject in pairs(validObjects) do
            local objectName = _internal.getWorldObjectDisplayName(worldObject)
            if objectName then
                local contextText = objectName.." [ "..getText("ContextMenu_ASSIGN_STORE").." ]"
                if storeObject then
                    contextText = getText("ContextMenu_SHOP_AT").." "..(storeObject.name or objectName)
                end

                local option = currentMenu:addOptionOnTop(contextText, worldObjects, CONTEXT_HANDLER.browseStore, playerObj, worldObject, storeObject, true)
                if isClient() and option and storeObject then
                    if not storeWindow.checkMaxShopperCapacity(storeObject, worldObject, playerObj) then
                        option.notAvailable = true
                        local tooltip = ISWorldObjectContextMenu.addToolTip()
                        local text = getText("IGUI_CURRENTLY_IN_USE")
                        tooltip:setName(text)
                        tooltip.description = text
                        option.tooltip = tooltip
                    end
                end
            end
        end
    end

end
Events.OnFillWorldObjectContextMenu.Add(CONTEXT_HANDLER.generateContextMenu)