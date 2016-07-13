local frame = nil
local startTime = imcTime.GetAppTime()
local timeElapsed = 0
local stat = info.GetStat(session.GetMyHandle())
local SP = stat.SP

function REGENTIMER_ON_INIT(addon, frame)
    frame = ui.CreateNewFrame('bandicam','REGEN_TIMER_FRAME')
    frame:ShowWindow(1)
    frame:SetBorder(5, 0, 0, 0)
    regentime = frame:CreateOrGetControl('richtext','regentimetext',0,0,0,0)
    regentime = tolua.cast(regentime,'ui::CRichText')
    regentime:SetGravity(ui.CENTER_HORZ,ui.CENTER_VERT)
    REGEN_TIMER = GET_CHILD(frame, "addontimer", "ui::CAddOnTimer");
    REGEN_TIMER:SetUpdateScript('REGEN_TIMER_UPDATE');
    REGEN_TIMER:EnableHideUpdate(1)
    REGEN_TIMER:Stop();
    REGEN_TIMER:Start(0.2);
end

function REGEN_TIMER_UPDATE()
    local timePassed = imcTime.GetAppTime() - startTime
 
    if math.floor(timePassed) > timeElapsed then
        -- ui.AddText('SystemMsgFrame',timeElapsed)
        if timePassed >= 10 then 
            regentime:SetText('{@st41}{s18}{#009933}Sit')
        else
            regentime:SetText('{@st41}{s18}'..math.floor(timePassed))
        end
        timeElapsed = timeElapsed+1
    end
    if stat.SP > SP then
        startTime = imcTime.GetAppTime()
        SP = stat.SP
        timeElapsed = 0
        regentime:SetText('{@st41}{s18}0')
    end
    SP = stat.SP
end
