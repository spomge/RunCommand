
if plugin == nil then
	return
end

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")
local ScriptEditorService = game:GetService("ScriptEditorService")
local HttpService = game:GetService("HttpService")

local toolbar = plugin:CreateToolbar("CDT Studio Tools")

local openScriptButton = toolbar:CreateButton("Open Script", "Open RunCommands", "rbxassetid://14978048121")
local runScriptButton: PluginToolbarButton = toolbar:CreateButton("Run Script", "Create an RunCommand", "rbxassetid://14978048121")

runScriptButton.ClickableWhenViewportHidden = true
openScriptButton.ClickableWhenViewportHidden = true
runScriptButton.Enabled = false

local function GetRunCommandFolder()
	local runCommandFolder = game:GetService("ServerScriptService"):FindFirstChild("RunCommands")
	if not runCommandFolder then
		runCommandFolder = Instance.new("Folder")
		runCommandFolder.Name = "RunCommands"
		runCommandFolder.Parent = game:GetService("ServerScriptService")
	end
	return runCommandFolder
end

local function ExecuteScript(selectedScript: Script)
	local runCommandFolder = GetRunCommandFolder()
	local newScript = Instance.new("ModuleScript")
	newScript.Name = HttpService:GenerateGUID()
	
	local wrapperCode = `\
		local thread = coroutine.create(function() {selectedScript.Source} end)\
		return thread\
	`
	ScriptEditorService:UpdateSourceAsync(newScript, function(oldContent)
		return wrapperCode
	end)

	local thread: thread
	local destroyListener = selectedScript:GetPropertyChangedSignal("Parent"):Connect(function()
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
	local selectedObjects = Selection:Get()
	local parent = game:GetService("ServerScriptService")
	for _, selected in selectedObjects do
		if selected:IsA("Script") then
			ExecuteScript(selected)
		end
	end
end


local function onOpenScriptButtonClicked()
	local runCommandFolder = GetRunCommandFolder()
	local newScript = Instance.new("Script")
	newScript.Name = "NewCommand"
	
	newScript.Source = [[-- Click Run Script to execute!
print("Hello World")
]]
	newScript.Parent = runCommandFolder
	Selection:Set({ newScript })
	plugin:OpenScript(newScript)
end

openScriptButton.Click:Connect(onOpenScriptButtonClicked)
runScriptButton.Click:Connect(onRunScriptButtonClicked)

Selection.SelectionChanged:Connect(function()
	local selectedObjects = Selection:Get()
	for _, selected in selectedObjects do
		if selected:IsA("Script") then
			runScriptButton.Enabled = true
			return
		end
	end
	runScriptButton.Enabled = false
end)
