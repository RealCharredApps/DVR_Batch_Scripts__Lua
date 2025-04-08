-- Add Loaders Next to Selected Nodes
-- This script adds a Loader node next to each selected node in the Flow view

-- Get the current composition
comp = fusion:GetCurrentComp()

-- Verify we have a composition
if not comp then
    print("No composition is currently open")
    return
end

-- Lock the composition to prevent unnecessary updates
comp:Lock()

-- Get the list of selected tools
selectedTools = comp:GetToolList(true)  -- 'true' means only selected tools

-- Check if there are any selected tools
if not next(selectedTools) then
    print("No tools are selected. Please select at least one tool.")
    comp:Unlock()
    return
end

print("Selected tools: " .. #selectedTools)

-- Get the Flow view for proper positioning
flowView = comp.CurrentFrame.FlowView

-- Process each selected tool
for i, tool in pairs(selectedTools) do
    -- Get the tool's position in the flow
    local x, y = flowView:GetPos(tool)
    
    -- Position the loader to the right of the selected tool
    local loaderX = x + 1
    local loaderY = y
    
    -- Create a loader at this position
    local loader = comp:AddTool("Loader", loaderX, loaderY)
    
    -- Name the loader based on the selected tool's name
    local newName = "Loader_for_" .. tool.Name
    loader:SetAttrs({TOOLS_Name = newName})
    
    print("Added " .. newName .. " at position (" .. loaderX .. ", " .. loaderY .. ")")
end

-- Unlock the composition when we're done
comp:Unlock()

print("Completed adding loaders next to selected tools")