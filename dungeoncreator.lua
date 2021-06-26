
-- ------------------------- Core ------------------------

DungeonCreator = {}
local self = DungeonCreator

-- ------------------------- Info ------------------------

self.Info = {
    Author      = "Mash#3428",
    AddonName   = "DungeonCreator",
    ClassName   = "DungeonCreator",
	Version     = 107,
	StartDate   = "21-06-2021",
	LastUpdate  = "26-06-2021",
    Description = "Kitanoi's Dungeon Framework assist addon that can be used to create new dungeon profiles with ease.",
    ChangeLog = {
        [100] = { Version = [[1.0.0]], Description = "Starting development" },
        [101] = { Version = [[1.0.1]], Description = "Reparsing file on save to format numeric values." },
        [102] = { Version = [[1.0.2]], Description = "Adding Advanced Avoidance." },
        [103] = { Version = [[1.0.3]], Description = "Adding Overhead Markers." },
        [104] = { Version = [[1.0.4]], Description = "Adding Author info and create/update date." },
        [105] = { Version = [[1.0.5]], Description = "Adding pullenemyoutofpuddle, interactdistance, requeuetimer, excludeavoid, prioritytargetdistance and type." },
        [106] = { Version = [[1.0.6]], Description = "Changing ternary operations." },
        [107] = { Version = [[1.0.7]], Description = "Adding a check for invalid profiles." },
    }
}

-- ------------------------- Paths ------------------------

local LuaPath       = GetLuaModsPath()
local StartupPath   = GetStartupPath()
self.ProfilePath    = LuaPath       .. [[KitanoiFuncs\dungeonprofiles\]]
self.MeshPath       = StartupPath   .. [[\Navigation\]]

-- ------------------------- GUI ------------------------

self.GUI = {
    Open        = false,
    Visible     = false,
    Width       = 760,
    Height      = 815,
    OnClick     = loadstring([[DungeonCreator.GUI.Open = not DungeonCreator.GUI.Open]]),
    IsOpen      = loadstring([[return DungeonCreator.GUI.Open]]),
    Combos      = {
        Profile = 1
    },
    Inputs = {
        NewProfileName = ""
    }
}

self.ProfileList        = {}
self.ProfileLoaded      = {}
self.CurrentFile        = {}
self.CreatingProfile    = false
self.EntitiesRecorded   = {}
self.EntityIndex        = 0
self.DutyType           = {
    [1] = "Story",
    [2] = "Trust",
    [3] = "Duty",
    [4] = "Squadron"
}

-- ------------------------- Log ------------------------

function DungeonCreator.Log(string) 
    d("==== [DungeonCreator] - " .. tostring(string))
end

-- ------------------------- Table stringify ------------------------

function DungeonCreator.TableStringify(table)
    if type(table) == 'table' then
        local s = '{ '
        
        for k,v in pairs(table) do
            if type(k) ~= 'number' then k = '"'..k..'"' end

            if type(v) == 'table' then
                s = s .. '['..k..'] = ' .. DungeonCreator.TableStringify(v) .. ','
            elseif type(v) == 'string' then
                s = s .. '['..k..'] = ' .. [["]] .. v .. [["]] .. ','
            elseif type(v) == 'number' then
                s = s .. '['..k..'] = ' .. v .. ','
            end
        end

        return s .. '} '
    else
        return tostring(table)
    end
end

-- ------------------------- Parse File to Framework ------------------------

function DungeonCreator.FormatFileToFramework(File)
    local FilePath  = DungeonCreator.ProfilePath .. DungeonCreator.ProfileList[DungeonCreator.GUI.Combos.Profile]
    local NewFile   = {}

-- ------------------------- Settings ------------------------

    NewFile.dutyid                  = tonumber(File.dutyid)
    NewFile.queuetype               = tonumber(File.queuetype)
    NewFile.enemytargetdistance     = tonumber(File.enemytargetdistance)
    NewFile.author                  = tostring(File.author)
    NewFile.bossids                 = File.bossids
    NewFile.mesh                    = File.mesh
    NewFile.name                    = File.name
    NewFile.forcemeleerange         = File.forcemeleerange
    NewFile.pullenemyoutofpuddle    = File.pullenemyoutofpuddle
    NewFile.interactdistance        = tonumber(File.interactdistance)
    NewFile.requeuetimer            = tonumber(File.requeuetimer)
    NewFile.excludeavoid            = tostring(File.excludeavoid)
    NewFile.prioritytargetdistance  = tonumber(File.prioritytargetdistance)
    NewFile.type                    = string.lower(DungeonCreator.DutyType[File.type])
    NewFile.interacts               = {}
    NewFile.objectivedestinations   = {}
    NewFile.prioritytarget          = {}
    NewFile.hasbuff                 = {}
    NewFile.advancedavoid           = {}
    NewFile.overheadmarkers         = {}

-- ------------------------- DateTime ------------------------

    NewFile.lastupdate              = MashLib.Helpers.GetDate() .. [[ EST]]
    
    if FileExists(FilePath) then
        local CheckDate = FileLoad(FilePath)

        if not CheckDate.createdate then
            NewFile.createdate = MashLib.Helpers.GetDate() .. [[ EST]]
        else
            NewFile.createdate = CheckDate.createdate
        end
    else
        NewFile.createdate = MashLib.Helpers.GetDate() .. [[ EST]]
    end
    
-- ------------------------- Interactions ------------------------

    if File.interacts ~= nil then
        for k, v in pairs(File.interacts) do 
            NewFile.interacts[#NewFile.interacts+1] = {
                contentid   = tonumber(v.contentid),
                priority    = tonumber(v.priority),
                type        = v.type,
            }
        end
    end

-- ------------------------- ObjectiveDestinations ------------------------

    if File.objectivedestinations ~= nil then
        for k, v in pairs(File.objectivedestinations) do 
            NewFile.objectivedestinations[#NewFile.objectivedestinations+1] = {
                objective   = tonumber(v.objective),
                pos         = {
                    x = v.pos.x + 0.0,
                    y = v.pos.y + 0.0,
                    z = v.pos.z + 0.0,
                }
            }
        end
    end

-- ------------------------- PriorityTargets ------------------------

    if File.prioritytarget ~= nil then
        for k, v in pairs(File.prioritytarget) do 
            NewFile.prioritytarget[#NewFile.prioritytarget+1] = {
                contentid   = tonumber(v.contentid),
                priority    = tonumber(v.priority),
                type        = v.type
            }
        end
    end

-- ------------------------- HasBuff ------------------------

    if File.hasbuff ~= nil then
        for k, v in pairs(File.hasbuff) do
            if v.type == 'interact' then
                NewFile.hasbuff[#NewFile.hasbuff+1] = {
                    type            = "interact",
                    interactid      = v.interactid,
                    buffid          = tonumber(v.buffid),
                    stacksrequired  = tonumber(v.stacksrequired),
                    desc            = v.desc
                }
            elseif v.type == 'move' then
                local index = #NewFile.hasbuff+1

                NewFile.hasbuff[index] = {
                    type            = "move",
                    buffid          = tonumber(v.buffid),
                    desc            = v.desc,
                    pos             = {}
                }

                for _, vp in pairs(v.pos) do 
                    NewFile.hasbuff[index].pos[#NewFile.hasbuff[index].pos+1] = {
                        x = vp.x + 0.0,
                        y = vp.y + 0.0,
                        z = vp.z + 0.0
                    }
                end
            end
        end
    end

-- ------------------------- AdvancedAvoid ------------------------

    if File.advancedavoid ~= nil then
        for k, v in pairs(File.advancedavoid) do
            if v.texteditor then
                loadstring("DungeonCreator.AdvancedAvoidTemporary = " .. v.texteditor)()
                NewFile.advancedavoid[k] = DungeonCreator.AdvancedAvoidTemporary
            end
        end
    end

-- ------------------------- OverheadMarkers ------------------------

    if File.overheadmarkers ~= nil then
        for k, v in pairs(File.overheadmarkers) do
            local index = #NewFile.overheadmarkers+1

            NewFile.overheadmarkers[index] = {
                id              = tonumber(v.id), 
                contentid       = tonumber(v.contentd),
                desc            = v.desc, 
                type            = v.type, 
                detectwho       = v.detectwho, 
                pos             = {}, 
                timetoreturn    = tonumber(v.timetoreturn)
            }

            for _, vp in pairs(v.pos) do 
                NewFile.overheadmarkers[index].pos[#NewFile.overheadmarkers[index].pos+1] = {
                    x = vp.x + 0.0,
                    y = vp.y + 0.0,
                    z = vp.z + 0.0
                }
            end
        end
    end

    FileSave(FilePath, NewFile)
end

-- ------------------------- Init ------------------------

function DungeonCreator.Init()
    local ModuleTable = self.GUI
    ml_gui.ui_mgr:AddSubMember({
        id      = "DungeonCreator",
        name    = "DungeonCreator",
        onClick = function() ModuleTable.OnClick() end,
        tooltip = "Kitanoi's DungeonFramework assist addon",
        texture = MashLib.ImagePath .. [[profiles-icon.png]]
    }, [[FFXIVMINION##MENU_HEADER]], [[MASHSTUFF##MENU_HEADER]])
end

-- ------------------------- MainWindow ------------------------

function DungeonCreator.MainWindow()
    if self.GUI.Open then
        local flags = GUI.WindowFlags_NoResize
        GUI:SetNextWindowSize(self.GUI.Width, self.GUI.Height, GUI.SetCond_Always)
        self.GUI.Visible, self.GUI.Open = GUI:Begin([[DungeonCreator v]] .. self.Info.ChangeLog[self.Info.Version].Version, self.GUI.Open, flags)
            
            if FolderExists(DungeonCreator.ProfilePath) then
                MashLib.UI.BeginTitledChild([[Header]], [[Profiles]], 740, 45, 0)
                    GUI:Columns(2, [[]], false)
                    GUI:SetColumnWidth(-1, 410)

-- ------------------------- Select Profile ------------------------

                        GUI:PushItemWidth(400)

                            DungeonCreator.ProfileList = MashLib.System.GetFilesInside(DungeonCreator.ProfilePath)
                            
                            if DungeonCreator.ProfileList then
                                DungeonCreator.GUI.Combos.Profile, _ = GUI:Combo([[##ProfileList]], DungeonCreator.GUI.Combos.Profile, DungeonCreator.ProfileList)
                            end

                        GUI:PopItemWidth()

                    GUI:NextColumn()
                    GUI:SetColumnWidth(-1, 350)

-- ------------------------- Save Profile ------------------------

                        local SaveProfile = GUI:Button([[Save##SaveProfile]], 50, 19)

                        if GUI:IsItemClicked(SaveProfile) then 
                            local FilePath = DungeonCreator.ProfilePath .. DungeonCreator.ProfileList[DungeonCreator.GUI.Combos.Profile]

                            if FileExists(FilePath) then
                                DungeonCreator.FormatFileToFramework(DungeonCreator.CurrentFile)
                                DungeonCreator.ProfileLoaded[DungeonCreator.GUI.Combos.Profile] = FileLoad(FilePath)
                            end
                        end

                        if GUI:IsItemHovered(SaveProfile) then
                            GUI:BeginTooltip()
                                GUI:Text([[Save this profile.]])
                            GUI:EndTooltip()
                        end

                        GUI:SameLine()

-- ------------------------- Reload Profile ------------------------

                        local ReloadProfile = GUI:Button([[Reload##ReloadProfile]], 50, 19)

                        if GUI:IsItemClicked(ReloadProfile) then 
                            local FilePath = DungeonCreator.ProfilePath .. DungeonCreator.ProfileList[DungeonCreator.GUI.Combos.Profile]

                            if FileExists(FilePath) then
                                DungeonCreator.ProfileLoaded[DungeonCreator.GUI.Combos.Profile] = FileLoad(FilePath)
                            end
                        end

                        if GUI:IsItemHovered(ReloadProfile) then
                            GUI:BeginTooltip()
                                GUI:Text([[Reload this profile.]])
                            GUI:EndTooltip()
                        end

                        GUI:SameLine()

-- ------------------------- New Profile ------------------------
                                
                        local NewProfile = GUI:Button([[+##AddProfile]], 19, 19)
                                
                        if GUI:IsItemClicked(NewProfile) then 
                            DungeonCreator.CreatingProfile = true
                        end

                        if GUI:IsItemHovered(NewProfile) then
                            GUI:BeginTooltip()
                                GUI:Text([[Create profile.]])
                            GUI:EndTooltip()
                        end

                        GUI:SameLine()

-- ------------------------- Delete Profile ------------------------

                        local DeleteProfile = GUI:Button([[-##DeleteProfile]], 19, 19)

                        if GUI:IsItemClicked(DeleteProfile) then 
                            local FilePath = DungeonCreator.ProfilePath .. DungeonCreator.ProfileList[DungeonCreator.GUI.Combos.Profile]

                            if FileExists(FilePath) then
                                FileDelete(FilePath)
                            end
                        end

                        if GUI:IsItemHovered(DeleteProfile) then
                            GUI:BeginTooltip()
                                GUI:Text([[Delete this profile.]])
                            GUI:EndTooltip()
                        end

                        GUI:SameLine()

-- ------------------------- Open Folder ------------------------

                        local OpenProfileFolder = GUI:Button([[Open Folder##OpenProfileFolder]], 90, 19)

                        if GUI:IsItemClicked(OpenProfileFolder) then 
                            d(MashLib.Helpers.EscapeSlash(DungeonCreator.ProfilePath))
                            MashLib.Powershell.Execute([[ii ]] .. DungeonCreator.ProfilePath)
                        end

                        if GUI:IsItemHovered(DeleteProfile) then
                            GUI:BeginTooltip()
                                GUI:Text([[Open profiles folder.]])
                            GUI:EndTooltip()
                        end

                        GUI:SameLine()
                            -- Tehe xD
                            GUI:Text(" ")
                        GUI:SameLine()
                        
-- ------------------------- Discord ------------------------

                        if FileExists(MashLib.MediaPath .. [[discord.png]]) then
                            local DiscordBtn = GUI:ImageButton([[DiscordBtn]], MashLib.MediaPath .. [[discord.png]], 20, 20, -1, -1, 0, 0, 0)

                            if GUI:IsItemHovered(DiscordBtn) then
                                GUI:BeginTooltip()
                                    GUI:Text([[Kitanoi's Discord Server]])
                                GUI:EndTooltip()
                            end

                            if GUI:IsItemClicked(DiscordBtn) then
                                MashLib.Powershell.OpenLink([[https://discord.gg/VzSGM7mANy]])
                            end
                        end

                        GUI:SameLine()
                            GUI:Text(" ")
                        GUI:SameLine()

-- ------------------------- Patreon ------------------------

                        local PatreonBtn = GUI:ImageButton([[PatreonBtn]], MashLib.MediaPath .. [[patreon.png]], 20, 20, -1, -1, 0, 0, 0)

                        if GUI:IsItemHovered(PatreonBtn) then
                            GUI:BeginTooltip()
                                GUI:Text([[Consider becoming a patron!]])
                            GUI:EndTooltip()
                        end

                        if GUI:IsItemClicked(PatreonBtn) then
                            MashLib.Powershell.OpenLink(MashLib.Info.Patreon)
                        end

                    GUI:Columns(1)
                MashLib.UI.PopTitledChild()

                GUI:NewLine()

-- ------------------------- Creating Profile ------------------------

                if DungeonCreator.CreatingProfile then
                    MashLib.UI.BeginTitledChild([[CreateNewProfileSect]], [[Creating new profile]], 715, 185, 0)
                        GUI:Indent()
                            DungeonCreator.GUI.Inputs.NewProfileName = GUI:InputText([[##DungeonName]], DungeonCreator.GUI.Inputs.NewProfileName)
                            
                            local CommitCreateProfile = GUI:Button([[Create##CommitCreateProfile]], 50, 19)

                            if GUI:IsItemClicked(CommitCreateProfile) then 
                                local NewProfile = {
                                    name = "",
                                    dutyid = 0,
                                    mesh = "",
                                    queuetype = 2,
                                    prioritytarget = {},
                                    enemytargetdistance = 30,
                                    objectivedestinations = {},	
                                    bossids = {},
                                    interacts = {}
                                }

                                FileSave(DungeonCreator.ProfilePath .. DungeonCreator.GUI.Inputs.NewProfileName .. [[.lua]], NewProfile)
                                DungeonCreator.GUI.Inputs.NewProfileName = [[]]
                                DungeonCreator.CreatingProfile = false
                            end

                            GUI:SameLine()

                            local CancelCreateProfile = GUI:Button([[Cancel##CancelCreateProfile]], 50, 19)

                            if GUI:IsItemClicked(CancelCreateProfile) then 
                                DungeonCreator.GUI.Inputs.NewProfileName = [[]]
                                DungeonCreator.CreatingProfile = false
                            end
                        GUI:Unindent()

                    MashLib.UI.PopTitledChild()
                else
                    
-- ------------------------- Loading Profile ------------------------

                    local FilePath = DungeonCreator.ProfilePath .. DungeonCreator.ProfileList[DungeonCreator.GUI.Combos.Profile]

                    if not DungeonCreator.ProfileLoaded[DungeonCreator.GUI.Combos.Profile] then
                        DungeonCreator.ProfileLoaded[DungeonCreator.GUI.Combos.Profile] = FileLoad(FilePath)
                    end

                    if table.valid(DungeonCreator.ProfileLoaded[DungeonCreator.GUI.Combos.Profile]) then
                        DungeonCreator.CurrentFile = DungeonCreator.ProfileLoaded[DungeonCreator.GUI.Combos.Profile]
                        DungeonCreator.ErrorProfileNotValid = false
                    else
                        DungeonCreator.ErrorProfileNotValid = true
                    end

                    if DungeonCreator.ErrorProfileNotValid then
                        MashLib.UI.BeginTitledChild([[ErrorProfileNotValid]], [[Error]], 740, 60, 0, { 255/255, 125/255, 125/255, 1 }, { 255/255, 125/255, 125/255, 1 })
                            GUI:Indent()
                                GUI:Text("The profile selected is not valid.")
                                GUI:Text("If you edited the profile manually, be sure that the syntax is correct.")
                            GUI:Unindent()
                        MashLib.UI.PopTitledChild()
                    else
                        
-- ------------------------- Settings ------------------------

                        MashLib.UI.BeginTitledChild([[ProfileSettings]], [[Settings]], 740, 185, 0)
                            GUI:Indent()
                                GUI:Columns(2, [[]], false)
                                GUI:SetColumnWidth(-1, 200)
                                    GUI:Text([[Profile Name]])
                                GUI:NextColumn()
                                GUI:SetColumnWidth(-1, 600)
                                    GUI:PushItemWidth(320)
                                        GUI:InputText([[##FileName]], DungeonCreator.ProfileList[DungeonCreator.GUI.Combos.Profile], (GUI.InputTextFlags_ReadOnly))
                                    GUI:PopItemWidth()

                                    GUI:SameLine()

                                    GUI:Text([[ ]] .. (DungeonCreator.CurrentFile.createdate and DungeonCreator.CurrentFile.createdate or [[]]))

                                    if GUI:IsItemHovered() then
                                        GUI:BeginTooltip()
                                            GUI:Text([[Profile creation date (dd/mm/yy)]])
                                        GUI:EndTooltip()
                                    end
                                GUI:NextColumn()
                                    GUI:Text([[Dungeon Name]])
                                GUI:NextColumn()
                                    GUI:PushItemWidth(320)
                                        DungeonCreator.CurrentFile.name = GUI:InputText([[##FileDungeonName]], DungeonCreator.CurrentFile.name or [[]])
                                    GUI:PopItemWidth()

                                    GUI:SameLine()

                                    GUI:Text([[ ]] .. (DungeonCreator.CurrentFile.lastupdate and DungeonCreator.CurrentFile.lastupdate or [[]]))

                                    if GUI:IsItemHovered() then
                                        GUI:BeginTooltip()
                                            GUI:Text([[Profile last update (dd/mm/yy)]])
                                        GUI:EndTooltip()
                                    end
                                GUI:NextColumn()
                                    GUI:Text([[Profile Author]])
                                GUI:NextColumn()
                                    GUI:PushItemWidth(320)
                                        DungeonCreator.CurrentFile.author = GUI:InputText([[##FileProfileAuthor]], DungeonCreator.CurrentFile.author or [[]])
                                    GUI:PopItemWidth()
                                GUI:NextColumn()
                                    GUI:Text([[Duty Type]])
                                GUI:NextColumn()
                                    if type(DungeonCreator.CurrentFile.type) == "string" then
                                        DungeonCreator.CurrentFile.type = MashLib.Helpers.GetByValue(DungeonCreator.DutyType, DungeonCreator.CurrentFile.type, true)
                                    end

                                    GUI:PushItemWidth(100)
                                        DungeonCreator.CurrentFile.type, _ = GUI:Combo([[##FileDutyType]], DungeonCreator.CurrentFile.type and DungeonCreator.CurrentFile.type or 1, DungeonCreator.DutyType)
                                    GUI:PopItemWidth()
                                GUI:NextColumn()
                                    GUI:Text([[Queue Type]])
                                GUI:NextColumn()
                                    local QueueTypes = {
                                        [1] = "Synced",
                                        [2] = "Unsynced"
                                    }
                                    
                                    GUI:PushItemWidth(100)
                                        DungeonCreator.CurrentFile.queuetype, _ = GUI:Combo([[##FileQueueType]], DungeonCreator.CurrentFile.queuetype and DungeonCreator.CurrentFile.queuetype or 2, QueueTypes)
                                    GUI:PopItemWidth()
                                GUI:NextColumn()
                                    GUI:Text([[Duty ID]])
                                GUI:NextColumn()

                                    local SetCurrentMapId = GUI:Button([[Get Current##SetCurrentMapId]], 120, 19)

                                    if GUI:IsItemClicked(SetCurrentMapId) then 
                                        DungeonCreator.CurrentFile.dutyid = Player.localmapid
                                    end

                                    GUI:SameLine()

                                    GUI:PushItemWidth(50)
                                        DungeonCreator.CurrentFile.dutyid = GUI:InputText([[##FileDutyId]], DungeonCreator.CurrentFile.dutyid and DungeonCreator.CurrentFile.dutyid or [[]])
                                    GUI:PopItemWidth()
                                GUI:NextColumn()
                                    GUI:Text([[Mesh]])
                                GUI:NextColumn()
                                    GUI:PushItemWidth(300)

                                        local SetCurrentMapMeshName = GUI:Button([[Get Current##SetCurrentMapMeshName]], 120, 19)

                                        if GUI:IsItemClicked(SetCurrentMapMeshName) then 
                                            DungeonCreator.CurrentFile.mesh = ml_mesh_mgr.currentfilename
                                        end

                                        GUI:SameLine()

                                        DungeonCreator.CurrentFile.mesh = GUI:InputText([[##FileMesh]], DungeonCreator.CurrentFile.mesh and DungeonCreator.CurrentFile.mesh or [[]])
                                        
                                    GUI:PopItemWidth()
                                GUI:Columns(1)
                            GUI:Unindent()
                        MashLib.UI.PopTitledChild()

                        GUI:NewLine()

    -- ------------------------- Profile Body ------------------------

                        GUI:BeginChild("##Body", 743, 510, true)
                                
    -- ------------------------- Misc Settings ------------------------

                            if (GUI:CollapsingHeader(GetString("Miscellaneous"))) then
                                MashLib.UI.BeginTitledChild([[ProfileMiscellaneous]], [[Miscellaneous]], 715, 160, 0)
                                    GUI:Indent()
                                        GUI:Columns(2, [[]], false)
                                        GUI:SetColumnWidth(-1, 200)
                                            GUI:Text([[Enemy Target Distance]])
                                        GUI:NextColumn()
                                        GUI:SetColumnWidth(-1, 600)
                                            GUI:PushItemWidth(100)
                                                DungeonCreator.CurrentFile.enemytargetdistance = GUI:InputInt([[##FileEnemyTargetDistance]], DungeonCreator.CurrentFile.enemytargetdistance and DungeonCreator.CurrentFile.enemytargetdistance or 30)
                                            GUI:PopItemWidth()
                                        GUI:NextColumn()
                                            GUI:Text([[Interaction Distance]])
                                        GUI:NextColumn()
                                            GUI:PushItemWidth(100)
                                                DungeonCreator.CurrentFile.interactdistance, _ = GUI:InputInt([[##FileInteractionDistance]], DungeonCreator.CurrentFile.interactdistance and DungeonCreator.CurrentFile.interactdistance or 30)
                                            GUI:PopItemWidth()
                                        GUI:NextColumn()
                                            GUI:Text([[Requeue Timer]])
                                        GUI:NextColumn()
                                            GUI:PushItemWidth(100)
                                                DungeonCreator.CurrentFile.requeuetimer, _ = GUI:InputInt([[##FileRequeueTimer]], DungeonCreator.CurrentFile.requeuetimer and DungeonCreator.CurrentFile.requeuetimer or 10)
                                            GUI:PopItemWidth()
                                        GUI:NextColumn()
                                            GUI:Text([[Priority Target Distance]])
                                        GUI:NextColumn()
                                            GUI:PushItemWidth(100)
                                                DungeonCreator.CurrentFile.prioritytargetdistance, _ = GUI:InputInt([[##FilePriorityTargetDistance]], DungeonCreator.CurrentFile.prioritytargetdistance and DungeonCreator.CurrentFile.prioritytargetdistance or 10)
                                            GUI:PopItemWidth()
                                        GUI:NextColumn()
                                            GUI:Text([[Exclude Avoiding]])
                                        GUI:NextColumn()
                                            GUI:PushItemWidth(300)
                                                DungeonCreator.CurrentFile.excludeavoid, _ = GUI:InputText([[##FileExcludeAvoid]], DungeonCreator.CurrentFile.excludeavoid and DungeonCreator.CurrentFile.excludeavoid or [[]])
                                            GUI:PopItemWidth()

                                            if GUI:IsItemHovered(DungeonCreator.CurrentFile.excludeavoid) then
                                                GUI:BeginTooltip()
                                                    GUI:Text([[Entities' ContentID separated by comma.]])
                                                GUI:EndTooltip()
                                            end

                                            GUI:SameLine()

                                            local AddTargetExcludeAvoid = GUI:Button([[Add target##AddTargetExcludeAvoid]], 120, 19)

                                            if GUI:IsItemClicked(AddTargetExcludeAvoid) then 
                                                if Player:GetTarget() then
                                                    local TargetContentId = Player:GetTarget().contentid

                                                    if DungeonCreator.CurrentFile.excludeavoid ~= [[]] then
                                                        local Split = MashLib.Helpers.SplitString(DungeonCreator.CurrentFile.excludeavoid, ',')
                                                        local Result = [[]]

                                                        for _, v in ipairs(Split) do 
                                                            Result = (Result ~= [[]] and Result .. [[,]] or [[]]) .. tostring(tonumber(v))
                                                        end

                                                        if not table.contains(Split, tostring(TargetContentId)) then
                                                            DungeonCreator.CurrentFile.excludeavoid = Result .. [[,]] .. TargetContentId
                                                        else
                                                            DungeonCreator.CurrentFile.excludeavoid = Result
                                                        end
                                                    else
                                                        DungeonCreator.CurrentFile.excludeavoid = TargetContentId
                                                    end
                                                end
                                            end

                                            GUI:SameLine()

                                            local ClearExcludeAvoid = GUI:Button([[Clear##ClearExcludeAvoid]], 50, 19)

                                            if GUI:IsItemClicked(ClearExcludeAvoid) then 
                                                DungeonCreator.CurrentFile.excludeavoid = [[]]
                                            end

                                        GUI:NextColumn()
                                            DungeonCreator.CurrentFile.forcemeleerange = GUI:Checkbox(GetString([[Force melee range]]), DungeonCreator.CurrentFile.forcemeleerange and DungeonCreator.CurrentFile.forcemeleerange or false)
                                        GUI:NextColumn()
                                            DungeonCreator.CurrentFile.pullenemyoutofpuddle = GUI:Checkbox(GetString([[Pull enemies out of puddles]]), DungeonCreator.CurrentFile.pullenemyoutofpuddle and DungeonCreator.CurrentFile.pullenemyoutofpuddle or false)
                                        GUI:Columns(1)
                                    GUI:Unindent()

                                MashLib.UI.PopTitledChild()
                                GUI:NewLine()
                            end

    -- ------------------------- Objectives ------------------------

                            if (GUI:CollapsingHeader(GetString("Objectives"))) then
                                if DungeonCreator.CurrentFile.objectivedestinations then
                                    MashLib.UI.BeginTitledChild([[ProfileObjectives]], [[Objectives]], 715, 200, 0)
                                        GUI:Indent()

                                            GUI:BeginChild([[##ObjectivesButtons]], 695, 30)
                                            
                                                local AddObjective = GUI:Button([[Add##AddObjective]], 50, 19)

                                                if GUI:IsItemClicked(AddObjective) then 
                                                    local index = #DungeonCreator.CurrentFile.objectivedestinations+1

                                                    DungeonCreator.CurrentFile.objectivedestinations[index] = {
                                                        objective = index,
                                                        pos = {
                                                            x = Player.pos.x,
                                                            y = Player.pos.y,
                                                            z = Player.pos.z
                                                        }
                                                    }
                                                end

                                                GUI:SameLine()

                                                local AddObjectiveTargetPos = GUI:Button([[Add from target##AddObjectiveTargetPos]], 150, 19)
                                                
                                                if GUI:IsItemClicked(AddObjectiveTargetPos) then
                                                    local index = #DungeonCreator.CurrentFile.objectivedestinations+1

                                                    if Player:GetTarget() then
                                                        DungeonCreator.CurrentFile.objectivedestinations[index] = {
                                                            objective = index,
                                                            pos = {
                                                                x = Player:GetTarget().pos.x,
                                                                y = Player:GetTarget().pos.y,
                                                                z = Player:GetTarget().pos.z
                                                            }
                                                        }
                                                    end
                                                end

                                                GUI:SameLine()

                                                local ClearObjectives = GUI:Button([[Clear##ClearObjectives]], 50, 19)

                                                if GUI:IsItemClicked(ClearObjectives) then 
                                                    DungeonCreator.CurrentFile.objectivedestinations = {}
                                                end

                                            GUI:EndChild()

                                            GUI:Columns(5, [[]], false)
                                            GUI:SetColumnWidth(-1, 80)
                                                GUI:Text([[Order]])
                                            GUI:NextColumn()
                                            GUI:SetColumnWidth(-1, 70)
                                                GUI:Text([[PosX]])
                                            GUI:NextColumn()
                                            GUI:SetColumnWidth(-1, 70)
                                                GUI:Text([[PosY]])
                                            GUI:NextColumn()
                                            GUI:SetColumnWidth(-1, 70)
                                                GUI:Text([[PosZ]])
                                            GUI:NextColumn()
                                            GUI:SetColumnWidth(-1, 200)
                                                GUI:Text()
                                            GUI:Columns(1)
                                            
                                            GUI:BeginChild([[##ObjectiveList]], 695, 120, true)

                                                GUI:Columns(5, [[]], false)
                                                GUI:SetColumnWidth(-1, 70)
                                                    if MashLib.Helpers.SizeOf(DungeonCreator.CurrentFile.objectivedestinations) > 0 then
                                                        for k, v in pairs(DungeonCreator.CurrentFile.objectivedestinations) do 
                                                                GUI:PushItemWidth(60)
                                                                    DungeonCreator.CurrentFile.objectivedestinations[k].objective = GUI:InputText([[##ObjectiveItem]] .. k, DungeonCreator.CurrentFile.objectivedestinations[k].objective)
                                                                GUI:PopItemWidth()
                                                            GUI:NextColumn()
                                                            GUI:SetColumnWidth(-1, 70)
                                                                GUI:PushItemWidth(60)
                                                                    DungeonCreator.CurrentFile.objectivedestinations[k].pos.x = GUI:InputFloat([[##ObjectivePosX]] .. k, DungeonCreator.CurrentFile.objectivedestinations[k].pos.x)
                                                                GUI:PopItemWidth()
                                                            GUI:NextColumn()
                                                            GUI:SetColumnWidth(-1, 70)
                                                                GUI:PushItemWidth(60)
                                                                    DungeonCreator.CurrentFile.objectivedestinations[k].pos.y = GUI:InputFloat([[##ObjectivePosY]] .. k, DungeonCreator.CurrentFile.objectivedestinations[k].pos.y)
                                                                GUI:PopItemWidth()
                                                            GUI:NextColumn()
                                                            GUI:SetColumnWidth(-1, 70)
                                                                GUI:PushItemWidth(60)
                                                                    DungeonCreator.CurrentFile.objectivedestinations[k].pos.z = GUI:InputFloat([[##ObjectivePosZ]] .. k, DungeonCreator.CurrentFile.objectivedestinations[k].pos.z)
                                                                GUI:PopItemWidth()
                                                            GUI:NextColumn()
                                                            GUI:SetColumnWidth(-1, 400)

                                                                local ObjectiveGoToPos = GUI:Button([[Go to pos##ObjectiveGoToPos]], 100, 19)
                                                                
                                                                if GUI:IsItemClicked(ObjectiveGoToPos) then 
                                                                    if DungeonCreator.CurrentFile.objectivedestinations[k].pos then
                                                                        Player:MoveTo(tonumber(DungeonCreator.CurrentFile.objectivedestinations[k].pos.x),tonumber(DungeonCreator.CurrentFile.objectivedestinations[k].pos.y),tonumber(DungeonCreator.CurrentFile.objectivedestinations[k].pos.z))
                                                                    end
                                                                end

                                                                GUI:SameLine()
                                                                
                                                                local ObjectiveGetTargetPos = GUI:Button([[Target or Me##ObjectiveGetTargetPos]], 150, 19)
                                                                
                                                                if GUI:IsItemClicked(ObjectiveGetTargetPos) then
                                                                    if Player:GetTarget() then
                                                                        DungeonCreator.CurrentFile.objectivedestinations[k].pos = {
                                                                            x = Player:GetTarget().pos.x,
                                                                            y = Player:GetTarget().pos.y,
                                                                            z = Player:GetTarget().pos.z
                                                                        }
                                                                    else
                                                                        DungeonCreator.CurrentFile.objectivedestinations[k].pos = {
                                                                            x = Player.pos.x,
                                                                            y = Player.pos.y,
                                                                            z = Player.pos.z
                                                                        }
                                                                    end
                                                                end

                                                                GUI:SameLine()

                                                                local RemoveObjective = GUI:Button([[Remove##RemoveObjective]], 50, 19)

                                                                if GUI:IsItemClicked(RemoveObjective) then 
                                                                    DungeonCreator.CurrentFile.objectivedestinations[k] = nil
                                                                end

                                                            GUI:NextColumn()
                                                        end
                                                    end
                                                GUI:Columns(1)
                                            GUI:EndChild()
                                        GUI:Unindent()
                                    MashLib.UI.PopTitledChild()
                                    GUI:NewLine()
                                else
                                    DungeonCreator.CurrentFile.objectivedestinations = {}
                                end
                            end
                            
    -- ------------------------- Boss ID ------------------------

                            if (GUI:CollapsingHeader(GetString("Bosses"))) then
                                if DungeonCreator.CurrentFile.bossids then
                                    MashLib.UI.BeginTitledChild([[ProfileBossId]], [[Bosses]], 715, 200, 0)
                                        GUI:Indent()

                                            GUI:BeginChild([[##BossIdButtons]], 695, 30)

                                                local AddTargetBossId = GUI:Button([[Add from target##AddTargetBossId]], 150, 19)

                                                if GUI:IsItemClicked(AddTargetBossId) then 
                                                    if Player:GetTarget() then
                                                        local index = #DungeonCreator.CurrentFile.bossids+1
                                                        DungeonCreator.CurrentFile.bossids[index] = Player:GetTarget().contentId
                                                    end
                                                end

                                                GUI:SameLine()

                                                local ClearBossId = GUI:Button([[Clear##ClearBossId]], 50, 19)

                                                if GUI:IsItemClicked(ClearBossId) then 
                                                    DungeonCreator.CurrentFile.bossids = {}
                                                end

                                            GUI:EndChild()

                                            GUI:Columns(2, [[]], false)
                                            GUI:SetColumnWidth(-1, 100)
                                                GUI:Text([[ContentID]])
                                            GUI:NextColumn()
                                            GUI:SetColumnWidth(-1, 200)
                                                GUI:Text()
                                            GUI:Columns(1)
                                            

                                            GUI:BeginChild([[##BossIdList]], 695, 120)
                                                GUI:Columns(2, [[]], false)
                                                GUI:SetColumnWidth(-1, 100)
                                                    if MashLib.Helpers.SizeOf(DungeonCreator.CurrentFile.bossids) > 0 then
                                                        for k, v in pairs(DungeonCreator.CurrentFile.bossids) do 
                                                                GUI:Text(v)
                                                            GUI:NextColumn()
                                                            GUI:SetColumnWidth(-1, 200)

                                                                local RemoveBossId = GUI:Button([[Remove##RemoveBossId]], 50, 19)
                            
                                                                if GUI:IsItemClicked(RemoveBossId) then 
                                                                    DungeonCreator.CurrentFile.bossids[k] = nil
                                                                end

                                                            GUI:NextColumn()
                                                        end
                                                    end
                                                GUI:Columns(1)
                                            GUI:EndChild()

                                        GUI:Unindent()
                                    MashLib.UI.PopTitledChild()
                                    GUI:NewLine()
                                else
                                    DungeonCreator.CurrentFile.bossids = {}
                                end
                            end
                            
    -- ------------------------- Priority Target ------------------------

                            if (GUI:CollapsingHeader(GetString("Priority Targets"))) then
                                if DungeonCreator.CurrentFile.prioritytarget then
                                    MashLib.UI.BeginTitledChild([[ProfilePriorityTarget]], [[Priority Targets]], 715, 200, 0)
                                        GUI:Indent()

                                            GUI:BeginChild([[##PriorityTargetsButtons]], 695, 30)

                                                local AddPriorityTarget = GUI:Button([[Add##AddPriorityTarget]], 50, 19)
                                                

                                                if GUI:IsItemClicked(AddPriorityTarget) then 
                                                    local index = #DungeonCreator.CurrentFile.prioritytarget+1

                                                    DungeonCreator.CurrentFile.prioritytarget[index] = {
                                                        contentid = 0,
                                                        priority = 1,
                                                        type = ""
                                                    }
                                                end
                                                
                                                GUI:SameLine()

                                                local AddTargetPriorityTarget = GUI:Button([[Add from target##AddTargetPriorityTarget]], 150, 19)
                                                

                                                if GUI:IsItemClicked(AddTargetPriorityTarget) then 
                                                    if Player:GetTarget() then
                                                        local index = #DungeonCreator.CurrentFile.prioritytarget+1
                                                        
                                                        DungeonCreator.CurrentFile.prioritytarget[index] = {
                                                            contentid = Player:GetTarget().contentId,
                                                            priority = 1,
                                                            type = Player:GetTarget().name
                                                        }
                                                    end
                                                end

                                                GUI:SameLine()

                                                local ClearPriorityTargets = GUI:Button([[Clear##ClearPriorityTargets]], 50, 19)

                                                if GUI:IsItemClicked(ClearPriorityTargets) then 
                                                    DungeonCreator.CurrentFile.prioritytarget = {}
                                                end

                                            GUI:EndChild()

                                            GUI:Columns(4, [[]], false)
                                            GUI:SetColumnWidth(-1, 100)
                                                GUI:Text([[ContentId]])
                                            GUI:NextColumn()
                                            GUI:SetColumnWidth(-1, 100)
                                                GUI:Text([[Priority]])
                                            GUI:NextColumn()
                                            GUI:SetColumnWidth(-1, 300)
                                                GUI:Text([[Type]])
                                            GUI:NextColumn()
                                            GUI:SetColumnWidth(-1, 100)
                                                GUI:Text()
                                            GUI:Columns(1)

                                            GUI:BeginChild([[##PriorityTargetList]], 695, 120)
                                                GUI:Columns(4, [[]], false)
                                                GUI:SetColumnWidth(-1, 100)
                                                    if MashLib.Helpers.SizeOf(DungeonCreator.CurrentFile.prioritytarget) > 0 then
                                                        for k, v in pairs(DungeonCreator.CurrentFile.prioritytarget) do 
                                                                DungeonCreator.CurrentFile.prioritytarget[k].contentid = GUI:InputText([[##PriorityTargetContentId]] .. k, DungeonCreator.CurrentFile.prioritytarget[k].contentid)
                                                            GUI:NextColumn()
                                                            GUI:SetColumnWidth(-1, 100)
                                                                DungeonCreator.CurrentFile.prioritytarget[k].priority = GUI:InputText([[##PriorityTargetPriority]] .. k, DungeonCreator.CurrentFile.prioritytarget[k].priority)
                                                            GUI:NextColumn()
                                                            GUI:SetColumnWidth(-1, 300)
                                                                GUI:PushItemWidth(290)
                                                                    DungeonCreator.CurrentFile.prioritytarget[k].type = GUI:InputText([[##PriorityTargetType]] .. k, DungeonCreator.CurrentFile.prioritytarget[k].type)
                                                                GUI:PopItemWidth()
                                                            GUI:NextColumn()
                                                            GUI:SetColumnWidth(-1, 200)

                                                                local GetPriorityTargetContentIdFromTarget = GUI:Button([[Get target##GetPriorityTargetContentIdFromTarget]], 100, 19)

                                                                if GUI:IsItemClicked(GetPriorityTargetContentIdFromTarget) then 
                                                                    DungeonCreator.CurrentFile.prioritytarget[k].contentid = Player:GetTarget().contentId
                                                                    DungeonCreator.CurrentFile.prioritytarget[k].type = Player:GetTarget().name
                                                                end

                                                                GUI:SameLine()

                                                                local RemovePriorityTarget = GUI:Button([[Remove##RemovePriorityTarget]], 50, 19)

                                                                if GUI:IsItemClicked(RemovePriorityTarget) then 
                                                                    DungeonCreator.CurrentFile.prioritytarget[k] = nil
                                                                end

                                                            GUI:NextColumn()
                                                        end
                                                    end
                                                GUI:Columns(1)
                                            GUI:EndChild()

                                        GUI:Unindent()
                                    MashLib.UI.PopTitledChild()
                                    GUI:NewLine()
                                else
                                    DungeonCreator.CurrentFile.prioritytarget = {}
                                end
                            end
                            
    -- ------------------------- Interactions ------------------------

                            if (GUI:CollapsingHeader(GetString("Interactions"))) then
                                if DungeonCreator.CurrentFile.interacts then
                                    MashLib.UI.BeginTitledChild([[ProfileInteractions]], [[Interactions]], 715, 200, 0)
                                        GUI:Indent()
                                            GUI:BeginChild([[##InteractionsButtons]], 695, 30)

                                                local AddInteraction = GUI:Button([[Add##AddInteraction]], 50, 19)

                                                if GUI:IsItemClicked(AddInteraction) then 
                                                    local index = #DungeonCreator.CurrentFile.interacts+1
                                                    
                                                    DungeonCreator.CurrentFile.interacts[index] = {
                                                        contentid = 0,
                                                        priority = 1,
                                                        type = ""
                                                    }
                                                end

                                                GUI:SameLine()

                                                local AddTargetInteraction = GUI:Button([[Add from target##AddTargetInteraction]], 150, 19)

                                                if GUI:IsItemClicked(AddTargetInteraction) then 
                                                    if Player:GetTarget() then
                                                        local index = #DungeonCreator.CurrentFile.interacts+1
                                                        
                                                        DungeonCreator.CurrentFile.interacts[index] = {
                                                            contentid = Player:GetTarget().contentId,
                                                            priority = 1,
                                                            type = Player:GetTarget().name
                                                        }
                                                    end
                                                end

                                                GUI:SameLine()

                                                local ClearInteractions = GUI:Button([[Clear##ClearInteractions]], 50, 19)

                                                if GUI:IsItemClicked(ClearInteractions) then 
                                                    DungeonCreator.CurrentFile.interacts = {}
                                                end

                                            GUI:EndChild()

                                            GUI:Columns(4, [[]], false)
                                            GUI:SetColumnWidth(-1, 100)
                                                GUI:Text([[ContentId]])
                                            GUI:NextColumn()
                                            GUI:SetColumnWidth(-1, 100)
                                                GUI:Text([[Priority]])
                                            GUI:NextColumn()
                                            GUI:SetColumnWidth(-1, 300)
                                                GUI:Text([[Type]])
                                            GUI:NextColumn()
                                            GUI:SetColumnWidth(-1, 100)
                                                GUI:Text()
                                            GUI:Columns(1)

                                            GUI:BeginChild([[##InteractionList]], 695, 120)
                                                GUI:Columns(4, [[]], false)
                                                GUI:SetColumnWidth(-1, 100)
                                                    if MashLib.Helpers.SizeOf(DungeonCreator.CurrentFile.interacts) > 0 then
                                                        for k, v in pairs(DungeonCreator.CurrentFile.interacts) do 
                                                            DungeonCreator.CurrentFile.interacts[k].contentid = GUI:InputText([[##InteractContentId]] .. k, DungeonCreator.CurrentFile.interacts[k].contentid and DungeonCreator.CurrentFile.interacts[k].contentid or [[0]])
                                                        GUI:NextColumn()
                                                        GUI:SetColumnWidth(-1, 100)
                                                            DungeonCreator.CurrentFile.interacts[k].priority = GUI:InputText([[##InteractPriority]] .. k, DungeonCreator.CurrentFile.interacts[k].priority and DungeonCreator.CurrentFile.interacts[k].priority or [[1]])
                                                        GUI:NextColumn()
                                                        GUI:SetColumnWidth(-1, 300)
                                                            GUI:PushItemWidth(290)
                                                                DungeonCreator.CurrentFile.interacts[k].type = GUI:InputText([[##InteractType]] .. k, DungeonCreator.CurrentFile.interacts[k].type and DungeonCreator.CurrentFile.interacts[k].type or [[]])
                                                            GUI:PopItemWidth()
                                                        GUI:NextColumn()
                                                        GUI:SetColumnWidth(-1, 200)
                                        
                                                            local GetInteraction = GUI:Button([[Get target##GetInteraction]], 100, 19)

                                                            if GUI:IsItemClicked(GetInteraction) then
                                                                DungeonCreator.CurrentFile.interacts[k] = {
                                                                    contentid = Player:GetTarget().contentId,
                                                                    priority = 1,
                                                                    type = Player:GetTarget().name
                                                                }
                                                            end

                                                            GUI:SameLine()
                                        
                                                            local RemoveInteraction = GUI:Button([[Remove##RemoveInteraction]], 50, 19)

                                                            if GUI:IsItemClicked(RemoveInteraction) then 
                                                                DungeonCreator.CurrentFile.interacts[k] = nil
                                                            end

                                                        GUI:NextColumn()
                                                    end
                                                end
                                                GUI:Columns(1)
                                            GUI:EndChild()

                                        GUI:Unindent()
                                    MashLib.UI.PopTitledChild()
                                    GUI:NewLine()
                                else
                                    DungeonCreator.CurrentFile.interacts = {}
                                end
                            end

    -- ------------------------- Buffs ------------------------

                            if (GUI:CollapsingHeader(GetString("Buff Checks"))) then
                                if DungeonCreator.CurrentFile.hasbuff then
                                    MashLib.UI.BeginTitledChild([[ProfileHasBuffs]], [[Buffs]], 715, 400, 0)
                                        GUI:Indent()

                                            GUI:BeginChild([[##HasBuffsButtons]], 695, 30)

                                                local AddMoveHasBuff = GUI:Button([[Add Interact##AddMoveHasBuff]], 150, 19)

                                                if GUI:IsItemClicked(AddMoveHasBuff) then 
                                                    DungeonCreator.CurrentFile.hasbuff[#DungeonCreator.CurrentFile.hasbuff+1] = {
                                                        type            = "interact",
                                                        interactid      = "",
                                                        buffid          = 0,
                                                        stacksrequired  = 1,
                                                        desc            = ""
                                                    }
                                                end

                                                GUI:SameLine()

                                                local AddInteractHasBuff = GUI:Button([[Add Move##AddInteractHasBuff]], 150, 19)

                                                if GUI:IsItemClicked(AddInteractHasBuff) then 
                                                    DungeonCreator.CurrentFile.hasbuff[#DungeonCreator.CurrentFile.hasbuff+1] = {
                                                        type            = "move",
                                                        pos             = {},
                                                        buffid          = 0,
                                                        desc            = ""
                                                    }
                                                end

                                                GUI:SameLine()

                                                local ClearHasBuff = GUI:Button([[Clear##ClearHasBuff]], 50, 19)

                                                if GUI:IsItemClicked(ClearHasBuff) then 
                                                    DungeonCreator.CurrentFile.hasbuff = {}
                                                end

                                            GUI:EndChild()

    -- ------------------------- Interact ------------------------

                                            MashLib.UI.BeginTitledChild([[HasBuffInteractList]], [[Interact]], 695, 100, 0)
                                                GUI:Indent()
                                                    GUI:Columns(5, [[]], false)
                                                    GUI:SetColumnWidth(-1, 60)
                                                        GUI:Text([[ID]])
                                                    GUI:NextColumn()
                                                    GUI:SetColumnWidth(-1, 240)
                                                        GUI:Text([[Interact IDs]])
                                                    GUI:NextColumn()
                                                    GUI:SetColumnWidth(-1, 80)
                                                        GUI:Text([[Stack]])
                                                    GUI:NextColumn()
                                                    GUI:SetColumnWidth(-1, 170)
                                                        GUI:Text([[Description]])
                                                    GUI:NextColumn()
                                                    GUI:SetColumnWidth(-1, 100)
                                                        GUI:Text()
                                                    GUI:Columns(1)

                                                    GUI:Columns(5, [[]], false)
                                                    GUI:SetColumnWidth(-1, 60)
                                                        for k, v in pairs(DungeonCreator.CurrentFile.hasbuff) do 
                                                            if DungeonCreator.CurrentFile.hasbuff[k].type == 'interact' then
                                                                GUI:PushItemWidth(50)
                                                                    DungeonCreator.CurrentFile.hasbuff[k].buffid = GUI:InputText([[##HasBuffBuffId]] .. k, DungeonCreator.CurrentFile.hasbuff[k].buffid)
                                                                GUI:PopItemWidth()
                                                                GUI:NextColumn()
                                                                GUI:SetColumnWidth(-1, 235)
                                                                    GUI:PushItemWidth(215)
                                                                        DungeonCreator.CurrentFile.hasbuff[k].interactid = GUI:InputText([[##HasBuffInteractIds]] .. k, DungeonCreator.CurrentFile.hasbuff[k].interactid)
                                                                    GUI:PopItemWidth()
                                                                GUI:NextColumn()
                                                                GUI:SetColumnWidth(-1, 80)
                                                                    GUI:PushItemWidth(50)
                                                                        DungeonCreator.CurrentFile.hasbuff[k].stacksrequired = GUI:InputText([[##HasBuffStackReq]] .. k, DungeonCreator.CurrentFile.hasbuff[k].stacksrequired)
                                                                    GUI:PopItemWidth()
                                                                GUI:NextColumn()
                                                                GUI:SetColumnWidth(-1, 180)
                                                                    GUI:PushItemWidth(160)
                                                                        DungeonCreator.CurrentFile.hasbuff[k].desc = GUI:InputText([[##HasBuffDescription]] .. k, DungeonCreator.CurrentFile.hasbuff[k].desc)
                                                                    GUI:PopItemWidth()
                                                                GUI:NextColumn()
                                                                GUI:SetColumnWidth(-1, 200)

                                                                    local RemoveHasBuff = GUI:Button([[Remove##RemoveHasBuffInteract]], 50, 19)

                                                                    if GUI:IsItemClicked(RemoveHasBuff) then 
                                                                        DungeonCreator.CurrentFile.hasbuff[k] = nil
                                                                    end

                                                                GUI:NextColumn()
                                                            end
                                                        end
                                                    GUI:Columns(1)
                                                GUI:Unindent()
                                            MashLib.UI.PopTitledChild()

    -- ------------------------- Move ------------------------

                                            MashLib.UI.BeginTitledChild([[HasBuffMoveList]], [[Move]], 695, 200, 0)
                                                GUI:Indent()
                                                    for k, v in pairs(DungeonCreator.CurrentFile.hasbuff) do 
                                                        if DungeonCreator.CurrentFile.hasbuff[k].type == 'move' then
                                                            if not GUI:CollapsingHeader(k) then
                                                                local HasBuffAddPosition = GUI:Button([[Add position##HasBuffAddPosition]], 100, 19)

                                                                if GUI:IsItemClicked(HasBuffAddPosition) then 
                                                                    DungeonCreator.CurrentFile.hasbuff[k].pos[#DungeonCreator.CurrentFile.hasbuff[k].pos+1] = {
                                                                        x = Player.pos.x,
                                                                        y = Player.pos.y,
                                                                        z = Player.pos.z
                                                                    }
                                                                end

                                                                GUI:SameLine()

                                                                local HasBuffDeleteItem = GUI:Button([[Delete##HasBuffDeleteItem]], 100, 19)

                                                                if GUI:IsItemClicked(HasBuffDeleteItem) then 
                                                                    DungeonCreator.CurrentFile.hasbuff[k] = nil
                                                                end

                                                                if DungeonCreator.CurrentFile.hasbuff[k] then
                                                                    MashLib.UI.BeginTitledChild([[HasBuffPositions]] .. k, [[Positions]], 667, 100, 0)
                                                                        if MashLib.Helpers.SizeOf(DungeonCreator.CurrentFile.hasbuff[k].pos) > 0 then 
                                                                            GUI:Indent()
                                                                                GUI:Columns(4, [[]], false)
                                                                                GUI:SetColumnWidth(-1, 60)
                                                                                    GUI:Text([[X]])
                                                                                GUI:NextColumn()
                                                                                GUI:SetColumnWidth(-1, 65)
                                                                                    GUI:Text([[Y]])
                                                                                GUI:NextColumn()
                                                                                GUI:SetColumnWidth(-1, 65)
                                                                                    GUI:Text([[Z]])
                                                                                GUI:NextColumn()
                                                                                GUI:SetColumnWidth(-1, 300)
                                                                                    GUI:Text()
                                                                                GUI:Columns(1)

                                                                                GUI:Columns(4, [[]], false)
                                                                                GUI:SetColumnWidth(-1, 60)
                                                                                    for kp, vp in pairs(DungeonCreator.CurrentFile.hasbuff[k].pos) do 
                                                                                            GUI:PushItemWidth(50)
                                                                                                DungeonCreator.CurrentFile.hasbuff[k].pos[kp].x = GUI:InputFloat([[##HasBuffMovePosX]] .. kp, DungeonCreator.CurrentFile.hasbuff[k].pos[kp].x)
                                                                                            GUI:PopItemWidth()
                                                                                        GUI:NextColumn()
                                                                                        GUI:SetColumnWidth(-1, 60)
                                                                                            GUI:PushItemWidth(50)
                                                                                                DungeonCreator.CurrentFile.hasbuff[k].pos[kp].y = GUI:InputFloat([[##HasBuffMovePosY]] .. kp, DungeonCreator.CurrentFile.hasbuff[k].pos[kp].y)
                                                                                            GUI:PopItemWidth()
                                                                                        GUI:NextColumn()
                                                                                        GUI:SetColumnWidth(-1, 60)
                                                                                            GUI:PushItemWidth(50)
                                                                                                DungeonCreator.CurrentFile.hasbuff[k].pos[kp].z = GUI:InputFloat([[##HasBuffMovePosZ]] .. kp, DungeonCreator.CurrentFile.hasbuff[k].pos[kp].z)
                                                                                            GUI:PopItemWidth()
                                                                                        GUI:NextColumn()
                                                                                        GUI:SetColumnWidth(-1, 300)

                                                                                            GUI:Text([[]])
                                                                                            GUI:SameLine()
                            
                                                                                            local HasBuffGetPos = GUI:Button([[Get Pos##HasBuffGetPos]], 120, 19)
                            
                                                                                            if GUI:IsItemClicked(HasBuffGetPos) then 
                                                                                                DungeonCreator.CurrentFile.hasbuff[k].pos[kp] = {
                                                                                                    x = Player.pos.x,
                                                                                                    y = Player.pos.x,
                                                                                                    z = Player.pos.x
                                                                                                }
                                                                                            end

                                                                                            GUI:SameLine()
                            
                                                                                            local RemoveHasBuffMove = GUI:Button([[Remove##RemoveHasBuffMove]], 120, 19)
                            
                                                                                            if GUI:IsItemClicked(RemoveHasBuffMove) then 
                                                                                                for kx, vx in pairs(DungeonCreator.CurrentFile.hasbuff[k].pos) do
                                                                                                    if kx == kp then 
                                                                                                        DungeonCreator.CurrentFile.hasbuff[k].pos[kx] = nil
                                                                                                    end
                                                                                                end
                                                                                            end
                            
                                                                                        GUI:NextColumn()
                                                                                    end
                                                                                    
                                                                                GUI:Columns(1)
                                                                            GUI:Unindent()
                                                                        end
                                                                    MashLib.UI.PopTitledChild()
                                                                end
                                                                GUI:NewLine()
                                                            end
                                                        end
                                                    end
                                                GUI:Unindent()
                                            MashLib.UI.PopTitledChild()

                                        GUI:Unindent()
                                    MashLib.UI.PopTitledChild()
                                    GUI:NewLine()
                                else
                                    DungeonCreator.CurrentFile.hasbuff = {}
                                end
                            end

    -- ------------------------- Avoidance ------------------------

                            if (GUI:CollapsingHeader(GetString("Advanced Avoidance"))) then
                                if DungeonCreator.CurrentFile.advancedavoid then
                                    MashLib.UI.BeginTitledChild([[AdvancedAvoidance]], [[Advanced Avoidance]], 715, 350, 0)
                                        GUI:Indent()

                                            GUI:BeginChild([[##AdvancedAvoidanceButtons]], 695, 30)

                                                local AddAdvancedAvoidance = GUI:Button([[Add##AddAdvancedAvoidance]], 150, 19)

                                                if GUI:IsItemClicked(AddAdvancedAvoidance) then 
                                                    DungeonCreator.CurrentFile.advancedavoid[#DungeonCreator.CurrentFile.advancedavoid+1] = {
                                                        creatordesc = [[]],
                                                        texteditor  = [[]]
                                                    }
                                                end

                                                GUI:SameLine()

                                                local ClearAdvancedAvoidance = GUI:Button([[Clear##ClearAdvancedAvoidance]], 50, 19)

                                                if GUI:IsItemClicked(ClearAdvancedAvoidance) then 
                                                    DungeonCreator.CurrentFile.advancedavoid = {}
                                                end

                                            GUI:EndChild()

                                            for k, v in pairs(DungeonCreator.CurrentFile.advancedavoid) do 

                                                if not DungeonCreator.CurrentFile.advancedavoid[k].creatordesc then
                                                    DungeonCreator.CurrentFile.advancedavoid[k].creatordesc = [[]]
                                                end
                                                
                                                if not DungeonCreator.CurrentFile.advancedavoid[k].texteditor then
                                                    if MashLib.Helpers.SizeOf(DungeonCreator.CurrentFile.advancedavoid[k]) > 0 then
                                                        DungeonCreator.CurrentFile.advancedavoid[k].texteditor = DungeonCreator.TableStringify(DungeonCreator.CurrentFile.advancedavoid[k])
                                                    else
                                                        DungeonCreator.CurrentFile.advancedavoid[k].texteditor = [[]]
                                                    end
                                                end

                                                local HeaderText = k .. (DungeonCreator.CurrentFile.advancedavoid[k].creatordesc ~= [[]] and [[ - ]] .. DungeonCreator.CurrentFile.advancedavoid[k].creatordesc or [[]])

                                                if not GUI:CollapsingHeader(HeaderText, k) then
                                                    GUI:BeginChild([[##AdvanceAvoidBody]] .. k, 687, 250, true)

    -- ------------------------- Description ------------------------

                                                        GUI:Text([[Temporary Comment ]])
                                                        
                                                        GUI:SameLine()
                                                        
                                                        DungeonCreator.CurrentFile.advancedavoid[k].creatordesc = GUI:InputText([[##CreatorAdvancedAvoidance]] .. k, DungeonCreator.CurrentFile.advancedavoid[k].creatordesc)
                                                        
                                                        GUI:SameLine()
                                                        
                                                        local DeleteAvoidance = GUI:Button([[Delete##DeleteAvoidance]], 50, 19)

                                                        if GUI:IsItemClicked(DeleteAvoidance) then 
                                                            DungeonCreator.CurrentFile.advancedavoid[k] = nil
                                                        end
                                                        
    -- ------------------------- Presets ------------------------

                                                        local AvoidancePresetLoS = GUI:Button([[LoS##AvoidancePresetLoS]], 50, 19)

                                                        if GUI:IsItemClicked(AvoidancePresetLOS) then 
                                                            DungeonCreator.CurrentFile.advancedavoid[k].texteditor = "{\n  castingid = 0,\n  type = \"los\",\n  args = {\n    entityone = 0,\n    entitytwo = 0,\n    dist = 0\n  },\n  desc = \"Description\"\n}"
                                                        end
                                                        
                                                        GUI:SameLine()

                                                        local AvoidancePresetSingleFixed = GUI:Button([[Single##AvoidancePresetSingleFixed]], 50, 19)

                                                        if GUI:IsItemClicked(AvoidancePresetSingleFixed) then 
                                                            DungeonCreator.CurrentFile.advancedavoid[k].texteditor = "{\n  castingid = 0,\n  desc = \"Description\",\n  pos = {\n    {\n      x = 0,\n      y = 0,\n      z = 0,\n    },\n  },\n  type = \"singlefixed\"\n}"
                                                        end
                                                        
                                                        GUI:SameLine()

                                                        local AvoidancePresetMultiFixed = GUI:Button([[Multi##AvoidancePresetMultiFixed]], 50, 19)

                                                        if GUI:IsItemClicked(AvoidancePresetMultiFixed) then 
                                                            DungeonCreator.CurrentFile.advancedavoid[k].texteditor = "{\n  castingid = 0,\n  type = \"multifixed\",\n  pos = {\n    [1] = {\n      x = 0,\n      y = 0,\n      z = 0\n    },\n    [2] = {\n      x = 0,\n      y = 0,\n      z = 0\n    },\n    [3] = {\n      x = 0,\n      y = 0,\n      z = 0\n    },\n    [4] = {\n      x = 0,\n      y = 0,\n      z = 0\n    }\n  }\n}"
                                                        end
                                                        
                                                        GUI:SameLine()

                                                        local AvoidancePresetSetDistance = GUI:Button([[Distance##AvoidancePresetSetDistance]], 65, 19)

                                                        if GUI:IsItemClicked(AvoidancePresetSetDistance) then 
                                                            DungeonCreator.CurrentFile.advancedavoid[k].texteditor = "{\n  castingid = 0,\n  type = \"setdistance\",\n  dist = 20,\n  desc = \"Description\"\n}"
                                                        end
                                                        
                                                        GUI:SameLine()

                                                        local AvoidancePresetFaceAway = GUI:Button([[Face away##AvoidancePresetFaceAway]], 70, 19)

                                                        if GUI:IsItemClicked(AvoidancePresetFaceAway) then 
                                                            DungeonCreator.CurrentFile.advancedavoid[k].texteditor = "{\n  castingid = 0,\n  type = \"faceaway\" \n}"
                                                        end
                                                        
                                                        GUI:SameLine()

                                                        local AvoidancePresetMoveBehind = GUI:Button([[Move Behind##AvoidancePresetMoveBehind]], 90, 19)

                                                        if GUI:IsItemClicked(AvoidancePresetMoveBehind) then 
                                                            DungeonCreator.CurrentFile.advancedavoid[k].texteditor = "{\n  castingid = 0,\n  desc = \"Description\",\n  type = \"movebehind\"\n}"
                                                        end
                                                        
                                                        GUI:SameLine()

                                                        local AvoidancePresetMoveFrontLeft = GUI:Button([[Move Front-Left##AvoidancePresetMoveFrontLeft]], 120, 19)

                                                        if GUI:IsItemClicked(AvoidancePresetMoveFrontLeft) then 
                                                            DungeonCreator.CurrentFile.advancedavoid[k].texteditor = "{\n  castingid = 0,\n  desc = \"Description\",\n  type = \"movefrontleftofenemy\" \n}"
                                                        end
                                                        
    -- ------------------------- Text Editor ------------------------

                                                        if DungeonCreator.CurrentFile.advancedavoid[k] then
                                                            DungeonCreator.CurrentFile.advancedavoid[k].texteditor = GUI:InputTextEditor([[Custom function##CustomFunction]] .. k, DungeonCreator.CurrentFile.advancedavoid[k].texteditor, 671, 187)
                                                        end

                                                    GUI:EndChild()
                                                end
                                            end
                                        GUI:Unindent()
                                    MashLib.UI.PopTitledChild()
                                    GUI:NewLine()
                                else
                                    DungeonCreator.CurrentFile.advancedavoid = {}
                                end
                            end
                            
    -- ------------------------- Overhead Markers ------------------------

                            if (GUI:CollapsingHeader(GetString("Overhead Markers"))) then
                                if DungeonCreator.CurrentFile.overheadmarkers then
                                    MashLib.UI.BeginTitledChild([[ProfileOverheadMarkers]], [[Overhead Markers]], 715, 310, 0)
                                        GUI:Indent()
                                            GUI:BeginChild([[##OverheadMarkersButtons]], 695, 30)

                                                local AddOverheadMarker = GUI:Button([[Add##AddOverheadMarker]], 50, 19)

                                                if GUI:IsItemClicked(AddOverheadMarker) then 
                                                    local index = #DungeonCreator.CurrentFile.overheadmarkers+1
                                                    DungeonCreator.CurrentFile.overheadmarkers[index] = {
                                                        id              = index, 
                                                        contentid       = 0,
                                                        desc            = "", 
                                                        type            = "move", 
                                                        detectwho       = "me", 
                                                        pos             = {},
                                                        timetoreturn    = 10
                                                    }
                                                end

                                                GUI:SameLine()

                                                local ClearOverheadMarkers = GUI:Button([[Clear##ClearOverheadMarkers]], 50, 19)

                                                if GUI:IsItemClicked(ClearOverheadMarkers) then 
                                                    DungeonCreator.CurrentFile.overheadmarkers = {}
                                                end

                                            GUI:EndChild()

                                                GUI:BeginChild([[##OverheadMarkerList]], 700, 250)
                                                    for k, v in pairs(DungeonCreator.CurrentFile.overheadmarkers) do 
                                                        local HeaderText = k .. (DungeonCreator.CurrentFile.overheadmarkers[k].desc ~= [[]] and [[ - ]] .. DungeonCreator.CurrentFile.overheadmarkers[k].desc or [[]])

                                                        if not GUI:CollapsingHeader(HeaderText, k) then
                                                            GUI:Indent()
                                                                GUI:Text("Content ID  ")

                                                                GUI:SameLine()

                                                                GUI:PushItemWidth(110)
                                                                    DungeonCreator.CurrentFile.overheadmarkers[k].contentid = GUI:InputText([[##OverHeadMarkerId]] .. k, DungeonCreator.CurrentFile.overheadmarkers[k].contentid and DungeonCreator.CurrentFile.overheadmarkers[k].contentid or k)
                                                                GUI:PopItemWidth()

                                                                GUI:SameLine()
                                                                
                                                                GUI:Text("   Type ")

                                                                GUI:SameLine()

                                                                GUI:PushItemWidth(110)
                                                                    DungeonCreator.CurrentFile.overheadmarkers[k].type = GUI:InputText([[##OverHeadMarkerType]] .. k, DungeonCreator.CurrentFile.overheadmarkers[k].type and DungeonCreator.CurrentFile.overheadmarkers[k].type or [[]])
                                                                GUI:PopItemWidth()

                                                                GUI:SameLine()
                                                                
                                                                GUI:Text("   Who? ")

                                                                GUI:SameLine()

                                                                GUI:PushItemWidth(110)
                                                                    DungeonCreator.CurrentFile.overheadmarkers[k].detectwho = GUI:InputText([[##OverHeadMarkerDetectWho]] .. k, DungeonCreator.CurrentFile.overheadmarkers[k].detectwho and DungeonCreator.CurrentFile.overheadmarkers[k].detectwho or [[]])
                                                                GUI:PopItemWidth()

                                                                if GUI:IsItemHovered(DungeonCreator.CurrentFile.overheadmarkers[k].detectwho) then
                                                                    GUI:BeginTooltip()
                                                                        GUI:Text([[me, any or all]])
                                                                    GUI:EndTooltip()
                                                                end

                                                                GUI:SameLine()
                                                                
                                                                GUI:Text("   Time ")

                                                                GUI:SameLine()

                                                                GUI:PushItemWidth(85)
                                                                    DungeonCreator.CurrentFile.overheadmarkers[k].timetoreturn = GUI:InputText([[##OverHeadMarkerTimeToReturn]] .. k, DungeonCreator.CurrentFile.overheadmarkers[k].timetoreturn and DungeonCreator.CurrentFile.overheadmarkers[k].timetoreturn or [[]])
                                                                GUI:PopItemWidth()

                                                                if GUI:IsItemHovered(DungeonCreator.CurrentFile.overheadmarkers[k].timetoreturn) then
                                                                    GUI:BeginTooltip()
                                                                        GUI:Text([[Seconds]])
                                                                    GUI:EndTooltip()
                                                                end

                                                                GUI:Text("Description ")

                                                                GUI:SameLine()

                                                                GUI:PushItemWidth(605)
                                                                    DungeonCreator.CurrentFile.overheadmarkers[k].desc = GUI:InputText([[##OverHeadMarkerDescription]] .. k, DungeonCreator.CurrentFile.overheadmarkers[k].desc and DungeonCreator.CurrentFile.overheadmarkers[k].desc or [[]])
                                                                GUI:PopItemWidth()

                                                                local AddPosOverheadMarker = GUI:Button([[Add position##AddPosOverheadMarker]] .. k, 150, 19)

                                                                if GUI:IsItemClicked(AddPosOverheadMarker) then 
                                                                    DungeonCreator.CurrentFile.overheadmarkers[k].pos[#DungeonCreator.CurrentFile.overheadmarkers[k].pos+1] = {
                                                                        x = 0,
                                                                        y = 0,
                                                                        z = 0   
                                                                    }
                                                                end

                                                                GUI:SameLine()

                                                                local ClearOverheadMarkerPos = GUI:Button([[Clear positions##ClearOverheadMarkerPos]] .. k, 150, 19)

                                                                if GUI:IsItemClicked(ClearOverheadMarkerPos) then 
                                                                    DungeonCreator.CurrentFile.overheadmarkers[k].pos = {}
                                                                end

                                                                GUI:SameLine()

                                                                local RemoveOverheadMarker = GUI:Button([[Remove##RemoveOverheadMarker]] .. k, 50, 19)

                                                                if GUI:IsItemClicked(RemoveOverheadMarker) then 
                                                                    DungeonCreator.CurrentFile.overheadmarkers[k] = nil
                                                                end

                                                                GUI:NewLine()

                                                                MashLib.UI.BeginTitledChild([[ProfileOverheadMarkerPositions]] .. k, [[Positions]], 680, 130, 0)
                                                                    GUI:Indent()
                                                                        GUI:Indent()
                                                                            GUI:Columns(4, [[]], false)
                                                                            GUI:SetColumnWidth(-1, 100)
                                                                                GUI:Text("X")
                                                                            GUI:NextColumn()
                                                                            GUI:SetColumnWidth(-1, 100)
                                                                                GUI:Text("Y")
                                                                            GUI:NextColumn()
                                                                            GUI:SetColumnWidth(-1, 300)
                                                                                GUI:Text("Z")
                                                                            GUI:Columns(1)
                                                                        GUI:Unindent()

                                                                        GUI:BeginChild([[##OverheadMarkerListSect]], 680, 80)
                                                                            if DungeonCreator.CurrentFile.overheadmarkers[k] and DungeonCreator.CurrentFile.overheadmarkers[k].pos then 
                                                                                for kp, vp in pairs(DungeonCreator.CurrentFile.overheadmarkers[k].pos) do
                                                                                    GUI:Columns(4, [[##OverheadMarkerListItem]] .. kp, true)
                                                                                    GUI:SetColumnWidth(-1, 100)
                                                                                        GUI:PushItemWidth(90)
                                                                                            DungeonCreator.CurrentFile.overheadmarkers[k].pos[kp].x = GUI:InputFloat([[##OverHeadMarkerPosX]] .. k, DungeonCreator.CurrentFile.overheadmarkers[k].pos[kp].x and DungeonCreator.CurrentFile.overheadmarkers[k].pos[kp].x or 0)
                                                                                        GUI:PopItemWidth()
                                                                                    GUI:NextColumn()
                                                                                    GUI:SetColumnWidth(-1, 100)
                                                                                        GUI:PushItemWidth(90)
                                                                                            DungeonCreator.CurrentFile.overheadmarkers[k].pos[kp].y = GUI:InputFloat([[##OverHeadMarkerPosY]] .. k, DungeonCreator.CurrentFile.overheadmarkers[k].pos[kp].y and DungeonCreator.CurrentFile.overheadmarkers[k].pos[kp].y or 0)
                                                                                        GUI:PopItemWidth()
                                                                                    GUI:NextColumn()
                                                                                    GUI:SetColumnWidth(-1, 100)
                                                                                        GUI:PushItemWidth(90)
                                                                                            DungeonCreator.CurrentFile.overheadmarkers[k].pos[kp].z = GUI:InputFloat([[##OverHeadMarkerPosZ]] .. k, DungeonCreator.CurrentFile.overheadmarkers[k].pos[kp].z and DungeonCreator.CurrentFile.overheadmarkers[k].pos[kp].z or 0)
                                                                                        GUI:PopItemWidth()
                                                                                    GUI:NextColumn()
                                                                                    GUI:SetColumnWidth(-1, 500)
                                                                                        local GetPosOverheadMarkerPos = GUI:Button([[Get Pos##GetPosOverheadMarkerPos]] .. kp, 150, 19)
                
                                                                                        if GUI:IsItemClicked(GetPosOverheadMarkerPos) then 
                                                                                            DungeonCreator.CurrentFile.overheadmarkers[k].pos[kp] = {
                                                                                                x = Player.pos.x,
                                                                                                y = Player.pos.y,
                                                                                                z = Player.pos.z,
                                                                                            }
                                                                                        end

                                                                                        GUI:SameLine()

                                                                                        local RemoveOverheadMarkerPos = GUI:Button([[Remove##RemoveOverheadMarkerPos]] .. kp, 150, 19)
                
                                                                                        if GUI:IsItemClicked(RemoveOverheadMarkerPos) then 
                                                                                            DungeonCreator.CurrentFile.overheadmarkers[k].pos[kp] = nil
                                                                                        end
                                                                                    GUI:Columns(1)
                                                                                end
                                                                            end
                                                                        GUI:EndChild()
                                                                    GUI:Unindent()

                                                                MashLib.UI.PopTitledChild()

                                                                GUI:NewLine()
                                                            GUI:Unindent()
                                                        end
                                                    end
                                                GUI:EndChild()
                                        GUI:Unindent()
                                    MashLib.UI.PopTitledChild()
                                    GUI:NewLine()
                                else
                                    DungeonCreator.CurrentFile.overheadmarkers = {}
                                end
                            end
                        GUI:EndChild()
                    end
                end
            else
                GUI:Text("KitanoiFuncs not installed.")
            end

        GUI:End()
        
        -- local flags = GUI.WindowFlags_NoResize
        -- GUI:SetNextWindowSize(400, 500, GUI.SetCond_Always)
        -- GUI:Begin([[CastHelper]], true, flags)
        --     MashLib.IRT.CastHelper()
        -- GUI:End()
    end
end

-- ------------------------- RegisterEventHandler ------------------------

RegisterEventHandler([[Module.Initalize]], DungeonCreator.Init, [[DungeonCreator.Init]])
RegisterEventHandler([[Gameloop.Draw]], DungeonCreator.MainWindow, [[DungeonCreator.MainWindow]])
