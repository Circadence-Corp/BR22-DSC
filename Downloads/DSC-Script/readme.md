# Post-DSC Provisioning Steps

After successfully provisioning the "on-prem" AD domain via DSC, the following steps will need to be performed to sync local AD users with Azure AD.

(Perform these steps on the newly provisioned domain controller)

1. Install AAD Connect
    - This is a manual process, but the install can be downloaded by running this script: [Download-AADConnect.ps1](./Download-AADConnect.ps1).
2. License users
    - Run the following script: [Assign-Licenses.ps1](./Assign-Licenses.ps1).
    - Be sure to edit the params of the script to match what is accurate for the environment.