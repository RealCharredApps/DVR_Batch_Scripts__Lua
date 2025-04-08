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
selectedTools = comp:GetToolList(true) -- 'true' means only selected tools

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
    local loaderX = x
    local loaderY = y

    -- Create a loader at this position
    local loader = comp:AddTool("Loader", loaderX, loaderY)

    -- Name the loader based on the selected tool's name
    local newName = "Loader_for_" .. tool.Name
    loader:SetAttrs({
        TOOLS_Name = newName
    })

    -- Setting both methods for maximum compatibility across Fusion versions

    -- Method 1: Direct property assignment
    if loader.Loop ~= nil then
        loader.Loop = 1 -- Enable looping
    end

    if loader.HoldLastFrame ~= nil then
        loader.HoldLastFrame = 1 -- Hold the last frame when going past the end
    end

    --[[if loader.HoldFirstFrame ~= nil then
        loader.HoldFirstFrame = 1 -- Hold the first frame when going before the start
    end]]--

    -- Method 2: Using SetInput (more universally supported)
    loader:SetInput("Loop", 1) -- Enable looping
    loader:SetInput("HoldLastFrame", 1) -- Hold the last frame when going past the end
    --loader:SetInput("HoldFirstFrame", 1) -- Hold the first frame when going before the start

    print("Added " .. newName .. " at position (" .. loaderX .. ", " .. loaderY .. ") with Loop and Hold Frame enabled")
end

-- Unlock the composition when we're done
comp:Unlock()

print("Completed adding loaders next to selected tools")
