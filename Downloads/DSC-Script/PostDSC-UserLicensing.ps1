$Subscription = "cloudconhmg"

#Set Parameters
param(
        # License SKU
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$LicenseSKU =  "$Subscription:SPE_E5",

        # User Location
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$Location =  'US'
)

#Set Variables
$UserEmails= @("JeffL@$Subscription.onmicrosoft.com",
"SamiraA@$Subscription.onmicrosoft.com",
"RonHd@$Subscription.onmicrosoft.com",
"LisaV@$Subscription.onmicrosoft.com",
"ElsieM@$Subscription.onmicrosoft.com")

#______________________________________________________Install AD Connect Sync (Manual)-COMPLETE

#------------------------------------------------------------------------------------
#-----------------------------------!!!IMPORTANT!!!----------------------------------
#------------------------------------------------------------------------------------
#Once users are licensed, use C:\AzureADConnect.msi to install the connector. 
#Use express installation. Once complete. Run AD Synchonization and enable synchronization 
#"in from AAD - User Join - Precedence 111 user"
#------------------------------------------------------------------------------------
#Download Azure AD Connect Installer
Invoke-WebRequest -Uri https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi -OutFile C:\AzureADConnect.msi -UseBasicParsing 
#C:\AzureADConnect.msi /quiet /qn /log C:\AZUREAD_LOGFILE.txt #IMPORTANT - QUIET INSTALL DOES NOT WORK

#______________________________________________________License AD Synched Users-COMPLETE
#Install MSOnline Module
Install-Module -Name MSOnline

#Connect to MSOL Service
Connect-MsolService

foreach ( $UserEmail in $UserEmails)
{
    #Set users' locations
    Set-MsolUser -UserPrincipalName $UserEmail -UsageLocation $Location

    #License Users
    Set-MsolUserLicense -UserPrincipalName $UserEmail -AddLicenses $LicenseSKU
}

#______________________________________________________REMOVE License AD Synched Users-COMPLETE - NOTE: User for after event or when running a new Deployment
#foreach ( $UserEmail in $UserEmails)
#{
#    Set-AzureADUserLicense -ObjectId UserEmail -AssignedLicenses $LicenseSKU
#}