# Fill in the correct path to your NAS or network files
$nasFolder = "H:\"
$TestH = Test-Path $nasFolder

if ($TestH -eq $false)
{
    exit
}



# Declares destination for onedrive environment
$destination = $env:OneDriveSync

if(Test-Path $destination\Documents\HomeDriveData)
{
    New-Item -ItemType File -Path "$destination\transferCompleted"
    Set-Content -Path "$destination\transferCompleted" "do not delete this file"
    Set-ItemProperty -Path "$destination\transferCompleted" -name IsReadOnly -Value $true
    (gi '$destination\transferCompleted').Attributes += 'Hidden'
    exit     
}
#
$loggedInUser = (get-wmiobject Win32_ComputerSystem).UserName.Split("\")[1]

#
$userMap = "c:\users\$loggedInUser"



# Creates path where files have to be copied to
$destinationFolder = Join-Path $destination "\HomeDrive"
#$destinationTestFolder = Join-Path $destination "\Test"

# Declare boolean
$pathExists = $false

$popUp = New-Object -ComObject wscript.shell


# Declares error file
$errorFile = "$destinationFolder\errorfile.txt"

# Declare result file
$resultFile = "$destinationFolder\resultfile.txt"


# Declare boolean
$pathExists = $false

if($destination -eq $null)
{
    Write-Output "OneDrive - Adecco map niet gevonden , bekijk de installatie" | Out-File $errorFile
    exit
}

####################
######function#####
####################


# Act is the main function that copies all files from NAS to OneDrive
Function Act
{
#    $popUp.Popup( "Copy is starting")
    try {Start-Sleep -Seconds 60
         Robocopy $nasFolder $destinationFolder  /R:1 /E /XF desktop.ini |Out-File $resultFile
         New-Item -ItemType File -Path "$destination\transferCompleted"
         Set-Content -Path "$destination\transferCompleted" "do not delete this file"
         Set-ItemProperty -Path "$destination\transferCompleted" -name IsReadOnly -Value $true
         (gi '$destination\transferCompleted').Attributes += 'Hidden'
         Start-Process cmd -Argument "echo y | cacls h: /T /C /E /P BE\%USERNAME%:r"}
          
    catch {
        Write-Error "Could not do RoboCopy, check for errors."
        exit
    }
#    $popUp.Popup("Migration completed - check $resultFile for deailted info")
}


###################
###End Function###
###################

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


#Check if transfer is already done
if(Test-Path "$destination\transferCompleted")
{
	Write-Output "Files were already transfered, aborting copy." | Out-File $errorFile
    exit
}


Act




#########################################################################################
#Drive cleanup
#########################################################################################


# List all files in new folder
$files = Get-ChildItem $destinationFolder -Recurse

# make everything file on demand - Save space
foreach($file in $files)
{
    attrib.exe $destinationFolder\$file +U -P /s
}