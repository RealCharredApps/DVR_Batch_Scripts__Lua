-- Robust MultiMerge Connector Script
-- Connects selected tools to MultiMerge with intelligent layer ordering
function Main()
    -- Lock the composition to prevent re-rendering during setup
    comp:Lock()

    -- Get all selected tools
    local selectedTools = comp:GetToolList(true)

    -- Debug: Print raw selected tools
    print("Debug: Selected Tools Type: " .. type(selectedTools))

    -- Check if we have enough selected tools
    if not selectedTools or #selectedTools == 0 then
        print("No tools selected. Please select at least one tool to connect.")
        comp:Unlock()
        return nil
    end

    -- Debug: Print number of selected tools
    print("Number of selected tools: " .. #selectedTools)

    -- Calculate average position for MultiMerge placement
    local avgX, avgY = 0, 0
    local count = 0
    local flow = comp.CurrentFrame.FlowView

    -- Collect tool information for sorting
    local toolInfo = {}
    for i, tool in pairs(selectedTools) do
        local x, y = flow:GetPos(tool)

        -- Store tool with its position information
        table.insert(toolInfo, {
            tool = tool,
            x = x,
            y = y
        })

        avgX = avgX + x
        avgY = avgY + y
        count = count + 1
    end

    -- Debug: Print count of processed tools
    print("Processed tools count: " .. count)

    -- Sort tools by vertical position (bottom to top)
    table.sort(toolInfo, function(a, b)
        return a.y < b.y
    end)

    avgX = avgX / count
    avgY = avgY / count

    -- Create a transparent Background for the MultiMerge's background input
    comp.XPos = avgX + 2
    comp.YPos = avgY - 1
    local bgNode = comp:AddTool("Background")

    -- Set background to transparent
    bgNode.TopLeftRed = 0
    bgNode.TopLeftGreen = 0
    bgNode.TopLeftBlue = 0
    bgNode.TopLeftAlpha = 0

    -- Create MultiMerge node
    comp.XPos = avgX + 3
    comp.YPos = avgY
    local multiMerge = comp:AddTool("MultiMerge")
    print("MultiMerge created at position: " .. avgX + 3 .. ", " .. avgY)

    -- Connect the Background to the MultiMerge's Background input
    multiMerge:ConnectInput("Background", bgNode)
    print("Connected Background to MultiMerge")

    -- Verify Inputs exist
    if not multiMerge.Inputs then
        print("Error: MultiMerge has no Inputs")
        comp:Unlock()
        return nil
    end

    -- Prepare layer order script value
    local layerOrderScript = "return {"

    -- Connect all selected tools to the MultiMerge
    print("Connecting " .. count .. " selected tools to MultiMerge")

    -- Dynamically connect tools to Foreground inputs in bottom-to-top order
    for i, info in ipairs(toolInfo) do
        local tool = info.tool

        -- Find the main output of the tool
        local mainOutput = tool:FindMainOutput(1)

        if mainOutput then
            -- Connect the tool's main output to the MultiMerge's NEXT AVAILABLE Foreground input
            tool:ConnectInput("Output", multiMerge)
            -- show the layer that was actually connected, if connect successful
            print("Connected " .. tool.Name .. " to MultiMerge Foreground input: " .. i)

            layerOrderScript = layerOrderScript .. "\n\t" .. tool.Name .. ""
            if i < count then 
                layerOrderScript = layerOrderScript .. ","
            end
        else
            print("Warning: Could not find main output for " .. tool.Name)
        end
    end

    -- Finalize layer order script
    layerOrderScript = layerOrderScript .. "}"

    -- Set the layer order input
    if multiMerge.Inputs and multiMerge.Inputs.LayerOrder then
        multiMerge.Inputs.LayerOrder = ScriptVal {
            Value = layerOrderScript
        }
    else
        print("Error: LayerOrder input not found in MultiMerge")
    end

    -- Unlock the composition
    comp:Unlock()

    print("MultiMerge connection process complete")
    return multiMerge
end

-- Run the main function
Main()
