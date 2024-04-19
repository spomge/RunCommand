--!strict

if plugin == nil then
	return
end

--// Services
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")
local ScriptEditorService = game:GetService("ScriptEditorService")
local HttpService = game:GetService("HttpService")

--// Plugin Visual Settings
local toolbar = plugin:CreateToolbar("CDT Studio Tools")

local openScriptButton: PluginToolbarButton = toolbar:CreateButton("Open Script", "Open RunCommands", "rbxassetid://14978048121")
local runScriptButton: PluginToolbarButton = toolbar:CreateButton("Run Script", "Create an RunCommand", "rbxassetid://14978048121")

runScriptButton.ClickableWhenViewportHidden = true
openScriptButton.ClickableWhenViewportHidden = true
runScriptButton.Enabled = false

--// Creates a folder or fetches the current one 
local function GetRunCommandFolder(): Folder
	
	local runCommandFolder: Folder = game:GetService("ServerScriptService"):FindFirstChild("RunCommands") or Instance.new("Folder", game:GetService("ServerScriptService"))
	runCommandFolder.Name = "RunCommands"
	
	return runCommandFolder
	
end

--// Executes the script that is given to the function
local function ExecuteScript(selectedScript: Script)

	local runCommandFolder: Folder = GetRunCommandFolder()
	local newScript: ModuleScript = Instance.new("ModuleScript")
	
	newScript.Name = HttpService:GenerateGUID()

	local wrapperCode = `\
	local thread = coroutine.create(function() {selectedScript.Source} end)\
	return thread\
	`
	ScriptEditorService:UpdateSourceAsync(newScript, function(oldContent: string)
		return wrapperCode
	end)

	local thread: thread
	local destroyListener: RBXScriptConnection? = selectedScript:GetPropertyChangedSignal("Parent"):Connect(function()
		print("Destroying Module Script")
		if thread then
			coroutine.close(thread)
		end
	end)

	local success, runtimeError = pcall(function()
		thread = require(newScript)
	end)
	
	coroutine.resume(thread)
	
	while coroutine.status(thread) ~= "dead" do
		task.wait(1)
	end
	
	if destroyListener then
		destroyListener:Disconnect()
		destroyListener = nil
	end
	
	if newScript then
		newScript:Destroy()
	end
	
end

local function onRunScriptButtonClicked()
	local selectedObjects: {Instance} = Selection:Get()
	
	for _, selected in selectedObjects do
		if selected:IsA("Script") then
			ExecuteScript(selected)
		end
	end
	
end


local function onOpenScriptButtonClicked()
	
	local newScript: Script = Instance.new("Script", GetRunCommandFolder())
	newScript.Name = "NewCommand"

	newScript.Source = [[-- Click Run Script to execute!
		print("Hello World")
	]]
	
	Selection:Set({newScript})
	plugin:OpenScript(newScript)
end

--// Fires respective functions on mouse clicks
openScriptButton.Click:Connect(onOpenScriptButtonClicked)
runScriptButton.Click:Connect(onRunScriptButtonClicked)

--// When you select a different objects enable run script button
Selection.SelectionChanged:Connect(function()
	local selectedObjects: {Instance} = Selection:Get()
	
	for _, selected: Instance in selectedObjects do
		if selected:IsA("Script") then
			runScriptButton.Enabled = true
			return
		end
	end
	
	runScriptButton.Enabled = false
end)
