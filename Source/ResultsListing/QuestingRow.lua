JournalatorLogViewQuestingRowMixin = CreateFromMixins(AuctionatorResultsRowTemplateMixin)

function JournalatorLogViewQuestingRowMixin:ShowTooltip()
  local tooltip  = GameTooltip
  tooltip:SetOwner(self, "ANCHOR_RIGHT")
  self.UpdateTooltip = self.OnEnter

  if string.match(self.rowData.itemLink, "battlepet") then
    BattlePetToolTip_ShowLink(self.rowData.itemLink)
    tooltip = BattlePetTooltip
  else
    GameTooltip:SetHyperlink(self.rowData.itemLink)
  end

  if #self.rowData.currencies > 0 or #self.rowData.items > 0 then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(JOURNALATOR_L_ADDITIONAL_COSTS_COLON)

    for _, item in ipairs(self.rowData.items) do
      local name, link = GetItemInfo(item.itemLink)
      GameTooltip:AddLine(Journalator.Utilities.GetItemText(item.itemLink, item.quantity))
    end
    for _, item in ipairs(self.rowData.currencies) do
      GameTooltip:AddLine(Journalator.Utilities.GetCurrencyText(item.currencyID, item.quantity))
    end
  end

  GameTooltip:Show()
end

-- Used to prevent tooltip triggering too late and interfering with another
-- tooltip
function JournalatorLogViewQuestingRowMixin:CancelContinuable()
  if self.continuableContainer then
    self.continuableContainer:Cancel()
    self.continuableContainer = nil
  end
end

function JournalatorLogViewQuestingRowMixin:OnHide()
  self:CancelContinuable()
end

function JournalatorLogViewQuestingRowMixin:OnEnter()
  AuctionatorResultsRowTemplateMixin.OnEnter(self)

  self:CancelContinuable()

  self.continuableContainer = ContinuableContainer:Create()

  -- Cache item data for all reagents ready for display in tooltip
  if self.rowData.items then
    for _, item in ipairs(self.rowData.items) do
      self.continuableContainer:AddContinuable(Item:CreateFromItemLink(item.itemLink))
    end
  end

  self.continuableContainer:ContinueOnLoad(function()
    self.continuableContainer = nil
    self:ShowTooltip()
  end)
end

function JournalatorLogViewQuestingRowMixin:OnLeave()
  AuctionatorResultsRowTemplateMixin.OnLeave(self)
  self.UpdateTooltip = nil
  self:CancelContinuable()
  GameTooltip:Hide()
end

function JournalatorLogViewQuestingRowMixin:OnClick(button)
  if button == "LeftButton" then
    if IsModifiedClick("CHATLINK") then
      if self.rowData.itemLink ~= nil then
        ChatEdit_InsertLink(self.rowData.itemLink)
      end
    else
      Auctionator.EventBus
        :RegisterSource(self, "JournalatorLogViewQuestingRowMixin")
        :Fire(self, Journalator.Events.RowClicked, self.rowData)
        :UnregisterSource(self)
    end
  end
end
