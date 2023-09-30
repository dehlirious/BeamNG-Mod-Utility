# This script processes mods for the game BeamNG.drive, converting mod information to HTML format.
# It also cleans up certain unwanted files from the mod directory.

# Define paths and initialize counters
$modPath = "G:\beamng\0.30\mods\Unshamed"
$modsFound = @()
$jsonErrorCount = 0
$jsonConfigErrorCount = 0
$processedCount = 0

<#
.SYNOPSIS
Converts BBCode to HTML format.

.DESCRIPTION
This function takes a string containing BBCode and converts it to its equivalent HTML format.

.PARAMETER content
The string containing BBCode.

.OUTPUTS
String. The converted HTML content.
#>
function Convert-BBCodeToHTML {
    param([string]$content)

    # Remove all [ATTACH=full]xxxxx[/ATTACH] patterns
    $content = $content -replace '\[ATTACH=full\]\d+\[/ATTACH\]', ''
    $content = $content -replace '\[ATTACH\]\d+\[/ATTACH\]', ''

    # Convert BBCode to HTML
    $content = $content -replace '\[B\]', '<strong>' -replace '\[/B\]', '</strong>'
    $content = $content -replace '\[I\]', '<em>' -replace '\[/I\]', '</em>'
    $content = $content -replace '\[U\]', '<u>' -replace '\[/U\]', '</u>'
    $content = $content -replace '\[URL=(.*?)\]', '<a href="$1">' -replace '\[/URL\]', '</a>'
    $content = $content -replace '\[LIST\]', '<ul>' -replace '\[/LIST\]', '</ul>'
    $content = $content -replace '\[\*\]', '<li>' -replace '\[/*\*\]', '</li>'
    $content = $content -replace '\[COLOR=(.*?)\]', '<span style="color:$1">' -replace '\[/COLOR\]', '</span>'
    
    # Convert other BBCodes like [CENTER], [SIZE], [LEFT], [SPOILER], etc.
    $content = $content -replace '\[CENTER\]', '<div style="text-align:center;">' -replace '\[/CENTER\]', '</div>'
    $content = $content -replace '\[RIGHT\]', '<div style="text-align:right;">' -replace '\[/RIGHT\]', '</div>'
    $content = $content -replace '\[LEFT\]', '<div style="text-align:left;">' -replace '\[/LEFT\]', '</div>'
    $content = $content -replace '\[SIZE=(\d+)\]', '<span style="font-size:$1px;">' -replace '\[/SIZE\]', '</span>'
    $content = $content -replace '\[SPOILER="(.*?)"\]', '<details><summary>$1</summary>' -replace '\[/SPOILER\]', '</details>'
    
    # Convert newlines to <br>
    $content = $content -replace "`n", '<br>'

    return $content
}

<#
.SYNOPSIS
Generates HTML content for a mod.

.DESCRIPTION
This function takes a mod object and generates its HTML representation.

.PARAMETER mod
The mod object containing details about the mod.

.PARAMETER includeConfigurations
A boolean indicating whether to include configurations in the HTML.

.OUTPUTS
String. The generated HTML content for the mod.
#>
function GenerateModHTML {
    param ([PSCustomObject]$mod, [bool]$includeConfigurations = $false)

    $modHtml = @"
<div class='mod-card'>
    <div class='title'>$($mod.Name)</div>
    <img src='file:///$($mod.Icon)' alt='$($mod.Name)'>
"@

    if ($mod.TagLine) {
        $modHtml += "<div class='tagline'>$($mod.TagLine)</div>"
    }

    if ($mod.Message) {
        $convertedMessage = Convert-BBCodeToHTML $mod.Message
        $modHtml += "<!--<div class='message'>$convertedMessage</div>-->"
    }

    if ($includeConfigurations) {
        foreach ($config in $mod.Configurations) {
            $modHtml += "<img src='file:///$($config.Image)' alt='$($config.Name)'>"
            
			$infoPath = Join-Path (Split-Path $config.Image -Parent) ("info_" + ($config.Name -replace "\.pc$", "") + ".json")

			if (Test-Path $infoPath) {
				$pythonOutput = python json_parser.py $infoPath | ConvertFrom-Json

				if ($pythonOutput.error) {
					Write-Warning "CONFIG: Invalid JSON content detected in $infoPath. Error: $($pythonOutput.error). Skipping extraction."
					$jsonConfigErrorCount++
				} elseif ($pythonOutput.Power) {
					$modHtml += "<div class='power'>Power: $($pythonOutput.Power) HP</div>"
				}
			}

        }
    }
	if ($mod.VehicleMods.Count -gt 0) {
        $modHtml += "<select class='mod-dropdown'>"
        $modHtml += "<option value=''>Select Mod</option>"
        foreach ($vehicleMod in $mod.VehicleMods ) {
            $modHtml += "<option value='$($vehicleMod.ModFile)'>$($vehicleMod.ModCategory)</option>"
        }
        $modHtml += "</select>"
    }
    $modHtml += "</div>"
    return $modHtml
}

<#
.SYNOPSIS
Processes each mod directory and gathers information about the mods.

.DESCRIPTION
This function iterates through each subdirectory in the specified mod path, extracts relevant information about the mods, and returns a list of processed mods.

.PARAMETER modPath
The path to the directory containing the mods.

.OUTPUTS
ArrayList(modsFound). A list of processed mods with their details.
#>
# Iterate through each subdirectory in the modPath
Get-ChildItem -Path $modPath -Directory | ForEach-Object {
    $modName = $_.Name
    $modInfoPath = Join-Path $_.FullName "mod_info"
    $vehiclesPath = Join-Path $_.FullName "vehicles"

    # Check for the icon
    $iconPath = Get-ChildItem -Path $modInfoPath -File -Recurse | Where-Object { $_.Name -eq "icon.jpg" }
	if (-not $iconPath) {
		$iconPath = Get-ChildItem -Path $modInfoPath -File -Recurse | Where-Object { $_.Name -eq "icon.png" }
	}

	# Check for the icon in the vehicles folder and immediate child folders
	if (-not $iconPath) {
		$iconPath = Get-ChildItem -Path $vehiclesPath -File -Recurse | Where-Object { $_.Name -eq "icon.jpg" }
		if (-not $iconPath) {
			$iconPath = Get-ChildItem -Path $vehiclesPath -File -Recurse | Where-Object { $_.Name -eq "icon.png" }
		}
	}

	# If still not found, check for .png/.jpg files in 1-level deep child folders of vehicles
	#if (-not $iconPath) {
	#	$iconPath = Get-ChildItem -Path $vehiclesPath -Directory | ForEach-Object {
	#		$childIcon = Get-ChildItem -Path $_.FullName -File | Where-Object { $_.Extension -in @(".jpg", ".png") } | Select-Object -First 1
	#		if ($childIcon) {
	#			$childIcon.FullName
	#		}
	#	}
	#}
	
    $processedCount++
    $hasLua = Test-Path (Join-Path $_.FullName "lua")
    $hasCommon = Test-Path (Join-Path $_.FullName "common")
    $hasUI = (Test-Path (Join-Path $_.FullName "ui")) -or (Test-Path (Join-Path $_.FullName "art"))

	# Mod Type (Default to Other)
	$modType = "Other"

	# Determine if it's a map
	if (Test-Path (Join-Path $_.FullName "levels")) {
		$modType = "Map"
	}
	# Determine if it's a UI app
	elseif ((Test-Path (Join-Path $_.FullName "ui")) -and (-not (Test-Path $vehiclesPath))) {
		$modType = "UIApp"
	}
	# Check for vehicle mod by examining the common directory for jbeam files
	elseif ((Test-Path (Join-Path $_.FullName "vehicles\common")) -and 
			(Get-ChildItem -Path (Join-Path $_.FullName "vehicles\common") -File -Recurse | Where-Object { $_.Extension -eq ".jbeam" })) {
		$modType = "VehicleMod"
	}
    # Vehicle configurations
    $configurations = @()
    if (Test-Path $vehiclesPath) {
        $jbeamFiles = Get-ChildItem -Path $vehiclesPath -File -Recurse | Where-Object { $_.Extension -eq ".jbeam" }
        if ($jbeamFiles) {
            $modType = "VehicleMod"
        }
        $pcFiles = Get-ChildItem -Path $vehiclesPath -File -Recurse | Where-Object { $_.Extension -eq ".pc" }
        foreach ($file in $pcFiles) {
            $configName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            $configImgPath = Join-Path $file.DirectoryName "$configName.jpg"
            if (-not (Test-Path $configImgPath)) {
                $configImgPath = Join-Path $file.DirectoryName "$configName.png"
            }
            if (Test-Path $configImgPath) {
                $configurations += @{
                    Name = $configName
                    Image = $configImgPath
                }
            }
        }
    }

    # Determine if it's a map
    if ((Test-Path (Join-Path $_.FullName "levels")) -and (-not $configurations)) {
        $modType = "Map"
    }

	# Extract the relevant information from the info.json files.
	$infoJsonPath = Join-Path $_.FullName "mod_info\info.json"

	if (Test-Path $infoJsonPath) {
		$pythonOutput = python json_parser.py $infoJsonPath | ConvertFrom-Json

		if ($pythonOutput.error) {
			Write-Warning "Invalid JSON content detected in $infoJsonPath. Error: $($pythonOutput.error). Skipping extraction."
			$jsonErrorCount++
		} else {
			$title = $pythonOutput.title
			$tagLine = $pythonOutput.tag_line
			$message = $pythonOutput.message
		}
	}

	
	$vehicleMods = @()
	if (Test-Path (Join-Path $_.FullName "vehicles\common")) {
		$modDirs = Get-ChildItem -Path (Join-Path $_.FullName "vehicles\common") -Directory
		foreach ($dir in $modDirs) {
			# Use the parent directory's name as the mod name
			$modName = Split-Path $_.FullName -Leaf
			$modFiles = Get-ChildItem -Path $dir.FullName -File -Recurse | Where-Object { $_.Extension -eq ".jbeam" }
			foreach ($file in $modFiles) {
				$vehicleMods += @{
					ModCategory = $modName
					ModFile     = $file.FullName
				}
			}
		}
	}
	#GenerateModHTML -mod $mod -includeConfigurations ($category.IncludeConfigurations -eq $true)
	Write-Host "Processed mod: $($modName)"
	#if ($iconPath) {
	#	Write-Host  "icon found.";
		$modsFound += @{
			Name          = $modName
			Icon          = $iconPath.FullName
			HasLua        = $hasLua
			HasCommon     = $hasCommon
			HasUI         = $hasUI
			Configurations= $configurations
			ModType       = $modType
			Title         = $title
			TagLine       = $tagLine
			Message       = $message
			VehicleMods   = $vehicleMods
		}
	#}
}

Write-Host "Total processed mods: $($processedCount)"


<#
.SYNOPSIS
Removes unwanted files from the mod directory.

.DESCRIPTION
This function searches for and removes specific unwanted files from the mod directory

.PARAMETER modPath
The path to the directory containing the mods.
#>
# The code for file deletion and HTML generation will come next.
# Search for and delete "! ModsBag.com !!!.txt"
Get-ChildItem -Path $modPath -File -Recurse | Where-Object { $_.Name -eq "! ModsBag.com !!!.txt" } | ForEach-Object {
    Remove-Item $_.FullName -Force
}

# Search for "read me.txt" files with the specific content and delete them
Get-ChildItem -Path $modPath -File -Recurse | Where-Object { $_.Name -eq "read me.txt" } | ForEach-Object {
    $content = Get-Content $_.FullName
    if ($content -like "*Dear fellow modder, if you see the hood jbeam has a bracket turned backwars, i know, its because the hoodstack i was working on, i didnt complete it, if you want to help, dm me on discord @Limitless Pain#5631, thanks in advance!*") {
        Remove-Item $_.FullName -Force
    }
}

<#
.SYNOPSIS
Generates the complete HTML content for a list of mods.

.DESCRIPTION
This function takes a list of mod objects and generates the complete HTML representation, including headers, styles, and individual mod details.

.PARAMETER mods
An array of mod objects containing details about each mod.

.OUTPUTS
String. The complete generated HTML content for the list of mods.
#>
function GenerateHTML {
    param ([System.Collections.ArrayList]$mods)

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Mods List</title>
    <style>
        body {
            display: flex;
            flex-wrap: wrap;
            justify-content: start;
            gap: 10px;
            padding: 20px;
        }
		
		.mod-dropdown {
			width: 100%;
			margin-bottom: 10px;
		}
		
        .mod-card {
            width: 150px;
            border: 1px solid #ccc;
            padding: 10px;
            box-shadow: 2px 2px 8px rgba(0, 0, 0, 0.1);
            max-height: 56vh;
            overflow-y: auto;
        }

        img {
            width: 100%;
            margin-bottom: 10px;
        }

        .title {
            font-weight: bold;
            margin-bottom: 10px;
        }

        .separator {
            width: 100%;
            height: 2px;
            background: #333;
            margin: 20px 0;
        }
    </style>
</head>
<body>
"@
$modsFoundForCategory = ($modsFound).Count
#$html += "<div>Total Mods Found: $($modsFound.Count + $jsonErrorCount) - $modsFoundForCategory | $jsonErrorCount | $jsonConfigErrorCount </div>"

     # Categories to process with the type and label
    $categories = @(
        @{ Type = "Map"; Label = "Maps" },
        @{ Type = "UIApp"; Label = "UI Apps" },
        @{ Type = "VehicleConfig"; Label = "Vehicles with Configurations"; IncludeConfigurations = $true },
		@{ Type = "VehicleMod"; Label = "Vehicles with Mods"; IncludeConfigurations = $true; IncludeMods = $true },
        @{ Type = "Other"; Label = "Other Mods" }
    )

    # Create a list of mod names that have vehicle mods:
    $vehicleModNames = $mods | Where-Object { $_.VehicleMods.Count -gt 0 } | ForEach-Object { $_.Name }

	foreach ($category in $categories) {
		$html += "<h2>$($category.Label)</h2>"

		if ($category.Type -eq "VehicleConfig") {
			# Exclude configurations that match any mods from the VehicleMod category:
			$vehicleModConfigs = ($mods | Where-Object { $_.VehicleMods.Count -gt 0 }).Configurations.Name
			$modsToProcess = $mods | Where-Object { $_.Configurations.Count -gt 0 -and ($_.Configurations.Name -notin $vehicleModConfigs) }
		}
		elseif ($category.Type -eq "VehicleMod") {
			$modsToProcess = $mods | Where-Object { $_.VehicleMods.Count -gt 0 }
		}
		else {
			$modsToProcess = $mods | Where-Object { $_.ModType -eq $category.Type }
		}
		$modsCountForCategory = ($modsToProcess).Count
		
		$html += "<div>Mods Displayed for $($category.Label): $modsCountForCategory</div><br/>"
		
		foreach ($mod in $modsToProcess) {
			$html += GenerateModHTML -mod $mod -includeConfigurations ($category.IncludeConfigurations -eq $true)
		}
		
		$html += "<div class='separator'></div>"
	}

    $html += @"
</body>
</html>
"@
    return $html
}

# Generate and display the HTML
$htmlContent = GenerateHTML -mods $modsFound
$htmlFile = Join-Path $modPath "modsList.html"
$htmlContent | Out-File $htmlFile
Start-Process $htmlFile