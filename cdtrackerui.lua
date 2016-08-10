local acutil = require('acutil')
acutil.slashCommand('/cdtracker',CDTRACKER_TOGGLE_FRAME)
local frameSkins = {'box_glass', 'slot_name', 'shadow_box', 'frame_bg', 'textview', 'chat_window', 'tooltip1'}

cd_buttons = {}

local settings = {}
local default = {
    alerts           = true;
    buffPosX         = 100;
    buffPosY         = 200;
    buffs            = true;
    chatList         = {};
    checkVal         = 5;
    firstTimeMessage = false;
    ignoreList       = {};
    lock             = false;
    message          = {};
    size             = 1;
    skillPosX        = 700;
    skillPosY        = 225;
    skills           = true;
    skin             = 1;
    sound            = true;
    soundtype        = 1;
    text             = true;
    time             = {}
    }

function CDTRACKER_COPYSETTINGS()
    local s, err = acutil.loadJSON("../addons/cdtracker/settings.json");
    if err then
        settings = default
    else
        settings = s
        for k,v in pairs(default) do
            if s[k] == nil then
                settings[k] = v
            end
        end
    end
    CDTRACKER_SAVESETTINGS()
end


function CD_CLOSE_FRAMES()
    cdTrackerUI = ui.GetFrame('CDTRACKER_UI')
    cdTrackerSkillsUI = ui.GetFrame('CDTRACKER_SKILLS_UI')

    if cdTrackerUI ~= nil then
        cdTrackerUI:ShowWindow(0)
    end
    if cdTrackerSkillsUI ~= nil then
        cdTrackerSkillsUI:ShowWindow(0)
    end
end

function CDTRACKER_CREATE_FRAME()
    CDTRACKER_COPYSETTINGS()
    cdTrackerUI = ui.CreateNewFrame('cdtracker','CDTRACKER_UI')
    cdTrackerUI:SetLayerLevel(999)
    -- cdTrackerUI:EnableHitTest(0)
    cdTrackerUI:SetSkinName(frameSkins[7])
    cdTrackerUI:Resize(500,500)
    cdTrackerUI:SetGravity(ui.CENTER_HORZ,ui.CENTER_VERT)
    cdTrackerUI:SetEventScript(ui.RBUTTONUP,'CD_CLOSE_FRAMES')

    cd_buttons['header'] = cdTrackerUI:CreateOrGetControl('richtext','CDTRACKER_HEADER', 0,15,200,55)
    cd_buttons['header'] = tolua.cast(cd_buttons['header'],'ui::CRichText')
    cd_buttons['header']:SetText('{@st66b}{s24}{#ffffff}Cooldown Tracker Settings{/}')
    cd_buttons['header']:SetSkinName("textview");
    cd_buttons['header']:EnableHitTest(0)
    cd_buttons['header']:SetGravity(ui.CENTER_HORZ,ui.TOP)

    cd_buttons['close'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_CLOSE', 460,10,30,30)
    cd_buttons['close'] = tolua.cast(cd_buttons['close'],'ui::CButton')
    cd_buttons['close']:SetText('{@st66b}X{/}')
    cd_buttons['close']:SetClickSound("button_click_big");
    cd_buttons['close']:SetOverSound("button_over");
    cd_buttons['close']:SetEventScript(ui.LBUTTONUP, "CD_CLOSE_FRAMES");
    cd_buttons['close']:SetSkinName("test_pvp_btn");



    cd_buttons['enabled'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_ENABLED', 30,55,200,30)
    cd_buttons['enabled'] = tolua.cast(cd_buttons['enabled'],'ui::CButton')
    if settings.alerts then enabled = '{#00cc00}on' else enabled = '{#cc0000}off' end
    cd_buttons['enabled']:SetText('{@st66b}{#ffffff}cdtracker: '..enabled..'{/}')
    cd_buttons['enabled']:SetClickSound("button_click_big");
    cd_buttons['enabled']:SetOverSound("button_over");
    cd_buttons['enabled']:SetEventScript(ui.LBUTTONUP, "TOGGLE_CD('enabled')");
    cd_buttons['enabled']:SetSkinName("quest_box");

    cd_buttons['skills'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_SKILLWINDOW', 30,90,200,30)
    cd_buttons['skills'] = tolua.cast(cd_buttons['skills'],'ui::CButton')
    if settings.skills then skills = '{#00cc00}on' else skills = '{#cc0000}off' end
    cd_buttons['skills']:SetText('{@st66b}{#ffffff}skills: '..skills..'{/}')

    -- cd_buttons['skills']:SetText('{@st66b}{#ffffff}skills: {#00cc00}on{/}')
    -- cd_buttons['skills']:SetText('{@st66b}{#ffffff}skills:{#cc0000}off{/}')
      
    cd_buttons['skills']:SetClickSound("button_click_big");
    cd_buttons['skills']:SetOverSound("button_over");
    cd_buttons['skills']:SetEventScript(ui.LBUTTONUP, "TOGGLE_CD('skills')");
    cd_buttons['skills']:SetSkinName("quest_box");

    cd_buttons['buffs'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_BUFFWINDOW', 30,125,200,30)
    cd_buttons['buffs'] = tolua.cast(cd_buttons['buffs'],'ui::CButton')
    if settings.buffs then buffs = '{#00cc00}on' else buffs = '{#cc0000}off' end
    cd_buttons['buffs']:SetText('{@st66b}{#ffffff}buffs: '..buffs..'{/}')
    cd_buttons['buffs']:SetClickSound("button_click_big");
    cd_buttons['buffs']:SetOverSound("button_over");
    cd_buttons['buffs']:SetEventScript(ui.LBUTTONUP, "TOGGLE_CD('buffs')");
    cd_buttons['buffs']:SetSkinName("quest_box");

    cd_buttons['text'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_TEXT', 30,160,200,30)
    cd_buttons['text'] = tolua.cast(cd_buttons['text'],'ui::CButton')
    if settings.text then text = '{#00cc00}on' else text = '{#cc0000}off' end
    cd_buttons['text']:SetText('{@st66b}{#ffffff}text: '..text..'{/}')
    cd_buttons['text']:SetClickSound("button_click_big");
    cd_buttons['text']:SetOverSound("button_over");
    cd_buttons['text']:SetEventScript(ui.LBUTTONUP, "TOGGLE_CD('text')");
    cd_buttons['text']:SetSkinName("quest_box");


    cd_buttons['sound'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_SOUND', 30,195,200,30)
    cd_buttons['sound'] = tolua.cast(cd_buttons['sound'],'ui::CButton')
    if settings.sound then sound = '{#00cc00}on' else sound = '{#cc0000}off' end
    cd_buttons['sound']:SetText('{@st66b}{#ffffff}sound: '..sound..'{/}')
    cd_buttons['sound']:SetClickSound("button_click_big");
    cd_buttons['sound']:SetOverSound("button_over");
    cd_buttons['sound']:SetEventScript(ui.LBUTTONUP, "TOGGLE_CD('sound')");
    cd_buttons['sound']:SetSkinName("quest_box");

    cd_buttons['lock'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_LOCK', 30,230,200,30)
    cd_buttons['lock'] = tolua.cast(cd_buttons['lock'],'ui::CButton')
    if settings.lock then lock = '{#00cc00}on' else lock = '{#cc0000}off' end
    cd_buttons['lock']:SetText('{@st66b}{#ffffff}lock: '..lock..'{/}')
    cd_buttons['lock']:SetClickSound("button_click_big");
    cd_buttons['lock']:SetOverSound("button_over");
    cd_buttons['lock']:SetEventScript(ui.LBUTTONUP, "TOGGLE_CD('lock')");
    cd_buttons['lock']:SetSkinName("quest_box");

    cd_buttons['showframes'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_SHOWFRAMES', 30,265,200,30)
    cd_buttons['showframes'] = tolua.cast(cd_buttons['showframes'],'ui::CButton')

    cd_buttons['showframes']:SetText('{@st66b}{#ffffff}show frames{/}')
    cd_buttons['showframes']:SetClickSound("button_click_big");
    cd_buttons['showframes']:SetOverSound("button_over");
    cd_buttons['showframes']:SetEventScript(ui.LBUTTONUP, "ui.Chat('/cd showframes')");
    cd_buttons['showframes']:SetSkinName("quest_box");

    cd_buttons['time'] = cdTrackerUI:CreateOrGetControl('richtext','CDTRACKER_TIME', 270,95,200,30)
    cd_buttons['time'] = tolua.cast(cd_buttons['time'],'ui::CRichText')
    cd_buttons['time']:SetText('{@st66b}{#ffffff}time:{/}')
    cd_buttons['time']:SetSkinName("textview");
    cd_buttons['time']:EnableHitTest(0)

    cd_buttons['timebox'] = cdTrackerUI:CreateOrGetControl('edit','CDTRACKER_TIMEBOX', 320,90,50,30)
    cd_buttons['timebox'] = tolua.cast(cd_buttons['timebox'],'ui::CEditControl')


    cd_buttons['timelabel'] = cd_buttons['timebox']:CreateOrGetControl('richtext','CDTRACKER_TIMELABEL', 0,0,30,30)
    cd_buttons['timelabel'] = tolua.cast(cd_buttons['timelabel'],'ui::CRichText')
    cd_buttons['timelabel']:SetGravity(ui.CENTER_HORZ,ui.CENTER_VERT)
    cd_buttons['timelabel']:EnableHitTest(0)
    cd_buttons['timelabel']:SetText('{@st66b}{#ffffff}'..settings.checkVal)

    cd_buttons['timebox']:SetEventScript(ui.LBUTTONUP,"cd_buttons['timelabel']:ShowWindow(0)")
    cd_buttons['timebox']:SetLostFocusingScp("cd_buttons['timelabel']:ShowWindow(1)")
    cd_buttons['timebox']:SetEventScript(ui.ENTERKEY,"CD_SET_MAIN_TIME")


    cd_buttons['size'] = cdTrackerUI:CreateOrGetControl('richtext','CDTRACKER_SIZE', 270,130,200,30)
    cd_buttons['size'] = tolua.cast(cd_buttons['size'],'ui::CRichText')
    cd_buttons['size']:SetText('{@st66b}{#ffffff}size:{/}')
    cd_buttons['size']:SetSkinName("textview");
    cd_buttons['size']:EnableHitTest(0)

    cd_buttons['sizebox'] = cdTrackerUI:CreateOrGetControl('edit','CDTRACKER_SIZEBOX', 320,125,50,30)
    cd_buttons['sizebox'] = tolua.cast(cd_buttons['sizebox'],'ui::CEditControl')
    cd_buttons['sizebox']:SetEventScript(ui.ENTERKEY,"CD_SET_SIZE")

    cd_buttons['sizelabel'] = cd_buttons['sizebox']:CreateOrGetControl('richtext','CDTRACKER_SIZELABEL', 0,0,30,30)
    cd_buttons['sizelabel'] = tolua.cast(cd_buttons['sizelabel'],'ui::CRichText')
    cd_buttons['sizelabel']:SetGravity(ui.CENTER_HORZ,ui.CENTER_VERT)
    cd_buttons['sizelabel']:EnableHitTest(0)
    cd_buttons['sizelabel']:SetText('{@st66b}{#ffffff}'..settings.size)


    cd_buttons['sizebox']:SetEventScript(ui.LBUTTONUP,"cd_buttons['sizelabel']:ShowWindow(0)")
    cd_buttons['sizebox']:SetLostFocusingScp("cd_buttons['sizelabel']:ShowWindow(1)")
    cd_buttons['sizebox']:SetEventScript(ui.ENTERKEY,"CD_SET_SIZE")


    cd_buttons['skin'] = cdTrackerUI:CreateOrGetControl('richtext','CDTRACKER_SKIN', 270,165,200,30)
    cd_buttons['skin'] = tolua.cast(cd_buttons['skin'],'ui::CRichText')
    cd_buttons['skin']:SetText('{@st66b}{#ffffff}skin:{/}')
    cd_buttons['skin']:SetSkinName("textview");
    cd_buttons['skin']:EnableHitTest(0)

    -- cd_buttons['skindroplist'] = cdTrackerUI:CreateOrGetControl('droplist','CDTRACKER_SKINDROPLIST', 320,165,150,20)
    -- cd_buttons['skindroplist'] = tolua.cast(cd_buttons['skindroplist'],'ui::CDropList')
    --  cd_buttons['skindroplist']:ClearItems()
    -- cd_buttons['skindroplist']:AddItem(0,'test')
    -- cd_buttons['skindroplist']:SelectItem(0)


    cd_buttons['soundtype'] = cdTrackerUI:CreateOrGetControl('richtext','CDTRACKER_SOUNDTYPE', 270,200,200,30)
    cd_buttons['soundtype'] = tolua.cast(cd_buttons['soundtype'],'ui::CRichText')
    cd_buttons['soundtype']:SetText('{@st66b}{#ffffff}sound:{/}')
    cd_buttons['soundtype']:SetSkinName("textview");
    cd_buttons['soundtype']:EnableHitTest(0)

    -- cd_buttons['soundtypedroplist'] = cdTrackerUI:CreateOrGetControl('richtext','CDTRACKER_soundtypedroplist', 320,200,200,30)
    -- cd_buttons['soundtypedroplist'] = tolua.cast(cd_buttons['soundtypedroplist'],'ui::CRichText')
    -- cd_buttons['soundtypedroplist']:SetText('{@st66b}{#ffffff}soundtypedroplist:{/}')

    cd_buttons['skillslist'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_SKILLSLIST', 270,55,200,30)
    cd_buttons['skillslist'] = tolua.cast(cd_buttons['skillslist'],'ui::CButton')
    cd_buttons['skillslist']:SetText('{@st66b}{#ffffff}individual skill settings{/}')
    cd_buttons['skillslist']:SetClickSound("button_click_big");
    cd_buttons['skillslist']:SetOverSound("button_over");
    cd_buttons['skillslist']:SetEventScript(ui.LBUTTONUP, "CD_LIST");
    cd_buttons['skillslist']:SetSkinName("quest_box");


    cd_buttons['reset'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_RESET', 270,450,200,30)
    cd_buttons['reset'] = tolua.cast(cd_buttons['reset'],'ui::CButton')
    cd_buttons['reset']:SetText('{@st66b}{#ff0000}reset all settings{/}')
    cd_buttons['reset']:SetClickSound("button_click_big");
    cd_buttons['reset']:SetOverSound("button_over");
    cd_buttons['reset']:SetEventScript(ui.LBUTTONUP, "CD_RESET_ALL_SETTINGS");
    cd_buttons['reset']:SetSkinName("quest_box");

    cd_buttons['helpbox'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_HELPBOX', 30,450,200,30)
    cd_buttons['helpbox'] = tolua.cast(cd_buttons['helpbox'],'ui::CButton')
    cd_buttons['helpbox']:SetText('{@st66b}{#ffff00}chat command help{/}')
    cd_buttons['helpbox']:SetClickSound("button_click_big");
    cd_buttons['helpbox']:SetOverSound("button_over");
    cd_buttons['helpbox']:SetEventScript(ui.LBUTTONUP, "ui.Chat('/cd help all')");
    cd_buttons['helpbox']:SetSkinName("quest_box");


    -- cd_buttons['skill'..k] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_BUFFS', 10,80,200,30)
    -- cd_buttons['skill'..k] = tolua.cast(cd_buttons['skill'..k],'ui::CButton')
    -- cd_buttons['skill'..k]:SetText('{@st66b}buff list{/}')
    -- cd_buttons['skill'..k]:SetClickSound("button_click_big");
    -- cd_buttons['skill'..k]:SetOverSound("button_over");
    -- cd_buttons['skill'..k]:SetEventScript(ui.LBUTTONUP, "CD_LIST");
    -- cd_buttons['skill'..k]:SetSkinName("test_pvp_btn");

    -- button:EnableHitTest(1)
-- time
-- size

-- soundtype
-- skin

-- buffs
-- skills
-- showframes
-- lock

-- help
-- reset
end

function CD_RESET_ALL_SETTINGS()
    ui.MsgBox("{s24}{#ff0000}WARNING!{#000000}{nl} {nl}{#03134d}"..
        "{s18}Are you sure you want to reset all settings? This cannot be undone.","ui.Chat('/cd reset')","Nope")
end

function RETURN_SKILL_LIST()
    skillList = {}
    for k,v in pairs(cdTrackSkill) do
        if type(tonumber(k)) == 'number' then
            skillList[k] = '[Skill] '..cdTrackSkill[k]['fullName']
        end
    end
    table.sort(skillList)
    return skillList
end

function RETURN_BUFF_LIST()
    buffList = {}
    for k,v in pairs(cdTrackBuff['class']) do
        local buffname = dictionary.ReplaceDicIDInCompStr(k)
        table.insert(buffList, '[Buff] '..buffname)
    end
    table.sort(buffList)
    return buffList
end

function CD_MAINMENU()
    CD_CLOSE_FRAMES()
    CDTRACKER_TOGGLE_FRAME()
    if cdTrackerSkillsUI ~= nil then
        cdTrackerUI:SetPos(cdTrackerSkillsUI:GetX(),cdTrackerSkillsUI:GetY())
    end
end

function CD_LIST()
    CD_CLOSE_FRAMES()
    GET_SKILL_LIST()
    GET_BUFF_LIST()
    CDTRACKER_COPYSETTINGS()
    cdTrackerSkillsUI = ui.CreateNewFrame('cdtracker','CDTRACKER_SKILLS_UI')
    cdTrackerSkillsUI:SetLayerLevel(999)
    -- cdTrackerSkillsUI:EnableHitTest(0)
    cdTrackerSkillsUI:SetSkinName(frameSkins[7])
    cdTrackerSkillsUI:Resize(800,510)
    if cdTrackerUI~=nil then
        cdTrackerSkillsUI:SetPos(cdTrackerUI:GetX(),cdTrackerUI:GetY())
    end
    cdTrackerSkillsUI:SetGravity(ui.CENTER_HORZ,ui.CENTER_VERT)
    cdTrackerSkillsUI:SetEventScript(ui.RBUTTONUP,'CD_MAINMENU')
    cdTrackerSkillsUI:ShowWindow(1)

    cd_buttons['close'] = cdTrackerSkillsUI:CreateOrGetControl('button','CDTRACKER_BUTTON_CLOSE', 760,10,30,30)
    cd_buttons['close'] = tolua.cast(cd_buttons['close'],'ui::CButton')
    cd_buttons['close']:SetText('{@st66b}X{/}')
    cd_buttons['close']:SetClickSound("button_click_big");
    cd_buttons['close']:SetOverSound("button_over");
    cd_buttons['close']:SetEventScript(ui.LBUTTONUP, "CD_CLOSE_FRAMES");
    cd_buttons['close']:SetSkinName("test_pvp_btn");


    skillList = RETURN_SKILL_LIST()
    buffList = RETURN_BUFF_LIST()
    dots = '.........................................................................................................................................................................................'

    cdGroupBox = cdTrackerSkillsUI:CreateOrGetControl('groupbox','CDTRACKER_GROUPBOX',10,50,780,420)
    cdGroupBox = tolua.cast(cdGroupBox,'ui::CGroupBox')
    cdGroupBox:SetSkinName("textview")
    cdGroupBox:EnableHittestGroupBox(false)
    cdGroupBox:RemoveAllChild()
    -- cdGroupBox:EnableDrawFrame(false)
    cd_buttons['skillname'] = cdTrackerSkillsUI:CreateOrGetControl('richtext','CDTRACKER_SKILLNAME', 20,20,200,30)
    cd_buttons['skillname'] = tolua.cast(cd_buttons['skillname'],'ui::CRichText')
    cd_buttons['skillname']:SetText('{@st66b}{#ffffff}Name{/}')
    cd_buttons['skillname']:SetSkinName("textview");
    cd_buttons['skillname']:EnableHitTest(0)

    cd_buttons['skillalert'] = cdTrackerSkillsUI:CreateOrGetControl('richtext','CDTRACKER_SKILLALERT', 300,20,200,30)
    cd_buttons['skillalert'] = tolua.cast(cd_buttons['skillalert'],'ui::CRichText')
    cd_buttons['skillalert']:SetText('{@st66b}{#ffffff}Alerts{/}')
    cd_buttons['skillalert']:SetSkinName("textview");
    cd_buttons['skillalert']:EnableHitTest(0)

    cd_buttons['skillchat'] = cdTrackerSkillsUI:CreateOrGetControl('richtext','CDTRACKER_SKILLCHAT', 400,20,200,30)
    cd_buttons['skillchat'] = tolua.cast(cd_buttons['skillchat'],'ui::CRichText')
    cd_buttons['skillchat']:SetText('{@st66b}{#ffffff}Chat{/}')
    cd_buttons['skillchat']:SetSkinName("textview");
    cd_buttons['skillchat']:EnableHitTest(0)

    cd_buttons['skillmessage'] = cdTrackerSkillsUI:CreateOrGetControl('richtext','CDTRACKER_SKILLMESSAGE', 525,20,200,30)
    cd_buttons['skillmessage'] = tolua.cast(cd_buttons['skillmessage'],'ui::CRichText')
    cd_buttons['skillmessage']:SetText('{@st66b}{#ffffff}Message{/}')
    cd_buttons['skillmessage']:SetSkinName("textview");
    cd_buttons['skillmessage']:EnableHitTest(0)

    cd_buttons['skilltime'] = cdTrackerSkillsUI:CreateOrGetControl('richtext','CDTRACKER_SKILLTIME', 685,20,200,30)
    cd_buttons['skilltime'] = tolua.cast(cd_buttons['skilltime'],'ui::CRichText')
    cd_buttons['skilltime']:SetText('{@st66b}{#ffffff}Time{/}')
    cd_buttons['skilltime']:SetSkinName("textview");
    cd_buttons['skilltime']:EnableHitTest(0)

    cd_buttons['skillhelp'] = cdTrackerSkillsUI:CreateOrGetControl('richtext','CDTRACKER_SKILLHELP',20,475,200,30)
    cd_buttons['skillhelp'] = tolua.cast(cd_buttons['skillhelp'],'ui::CRichText')
    cd_buttons['skillhelp']:SetText('{@st66b}{#ffffff}Right-click to return to the main menu.{/}')
    cd_buttons['skillhelp']:SetSkinName("textview");
    cd_buttons['skillhelp']:EnableHitTest(0)

    offset = 0
    for k, v in ipairs(skillList) do

        -- cd_buttons['groupbox'..k] = cdGroupBox:CreateOrGetControl('frame','CD_GROUPBOX_'..k, 10,10+offset,400,30)

        -- cd_buttons['groupbox'..k] = tolua.cast(cd_buttons['groupbox'..k],'ui::CFrame')
        --         cd_buttons['groupbox'..k]:SetLayerLevel(1000)
        -- cd_buttons['groupbox'..k]:SetSkinName("textview");
        skillname = v:gsub('%[Skill%]','')

        cd_buttons['skill'..k] = cdGroupBox:CreateOrGetControl('richtext','CDTRACKER_BUTTON_SKILL_'..k,10,10+offset,100,100)
        cd_buttons['skill'..k] = tolua.cast(cd_buttons['skill'..k],'ui::CRichText')
        cd_buttons['skill'..k]:SetText('{@st66b}{#ffff55}[Skill]{#ffffff}'..skillname..'{/}')
        cd_buttons['skill'..k]:EnableHitTest(0)

        cd_buttons['skillalert'..k] = cdGroupBox:CreateOrGetControl('checkbox','CDTRACKER_BUTTON_SKILLALERT_'..k,300,10+offset,100,100)
        cd_buttons['skillalert'..k] = tolua.cast(cd_buttons['skillalert'..k],'ui::CCheckBox')
        cd_buttons['skillalert'..k]:Resize(20,20)
        if settings.ignoreList[v] == true then
            cd_buttons['skillalert'..k]:SetCheck(0)
        else
            cd_buttons['skillalert'..k]:SetCheck(1)
        end
        cd_buttons['skillalert'..k]:SetEventScript(ui.LBUTTONUP,"ui.Chat('/cd alert "..k.."') CDTRACKER_COPYSETTINGS() if settings.ignoreList[v] == true then cd_buttons['skillalert'..k]:SetCheck(0) else cd_buttons['skillalert'..k]:SetCheck(1) end")



        cd_buttons['skillchat'..k] = cdGroupBox:CreateOrGetControl('checkbox','CDTRACKER_BUTTON_SKILLCHAT_'..k,400,10+offset,100,100)
        cd_buttons['skillchat'..k] = tolua.cast(cd_buttons['skillchat'..k],'ui::CCheckBox')
        cd_buttons['skillchat'..k]:Resize(20,20)
        if settings.chatList[v] == true then
            cd_buttons['skillchat'..k]:SetCheck(1)
        end
        cd_buttons['skillchat'..k]:SetEventScript(ui.LBUTTONUP,"ui.Chat('/cd chat "..k.."') CDTRACKER_COPYSETTINGS() if settings.chatList[v] == true then cd_buttons['skillchat'..k]:SetCheck(1) else cd_buttons['skillchat'..k]:SetCheck(0) end")

        cd_buttons['skillmessage'..k] = cdGroupBox:CreateOrGetControl('button','CDTRACKER_BUTTON_SKILLMESSAGE'..k, 450,10+offset,200,25)
        cd_buttons['skillmessage'..k] = tolua.cast(cd_buttons['skillmessage'..k],'ui::CButton')
        if settings.message[v] ~= nil then
            cd_buttons['skillmessage'..k]:SetText('{@st46b}{s12}{#ffffff}'..settings.message[v]..'{/}')
            cd_buttons['skillmessage'..k]:SetTextTooltip('{@st46b}{s12}{#ffffff}'..settings.message[v]..'{/}')
        else
            cd_buttons['skillmessage'..k]:SetText('{@st46b}{s12}{#ffffff}Set Message{/}')
            cd_buttons['skillmessage'..k]:SetTextTooltip('{@st46b}{s12}{#ffffff}Set Message{/}')
        end
        cd_buttons['skillmessage'..k]:Resize(200,25)
        cd_buttons['skillmessage'..k]:SetClickSound("button_click_big");
        cd_buttons['skillmessage'..k]:SetOverSound("button_over");
        -- cd_buttons['skillmessage'..k]:SetEventScript(ui.LBUTTONUP, "CD_LIST");
        cd_buttons['skillmessage'..k]:SetSkinName('quest_box')
        cd_buttons['skillmessage'..k]:SetEventScript(ui.LBUTTONUP,"CD_SET_CHAT_MESSAGE("..k..")")
        -- cd_buttons['skillmessage'..k]:EnableImageStretch(true)
        -- cd_buttons['skillmessage'..k]:SetImage("btn_partyshare"); 
        -- cd_buttons['skillmessage'..k]:Resize(200,25)

        cd_buttons['skilltime'..k] = cdGroupBox:CreateOrGetControl('edit','CDTRACKER_SKILLTIME'..k, 685,10+offset,50,30)
        cd_buttons['skilltime'..k] = tolua.cast(cd_buttons['skilltime'..k],'ui::CEditControl')

        cd_buttons['skilltimelabel'..k] = cd_buttons['skilltime'..k]:CreateOrGetControl('richtext','CDTRACKER_SKILLTIMELABEL'..k, 0,0,30,30)
        cd_buttons['skilltimelabel'..k] = tolua.cast(cd_buttons['skilltimelabel'..k],'ui::CRichText')
        cd_buttons['skilltimelabel'..k]:SetGravity(ui.CENTER_HORZ,ui.CENTER_VERT)
        cd_buttons['skilltimelabel'..k]:EnableHitTest(0)

        if settings.time[v] == nil then
            cd_buttons['skilltimelabel'..k]:SetText('{@st66b}{#ffffff}'..settings.checkVal)
        else
            cd_buttons['skilltimelabel'..k]:SetText('{@st66b}{#ffffff}'..settings.time[v])
        end

        cd_buttons['skilltime'..k]:SetEventScript(ui.LBUTTONUP,"cd_buttons['skilltimelabel"..k.."']:ShowWindow(0)")
        cd_buttons['skilltime'..k]:SetLostFocusingScp("cd_buttons['skilltimelabel"..k.."']:ShowWindow(1)")
        cd_buttons['skilltime'..k]:SetEventScript(ui.ENTERKEY,"CD_SET_TIME("..k..")")


        -- cd_buttons['skilltime'..k]:SetGravity(ui.CENTER_HORZ,ui.CENTER_VERT)

        cd_buttons['skill_'..k] = cdGroupBox:CreateOrGetControl('richtext','CDTRACKER_BUTTON_SKILL__'..k,10,25+offset,100,5)
        cd_buttons['skill_'..k] = tolua.cast(cd_buttons['skill_'..k],'ui::CRichText')
        cd_buttons['skill_'..k]:SetText('{@st66b}{#708090}'..dots..'{/}')
        cd_buttons['skill_'..k]:EnableHitTest(0)
        -- cd_buttons['skill'..k]:SetSkinName("box_glass");
        -- cdTrackerSkillsUI:Invalidate()
        -- cd_buttons['skillmessage'..k]:Invalidate()
        -- cdGroupBox:Invalidate()
        offset = offset+35
    end

    for k,v in ipairs(buffList) do 
        buffname = v:gsub('%[Buff%]','')
        cd_buttons['buff'..k] = cdGroupBox:CreateOrGetControl('richtext','CDTRACKER_BUTTON_BUFF_'..k,10,10+offset,100,100)
        cd_buttons['buff'..k] = tolua.cast(cd_buttons['buff'..k],'ui::CRichText')
        cd_buttons['buff'..k]:SetText('{@st66b}{#ccffff}[Buff]{#ffffff}'..buffname..'{/}')
        cd_buttons['buff'..k]:EnableHitTest(0)

        cd_buttons['buffalert'..k] = cdGroupBox:CreateOrGetControl('checkbox','CDTRACKER_BUTTON_BUFFALERT_'..k,300,10+offset,100,100)
        cd_buttons['buffalert'..k] = tolua.cast(cd_buttons['buffalert'..k],'ui::CCheckBox')
        cd_buttons['buffalert'..k]:Resize(20,20)
        if settings.ignoreList[v] == true then
            cd_buttons['buffalert'..k]:SetCheck(0)
        else
            cd_buttons['buffalert'..k]:SetCheck(1)
        end
        cd_buttons['buffalert'..k]:SetEventScript(ui.LBUTTONUP,"ui.Chat('/cd alert "..k+#skillList.."') CDTRACKER_COPYSETTINGS() if settings.ignoreList[v] == true then cd_buttons['buffalert'..k]:SetCheck(0) else cd_buttons['buffalert'..k]:SetCheck(1) end")

        cd_buttons['buff_'..k] = cdGroupBox:CreateOrGetControl('richtext','CDTRACKER_BUTTON_BUFF__'..k,10,25+offset,100,5)
        cd_buttons['buff_'..k] = tolua.cast(cd_buttons['buff_'..k],'ui::CRichText')
        cd_buttons['buff_'..k]:SetText('{@st66b}{#708090}'..dots..'{/}')
        cd_buttons['buff_'..k]:EnableHitTest(0)
        offset = offset+35
    end

end

function TOGGLE_CD(setting)
    CDTRACKER_COPYSETTINGS()
    if setting == 'enabled' then
        if settings.alerts then
            ui.Chat('/cd off')
        else
            ui.Chat('/cd on')
        end
        CDTRACKER_COPYSETTINGS()
        if settings.alerts then enabled = '{#00cc00}on' else enabled = '{#cc0000}off' end
        cd_buttons['enabled']:SetText('{@st66b}{#ffffff}cdtracker:'..enabled..'{/}')
        return;
    end
    ui.Chat('/cd '..setting)
    CDTRACKER_COPYSETTINGS()
    if settings[setting] then enabled = '{#00cc00}on' else enabled = '{#cc0000}off' end
    cd_buttons[setting]:SetText('{@st66b}{#ffffff}'..setting..':'..enabled..'{/}')

end


function CDTRACKER_TOGGLE_FRAME()
    cdTrackerUI = ui.GetFrame('CDTRACKER_UI')
    if cdTrackerUI == nil then
        CDTRACKER_CREATE_FRAME()
    elseif cdTrackerUI:IsVisible() == 1 then
        cdTrackerUI:ShowWindow(0)
    end
end

function CD_SET_TIME(id)
    time = cd_buttons['skilltime'..id]:GetText()

    ui.Chat('/cd time '..id..' '..time)
    
    
    cd_buttons['skilltimelabel'..id]:SetText('{@st66b}{#ffffff}'..time..'{/}')
    cd_buttons['skilltimelabel'..id]:ShowWindow(1)
    cd_buttons['skilltime'..id]:SetText('')
    cd_buttons['skilltime'..id]:ReleaseFocus()

end

function CD_SET_MAIN_TIME()
    time = cd_buttons['timebox']:GetText()

    ui.Chat('/cd '..time)
    cd_buttons['timelabel']:SetText('{@st66b}{#ffffff}'..time..'{/}')
    cd_buttons['timelabel']:ShowWindow(1)

    CDTRACKER_CREATE_FRAME()
    cd_buttons['timebox']:SetText('')
    cd_buttons['timebox']:ReleaseFocus()

end

function CD_SET_SIZE()
    size = cd_buttons['sizebox']:GetText()

    ui.Chat('/cd size '..size)
    cd_buttons['sizelabel']:SetText('{@st66b}{#ffffff}'..size..'{/}')
    cd_buttons['sizelabel']:ShowWindow(1)

    CDTRACKER_CREATE_FRAME()
    cd_buttons['sizebox']:SetText('')
    cd_buttons['sizebox']:ReleaseFocus()
end


function CD_SEND_CHAT_MESSAGE(id)
    message = cd_buttons['skillmessageinput'..id]:GetText()
    ui.Chat('/cd chat '..id..' '..message)

    cd_buttons['skillmessage'..id]:SetText('{@st46b}{s12}{#ffffff}'..message..'{/}')
    ui.DestroyFrame('CDTRACKER_INPUT')
    CD_LIST()


end


function CD_SET_CHAT_MESSAGE(id)
    cdTrackerInput =  ui.CreateNewFrame('cdtracker','CDTRACKER_INPUT')
    cdTrackerInput:SetLayerLevel(1001)
    cdTrackerInput:EnableHitTest(1)
    cdTrackerInput:Resize(500,50)
    cd_buttons['skillmessageinput'..id] = cdTrackerInput:CreateOrGetControl('edit','CDTRACKER_SKILLMESSAGEINPUT'..id, 0,0,500,30)
    cd_buttons['skillmessageinput'..id] = tolua.cast(cd_buttons['skillmessageinput'..id],'ui::CEditControl')
    cd_buttons['skillmessageinput'..id]:AcquireFocus()
    -- cd_buttons['skillmessageinput']:MakeTextPack()
    cd_buttons['skillmessageinput'..id]:SetEnable(1)
    -- cd_buttons['skillmessageinput'..id]:SetText('enter message')
    cd_buttons['skillmessageinput'..id]:SetEventScript(ui.ENTERKEY,"CD_SEND_CHAT_MESSAGE("..id..")")
    -- cd_buttons['skillmessageinput']:SetText('{@st66b}{#ffffff}Name{/}')
    -- cd_buttons['skillmessageinput']:SetSkinName("textview");
    -- cd_buttons['skillmessageinput']:EnableHitTest(0)
    -- CHAT_SYSTEM("CD_SEND_CHAT_MESSAGE("..id..","..cd_buttons['skillmessageinput']:GetText()..")")
    -- "CD_SEND_CHAT_MESSAGE("..","..cd_buttons['skillmessageinput']:GetText()
-- CHAT_SYSTEM("CD_SEND_CHAT_MESSAGE("..id..",".."'"..cd_buttons['skillmessageinput'..id]:GetText().."'"..")")

end
CDTRACKER_COPYSETTINGS()

print("Successfully loaded UI.")