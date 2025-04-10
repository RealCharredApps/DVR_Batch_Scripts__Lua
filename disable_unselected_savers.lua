fusion = Fusion()
fu = fusion
composition = fu.CurrentComp
comp = composition
SetActiveComp(comp)

comp:Lock()

local selectedSavers = comp:GetToolList(true, "Saver")
local allSavers = comp:GetToolList(false, "Saver")

for i, currentSaver in pairs(allSavers) do
    local isSelected = false
    for j, selectedSaver in pairs(selectedSavers) do
        if currentSaver == selectedSaver then
            isSelected = true
            break
        end
    end
    if isSelected == false then
        currentSaver:SetAttrs({ ["TOOLB_PassThrough"] = true })
        --print("Set " .. currentSaver.Name .. " to pass-through")
    end
end

comp:Unlock()

print("All Unselected Savers have been turned off")