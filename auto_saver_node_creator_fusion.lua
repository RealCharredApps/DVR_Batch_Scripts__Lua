-- Auto Saver Script for Fusion
-- This script adds a Saver node after each selected node in the Fusion composition
-- It automatically names the output file based on the selected node's name and sets up the connection
-- Get the current composition
local comp = fu:GetCurrentComp()

-- Check if we have a valid composition
if not comp then
    print("Error: No active composition found")
    return
end

-- Get the currently selected nodes
local selected_nodes = comp:GetToolList(true)

-- Check if any nodes are selected
print("Selected nodes: " .. #selected_nodes)
if #selected_nodes == 0 then
    print("Error: No nodes selected")
    return
end

-- Function to create a file path based on the node name
local function createFilePath(nodeName)
    -- You can customize this path as needed
    local basePath = comp:MapPath("Temp:\\")
    local fileName = nodeName:gsub("[^%w%-%_]", "_") -- Replace invalid filename chars
    return basePath .. fileName .. ".exr"
end

-- Process each selected node
for _, node in ipairs(selected_nodes) do
    -- Get node information
    local nodeName = node:GetAttrs().TOOLS_Name
    print("Creating saver for node: " .. nodeName)
    local saver = comp:AddTool("Saver")

    -- Set up the Saver node
    if saver then
        -- Name the Saver based on the selected node
        saver:SetAttrs({
            TOOLS_Name = nodeName .. "_Saver"
        })

        -- Create and set the output file path
        local filePath = createFilePath(nodeName)
        saver:SetAttrs({
            TOOLB_Filename = filePath
        })

        -- Connect the selected node to the Saver's input
        saver.Input = node.Output

        -- Position the saver after the input node (auto-positioning)
        print("Created Saver for node: " .. nodeName)
    else
        print("Failed to create Saver for node: " .. nodeName)
    end
end

print("Auto Saver process complete")
