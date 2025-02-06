# =============================================================================

# Nessus to POAM Converter

# Author: Shane Trimbur

# Last Updated: January 15, 2025

# =============================================================================

#

# DESCRIPTION:

# This PowerShell script converts Nessus vulnerability scan results (.nessus files) 

# into a Plan of Actions and Milestones (POAM) Excel spreadsheet format.

#

# PREREQUISITES:

# - PowerShell 5.1 or higher

# - Administrator rights (for module installation if ImportExcel is not present)

# - A valid .nessus scan file

#

# USAGE:

# 1. Basic usage with default output filename:

#    .\NessusToPOAM.ps1 -NessusFile "path\to\scan.nessus"

#

# 2. Specify custom output filename:

#    .\NessusToPOAM.ps1 -NessusFile "path\to\scan.nessus" -OutputFile "custom_poam.xlsx"

#

# OUTPUT:

# - Creates an Excel file with formatted POAM data

# - Default filename format: POAM_YYYYMMDD.xlsx

# - Includes risk levels, vulnerability details, and system information

#

# =============================================================================



param(

    [Parameter(Mandatory = $true)]

    [string]$NessusFile,

    

    [Parameter(Mandatory = $false)]

    [string]$OutputFile = "POAM_$(Get-Date -Format 'yyyyMMdd').xlsx"

)



# Check and install required Excel module

if (-not (Get-Module -ListAvailable -Name ImportExcel)) {

    Write-Host "Installing ImportExcel module..."

    Install-Module ImportExcel -Force -Scope CurrentUser

}



# Import the required module

Import-Module ImportExcel



# Function to convert Nessus severity levels to risk levels

function ConvertTo-RiskLevel {

    param([string]$Severity)

    

    switch ($Severity) {

        "1" { return "Low" }

        "2" { return "Moderate" }

        "3" { return "High" }

        "4" { return "Critical" }

        default { return "Unknown" }

    }

}



# Function to extract host IP from Nessus report

function Get-HostIP {

    param($ReportHost)

    

    $ipNode = $ReportHost.SelectSingleNode(".//tag[@name='host-ip']")

    if ($ipNode -ne $null) {

        return $ipNode.InnerText

    }

    return "Unknown IP"

}



# Main function to process Nessus file and extract findings

function Process-NessusFile {

    param([string]$FilePath)

    

    try {

        Write-Host "Reading Nessus file..."

        [xml]$nessusContent = Get-Content -Path $FilePath -Encoding UTF8

        $findings = @()

        $poamId = 1

        

        Write-Host "Processing vulnerability data..."

        foreach ($reportHost in $nessusContent.SelectNodes("//ReportHost")) {

            $hostname = $reportHost.name

            if ([string]::IsNullOrEmpty($hostname)) {

                $hostname = "Unknown Host"

            }

            

            $ip = Get-HostIP -ReportHost $reportHost

            

            # Process each vulnerability finding

            foreach ($item in $reportHost.SelectNodes(".//ReportItem")) {

                # Skip informational findings (severity 0)

                if ($item.severity -eq "0") { continue }

                

                $description = if ($item.description -ne $null) { $item.description } else { "" }

                $solution = if ($item.solution -ne $null) { $item.solution } else { "" }

                

                # Create POAM entry object

                $finding = [PSCustomObject]@{

                    'POAM ID'                      = $poamId

                    'Name'                         = $item.pluginName

                    'Date Identified'              = Get-Date -Format "yyyy-MM-dd"

                    'Source Identifying Weakness'   = "Nessus Scan - Plugin ID: $($item.pluginID)"

                    'POAM Status'                  = "Open"

                    'Calculated Risk Level'        = ConvertTo-RiskLevel -Severity $item.severity

                    'Mitigated Risk Level'         = ""

                    'Estimated Completion Date'    = ""

                    'Actual Start Date'            = Get-Date -Format "yyyy-MM-dd"

                    'Actual Completion Date'       = ""

                    'Vulnerability Library'        = ""

                    'Allocated Control'            = ""

                    'Subjective Mitigated Risk Level' = ""

                    'Weaknesses'                   = $description

                    'Mitigation'                   = $solution

                    'Comments'                     = ""

                    'Affected Hardware'            = "$hostname ($ip)"

                    'Days Open'                    = "0"

                    'Last Updated'                 = Get-Date -Format "yyyy-MM-dd"

                }

                

                $findings += $finding

                $poamId++

            }

        }

        

        Write-Host "Found $($findings.Count) vulnerabilities..."

        return $findings

    }

    catch {

        Write-Error "Failed to process Nessus file. Error: $_"

        exit 1

    }

}



# Main execution block

try {

    Write-Host "Starting Nessus to POAM conversion..."

    

    # Check and remove existing output file

    if (Test-Path $OutputFile) {

        Write-Warning "Output file already exists. It will be overwritten."

        Remove-Item $OutputFile -Force

    }

    

    # Process the Nessus file and get findings

    $findings = Process-NessusFile -FilePath $NessusFile

    if (-not $findings) {

        throw "No findings were processed from the Nessus file"

    }

    

    # Export findings to Excel with formatting

    Write-Host "Exporting to Excel..."

    $excelParams = @{

        Path = $OutputFile

        AutoSize = $true

        AutoFilter = $true

        BoldTopRow = $true

        WorksheetName = "POAM"

        TableStyle = "Medium2"

        FreezeTopRow = $true

    }

    

    $findings | Export-Excel @excelParams

    

    # Apply additional Excel formatting

    $excel = Open-ExcelPackage -Path $OutputFile

    $ws = $excel.Workbook.Worksheets["POAM"]

    

    # Format header with custom styling

    $headerRange = $ws.Dimension.Address -replace "\d+", "1"

    $ws.Row(1).Style.Fill.PatternType = 'Solid'

    $ws.Row(1).Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::FromArgb(54, 96, 146))

    $ws.Row(1).Style.Font.Color.SetColor([System.Drawing.Color]::White)

    

    # Auto-fit columns for better readability

    foreach ($col in 1..$ws.Dimension.Columns) {

        $maxLength = 0

        $colName = [char]([int][char]'A' + $col - 1)

        $ws.Column($col).AutoFit()

    }

    

    Close-ExcelPackage $excel

    

    $fullOutputPath = Join-Path (Resolve-Path .).Path $OutputFile

    Write-Host "POAM spreadsheet created successfully: $fullOutputPath" -ForegroundColor Green

}

catch {

    Write-Error "An error occurred: $_"

    exit 1

}