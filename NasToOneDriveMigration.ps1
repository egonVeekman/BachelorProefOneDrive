#Name script: NasToOneDriveMigration.ps1
#Author: Veekman Egon
#Date: 15 april 2019
#Comments: This script is made to migrate your NAS drive to OneDrive
#Notes: Please make sure variables are filled in correctly
#

# Declares error file
$errorFile = "C:\MigrationErrorfile.txt"

# Declare result file
$resultFile = "C:\MigrationResults.txt"

# Fill in the correct path to your NAS or network files
$nasFolder = "\\MYCLOUDEX2ULTRA\egon"

# Declares destination for onedrive environment
$destination = $env:OneDrive

# Creates path where files have to be copied to
$destinationFolder = Join-Path $destination "\NAS"

# Declare boolean
$pathExists = $false

# Check if path exists
if(Test-Path $destinationFolder)
{
    $pathExists =$true
}
else
{
    $pathExists = $false
}


# Create the new folder for files to be copied in
if( $pathExists -eq $false)
{
    New-Item -ItemType Directory -Path $destinationFolder
    Write-Output "file $destinationFolder created" | Out-File $errorFile -Append
}
else
{
    Write-Output "File already existed - proces not interrupted" | Out-File $errorFile
}

$popUp = New-Object -ComObject wscript.shell
$popUp.Popup( "Copy is starting")
Act


$popUp.Popup("Migration completed - check c:\MigrationResults for deailted info")



####################
#function
####################

# Act is the main function that copies all files from NAS to OneDrive
Function Act
{
    try {Robocopy $nasFolder $destinationFolder  /R:1 /XF desktop.ini |Out-File $resultFile } 
    catch {
        Write-Error "Could not do RoboCopy, check for errors."
        exit
    }
}


#########################################################################################
#Drive cleanup
#########################################################################################


# List all files in new folder
$files = Get-ChildItem $destinationFolder

# make everything file on demand - Save space
foreach($file in $files)
{
    attrib.exe $destinationFolder\$file +U -P /s
}

