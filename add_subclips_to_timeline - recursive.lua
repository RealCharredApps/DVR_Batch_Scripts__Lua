-- Script to automatically add subclips to the timeline
-- Connect to Resolve
local resolve = bmd.scriptapp("Resolve")

-- Get the current projectk
local projectManager = resolve:GetProjectManager()
local project = projectManager:GetCurrentProject()

-- Exit if no project is open
if not project then
    print("No project is open.")
    return
end

-- Get the Media Pool
local mediaPool = project:GetMediaPool()

-- Get current folder in Media Pool
local folder = mediaPool:GetCurrentFolder()

-- Get all clips in the current folder
local clips = folder:GetClips()

-- Check if there are clips in the folder
if not clips or #clips == 0 then
    print("No clips in the folder.")
    return
end

print("Found " .. #clips .. " clips in the folder.")

-- get current timeline
local timeline = project:GetCurrentTimeline()
if not timeline then
    -- create a new timeline if none exists
    timeline = mediaPool:CreateEmptyTimeline("New Timeline")
    if not timeline then
        print("Failed to create a new timeline.")
        return
    end

    print("Created a new timeline: " .. timeline:GetName())
else
    print("Using existing timeline: " .. timeline:GetName())
end

-- append clips to the timeline
local addedItems = mediaPool:AppendToTimeline(clips)

if addedItems then
    print("Successfully added " .. #addedItems .. " clips to the timeline!")

    print("Clips added to the timeline:")
    for i = 1, math.min(3, #addedItems) do
        print(" -  " .. addedItems[i]:GetName())
    end
else
    print("Failed to append clips to the timeline.")
end
