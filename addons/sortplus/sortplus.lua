local inventoryItems = {}

function GET_INVENTORY_LIST()
    local group = GET_CHILD(ui.GetFrame('inventory'), 'inventoryGbox', 'ui::CGroupBox')
    local tree_box = GET_CHILD(group, 'treeGbox','ui::CGroupBox')
    local tree = GET_CHILD(tree_box, 'inventree','ui::CTreeControl')

    for i = 1 , #SLOTSET_NAMELIST do
        inventoryItems[i] = {}
        local slotSet = GET_CHILD(tree,SLOTSET_NAMELIST[i],'ui::CSlotSet')  
        for j = 0 , slotSet:GetChildCount() - 1 do
            local slot = slotSet:GetChildByIndex(j);
            local invItem = GET_SLOT_ITEM(slot); 
            if invItem ~= nil then
                local invIndex = invItem.invIndex
                local itemCls = GetIES(invItem:GetObject());
                if itemCls ~= nil then
                    inventoryItems[i][invIndex] = {}
                    inventoryItems[i][invIndex].name = dictionary.ReplaceDicIDInCompStr(itemCls.Name)
                    inventoryItems[i][invIndex].slot = slot
                    inventoryItems[i][invIndex].slotset = slotSet
                end
            end
        end
    end
end


function SORT_INVENTORY_BY_NAME()
    GET_INVENTORY_LIST()
    for k,v in pairs(inventoryItems) do
        local lowestIndex = 9999999
        local highestIndex = 0

        for i,j in pairs(inventoryItems[k]) do
            if lowestIndex > i then
                lowestIndex = i
            end
            if highestIndex < i then
                highestIndex = i
            end
        end
        local slotset = inventoryItems[k][lowestIndex].slotset
        for count = lowestIndex,highestIndex do
            slotset = inventoryItems[k][lowestIndex].slotset
            GET_INVENTORY_LIST()
            lowestItem = FIND_LOWEST_ITEM(inventoryItems[k],count,highestIndex)
            SWAP_ITEMS_(slotset,count,lowestItem)
        end

    end

end

function FIND_LOWEST_ITEM(invItemSort,lowestIndex,highestIndex)
    firstItem = {'~',0}
    for i = lowestIndex,highestIndex do
        if firstItem[1] > invItemSort[i].name then
            firstItem[1] = invItemSort[i].name
            firstItem[2] = i
        end

    end
    return firstItem[2]
end


function SWAP_ITEMS_(parentSlotSet,fromInvIndex,toInvIndex)
    toFrame = parentSlotSet:GetTopParentFrame();
    local fromSlotIndex = GET_SLOT_INDEX_BY_INVINDEX(parentSlotSet, fromInvIndex);
    local toSlotIndex = GET_SLOT_INDEX_BY_INVINDEX(parentSlotSet, toInvIndex);

    item.SwapSlotIndex(IT_INVENTORY, fromInvIndex, toInvIndex);
    ON_CHANGE_INVINDEX(toFrame, nil, fromInvIndex, toInvIndex);

    parentSlotSet:SwapSlot(fromSlotIndex, toSlotIndex, "ONUPDATE_SLOT_INVINDEX");
    QUICKSLOT_ON_CHANGE_INVINDEX(fromInvIndex, toInvIndex);
end
