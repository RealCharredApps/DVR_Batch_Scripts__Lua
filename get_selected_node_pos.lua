#!/usr/bin/env lua

-- Get the current composition
local comp = fu:GetCurrentComp()
if not comp then print("No composition found") return end

-- Get the FlowView reference
local flow = comp.CurrentFrame.FlowView
if not flow then print("Error: Could not access FlowView") return end

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
    
    -- Get the node position using FlowView
    local x, y = flow:GetPos(node)
    
    if x and y then
        print("Node '" .. nodeName .. "' position:")
        print("X: " .. x)
        print("Y: " .. y)
    else
        print("Could not get position for node: " .. nodeName)
    end
end

print("Get Node Position process complete")