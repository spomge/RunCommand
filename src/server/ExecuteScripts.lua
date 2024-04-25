-- Services
local ScriptEditorService = game:GetService("ScriptEditorService") 

-- Private Variables
local currentRunningScripts: {[{}]: thread} = {}

-- Global Variables
local module = {}

-- Runs a script
function module:runScript(script: Script): (cleanup: () -> ()) -> ()
    
	local newScript: ModuleScript = Instance.new("ModuleScript")
	newScript.Name = script.Name

	local wrapperCode = `\n return coroutine.create(function() {script.Source} end)`
	ScriptEditorService:UpdateSourceAsync(newScript, function(_)
		return wrapperCode
	end)

    local key = {}
	currentRunningScripts[key] = require(newScript) :: thread
	local destroyListener: RBXScriptConnection = script.AncestryChanged:Connect(function()
		if currentRunningScripts[key] and not script:IsDescendantOf(game) then
			coroutine.close(currentRunningScripts[key])
		end
	end)

	local success: boolean, runtimeErrorMessage: string = coroutine.resume(currentRunningScripts[key])

	if not success then
		warn(script.Name, " got this error: ")
		warn(runtimeErrorMessage)
	end

    local runningTask: thread = coroutine.create(function()
        
        while coroutine.status(currentRunningScripts[key]) ~= "dead" do
            task.wait(1)
        end

        currentRunningScripts[key] = nil

        if destroyListener then
            destroyListener:Disconnect()
            destroyListener = nil
        end
    
        if newScript then
            newScript:Destroy()
        end

    end)

    coroutine.resume(runningTask)

	return function(cleanup: () -> ()?)

        -- Stops running task if still running
        if coroutine.status(runningTask) == "suspended" then
            if currentRunningScripts[key] then
                coroutine.close(currentRunningScripts[key]) 
            end
        end

        -- Any other cleanup
        if cleanup then
            task.spawn(cleanup)
        end

    end

end

return module