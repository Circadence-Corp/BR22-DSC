#Set Parameters
param(
    # User Location
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Location =  'US',

    # UserPrincipalName Suffix to use for the user email addresses
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$UPNSuffix =  "@seccdt2.onmicrosoft.com",

    # List of usernames to activate
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Users =  @(
        "JeffL",
        "SamiraA",
        "RonHd",
        "LisaV"
    )
)

# If need to set UPN for users, then run the following:
#   ForEach ($User in $Users) {
#       Get-ADUser -Identity $User | Set-ADUser -UserPrincipalName ($User + $UPNSuffix)
#   }

# Combine user names and UPNSuffix
$UserEmails = $Users | ForEach-Object {
    $_ + $UPNSuffix
}

#Install AzureAD Module if not already installed
$InstalledModules = Get-Module -ListAvailable
if ($InstalledModules.Name -notcontains "AzureAD") {
    Install-PackageProvider -Name Nuget -MinimumVersion 2.8.5.201 -Force
    Install-Module -Name AzureAD -SkipPublisherCheck -Force
}

# Connect to AzureAD Service (should give a pop-up window to authenticate)
Connect-AzureAD

# Get License Sku (assumed only one...unsure of how to handle multiple)
$LicenseSkuId = Get-AzureADSubscribedSku |
    Where-Object {$_.SkuPartNumber -eq "SPE_E5"} |
    Select-Object -ExpandProperty SkuId

foreach ( $UserEmail in $UserEmails) {
    # Get User object
    $ThisUser = Get-AzureADUser -ObjectId $UserEmail

    # Set usage location
    $ThisUser | Set-AzureADUser -UsageLocation $Location

    # Assign License
    $License = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
    $License.SkuId = $LicenseSkuId
    $Licenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
    $Licenses.AddLicenses = $License
    Set-AzureADUserLicense -ObjectId $ThisUser.ObjectId -AssignedLicenses $Licenses
}

Disconnect-AzureAD