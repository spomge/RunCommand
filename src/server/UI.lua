-- Services
local StudioService = game:GetService("StudioService")

-- Modules
local ExcuteScripts = require(script.Parent.ExecuteScripts)

local module = {

    -- MAYBE SOME STATE    

}

-- Plugin Visual Settings
function module:createPlugin(plugin: Plugin)


    local toolbar = plugin:CreateToolbar("CDT Studio Tools")

    local openGUIButton: PluginToolbarButton = toolbar:CreateButton(
        "Open Script", 
        "Open RunCommands", 
        "rbxassetid://14978048121"
    )

    local panicButton: PluginToolbarButton = toolbar:CreateButton(
        "Panic", 
        "Stops all scripts", 
        "rbxassetid://14978048121"
    )

    local runScriptFromEditorButton: PluginToolbarButton = toolbar:CreateButton(
        "Run From Editor", 
        "Create an RunCommand", 
        "rbxassetid://14978048121"
    )

    openGUIButton.ClickableWhenViewportHidden = true
    runScriptFromEditorButton.ClickableWhenViewportHidden = true
    panicButton.ClickableWhenViewportHidden = true

    runScriptFromEditorButton.Enabled = false
    openGUIButton.Enabled = true
    panicButton.Enabled = true

    -- Listens to when you are currently editing a script or not
    local currentlyEditing: LuaSourceContainer?
    StudioService:GetPropertyChangedSignal("ActiveScript"):Connect(function()

        local newScript: LuaSourceContainer? = StudioService.ActiveScript

        if not newScript then
            runScriptFromEditorButton.Enabled = false
        else
            runScriptFromEditorButton.Enabled = true
            currentlyEditing = newScript
        end 
        
    end)

    local currentlyRunningScripts: {() -> ()?} = {}
    runScriptFromEditorButton.Click:Connect(function()
        if currentlyEditing then
            table.insert(currentlyRunningScripts, ExcuteScripts:runScript(currentlyEditing :: Script))
        end
    end)

    panicButton.Click:Connect(function()
        
        for _ , runningCallbackCleanup in currentlyRunningScripts do 
            runningCallbackCleanup()
        end

        currentlyRunningScripts = {}

    end)

end

return module