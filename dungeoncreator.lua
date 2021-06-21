
-- ------------------------- Core ------------------------

DungeonCreator = {}
local self = DungeonCreator

-- ------------------------- Info ------------------------

self.Info = {
    Author      = "Mash#3428",
    AddonName   = "DungeonCreator",
    ClassName   = "DungeonCreator",
	Version     = 101,
	StartDate   = "21-06-2021",
	LastUpdate  = "21-06-2021",
    Description = "DungeonCreator",
    ChangeLog = {
        [100] = { Version = 100, Description = "Starting development" },
        [101] = { Version = 101, Description = "Reparsing file on save to format numeric values." },
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

self.ProfileList = {}
self.ProfileLoaded = {}
self.CurrentFile = {}
self.CreatingProfile = false

-- ------------------------- Parse File to Framework ------------------------

function DungeonCreator.FormatFileToFramework(File)
    local NewFile = {}

-- ------------------------- Settings ------------------------

    NewFile.dutyid                  = tonumber(File.dutyid)
    NewFile.queuetype               = tonumber(File.queuetype)
    NewFile.enemytargetdistance     = tonumber(File.enemytargetdistance)
    NewFile.bossids                 = File.bossids
    NewFile.mesh                    = File.mesh
    NewFile.name                    = File.name
    NewFile.interacts               = {}
    NewFile.objectivedestinations   = {}
    NewFile.prioritytarget          = {}

-- ------------------------- Interactions ------------------------

    for k, v in pairs(File.interacts) do 
        NewFile.interacts[#NewFile.interacts+1] = {
            contentid   = tonumber(v.contentid),
            priority    = tonumber(v.priority),
            type        = v.type,
        }
    end

-- ------------------------- ObjectiveDestinations ------------------------

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

-- ------------------------- PriorityTargets ------------------------

    for k, v in pairs(File.prioritytarget) do 
        NewFile.prioritytarget[#NewFile.prioritytarget+1] = {
            contentid   = tonumber(v.contentid),
            priority    = tonumber(v.priority),
            type        = v.type
        }
    end

    return NewFile
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
        self.GUI.Visible, self.GUI.Open = GUI:Begin("DungeonCreator", self.GUI.Open, flags)
        
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
                    GUI:SetColumnWidth(-1, 200)

    -- ------------------------- Save Profile ------------------------

                        local SaveProfile = GUI:Button([[Save##SaveProfile]], 50, 19)

                        if GUI:IsItemClicked(SaveProfile) then 
                            local FilePath = DungeonCreator.ProfilePath .. DungeonCreator.ProfileList[DungeonCreator.GUI.Combos.Profile]

                            if FileExists(FilePath) then
                                local File = DungeonCreator.FormatFileToFramework(DungeonCreator.CurrentFile)
                                FileSave(FilePath, File)
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
                                    enemytargetdistance = 15,
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

    -- ------------------------- Profile Body ------------------------

                    GUI:BeginChild("##Body", 745, 710, true)
                        if not DungeonCreator.ProfileList[DungeonCreator.GUI.Combos.Profile] then
                            GUI:Text("Select a profile above <3")
                        else
                            local FilePath = DungeonCreator.ProfilePath .. DungeonCreator.ProfileList[DungeonCreator.GUI.Combos.Profile]

                            if not DungeonCreator.ProfileLoaded[DungeonCreator.GUI.Combos.Profile] then
                                DungeonCreator.ProfileLoaded[DungeonCreator.GUI.Combos.Profile] = FileLoad(FilePath)
                            end

                            DungeonCreator.CurrentFile = DungeonCreator.ProfileLoaded[DungeonCreator.GUI.Combos.Profile]
                            
    -- ------------------------- Settings ------------------------

                            MashLib.UI.BeginTitledChild([[ProfileSettings]], [[Settings]], 715, 160, 0)
                                GUI:Indent()
                                    GUI:Columns(2, [[]], false)
                                    GUI:SetColumnWidth(-1, 200)
                                        GUI:Text([[Profile Name]])
                                    GUI:NextColumn()
                                    GUI:SetColumnWidth(-1, 600)
                                        GUI:PushItemWidth(500)
                                            GUI:InputText([[##FileName]], DungeonCreator.ProfileList[DungeonCreator.GUI.Combos.Profile], (GUI.InputTextFlags_ReadOnly))
                                        GUI:PopItemWidth()
                                    GUI:NextColumn()
                                        GUI:Text([[Dungeon Name]])
                                    GUI:NextColumn()
                                        GUI:PushItemWidth(500)
                                            DungeonCreator.CurrentFile.name = GUI:InputText([[##FileDungeonName]], DungeonCreator.CurrentFile.name)
                                        GUI:PopItemWidth()
                                    GUI:NextColumn()
                                        GUI:Text([[Duty ID]])
                                    GUI:NextColumn()
                                        GUI:PushItemWidth(50)
                                            DungeonCreator.CurrentFile.dutyid = GUI:InputText([[##FileDutyId]], DungeonCreator.CurrentFile.dutyid)
                                        GUI:PopItemWidth()

                                        GUI:SameLine()

                                        local SetCurrentMapId = GUI:Button([[Get Current##SetCurrentMapId]], 150, 19)

                                        if GUI:IsItemClicked(SetCurrentMapId) then 
                                            DungeonCreator.CurrentFile.dutyid = Player.localmapid
                                        end
                                    GUI:NextColumn()
                                        GUI:Text([[Queue Type]])
                                    GUI:NextColumn()
                                        local QueueTypes = {
                                            [1] = "Synced",
                                            [2] = "Unsynced"
                                        }
                                        
                                        GUI:PushItemWidth(100)
                                            DungeonCreator.CurrentFile.queuetype, _ = GUI:Combo([[##FileQueueType]], DungeonCreator.CurrentFile.queuetype, QueueTypes)
                                        GUI:PopItemWidth()
                                    GUI:NextColumn()
                                        GUI:Text([[Mesh]])
                                    GUI:NextColumn()
                                        GUI:PushItemWidth(500)
                                            DungeonCreator.CurrentFile.mesh = GUI:InputText([[##FileMesh]], DungeonCreator.CurrentFile.mesh)
                                        GUI:PopItemWidth()
                                    GUI:NextColumn()
                                        GUI:Text([[Enemy Target Distance]])
                                    GUI:NextColumn()
                                        GUI:PushItemWidth(50)
                                            DungeonCreator.CurrentFile.enemytargetdistance = GUI:InputText([[##FileEnemyTargetDistance]], DungeonCreator.CurrentFile.enemytargetdistance)
                                        GUI:PopItemWidth()
                                    GUI:Columns(1)
                                GUI:Unindent()
                            MashLib.UI.PopTitledChild()
                            
                            GUI:NewLine()
                            
    -- ------------------------- Objectives ------------------------

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
                                                        x = MashLib.Helpers.ToFixed(Player.pos.x, 2),
                                                        y = MashLib.Helpers.ToFixed(Player.pos.y, 2),
                                                        z = MashLib.Helpers.ToFixed(Player.pos.z, 2)
                                                    }
                                                }
                                            end

                                            GUI:SameLine()

                                            local ClearObjectives = GUI:Button([[Clear##ClearObjectives]], 50, 19)

                                            if GUI:IsItemClicked(ClearObjectives) then 
                                                DungeonCreator.CurrentFile.objectivedestinations = {}
                                            end

                                        GUI:EndChild()

                                        GUI:Columns(5, [[]], false)
                                        GUI:SetColumnWidth(-1, 100)
                                            GUI:Text([[Order]])
                                        GUI:NextColumn()
                                        GUI:SetColumnWidth(-1, 100)
                                            GUI:Text([[PosX]])
                                        GUI:NextColumn()
                                        GUI:SetColumnWidth(-1, 100)
                                            GUI:Text([[PosY]])
                                        GUI:NextColumn()
                                        GUI:SetColumnWidth(-1, 100)
                                            GUI:Text([[PosZ]])
                                        GUI:NextColumn()
                                        GUI:SetColumnWidth(-1, 200)
                                            GUI:Text()
                                        GUI:Columns(1)
                                        
                                        GUI:BeginChild([[##ObjectiveList]], 695, 120)
                                            GUI:Columns(5, [[]], false)
                                            GUI:SetColumnWidth(-1, 100)
                                                if MashLib.Helpers.SizeOf(DungeonCreator.CurrentFile.objectivedestinations) > 0 then
                                                    for k, v in pairs(DungeonCreator.CurrentFile.objectivedestinations) do 
                                                            DungeonCreator.CurrentFile.objectivedestinations[k].objective = GUI:InputText([[##ObjectiveItem]] .. k, DungeonCreator.CurrentFile.objectivedestinations[k].objective)
                                                        GUI:NextColumn()
                                                        GUI:SetColumnWidth(-1, 100)
                                                            DungeonCreator.CurrentFile.objectivedestinations[k].pos.x = GUI:InputText([[##ObjectivePosX]] .. k, DungeonCreator.CurrentFile.objectivedestinations[k].pos.x)
                                                        GUI:NextColumn()
                                                        GUI:SetColumnWidth(-1, 100)
                                                            DungeonCreator.CurrentFile.objectivedestinations[k].pos.y = GUI:InputText([[##ObjectivePosY]] .. k, DungeonCreator.CurrentFile.objectivedestinations[k].pos.y)
                                                        GUI:NextColumn()
                                                        GUI:SetColumnWidth(-1, 100)
                                                            DungeonCreator.CurrentFile.objectivedestinations[k].pos.z = GUI:InputText([[##ObjectivePosZ]] .. k, DungeonCreator.CurrentFile.objectivedestinations[k].pos.z)
                                                        GUI:NextColumn()
                                                        GUI:SetColumnWidth(-1, 300)

                                                            local ObjectiveGetPos = GUI:Button([[Get current pos##ObjectiveGetPos]], 150, 19)
                        
                                                            if GUI:IsItemClicked(ObjectiveGetPos) then 
                                                                DungeonCreator.CurrentFile.objectivedestinations[k].pos = {
                                                                    x = MashLib.Helpers.ToFixed(Player.pos.x, 2),
                                                                    y = MashLib.Helpers.ToFixed(Player.pos.y, 2),
                                                                    z = MashLib.Helpers.ToFixed(Player.pos.z, 2)
                                                                }
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
                            end
                            
    -- ------------------------- Boss ID ------------------------

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
                            end
                            
    -- ------------------------- Priority Target ------------------------

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
                            end
                            
    -- ------------------------- Interactions ------------------------

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
                                                    type = "loot"
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
                                                        type = "loot"
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
                                                        DungeonCreator.CurrentFile.interacts[k].contentid = GUI:InputText([[##InteractContentId]] .. k, DungeonCreator.CurrentFile.interacts[k].contentid)
                                                    GUI:NextColumn()
                                                    GUI:SetColumnWidth(-1, 100)
                                                        DungeonCreator.CurrentFile.interacts[k].priority = GUI:InputText([[##InteractPriority]] .. k, DungeonCreator.CurrentFile.interacts[k].priority)
                                                    GUI:NextColumn()
                                                    GUI:SetColumnWidth(-1, 300)
                                                        GUI:PushItemWidth(290)
                                                            DungeonCreator.CurrentFile.interacts[k].type = GUI:InputText([[##InteractType]] .. k, DungeonCreator.CurrentFile.interacts[k].type)
                                                        GUI:PopItemWidth()
                                                    GUI:NextColumn()
                                                    GUI:SetColumnWidth(-1, 200)
                                    
                                                        local GetInteraction = GUI:Button([[Get target##GetInteraction]], 100, 19)

                                                        if GUI:IsItemClicked(RemoveInteraction) then 
                                                            DungeonCreator.CurrentFile.interacts[k].contentId = Player:GetTarget().contentId
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
                            end

    -- ------------------------- Buffs ------------------------

                            -- if DungeonCreator.CurrentFile.hasbuff then
                            --     MashLib.UI.BeginTitledChild([[ProfileHasBuffs]], [[Buffs]], 715, 200, 0)
                            --         GUI:Indent()

                            --             GUI:BeginChild([[##HasBuffsButtons]], 695, 30)

                            --                 local AddHasBuff = GUI:Button([[Add##AddHasBuff]], 50, 19)

                            --                 if GUI:IsItemClicked(AddHasBuff) then 

                            --                 end

                            --                 GUI:SameLine()

                            --                 local ClearHasBuffs = GUI:Button([[Clear##ClearHasBuffs]], 50, 19)

                            --                 if GUI:IsItemClicked(ClearHasBuffs) then 

                            --                 end

                            --             GUI:EndChild()

                            --             GUI:Columns(4, [[]], false)
                            --             GUI:SetColumnWidth(-1, 100)
                            --                 GUI:Text([[ID]])
                            --             GUI:NextColumn()
                            --             GUI:SetColumnWidth(-1, 100)
                            --                 GUI:Text([[Type]])
                            --             GUI:NextColumn()
                            --             GUI:SetColumnWidth(-1, 300)
                            --                 GUI:Text([[Type]])
                            --             GUI:NextColumn()
                            --             GUI:SetColumnWidth(-1, 100)
                            --                 GUI:Text()
                            --             GUI:Columns(1)

                            --             GUI:BeginChild([[##InteractionList]], 695, 120)
                            --                 GUI:Columns(4, [[]], false)
                            --                 GUI:SetColumnWidth(-1, 100)
                            --                     for k, v in ipairs(DungeonCreator.CurrentFile.prioritytarget) do 
                            --                             DungeonCreator.CurrentFile.interacts[k].contentid = GUI:InputText([[##InteractContentId]] .. k, DungeonCreator.CurrentFile.interacts[k].contentid)
                            --                         GUI:NextColumn()
                            --                         GUI:SetColumnWidth(-1, 100)
                            --                             DungeonCreator.CurrentFile.interacts[k].priority = GUI:InputText([[##InteractPriority]] .. k, DungeonCreator.CurrentFile.interacts[k].priority)
                            --                         GUI:NextColumn()
                            --                         GUI:SetColumnWidth(-1, 300)
                            --                             GUI:PushItemWidth(290)
                            --                                 DungeonCreator.CurrentFile.interacts[k].type = GUI:InputText([[##InteractType]] .. k, DungeonCreator.CurrentFile.interacts[k].type)
                            --                             GUI:PopItemWidth()
                            --                         GUI:NextColumn()
                            --                         GUI:SetColumnWidth(-1, 200)
                                    
                            --                             local AddInteraction = GUI:Button([[Add##AddInteraction]], 50, 19)

                            --                             if GUI:IsItemClicked(AddInteraction) then 

                            --                             end

                            --                             GUI:SameLine()

                            --                             local ClearInteractions = GUI:Button([[Clear##ClearInteractions]], 50, 19)

                            --                             if GUI:IsItemClicked(ClearInteractions) then 

                            --                             end

                            --                         GUI:NextColumn()
                            --                     end
                            --                 GUI:Columns(1)
                            --             GUI:EndChild()

                            --         GUI:Unindent()
                            --     MashLib.UI.PopTitledChild()
                            -- end

    -- ------------------------- Avoidance ------------------------

                            -- if DungeonCreator.CurrentFile.advancedavoid then
                            --     MashLib.UI.BeginTitledChild([[ProfileInteractions]], [[Interactions]], 715, 200, 0)
                            --         GUI:Indent()

                            --             GUI:BeginChild([[##InteractionsButtons]], 695, 30)
                            --                 local AddInteraction = GUI:Button([[Add##AddInteraction]], 50, 19)

                            --                 if GUI:IsItemClicked(AddInteraction) then 

                            --                 end

                            --                 GUI:SameLine()

                            --                 local ClearInteractions = GUI:Button([[Clear##ClearInteractions]], 50, 19)

                            --                 if GUI:IsItemClicked(ClearInteractions) then 

                            --                 end
                            --             GUI:EndChild()

                            --             GUI:Columns(4, [[]], false)
                            --             GUI:SetColumnWidth(-1, 100)
                            --                 GUI:Text([[ContentId]])
                            --             GUI:NextColumn()
                            --             GUI:SetColumnWidth(-1, 100)
                            --                 GUI:Text([[Priority]])
                            --             GUI:NextColumn()
                            --             GUI:SetColumnWidth(-1, 300)
                            --                 GUI:Text([[Type]])
                            --             GUI:NextColumn()
                            --             GUI:SetColumnWidth(-1, 100)
                            --                 GUI:Text()
                            --             GUI:Columns(1)

                            --             GUI:BeginChild([[##InteractionList]], 695, 120)
                            --                 GUI:Columns(4, [[]], false)
                            --                 GUI:SetColumnWidth(-1, 100)
                            --                     for k, v in ipairs(DungeonCreator.CurrentFile.prioritytarget) do 
                            --                             DungeonCreator.CurrentFile.interacts[k].contentid = GUI:InputText([[##InteractContentId]] .. k, DungeonCreator.CurrentFile.interacts[k].contentid)
                            --                         GUI:NextColumn()
                            --                         GUI:SetColumnWidth(-1, 100)
                            --                             DungeonCreator.CurrentFile.interacts[k].priority = GUI:InputText([[##InteractPriority]] .. k, DungeonCreator.CurrentFile.interacts[k].priority)
                            --                         GUI:NextColumn()
                            --                         GUI:SetColumnWidth(-1, 300)
                            --                             GUI:PushItemWidth(290)
                            --                                 DungeonCreator.CurrentFile.interacts[k].type = GUI:InputText([[##InteractType]] .. k, DungeonCreator.CurrentFile.interacts[k].type)
                            --                             GUI:PopItemWidth()
                            --                         GUI:NextColumn()
                            --                         GUI:SetColumnWidth(-1, 200)
                                    
                            --                             local AddInteraction = GUI:Button([[Add##AddInteraction]], 50, 19)

                            --                             if GUI:IsItemClicked(AddInteraction) then 

                            --                             end

                            --                             GUI:SameLine()

                            --                             local ClearInteractions = GUI:Button([[Clear##ClearInteractions]], 50, 19)

                            --                             if GUI:IsItemClicked(ClearInteractions) then 

                            --                             end

                            --                         GUI:NextColumn()
                            --                     end
                            --                 GUI:Columns(1)
                            --             GUI:EndChild()

                            --         GUI:Unindent()
                            --     MashLib.UI.PopTitledChild()
                            -- end

    -- ------------------------- Overhead Markers ------------------------

                            -- if DungeonCreator.CurrentFile.overheadmarkers then
                            --     MashLib.UI.BeginTitledChild([[ProfileInteractions]], [[Interactions]], 715, 200, 0)
                            --         GUI:Indent()

                            --             GUI:BeginChild([[##InteractionsButtons]], 695, 30)
                            --                 local AddInteraction = GUI:Button([[Add##AddInteraction]], 50, 19)

                            --                 if GUI:IsItemClicked(AddInteraction) then 

                            --                 end

                            --                 GUI:SameLine()

                            --                 local ClearInteractions = GUI:Button([[Clear##ClearInteractions]], 50, 19)

                            --                 if GUI:IsItemClicked(ClearInteractions) then 

                            --                 end
                            --             GUI:EndChild()

                            --             GUI:Columns(4, [[]], false)
                            --             GUI:SetColumnWidth(-1, 100)
                            --                 GUI:Text([[ContentId]])
                            --             GUI:NextColumn()
                            --             GUI:SetColumnWidth(-1, 100)
                            --                 GUI:Text([[Priority]])
                            --             GUI:NextColumn()
                            --             GUI:SetColumnWidth(-1, 300)
                            --                 GUI:Text([[Type]])
                            --             GUI:NextColumn()
                            --             GUI:SetColumnWidth(-1, 100)
                            --                 GUI:Text()
                            --             GUI:Columns(1)

                            --             GUI:BeginChild([[##InteractionList]], 695, 120)
                            --                 GUI:Columns(4, [[]], false)
                            --                 GUI:SetColumnWidth(-1, 100)
                            --                     for k, v in ipairs(DungeonCreator.CurrentFile.prioritytarget) do 
                            --                             DungeonCreator.CurrentFile.interacts[k].contentid = GUI:InputText([[##InteractContentId]] .. k, DungeonCreator.CurrentFile.interacts[k].contentid)
                            --                         GUI:NextColumn()
                            --                         GUI:SetColumnWidth(-1, 100)
                            --                             DungeonCreator.CurrentFile.interacts[k].priority = GUI:InputText([[##InteractPriority]] .. k, DungeonCreator.CurrentFile.interacts[k].priority)
                            --                         GUI:NextColumn()
                            --                         GUI:SetColumnWidth(-1, 300)
                            --                             GUI:PushItemWidth(290)
                            --                                 DungeonCreator.CurrentFile.interacts[k].type = GUI:InputText([[##InteractType]] .. k, DungeonCreator.CurrentFile.interacts[k].type)
                            --                             GUI:PopItemWidth()
                            --                         GUI:NextColumn()
                            --                         GUI:SetColumnWidth(-1, 200)
                                    
                            --                             local AddInteraction = GUI:Button([[Add##AddInteraction]], 50, 19)

                            --                             if GUI:IsItemClicked(AddInteraction) then 

                            --                             end

                            --                             GUI:SameLine()

                            --                             local ClearInteractions = GUI:Button([[Clear##ClearInteractions]], 50, 19)

                            --                             if GUI:IsItemClicked(ClearInteractions) then 

                            --                             end

                            --                         GUI:NextColumn()
                            --                     end
                            --                 GUI:Columns(1)
                            --             GUI:EndChild()

                            --         GUI:Unindent()
                            --     MashLib.UI.PopTitledChild()
                            -- end
                        end
                    GUI:EndChild()
                end

            else
                GUI:Text("KitanoiFuncs not installed.")
            end

        GUI:End()
    end
end

-- ------------------------- RegisterEventHandler ------------------------

RegisterEventHandler([[Module.Initalize]], DungeonCreator.Init, [[DungeonCreator.Init]])
RegisterEventHandler([[Gameloop.Draw]], DungeonCreator.MainWindow, [[DungeonCreator.MainWindow]])