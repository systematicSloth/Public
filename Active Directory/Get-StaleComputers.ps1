<#
.SYNOPSIS
	This script queries active directory computer objects for their Last Logon Date. If the date is less than today-inactiveDays then the computer is considered "stale".
.DESCRIPTION
	Running this script will query all Computer objects in Active Directory OU Specified in the run parameter. When a computer is detected as "stale" the object "comment" 
	is updated with the current OU Location for remedial changes, the description is updated with "Disabled on $DATE for inactivity", the object is disabled and then moved
	to an ArchivedComputers OU.
.PARAMETER
	-OU - The Organizational Unit that the computer objects exist in.
	-ArchiveOU - The Organizationl Unit that old computer objects will be moved to.
	-InactiveDays - The number of days since the computer last had a Logon Event that has been logged in Active Directory.
	-Scope - Whether the report should run in Production or Report only mode. Report only will make NO changes.
	-LogPath - This is where logs are stored. Do not include a trailing backslash.
.INPUTS
	None
.OUTPUTS
	$LogPath\StaleComputers_$(Get-Date -Format ddmmyyyy).log"
.NOTES
	Version:        2.0
	Author:         systematicSloth (systematicsloth.blogspot.com)
	Creation Date:  03.03.2020
	Purpose/Change: Initial script development
  
.EXAMPLE
	Get-StaleComputers.ps1 -OU "OU=Computers,DC=contoso,DC=com" -ArchiveOU "OU=Computers,OU=Archive,DC=contoso,DC=com" -InactiveDays 60 -Scope Report -LogPath "C:\Logs"
#>

Param 
    ( 
        [Parameter(Mandatory=$TRUE,position=1)]
	    [string]$OU,

        [Parameter(Mandatory=$TRUE,position=1)]
	    [string]$ArchiveOU,
          
        [Parameter(Mandatory=$TRUE,position=1)]
	    $InactiveDays,

        [ValidateSet("Report","Production")]
		[Parameter(Mandatory=$true,position=1)]
		[string]$Scope,

        [ValidateScript({Test-Path $_})]
		[Parameter(Mandatory=$true,position=1)]
		[String]$LogPath
    )

$Computers = Get-ADComputer -SearchBase $OU -Filter { (Enabled -eq $True) -and (LastLogonDate -NE "*") } -Properties Name,Comment,LastLogonDate | Where-Object {($_.LastLogonDate.Subtract($(Get-Date)) | Select -ExpandProperty Days) -le "-$InactiveDays"}

If($Scope -eq "Report") 
	{
		$Computers | Select Name,LastLogonDate | Out-File  "$LogPath\StaleComputers_$(Get-Date -Format ddmmyyyy).log"
	}

Else($Scope -eq "Production")
	{
		ForEach ($Computer in $Computers) 
		{

		$ComputerLocation = Get-ADComputer $Computer | Select @{Name="OU";Expression={$_.DistinguishedName -replace "CN=$($Computer.Name),",""}}
	
			{ 			
					try 
						{
							Set-ADComputer -Identity $Computer -Description "Disabled on $Date for inactivity."
							Set-ADComputer -Identity $Computer -Replace @{Comment="$($ComputerLocation.OU)"}
							Disable-ADAccount -Identity $Computer
							Move-ADObject -Identity $Computer -TargetPath "$ArchiveOU" -Verbose
						}
					Catch 
						{
							$_ | Out-File  "$LogPath\Report_$(Get-Date -Format ddmmyyyy).log"
						}
	}
