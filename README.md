# BR 22

## Intro

This repo currently is a straight copy of git ref 4ab8ce957fa76d60c43e5b326d0c0f4222351cb4 from the repo at https://github.com/Circadence-Corp/DSREexpertBR

Everything below this line is the readme copied from there.

# DSRE Expert BR range

This range was borrowed from the good folks at MSFT to build a range that we could integrate with different Azure and Microsoft Security tools for demonstration in Azure.

> DISCLAIMER
> These VMs should not be placed in production environments or used in production workloads. The settings of the VMs have antivirus purposefully disabled, updates disabled (after provisioning), and attack tools stagged.

## Contents

| File/folder       | Description                                                                       |
|-------------------|-----------------------------------------------------------------------------------|
| `Downloads`       | Staged code.                                                                      |
| `Nested`          | Nested ARM scripts for ARM deployment. Extends azuredeploy.json                   |
| `Stage`           | Scripts to help *snapshot* resources. Convert them to images for easy deployment  |
| `Troubleshoot`    | Helper scripts to help troubleshoot and build-out ARM and DSC environment         |
| `DSC`             | Desired State Configuration which configure the resources after ARM provisioning  |
| `CHANGELOG.md`    | Changelog for each version, plus current dev efforts (vNext)                      |

## Setup

Primer for PowerShell Az cmdlets: [here](https://docs.microsoft.com/en-us/powershell/azure/get-started-azureps?view=azps-2.6.0)

## About the environment

This creates VMs, one of those VMs being a Domain Controller which hydrates users in an AD environment.  Those users are also configured appropriately on the respective VMs to simulate management and administrative activities.

For more information refer to ```DSC``` [folder](https://github.com/Circadence-Corp/DSREexpertBR/blob/master/CHANGELOG.md).

### Phase 0 (build from absolute scratch)
To build from scratch (**Phase 0**):

1. ```New-AzResourceGroup -Name <<resource-group-name>>```
2. ```New-AzResourceGroupDeployment -ResourceGroupName <<resource-group-name>> -TemplateFile .\azuredeploy.json```

The first command creates the resource group (in your respective Tenant).  The second line hydrates the new resource group with the provided ARM tempalte file.  The ```azuredeploy.json``` wraps in the Desired State Configuration policys to build out the Domain Controller, VictimPC, AdminPC and Client01.

You can make modifications to these VMs, but again, we recommend any change is made at the ARM and DSC level.

If you wish to remove the DSC from a resource, use the ```Remove-AzVmExtension``` command. Make the desired configurations to the DSC, re-compile the DSC (```Publish-AzVmDscConfiguratoin```) and repeat the above steps, although you do not need to re-create another resource-group.  You can target the same one and Azure is smart enough to know what ARM to apply, and same with DSC, thanks to them being idempotent.

Once you have what you want, you can use the scripts in ```Stage``` folder to help capture the VMs and move them into Azure Storage Containers.  This allows us to then deploy these VMs in minutes vs seconds.

### Phase 1: Stagging Changes

```Stage``` has what you need.  Use ```New-BackupVmsToDisk.ps1```, point to the right resource group, and the disks will be snapshotted to the resource-group.  Then, ```New-MoveDisksToStorageAccountContainer.ps1``` will take those snapshots and move them into the respective Azure Storage Account container.

Once this is done, you can do Phase 2.

### Phase 2: Deploying from Stagged Changes

Like before, but with different parameters, we can deploy VMs.

1. ```New-AzResourceGroup -Name <<other-resource-group-name>>```
2. ```New-AzResourceGroupDeployment -ResourceGroupName <<other-resource-group-name>> -Templatefile .\template.json```

Note that ```template.json``` will need to be updated so it points to the right location of the VMs earlier captured.  This can be done very quickly once you realize the variables use specific names (i.e. ```DcVhdUri``` is the Domain Controller's VHD URI).  Also note the other changes that can be made in the ```template.json``` including the VMs names.

The most critical part of this is knowing the Domain Controller becomes the vNet's DNS server, which can only happen *after* the DC VM exists.  For this reason, we have a nested ARM template, similar to what we do in Phase 0.  Without this, VMs would not always be able to resolve each other consistently and a race-condition would exist between the vNet DNS settings taking effect before the other VMs are built.

### Access your VMs

Regardless of if your in Phase 0 or Phase 2, you eventually will want to access your VMs.  You can of course do this from the Azure Portal, but we also created a quick script, ```Get-VmsInfo.ps1 -ResourceGroupName <ResourceGroupName>```.  This will tell you the VMs IPs.  You can then ```mstsc /v:<<ip>>``` or, ```ssh <<ip>>``` to quickly RDP into that machine, depending on the VM type and its authentication service.

## Skip straight to Phase 2

Want to skip Phase 0?  Feel free to grab our VHDs from an open Azure Storage account.

* ContosoDC: https://publicdefendtheflag.blob.core.windows.net/public-v1/ContosoDcd.vhd
* VictimPC: https://publicdefendtheflag.blob.core.windows.net/public-v1/VictimPcd.vhd
* AdminPC: https://publicdefendtheflag.blob.core.windows.net/public-v1/AdminPcd.vhd
* Client01: https://publicdefendtheflag.blob.core.windows.net/public-v1/Client01d.vhd
* Ubuntu-Katoolin: https://publicdefendtheflag.blob.core.windows.net/public-v1/Ubuntu-Katoolind.vhd

> NOTE:
> Ubuntu-Katoolin will leverage Ubuntu since it supports ```cloud-init``` and the [Katoolin](https://github.com/LionSec/katoolin) project.  No work has been done to automate on top of this **yet**, however, scripts exist in the ```Downloads``` > ```Katoolin``` folder.  Until automation exists, grabbing the VHD for Ubuntu-Katoolin adds very little.  The scripts are more important here as grabbing the necessary files is fairly easy with the right distro.

Don't want to download them?  See guidance on ```Phase 2```; those commands automatically pull from these public Azure Storage Containers; total deployment time is usually ~2 minutes.

## Changelog
For full view of [whats new and comprehensive changelog, here here](https://github.com/Circadence-Corp/DSREexpertBR/blob/master/CHANGELOG.md).
