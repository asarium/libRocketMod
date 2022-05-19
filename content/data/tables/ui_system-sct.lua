
local updateCategory = engine.createTracingCategory("UpdateRocket", false)
local renderCategory = engine.createTracingCategory("RenderRocket", true)

RocketUiSystem = {
    replacements = {},
	substate = "none"
}

RocketUiSystem.context = rocket:CreateContext("menuui", Vector2i.new(gr.getCenterWidth(), gr.getCenterHeight()));

function RocketUiSystem:init()
    for _, v in ipairs(cf.listFiles("data/config", "*-ui.cfg")) do
        parse.readFileText(v, "data/config")

        parse.requiredString("#State Replacement")

        while parse.optionalString("$State:") do
            local state = parse.getString()

			if state == "GS_STATE_SCRIPTING" then
				parse.requiredString("+Substate:")
				local state = parse.getString()
				parse.requiredString("+Markup:")
				local markup = parse.getString()
				ba.print("SCPUI found definition for script substate " .. state .. " : " .. markup .. "\n")
				self.replacements[state] = {
					markup = markup
				}
			else
				parse.requiredString("+Markup:")
				local markup = parse.getString()
				ba.print("SCPUI found definition for game state " .. state .. " : " .. markup .. "\n")
				self.replacements[state] = {
					markup = markup
				}
			end
        end

        parse.requiredString("#End")

        parse.stop()
    end
end

function RocketUiSystem:getDef(state)
    return self.replacements[state]
end

function RocketUiSystem:stateStart()

	--This allows for states to correctly return to the previous state even if has no rocket ui defined
	RocketUiSystem.currentState = ba.getCurrentGameState()
	
    if not self:hasOverrideForState(getRocketUiHandle(hv.NewState)) then
        return
    end

    local def = self:getDef(getRocketUiHandle(hv.NewState).Name)
    def.document = self.context:LoadDocument(def.markup)
    def.document:Show()

    ui.enableInput(self.context)
end

function RocketUiSystem:stateFrame()
    if not self:hasOverrideForCurrentState() then
        return
    end

    -- Add some tracing scopes here to see how long this stuff takes
    updateCategory:trace(function()
        self.context:Update()
    end)
    renderCategory:trace(function()
        self.context:Render()
    end)
end

function RocketUiSystem:stateEnd()

	--This allows for states to correctly return to the previous state even if has no rocket ui defined
	RocketUiSystem.lastState = RocketUiSystem.currentState

    if not self:hasOverrideForState(getRocketUiHandle(hv.OldState)) then
        return
    end

    local def = self:getDef(getRocketUiHandle(hv.OldState).Name)

    def.document:Close()
    def.document = nil

    ui.disableInput()
	
	if hv.OldState.Name == "GS_STATE_SCRIPTING" then
		RocketUiSystem.substate = "None"
	end
end

function getRocketUiHandle(state)
    if state.Name == "GS_STATE_SCRIPTING" then
        return {Name = RocketUiSystem.substate}
    else
        return state
    end
end

function RocketUiSystem:beginSubstate(state) 
	RocketUiSystem.substate = state
	ba.postGameEvent(ba.GameEvents["GS_EVENT_SCRIPTING"])
end

--This allows for states to correctly return to the previous state even if has no rocket ui defined
function RocketUiSystem:ReturnToState(state)

	local event

	if state.Name == "GS_STATE_BRIEFING" then
		event = "GS_EVENT_START_BRIEFING"
	else
		event = string.gsub(state.Name, "STATE", "EVENT")
	end

	ba.postGameEvent(ba.GameEvents[event])

end

function RocketUiSystem:hasOverrideForState(state)
    return self:getDef(state.Name) ~= nil
end

function RocketUiSystem:hasOverrideForCurrentState()
    return self:hasOverrideForState(getRocketUiHandle(ba.getCurrentGameState()))
end

RocketUiSystem:init()

engine.addHook("On State Start", function()
    RocketUiSystem:stateStart()
end, {}, function()
    return RocketUiSystem:hasOverrideForState(getRocketUiHandle(hv.NewState))
end)

engine.addHook("On Frame", function()
    RocketUiSystem:stateFrame()
end, {}, function()
    return RocketUiSystem:hasOverrideForCurrentState()
end)

engine.addHook("On State End", function()
    RocketUiSystem:stateEnd()
end, {}, function()
    return RocketUiSystem:hasOverrideForState(getRocketUiHandle(hv.OldState))
end)

