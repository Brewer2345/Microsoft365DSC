
$repoDir = Join-Path -Path $PSScriptRoot -ChildPath '..\' -Resolve

Import-Module -Name "$repoDir\modules\Microsoft365DSC\Microsoft365DSC.psd1"
Import-Module -Name PSDesiredStateConfiguration
Import-Module -Name ReverseDSC


$Credential = Get-Credential -UserName 'mbrewer-admin@devl.justice.gov.uk' -Message 'Y'

#Export-M365DSCConfiguration -Components @("PPDataPolicy") -Path "C:\projects\Microsoft365DSC\Output" -Credential $Credential #Export the tenant Data Policies
#Export-M365DSCConfiguration -Components @("PPTenantSettings") -Path "C:\projects\Microsoft365DSC\Output" -Credential $Credential #Export the tenant settings
#Export-M365DSCConfiguration -Components @("PPPowerAppsEnvironment") -Credential $Credential -Path "C:\projects\Microsoft365DSC\Output"  #Export the tenant Isolation settings
Export-M365DSCConfiguration -Components @("PPTenantIsolationSettings") -Credential $Credential -Path "C:\projects\Microsoft365DSC\Output"  #Export the tenant Environment settings

#Start-DSCConfiguration -Path 'C:\projects\Microsoft365DSC\Output\M365TenantConfig' -Wait -Verbose -Force
