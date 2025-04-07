-- Script to export all gallery stills to a user-defined folder
-- Connect to Resolve
local resolve = bmd.scriptapp("Resolve")
local projectManager = resolve:GetProjectManager()
local project = projectManager:GetCurrentProject()

-- Exit if no project is open
if not project then
    print("No project is open.")
    return
end

-- MAIN FUNCTION
function exportGalleryStills()
    -- get the gallery -- check if exists
    local gallery = project:GetGallery()
    if not gallery then
        print("No gallery found.")
        return
    end
    -- get the current stills album
    local currentAlbum = gallery:GetCurrentAlbum()
    if not currentAlbum then
        print("No still album selected.")
        return
    end
    -- get all stills in the current album
    local stills = currentAlbum:GetStills()
    if not stills or #stills == 0 then
        print("No stills in the current album.")
        return
    end
    print("Found " .. #stills .. " stills in the album.")
end

-- INPUT FUNCTION: get the user-defined folder
function getExportFolderPath()
    local os_type = bmd.getversion().platform
    local folderPath = ""
    if os_type == "Windows" then
         -- Windows approach - save a temporary file that asks PowerShell to show a folder picker
        local tempFile = os.getenv("TEMP") .. "\\resolve_select_folder.ps1"
        local tempOutputFile = os.getenv("TEMP") .. "\\resolve_selected_folder.txt"

        --create a powershell script to show a folder picker
        local file = io.open(tempFile, "w")
        file:write([[
            Add-Type -AssemblyName System.Windows.Forms
            $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
            $folderBrowser.Description = "Select a folder to export gallery stills"
            $folderBrowser.RootFolder = "MyComputer"
            if ($folderBrowser.ShowDialog() -eq "OK") {
                $folderBrowser.SelectedPath | Out-File -FilePath "]] .. tempOutputFile .. [[" -Encoding utf8
            }
        ]])
        file:close()

        --executes the powershell script and waits for it to finish
        os.execute("powershell -ExecutionPolicy Bypass -File " .. tempFile .. "")

        --read the selected folder path
        local fileOutput = io.open(tempOutputFile, "r")
        if fileOutput then
            folderPath = fileOutput:read("*1")
            fileOutput:close()
            os.remove(tempOutputFile)
        end
        os.remove(tempFile)
    elseif os_type == "Darwin" then
        -- macOS approach - use osascript (AppleScript)
        local script = [[osascript -e 'tell application "System Events" to set folderPath to POSIX path of (choose folder with prompt "Select a folder to export gallery stills")' 2>/dev/null]]
        local file = io.popen(script)
        folderPath = file:read("*l")
        file:close()
      
      else
        -- Linux approach - use zenity
        local script = [[zenity --file-selection --directory --title="Select a folder to export gallery stills" 2>/dev/null]]
        local file = io.popen(script)
        folderPath = file:read("*l")
        file:close()
      end
      
      return folderPath
    end


-- EXPORT LOGIC FUNCTION
function exportGalleryStills()
    -- Get the Gallery
    local gallery = project:GetGallery()
    if not gallery then
      print("Failed to access the Gallery!")
      return
    end
    
    -- Get the current still album
    local currentAlbum = gallery:GetCurrentStillAlbum()
    if not currentAlbum then
      print("No still album is currently selected!")
      return
    end
    
    -- Get all stills in the current album
    local stills = currentAlbum:GetStills()
    if not stills or #stills == 0 then
      print("No stills found in the current album!")
      return
    end
    
    print("Found " .. #stills .. " stills in the current album.")
    
    -- Get destination folder from user
    local folderPath = getExportFolderPath()
    if not folderPath or folderPath == "" then
      print("Export cancelled - no folder selected.")
      return
    end
    
    print("Exporting stills to: " .. folderPath)
    
    -- Export all stills
    local exportFormat = "png"  -- Options: dpx, cin, tif, jpg, png, ppm, bmp, xpm, drx
    local filePrefix = "still_" -- Prefix for the exported files
    
    local success = currentAlbum:ExportStills(stills, folderPath, filePrefix, exportFormat)
    
    if success then
      print("Successfully exported " .. #stills .. " stills to " .. folderPath)
    else
      print("Failed to export stills.")
    end
  end

-- call the main function
exportGalleryStills()
