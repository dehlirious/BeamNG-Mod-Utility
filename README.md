# BeamNG Mod Processing Script

This script is designed to process mods for BeamNG, extracting relevant information, converting BBCode to HTML, and generating an HTML representation of the mods.

## Features

- **Mod Information Extraction**: Extracts details such as mod name, icon, type, configurations, and more.
- **HTML Generation**: Generates an HTML file that provides a visual representation of the mods.
- **Unwanted File Removal**: Removes specific unwanted files from the mod directory.
- **JSON Parser**: Using python, json can be parsed in such a way to remove most json syntax errors that occur when trying to handle beamng .json files in PowerShell.

## Demos


### Console Output
![Animation](https://github.com/dehlirious/BeamNG-Mod-Utility/assets/25449483/a1c25124-9d9e-42fe-b585-47fdf361d36c)

### Generated HTML Page
![Animation23](https://github.com/dehlirious/BeamNG-Mod-Utility/assets/25449483/1250a93f-e81f-49cc-b4e3-44559eea973b)

## Usage

1. Clone the repository or download the script.
2. Modify the `$modPath` variable in the script to point to your BeamNG mods directory.
3. *FOR THE TIME BEING* Extract mods into folders. Will directly add the ability to process .zip files soon!
4. Run the script using PowerShell.

```powershell
.\script.ps1

