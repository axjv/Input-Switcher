local inventoryItems = {}
function GET_INVENTORY_LIST()

    inventoryItems = {}
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
                    inventoryItems[i][invIndex].count = GET_REMAIN_INVITEM_COUNT(invItem)
                    inventoryItems[i][invIndex].weight = itemCls.Weight
                    -- print(itemCls.ItemGrade)
                    -- print(i..inventoryItems[i][invIndex].count..inventoryItems[i][invIndex].weight)
                end
            end
        end
    end
end


function SORTFUNC(command)
    local cmd = table.remove(command,1)
    CHAT_SYSTEM('Sort by '..cmd)
    SORT_INVENTORY_BY(cmd)
end

function SORT_INVENTORY_BY(type)
    local invItemSort = {}
    GET_INVENTORY_LIST()
    for k,v in pairs(inventoryItems) do
        local lowestIndex = 9999999
        local highestIndex = 0
        invItemSort = inventoryItems[k]
        for i,j in pairs(invItemSort) do
            if lowestIndex > i then
                if i > 1 then
                    lowestIndex = i
                end
            end
            if highestIndex < i then
                highestIndex = i
            end
        end
        -- print(lowestIndex..' '..highestIndex)
        local slotset = invItemSort[lowestIndex].slotset
        for count = lowestIndex,highestIndex do
            print(count)
            if invItemSort[count] == nil or invItemSort[lowestIndex] == nil then
            else
            -- print(count)
                slotset = invItemSort[lowestIndex].slotset
                -- GET_INVENTORY_LIST()
                invItemSort = inventoryItems[k]
                lowestItem = SORTPLUS_SORTER(invItemSort,count,highestIndex,type)
                if lowestItem ~= nil then
                    SWAP_ITEMS_(slotset,count,lowestItem)
                    local temp = {}
                    temp = invItemSort[lowestItem]
                    invItemSort[lowestItem] = invItemSort[count]
                    invItemSort[count] = temp
                end
            end
        end
    end
end


function SORTPLUS_SORTER(invItemSort,currentIndex,highestIndex,sortType)
    if sortType == 'name' then 
        local firstItem = {'~',0}
        for i = currentIndex,highestIndex do
            -- print(i)
            if invItemSort[i] == nil then
            else
                if firstItem[1] > invItemSort[i].name then
                    firstItem[1] = invItemSort[i].name
                    firstItem[2] = i
                end
            end
        end
        return firstItem[2]
        
    end

    if sortType == 'weight' then 
        local firstItem = {0,0}
        for i = currentIndex,highestIndex do
            if invItemSort[i] == nil then
            else
                local fullWeight = invItemSort[i].weight * invItemSort[i].count
                if firstItem[1] < fullWeight then
                    firstItem[1] = fullWeight
                    firstItem[2] = i
                end
            end
        end
        return firstItem[2]
        -- return firstItem[2]
    end
    
end


function SWAP_ITEMS_(parentSlotSet,fromInvIndex,toInvIndex)
    toFrame = parentSlotSet:GetTopParentFrame();
    local fromSlotIndex = GET_SLOT_INDEX_BY_INVINDEX(parentSlotSet, fromInvIndex);
    local toSlotIndex = GET_SLOT_INDEX_BY_INVINDEX(parentSlotSet, toInvIndex);
    if fromSlotIndex ~= nil and toSlotIndex ~= nil then
        item.SwapSlotIndex(IT_INVENTORY, fromInvIndex, toInvIndex);
        ON_CHANGE_INVINDEX(toFrame, nil, fromInvIndex, toInvIndex);

        parentSlotSet:SwapSlot(fromSlotIndex, toSlotIndex, "ONUPDATE_SLOT_INVINDEX");
        QUICKSLOT_ON_CHANGE_INVINDEX(fromInvIndex, toInvIndex);
    end
end
-- SORTPLUS
GET_INVENTORY_LIST()
-- for k,v in pairs(inventoryItems) do
--     for i,j in pairs(v) do
--         print(k..' '..i..' '..inventoryItems[k][i].name)
--     end
-- end