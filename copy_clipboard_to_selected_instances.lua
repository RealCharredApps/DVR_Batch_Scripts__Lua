-- connect to fusion - based on docs
local fu = fu or Fusion()
-- print("Fusion: " .. tostring(fu))
local comp = fu:GetCurrentComp()
print("Comp: " .. tostring(comp))
-- check if the comp is valid
if not comp then
    print("No composition is currently open")
    return
end

-- get the clipboard 
local clipboard = fu:GetClipboard()
print("Clipboard: " .. tostring(clipboard))
print("Clipboard Tool: " .. tostring(clipboard.GetAttrs() or "nil"))

if not clipboard then
    print("No clipboard found. Copy a node first.")
    comp:unlock()
    return
end

function main()
    comp:Lock()

    -- get the selected tools 
    local selectedTools = comp:GetSelectedToolList()
    print("Selected tools: " .. tostring(selectedTools))
    if #selectedTools == 0 then
        print("No tools selected. Select nodes first.")
        comp:unlock()
        return
    end

    -- for each selected tool, paste clipboard instances underneath after the selected tool(s)
    for i, tool in ipairs(selectedTools) do
        print("Attempting to paste instances after: " .. tool.Name)
        local x, y = comp.CurrentFrame.FlowView:GetPos(tool)
        local clipboardInstance = clipboard:PasteInstance(tool)
        -- set the position of the instance
        comp.CurrentFrame.FlowView:SetPos(clipboardInstance, x + 1, y + 1)
        -- connect the output of select to instance Input
        print("Instances pasted after: " .. tool.Name)
        local connected = tool:ConnectInput("Output", clipboardInstance)
        if connected then
            print("Connected " .. tool.Name .. " to clipboard instance.")
        else
            print("Failed to connect " .. tool.Name .. " to clipboard instance.")
        end
    end

    -- unlock the comp
    comp:unlock()

    -- print the result
    print("Clipboard instances pasted after selected tools.")
end
