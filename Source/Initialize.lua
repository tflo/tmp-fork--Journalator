local function SetupMonitors()
  CreateFrame("Frame", "JNRMailMonitor", nil, "JournalatorMailMonitorTemplate")
  CreateFrame("Frame", "JNRPostingMonitor", nil, "JournalatorPostingMonitorTemplate")
  CreateFrame("Frame", "JNRVendorMonitor", nil, "JournalatorVendorMonitorTemplate")
end

function Journalator.Initialize()
  Journalator.Config.InitializeData()

  Journalator.Archiving.Initialize()

  Journalator.State.CurrentVersion = GetAddOnMetadata("Journalator", "Version")

  SetupMonitors()

  Journalator.SlashCmd.Initialize()

  local faction = UnitFactionGroup("player")
  Journalator.State.Source = {
    realm = GetRealmName(),
    character = GetUnitName("player"),
    faction = faction,
  }

  Journalator.Statistics.InitializeCache()

  Journalator.MinimapIcon.Initialize()

  Journalator.ToggleView = function()
    if JNRView == nil then
      CreateFrame("Frame", "JNRView", UIParent, "JournalatorDisplayTemplate")
    end

    JNRView:SetShown(not JNRView:IsShown())
  end
end
