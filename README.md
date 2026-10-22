# Reaper Clip Exporter

A Lua script for preparing audio clips in REAPER using **Dynamic Split, fades, and numbered regions**. Designed to simplify repetitive editing tasks when organizing sound effects, variations, and other clips for rendering.

**Script:** `joseisaudio_clipExporter.lua`

> This version prepares items and creates regions. It does not automatically render or export audio files.

## Features

- Opens REAPER's native **Dynamic Split** window to configure and preview cuts.
- Applies fade-ins and fade-outs to selected items.
- Provides independent fade duration sliders ranging from **0 to 2000 ms**.
- Offers seven shape options for each fade.
- Creates optional regions with a base name and automatic numbering: `SFX_01`, `SFX_02`, etc.
- Groups fade application and region creation into a single undo operation.

## Requirements

- REAPER with Lua ReaScript support.
- The `joseisaudio_clipExporter.lua` file.

The script uses REAPER's built-in APIs and `gfx` interface. SWS, ReaPack, ReaImGui, and a separate Lua installation are not required.

## Installation

1. Download `joseisaudio_clipExporter.lua` and save it in a permanent location.
2. In REAPER, open **Actions → Show action list…**.
3. In the **Main** section, use **ReaScript → Load…** to load the file.
4. Select the script in the action list and click **Run**.

You can assign a keyboard shortcut from the action list.

## Usage

### 1. Prepare and split items

1. Select the audio items you want to process.
2. Run the script.
3. Click **OPEN DYNAMIC SPLIT**.
4. Adjust the Dynamic Split settings and review the cut preview.
5. Execute the split in that window, then return to the script.

Trimming or splitting is configured and performed within Dynamic Split. The script opens the tool; it does not configure its parameters or automatically verify the result.

### 2. Configure fades

Choose a shape under **Fade in shape** and **Fade out shape**, then adjust their durations using the sliders.

| Control | Default | Range |
| --- | --- | --- |
| Fade in duration | 50 ms | 0–2000 ms |
| Fade out duration | 50 ms | 0–2000 ms |
| Fade-in and fade-out shapes | Linear | Seven options |

The labels displayed by the script are **Linear, Fast Start, Fast End, S-Curve, Bezier, Logarithmic, and Exponential**.

### 3. Create regions and apply

1. Enable **Create regions after Dynamic Split** if you want to create regions.
2. Enter a **Base region name**, such as `Footstep_Concrete`.
3. Verify that the items you want to process are selected.
4. Click **APPLY FADES / REGIONS**.

For three items with different start positions, this example produces:

```text
Footstep_Concrete_01
Footstep_Concrete_02
Footstep_Concrete_03
```

Each region starts at its item's position and ends at the end of that item's duration. The status message reports how many items were processed and how many regions were created.

You can also use **APPLY FADES / REGIONS** directly on previously edited clips without opening Dynamic Split.

### 4. Render audio

To produce audio files, use REAPER's rendering tools afterward and configure the regions, audio sources, and output settings you need. This script does not configure rendering or the Region Render Matrix.

## Behavior and limitations

- **Current selection:** the apply button processes the items selected at that moment. It does not preserve the initial selection from when Dynamic Split was opened.
- **Existing fades:** applying overwrites the selected items' manual fade durations and shapes. There is no option to skip this step.
- **Simultaneous items:** if multiple items start less than 0.0001 seconds apart, only one region is created for that start position. Its duration comes from the first item processed, which may not be the longest.
- **Repeated runs:** numbering restarts at `01` each time you apply. Existing regions are not checked, so applying again may create duplicate regions and names.
- **Names:** an empty or whitespace-only base name prevents region creation. The field accepts up to 80 printable ASCII characters; accented letters and other Unicode characters are not supported.
- **Temporary settings:** preferences return to their defaults when you close and rerun the script.
- **Name editing:** the field supports typing at the end and deleting with Backspace. Enter ends editing, and Esc closes the window.
- **Undo:** each application of fades and regions is grouped into one undo block. The operation performed in Dynamic Split is handled separately.

## Troubleshooting

| Situation | What to check |
| --- | --- |
| Dynamic Split does not open from the script | Select at least one item before clicking the button. |
| “No items are selected after Dynamic Split.” appears | Select the resulting clips and apply again. This message can also appear if you have not used Dynamic Split. |
| No regions are created | Check that the checkbox is enabled and the base name is not empty. |
| There are fewer regions than selected items | Check whether multiple items share the same start position. |
| No exported audio files appear | Render the audio separately in REAPER. |

## About this documentation

This README describes the behavior implemented in the supplied script. It does not establish a verified minimum REAPER version or certify tested compatibility with specific operating systems.
