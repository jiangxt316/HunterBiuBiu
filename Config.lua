local L = HunterBiuBiu.L
print('config module loaded')

local roundNum = function(num, precision)
  if not precision then
    precision = 2
  end
  return string.format("%."..precision.."f", num)
end

local toBoolean = function(v)
  if v then
    return true
  end
  return false
end

local setChecked = function(name, val)
  local r = HunterBiuBiu.db.profile
  local opts = {}
  for n in string.gmatch(name, "([^.]+)") do
    table.insert(opts, n)
  end

  local n = opts[table.getn(opts)]
  if table.getn(opts) > 1 then
    table.remove(opts, table.getn(opts))
    for _, optName in ipairs(opts) do
      r = r[optName]
    end
  end

  print(n..'='..(val and 1 or 0))
  r[n] = val

  -- HunterBiuBiu.db.profile[name] = val and true or false
end
local getProfileValue = function(name)
  if not name then
    return nil
  end
  local r = HunterBiuBiu.db.profile
  local opts = {}
  for n in string.gmatch(name, "([^.]+)") do
    table.insert(opts, n)
  end

  local n = opts[table.getn(opts)]
  if table.getn(opts) > 1 then
    table.remove(opts, table.getn(opts))
    for _, optName in ipairs(opts) do
      r = r[optName]
    end
  end

  return r[n]
end



local activeTabIndex = 'old'
local tabButtons = {}
local tabPanels = {}
local tabOptions = {}

function capitalize_first_letter(s)
  if s == nil or s == "" then
      return s
  end

  -- 将首字母转换为大写
  local first_char = string.upper(string.sub(s, 1, 1))

  -- 如果字符串只有一个字符，直接返回大写的字符
  if string.len(s) == 1 then
      return first_char
  end

  -- 否则，将首字母与剩余的字符串（小写）连接起来
  local rest_of_string = string.lower(string.sub(s, 2))
  return first_char .. rest_of_string
end

local updateTab = function (newTabIndex)
  if newTabIndex == activeTabIndex then
    return
  end
  activeTabIndex = newTabIndex

  local tabIndexPascal = capitalize_first_letter(newTabIndex)
  for _, tabBtn in ipairs(tabButtons) do
    if tabBtn:GetName() == 'Hbb'..tabIndexPascal..'PanelTagBtn' then
      tabBtn.bg:SetTexture(0, 1, 0, 0.2)
    else
      tabBtn.bg:SetTexture(0, 1, 0, 0.05)
    end
  end

  for _, tabPanel in ipairs(tabPanels) do
    if tabPanel:GetName() == 'Hbb'..tabIndexPascal..'PanelFrm' then
      tabPanel:Show()
    else
      tabPanel:Hide()
    end
  end

end

function HunterBiuBiu.CreateConfigPanel(name, title, isScrollView)
  local panelCount = table.getn(tabPanels)

  local x,y,namePascal = 10, 10 + (panelCount * 40), capitalize_first_letter(name)
  local tagBtn = CreateFrame("Button", "Hbb"..namePascal.."PanelTagBtn", HbbConfigFrame)
  tagBtn.tag = name

  tagBtn.text = tagBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  tagBtn.text:SetText(title)
  tagBtn.text:SetAllPoints(tagBtn)
  tagBtn:SetWidth(80)
  tagBtn:SetHeight(30)
  tagBtn.bg = tagBtn:CreateTexture(nil, "BACKGROUND")
  tagBtn.bg:SetTexture(0, 1, 0, 0.05)
  tagBtn.bg:SetAllPoints(tagBtn)

  tagBtn:SetPoint("TOPLEFT", "HbbConfigFrame", "TOPLEFT", x, -y)
  tagBtn:SetScript("OnClick", function()
    updateTab(name)
  end)

  table.insert(tabButtons, tagBtn)

  local panel = CreateFrame("Frame", "Hbb"..namePascal.."PanelFrm", HbbConfigFrame)
  -- local panel = CreateFrame(isScrollView and "ScrollFrame" or "Frame", "Hbb"..namePascal.."PanelFrm", HbbConfigFrame)

  -- if isScrollView then
	--   panel.slider = CreateFrame("Slider", nil, panel, "UIPanelScrollBarTemplate")
  --   panel.slider:SetOrientation('VERTICAL')
  --   panel.slider:SetPoint("TOPLEFT", panel, "TOPRIGHT", -16, 0)
  --   panel.slider:SetPoint("BOTTOMRIGHT", 0, 0)

  --   -- panel.slider:SetThumbTexture("Interface\\BUTTONS\\WHITE8X8")
  --   -- panel.slider.thumb = panel.slider:GetThumbTexture()
  --   -- panel.slider.thumb:SetHeight(50)
  --   -- panel.slider.thumb:SetTexture(.3,1,.8,.5)

  --   panel.slider:SetScript("OnValueChanged", function()
  --     panel:SetVerticalScroll(this:GetValue())
  --     panel.UpdateScrollState()
  --   end)

  --   panel.UpdateScrollState = function()
  --     panel.slider:SetMinMaxValues(0, panel:GetVerticalScrollRange())
  --     panel.slider:SetValue(panel:GetVerticalScroll())

  --     local m = panel:GetHeight()+panel:GetVerticalScrollRange()
  --     local v = panel:GetHeight()
  --     local ratio = v / m

  --     if ratio < 1 then
  --       local size = math.floor(v * ratio)
  --       panel.slider.thumb:SetHeight(size)
  --       panel.slider:Show()
  --     else
  --       panel.slider:Hide()
  --     end
  --   end

  --   panel.Scroll = function(self, step)
  --     local step = step or 0

  --     local current = panel:GetVerticalScroll()
  --     print('current:'..current)
  --     local max = panel:GetVerticalScrollRange()
  --     print('max:'..max)
  --     local new = current - step
  --     print('new:'..new)

  --     if new >= max then
  --       panel:SetVerticalScroll(max)
  --     elseif new <= 0 then
  --       panel:SetVerticalScroll(0)
  --     else
  --       panel:SetVerticalScroll(new)
  --     end

  --     panel:UpdateScrollState()
  --   end

  --   panel:EnableMouseWheel(1)
  --   panel:SetScript("OnMouseWheel", function()
  --     this:Scroll(arg1*10)
  --   end)

  --   panel.frm = CreateFrame("Frame","Hbb"..namePascal.."PanelFrmChildFrame", panel)
  --   panel.frm:ClearAllPoints()
  --   panel.frm:SetAllPoints(panel)

  --   -- panel:SetScrollChild(panel.scrollbar)
  --   -- panel:EnableMouseWheel(true)
  --   -- panel:SetScript("OnMouseWheel", function()
  --     --   print('OnMouseWheel:'..arg1)
  --     -- end)
  --     -- panel.scrollbar:ClearAllPoints()
  --     -- panel.scrollbar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, -32)
  --     -- -- panel.scrollbar:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT",0,16)
  --     -- panel.scrollbar:SetHeight(HbbConfigFrame:GetHeight() - 64)
  --     -- panel.scrollbar:SetMinMaxValues(0, 1000)
  --     -- panel.scrollbar:SetValueStep(1)
  --     -- panel.scrollbar:SetValue(0)
  --   -- panel.scrollbar:SetWidth(16)
  --   -- panel.scrollbar:SetScript("OnValueChanged", function()
  --   --   print('OnValueChanged'..arg1)
  --   --   local frame, child = panel, panel.frm
  --   --   local viewheight, height = frame:GetHeight(), child:GetHeight()
  --   --   -- local width, viewwidth = frame:GetWidth(), child:GetWidth()
  --   --   local offset
  --   --   -- local xOffset = max(0, (width-viewwidth)/2 )
  --   --   if viewheight > height then
  --   --     offset = 0
  --   --   else
  --   --     offset = floor((height - viewheight) / 1000.0 * (arg1 or 0))
  --   --   end
  --   --   -- child:ClearAllPoints()
  --   --   -- child:SetPoint("TOPLEFT",frame,"TOPLEFT",xOffset,offset)
  --   --   child.offset = offset
  --   --   panel.scrollvalue = arg1
  --   -- end)
  -- end

  panel.tag = name
  panel.bg = panel:CreateTexture(nil, 'BACKGROUND')
  panel.bg:SetTexture(0, 1, 0, 0.25)
  panel:SetWidth(HbbConfigFrame:GetWidth() - 100)
  panel:SetHeight(HbbConfigFrame:GetHeight() - 10)
  panel:SetPoint("TOPRIGHT", "HbbConfigFrame", "TOPRIGHT", -10, -10)
  -- panel.vtext = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  -- panel.vtext:SetText(namePascal.." panel")
  -- panel.vtext:SetAllPoints(panel)
  panel:Hide()
  table.insert(tabPanels, panel)

  panel.opts = {}

  panel.AddOption = function(comp, nowrap, offsetX, offsetY, point)
    if not point then
      point = "TOPLEFT"
    end
    local gap = 6
    local y = offsetY
    if not y then
      if panel.lastOpt then
        local _,_,_,_,optY = panel.lastOpt:GetPoint()
        y = optY - panel.lastOpt:GetHeight() - gap
      else
        y = -gap
      end
    end
    comp:SetPoint(point, panel, point, offsetX or 10, y)

    if not nowrap then
      panel.lastOpt = comp
    end
  end

  return panel
end

function HunterBiuBiu.CreateConfigCheck(panel, name, text, hook, offsetX, nowrap)
  local tagPascal = capitalize_first_letter(panel.tag)
  local namePascal = capitalize_first_letter(name)
  local cb = CreateFrame("CheckButton", 'Hbb'..(tagPascal)..'PanelOpt'..namePascal, panel, "OptionsCheckButtonTemplate")

  -- if name == 'secondspellonlyboss' or name == 'secondspellserpent' then
  --   print(name..'='..(getProfileValue(name) and 1 or 0) )
  -- end

  cb:SetChecked(toBoolean(getProfileValue(name)))
  getglobal(cb:GetName().."Text"):SetText(text)
  cb:SetScript("OnClick", function(a, b)
    setChecked(name, toBoolean(cb:GetChecked()))
    if type(hook) == "function" then
      hook(toBoolean(cb:GetChecked()))
    end
  end)

  panel.AddOption(cb, nowrap, offsetX)
  return cb
end

function HunterBiuBiu.GetPanelY(panel)
  if not panel.lastOpt then
    return -10
  end

  return ({panel.lastOpt:GetPoint()})[5] - panel.lastOpt:GetHeight() - 10
end

function HunterBiuBiu.offsetComp(comp, offsetX, offsetY)
  local p1,rt,p2,x,y = comp:GetPoint()
  comp:SetPoint(p1, rt, p2, x + (offsetX or 0), y + (offsetY or 0))
end

function HunterBiuBiu.CreateConfigLabel(panel, text, offsetX, nowrap)

  local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetText(text)

  panel.AddOption(label, nowrap, offsetX)

  return label
end

function HunterBiuBiu.CreateConfigText(panel, name, text, hook, offsetX, nowrap)
  local tagPascal = capitalize_first_letter(panel.tag)
  local namePascal = capitalize_first_letter(name)
  local cb = CreateFrame("EditBox", 'Hbb'..(tagPascal)..'PanelOpt'..namePascal, panel, 'InputBoxTemplate')
  cb:SetHeight(16)
  cb:SetWidth(260)
  cb:SetAutoFocus(nil)

  cb.label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  panel.AddOption(cb.label, nil, offsetX)
  cb.label:SetText(text)
  cb:SetText(getProfileValue(name))
  cb:SetScript("OnTextChanged", function()
    setChecked(name, cb:GetText())
    if type(hook) == "function" then
      hook(cb:GetText())
    end
  end)

  panel.AddOption(cb, nowrap, offsetX, HunterBiuBiu.GetPanelY(panel) + 4)

  return cb
end

function HunterBiuBiu.CreateConfigSlider(panel, name, text, minValue, maxValue, valueStep, hook, offsetX)
  local tagPascal = capitalize_first_letter(panel.tag)
  local namePascal = capitalize_first_letter(name)

  local cb = CreateFrame("Slider", 'Hbb'..(tagPascal)..'PanelOpt'..namePascal, panel, 'OptionsSliderTemplate')
  cb:SetMinMaxValues(minValue, maxValue)
  cb:SetValueStep(valueStep)
  cb:SetWidth(280)
  getglobal(cb:GetName()..'Low'):Hide()
  getglobal(cb:GetName()..'High'):Hide()

  cb.label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  panel.AddOption(cb.label, 1, offsetX)
  cb.label:SetText(text)
  local v = getProfileValue(name)
  cb:SetValue(v)
  cb.vlabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  cb.vlabel:SetText(roundNum(v, 2))
  panel.AddOption(cb.vlabel, 1, -20, nil, "TOPRIGHT")
  cb:SetScript("OnValueChanged", function()
    setChecked(name, this:GetValue())
    cb.vlabel:SetText(roundNum(this:GetValue(), 2))
    if type(hook) == "function" then
      hook(this:GetValue())
    end
  end)

  panel.AddOption(cb, nil, offsetX, HunterBiuBiu.GetPanelY(panel) - 16)

  return cb
end

function CreatePanelColorPicker(panel, name, options, template)
  local tagPascal = capitalize_first_letter(panel.tag)
  local namePascal = capitalize_first_letter(name)
	local frame = CreateFrame("Button", 'Hbb'..(tagPascal)..'PanelOpt'..namePascal, panel, template)
	frame.options = options

	frame.colorSwatch = frame:CreateTexture(nil, "OVERLAY")
	frame.colorSwatch:SetWidth(19)
	frame.colorSwatch:SetHeight(19)
	frame.colorSwatch:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
	frame.colorSwatch:SetPoint("CENTER", frame)

	frame.Callback = function()
		if not ColorPickerFrame:IsVisible() then
			local options = frame.options
			local r, g, b = ColorPickerFrame:GetColorRGB()
			frame.colorSwatch:SetVertexColor(r, g, b)
			options.r = r
			options.g = g
			options.b = b
		end
	end

	frame.texture = frame:CreateTexture(nil, "BACKGROUND")
	frame.texture:SetWidth(16)
	frame.texture:SetHeight(16)
	frame.texture:SetTexture(1, 1, 1)
	frame.texture:SetPoint("CENTER", frame.colorSwatch)
	frame.texture:Show()

	frame.checkers = frame:CreateTexture(nil, "BACKGROUND")
	frame.checkers:SetWidth(14)
	frame.checkers:SetHeight(14)
	frame.checkers:SetTexture("Tileset\\Generic\\Checkers")
	frame.checkers:SetTexCoord(.25, 0, 0.5, .25)
	frame.checkers:SetDesaturated(true)
	frame.checkers:SetVertexColor(1, 1, 1, 0.75)
	frame.checkers:SetPoint("CENTER", frame.colorSwatch)
	frame.checkers:Show()

	frame.text = frame:CreateFontString(nil,"OVERLAY","GameFontHighlight")
	frame.text:SetHeight(24)
	frame.text:SetJustifyH("LEFT")
	frame.text:SetTextColor(1, 1, 1)
	frame.text:SetPoint("LEFT", frame.colorSwatch, "RIGHT", 2, 0)

	frame:EnableMouse(true)
	frame:SetScript("OnClick", function ()
		local r,g,b = this.colorSwatch:GetVertexColor()
		ShowColorPicker(r, g, b, this.Callback, this.options)
	end)

	frame.load = function (frame, options)
		frame.options = options
		frame.colorSwatch:SetVertexColor(options.r, options.g, options.b)
	end

	return frame
end

function HunterBiuBiu.CreateConfigColor(panel, name, text, propr, propg, propb, hook, width)
  local prof = HunterBiuBiu.db.profile
  local tagPascal = capitalize_first_letter(panel.tag)
  local namePascal = capitalize_first_letter(name)
  local colorBtn = CreateFrame("Button", "Hbb"..tagPascal.."Panel"..namePascal.."ColorBtn", panel)
    colorBtn.text = colorBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    colorBtn.text:SetText(text)
    colorBtn.text:SetPoint("LEFT", colorBtn)
    colorBtn:SetWidth(width or 110)
    colorBtn:SetHeight(30)
    colorBtn.texture = colorBtn:CreateTexture(nil, "BACKGROUND")
    colorBtn.texture:SetTexture(prof[propr],prof[propg],prof[propb], 1)
    colorBtn.texture:SetWidth(16)
    colorBtn.texture:SetHeight(16)
    colorBtn.texture:SetPoint("RIGHT", colorBtn)

    colorBtn:SetScript("OnClick", function()
      ColorPickerFrame.func = function()
        local newR, newG, newB = ColorPickerFrame:GetColorRGB();
        prof[propr] = newR
        prof[propg] = newG
        prof[propb] = newB
        colorBtn.texture:SetTexture(prof[propr],prof[propg],prof[propb], 1)
        HunterBiuBiu:UpdateFeignDeathSetting()
        if type(hook) == 'function' then
          hook(newR, newG, newB)
        end
      end;
      ColorPickerFrame.hasOpacity = nil;
      ColorPickerFrame.opacityFunc = nil;
      ColorPickerFrame.opacity = nil;
      ColorPickerFrame:SetColorRGB( prof[propr], prof[propg], prof[propb]);
      ColorPickerFrame.previousValues = {
        r = prof[propr],
        g = prof[propg],
        b = prof[propb]
      };
      ColorPickerFrame.cancelFunc = function(previousValues)
        if previousValues and previousValues.r then
          prof[propr] = previousValues.r
          prof[propg] = previousValues.g
          prof[propb] = previousValues.b
          colorBtn.texture:SetTexture(previousValues.r,previousValues.g,previousValues.b, 1)
          HunterBiuBiu:UpdateFeignDeathSetting()
          if type(hook) == 'function' then
            hook(previousValues.r,previousValues.g,previousValues.b)
          end
        end
      end;
      -- ColorPickerFrame:SetPoint(HbbConfigFrame)
      ShowUIPanel(ColorPickerFrame);
    end)

  return colorBtn
end

function HunterBiuBiu.PointTo(o, parent, p1, p2, x, y)
  if o and o.SetPoint then
    o:SetPoint(p1, parent, p2, x or 0, y or 0)
  end
end

function HbbConfigFrameInit()

  if not HbbConfigFrame then
    HbbConfigFrame = CreateFrame("Frame", "HbbConfigFrame", UIParent)
    HbbConfigFrame:SetWidth(420)
    HbbConfigFrame:SetHeight(670)
    HbbConfigFrame:SetPoint("CENTER", WorldFrame, "CENTER")
    HbbConfigFrame:Hide()

    HbbConfigFrame.Bdr = HbbConfigFrame:CreateTexture(nil, "BACKGROUND")
    HbbConfigFrame.Bdr:SetPoint("CENTER", HbbConfigFrame, "CENTER")
    HbbConfigFrame.Bdr:SetTexture(0.15, 0.6, 0.15, 0.5)
    HbbConfigFrame.Bdr:SetWidth(HbbConfigFrame:GetWidth() + 2)
    HbbConfigFrame.Bdr:SetHeight(HbbConfigFrame:GetHeight() + 2)

    HbbConfigFrame.Bg = HbbConfigFrame:CreateTexture(nil, "ARTWORK")
    HbbConfigFrame.Bg:SetAllPoints(HbbConfigFrame)
    HbbConfigFrame.Bg:SetTexture(0, 0, 0, 0.75)

    HbbConfigFrame:SetClampedToScreen(true)
    HbbConfigFrame:EnableMouse(1)
    HbbConfigFrame:SetMovable(1)
    HbbConfigFrame:RegisterForDrag("LeftButton")
    HbbConfigFrame:SetScript("OnDragStart", function()
      this:StartMoving()
    end)
    HbbConfigFrame:SetScript("OnDragStop", function()
      this:StopMovingOrSizing()
      local _, _, _, x, y = this:GetPoint()
      local xx = x - HbbConfigFrame:GetWidth() / 2
      local yy = y - HbbConfigFrame:GetHeight() / 2

      HbbConfigFrame:SetPoint("CENTER", WorldFrame, "CENTER", xx, yy)
    end)

    HbbConfigFrame.closeBtn = CreateFrame("Button","HbbConfigFrameCloseBtn",HbbConfigFrame,"UIPanelCloseButton")
    HbbConfigFrame.closeBtn:SetScript("OnClick", function()
      HbbConfigFrame:Hide();
    end)
    HbbConfigFrame.closeBtn:SetPoint("TOPRIGHT",HbbConfigFrame,"TOPRIGHT",-2,-2)

    local panelBiu = HunterBiuBiu.CreateConfigPanel('biu', 'BiuBiu', 1)
    HunterBiuBiu.CreateConfigCheck(panelBiu, "multishot", L["Multi-Shot"], nil, nil, 1)
    HunterBiuBiu.CreateConfigCheck(panelBiu, "multishotfirst", L["Multi-Shot First"], nil, 150)
    HunterBiuBiu.CreateConfigSlider(panelBiu, "multishotfirstlimit", L["Multi-Shot First Limit"], 1, 1.5, 0.01)
    HunterBiuBiu.CreateConfigCheck(panelBiu, "aimedshot", L["Aimed Shot"])
    HunterBiuBiu.CreateConfigCheck(panelBiu, "howl", L["Howl"], nil, nil, 1)
    HunterBiuBiu.CreateConfigCheck(panelBiu, "lightningbreath", L["Lightning Breath"], nil, 150)
    HunterBiuBiu.CreateConfigCheck(panelBiu, "optimizeSec", L["OptimizeSecondCast"])
    HunterBiuBiu.CreateConfigSlider(panelBiu, "optimizeSecLimit", L["OptimizeSecondCastLimit"], 0.65, 1, 0.01)
    HunterBiuBiu.CreateConfigSlider(panelBiu, "tv1", L["ThresholdValue"]..'1', 2.5, 3, 0.05, function(v)
    HunterBiuBiu.tv1 = v end)
    HunterBiuBiu.CreateConfigSlider(panelBiu, "tv2", L["ThresholdValue"]..'2', 1.9, 2.8, 0.01, function(v)
      HunterBiuBiu.tv2 = v end)
    HunterBiuBiu.CreateConfigCheck(panelBiu, "priorauto", L["Prior Autoshot"], nil, nil, 1)
    HunterBiuBiu.CreateConfigCheck(panelBiu, "restoreauto", L["Restore Autoshot"], nil, 150)
    HunterBiuBiu.CreateConfigCheck(panelBiu, "aconlycombat", L["Assist Cast Only Combat"])
    HunterBiuBiu.CreateConfigCheck(panelBiu, "secondspell", L["Second Spell"],nil, nil, 1)
    HunterBiuBiu.CreateConfigCheck(panelBiu, "secondspellonlyboss", L["Only Boss"], nil, 170)
    HunterBiuBiu.CreateConfigSlider(panelBiu, "secondspelllimit", L["Second Spell Limit"], 0.65, 1.5, 0.01)
    HunterBiuBiu.CreateConfigCheck(panelBiu, "secondspellserpent", L["Serpent Sting"])
    HunterBiuBiu.CreateConfigSlider(panelBiu, "secondspellserpentlimit", L["Target Health"].." >", 100000, 1000000, 10000)
    HunterBiuBiu.CreateConfigCheck(panelBiu, "secondspellarcane", L["Arcane Shot"], nil, nil, 1)
    HunterBiuBiu.CreateConfigCheck(panelBiu, "secondspellarcanelv1", L["Arcane Shot"]..' ('..L["Level"]..' 1)', nil, 150)
    HunterBiuBiu.CreateConfigSlider(panelBiu, "secondspellarcanelimit", L["Switch Rank Mana"].." < ", 2000, 6000, 100)

    local panelTranq = HunterBiuBiu.CreateConfigPanel('tranq', L["Tranquilizing Shot"])
    HunterBiuBiu.CreateConfigCheck(panelTranq, "tranq", L["Tranq Alert"], nil)
    HunterBiuBiu.CreateConfigCheck(panelTranq, "channels.SAY", L["CHAT_SAY"], nil, 30)
    HunterBiuBiu.CreateConfigCheck(panelTranq, "channels.EMOTE", L["CHAT_EMOTE"], nil, 30)
    HunterBiuBiu.CreateConfigCheck(panelTranq, "channels.YELL", L["CHAT_YELL"], nil, 30)
    HunterBiuBiu.CreateConfigCheck(panelTranq, "channels.PARTY", L["CHAT_PARTY"], nil, 30)
    HunterBiuBiu.CreateConfigCheck(panelTranq, "channels.RAID", L["CHAT_RAID"], nil, 30)
    HunterBiuBiu.CreateConfigText(panelTranq, "tranqmsg", L["Succeed Message"], nil, 30)
    HunterBiuBiu.CreateConfigText(panelTranq, "tranqfailmsg", L["Failure Message"], nil, 30)

    -- local succeedBtn = CreateFrame("Button", "HbbTranqPanelSucceedBtn", panelTranq, "UIPanelButtonTemplate")
    -- succeedBtn.text = succeedBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- succeedBtn.text:SetText("测试成功消息")
    -- succeedBtn.text:SetAllPoints(succeedBtn)
    -- succeedBtn:SetWidth(120)
    -- succeedBtn:SetHeight(30)
    -- succeedBtn:SetPoint("BOTTOMLEFT", panelTranq, "BOTTOMLEFT", 20, 120)
    -- succeedBtn:SetScript("OnClick", function()
    --   print('测试宁神成功')
    -- end)

    -- local failedBtn = CreateFrame("Button", "HbbTranqPanelFailedBtn", panelTranq, "UIPanelButtonTemplate")
    -- failedBtn.text = failedBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- failedBtn.text:SetText("测试失败消息")
    -- failedBtn.text:SetAllPoints(failedBtn)
    -- failedBtn:SetWidth(120)
    -- failedBtn:SetHeight(30)
    -- failedBtn:SetPoint("BOTTOMLEFT", panelTranq, "BOTTOMLEFT", 160, 120)
    -- failedBtn:SetScript("OnClick", function()
    --   print('测试宁神失败')
    -- end)

    local panelAutoTimer = HunterBiuBiu.CreateConfigPanel('timer', '射击计时条')
    HunterBiuBiu.CreateConfigCheck(panelAutoTimer, "autoshotbar", L["On"], nil)
    HunterBiuBiu.CreateConfigCheck(panelAutoTimer, "autoshotbartext", L["AutoshotBarShowText"], nil)
    HunterBiuBiu.CreateConfigCheck(panelAutoTimer, "autoshotbartmr", L["AutoshotBarShowTimer"], nil)
    HunterBiuBiu.CreateConfigCheck(panelAutoTimer, "autoshotbarl", L["AutoshotBar Lock"], nil)
    HunterBiuBiu.CreateConfigSlider(panelAutoTimer, "autoshotbarw", L["AutoshotBar Width"], 100, 400, 10)
    HunterBiuBiu.CreateConfigSlider(panelAutoTimer, "autoshotbarh", L["AutoshotBar Height"], 5, 60, 1)

    local autoshotTimerColorBtn1 = HunterBiuBiu.CreateConfigColor(panelAutoTimer, 'mcolor', L["AutoshotBar Color1"], 'autoshotbarr1', 'autoshotbarg1', 'autoshotbarb1', nil, 170)
    panelAutoTimer.AddOption(autoshotTimerColorBtn1)
    local autoshotTimerColorBtn2 = HunterBiuBiu.CreateConfigColor(panelAutoTimer, 'scolor', L["AutoshotBar Color2"], 'autoshotbarr2', 'autoshotbarg2', 'autoshotbarb2', nil, 156)
    panelAutoTimer.AddOption(autoshotTimerColorBtn2)

    local autoshotBarTempLabel = HunterBiuBiu.CreateConfigLabel(panelAutoTimer, L["AutoshotBarTemp"], 10)
    HunterBiuBiu.offsetComp(autoshotBarTempLabel, 0, -6)

    local chk1,chk2,chk3
    local checkAutoshotBarTemp = function(chk, template)
      for _, c in ipairs({chk1, chk2, chk3}) do
        if c == chk then
          c:SetChecked(true)
        else
          c:SetChecked(false)
        end
      end
      if template then
        HunterBiuBiu.db.profile.autoshotbartemp = template
      end
    end
    chk1 = HunterBiuBiu.CreateConfigCheck(panelAutoTimer, "autoshotbard1", L["AutoshotBarL2rr2l"], function () checkAutoshotBarTemp(chk1, 'l2rr2l') end, 10)
    chk2 = HunterBiuBiu.CreateConfigCheck(panelAutoTimer, "autoshotbard2", L["AutoshotBarL2rl2r"], function () checkAutoshotBarTemp(chk2, 'l2rl2r') end, 10)
    HunterBiuBiu.offsetComp(chk2, 0, 5)
    chk3 = HunterBiuBiu.CreateConfigCheck(panelAutoTimer, "autoshotbard3", L["AutoshotBarS2cc2s"], function () checkAutoshotBarTemp(chk3, 's2cc2s') end, 10)
    HunterBiuBiu.offsetComp(chk3, 0, 5)

    HunterBiuBiu.CreateConfigCheck(panelAutoTimer, "autoshotbarshow", L["AutoshotBar Always Visible"], function(v) if v then
      HbbAutoBar:SetAlpha(1)
      HbbAutoBar:Show()
    else
      HbbAutoBar:Hide()
    end end)

    local checkedTemplate
    if HunterBiuBiu.db.profile.autoshotbartemp == 'l2rr2l' then
      checkedTemplate = chk1
    elseif HunterBiuBiu.db.profile.autoshotbartemp == 'l2rl2r' then
      checkedTemplate = chk2
    elseif HunterBiuBiu.db.profile.autoshotbartemp == 's2cc2s' then
      checkedTemplate = chk3
    end
    checkAutoshotBarTemp(checkedTemplate)

    local panelFD = HunterBiuBiu.CreateConfigPanel('fd', '假死')
    HunterBiuBiu.CreateConfigCheck(panelFD, "feigndeathon", L["On"], nil)
    HunterBiuBiu.CreateConfigCheck(panelFD, "feigndeathalarm", L["Feign Death Alarm"], nil)
    HunterBiuBiu.CreateConfigCheck(panelFD, "feigndeathmask", L["Feign Death Mask"], nil)
    HunterBiuBiu.CreateConfigSlider(panelFD, "feigndeathdelay", L["Feign Death Delay"], 0.1, 5, 0.1)
    HunterBiuBiu.CreateConfigSlider(panelFD, "feigndeatha", L["Feign Death Alpha"], 0, 1, 0.05, function() HunterBiuBiu:UpdateFeignDeathSetting() end)
    HunterBiuBiu.CreateConfigSlider(panelFD, "feigndeathfontsize", L["Feign Death Text Size"], 12, 24, 1, function() HunterBiuBiu:UpdateFeignDeathSetting() end)
    local feigndeathtextTextbox = HunterBiuBiu.CreateConfigText(panelFD, "feigndeathtext", L["Feign Death Text"], function() HunterBiuBiu:UpdateFeignDeathSetting() end, 10)
    feigndeathtextTextbox:SetWidth(panelFD:GetWidth() - 20)
    local feigndeathxTextbox = HunterBiuBiu.CreateConfigText(panelFD, "feigndeathx", L["Feign Death X"], function() HunterBiuBiu:UpdateFeignDeathSetting() end, 10)
    feigndeathxTextbox:SetWidth((panelFD:GetWidth() - 20) / 2 - 5)
    local feigndeathyTextbox = HunterBiuBiu.CreateConfigText(panelFD, "feigndeathy", L["Feign Death Y"], function() HunterBiuBiu:UpdateFeignDeathSetting() end, 10)
    feigndeathyTextbox:SetWidth((panelFD:GetWidth() - 20) / 2 - 5)

    local fdPreviewBtn = CreateFrame("Button", "HbbFDPanelPreviewBtn", panelFD, "UIPanelButtonTemplate")
    fdPreviewBtn.text = fdPreviewBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fdPreviewBtn.text:SetText(L["Feign Death Preview"])
    fdPreviewBtn.text:SetAllPoints(fdPreviewBtn)
    fdPreviewBtn:SetWidth(120)
    fdPreviewBtn:SetHeight(30)
    fdPreviewBtn:SetPoint("TOPLEFT", panelFD, "TOPLEFT", 0, -500)
    fdPreviewBtn:SetScript("OnClick", function()
      HunterBiuBiu:FeignDeathFailed()
    end)


    local fdBgColorBtn = HunterBiuBiu.CreateConfigColor(panelFD, 'bg', L["Feign Death Color"], 'feigndeathr', 'feigndeathg', 'feigndeathb')
    local fdTextColorBtn = HunterBiuBiu.CreateConfigColor(panelFD, 'bg', L["Feign Death Text Color"], 'feigndeathtextr', 'feigndeathtextg', 'feigndeathtextb')

    panelFD.AddOption(fdBgColorBtn, 1, 10)
    panelFD.AddOption(fdTextColorBtn, nil, 150)

    local fdAlertCheck = HunterBiuBiu.CreateConfigCheck(panelFD, "feigndeathalert", L["Feign Death Alert"], nil)
    HunterBiuBiu.offsetComp(fdAlertCheck, -5)
    local fdMsgTextBox = HunterBiuBiu.CreateConfigText(panelFD, "feigndeathalertmsg", L["Feign Death Alert Label"])
    fdMsgTextBox:SetWidth(panelFD:GetWidth() - 20)

    local actionSlotIdHandler = function(v, name)
      local slotId = HunterBiuBiu.toActionSlot(v)
      if slotId then
        HunterBiuBiu.db.profile[name] = slotId
        HunterBiuBiu[name] = slotId
      end
    end

    local panelOld = HunterBiuBiu.CreateConfigPanel('old', '老版本')
    HunterBiuBiu.CreateConfigText(panelOld, "trueshotActionId", L["Trueshot Action Id"], function(text) actionSlotIdHandler(text, "trueshotActionId") end)
    HunterBiuBiu.CreateConfigText(panelOld, "multishotActionId", L["Multishot Action Id"], function(text) actionSlotIdHandler(text, "multishotActionId") end)
    HunterBiuBiu.CreateConfigText(panelOld, "autoshotActionId", L["Autoshot Action Id"], function(text) actionSlotIdHandler(text, "autoshotActionId") end)

    local autoSetActionBtn = CreateFrame("Button", "HbbOldPanelAutoSetActionBtn", panelOld, "UIPanelButtonTemplate")
    autoSetActionBtn.text = autoSetActionBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    autoSetActionBtn.text:SetText(L["Auto Set Action"])
    autoSetActionBtn.text:SetAllPoints(autoSetActionBtn)
    autoSetActionBtn:SetWidth(120)
    autoSetActionBtn:SetHeight(30)
    autoSetActionBtn:SetPoint("TOPLEFT", panelOld, "TOPLEFT", 10, -130)
    autoSetActionBtn:SetScript("OnClick", function()
      HunterBiuBiu:autoSetAction()
    end)



    updateTab('biu')


  --   HbbConfigCreateCheckbox("multishot", L["Multi-Shot"], function(v) print("callback, now is "..(v and "checked" or "not checked")) end)

  --   local name = 'testscroll'
  --   local frmName = "HbbConfigFrame_" .. name
  --   local frm = CreateFrame("CheckButton", frmName, HbbConfigFrame, "OptionsCheckButtonTemplate")
  --   local frmText = getglobal(frmName .. "Text")
  --   frmText:SetText(text)
  --   frm:SetScript("OnClick", function(a, b)
  --     setChecked(name, frm:GetChecked())
  --   if type(hook) == "function" then
  --     hook(frm:GetChecked())
  --   end
  -- end)

  -- frm:SetPoint("TOPLEFT", "HbbConfigFrame", "TOPLEFT", 150, -150)

  end

end

function HbbConfigFrameShow()
  HbbConfigFrameInit()
  HbbConfigFrame:Show();
end

function HbbConfigCreateCheckbox(name, text, hook)
  local cursor = HbbConfigFrame.CompCursor or 0
  local col = math.mod(cursor, 2)
  local row = math.floor(cursor / 2)
  local compw = (HbbConfigFrame:GetWidth() - 20) / 2
  local comph = 20
  local x = col * compw + 10
  local y = row * comph - 10

  local frmName = "HbbConfigFrame_" .. name
  CreateFrame("CheckButton", frmName, HbbConfigFrame, "OptionsCheckButtonTemplate")
  -- Check:SetText(text)
  local frm = getglobal(frmName)
  local frmText = getglobal(frmName .. "Text")
  frmText:SetText(text)
  frm:SetScript("OnClick", function(a, b)
    setChecked(name, frm:GetChecked())
    if type(hook) == "function" then
      hook(frm:GetChecked())
    end
  end)

  frm:SetPoint("TOPLEFT", "HbbConfigFrame", "TOPLEFT", x, y)
end



-- self.cmdtable = {
--   type = "group",
--   args =
--   {
--     trueshotActionId = {
--       type = "text",
--       name = L["Trueshot Action Id"],
--       desc = L["Trueshot Action Id"],
--       usage = L["Trueshot Action Id"],
--       get = function() return HunterBiuBiu.db.profile.trueshotActionId end,
--       set = function(v) if toActionSlot(v) then HunterBiuBiu.db.profile.trueshotActionId = toActionSlot(v); self.trueshotActionId = toActionSlot(v); end end,
--       order = 1,
--     },
--     multishotActionId = {
--       type = "text",
--       name = L["Multishot Action Id"],
--       desc = L["Multishot Action Id"],
--       usage = L["Multishot Action Id"],
--       get = function() return HunterBiuBiu.db.profile.multishotActionId end,
--       set = function(v) if toActionSlot(v) then HunterBiuBiu.db.profile.multishotActionId = toActionSlot(v); self.multishotActionId = toActionSlot(v); end end,
--       order = 2,
--     },
--     autoshotActionId = {
--       type = "text",
--       name = L["Autoshot Action Id"],
--       desc = L["Autoshot Action Id"],
--       usage = L["Autoshot Action Id"],
--       get = function() return HunterBiuBiu.db.profile.autoshotActionId end,
--       set = function(v) if toActionSlot(v) then HunterBiuBiu.db.profile.autoshotActionId = toActionSlot(v); self.autoshotActionId = toActionSlot(v); end end,
--       order = 3,
--     },
--     autoSetAction = {
--       type = "execute",
--       name = L["Auto Set Action"],
--       desc = L["Auto Set Action"],
--       func = function() self:autoSetAction() end,
--       order = 4,
--     },
--     tv1 = {
--       type = "range",
--       name = L["ThresholdValue"].."1",
--       desc = L["ThresholdValue"].."1",
--       min = 2,
--       max = 3,
--       step = 0.1,
--       get = function() return HunterBiuBiu.db.profile.tv1 end,
--       set = function(v) HunterBiuBiu.db.profile.tv1 = v; self.tv1 = v; end,
--     },
--     tv2 = {
--       type = "range",
--       name = L["ThresholdValue"].."2",
--       desc = L["ThresholdValue"].."2",
--       min = 1.8,
--       max = 2.2,
--       step = 0.01,
--       get = function() return HunterBiuBiu.db.profile.tv2 end,
--       set = function(v) HunterBiuBiu.db.profile.tv2 = v; self.tv2 = v; end,
--     },
--     multishot = {
--       type = "toggle",
--       name = L["Multi-Shot"],
--       desc = L["Multi-Shot"],
--       get = function() return HunterBiuBiu.db.profile.multishot end,
--       set = function () self:ToggleCastMultishot() end,
--       order = 7,
--     },
--     aimedshot = {
--       type = "toggle",
--       name = L["Aimed Shot"],
--       desc = L["Aimed Shot"],
--       get = function() return HunterBiuBiu.db.profile.aimedshot end,
--       set = function () self:ToggleCastAimedshot() end,
--       order = 8,
--     },
--     howl = {
--       type = "toggle",
--       name = L["Howl"],
--       desc = L["Howl"],
--       get = function() return HunterBiuBiu.db.profile.howl end,
--       set = function() local v = not HunterBiuBiu.db.profile.howl;HunterBiuBiu.db.profile.howl = v;self.castHowl = v; end,
--       order = 9,
--     },
--     tranq = {
--       type = "toggle",
--       name = L["Tranq Alert"],
--       desc = L["Tranq Alert"],
--       get = function() return HunterBiuBiu.db.profile.tranq end,
--       set = function() local v = not HunterBiuBiu.db.profile.tranq;HunterBiuBiu.db.profile.tranq = v; end,
--       order = 10,
--     },
--     channel = {
--       type = "group",
--       name = L["Tranq Notification Channel"],
--       desc = L["Tranq Notification Channel"],
--       usage = L["Tranq Notification Channel"],
--       order = 11,
--       args = {
--         SAY = {
--           type = "toggle",
--           name = L["CHAT_SAY"],
--           desc = L["CHAT_SAY"],
--           get = function() return HunterBiuBiu.db.profile.channels["SAY"] end,
--           set = function() HunterBiuBiu.db.profile.channels["SAY"] = not HunterBiuBiu.db.profile.channels["SAY"] end
--         },
--         EMOTE = {
--           type = "toggle",
--           name = L["CHAT_EMOTE"],
--           desc = L["CHAT_EMOTE"],
--           get = function() return HunterBiuBiu.db.profile.channels["EMOTE"] end,
--           set = function() HunterBiuBiu.db.profile.channels["EMOTE"] = not HunterBiuBiu.db.profile.channels["EMOTE"] end
--         },
--         YELL = {
--           type = "toggle",
--           name = L["CHAT_YELL"],
--           desc = L["CHAT_YELL"],
--           get = function() return HunterBiuBiu.db.profile.channels["YELL"] end,
--           set = function() HunterBiuBiu.db.profile.channels["YELL"] = not HunterBiuBiu.db.profile.channels["YELL"] end
--         },
--         PARTY = {
--           type = "toggle",
--           name = L["CHAT_PARTY"],
--           desc = L["CHAT_PARTY"],
--           get = function() return HunterBiuBiu.db.profile.channels["PARTY"] end,
--           set = function() HunterBiuBiu.db.profile.channels["PARTY"] = not HunterBiuBiu.db.profile.channels["PARTY"] end
--         },
--         RAID = {
--           type = "toggle",
--           name = L["CHAT_RAID"],
--           desc = L["CHAT_RAID"],
--           get = function() return HunterBiuBiu.db.profile.channels["RAID"] end,
--           set = function() HunterBiuBiu.db.profile.channels["RAID"] = not HunterBiuBiu.db.profile.channels["RAID"] end
--         },
--       }
--     },
--     -- channel = {
--     -- 	type = "text",
--     -- 	name = L["Tranq Notification Channel"],
--     -- 	desc = L["Tranq Notification Channel"],
--     -- 	usage = L["Tranq Notification Channel"],
--     -- 	get = function() return HunterBiuBiu.db.profile.channel end,
--     -- 	set = function(v) HunterBiuBiu.db.profile.channel = v; end,
--     -- 	order = 10,
--     -- },
--     beta = {
--       type = "group",
--       name = L["Beta Func"],
--       desc = L["Beta Func"],
--       usage = L["Beta Func"],
--       order = 11,
--       args = {
--         priorauto = {
--           type = "toggle",
--           name = L["Prior Autoshot"],
--           desc = L["Prior Autoshot"],
--           get = function() return HunterBiuBiu.db.profile.priorauto end,
--           set = function() HunterBiuBiu.db.profile.priorauto = not HunterBiuBiu.db.profile.priorauto end,
--           order = 1
--         },
--         autoshotbar = {
--           type = "toggle",
--           name = L["AutoshotBar"],
--           desc = L["AutoshotBar"],
--           get = function() return HunterBiuBiu.db.profile.autoshotbar end,
--           set = function() HunterBiuBiu.db.profile.autoshotbar = not HunterBiuBiu.db.profile.autoshotbar; self:UpdateAutoshotBarVisible() end,
--           order = 2
--         },
--         autoshotbartemp = {
--           type = "group",
--           name = L["AutoshotBarTemp"],
--           desc = L["AutoshotBarTemp"],
--           usage = L["AutoshotBarTemp"],
--           order = 3,
--           args = {
--             l2rr2l = {
--               type = "toggle",
--               name = L["AutoshotBarL2rr2l"],
--               desc = L["AutoshotBarL2rr2l"],
--               get = function() return HunterBiuBiu.db.profile.autoshotbartemp=='l2rr2l' end,
--               set = function() HunterBiuBiu.db.profile.autoshotbartemp ='l2rr2l' end,
--               order = 1
--             },
--             l2rl2r = {
--               type = "toggle",
--               name = L["AutoshotBarL2rl2r"],
--               desc = L["AutoshotBarL2rl2r"],
--               get = function() return HunterBiuBiu.db.profile.autoshotbartemp=='l2rl2r' end,
--               set = function() HunterBiuBiu.db.profile.autoshotbartemp ='l2rl2r' end,
--               order = 2
--             },
--             s2cc2s = {
--               type = "toggle",
--               name = L["AutoshotBarS2cc2s"],
--               desc = L["AutoshotBarS2cc2s"],
--               get = function() return HunterBiuBiu.db.profile.autoshotbartemp=='s2cc2s' end,
--               set = function() HunterBiuBiu.db.profile.autoshotbartemp ='s2cc2s' end,
--               order = 3
--             },
--           }
--         },
--         autoshotbarw = {
--           type = "range",
--           name = L["AutoshotBar Width"],
--           desc = L["AutoshotBar Width"],
--           min = 120,
--           max = 360,
--           step = 5,
--           get = function() return HunterBiuBiu.db.profile.autoshotbarw end,
--           set = function(v) HunterBiuBiu.db.profile.autoshotbarw = v; self:UpdateAutoshotBarW() end,
--           order = 4
--         },
--         autoshotbarh = {
--           type = "range",
--           name = L["AutoshotBar Height"],
--           desc = L["AutoshotBar Height"],
--           min = 6,
--           max = 60,
--           step = 1,
--           get = function() return HunterBiuBiu.db.profile.autoshotbarh end,
--           set = function(v) HunterBiuBiu.db.profile.autoshotbarh = v; self:UpdateAutoshotBarH() end,
--           order = 5
--         },
--         autoshotbarshowtext = {
--           type = "toggle",
--           name = L["AutoshotBarShowText"],
--           desc = L["AutoshotBarShowText"],
--           get = function() return HunterBiuBiu.db.profile.autoshotbartext end,
--           set = function() HunterBiuBiu.db.profile.autoshotbartext = not HunterBiuBiu.db.profile.autoshotbartext; self:UpdateAutobarLockStatus() end,
--           order = 6
--         },
--         autoshotbarshowtimer = {
--           type = "toggle",
--           name = L["AutoshotBarShowTimer"],
--           desc = L["AutoshotBarShowTimer"],
--           get = function() return HunterBiuBiu.db.profile.autoshotbartmr end,
--           set = function() HunterBiuBiu.db.profile.autoshotbartmr = not HunterBiuBiu.db.profile.autoshotbartmr; self:UpdateAutobarLockStatus() end,
--           order = 7
--         },
--         autoshotbarl = {
--           type = "toggle",
--           name = L["AutoshotBar Lock"],
--           desc = L["AutoshotBar Lock"],
--           get = function() return HunterBiuBiu.db.profile.autoshotbarl end,
--           set = function() HunterBiuBiu.db.profile.autoshotbarl = not HunterBiuBiu.db.profile.autoshotbarl; self:UpdateAutobarLockStatus() end,
--           order = 8
--         },
--         autoshotbarc1 = {
--           type = 'color',
--           name = L["AutoshotBar Color1"],
--           desc = L["AutoshotBar Color1"],
--           get = function() return HunterBiuBiu.db.profile.autoshotbarr1, HunterBiuBiu.db.profile.autoshotbarg1, HunterBiuBiu.db.profile.autoshotbarb1 end,
--           set = function(r, g, b) HunterBiuBiu.db.profile.autoshotbarr1 = r; HunterBiuBiu.db.profile.autoshotbarg1 = g; HunterBiuBiu.db.profile.autoshotbarb1 = b; self:UpdateAutoshotBarColor() end,
--           order = 9
--         },
--         autoshotbarc2 = {
--           type = 'color',
--           name = L["AutoshotBar Color2"],
--           desc = L["AutoshotBar Color2"],
--           get = function() return HunterBiuBiu.db.profile.autoshotbarr2, HunterBiuBiu.db.profile.autoshotbarg2, HunterBiuBiu.db.profile.autoshotbarb2 end,
--           set = function(r, g, b) HunterBiuBiu.db.profile.autoshotbarr2 = r; HunterBiuBiu.db.profile.autoshotbarg2 = g; HunterBiuBiu.db.profile.autoshotbarb2 = b; self:UpdateAutoshotBarColor() end,
--           order = 10
--         },
--         restoreauto = {
--           type = "toggle",
--           name = L["Restore Autoshot"],
--           desc = L["Restore Autoshot"],
--           get = function() return HunterBiuBiu.db.profile.restoreauto end,
--           set = function() HunterBiuBiu.db.profile.restoreauto = not HunterBiuBiu.db.profile.restoreauto end,
--           order = 12
--         },
--         resetautoshotbar = {
--           type = "execute",
--           name = L["Reset AutoshotBar"],
--           desc = L["Reset AutoshotBar"],
--           func = function() self:ResetAutoshotBar() end,
--           order = 13
--         },
--         feigndeath = {
--           type = "group",
--           name = L["Feign Death"],
--           desc = L["Feign Death"],
--           usage = L["Feign Death"],
--           args = {
--             stat = {
--               type = "toggle",
--               name = L["On"],
--               desc = L["On"],
--               get = function() return HunterBiuBiu.db.profile.feigndeathon end,
--               set = function() HunterBiuBiu.db.profile.feigndeathon = not HunterBiuBiu.db.profile.feigndeathon end,
--               order = 1
--             },
--             alarm = {
--               type = "toggle",
--               name = L["Feign Death Alarm"],
--               desc = L["Feign Death Alarm"],
--               get = function() return HunterBiuBiu.db.profile.feigndeathalarm end,
--               set = function() HunterBiuBiu.db.profile.feigndeathalarm = not HunterBiuBiu.db.profile.feigndeathalarm end,
--               order = 2
--             },
--             delay = {
--               type = "range",
--               name = L["Feign Death Delay"],
--               desc = L["Feign Death Delay"],
--               min = 0.5,
--               max = 5,
--               step = 0.5,
--               get = function() return HunterBiuBiu.db.profile.feigndeathdelay end,
--               set = function(v) HunterBiuBiu.db.profile.feigndeathdelay = v end,
--               order = 3
--             },
--             mask = {
--               type = "toggle",
--               name = L["Feign Death Mask"],
--               desc = L["Feign Death Mask"],
--               get = function() return HunterBiuBiu.db.profile.feigndeathmask end,
--               set = function() HunterBiuBiu.db.profile.feigndeathmask = not HunterBiuBiu.db.profile.feigndeathmask end,
--               order = 4
--             },
--             color = {
--               type = 'color',
--               name = L["Feign Death Color"],
--               desc = L["Feign Death Color"],
--               get = function() return HunterBiuBiu.db.profile.feigndeathr, HunterBiuBiu.db.profile.feigndeathg, HunterBiuBiu.db.profile.feigndeathb end,
--               set = function(r, g, b) HunterBiuBiu.db.profile.feigndeathr = r; HunterBiuBiu.db.profile.feigndeathg = g; HunterBiuBiu.db.profile.feigndeathb = b; self:UpdateFeignDeathSetting() end,
--               order = 5
--             },
--             alpha = {
--               type = "range",
--               min = 0,
--               max = 1,
--               step = 0.05,
--               name = L["Feign Death Alpha"],
--               desc = L["Feign Death Alpha"],
--               get = function() return HunterBiuBiu.db.profile.feigndeatha end,
--               set = function(v) HunterBiuBiu.db.profile.feigndeatha = v; self:UpdateFeignDeathSetting() end,
--               order = 6
--             },
--             text = {
--               type = "text",
--               name = L["Feign Death Text"],
--               desc = L["Feign Death Text"],
--               usage = L["Feign Death Text"],
--               get = function() return HunterBiuBiu.db.profile.feigndeathtext end,
--               set = function(v) HunterBiuBiu.db.profile.feigndeathtext = v; self:UpdateFeignDeathSetting() end,
--               order = 7
--             },
--             textsize = {
--               type = "range",
--               min = 12,
--               max = 24,
--               step = 1,
--               name = L["Feign Death Text Size"],
--               desc = L["Feign Death Text Size"],
--               get = function() return HunterBiuBiu.db.profile.feigndeathfontsize end,
--               set = function(v) HunterBiuBiu.db.profile.feigndeathfontsize = v; self:UpdateFeignDeathSetting() end,
--               order = 8
--             },
--             textcolor = {
--               type = 'color',
--               name = L["Feign Death Text Color"],
--               desc = L["Feign Death Text Color"],
--               get = function() return HunterBiuBiu.db.profile.feigndeathtextr, HunterBiuBiu.db.profile.feigndeathtextg, HunterBiuBiu.db.profile.feigndeathtextb end,
--               set = function(r, g, b) HunterBiuBiu.db.profile.feigndeathtextr = r; HunterBiuBiu.db.profile.feigndeathtextg = g; HunterBiuBiu.db.profile.feigndeathtextb = b; self:UpdateFeignDeathSetting() end,
--               order = 9
--             },
--             x = {
--               type = "text",
--               name = L["Feign Death X"],
--               desc = L["Feign Death X"],
--               usage = L["Feign Death X"],
--               get = function() return HunterBiuBiu.db.profile.feigndeathx end,
--               set = function(v) if tonumber(v) then HunterBiuBiu.db.profile.feigndeathx = v; self:UpdateFeignDeathSetting() end end,
--               order = 10
--             },
--             y = {
--               type = "text",
--               name = L["Feign Death Y"],
--               desc = L["Feign Death Y"],
--               usage = L["Feign Death Y"],
--               get = function() return HunterBiuBiu.db.profile.feigndeathy end,
--               set = function(v) if tonumber(v) then HunterBiuBiu.db.profile.feigndeathy = v; self:UpdateFeignDeathSetting() end end,
--               order = 11
--             },
--             preview = {
--               type = "execute",
--               name = L["Feign Death Preview"],
--               desc = L["Feign Death Preview"],
--               func = function() self:FeignDeathFailed() end,
--               order = 12
--             },
--             -- preview = {
--             -- 	type = "execute",
--             -- 	name = "配置",
--             -- 	desc = "配置",
--             -- 	func = function() HbbConfigFrame:Show() end,
--             -- 	order = 13
--             -- }
--           }
--         }
--       }
--     },
--     optimizesec = {
--       type = "toggle",
--       name = L["OptimizeSecondCast"],
--       desc = L["OptimizeSecondCast"],
--       get = function() return HunterBiuBiu.db.profile.optimizeSec end,
--       set = function() HunterBiuBiu.db.profile.optimizeSec = not HunterBiuBiu.db.profile.optimizeSec end
--     },
--     reset = {
--       type = "execute",
--       name = L["Reset Settings"],
--       desc = L["Reset Settings"],
--       func = function() StaticPopup_Show("RESET_HBB_PROFILE"); end,
--       order = 13,
--     }
--   }
-- }
