# Nessus to POAM Converter

This PowerShell script automates the conversion of Nessus vulnerability scan results into a Plan of Actions and Milestones (POAM) Excel spreadsheet.

## Features
- Converts .nessus XML files to formatted Excel POAM spreadsheets
- Automatically maps Nessus severity levels to risk levels
- Includes detailed vulnerability information and system details
- Applies professional formatting to the Excel output
- Handles multiple hosts and vulnerabilities

## Output Format
The script generates an Excel file with the following columns:
- POAM ID
- Name
- Date Identified
- Source Identifying Weakness
- POAM Status
- Calculated Risk Level
- Mitigated Risk Level
- Estimated Completion Date
- Actual Start Date
- Actual Completion Date
- Vulnerability Library
- Allocated Control
- Subjective Mitigated Risk Level
- Weaknesses
- Mitigation
- Comments
- Affected Hardware
- Days Open
- Last Updated

## Risk Level Mapping
- Critical (4)
- High (3)
- Moderate (2)
- Low (1)
- Info (0) - Filtered out by default

## Error Handling
The script includes comprehensive error handling for:
- Missing input files
- Invalid XML content
- Module installation issues
- Excel export errors

## Requirements
- PowerShell 5.1 or higher
- ImportExcel PowerShell module
- Administrator rights (for module installation) 