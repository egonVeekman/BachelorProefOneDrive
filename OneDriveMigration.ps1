# Declares destination for onedrive environment
$destination = $env:OneDriveSync

# Declares error file
$errorFile = "$destinationFolder\errorfile.txt"

# Declare result file
$resultFile = "$destinationFolder\resultfile.txt"

# Fill in the correct path to your NAS or network files
# Create variable for source files (in this case every HomeDrive was mapped to the H drive)
$nasFolder = "H:\"

# Test if the newly created variable actually contains a path. This can be false when the user cannot reach their HomeDrive.
$TestH = Test-Path $nasFolder

# If the variable with the source path is empty, abort the script and write log to error file.
if ($TestH -eq $false)
{
    write-output "Could not reach homedrive - make sure homedrive is mapped to H" | out-file $errorfile
    exit
}


# Creates path where files have to be copied to
$destinationFolder = Join-Path $destination "\HomeDrive"
#$destinationTestFolder = Join-Path $destination "\Test"

# Declare boolean
$pathExists = $false

#Create variable to make pop-ups.
$popUp = New-Object -ComObject wscript.shell


#Check if OneDrive for business is installed. If not, notify the user with popup and abort the process.
if($destination -eq $null)
{
    $popUp.Popup("OneDrive - <company> map not found , make sure OneDrive For Business is installed")
    exit
}

####################
######function#####
####################


# Act is the main function that copies all files from NAS to OneDrive
# Will copy the exact same structure from the homedrive into the OneDrive account.
# After the copy a hidden file read-only file will be created to notify that the migration is completed.
# Afterwards the original homedrive will become readonly
Function Act
{
    $popUp.Popup( "Copy is starting")
    try {Start-Sleep -Seconds 60
         Robocopy $nasFolder $destinationFolder  /R:1 /E /XF desktop.ini |Out-File $resultFile
         New-Item -ItemType File -Path "$destination\transferCompleted"
         Set-Content -Path "$destination\transferCompleted" "do not delete this file"
         Set-ItemProperty -Path "$destination\transferCompleted" -name IsReadOnly -Value $true
         (gi '$destination\transferCompleted').Attributes += 'Hidden'
         Start-Process cmd -Argument "echo y | cacls h: /T /C /E /P BE\%USERNAME%:r"}
          
    catch {
        Write-Error "Error happened during migration, please check robocopy output."
        exit
    }
    $popUp.Popup("Migration completed - check $resultFile for detailed info")
}


###################
###End Function###
###################

# Check if path exists and assign a value to the boolean
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


#Check if transfer is already done by looking for the hidden file created after copy. 
#If the file is present, the migration is already done once and the script may be aborted.
if(Test-Path "$destination\transferCompleted")
{
    Write-Output "Files were already transfered, aborting copy." | Out-File $errorFile
    exit
}

# Execute the main function
Act




#########################################################################################
#Drive cleanup
#########################################################################################


# List all files in new folder
$files = Get-ChildItem $destinationFolder -Recurse

# make everything file on demand to save space on the end-user device
foreach($file in $files)
{
    attrib.exe $destinationFolder\$file +U -P /s
}
