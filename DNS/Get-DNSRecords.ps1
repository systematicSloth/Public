<#
.SYNOPSIS
	This script scavenges all DNS Records, Static and Automatic for specific IP Addresses.

.DESCRIPTION
	This script was written to aid with the accurate decomissioning of legacy services and their assigned DNS Records.

.PARAMETER <Parameter_Name>
    -IPAddress			- This is the IP Address that you wish to find records for
	-LogPath			- This is the location to record all records after the script has run
	-DomainController	- This is the domain controller you wish to run the queries against

.INPUTS
	None

.OUTPUTS
	Log file stored in $LogPath

.NOTES
	Version:        1.0
	Author:         Chris Robb
	Creation Date:  30.06.2020
	Purpose/Change: Initial script development
  
.EXAMPLE
	Get-DNSRecords.ps1 -IPAddress "192.168.1.1" -LogPath "C:\Temp\" -DomainController "Contoso-DS1"

#>

Param
			(
				[Parameter(Mandatory=$true,position=1)]
				[string]$IPAddress,
				[Parameter(Mandatory=$true,position=1)]
				[string]$LogPath,
				[Parameter(Mandatory=$true,position=1)]
				[string]$DomainController

			)

	function New-Result{
	param (
				[string]$Hostname,
				[string]$IP,
				[string]$RecordType,
				[string]$DNSZone
				)

	 New-Object PSObject -Property @{
				'Hostname' = $Hostname
				'IP' = $IP
				'Record Type' = $RecordType
				'DNS Zone' = $DNSZone
		}
	}

	If( $z = Get-DNSServerZone -ComputerName $DomainController | Where-Object {$_.IsReverseLookupZone -eq $False} )
		{
			ForEach( $Zone in $Z )
				{

					$ZoneName = $Zone.ZoneName
					$r = Get-DnsServerResourceRecord -ZoneName $ZoneName -ComputerName $DomainController | Where-Object {$_.RecordData.IPv4Address -like "$IPAddress"}
					$Log = $LogPath + $Date + $IP + "_DNS_$ZoneName"
                
							ForEach($s in $r)
								{
									$Result = New-Result -Hostname $s.HostName -IP $s.RecordData.IPv4Address -RecordType $s.RecordType -DNSZone $ZoneName
									$Results += @($Result)

									try
										{
									$Results | Export-Csv "$Log.csv" -NoTypeInformation -Append -Force                                                                              
										}

									catch
										{
										write-host "WARNING: $(Get-Date -Format 'hhmm.dd.MM') | $_" -BackgroundColor Black -ForegroundColor Green
										}
								}
                    
				}
		 }

	$Results | Out-Host
	write-host "INFORMATION: Results are available in $LogPath"

	$results = $NULL