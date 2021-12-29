------- Place Insight CA --------------

local AH = wesnoth.require "ai/lua/ai_helper.lua"
local IS = wesnoth.require "~add-ons/Archaic_Resources/ai/ca_insight_move.lua"

local ca_place_insight = {}

function ca_place_insight:evaluation(cfg, data, filter_own)
    local start_time, ca_name = wesnoth.ms_since_init() / 1000., 'place_insight'
    if AH.print_eval() then AH.print_ts('     - Evaluating place_insight CA:') end

    if IS:evaluation({ { 'filter', filter_own } }, data) > 0 then
        if AH.print_eval() then AH.done_eval_messages(start_time, ca_name) end
        -- return 96000 -- change this to something higher than combat CA score
        return 191005 -- higher than AI_CA_GRAB_VILLAGES_SCORE
    end
    if AH.print_eval() then AH.done_eval_messages(start_time, ca_name) end
    return 0
end

function ca_place_insight:execution(cfg, data)
    if AH.print_exec(cfg, data) then AH.print_ts('   Executing place_insight CA') end
    IS:execution()
end

return ca_place_insight
