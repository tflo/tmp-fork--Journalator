function Journalator.Initialize()
  JOURNALATOR_LOGS = JOURNALATOR_LOGS or {
    Version = 1,
    Invoices = {},
    Posting = {},
    Failures = {}
  }
  JOURNALATOR_LOGS.Failures = JOURNALATOR_LOGS.Failures or {}
  if JOURNALATOR_LOGS.Version ~= 1 then
    error("Unexpected log version")
  end
  Journalator.CurrentVersion = GetAddOnMetadata("Journalator", "Version")

  CreateFrame("Frame", "JNRMailMonitor", nil, "JournalatorMailMonitorTemplate")
  CreateFrame("Frame", "JNRPostingMonitor", nil, "JournalatorPostingMonitorTemplate")
  CreateFrame("Frame", "JNRView", UIParent, "JournalatorDisplayTemplate")

  Journalator.SlashCmd.Initialize()
  Journalator.Source = {
    realm = GetRealmName(),
    character = GetUnitName("player"),
  }
end
