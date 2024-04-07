-- for lazy programmers
local S = minetest.get_translator("fox_hunting")

local storage = minetest.get_mod_storage()

local TIME_LIMIT = tonumber(minetest.settings:get("fox_hunting_timeout")) or 10.0
local DIST_LIMIT = tonumber(minetest.settings:get("fox_hunting_distance")) or 1000.0

minetest.register_tool(
    "fox_hunting:scanner",
    {
        description = "Fox scanner",
        inventory_image = "fox_hunting_scanner.png",
        on_use = function(itemstack, user, pointed_thing)
            local pos = user:get_pos()
            minetest.chat_send_player(user:get_player_name(), S("Do not move while scanning (@1s)", TIME_LIMIT))
            local keys = storage:get_keys()
            for k, v in ipairs(keys) do
                local p = minetest.string_to_pos(v)

                if p then
                    -- Check is node not changed
                    local m = minetest.get_meta(p)
                    if m:get_string("fox_hunting") == "" then
                        -- Remove node from storage
                        storage:set_string(v, "")
                        minetest.log("warning", S("Incorrect fox beacon at @1", v))
                    else
                        -- Calculate distance
                        local s = vector.distance(pos, p)
                        if s < DIST_LIMIT then
                            minetest.after(
                                TIME_LIMIT * s / DIST_LIMIT,
                                function(user, pos, s)
                                    if (vector.distance(pos, user:get_pos()) < 1.0) then
                                        minetest.chat_send_player(user:get_player_name(), S("Fox in @1m", s))
                                    else
                                        minetest.chat_send_player(
                                            user:get_player_name(),
                                            S("Incorrect scan results - you are moved")
                                        )
                                    end
                                end,
                                user,
                                user:get_pos(),
                                s
                            )
                        end
                    end
                else
                    storage:set_string(v, "")
                end
            end
            return nil
        end
    }
)

minetest.register_node(
    "fox_hunting:beacon",
    {
        description = "Fox beacon",
        inventory_image = "fox_hunting_beacon.png",
        walkable = true,
        drawtype = "signlike",
        groups = {dig_immediate = 2, unbreakable = 1},
        tiles = {"fox_hunting_beacon.png"},
        -- Required: store the rotation in param2
        paramtype2 = "wallmounted",
        selection_box = {
            type = "wallmounted"
        },
        node_box = {
            type = "wallmounted"
        },
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            storage:set_string(minetest.pos_to_string(pos, 0), "1")
            local m = minetest.get_meta(pos)
            m:set_string("fox_hunting", "1")
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            storage:set_string(minetest.pos_to_string(pos, 0), "")
        end
    }
)

minetest.register_craft(
    {
        output = "fox_hunting:scanner",
        recipe = {
            {"default:steel_ingot", "default:steel_ingot"},
            {"default:steel_ingot", "default:steel_ingot"},
            {"default:stick", "default:stick"}
        }
    }
)

minetest.register_craft(
    {
        output = "fox_hunting:beacon",
        recipe = {
            {"", "default:steel_ingot", ""},
            {"default:steel_ingot", "default:stick", "default:steel_ingot"},
            {"", "default:steel_ingot", ""}
        }
    }
)
