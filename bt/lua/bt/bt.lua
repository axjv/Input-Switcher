
bossList = {}
bossTimerReport = false
local bossTimerSync = {
authorizing = 2;
sending = 2;
refreshing = 2;
saving = 2;
complete = 2
}

local timerStatusFile = io.open('timerstatus.txt','w')
timerStatusFile:write('read_complete')
timerStatusFile:close()


local acutil = require('acutil')

function BOSSTIMER_ON_INIT(addon, frame)
    addon:RegisterMsg('FPS_UPDATE','BOSS_TIMER_TARGET_UPDATE')
    acutil.slashCommand('/boss',BOSS_TIMER_CREATE_FRAME)
end


function BOSS_TIMER_TARGET_UPDATE()
    -- switch = math.abs(switch-1)
    local frame = ui.GetFrame('BOSS_UI')
    if bossTimerSync['complete'] < 2 then
        print(bossTimerSync['complete'])

        local file, err = io.open('timerstatus.txt','r')
        if err then 
            print('err') 
        else
            local status = file:read("*all")
            file:close()
            if status == 'read_complete' then
                print('read complete')
            else
                BOSS_TIMER_UPDATE_SYNC(status)
            end
        end
    elseif bossTimerSync['complete'] == 1 then
        BOSS_TIMER_UPDATE_SYNC('complete')
    end
    if session.world.IsIntegrateServer() or session.world.IsIntegrateIndunServer() then
        print('instance')
        return;
    end
    local handle = session.GetTargetHandle()
    -- if handle == 0 then
    for bossName, bossData in pairs(bossList) do
        local handle = bossData[4]
        print(bossName..bossData[4])
        if info.GetName(handle) == "None" and bossTimerReport == false then
            print('rep')
            BOSS_TIMER_REPORT_DIALOG(bossName)
            bossTimerReport = true
            print('clear')
        end
    end
        

    if handle == 0 then
        return;
    end
    -- end
    -- print('pass handle')
    local rank = info.GetMonRankbyHandle(handle)
    -- print(rank)
    if rank ~= "Boss" then
        return;
    end
    print('pass rank')
    local targetInfo = info.GetTargetInfo(handle)
    if targetInfo.isSummonedBoss == 1 then
        return;
    end        
    local bossName = dictionary.ReplaceDicIDInCompStr(info.GetName(handle))
    
    local bossMap = dictionary.ReplaceDicIDInCompStr(session.GetCurrentMapProp():GetName())
    local bossChannel = 'Channel '..(session.loginInfo.GetChannel() + 1)
    local familyName = GETMYFAMILYNAME()

    bossList[bossName] = {bossMap, bossChannel, familyName, handle}
    -- print(bossName)

end

function BOSS_TIMER_CLEAR_LIST()
    bossList = {}
    bossTimerReport = false
end

function BOSS_TIMER_REPORT_DIALOG(name)
    print(string.format("BOSS_TIMER_REPORT_TIME(\"%s\")",name))
    ui.MsgBox("Boss timer has detected that you have killed "..name..", would you like to sync data?",string.format("BOSS_TIMER_REPORT_TIME(\"%s\")",name),"BOSS_TIMER_CLEAR_LIST()")
end

function BOSS_TIMER_REPORT_TIME(name)
    print('start report')

    if bossList[name] == nil then
        print('noname')
        return;
    end
    print('rep')
    print(name)
    local queryType = "report"
    local bossMap = bossList[name][1]
    local bossChannel = bossList[name][2]
    local familyName = bossList[name][3]
    BOSS_TIMER_CLEAR_LIST()

    local sysTime = geTime.GetServerSystemTime()
    local sysHour, sysMinute
    if sysTime.wHour < 10 then 
        sysHour = "0"..sysTime.wHour
    else
        sysHour = sysTime.wHour
    end

    if sysTime.wMinute < 10 then 
        sysMinute = "0"..sysTime.wMinute
    else
        sysMinute = sysTime.wMinute
    end
    local bossDeadTime = sysHour..":"..sysMinute

    ui.AddText('SystemMsgFrame',bossDeadTime..' '..name)
    ui.AddText('SystemMsgFrame',bossMap)
    ui.AddText('SystemMsgFrame',bossChannel)
    for k,v in pairs(bossTimerSync) do
        bossTimerSync[k] = 0
    end

    file = io.open('timerstatus.txt','w')
    file:write('authorizing')
    file:close()
    CHAT_SYSTEM('Boss killed: '..name..', syncing to server.')
    os.execute(string.format("boss_timer.exe \"%s\" \"%s\" \"%s\" \"%s\" \"%s\"&", queryType, name, bossMap, familyName, bossChannel))
    
    print('execute')

end

local bossUI = {}

function BOSS_TIMER_LOAD_JSON()
    local bossData, err = acutil.loadJSON('bossdata.json')
    if err then
        bossData = {}
    end
    
    for j,k in pairs(bossData) do
        local min = j
        for k = j,#bossData do
            if bossData[k].bossname < bossData[min].bossname then
                min = k
            end
            -- print(bossData[k].bossname..' '..bossData[k].time..' '..bossData[k].mapname..' '..bossData[k].user..' '..bossData[k].channel)
        end
        -- print(bossData[min].bossname)
        bossData[j],bossData[min] = bossData[min],bossData[j]
    end
    -- table.sort(bossData)
    return bossData
end

function BOSS_TIMER_UPDATE_FRAME()
    local frame = ui.GetFrame('BOSS_UI')
    if frame == nil then
        return;
    end
    bossUI['gbox']:RemoveAllChild()
    local bossData = BOSS_TIMER_LOAD_JSON()
    for k,v in pairs(bossData) do
        -- if not bossUI['name'..k] then
        bossUI['name'..k] = bossUI['gbox']:CreateOrGetControl('richtext','BOSS_NAME_'..k,10,35*k-25,100,100)
        bossUI['name'..k] = tolua.cast(bossUI['name'..k],'ui::CRichText')
        -- end
        bossUI['name'..k]:SetText('{@st66b}{#ffffff}'..bossData[k].bossname..'{/}')
        bossUI['name'..k]:EnableHitTest(0)

        -- if not bossUI['time'..k] then
        bossUI['time'..k] = bossUI['gbox']:CreateOrGetControl('richtext','BOSS_TIME_'..k,300,35*k-25,100,100)
        bossUI['time'..k] = tolua.cast(bossUI['time'..k],'ui::CRichText')
        -- end
        bossUI['time'..k]:SetText('{@st66b}{#ffffff}'..bossData[k].time..'{/}')
        bossUI['time'..k]:EnableHitTest(0)    

        -- if not bossUI['channel'..k] then
        bossUI['channel'..k] = bossUI['gbox']:CreateOrGetControl('richtext','BOSS_CHANNEL_'..k,500,35*k-25,100,100)
        bossUI['channel'..k] = tolua.cast(bossUI['channel'..k],'ui::CRichText')
        -- end
        bossUI['channel'..k]:SetText('{@st66b}{#ffffff}'..bossData[k].channel..'{/}')
        bossUI['channel'..k]:EnableHitTest(0)  

        -- if not bossUI['map'..k] then
        bossUI['map'..k] = bossUI['gbox']:CreateOrGetControl('richtext','BOSS_MAP_'..k,620,35*k-25,100,100)
        bossUI['map'..k] = tolua.cast(bossUI['map'..k],'ui::CRichText')
        -- end
        bossUI['map'..k]:SetText('{@st66b}{#ffffff}'..bossData[k].mapname..'{/}')
        bossUI['map'..k]:EnableHitTest(0)  
    end

    print('update')
end

function BOSS_TIMER_CREATE_FRAME()

    bossUI['main'] = ui.CreateNewFrame('bosstimer', "BOSS_UI")
    bossUI['main']:SetLayerLevel(100)
    bossUI['main']:SetSkinName('tooltip1')
    bossUI['main']:Resize(1000,600)
    bossUI['main']:SetGravity(ui.CENTER_HORZ,ui.CENTER_VERT)
    bossUI['main']:SetEventScript(ui.RBUTTONUP,'ui.DestroyFrame(\"BOSS_UI\")')


    bossUI['close'] = bossUI['main']:CreateOrGetControl('button','BOSS_TIMER_CLOSE',960,10,30,30)
    bossUI['close'] = tolua.cast(bossUI['close'],'ui::CButton')
    bossUI['close']:SetText('{@st66b}{#ffffff}X{/}')
    bossUI['close']:SetClickSound("button_click_big");
    bossUI['close']:SetOverSound("button_over");
    bossUI['close']:SetSkinName('chat_window')

    bossUI['close']:SetEventScript(ui.LBUTTONUP,"ui.DestroyFrame(\"BOSS_UI\")")

    bossUI['header'] = bossUI['main']:CreateOrGetControl('richtext','BOSS_TIMER_HEADER',20,20,970,20)
    bossUI['header'] = tolua.cast(bossUI['header'],'ui::CRichText')
    bossUI['header']:SetText('{@st66b}{s20}{#ffffff}Name                                                       Time                      Channel          Map')
    bossUI['header']:EnableHitTest(0)


    bossUI['gbox'] = bossUI['main']:CreateOrGetControl('groupbox','BOSS_GROUP_BOX',10,50,980,510)
    bossUI['gbox'] = tolua.cast(bossUI['gbox'],'ui::CGroupBox')
    bossUI['gbox']:SetSkinName("textview")
    bossUI['gbox']:EnableHittestGroupBox(false)
    bossUI['gbox']:RemoveAllChild()

    offset = 0
    os.execute("boss_timer.exe list&")
    bossData = BOSS_TIMER_LOAD_JSON()
    for k,v in pairs(bossData) do
        bossUI['name'..k] = bossUI['gbox']:CreateOrGetControl('richtext','BOSS_NAME_'..k,10,35*k-25,100,100)
        bossUI['name'..k] = tolua.cast(bossUI['name'..k],'ui::CRichText')
        bossUI['name'..k]:SetText('{@st66b}{#ffffff}'..bossData[k].bossname..'{/}')
        bossUI['name'..k]:EnableHitTest(0)

        bossUI['time'..k] = bossUI['gbox']:CreateOrGetControl('richtext','BOSS_TIME_'..k,300,35*k-25,100,100)
        bossUI['time'..k] = tolua.cast(bossUI['time'..k],'ui::CRichText')
        bossUI['time'..k]:SetText('{@st66b}{#ffffff}'..bossData[k].time..'{/}')
        bossUI['time'..k]:EnableHitTest(0)    

        bossUI['channel'..k] = bossUI['gbox']:CreateOrGetControl('richtext','BOSS_CHANNEL_'..k,500,35*k-25,100,100)
        bossUI['channel'..k] = tolua.cast(bossUI['channel'..k],'ui::CRichText')
        bossUI['channel'..k]:SetText('{@st66b}{#ffffff}'..bossData[k].channel..'{/}')
        bossUI['channel'..k]:EnableHitTest(0)  

        bossUI['map'..k] = bossUI['gbox']:CreateOrGetControl('richtext','BOSS_MAP_'..k,620,35*k-25,100,100)
        bossUI['map'..k] = tolua.cast(bossUI['map'..k],'ui::CRichText')
        bossUI['map'..k]:SetText('{@st66b}{#ffffff}'..bossData[k].mapname..'{/}')
        bossUI['map'..k]:EnableHitTest(0)  

        -- begin new code

    end

    bossUI['sync'] = bossUI['main']:CreateOrGetControl('button','BOSS_TIMER_SYNC',750,560,200,30)
    bossUI['sync'] = tolua.cast(bossUI['sync'],'ui::CButton')
    bossUI['sync']:SetText('{@st66b}{#ffffff}sync to web{/}')
    bossUI['sync']:SetClickSound("button_click_big");
    bossUI['sync']:SetOverSound("button_over");
    bossUI['sync']:SetSkinName('quest_box')
    bossUI['sync']:SetEventScript(ui.LBUTTONUP,"BOSS_TIMER_SYNC_LIST()")


    bossUI['refresh'] = bossUI['main']:CreateOrGetControl('button','BOSS_TIMER_REFRESH',540,560,200,30)
    bossUI['refresh'] = tolua.cast(bossUI['refresh'],'ui::CButton')
    bossUI['refresh']:SetText('{@st66b}{#ffffff}load bossdata.json {/}')
    bossUI['refresh']:SetClickSound("button_click_big");
    bossUI['refresh']:SetOverSound("button_over");
    bossUI['refresh']:SetSkinName('quest_box')
    bossUI['refresh']:SetEventScript(ui.LBUTTONUP,"BOSS_TIMER_UPDATE_FRAME()")

    bossUI['manual'] = bossUI['main']:CreateOrGetControl('button','BOSS_TIMER_MANUAL',20,560,200,30)
    bossUI['manual'] = tolua.cast(bossUI['manual'],'ui::CButton')
    bossUI['manual']:SetText('{@st66b}{#ffffff}manual entry{/}')
    bossUI['manual']:SetClickSound("button_click_big");
    bossUI['manual']:SetOverSound("button_over");
    bossUI['manual']:SetSkinName('quest_box')
    bossUI['manual']:SetEventScript(ui.LBUTTONUP,"BOSS_TIMER_NAME_ENTRY()")

    for k,v in pairs(bossTimerSync) do
        bossTimerSync[k] = 0
    end

end

function BOSS_TIMER_NAME_ENTRY()

    bossUI['manual']:SetText('{@st66b}{#ffffff}cancel{/}')
    bossUI['manual']:SetEventScript(ui.LBUTTONUP,"BOSS_TIMER_CANCEL_ENTRY()")

    bossUI['entrytext'] = bossUI['main']:CreateOrGetControl('richtext','BOSS_TIMER_ENTRY_TEXT',250,560,970,20)
    bossUI['entrytext'] = tolua.cast(bossUI['entrytext'],'ui::CRichText')
    bossUI['entrytext']:SetText('{@st66b}{s18}{#ffffff}name:')
    bossUI['entrytext']:EnableHitTest(0)
    bossUI['entrytext']:ShowWindow(1)

    bossUI['entrybox'] = bossUI['main']:CreateOrGetControl('edit','BOSS_TIMER_ENTRY_BOX', 350,560,150,30)
    bossUI['entrybox'] = tolua.cast(bossUI['entrybox'],'ui::CEditControl')

    bossUI['entrybox']:SetEventScript(ui.ENTERKEY,"BOSS_TIMER_TIME_ENTRY()")
    bossUI['entrybox']:ShowWindow(1)

end

function BOSS_TIMER_SYNC_LIST()
    local frame = ui.GetFrame('BOSS_UI')
    if frame == nil then
        return;
    end
    bossUI['sync']:SetText('{@st66b}{#ffffff}authorizing{/}')
    for k,v in pairs(bossTimerSync) do
        bossTimerSync[k] = 0
    end
    os.execute("boss_timer.exe list&")
end

function BOSS_TIMER_UPDATE_SYNC(status)

    local frame = ui.GetFrame('BOSS_UI')
    if frame == nil then

    end
    if status == 'complete' then
        if bossTimerSync[status] == 0 then
            if frame ~= nil then
                bossUI['sync']:SetText('{@st66b}{#ffffff}complete{/}')
            else
                CHAT_SYSTEM('Syncing complete!')
            end
            bossTimerSync[status] = -1
            return;
        else
            file = io.open('timerstatus.txt','w')
            file:write('read_complete')
            file:close()
            bossTimerSync[status] = 2
            if frame ~= nil then
                BOSS_TIMER_UPDATE_FRAME()
                bossUI['sync']:SetText('{@st66b}{#ffffff}sync to web{/}')
            else
                return;
            end
        end
    
    elseif bossTimerSync[status] == 0 then
        if frame ~= nil then
            bossUI['sync']:SetText('{@st66b}{#ffffff}'..status..'{/}')
        else
            if status == 'authorizing' then
                CHAT_SYSTEM('Getting authorization...')
            elseif status == 'sending' then
                CHAT_SYSTEM('Sending data.')
            elseif status == 'refreshing' then
                CHAT_SYSTEM('Retrieving data.')
            elseif status == 'saving' then
                CHAT_SYSTEM('Saving data locally.')
            end
        end
        bossTimerSync[status] = 1
        return;
    end
    bossTimerSync[status] = 2

end

function BOSS_TIMER_TIME_ENTRY()
    bossUI['nameentry'] = bossUI['entrybox']:GetText()
    print(bossUI['nameentry'])
    bossUI['entrytext']:SetText('{@st66b}{s18}{#ffffff}time:')
    bossUI['entrybox']:SetText('')
    bossUI['entrybox']:SetEventScript(ui.ENTERKEY,"BOSS_TIMER_CHANNEL_ENTRY()")

end

function BOSS_TIMER_CHANNEL_ENTRY()
    bossUI['timeentry'] = bossUI['entrybox']:GetText()
    print(bossUI['mapentry'])
    bossUI['entrytext']:SetText('{@st66b}{s18}{#ffffff}channel:')
    bossUI['entrybox']:SetText('')
    bossUI['entrybox']:SetEventScript(ui.ENTERKEY,"BOSS_TIMER_MAP_ENTRY()")

end

function BOSS_TIMER_MAP_ENTRY()
    bossUI['channelentry'] = bossUI['entrybox']:GetText()
    print(bossUI['channel'])
    bossUI['entrytext']:SetText('{@st66b}{s18}{#ffffff}map:')
    bossUI['entrybox']:SetText('')
    bossUI['entrybox']:SetEventScript(ui.ENTERKEY,"BOSS_TIMER_SUBMIT_ENTRY()")

end

function BOSS_TIMER_SUBMIT_ENTRY()
    bossUI['mapentry'] = bossUI['entrybox']:GetText()
    print(bossUI['mapentry'])
    bossUI['entrybox']:SetText('')

    local queryType = "report"
    local bossName = bossUI['nameentry']
    local bossDeadTime = bossUI['timeentry']
    local bossMap = bossUI['mapentry']
    local bossChannel = bossUI['channelentry']
    local familyName = GETMYFAMILYNAME()


    ui.AddText('SystemMsgFrame',bossDeadTime..' '..bossName)
    ui.AddText('SystemMsgFrame',bossMap)
    ui.AddText('SystemMsgFrame',bossChannel)


    for k,v in pairs(bossTimerSync) do
        bossTimerSync[k] = 0
    end

    os.execute(string.format("boss_timer.exe \"%s\" \"%s\" \"%s\" \"%s\" \"%s\" \"%s\"&", queryType, bossName, bossMap, familyName, bossChannel, bossDeadTime))
    print(string.format("boss_timer.exe \"%s\" \"%s\" \"%s\" \"%s\" \"%s\" \"%s\"&", queryType, bossName, bossMap, familyName, bossChannel, bossDeadTime))
    BOSS_TIMER_CANCEL_ENTRY()

end


function BOSS_TIMER_CANCEL_ENTRY()
    if bossUI['entrybox'] ~= nil then
        bossUI['entrybox']:ShowWindow(0)
    end
    if bossUI['entrytext'] ~= nil then
        bossUI['entrytext']:ShowWindow(0)
    end
    bossUI['manual']:SetText('{@st66b}{#ffffff}manual entry{/}')
    bossUI['manual']:SetEventScript(ui.LBUTTONUP,"BOSS_TIMER_NAME_ENTRY()") 
end

