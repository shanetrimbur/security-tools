# Security Tools Collection

A comprehensive collection of security-focused utilities and scripts designed to streamline and automate common security tasks and assessments.

![PowerShell](https://img.shields.io/badge/PowerShell-%235391FE.svg?style=for-the-badge&logo=powershell&logoColor=white)
![Security](https://img.shields.io/badge/Security-FF1B2D?style=for-the-badge&logo=security&logoColor=white)

## 🛠️ Nessus to POAM Converter

### Overview
This PowerShell script automates the conversion of Nessus vulnerability scan results into a Plan of Actions and Milestones (POAM) Excel spreadsheet. Below is a detailed breakdown of how the script works.

### Script Analysis

#### 1. Script Parameters

### Key Features
- 📊 Converts .nessus XML files to formatted Excel POAM spreadsheets
- 🎯 Intelligent severity-to-risk level mapping
- 📝 Comprehensive vulnerability documentation
- 🖥️ Multi-host support
- ✨ Professional Excel formatting

### Prerequisites
- PowerShell 5.1 or higher
- Administrator rights (for module installation if ImportExcel is not present)
- A valid .nessus scan file

### Quick Start
1. Clone the repository:

```bash
git clone https://github.com/shanetrimbur/security-tools.git
cd security-tools
```

2. Install required PowerShell module:
```powershell
Install-Module ImportExcel -Force -Scope CurrentUser
```

3. Run the script:
```powershell
.\src\nessus-to-poam\nessus_to_POAM.ps1 -NessusFile "path\to\scan.nessus"
```

## 📖 Code Breakdown

Let's walk through each component of the script and understand how it works.

### 1. Script Parameters
```powershell
param(
    [Parameter(Mandatory = $true)]
    [string]$NessusFile,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputFile = "POAM_$(Get-Date -Format 'yyyyMMdd').xlsx"
)
```

This block defines two parameters:
- `$NessusFile`: Required path to your Nessus scan file
- `$OutputFile`: Optional output path, defaults to `POAM_YYYYMMDD.xlsx`

### 2. Module Management
```powershell
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Write-Host "Installing ImportExcel module..."
    Install-Module ImportExcel -Force -Scope CurrentUser
}
Import-Module ImportExcel
```

This section:
- Checks if ImportExcel module exists
- Installs it if missing
- Imports the module for use

### 3. Risk Level Conversion
```powershell
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
```

This function:
- Takes a Nessus severity number (1-4)
- Maps it to human-readable risk levels:
  - 4 → Critical (highest risk)
  - 3 → High
  - 2 → Moderate
  - 1 → Low
  - Other → Unknown

### 4. Host IP Extraction
```powershell
function Get-HostIP {
    param($ReportHost)
    
    $ipNode = $ReportHost.SelectSingleNode(".//tag[@name='host-ip']")
    if ($ipNode -ne $null) {
        return $ipNode.InnerText
    }
    return "Unknown IP"
}
```

This function:
- Takes a ReportHost XML node as input
- Uses XPath to locate the host-ip tag
- Returns the IP address if found
- Falls back to "Unknown IP" if not found

### 5. Core Processing Function
```powershell
function Process-NessusFile {
    param([string]$FilePath)
    
    try {
        [xml]$nessusContent = Get-Content -Path $FilePath -Encoding UTF8
        $findings = @()
        $poamId = 1
```

Initial setup:
- Reads the Nessus file as XML
- Initializes an array for findings
- Sets up a counter for POAM IDs

```powershell
        foreach ($reportHost in $nessusContent.SelectNodes("//ReportHost")) {
            $hostname = $reportHost.name ?? "Unknown Host"
            $ip = Get-HostIP -ReportHost $reportHost
            
            foreach ($item in $reportHost.SelectNodes(".//ReportItem")) {
                if ($item.severity -eq "0") { continue }
```

Host and vulnerability processing:
- Iterates through each host in the scan
- Gets hostname and IP
- Processes each vulnerability
- Skips informational findings (severity 0)

```powershell
                $finding = [PSCustomObject]@{
                    'POAM ID'                      = $poamId
                    'Name'                         = $item.pluginName
                    'Date Identified'              = Get-Date -Format "yyyy-MM-dd"
                    'Source Identifying Weakness'  = "Nessus Scan - Plugin ID: $($item.pluginID)"
                    'POAM Status'                  = "Open"
                    'Calculated Risk Level'        = ConvertTo-RiskLevel -Severity $item.severity
                    # ... additional fields ...
                }
```

Data structure:
- Creates a structured object for each finding
- Includes all required POAM fields
- Maps Nessus data to appropriate fields
- Assigns unique POAM ID

### 6. Excel Generation and Formatting
```powershell
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
```

Excel configuration:
- Sets up professional formatting
- Enables filtering and frozen header
- Applies consistent styling
- Auto-sizes columns for readability

```powershell
$excel = Open-ExcelPackage -Path $OutputFile
$ws = $excel.Workbook.Worksheets["POAM"]

$ws.Row(1).Style.Fill.PatternType = 'Solid'
$ws.Row(1).Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::FromArgb(54, 96, 146))
$ws.Row(1).Style.Font.Color.SetColor([System.Drawing.Color]::White)
```

Visual enhancements:
- Opens the Excel package for additional formatting
- Applies professional color scheme to headers
- Sets white text for contrast

## 📊 Output Format

The generated Excel file includes these columns:
- POAM ID (unique identifier)
- Name (vulnerability title)
- Date Identified
- Source Identifying Weakness
- POAM Status
- Calculated Risk Level
- Mitigated Risk Level
- Estimated Completion Date
- And more...

## 🔧 Advanced Usage

### Custom Output File
```powershell
.\src\nessus-to-poam\nessus_to_POAM.ps1 -NessusFile "scan.nessus" -OutputFile "custom_poam.xlsx"
```

### Error Handling
The script includes comprehensive error handling for:
- Missing input files
- Invalid XML content
- Module installation issues
- Excel export errors

## 🤝 Contributing
Contributions are welcome! Please:
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📜 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📧 Contact
Shane Trimbur - [@shanetrimbur](https://github.com/shanetrimbur)

Project Link: [https://github.com/shanetrimbur/security-tools](https://github.com/shanetrimbur/security-tools)

---
⭐ If you find this project useful, please consider giving it a star!
