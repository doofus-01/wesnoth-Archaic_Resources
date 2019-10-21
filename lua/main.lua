
helper = wesnoth.require "lua/helper.lua"
T = wml.tag
items = wesnoth.require "lua/wml/items.lua"
_ = wesnoth.textdomain "wesnoth-Archaic_Era"
                


function z_require(script)
        return wesnoth.dofile('~add-ons/Archaic_Resources/lua/' .. script .. '.lua')
end

-- arc_menus = z_require("arc_menus")
arc_wml_tags = z_require("arc_wml_tags")
