function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $defaultConnectorsClassification = 'Blocked',

        [Parameter()]
        [System.String]
        $environments,

        [Parameter()]
        [System.String]
        $environmentType,

        [Parameter()]
        [System.String]
        $filterType,

        [Parameter()]
        [System.String]
        $policyName,

        [Parameter()]
        [System.String]
        $type,

        [Parameter()]
        [System.String]
        $connectorGroups,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationSecret
    )

    Write-Verbose -Message "Getting configuration for PowerApps Environment {$DisplayName}"
    $ConnectionMode = New-M365DSCConnection -Workload 'PowerPlatforms' `
        -InboundParameters $PSBoundParameters

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName -replace 'MSFT_', ''
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $nullReturn = $PSBoundParameters
    $nullReturn.Ensure = 'Absent'

    try
    {
        $dlpPolicy = Get-AdminDlpPolicy -ErrorAction Stop | Where-Object -FilterScript { $_.DisplayName -eq $DisplayName }

        if ($null -eq $dlpPolicy)
        {
            Write-Verbose -Message "Could not find DLP Policy {$DisplayName}"
            return $nullReturn
        }

        Write-Verbose -Message "Found DLP Policy {$DisplayName}"

        [Array]$businessdataGroupConnectors = $dlpPolicy.BusinessDataGroup | ForEach-Object {
            return @{
                id = $_.id
                name  = $_.name
                type = $_.type
            }
        }

        [Array]$NonBusinessDataGroupConnectors = $dlpPolicy.NonBusinessDataGroup | ForEach-Object {
            return @{
                id = $_.id
                name  = $_.name
                type = $_.type
            }
        }

        [Array]$BlockedGroupConnectors = $dlpPolicy.BlockedGroup | ForEach-Object {
            return @{
                id = $_.id
                name  = $_.name
                type = $_.type
            }
        }

        $connectorGroupstemp = @()
        $connectorGroupstemp += @{
            classification = "Confidential"
            connectors  = $businessdataGroupConnectors
        }
        $connectorGroupstemp += @{
            classification = "General"
            connectors  = $NonBusinessDataGroupConnectors
        }
        $connectorGroupstemp += @{
            classification = "Blocked"
            connectors  = $BlockedGroupConnectors
        }

        return @{
            PolicyName                      = $dlpPolicy.PolicyName
            Type                            = $dlpPolicy.Type
            DisplayName                     = $DisplayName
            ConnectorGroups                 = ConvertTo-Json -Depth 100 -InputObject $connectorGroupstemp -EscapeHandling EscapeNonAscii
            FilterType                      = $dlpPolicy.FilterType
            Environments                    = ConvertTo-Json -Depth 100 -InputObject $dlpPolicy.Environments -EscapeHandling EscapeNonAscii
            Ensure                          = 'Present'
            Credential                      = $Credential
            ApplicationId                   = $ApplicationId
            TenantId                        = $TenantId
            CertificateThumbprint           = $CertificateThumbprint
            ApplicationSecret               = $ApplicationSecret
        }
    }
    catch
    {
        New-M365DSCLogEntry -Message 'Error retrieving data:' `
            -Exception $_ `
            -Source $($MyInvocation.MyCommand.Source) `
            -TenantId $TenantId `
            -Credential $Credential

        return $nullReturn
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $defaultConnectorsClassification = 'Blocked',

        [Parameter()]
        [System.String]
        $environments,

        [Parameter()]
        [System.String]
        $environmentType,

        [Parameter()]
        [System.String]
        $filterType,

        [Parameter()]
        [System.String]
        $policyName,

        [Parameter()]
        [System.String]
        $type,

        [Parameter()]
        [System.String]
        $connectorGroups,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationSecret
    )


    Write-Verbose -Message "Setting configuration for DLP Policy {$DisplayName}"

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName -replace 'MSFT_', ''
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $ConnectionMode = New-M365DSCConnection -Workload 'PowerPlatforms' `
        -InboundParameters $PSBoundParameters

    $CurrentValues = Get-TargetResource @PSBoundParameters
    $CurrentParameters = $PSBoundParameters
    $CurrentParameters.Remove('Credential') | Out-Null
    $CurrentParameters.Remove('ApplicationId') | Out-Null
    $CurrentParameters.Remove('TenantId') | Out-Null
    $CurrentParameters.Remove('ApplicationSecret') | Out-Null
    $CurrentParameters.Remove('CertificateThumbprint') | Out-Null
    $CurrentParameters.Remove('Ensure') | Out-Null

    if ($Ensure -eq 'Present' -and $CurrentValues.Ensure -eq 'Absent')
    {
        Write-Verbose -Message "Creating new DLP Policy {$DisplayName}"
        try
        {
            New-PowerPlatformDLPPolicy @CurrentParameters
        }
        catch
        {
            Write-Verbose -Message "An error occured trying to create new DLP Policy {$DisplayName}"
            throw $_
        }
    }
    elseif ($Ensure -eq 'Present' -and $CurrentValues.Ensure -eq 'Present')
    {
        Write-Warning -Message "Resource doesn't support updating existing DLP Policies. Please delete and recreate {$DisplayName}"
    }
    elseif ($Ensure -eq 'Absent' -and $CurrentValues.Ensure -eq 'Present')
    {
        Write-Verbose -Message "Removing existing instance of DLP Policy {$DisplayName}"
        Remove-DlpPolicy -PolicyName -$DisplayName | Out-Null
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $defaultConnectorsClassification = 'Blocked',

        [Parameter()]
        [System.String]
        $environments,

        [Parameter()]
        [System.String]
        $environmentType,

        [Parameter()]
        [System.String]
        $filterType,

        [Parameter()]
        [System.String]
        $type,

        [Parameter()]
        [System.String]
        $policyName,

        [Parameter()]
        [System.String]
        $connectorGroups,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationSecret
    )

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName -replace 'MSFT_', ''
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    Write-Verbose -Message "Testing configuration for DLP Policy {$DisplayName}"
    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-M365DscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-M365DscHashtableToString -Hashtable $PSBoundParameters)"

    $ValuesToCheck = $PSBoundParameters
    $ValuesToCheck.Remove('Credential') | Out-Null
    $TestResult = Test-M365DSCParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck $ValuesToCheck.Keys

    Write-Verbose -Message "Test-TargetResource returned $TestResult"

    return $TestResult
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationSecret
    )

    $ConnectionMode = New-M365DSCConnection -Workload 'PowerPlatforms' `
        -InboundParameters $PSBoundParameters

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName -replace 'MSFT_', ''
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    try
    {
        [array]$policies = Get-AdminDlpPolicy -ErrorAction Stop
        $dscContent = ''
        $i = 1

        if ($policies.Length -eq 0)
        {
            Write-Host $Global:M365DSCEmojiGreenCheckMark
        }
        else
        {
            Write-Host "`r`n" -NoNewline
        }
        foreach ($policy in $policies)
        {

            Write-Host "    |---[$i/$($policies.Count)] $($policy.DisplayName)" -NoNewline
            Write-Host "Policy Name: " $policy.PolicyName
            Write-Host $Params

            $Params = @{
                DisplayName             = $policy.DisplayName
                Credential              = $Credential
                ApplicationId           = $ApplicationId
                TenantId                = $TenantId
                CertificateThumbprint   = $CertificateThumbprint
                ApplicationSecret       = $ApplicationSecret
            }
            $Results = Get-TargetResource @Params
            $Results = Update-M365DSCExportAuthenticationResults -ConnectionMode $ConnectionMode `
                -Results $Results
            $currentDSCBlock = Get-M365DSCExportContentForResource -ResourceName $ResourceName `
                -ConnectionMode $ConnectionMode `
                -ModulePath $PSScriptRoot `
                -Results $Results `
                -Credential $Credential
            $dscContent += $currentDSCBlock

            Save-M365DSCPartialExport -Content $currentDSCBlock `
                -FileName $Global:PartialExportFileName
            Write-Host $Global:M365DSCEmojiGreenCheckMark

            $i++
        }
        return $dscContent
    }
    catch
    {
        Write-Host $Global:M365DSCEmojiRedX

        New-M365DSCLogEntry -Message 'Error during Export:' `
            -Exception $_ `
            -Source $($MyInvocation.MyCommand.Source) `
            -TenantId $TenantId `
            -Credential $Credential

        return ''
    }
}

#Helper functions
function New-PowerPlatformDLPPolicy {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter()]
        [System.String]
        $defaultConnectorsClassification = 'Blocked',

        [Parameter()]
        [System.String]
        $environments,

        [Parameter()]
        [System.String]
        $environmentType,

        [Parameter()]
        [System.String]
        $connectorGroups
    )
    begin {
        # Validate if environment with the same name already exists
        $existingPolicy = Invoke-PowerOpsRequest -Method Get -Path '/providers/PowerPlatform.Governance/v1/policies?$top=100' | Where-Object { $_.displayName -eq $Name }
        if ($existingPolicy) {
            throw "DLP Policy with DisplayName '$Name' already exists in Power Platform. Retry command with the -Force switch if you really want to create the policy with the duplicate name"
        }
    }
    process {
        # API payload
        try {
            Write-Verbose -Message "Creating DLP Policy $Name"

            $newPolicy = [pscustomobject]@{
                displayName = $Name
                defaultConnectorsClassification = $defaultConnectorsClassification
                connectorGroups = $connectorGroups
                environmentType = $environmentType
                environments = $environments
                etag = $null
            }
            Invoke-PowerOpsRequest -Method Post -Path '/providers/PowerPlatform.Governance/v1/policies' -RequestBody $newPolicy
        }
        catch {
            Write-Error $_
        }

    }
    end {

    }
}

function Invoke-PowerPlatformRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Get', 'Post', 'Patch', 'Delete', 'Put')]
        [String]
        $Method,

        [Parameter(Mandatory = $false)]
        [Object]
        $RequestBody,

        [Parameter(Mandatory = $true)]
        $Path,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    begin {
        # Set base URI
        $BaseUri = "https://api.bap.microsoft.com"
        if (-not $PSBoundParameters['Force']) {
            $ApiVersion = if ($Path -notmatch '\?') { '?api-version=2021-07-01' } else { '&api-version=2021-07-01' }
        }
        else {
            $ApiVersion = $null
        }
    }
    process {
        $RestParameters = @{
            "Uri"         = "$($BaseUri)$($Path)$($ApiVersion)"
            "Method"      = $Method
            "Headers"     = $Headers
            "ContentType" = 'application/json; charset=utf-8'
        }
        if ($RequestBody) {
            $RestParameters["Body"] = $RequestBody
        }
        try {
            $Request = InvokeApi -Method $Method -Route "$($BaseUri)$($Path)$($ApiVersion)" -Body $RequestBody -ThrowOnFailure
            if ($Method -eq 'Get') {
                if ($Request.value) {
                    return $Request.value
                }
                if ($Request.Properties) {
                    return $Request.Properties
                }
            }
            else {
                $Request
            }
        }
        catch {
            throw $_
        }
    }
    end {

    }
}
Export-ModuleMember -Function *-TargetResource
