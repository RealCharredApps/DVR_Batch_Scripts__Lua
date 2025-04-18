fusion = Fusion()
fu = fusion
composition = fu.CurrentComp
comp = composition
SetActiveComp(comp)
 
-- ----------------------
-- UI_MANAGER SETUP
-- ----------------------
local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width, height = 400, 200
local positionX, positionY = 800, 400

-- Function to convert timecode to frames
function TCtoFrames(tc, fps)
    local h, m, s, f = tc:match("(%d+):(%d+):(%d+):(%d+)")
    if h and m and s and f then
        -- Convert timecode to frames
        h, m, s, f = tonumber(h), tonumber(m), tonumber(s), tonumber(f)
        return f + (s * fps) + (m * 60 * fps) + (h * 60 * 60 * fps)
    else
        return 0
    end
end

-- Function to validate timecode format
function isValidTimecode(tc)
    local h, m, s, f = tc:match("(%d+):(%d+):(%d+):(%d+)")
    return h ~= nil and m ~= nil and s ~= nil and f ~= nil
end

-- Create and insert the adjustment layer into the timeline
function CreateAndInsertAdjustmentLayer(tcDuration)
    -- Start an undo event
    comp:StartUndo("Insert Adjustment Layer")
    
    -- Lock the composition to prevent unwanted UI updates
    comp:Lock()
    
    -- Get current playhead position
    local currentTime = comp.CurrentTime
    
    -- Get current FPS
    local fps = comp:GetPrefs("Comp.FrameFormat.Rate")
    
    -- Convert duration to frames
    local durationFrames = TCtoFrames(tcDuration, fps)
    
    print("Creating adjustment layer at frame: " .. currentTime .. " with duration: " .. durationFrames .. " frames")
    
    -- Create a solid color generator as our adjustment layer
    local adjLayer = comp:AddTool("Background")
    
    if not adjLayer then
        comp:Unlock()
        comp:EndUndo(false)
        print("Failed to create Background tool")
        return nil
    end
    
    -- Configure the generator to be transparent
    adjLayer.UseFrameFormatSettings = 1 -- Use timeline format
    adjLayer.TopLeftAlpha = 0      -- Make fully transparent
    adjLayer.TopRightAlpha = 0
    adjLayer.BottomLeftAlpha = 0
    adjLayer.BottomRightAlpha = 0
    
    -- Set the name
    adjLayer:SetAttrs({TOOLS_Name = "AdjustmentLayer"})
    
    -- Set the time range
    adjLayer:SetAttrs({TOOLNT_EnabledRegion_Start = currentTime})
    adjLayer:SetAttrs({TOOLNT_EnabledRegion_End = currentTime + durationFrames})
    
    -- Place on video track 1
    if adjLayer.MediaTrack then
        adjLayer.MediaTrack = 1
    end
    
    -- Get the media pool for the current project
    local mediaPool = comp:GetMediaPool()
    if mediaPool then
        -- Append to timeline (this is a key part for the Edit page)
        local timelineItems = mediaPool:AppendToTimeline({
            {
                mediaPoolItem = adjLayer,
                startFrame = 0,
                endFrame = durationFrames,
                mediaType = 1, -- Video only
                trackIndex = 1, -- Video track 1
                recordFrame = currentTime -- Insert at current position
            }
        })
        
        print("Timeline items added: " .. (timelineItems and #timelineItems or "0"))
    else
        print("Failed to get media pool")
    end
    
    -- Position in flow for visibility
    local flow = comp.CurrentFrame.FlowView
    if flow then
        flow:SetPos(adjLayer, 0, 0)
    end
    
    -- Set as active tool
    comp:SetActiveTool(adjLayer)
    
    -- Unlock the composition
    comp:Unlock()
    
    -- End the undo event
    comp:EndUndo(true)
    
    return adjLayer
end

-- Create a dialog to get duration from user
function ShowDurationDialog()
    local defaultTC = "00:00:02:10"  -- Default duration
    local keepOpen = true
    
    local dialog = disp:AddWindow({
        ID = "AdjLayerDialog",
        WindowTitle = "Create Adjustment Layer",
        Geometry = { positionX, positionY, width, height },
        
        ui:VGroup{
            ID = "root",
            
            -- Duration input
            ui:HGroup{
                ui:Label{ Text = "Duration (HH:MM:SS:FF):" },
                ui:LineEdit{ ID = "DurationTC", Text = defaultTC, MinimumSize = { 100, 20 } },
            },
            
            ui:VGap(10),
            ui:Label{ ID = "CurrentTC", Text = "Current Time: " .. comp.CurrentTime },
            ui:VGap(5),
            ui:Label{ ID = "StatusMsg", Text = "" },
            ui:VGap(10),
            
            -- Buttons
            ui:HGroup{
                ui:Button{
                    ID = "CreateButton",
                    Text = "Create",
                },
                ui:Button{
                    ID = "CloseButton",
                    Text = "Close",
                },
            },
        },
    })
    
    -- Handle button clicks
    function dialog.On.CreateButton.Clicked(ev)
        local duration = dialog:GetItems().DurationTC.Text
        
        -- Validate timecode format
        if isValidTimecode(duration) then
            local statusLabel = dialog:GetItems().StatusMsg
            statusLabel.Text = "Creating adjustment layer..."
            
            local adjLayer = CreateAndInsertAdjustmentLayer(duration)
            
            if adjLayer then
                statusLabel.Text = "Created adjustment layer with duration " .. duration
            else
                statusLabel.Text = "Failed to create adjustment layer"
            end
        else
            local statusLabel = dialog:GetItems().StatusMsg
            statusLabel.Text = "Invalid timecode format. Please use HH:MM:SS:FF"
        end
    end
    
    function dialog.On.CloseButton.Clicked(ev)
        keepOpen = false
        disp:ExitLoop()
    end
    
    function dialog.On.AdjLayerDialog.Close(ev)
        keepOpen = false
        disp:ExitLoop()
    end
    
    dialog:Show()
    
    -- Main dialog loop
    while keepOpen do
        disp:RunLoop()
    end
    
    dialog:Hide()
end

-- Run the script
ShowDurationDialog()