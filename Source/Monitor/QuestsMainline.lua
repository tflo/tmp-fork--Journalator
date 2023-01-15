JournalatorQuestsMainlineMonitorMixin = {}

local function GetKeyByID(questID)
  return "quests-" .. questID
end

function JournalatorQuestsMainlineMonitorMixin:OnLoad()
  self.pendingQuests = {}

  self.rewardTimers = {} -- Wait QUEST_LOOT_DELAY seconds to make sure all the rewards are obtained

  self.rewardItems = {}
  self.rewardCurrencies = {}

  hooksecurefunc("GetQuestReward", function(choice)
    local questID = GetQuestID()
    self.reputationMonitor:SetReportKey(GetKeyByID(questID))
    Journalator.Debug.Message("get quest reward hook", questID, choice)
  end)

  FrameUtil.RegisterFrameForEvents(self, {
    "QUEST_TURNED_IN",
    "QUEST_REMOVED",
    "QUEST_LOOT_RECEIVED",
    "QUEST_CURRENCY_LOOT_RECEIVED",
    "QUEST_DATA_LOAD_RESULT",
    "PLAYER_LEAVING_WORLD",
  })
end

function JournalatorQuestsMainlineMonitorMixin:SetReputationMonitor(monitor)
  self.reputationMonitor = monitor
end

function JournalatorQuestsMainlineMonitorMixin:OnEvent(eventName, ...)
  if eventName == "QUEST_TURNED_IN" then
    local questID, experience, money = ...
    Journalator.Debug.Message("quest turned in", questID, experience, money)
    local questInfo = {
      state = "turned in",
      rewardItems = nil,
      rewardCurrencies = nil,
      questID = questID,
      questName = nil,
      experience = experience,
      rewardMoney = money,
      time = time(),
      source = Journalator.State.Source,
    }
    self.pendingQuests[questID] = questInfo

    self.rewardTimers[questID] = C_Timer.NewTimer(Journalator.Constants.QUEST_REWARD_DELAY, function()
      Journalator.Debug.Message("quest reward timer finished", questID)
      self.rewardTimers[questID] = nil
      self:CheckForCompleted()
    end)

    C_QuestLog.RequestLoadQuestByID(questInfo.questID)

  elseif eventName == "QUEST_DATA_LOAD_RESULT" then
    local questID, success = ...
    local questInfo = self.pendingQuests[questID]
    if questInfo and questInfo.questName == nil then
      if success then
        self.pendingQuests[questID].questName = QuestUtils_GetQuestName(questID)
        self:CheckForCompleted()
      else
        self:RemoveQuest(questID)
      end
    end

  elseif eventName == "QUEST_LOOT_RECEIVED" then
    local questID, itemLink, quantity = ...
    self.rewardItems[questID] = self.rewardItems[questID] or {}

    Journalator.Debug.Message("quest loot recieved", questID, itemLink, quantity)
    table.insert(self.rewardItems[questID], {
      itemLink = itemLink,
      quantity = quantity,
    })

  elseif eventName == "QUEST_CURRENCY_LOOT_RECEIVED" then
    local questID, currencyID, quantity = ...
    self.rewardCurrencies[questID] = self.rewardCurrencies[questID] or {}

    Journalator.Debug.Message("quest currency loot recieved", questID, currencyID, quantity)
    table.insert(self.rewardCurrencies[questID], {
      currencyID = currencyID,
      quantity = quantity,
    })

  elseif eventName == "PLAYER_LEAVING_WORLD" then
    for questID in pairs(self.pendingQuests) do
      if self.rewardTimers[questID] then
        self.rewardTimers[questID]:Cancel()
        self.rewardTimers[questID] = nil
      end
    end
    self:CheckForCompleted()
  end
end

function JournalatorQuestsMainlineMonitorMixin:IsWorldQuest(questID)
  return C_QuestLog and C_QuestLog.IsWorldQuest and (C_QuestLog.IsWorldQuest(questID) or C_QuestLog.IsQuestTask(questID))
end

function JournalatorQuestsMainlineMonitorMixin:HasAnyRewards(questInfo)
  return #questInfo.rewardItems > 0 or #questInfo.rewardCurrencies > 0 or questInfo.experience > 0 or questInfo.rewardMoney > 0
end

function JournalatorQuestsMainlineMonitorMixin:RemoveQuest(questID)
  Journalator.Debug.Message("removed jnr", questID)
  self.pendingQuests[questID] = nil

  self.rewardItems[questID] = nil
  self.rewardCurrencies[questID] = nil
  if self.rewardTimers[questID] then
    self.rewardTimers[questID]:Cancel()
    self.rewardTimers[questID] = nil
  end

  self.reputationMonitor:ClearByKey(GetKeyByID(questID))
end

function JournalatorQuestsMainlineMonitorMixin:CheckForCompleted()
  for questID, questInfo in pairs(self.pendingQuests) do
    local currentName = self.pendingQuests[questID].questName
    if currentName ~= nil and self.rewardTimers[questID] == nil then
      local items = self.rewardItems[questID] or {}
      local currencies = self.rewardCurrencies[questID] or {}
      local reputationChanges = self.reputationMonitor:GetByKey(GetKeyByID(questID))
      Journalator.Debug.Message("quest accept", questID, #items + #currencies, #reputationChanges)
      questInfo.reputationChanges = reputationChanges
      questInfo.rewardItems = items
      questInfo.rewardCurrencies = currencies
      -- Don't record any empty quests
      if self:HasAnyRewards(questInfo) then
        Journalator.AddToLogs({Questing = {questInfo}})
      end
      self:RemoveQuest(questID)
    else
      Journalator.Debug.Message("quest reject not ready", questID, currentName ~= nil, not self.rewardTimers[questID])
    end
  end
end
