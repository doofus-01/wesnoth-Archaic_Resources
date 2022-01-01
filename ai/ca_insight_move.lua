----------- Insight (ability) Movement CA ------------------
-- adapted from healers MAI

local AH = wesnoth.require "ai/lua/ai_helper.lua"
local BC = wesnoth.require "ai/lua/battle_calcs.lua"
local M = wesnoth.map

-- local ca_insight_move, best_healer, best_hex = {}
local ca_insight_move, best_insighter, best_hex = {}

function ca_insight_move:evaluation(cfg, data)
    -- Should happen with higher priority than attacks of all same-side units
    -- This is done so that it is possible for healers to attack, if they do not
    -- find an appropriate hex to back up other units
    local score = data.IS_insight_move_score or 96000

    local all_insighters = wesnoth.units.find_on_map {
        side = wesnoth.current.side,
        ability = "aa_insight",
        { "and", wml.get_child(cfg, "filter") }
    }

    local insighters, insighters_noMP = {}, {}
    for _,insighter in ipairs(all_insighters) do
        -- For the purpose of this evaluation, guardians count as units without moves, as do passive leaders
        if (insighter.moves > 0) and (not insighter.status.guardian)
            and ((not insighter.canrecruit) or (not ai.aspects.passive_leader))
        then
            table.insert(insighters, insighter)
        else
            table.insert(insighters_noMP, insighter)
        end
    end
    if (not insighters[1]) then return 0 end

    local all_insightees = wesnoth.units.find_on_map {
        side = wesnoth.current.side,
        { "and", wml.get_child(cfg, "filter_second") }
    }

    local insightees, insightees_MP = {}, {}
    for _,insightee in ipairs(all_insightees) do
        -- Potential insightees are units without MP that don't already have an insighter (also without MP) next to them
        -- Also, they must be next to an enemy unit - FLAG: this part needs better evaluation
        if (insightee.moves == 0) then
            if (not insightee:matches { ability = "aa_insight" }) then -- expand this to other c_t_h specials/abilities, like magic or marksman
                -- local healing = wesnoth.terrain_types[wesnoth.current.map[healee]].healing
                -- if (healing == 0) then
                    local is_insightee = true
                    for _,insighter in ipairs(insighters_noMP) do
                        if (M.distance_between(insightee.x, insightee.y, insighter.x, insighter.y) == 1) then
                            is_insightee = false
                            break
                        end
                    end
                    if is_insightee then table.insert(insightees, insightee) end
                -- end
            end
        else
            table.insert(insightees_MP, insightee)
        end
    end

    local enemies = AH.get_attackable_enemies()
    for _,insightee in ipairs(insightees_MP) do insightee:extract() end -- removing insightees who could move out of the enemy's way
    local enemy_attack_map = BC.get_attack_map(enemies)
    for _,insightee in ipairs(insightees_MP) do insightee:to_map() end -- putting them back

    -- Other options of adding avoid zones may be added later
    local avoid_map = AH.get_avoid_map(ai, nil, true)

    local max_rating = - math.huge
    for _,insighter in ipairs(insighters) do
        local reach_map = AH.get_reachmap(insighter, { avoid_map = avoid_map, exclude_occupied = true })
        reach_map:iter( function(x, y, v)
            -- Only consider hexes that are next to at least one noMP unit that
            --  - can be attacked by an enemy (25 points per enemy)
            --  - (anything else? -> yes, try adding base 1pt per insightee, even if there are no enemies nearby)

            -- local rating, adjacent_healer = 0
            local rating = 0
            for _,insightee in ipairs(insightees) do
                if (M.distance_between(insightee.x, insightee.y, x, y) == 1) then
                    rating = rating + 1 + 25 * (enemy_attack_map.units:get(insightee.x, insightee.y) or 0)
                end
            end

            -- Number of enemies that can threaten the insighter at that position
            local enemies_in_reach = enemy_attack_map.units:get(x, y) or 0
            -- This has to be no larger than cfg.max_threats for hex to be considered

            -- If this hex fulfills those requirements, 'rating' is now greater than 0
            -- and we do the rest of the rating, otherwise set rating to below max_rating
            if (rating == 0) or (enemies_in_reach > (cfg.max_threats or 9999)) then
                rating = max_rating - 1
            else
                -- Strongly discourage hexes that can be reached by enemies (but less strongly than healers x1000 factor)
                rating = rating - enemies_in_reach * 500

                -- All else being more or less equal, prefer villages and strong terrain
                local terrain = wesnoth.current.map[{x, y}]
                local is_village = wesnoth.terrain_types[terrain].village
                if is_village then rating = rating + 2 end

                local defense = insighter:defense_on(terrain)
                rating = rating + defense / 10.
            end

            if (rating > max_rating) then
                max_rating, best_insighter, best_hex = rating, insighter, { x, y }
            end
        end)
    end

    if best_insighter then
        return score
    end

    return 0
end

function ca_insight_move:execution(cfg)
    AH.robust_move_and_attack(ai, best_insighter, best_hex)
    best_insighter, best_hex = nil, nil
end

return ca_insight_move
