#Download Azure AD Connect Installer
if (!(Test-Path "C:\AzureADConnect.msi")) {
    Invoke-WebRequest -Uri "https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi" -OutFile "C:\AzureADConnect.msi" -UseBasicParsing
}

