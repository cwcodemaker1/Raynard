function Library:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    local controls = {}
    for _, control in pairs(self.Controls) do table.insert(controls, control) end
    for _, control in ipairs(controls) do pcall(function() control:Destroy() end) end
    table.clear(self.Controls)
    for _, connection in ipairs(self._connections) do pcall(function() connection:Disconnect() end) end
    table.clear(self._connections)
    self.Feedback:Destroy()
    if self.Gui then self.Gui:Destroy() end
end

Library.CreateWindow = Library.new
Section.AddInput = Section.AddTextbox
Section.AddNumberInput = Section.AddNumberbox
Section.AddSelect = Section.AddDropdown
Section.AddSearchSelect = Section.AddSearchDropdown
Section.AddMultiSelect = Section.AddMultiDropdown
Section.AddPlayerSelect = Section.AddPlayerPicker
Section.AddColor = Section.AddColorPicker
Section.AddLanguage = Section.AddLanguageSelector
Section.AddLanguageSelect = Section.AddLanguageSelector
Section.AddInfo = Section.AddCallout
Section.AddBadge = Section.AddStatus
Section.AddTags = Section.AddTagInput
Section.AddStars = Section.AddRating
Section.AddGauge = Section.AddMeter
Section.AddDataTable = Section.AddTable
Section.AddTree = Section.AddTreeView
Section.AddConsole = Section.AddLogConsole
Section.AddCommandInput = Section.AddCommandBox
Section.AddSpinner = Section.AddLoadingSpinner
Section.AddAvatar = Section.AddAvatarViewport
Section.AddSwatches = Section.AddColorSwatches
Section.AddVector2 = Section.AddVector2Input
Section.AddVector3 = Section.AddVector3Input
Section.AddRGB = Section.AddRGBInput
Section.AddProperties = Section.AddPropertyGrid
Section.AddAccordion = Section.AddDisclosure
Section.AddSubTabs = Section.AddMiniTabs

setmetatable(Library, {
    __call = function(_, configuration)
        return Library.new(configuration)
    end,
})

return Library
