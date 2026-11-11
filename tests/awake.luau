--!strict
-- The plugin's tests, which `sleip test` runs on a host of the tests: each
-- function of the table a test, of a host of its own, which fails at its
-- first error, as `assert` raises it.

local test = {}

-- The button of the focused window, as the plugin renders it.
local function button(host: TestHost): Node
    return assert(host.render({ title_buttons = assert(host.window()) }))
end

-- The modes of the submenu of View that are ticked, by their commands.
local function ticked(host: TestHost): { string }
    local names = {}
    for _, item in host.menu_items() do
        assert(item.submenu == "awake-submenu", "each in the submenu")
        if item.ticked then
            table.insert(names, item.command)
        end
    end
    return names
end

function test.it_starts_in_default_letting_the_mac_sleep(host: TestHost)
    host.activate()
    local names = host.commands()
    for _, name in { "awake.default", "awake.stay", "awake.after-jobs" } do
        assert(table.find(names, name) ~= nil, name)
    end
    assert(host.awake() == "off")
    assert(#host.menu_items() == 3)
    assert(ticked(host)[1] == "awake.default" and #ticked(host) == 1)
    local shown = button(host)
    assert(shown.icon == "eye-closed" and (shown.text or "") == "", "an icon alone")
    assert(shown.tooltip == "Awake: the Mac sleeps as usual")
end

function test.stay_awake_keeps_the_system_and_the_display(host: TestHost)
    host.activate()
    host.command("awake.stay")
    assert(host.awake() == "display")
    assert(ticked(host)[1] == "awake.stay")
    local shown = button(host)
    assert(shown.icon == "coffee")
    assert(shown.style and shown.style.color == "accent", "the accent while awake")
    host.command("awake.default")
    assert(host.awake() == "off")
    assert(button(host).icon == "eye-closed")
end

function test.sleep_after_jobs_keeps_the_system_while_a_tab_runs_a_program(host: TestHost)
    host.activate()
    host.command("awake.after-jobs")
    assert(host.awake() == "off", "no program runs")
    assert(button(host).icon == "pulse")
    local first = assert(host.tab())
    local second = host.open_tab()
    host.set_tab_marks({ running = true }, second)
    assert(host.awake() == "system", "a program runs")
    assert(button(host).icon == "coffee")
    host.set_tab_marks({ running = true }, first)
    host.set_tab_marks({ running = false }, second)
    assert(host.awake() == "system", "the first tab's program runs still")
    host.set_tab_marks({}, first)
    assert(host.awake() == "off", "the last program ended")
    assert(button(host).icon == "pulse")
end

function test.a_program_runs_unheeded_in_the_other_modes(host: TestHost)
    host.activate()
    host.set_tab_marks({ running = true })
    assert(host.awake() == "off")
    -- Chosen while a program runs already, it keeps the Mac awake at once.
    host.command("awake.after-jobs")
    assert(host.awake() == "system")
    host.command("awake.stay")
    assert(host.awake() == "display")
end

function test.the_button_opens_the_modes_menu_whose_choice_sets_the_mode(host: TestHost)
    host.activate()
    local view = { title_buttons = assert(host.window()) }
    button(host)
    host.ui_event({ view = view, key = "button", kind = "click" })
    assert(host.panels()[1] == "menu", "its menu shows")
    local menu = assert(host.render({ panel = "menu" }))
    local items = assert(menu.children)
    assert(#items == 3 and items[1].kind == "toggle" and items[1].on, "Default ticked")
    assert(items[2].text == "Stay Awake" and not items[2].on)
    host.ui_event({ view = { panel = "menu" }, key = "stay", kind = "toggle", on = true })
    assert(host.awake() == "display")
    assert(#host.panels() == 0, "the menu closes")
end

return test
