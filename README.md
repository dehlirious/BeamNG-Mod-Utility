# BeamNG Mod Processing Script

This script is designed to process mods for BeamNG, extracting relevant information, converting BBCode to HTML, and generating an HTML representation of the mods.

## Features

- **BBCode to HTML Conversion**: Converts BBCode content in mod descriptions to HTML format.
- **Mod Information Extraction**: Extracts details such as mod name, icon, type, configurations, and more.
- **HTML Generation**: Generates an HTML file that provides a visual representation of the mods.
- **Unwanted File Removal**: Removes specific unwanted files from the mod directory.
- **JSON Parser**: Using python, json can be parsed in such a way to remove most json syntax errors that occur when trying to handle beamng .json files in PowerShell.

## Demos

### Console Output


### Generated HTML Page

## Why?

Sick of having mods that dont have icons, or that have a completely different name in game than the zip causing me to not be able to find the mod.
Why powershell? No real reason, might switch eventually considering I already have to use python to parse the json.
This script may or may not be maintained. 

## Usage

1. Clone the repository or download the script.
2. Modify the `$modPath` variable in the script to point to your BeamNG mods directory.
3. Run the script using PowerShell.

```powershell
.\script.ps1

