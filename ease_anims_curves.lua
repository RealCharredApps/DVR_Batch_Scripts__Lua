-- Easecopy v1.0.3
-- OG by CHFR-wide
-- Rec by PEEJ

-- Changelog:
-- v1.0.3 : Makes the script composition-agnostic
-- v1.0.2 : Fixes an issue where number-only ease names would crash the script
-- v TBD

----------------------
-- UI_MANAGER SETUP --
----------------------

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width,height = 275,300
local positionX,positionY = 800,400
local currentComp = fu:GetCurrentComp()

win = disp:AddWindow({
	ID = 'MyWin',
	TargetID = 'MyWin',
	WindowTitle = 'Ease Copy',
  Geometry = {positionX, positionY, width, height},
	Spacing = 0,
  ui:VGroup{
    ID = 'root',
    ui:Label{
      Weight = 0,
      Text = 'Apply',
      Alignment = {AlignHCenter = true},
    },
    ui:HGroup{
      Weight = 0,
      ui:Label    { Weight = 0.5, Text = 'Ease', },
      ui:ComboBox { Weight = 2, ID = 'qEase', Text = '', },
    },
    ui:HGroup{
      Weight = 0,
      ui:Label    { Weight = 0.5, Text = 'Target', },
      ui:ComboBox { Weight = 2, ID = 'qTargetProp', Text = '', },
    },
    ui:Button { Weight=0, ID = 'qApplyBtn', Text = 'Apply ease' },
    ui:TabBar{},
    ui:Label{
      Weight = 0,
      Text = 'Save',
      Alignment = {AlignHCenter = true},
    },
    ui:HGroup{
      Weight = 0,
      ui:LineEdit { ID = 'qSaveEaseText' },
      ui:Button { ID = 'qSaveBtn', Text = 'Save ease' },
    },
    ui:TabBar{},
    ui:Label{
      Weight = 0,
      Text = 'Delete',
      Alignment = {AlignHCenter = true},
    },
    ui:HGroup{
      Weight = 0,
      ui:Button { 
        Weight = 0.5, 
        ID = 'qDeleteOne', 
        Text = 'Selected ease' 
      },
      ui:Button { 
        Weight = 0.5, 
        ID = 'qDeleteAll', 
        Text = 'All eases' 
      },
    },

  }
})

selectedTool = tool
itm = win:GetItems()
notify = ui:AddNotify('Comp_Activate_Tool')

-- EVENT BINDING --

function win.On.MyWin.Close(ev)
	disp:ExitLoop()
end

function disp.On.Comp_Activate_Tool(ev)
  ReloadTargetComboBox()
end

function win.On.qApplyBtn.Clicked(ev)
  local presetName = itm.qEase.CurrentText
  local targetProp = itm.qTargetProp.CurrentText

  if (presetName ~= '') then
    EaseCopy(presetName, targetProp)
  end
end

function win.On.qSaveBtn.Clicked(ev)
  local presetName = itm.qSaveEaseText.Text
  local targetProp = itm.qTargetProp.CurrentText

  if (presetName ~= '') then
    if EaseCopy(presetName, targetProp, true) then
      itm.qSaveEaseText.Text = ''
      ReloadEaseComboBox(presetName)
    end
  end
end

function win.On.qDeleteOne.Clicked(ev)
  local presetName = itm.qEase.CurrentText
  fusion:SetData("easeCopy.presets." .. presetName, nil)
  ReloadEaseComboBox()
  print('Ease: ' .. presetName .. ' deleted.')
end

function win.On.qDeleteAll.Clicked(ev)
  local confirmClear = currentComp:AskUser("Delete all eases?", {})
  if not confirmClear then return end
  fusion:SetData("easeCopy", nil)
  ReloadEaseComboBox()
  print('All eases have been deleted.')
end

-- DISPLAY UPDATE --

function ReloadEaseComboBox(newSelected)
  dump('reloading')
  local savedEases = fusion:GetData("easeCopy.presets")
  local presets = {}



  if savedEases then;
    presets = GetKeys(fusion:GetData("easeCopy.presets"));
  end

  itm.qEase:Clear()
  for _, preset in pairs(presets) do
    itm.qEase:AddItem(preset)
  end

  if newSelected ~= '' then
    itm.qEase:SetCurrentText(newSelected)
  end

end

function ReloadTargetComboBox()
  currentComp = fu:GetCurrentComp()

  itm.qTargetProp:Clear()
  itm.qTargetProp:AddItem('ALL')
  for _, target in pairs(FindEligibleInputs(currentComp:GetToolList(true))) do
    itm.qTargetProp:AddItem(target)
  end
end

----------------
-- MAIN LOGIC --
----------------


function EaseCopy(presetName, targetProp, copy)
  currentComp:StartUndo("EaseCopy")
  currentComp:Lock()
  for k,v in pairs(currentComp:GetToolList(true)) do
    local endExecutionEarly = EaseCopyTool(v, presetName, targetProp, copy)
    if (endExecutionEarly) then
      currentComp:Unlock()
      currentComp:EndUndo(true)
      return true
    end
  end
  currentComp:Unlock()
  currentComp:EndUndo(true)
end

function EaseCopyTool(tool, presetName, targetProp, copy)
  for k,v in pairs(tool:GetInputList()) do
    local endExecutionEarly = EaseCopyInput(v, presetName, targetProp, copy)
    if (endExecutionEarly) then
      return true
    end
  end
end

function EaseCopyInput(input, presetName, targetProp, copy)
  if not IsViableInput(input) then return end
  
  local inputTool = GetTool(input)

  if not inputTool then; return; end

  if (IsModifier(inputTool) and not IsBezierSpline(inputTool)) then
    return EaseCopyTool(inputTool, presetName, targetProp, copy)
  end

  if not IsTargetInput(input, targetProp) then return end
  
  local keyframes = inputTool:GetKeyFrames()

  if not keyframes then; return; end

  local adjacentKeyframes = GetAdjacentKeyframes(keyframes)

  if not adjacentKeyframes then
    return
  end

  print("Found valid property: " .. input:GetAttrs().INPS_Name)
  if copy then
    CopyEase(presetName, adjacentKeyframes)
    return true
  else
    local hardReplace = input:GetAttrs().INPS_ID ~= "Displacement"

    PasteEase(inputTool, presetName, adjacentKeyframes, hardReplace)
  end

end

function CopyEase(presetName, adjacentKeyframes)
  local normalized = NormalizeKeyframePairHandles(adjacentKeyframes)
  print("copying ease as " .. presetName)
  fusion:SetData("easeCopy.presets." .. presetName, normalized)
end

function PasteEase(tool, presetName, adjacentKeyframes, hardReplace)
  local ease = fusion:GetData("easeCopy.presets." .. presetName)
  if ease then
    print("pasting ease preset " .. presetName)
    local denormalized = DenormalizeKeyframePairHandles(adjacentKeyframes, ease)
    local oldKf = tool:GetKeyFrames()
    local newKf = PatchExistingKeyFrames(oldKf, denormalized)

    if hardReplace then
      tool:DeleteKeyFrames(currentComp:GetAttrs().COMPN_GlobalStart, currentComp:GetAttrs().COMPN_GlobalEnd)
      tool:SetKeyFrames(newKf, false)
    else
      ShowDisplacementWarning()
      tool:SetKeyFrames(newKf, false)
      -- This is not a mistake, for some reason, running this twice on Displacement properties
      -- gives better (though still inconsistent) results
      tool:SetKeyFrames(newKf, false)
    end
  end
end

function ShowDisplacementWarning()
  if fusion:GetData('easeCopy.displacementWarning.doNotShow') == true then return end
  local warnMessage = 'Pasting eases on a Displacement property can give inconsistent results, if it doesn\'t work as intended, please use an XY path modifier instead.'
  local warnText = {"Message", Name="Message", "Text", ReadOnly = true, Wrap = true, Default = warnMessage, Lines = 5}
  local checkBox = {"DoNotShowAgain", Name="Don\'t show this message again", "Checkbox"}
  local dialog = currentComp:AskUser("Warning", {warnText, checkBox})
  dump(dialog)
  if dialog and dialog.DoNotShowAgain == 1 then
    dump('Saving preferences')
    fusion:SetData('easeCopy.displacementWarning.doNotShow', true)
  end
end

----------------------------------
-- INPUT PARSING AND VALIDATION --
----------------------------------

function FindEligibleInputs(tools)
  local eligibleInputs = {}
  for _, tool in pairs(tools) do
    for _, input in pairs(tool:GetInputList()) do
      if IsViableInput(input) then
        local inputTool = GetTool(input)
        if IsModifier(inputTool) then
          if IsBezierSpline(inputTool) then
            local savedTarget = tool:GetAttrs().TOOLS_Name .. ":" .. input:GetAttrs().INPS_ID
            table.insert(eligibleInputs, savedTarget  )
          else
            for _, v in ipairs(FindEligibleInputs({inputTool})) do
              table.insert(eligibleInputs, v)
            end
          end
        end
      end
    end
  end

  return eligibleInputs
end

function IsViableInput(input)
  return input:GetAttrs("INPB_Connected") and input:GetAttrs("INPS_DataType") ~= "LookUpTable"
end

function IsTargetInput(input, targetProp)
  if targetProp == 'ALL' then return true end

  t = Split(targetProp, ':')

  dump(input:GetAttrs().INPS_ID)
  dump(input:GetTool():GetAttrs().TOOLS_Name == t[1] and input:GetAttrs().INPS_ID == t[2])

  return input:GetTool():GetAttrs().TOOLS_Name == t[1] and input:GetAttrs().INPS_ID == t[2]
end

-- thanks. https://www.steakunderwater.com/wesuckless/viewtopic.php?p=45445#p45445
function IsModifier(tool)
  local regModifiers = fusion:GetRegList(fusion.CT_Modifier)
  local toolAttrs = tool:GetAttrs()

  for _,v in pairs(regModifiers) do
    if v:GetAttrs().REGS_ID == toolAttrs.TOOLS_RegID then
      return true
    end
  end
  return false
end

function IsBezierSpline(tool)
  return tool:GetAttrs().TOOLS_RegID == "BezierSpline"
end

function GetTool(input)
  local output = input:GetConnectedOutput()
  if (output ~= nil) then
    return output:GetTool()
  end
end

----------------------------
-- KEYFRAMES MANIPULATION --
----------------------------


function GetAdjacentKeyframes(keyframes)

  local closestLeft = nil
  local closestRight = nil

  for k,v in pairs(keyframes) do
    if k <= currentComp.CurrentTime and (closestLeft == nil or k > closestLeft) then
      closestLeft = k
    end
    if k > currentComp.CurrentTime and (closestRight == nil or k < closestRight) then
      closestRight = k
    end
  end

  if (closestLeft and closestRight) then
    return {[closestLeft] = keyframes[closestLeft], [closestRight] = keyframes[closestRight]}
  end
end

function IsolateAdjacentKeyframes(keyframes, adjacent)
  return {
    [adjacent.Left] = keyframes[adjacent.Left],
    [adjacent.Right] = keyframes[adjacent.Right]
  }
end

function NormalizeKeyframePairHandles(adjacentKeyframes)
  local tLeft, hLeft, tRight, hRight = SortAdjacentFrames(adjacentKeyframes)

  local timeDiff = tRight - tLeft
  local valueDiff = hRight[1] - hLeft[1]

  if valueDiff == 0 then; return nil; end

  local RH = hLeft.RH
  local LH = hRight.LH

  return {
    RH = { RH[1] / timeDiff, RH[2] / valueDiff },
    LH = { LH[1] / timeDiff, LH[2] / valueDiff },
  }
end

function DenormalizeKeyframePairHandles(adjacentKeyframes, normalized)
  local tLeft, hLeft, tRight, hRight = SortAdjacentFrames(adjacentKeyframes)

  local timeDiff = tRight - tLeft
  local valueDiff = hRight[1] - hLeft[1]

  local RH = normalized.RH
  local LH = normalized.LH

  adjacentKeyframes[tLeft].RH = { RH[1] * timeDiff, RH[2] * valueDiff }
  adjacentKeyframes[tRight].LH = { LH[1] * timeDiff, LH[2] * valueDiff }
  adjacentKeyframes[tLeft].Flags = { RH[1] * timeDiff, RH[2] * valueDiff }
  adjacentKeyframes[tRight].Flags = { LH[1] * timeDiff, LH[2] * valueDiff }
  
  return adjacentKeyframes
end

function SortAdjacentFrames(adjacentKeyframes)
  local tLeft, hLeft = next(adjacentKeyframes)
  local tRight, hRight = next(adjacentKeyframes, tLeft)

  if tLeft < tRight then
    return tLeft, hLeft, tRight, hRight
  else
    return tRight, hRight, tLeft, hLeft
  end
end

function PatchExistingKeyFrames(keyframes, denormalized)
  local k1, v1 = next(denormalized)
  local k2, v2 = next(denormalized, k1)

  keyframes[k1] = v1
  keyframes[k2] = v2

  return keyframes
end

----------------------
-- HELPER FUNCTIONS --
----------------------

function PairsByKeys (t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, tostring(n)) end
  table.sort(a, f)
  local i = 0
  local iter = function ()
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end

function GetKeys(t)
  if t == nil then; return; end 
  local keys={}

  for key,_ in PairsByKeys(t) do
    table.insert(keys, key)
  end
  return keys
end

function Split (inputstr, sep)
  if sep == nil then
     sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
     table.insert(t, str)
  end
  return t
end

----------------------

ReloadEaseComboBox()
ReloadTargetComboBox()
win:Show()
disp:RunLoop()
win:Hide()

collectgarbage()