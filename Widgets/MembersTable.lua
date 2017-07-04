--
-- GuildTaxes - keep your guild bank full
-- Author: Неогик@Галакронд
--

local Type, Version = "GuildTaxesMembersTable", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local _G = _G
local CreateFrame, UIParent = CreateFrame, UIParent


--------------------------------------------------------------------------------
-- Methods
--------------------------------------------------------------------------------
local function CreateRow(self, parent)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(self.rowHeight)
	row.cols = {}
	for i, r in pairs(self.columns) do
		local col = CreateFrame("Button", nil, row)
		col:SetHeight(self.rowHeight)
		local text = col:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		text:SetAllPoints()
		--text:SetJustifyV("CENTER")
		text:SetJustifyH("LEFT")
		text:SetText("-")
		col.textString = text
		row.cols[#row.cols + 1] = col
	end
	return row
end

local function LayoutCols(self, row)
	local width = row:GetWidth()
	local height = row:GetHeight()

	local total = 0
	for i=1, #row.cols, 1 do
		total = total + self.columns[i][3]
	end
	local left = 0
	for i, col in pairs(row.cols) do
		local width = (self.columns[i][3] / total) * width
		col:SetWidth(width)
		col:SetHeight(height)
		col:SetPoint("TOPLEFT", left, 0)
		left = left + width
	end
end

local function Layout(self)
	local fullWidth = self.frame:GetWidth()
	local fullHeight = self.frame:GetHeight()

	self.headerLine:ClearAllPoints()
	self.headerLine:SetPoint("TOPLEFT", 0, 0)
	self.headerLine:SetPoint("TOPRIGHT", -(self.scrollWidth + self.scrollSpace), 0)
	LayoutCols(self, self.headerLine)

	self.scrollBar:ClearAllPoints()
	self.scrollBar:SetPoint("TOPRIGHT", self.frame, -1, -(self.headerHeight + self.headerSpace + 16))
	self.scrollBar:SetPoint("BOTTOMRIGHT", self.frame, -1, 15)

	self.content:ClearAllPoints()
	self.content:SetPoint("TOPLEFT", 0, -(self.headerHeight + self.headerSpace))
	self.content:SetPoint("BOTTOMRIGHT", -(self.scrollWidth + self.scrollSpace), 0)

	local numRows = max(floor((self.frame:GetHeight() - self.headerHeight) / self.rowHeight), 0)

	while #self.rows < numRows do
		self.rows[#self.rows + 1] = CreateRow(self, self.content)
	end

	for i, row in pairs(self.rows) do
		if i > numRows then
			row:Hide()
		else
			row:Show()
			row:SetHeight(self.rowHeight)
			row:SetPoint("TOPLEFT", 0, -(i - 1) * self.rowHeight)
			row:SetPoint("TOPRIGHT", 0, -(i - 1) * self.rowHeight)
			LayoutCols(self, row)
		end
	end
end

local methods = {
	["OnAcquire"] = function(self)
	end,

	["SetData"] = function(self, data)
		GuildTaxes:Debug("SetData")
		self.data = data
		self:RefreshRows()
	end,

	["OnWidthSet"] = function(self, width)
		Layout(self)
	end,

	["OnHeightSet"] = function(self, height)
		Layout(self)
	end,

	["RefreshRows"] = function(self)
		GuildTaxes:Debug("Refresh rows: " .. self.rowHeight)
	end,
}


--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
local function Constructor()
	local num = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", ("GuildTaxesMembersTable%d"):format(num), UIParent)

	local widget = {
		type = Type,
		frame = frame,
		columns = {
			{"name", "Имя", 1},
			{"name", "Звание", 1},
			{"name", "Налог", 0.5},
			{"name", "Мес 1", 0.5},
			{"name", "Мес 2", 0.5},
			{"name", "Мес 3", 0.5},
			{"name", "Всего", 0.5},
		},
		rowHeight = 16,
		headerHeight = 16,
		headerSpace = 4,
		scrollWidth = 16,
		scrollSpace = 6,
		thumbHeight = 50,
		rows = {},
		data = {},
	}

	widget.headerLine = CreateRow(widget, frame)
	for i, col in pairs(widget.headerLine.cols) do
		col.textString:SetText(widget.columns[i][2])
	end
	headerLine = headerLine

	widget.content = CreateFrame("Frame", nil, frame)

	local scroll = CreateFrame("ScrollFrame", frame:GetName() .. "ScrollFrame", frame, "FauxScrollFrameTemplate")
	scroll:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, widget.rowHeight, function() widget:RefreshRows() end)
	end)

	local scrollBar = _G[scroll:GetName() .. "ScrollBar"]
	scrollBar:SetWidth(widget.scrollWidth)
	widget.scrollBar = scrollBar

	local thumb = scrollBar:GetThumbTexture()
	thumb:SetPoint("CENTER")
	thumb:SetHeight(widget.thumbHeight)
	thumb:SetWidth(widget.scrollWidth)

	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
