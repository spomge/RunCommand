local Fusion = require(script.Parent.Packages.fusion)

local Value = Fusion.Value

return {

    savedLocalScripts = Value(),
    savedGlobalScripts = Value(),

    currentSelectedScripts = Value({}),
    currentEditorScipt = Value(),

}