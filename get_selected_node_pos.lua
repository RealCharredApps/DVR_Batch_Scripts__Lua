#!/usr/bin/env lua

-- Get the current composition
local comp = fu:GetCurrentComp()
if not comp then print("No composition found") return end

-- Get the currently selected nodes
local selected_nodes = comp:GetToolList(true)

-- Check if any nodes are selected
print("Selected nodes: " .. #selected_nodes)
if #selected_nodes == 0 then
    print("Error: No nodes selected")
    return
end


-- Process each selected node
for _, node in ipairs(selected_nodes) do
    -- Get node information
    local nodeName = node:GetAttrs().TOOLS_Name
    print("Node Selected: " .. nodeName)
        
    local position = getNodePosition(comp, selected_nodes[1])
    
    if position then
        print("Node '" .. nodeName .. "' position:")
        print("X: " .. position.X)
        print("Y: " .. position.Y)
    end
end

print("Get Node Position process complete")