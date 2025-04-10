fusion = Fusion()
fu = fusion
composition = fu.CurrentComp
comp = composition
SetActiveComp(comp)

comp:Lock()

local selectedSavers = comp:GetToolList(true, "Saver")

if #selectedSavers == 0 then
    print("No Savers selected")
else
    -- track pos for new loaders
    local loaderX = 0
    local loaderY = 1
    -- get flow view for positioning 
    local flow = comp.CurrentFrame.FlowView
    -- create a loader for each selected saver
    for i, saver in pairs(selectedSavers) do
        print("Creating Loader for " .. saver.Name)
        local saverClipPath = saver:GetInput("Clip")
        if saverClipPath and saverClipPath ~= "" then
            local saverX, saverY = flow:GetPos(saver)
            -- position the loader to the right of the saver
            local loader = comp:AddTool("Loader", saverX, saverY + loaderY)
            -- set loaders path to the saver clip path
            loader:SetInput("Clip", saverClipPath)
            -- name the loader x set clipath based on saver 
            local saverName = saver:GetAttrs().TOOLS_Name
            loader:SetAttrs({
                TOOLS_Name = "Loader_" .. saverName,
                TOOLS_ClipPath = saverClipPath,
            })
            loader:SetInput("Loop", 1) -- Enable looping
            print("created loader for " .. saver:GetAttrs().TOOLS_Name .. " at path " .. saverClipPath)
        else
            print("No Clip Path found for " .. saver:GetAttrs().TOOLS_Name)
        end
    end
end

comp:Unlock()

print("All Selected Savers now have Loaders")

