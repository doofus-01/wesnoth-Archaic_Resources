-----------------------------------------------
-- WML tags for UI
------------------------------------------------

-- shows a simple Y/N message box
-- 
--[[

[arc_message_box]
  title=
  message=
  variable=
[/arc_message_box]

]]--

function wesnoth.wml_actions.arc_message_box(cfg)
        local amb_title = tostring(cfg.title or "No title available") 
        local amb_message = tostring(cfg.message or "No message available") 
        -- or helper.wml_error "[arc_message_box] expects a message= attribute."
        local amb_variable = cfg.variable or helper.wml_error "[arc_message_box] expects a variable= attribute."
        local result = wesnoth.show_message_box(amb_title, amb_message, "yes_no", false)
        if result then
            wesnoth.set_variable(amb_variable, "yes")
        else
            wesnoth.set_variable(amb_variable, "no")
        end
end
