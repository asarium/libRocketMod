local class = require("class")

local AbstractBriefingController = require("briefingCommon")

local CommandBriefingController = class(AbstractBriefingController)

function CommandBriefingController:init()
    --- @type cmd_briefing_stage[]
    self.stages = {}

    self.element_names = {
        pause_btn = "cmdpause_btn",
        last_btn = "cmdlast_btn",
        next_btn = "cmdnext_btn",
        prev_btn = "cmdprev_btn",
        first_btn = "cmdfirst_btn",
        text_el = "cmd_text_el",
        stage_text_el = "cmd_stage_text_el",
    }
end

function CommandBriefingController:initialize(document)
    AbstractBriefingController.initialize(self, document)

    local briefing = ui.CommandBriefing.getBriefing()
    for i = 1, #briefing do
        --- @type cmd_briefing_stage
        local stage = briefing[i]

        self.stages[i] = stage
    end

    self:go_to_stage(1)
end

function CommandBriefingController:acceptPressed()
    if mn.isRedAlertMission() then
        ba.postGameEvent(ba.GameEvents["GS_EVENT_RED_ALERT"])
    else
        ba.postGameEvent(ba.GameEvents["GS_EVENT_START_BRIEFING"])
    end
end

function CommandBriefingController:go_to_stage(stage_idx)
    self:leaveStage()

    local stage = self.stages[stage_idx]

    self:initializeStage(stage_idx, stage.Text, stage.AudioFilename)

    local aniWrapper = self.document:GetElementById("cmd_anim")
    if #stage.AniFilename > 0 then
        local aniEl = self.document:CreateElement("ani")
        aniEl:SetAttribute("src", stage.AniFilename)

        aniWrapper:ReplaceChild(aniEl, aniWrapper.first_child)
    else
        aniWrapper:RemoveChild(aniWrapper.first_child)
    end
end

return CommandBriefingController
