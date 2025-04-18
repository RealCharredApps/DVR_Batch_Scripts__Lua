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
local width, height = 400, 500
local positionX, positionY = 800, 400

-- Make sure comp is unlocked while UI is running
comp:Unlock()

-- Create the UI
local window = disp:AddWindow({
    ID = "ScriptBrowserWin",
    WindowTitle = "Fusion Script Browser",
    Geometry = {Width = width, Height = height, X = positionX, Y = positionY},
    
    ui:VGroup{
        ID = "root",
        
        -- Title label
        ui:Label{
            ID = "TitleLabel", 
            Text = "Script Browser",
            StyleSheet = [[
                font-size: 16px;
                font-weight: bold;
                margin-bottom: 10px;
            ]]
        },
        
        -- Placeholder for script list
        ui:Label{
            ID = "PlaceholderLabel",
            Text = "Script list would go here",
            Alignment = {AlignHCenter = true, AlignVCenter = true},
            MinimumSize = {Width = width - 40, Height = 300},
            StyleSheet = [[
                background-color: #333333;
                border: 1px solid #555555;
                border-radius: 4px;
                padding: 10px;
            ]]
        },
        
        -- Add some spacing
        ui:VGap(10),
        
        -- Button row
        ui:HGroup{
            Weight = 0,
            ui:HGap(0, 1),  -- Push buttons to the right
            ui:Button{
                ID = "CloseButton",
                Text = "Close",
                MinimumSize = {Width = 100},
            },
        }
    }
})

-- Define what happens when the close button is clicked
function window.On.CloseButton.Clicked(ev)
    disp:ExitLoop()
end

-- Define what happens when the window's close button (X) is clicked
function window.On.ScriptBrowserWin.Close(ev)
    disp:ExitLoop()
end

-- Show the window
window:Show()

-- Run the UI event loop
disp:RunLoop()