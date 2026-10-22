-- Reaper Clip Exporter
--
-- Integrated workflow:
--   1. Open REAPER's native Dynamic Split so the user can adjust the
--      threshold/fader and preview the cuts in real time.
--   2. After clicking Split, apply fades and optionally create regions.
--
-- The native Dynamic Split is used instead of a custom peak analysis so its
-- exact UI, preview and behavior are preserved.

local SCRIPT_NAME = "Reaper Clip Exporter"
local WINDOW_TITLE = SCRIPT_NAME .. " - Dynamic Split / Fades / Regions"
local WINDOW_W, WINDOW_H = 620, 735
local DYNAMIC_SPLIT_COMMAND = 40760 -- Item: Dynamic split items...
local FADE_MAX_MS = 2000

local shapes = {
  { label = "Linear",      id = 0 },
  { label = "Fast Start",  id = 1 },
  { label = "Fast End",    id = 2 },
  { label = "S-Curve",     id = 3 },
  { label = "Bezier",      id = 4 },
  { label = "Logarithmic", id = 5 },
  { label = "Exponential", id = 6 }
}

local state = {
  regions_enabled = true,
  region_name = "SFX",
  fade_in_ms = 50,
  fade_out_ms = 50,
  fade_in_shape = 1,
  fade_out_shape = 1,
  split_started = false,
  status = "Select items and open Dynamic Split."
}

local active_field = nil
local active_slider = nil
local mouse_was_down = false

local fields = {
  { key = "region_name", label = "Base region name", x = 25, y = 570, w = 545 }
}

local function number(key, default)
  return tonumber(state[key]) or default
end

local function rect_hit(x, y, w, h)
  return gfx.mouse_x >= x and gfx.mouse_x <= x + w and
         gfx.mouse_y >= y and gfx.mouse_y <= y + h
end

local function draw_text(text, x, y, size, r, g, b)
  gfx.setfont(1, "Arial", size or 13)
  gfx.set(r or 0.9, g or 0.9, b or 0.9, 1)
  gfx.x, gfx.y = x, y
  gfx.drawstr(text)
end

local function draw_section_title(text, x, y)
  draw_text(text, x, y, 14, 0.3, 0.75, 1)
end

local function draw_button(text, x, y, w, h, enabled, green)
  local hover = enabled and rect_hit(x, y, w, h)
  if not enabled then
    gfx.set(0.12, 0.12, 0.12, 1)
  elseif green then
    gfx.set(hover and 0.18 or 0.11, hover and 0.68 or 0.50,
            hover and 0.32 or 0.23, 1)
  else
    gfx.set(hover and 0.22 or 0.15, hover and 0.48 or 0.34,
            hover and 0.72 or 0.55, 1)
  end
  gfx.rect(x, y, w, h, 1)
  local text_color = enabled and 1 or 0.45
  gfx.setfont(1, "Arial", 13)
  local text_width = gfx.measurestr(text)
  draw_text(text, x + (w - text_width) / 2, y + (h - 15) / 2, 13,
            text_color, text_color, text_color)
  return enabled and hover
end

local function draw_checkbox(x, y, checked, label)
  gfx.set(checked and 0.2 or 0.12, checked and 0.55 or 0.12,
          checked and 0.3 or 0.12, 1)
  gfx.rect(x, y, 18, 18, 1)
  if checked then draw_text("X", x + 4, y + 1, 13, 1, 1, 1) end
  draw_text(label, x + 28, y + 2, 13, 0.85, 0.85, 0.85)
end

local function draw_field(field)
  draw_text(field.label, field.x, field.y - 20, 12, 0.7, 0.7, 0.7)
  local active = active_field == field.key
  gfx.set(active and 0.15 or 0.09, active and 0.32 or 0.09,
          active and 0.48 or 0.09, 1)
  gfx.rect(field.x, field.y, field.w, 29, 1)
  draw_text(state[field.key] .. (active and "|" or ""),
            field.x + 8, field.y + 7, 13, 1, 1, 1)
end

local function draw_slider(label, key, x, y, w)
  local value = number(key, 0)
  local ratio = math.max(0, math.min(1, value / FADE_MAX_MS))
  local track_y = y + 22

  draw_text(label, x, y, 12, 0.7, 0.7, 0.7)
  local value_text = string.format("%d ms", value)
  local value_width = gfx.measurestr(value_text)
  draw_text(value_text, x + w - value_width, y, 12, 0.95, 0.95, 0.95)

  gfx.set(0.18, 0.18, 0.18, 1)
  gfx.rect(x, track_y, w, 7, 1)
  gfx.set(0.22, 0.55, 0.82, 1)
  gfx.rect(x, track_y, w * ratio, 7, 1)
  gfx.set(0.9, 0.9, 0.9, 1)
  gfx.circle(x + w * ratio, track_y + 3.5, 9, 1)
  draw_text("0", x, y + 36, 10, 0.5, 0.5, 0.5)
  local max_text = string.format("%d ms", FADE_MAX_MS)
  draw_text(max_text, x + w - gfx.measurestr(max_text), y + 36, 10, 0.5, 0.5, 0.5)
end

local function set_slider_from_mouse(key, x, w)
  local ratio = math.max(0, math.min(1, (gfx.mouse_x - x) / w))
  state[key] = math.floor(ratio * FADE_MAX_MS + 0.5)
end

local function draw_shape_list(title, x, y, selected)
  draw_text(title, x, y, 12, 0.7, 0.7, 0.7)
  for i, shape in ipairs(shapes) do
    local by = y + 22 + (i - 1) * 24
    local hover = rect_hit(x, by, 220, 21)
    if selected == i then
      gfx.set(0.18, 0.45, 0.72, 1)
    elseif hover then
      gfx.set(0.22, 0.22, 0.22, 1)
    else
      gfx.set(0.12, 0.12, 0.12, 1)
    end
    gfx.rect(x, by, 220, 21, 1)
    draw_text(shape.label, x + 8, by + 3, 12, 0.95, 0.95, 0.95)
  end
end

local function collect_selected_items()
  local items = {}
  for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
    items[#items + 1] = reaper.GetSelectedMediaItem(0, i)
  end
  return items
end

local function apply_fades(items)
  local in_seconds = math.max(0, number("fade_in_ms", 0)) / 1000
  local out_seconds = math.max(0, number("fade_out_ms", 0)) / 1000
  local processed = 0

  for _, item in ipairs(items) do
    reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", in_seconds)
    reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", out_seconds)
    reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", shapes[state.fade_in_shape].id)
    reaper.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", shapes[state.fade_out_shape].id)
    reaper.UpdateItemInProject(item)
    processed = processed + 1
  end
  return processed
end

local function create_regions(items)
  local base = state.region_name:gsub("^%s+", ""):gsub("%s+$", "")
  if base == "" then return 0 end

  local processed_positions = {}
  local region_index = 1
  for _, item in ipairs(items) do
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local duplicate = false
    for _, previous_pos in ipairs(processed_positions) do
      if math.abs(previous_pos - item_pos) < 0.0001 then
        duplicate = true
        break
      end
    end

    if not duplicate then
      local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      local region_name = string.format("%s_%02d", base, region_index)
      reaper.AddProjectMarker2(0, true, item_pos, item_pos + item_length,
                               region_name, -1, 0)
      processed_positions[#processed_positions + 1] = item_pos
      region_index = region_index + 1
    end
  end
  return region_index - 1
end

local function apply_post_split()
  local items = collect_selected_items()
  if #items == 0 then
  state.status = "No items are selected after Dynamic Split."
    return
  end

  reaper.Undo_BeginBlock()
  local faded = apply_fades(items)
  local regions = state.regions_enabled and create_regions(items) or 0
  reaper.UpdateArrange()
  reaper.Undo_EndBlock(SCRIPT_NAME .. " - fades and regions", -1)

  state.split_started = false
  state.status = string.format("Done: %d items processed, %d regions created.",
                               faded, regions)
end

local function open_dynamic_split()
  local items = collect_selected_items()
  if #items == 0 then
    state.status = "Error: select at least one item before opening Dynamic Split."
    return
  end

  state.split_started = true
  state.status = "Adjust the fader and preview in Dynamic Split, click Split, then apply fades and regions."
  -- Native REAPER action: waveform, threshold/fader and real-time preview.
  reaper.Main_OnCommand(DYNAMIC_SPLIT_COMMAND, 0)
end

local function handle_keyboard(char)
  if not active_field or char <= 0 then return end
  local value = state[active_field]
  if char == 8 then
    state[active_field] = value:sub(1, -2)
  elseif char == 13 then
    active_field = nil
  elseif char >= 32 and char <= 126 then
    if #value < 80 then state[active_field] = value .. string.char(char) end
  end
end

local function main()
  local char = gfx.getchar()
  if char < 0 or char == 27 then
    gfx.quit()
    return
  end
  handle_keyboard(char)

  local mouse_down = (gfx.mouse_cap & 1) == 1
  local click = mouse_down and not mouse_was_down
  mouse_was_down = mouse_down

  gfx.set(0.09, 0.09, 0.09, 1)
  gfx.rect(0, 0, WINDOW_W, WINDOW_H, 1)

  draw_text("Reaper Clip Exporter", 25, 18, 21, 0.95, 0.95, 0.95)
  draw_text("Native Dynamic Split + fades + regions", 25, 47, 12, 0.65, 0.65, 0.65)

  draw_section_title("1. TRIM / DYNAMIC SPLIT", 25, 82)
  draw_text("Adjust the threshold and preview the cuts in real time in REAPER's native window.",
            25, 108, 12, 0.72, 0.72, 0.72)
  local split_button = draw_button("OPEN DYNAMIC SPLIT", 25, 130, 270, 42, true, false)
  draw_text(state.split_started and "Dynamic Split opened or already used." or
            "After clicking Split, return here and apply the next step.",
            315, 145, 11, 0.75, 0.75, 0.4)

  draw_section_title("2. FADES", 25, 205)
  draw_shape_list("Fade in shape", 25, 230, state.fade_in_shape)
  draw_shape_list("Fade out shape", 320, 230, state.fade_out_shape)
  draw_slider("Fade in duration", "fade_in_ms", 25, 440, 250)
  draw_slider("Fade out duration", "fade_out_ms", 320, 440, 250)

  draw_section_title("3. REGIONS", 25, 515)
  if click and rect_hit(25, 532, 18, 18) then
    state.regions_enabled = not state.regions_enabled
  end
  draw_checkbox(25, 532, state.regions_enabled, "Create regions after Dynamic Split")
  draw_field(fields[1])

  local apply_button = draw_button("APPLY FADES / REGIONS", 25, 650, 545, 42, true, true)

  draw_text(state.status, 25, 710, 11, 0.85, 0.75, 0.35)

  if click then
    if split_button then
      active_field = nil
      open_dynamic_split()
    elseif apply_button then
      active_field = nil
      apply_post_split()
    else
      for _, field in ipairs(fields) do
        if rect_hit(field.x, field.y, field.w, 29) then
          active_field = field.key
        end
      end
      for i = 1, #shapes do
        if rect_hit(25, 252 + (i - 1) * 24, 220, 21) then
          state.fade_in_shape = i
        elseif rect_hit(320, 252 + (i - 1) * 24, 220, 21) then
          state.fade_out_shape = i
        end
      end
      if rect_hit(25, 440, 250, 45) then
        active_slider = "fade_in_ms"
        set_slider_from_mouse(active_slider, 25, 250)
      elseif rect_hit(320, 440, 250, 45) then
        active_slider = "fade_out_ms"
        set_slider_from_mouse(active_slider, 320, 250)
      end
    end
  end

  if active_slider then
    if mouse_down then
      local slider_x = active_slider == "fade_in_ms" and 25 or 320
      set_slider_from_mouse(active_slider, slider_x, 250)
    else
      active_slider = nil
    end
  end

  gfx.update()
  reaper.defer(main)
end

gfx.init(WINDOW_TITLE, WINDOW_W, WINDOW_H)
main()
