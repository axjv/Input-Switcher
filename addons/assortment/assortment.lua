local inventoryItems = {}
local acutil = require('acutil')

function ASSORTMENT_ON_INIT(addon,frame)
    acutil.setupHook(SORT_ITEM_INVENTORY_HOOKED,'SORT_ITEM_INVENTORY')
end

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
                    inventoryItems[i][invIndex].type = itemCls.StringArg..dictionary.ReplaceDicIDInCompStr(itemCls.Name)
                    if (itemCls.ItemType == "Recipe") then
                        -- Credit to Mie for recipe grades!
                        local recipeGrade = string.match(itemCls.Icon, "misc(%d)");
                        if recipeGrade ~= nil then
                           inventoryItems[i][invIndex].grade = (tonumber(recipeGrade) - 1)..itemCls.Name;
                        end
                    else
                            inventoryItems[i][invIndex].grade = itemCls.ItemGrade..itemCls.Name
                    end

                end
            end
        end
    end
end



function SORT_INVENTORY_BY(type,order)
    -- print(order)
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
            -- print(count)
            if invItemSort[count] == nil or invItemSort[lowestIndex] == nil then
            else
            -- print(count)
                slotset = invItemSort[lowestIndex].slotset
                -- GET_INVENTORY_LIST()
                invItemSort = inventoryItems[k]
                -- print(order)
                lowestItem = SORTPLUS_SORTER(invItemSort,count,highestIndex,type,order)
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


function SORTPLUS_SORTER(invItemSort,currentIndex,highestIndex,sortType,order)

    if sortType == 'name' then 
        local firstItem = {'~',0}
        if order ~= 'ascending' then
            firstItem[1] = '!'
        end
        for i = currentIndex,highestIndex do
            if invItemSort[i] == nil then
            else
                if order == 'ascending' then
                    if firstItem[1] > invItemSort[i].name then
                        firstItem[1] = invItemSort[i].name
                        firstItem[2] = i
                    end
                else

                    if firstItem[1] < invItemSort[i].name then
                        firstItem[1] = invItemSort[i].name
                        firstItem[2] = i
                    end
                end
            end
        end
        return firstItem[2]
        
    end

    if sortType == 'weight' then 
        local firstItem = {999999,0}
            if order ~= 'ascending' then
                firstItem[1] = 0
            end
        for i = currentIndex,highestIndex do
            if invItemSort[i] == nil then
            else
                local fullWeight = invItemSort[i].weight * invItemSort[i].count
                if order == 'ascending' then
                    if firstItem[1] > fullWeight then
                        firstItem[1] = fullWeight
                        firstItem[2] = i
                    end
                else
                    if firstItem[1] < fullWeight then
                        firstItem[1] = fullWeight
                        firstItem[2] = i
                    end
                end
            end
        end
        return firstItem[2]
    end

    if sortType == 'itemweight' then 
        local firstItem = {999999,0}
            if order ~= 'ascending' then
                firstItem[1] = 0
            end
        for i = currentIndex,highestIndex do
            if invItemSort[i] == nil then
            else
                local fullWeight = invItemSort[i].weight
                if order == 'ascending' then
                    if firstItem[1] > fullWeight then
                        firstItem[1] = fullWeight
                        firstItem[2] = i
                    end
                else
                    if firstItem[1] < fullWeight then
                        firstItem[1] = fullWeight
                        firstItem[2] = i
                    end
                end
            end
        end
        return firstItem[2]
    end
    if sortType == 'type' then 
        local firstItem = {'~',0}
        if order ~= 'ascending' then
            firstItem[1] = '!'
        end
        for i = currentIndex,highestIndex do
            if invItemSort[i] == nil then
            else                
                if order == 'ascending' then
                    if firstItem[1] > invItemSort[i].type then
                        firstItem[1] = invItemSort[i].type
                        firstItem[2] = i
                    end
                else

                    if firstItem[1] < invItemSort[i].type then
                        firstItem[1] = invItemSort[i].type
                        firstItem[2] = i
                    end
                end
            end
        end
        return firstItem[2]
    end

    if sortType == 'grade' then 

        local firstItem = {'~',0}
            if order ~= 'ascending' then
                firstItem[1] = '!'
            end
        for i = currentIndex,highestIndex do
            if invItemSort[i] == nil then
            else
                if order == 'ascending' then
                    if firstItem[1] > invItemSort[i].grade then
                        firstItem[1] = invItemSort[i].grade
                        firstItem[2] = i
                    end
                else
                    if firstItem[1] < invItemSort[i].grade then
                        firstItem[1] = invItemSort[i].grade
                        firstItem[2] = i
                    end
                end
            end
        end
        return firstItem[2]
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

function SORT_ITEM_INVENTORY_HOOKED()
    local context = ui.CreateContextMenu("CONTEXT_INV_SORT", "", 0, 0, 170, 100);
    local scpScp = string.format("REQ_INV_SORT(%d, %d)",IT_INVENTORY, BY_PRICE);
    ui.AddContextMenuItem(context, ScpArgMsg("SortByPrice"), scpScp);   
    -- scpScp = string.format("REQ_INV_SORT(%d, %d)",IT_INVENTORY, BY_WEIGHT);
    -- ui.AddContextMenuItem(context, ScpArgMsg("SortByWeight"), scpScp);  
    -- scpScp = string.format("REQ_INV_SORT(%d, %d)",IT_INVENTORY, BY_NAME);
    -- ui.AddContextMenuItem(context, ScpArgMsg("SortByName"), scpScp);    
    scpScp = string.format("SORT_INVENTORY_BY('%s','%s')","name","ascending");
    ui.AddContextMenuItem(context, 'By Name (Ascending)', scpScp);   
    scpScp = string.format("SORT_INVENTORY_BY('%s','%s')","name","descending");
    ui.AddContextMenuItem(context, 'By Name (Descending)', scpScp);   

    scpScp = string.format("SORT_INVENTORY_BY('%s','%s')","weight","ascending");
    ui.AddContextMenuItem(context, 'By Stack Weight (Ascending)', scpScp); 
    scpScp = string.format("SORT_INVENTORY_BY('%s','%s')","weight","descending");
    ui.AddContextMenuItem(context, 'By Stack Weight (Descending)', scpScp); 

    scpScp = string.format("SORT_INVENTORY_BY('%s','%s')","itemweight","ascending");
    ui.AddContextMenuItem(context, 'By Item Weight (Ascending)', scpScp); 
    scpScp = string.format("SORT_INVENTORY_BY('%s','%s')","itemweight","descending");
    ui.AddContextMenuItem(context, 'By Item Weight (Descending)', scpScp); 

    scpScp = string.format("SORT_INVENTORY_BY('%s','%s')","type","ascending");
    ui.AddContextMenuItem(context, 'By Type (Ascending)', scpScp); 
    scpScp = string.format("SORT_INVENTORY_BY('%s','%s')","type","descending");
    ui.AddContextMenuItem(context, 'By Type (Descending)', scpScp); 

    scpScp = string.format("SORT_INVENTORY_BY('%s','%s')","grade","ascending");
    ui.AddContextMenuItem(context, 'By Grade (Ascending)', scpScp); 
    scpScp = string.format("SORT_INVENTORY_BY('%s','%s')","grade","descending");
    ui.AddContextMenuItem(context, 'By Grade (Descending)', scpScp); 
    ui.OpenContextMenu(context);
end

