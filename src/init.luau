--!strict
-- Awake: keeps the Mac awake from a button beside the window's buttons, of
-- three modes, which the button's menu, the commands and a submenu of View
-- choose: Default, the system's rules of sleep; Stay Awake, the system and
-- the display kept awake; and Sleep After Jobs, the system kept awake
-- while a tab runs a program, as the tabs' marks tell, and let sleep once
-- the last one ends. Every launch starts in Default.

-- A mode: "default", "stay" or "after-jobs".
type Mode = string

local Plugin: Plugin = {}

-- The modes, in their menus' order, and the command of each.
local MODES: { Mode } = { "default", "stay", "after-jobs" }
local COMMANDS: { [Mode]: string } = {
    default = "awake.default",
    stay = "awake.stay",
    ["after-jobs"] = "awake.after-jobs",
}
local TITLES: { [Mode]: string } = {
    default = "Sleep as Usual",
    stay = "Stay Awake",
    ["after-jobs"] = "Sleep After Jobs",
}

-- The button's key, and its menu's panel.
local BUTTON = "button"
local MENU = "menu"

local mode: Mode = "default"
-- What the host keeps from idle sleep for the plugin.
local kept: Awake = "off"
-- Whether a tab runs a program, of the last read of the tabs.
local busy = false
-- The button's views, one of each window, that showed.
local views: { ViewId } = {}

-- Whether a tab of a window runs a program, as its marks tell.
local function running(cx: Cx): boolean
    local windows = cx.windows()
    if windows == nil then
        return false
    end
    for _, window in windows do
        local tabs = cx.tabs(window.id)
        if tabs ~= nil then
            for _, tab in tabs do
                if tab.running then
                    return true
                end
            end
        end
    end
    return false
end

-- What the mode keeps from idle sleep now.
local function wanted(): Awake
    local awake: Awake = "off"
    if mode == "stay" then
        awake = "display"
    elseif mode == "after-jobs" and busy then
        awake = "system"
    end
    return awake
end

-- The submenu of View of the modes, the one in force ticked, which takes
-- the commands' own places in the menu.
local function menu(cx: Cx)
    for _, each in MODES do
        assert(cx.add_menu_item({
            place = { bar = "view" },
            command = COMMANDS[each],
            title = "awake-mode-" .. each,
            submenu = "awake-submenu",
            ticked = mode == each,
        }))
    end
end

-- Keeps what the mode wants from idle sleep, and shows it: the submenu's
-- tick and each window's button.
local function show(cx: Cx)
    local now: Awake = wanted()
    if now ~= kept then
        assert(cx.keep_awake(now))
        kept = now
    end
    menu(cx)
    for _, view in views do
        cx.request_render(view)
    end
end

local function set(cx: Cx, chosen: Mode)
    mode = chosen
    busy = mode == "after-jobs" and running(cx)
    show(cx)
end

function Plugin.activate(cx: Cx)
    for _, each in MODES do
        assert(cx.register_command({ name = COMMANDS[each], title = TITLES[each], category = "view" }))
    end
    assert(cx.subscribe({ "tab-created", "tab-changed", "tab-closed" }))
    menu(cx)
end

function Plugin.on_command(cx: Cx, name: string, args: Args)
    for _, each in MODES do
        if COMMANDS[each] == name then
            set(cx, each)
        end
    end
end

-- The tabs' changes, as a program starts or ends in one, which Sleep After
-- Jobs follows.
function Plugin.on_event(cx: Cx, events: { Event })
    if mode ~= "after-jobs" then
        return
    end
    local now = running(cx)
    if now ~= busy then
        busy = now
        show(cx)
    end
end

-- The button's icon and tooltip, of the mode and of whether a program
-- keeps the Mac awake: a closed eye, the steaming cup, or a pulse.
local function look(cx: Cx): (string, string)
    if mode == "stay" then
        return "coffee", cx.message("awake-tooltip-stay") or "Awake: the Mac stays awake"
    elseif mode == "after-jobs" and busy then
        return "coffee", cx.message("awake-tooltip-after-jobs-busy") or "Awake: kept awake until the jobs end"
    elseif mode == "after-jobs" then
        return "pulse", cx.message("awake-tooltip-after-jobs-idle") or "Awake: sleeps as usual, as no job runs"
    end
    return "eye-closed", cx.message("awake-tooltip-default") or "Awake: the Mac sleeps as usual"
end

function Plugin.render(cx: Cx, view: ViewId): Node?
    local seen = view :: any
    if seen.panel == MENU then
        local items: { Node } = {}
        for _, each in MODES do
            table.insert(items, {
                kind = "toggle",
                key = each,
                text = cx.message("awake-mode-" .. each) or TITLES[each],
                on = mode == each,
            })
        end
        return { kind = "container", key = "modes", children = items }
    end
    if seen.title_buttons == nil then
        return nil
    end
    local known = false
    for _, shown in views do
        known = known or (shown :: any).title_buttons == seen.title_buttons
    end
    if not known then
        table.insert(views, view)
    end
    local icon, tooltip = look(cx)
    return {
        kind = "button",
        key = BUTTON,
        icon = icon,
        tooltip = tooltip,
        style = {
            background = "transparent",
            -- The accent while the Mac is kept awake.
            color = if kept ~= "off" then "accent" else nil,
            radius = 5,
            hover = { background = "button.hover.bg" },
            pressed = { background = "button.pressed.bg" },
            transition = { duration = 0.12 },
        },
    }
end

function Plugin.on_ui_event(cx: Cx, event: UiEvent)
    local happened = event :: any
    if happened.key == BUTTON and happened.kind == "click" then
        assert(cx.open_panel(MENU, {
            anchor = { node = { view = happened.view, key = BUTTON } },
            role = "menu",
            close_outside = true,
            close_escape = true,
        }))
    elseif happened.kind == "toggle" then
        for _, each in MODES do
            if happened.key == each then
                cx.close_panel(MENU)
                set(cx, each)
            end
        end
    end
end

return Plugin
