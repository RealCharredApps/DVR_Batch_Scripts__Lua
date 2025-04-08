-- Center Selected Nodes Script for Fusion
-- This script centers selected nodes in the current flow view
-- and cascades them vertically by name

-- Get the current composition
local comp = fu:GetCurrentComp()
if not comp then 
    print("No composition found") 
    return 
end

-- Get the FlowView reference
local flow = comp.CurrentFrame.FlowView
if not flow then 
    print("Error: Could not access FlowView") 
    return 
end

-- Lock the composition to prevent rendering during changes
comp:Lock()

-- Get the currently selected nodes
local selected_nodes = comp:GetToolList(true)

-- Check if any nodes are selected
print("Selected nodes: " .. #selected_nodes)
if #selected_nodes == 0 then
    print("Error: No nodes selected")
    comp:Unlock()
    return
end

-- Sort the nodes by name alphabetically
table.sort(selected_nodes, function(a, b)
    return a:GetAttrs().TOOLS_Name < b:GetAttrs().TOOLS_Name
end)

-- Function to queue positions and then apply them all at once for efficiency
local function centerSelectedNodes()
    -- Tell FlowView we're going to queue some position changes
    flow:QueueSetPos()
    
    -- Get the current flow position as the center point
    -- This uses the current view center coordinates
    local centerX = comp.XPos
    local centerY = comp.YPos
    
    print("Using view center at X: " .. centerX .. ", Y: " .. centerY)
    
    -- Calculate the vertical spacing for the cascade
    -- We'll use a fixed spacing of 1 grid unit
    local verticalSpacing = 1.0
    
    -- Calculate the starting Y position so nodes are centered around the view center
    local cascadeStartY = centerY + ((#selected_nodes - 1) * verticalSpacing / 2)
    
    -- Queue position changes for each node
    for i, node in ipairs(selected_nodes) do
        local nodeName = node:GetAttrs().TOOLS_Name
        
        -- Calculate the Y position for this node in the cascade
        local newY = cascadeStartY - (i-1) * verticalSpacing
        
        -- Queue the position change
        flow:QueueSetPos(node, centerX, newY)
        
        print("Queued node '" .. nodeName .. "' for position X: " .. centerX .. ", Y: " .. newY)
    end
    
    -- Apply all the position changes at once
    flow:FlushSetPosQueue()
    print("Applied all position changes")
end

-- Execute the node positioning
centerSelectedNodes()

-- Unlock the composition
comp:Unlock()

print("Node centering and cascading complete")