Configuration Main {
	param(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$DomainName,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$NetBiosName,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$DnsServer,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$AdminCreds,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$UserPrincipalName,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$JeffLCreds,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$SamiraACreds,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$RonHdCreds,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[PSCredential]$LisaVCreds,

		# AATP: used for AATP Service
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[PsCredential]$AatpServiceCreds,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[PsCredential]$AipServiceCreds,

		[int]$RetryCount = 20,
		[int]$RetryIntervalSec = 30,

		# Branch
		## Useful when have multiple for testing
		[Parameter(Mandatory = $false)]
		[String]$Branch
	)

	Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force

	Import-DscResource -ModuleName xActiveDirectory -ModuleVersion 3.0.0.0
	Import-DscResource -ModuleName PSDesiredStateConfiguration
	Import-DscResource -ModuleName xPSDesiredStateConfiguration -ModuleVersion 8.10.0.0
	Import-DscResource -ModuleName xDefender -ModuleVersion 0.2.0.0
	Import-DscResource -ModuleName ComputerManagementDsc -ModuleVersion 6.5.0.0
	Import-DscResource -ModuleName NetworkingDsc -ModuleVersion 7.4.0.0
	Import-DscResource -ModuleName xSystemSecurity -ModuleVersion 1.4.0.0
	Import-DscResource -ModuleName cChoco -ModuleVersion 2.4.0.0
	Import-DscResource -ModuleName xPendingReboot -ModuleVersion 0.4.0.0

	$Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
	$InterfaceAlias = $($Interface.Name)

	[PSCredential]$Creds = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$($AdminCreds.UserName)", $AdminCreds.Password)
	[PSCredential]$SamiraADomainCred = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$($SamiraACred.UserName)", $SamiraACred.Password)
	[PSCredential]$RonHdDomainCred = New-Object System.Management.Automation.PSCredential ("${NetBiosName}\$($RonHdCred.UserName)", $RonHdCred.Password)

	Node $AllNodes.where( { $_.Role -contains 'Domain_Controller' }).NodeName {
		LocalConfigurationManager
		{
			ConfigurationMode = 'ApplyOnly'
			RebootNodeIfNeeded = $true
			ActionAfterReboot = 'ContinueConfiguration'
			AllowModuleOverwrite = $true
		}

		Service DisableWindowsUpdate
		{
			Name = 'wuauserv'
			State = 'Stopped'
			StartupType = 'Disabled'
			Ensure = 'Present'
		}

		Service WmiMgt
		{
			Name = 'WinRM'
			State = 'Running'
			StartupType = 'Automatic'
			Ensure = 'Present'
		}

		WindowsFeature DNS
		{
			Ensure = 'Present'
			Name = 'DNS'
		}

		DnsServerAddress DnsServerAddress
		{
			Address        = '127.0.0.1'
			InterfaceAlias = $InterfaceAlias
			AddressFamily  = 'IPv4'
			DependsOn = "[WindowsFeature]DNS"
		}

		WindowsFeature DnsTools
		{
			Ensure = "Present"
			Name = "RSAT-DNS-Server"
			DependsOn = "[WindowsFeature]DNS"
		}

		WindowsFeature ADDSInstall
		{
			Ensure = 'Present'
			Name = 'AD-Domain-Services'
		}

		WindowsFeature ADDSTools
		{
			Ensure = "Present"
			Name = "RSAT-ADDS-Tools"
			DependsOn = "[WindowsFeature]ADDSInstall"
		}

		WindowsFeature ADAdminCenter
		{
			Ensure = "Present"
			Name = "RSAT-AD-AdminCenter"
			DependsOn = "[WindowsFeature]ADDSInstall"
		}

		xADDomain ContosoDC
		{
			DomainName = $DomainName
			DomainNetbiosName = $NetBiosName
			DomainAdministratorCredential = $Creds
			SafemodeAdministratorPassword = $Creds
			ForestMode = 'Win2012R2'
			DatabasePath = 'C:\Windows\NTDS'
			LogPath = 'C:\Windows\NTDS'
			SysvolPath = 'C:\Windows\SYSVOL'
			DependsOn = '[WindowsFeature]ADDSInstall'
		}

		xADForestProperties ForestProps
		{
			ForestName = $DomainName
			UserPrincipalNameSuffixToAdd = $UserPrincipalName
			DependsOn = @('[xADDomain]ContosoDC')
		}

		xWaitForADDomain DscForestWait
		{
			DomainName = $DomainName
			DomainUserCredential = $Creds
			RetryCount = $RetryCount
			RetryIntervalSec = $RetryIntervalSec
			DependsOn = @('[xADDomain]ContosoDC', '[xADDomain]ContosoDC', '[Registry]EnableTls12WinHttp64', '[Registry]EnableTls12WinHttp',
				'[Registry]EnableTlsInternetExplorerLM', '[Registry]EnableTls12ServerEnabled',
				'[Registry]SchUseStrongCrypto64', '[Registry]SchUseStrongCrypto', '[xIEEsc]DisableAdminIeEsc',
				'[xIEEsc]DisableUserIeEsc')
		}

		xADUser SamiraA
		{
			DomainName = $DomainName
			UserName = 'SamiraA'
			Password = $SamiraACreds
			Ensure = 'Present'
			GivenName = 'Samira'
			Surname = 'A'
			PasswordNeverExpires = $true
			DependsOn = @("[xADForestProperties]ForestProps", "[xWaitForADDomain]DscForestWait")
		}

		xADUser AipService
		{
			DomainName = $DomainName
			UserName = $AipServiceCreds.UserName
			Password = $AipServiceCreds
			Ensure = 'Present'
			GivenName = 'AipService'
			Surname = 'Account'
			PasswordNeverExpires = $true
			DependsOn = @("[xADForestProperties]ForestProps", "[xWaitForADDomain]DscForestWait")
		}

		xADUser RonHD
		{
			DomainName = $DomainName
			UserName = 'RonHD'
			Password = $RonHdCreds
			Ensure = 'Present'
			GivenName = 'Ron'
			Surname = 'HD'
			PasswordNeverExpires = $true
			DisplayName = 'RonHD'
			DependsOn = @("[xADForestProperties]ForestProps", "[xWaitForADDomain]DscForestWait")
		}

		xADUser AatpService
		{
			DomainName = $DomainName
			UserName = $AatpServiceCreds.UserName
			Password = $AatpServiceCreds
			Ensure = 'Present'
			GivenName = 'AATP'
			Surname = 'Service'
			PasswordNeverExpires = $true
			DisplayName = 'AATPService'
			DependsOn = @("[xADForestProperties]ForestProps", "[xWaitForADDomain]DscForestWait")
		}

		xADUser JeffL
		{
			DomainName = $DomainName
			UserName = 'JeffL'
			GivenName = 'Jeff'
			Surname = 'Leatherman'
			Password = $JeffLCreds
			Ensure = 'Present'
			PasswordNeverExpires = $true
			DisplayName = 'JeffL'
			DependsOn = @("[xADForestProperties]ForestProps", "[xWaitForADDomain]DscForestWait")
		}

		xADUser LisaV
		{
			DomainName = $DomainName
			UserName = 'LisaV'
			GivenName = 'Lisa'
			Surname = 'Valentine'
			Password =  $LisaVCreds
			Ensure = 'Present'
			PasswordNeverExpires = $true
			DependsOn = @("[xADForestProperties]ForestProps", "[xWaitForADDomain]DscForestWait")
		}

		xADGroup DomainAdmins
		{
			GroupName = 'Domain Admins'
			Category = 'Security'
			GroupScope = 'Global'
			MembershipAttribute = 'SamAccountName'
			MembersToInclude = "SamiraA"
			Ensure = 'Present'
			DependsOn = @("[xADUser]SamiraA", "[xWaitForADDomain]DscForestWait")
		}

		xADGroup Helpdesk
		{
			GroupName = 'Helpdesk'
			Category = 'Security'
			GroupScope = 'Global'
			Description = 'Tier-2 (desktop) Helpdesk for this domain'
			DisplayName = 'Helpdesk'
			MembershipAttribute = 'SamAccountName'
			MembersToInclude = "RonHD"
			Ensure = 'Present'
			DependsOn = @("[xADUser]RonHD", "[xWaitForADDomain]DscForestWait")
		}

		xIEEsc DisableAdminIeEsc
		{
			UserRole = 'Administrators'
			IsEnabled = $false
		}

		xIEEsc DisableUserIeEsc
		{
			UserRole = 'Users'
			IsEnabled = $false
		}

		xUac DisableUac
		{
			Setting = 'NeverNotifyAndDisableAll'
		}

		#region Enable TLS1.2
		# REF: https://support.microsoft.com/en-us/help/3140245/update-to-enable-tls-1-1-and-tls-1-2-as-default-secure-protocols-in-wi
		# Enable TLS 1.2 SChannel
		Registry EnableTls12ServerEnabled
		{
			Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client'
			ValueName = 'DisabledByDefault'
			ValueType = 'Dword'
			ValueData = 0
			Ensure = 'Present'
			Force = $true
		}
		# Enable Internet Settings
		Registry EnableTlsInternetExplorerLM
		{
			Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings'
			ValueName = 'SecureProtocols'
			ValueType = 'Dword'
			ValueData = '0xA80'
			Ensure = 'Present'
			Hex = $true
			Force = $true
		}
		#enable for WinHTTP
		Registry EnableTls12WinHttp
		{
			Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp'
			ValueName = 'DefaultSecureProtocols'
			ValueType = 'Dword'
			ValueData = '0x00000800'
			Ensure = 'Present'
			Hex = $true
			Force = $true
		}
		Registry EnableTls12WinHttp64
		{
			Key = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp'
			ValueName = 'DefaultSecureProtocols'
			ValueType = 'Dword'
			ValueData = '0x00000800'
			Hex = $true
			Ensure = 'Present'
			Force = $true
		}
		#powershell defaults
		Registry SchUseStrongCrypto
		{
			Key = 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319'
			ValueName = 'SchUseStrongCrypto'
			ValueType = 'Dword'
			ValueData =  '1'
			Ensure = 'Present'
			Force = $true
		}
		Registry SchUseStrongCrypto64
		{
			Key = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319'
			ValueName = 'SchUseStrongCrypto'
			ValueType = 'Dword'
			ValueData =  '1'
			Ensure = 'Present'
			Force = $true
		}

		Registry DisableSmartScreen
		{
			Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'
			ValueName = 'SmartScreenEnable'
			ValueType = 'String'
			ValueData = 'Off'
			Ensure = 'Present'
			Force = $true
			# The DependsOn fields were removed from the original configs so that this setting
			# can be used generically for all nodes. However, if problems arise, try splitting
			# the setting out into domain_controller and other roles, and adding Depends as is
			# relevant (see below):
			#	 DependsOn = '[xWaitForADDomain]DscForestWait'
			# 	 -or-
			#	 DependsOn = '[Computer]JoinDomain'
		}

		Registry HideServerManager
		{
			Key = 'HKLM:\SOFTWARE\Microsoft\ServerManager'
			ValueName = 'DoNotOpenServerManagerAtLogon'
			ValueType = 'Dword'
			ValueData = '1'
			Ensure = 'Present'
			Force = $true
			# The DependsOn fields were removed from the original configs so that this setting
			# can be used generically for all nodes. However, if problems arise, try splitting
			# the setting out into domain_controller and other roles, and adding Depends as is
			# relevant (see below):
			#	 DependsOn = '[xWaitForADDomain]DscForestWait'
			# 	 -or-
			#	 DependsOn = '[Computer]JoinDomain'
			DependsOn = @("[xADForestProperties]ForestProps", "[xWaitForADDomain]DscForestWait")
		}

		Registry HideInitialServerManager
		{
			Key = 'HKLM:\SOFTWARE\Microsoft\ServerManager\Oobe'
			ValueName = 'DoNotOpenInitialConfigurationTasksAtLogon'
			ValueType = 'Dword'
			ValueData = '1'
			Ensure = 'Present'
			Force = $true
			# The DependsOn fields were removed from the original configs so that this setting
			# can be used generically for all nodes. However, if problems arise, try splitting
			# the setting out into domain_controller and other roles, and adding Depends as is
			# relevant (see below):
			#	 DependsOn = @("[xADForestProperties]ForestProps", "[xWaitForADDomain]DscForestWait")
			# 	 -or-
			#	 DependsOn = '[Computer]JoinDomain'
		}

		cChocoInstaller InstallChoco
		{
			InstallDir = 'C:\choco'
			DependsOn = @('[xADForestProperties]ForestProps', '[xWaitForADDomain]DscForestWait')
		}

		cChocoPackageInstaller EdgeBrowser
		{
			Name = 'microsoft-edge'
			Ensure = 'Present'
			AutoUpgrade = $true
			DependsOn = '[cChocoInstaller]InstallChoco'
		}

		cChocoPackageInstaller WindowsTerminal
		{
			Name = 'microsoft-windows-terminal'
			Ensure = 'Present'
			AutoUpgrade = $true
			DependsOn = '[cChocoInstaller]InstallChoco'
		}

		cChocoPackageInstaller InstallSysInternals
		{
			Name = 'sysinternals'
			Ensure = 'Present'
			AutoUpgrade = $false
			DependsOn = '[cChocoInstaller]InstallChoco'
		}

		xRemoteFile DownloadBginfo
		{
			DestinationPath = 'C:\BgInfo\BgInfoConfig.bgi'
			Uri = 'https://github.com/Circadence-Corp/BR22-DSC/blob/master/Downloads/BgInfo/contosodc.bgi?raw=true'
			DependsOn = '[xWaitForADDomain]DscForestWait'
		}

		Script MakeShortcutForBgInfo {
			SetScript = {
				$s = (New-Object -COM WScript.Shell).CreateShortcut('C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BgInfo.lnk')
				$s.TargetPath = 'bginfo64.exe'
				$s.Arguments = 'c:\BgInfo\BgInfoConfig.bgi /accepteula /timer:0'
				$s.Description = 'Ensure BgInfo starts at every logon, in context of the user signing in (only way for stable use!)'
				$s.Save()
			}
			GetScript = {
				if (Test-Path -LiteralPath 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BgInfo.lnk') {
					return @{
						result = $true
					}
				}
				else {
					return @{
						result = $false
					}
				}
			}

			TestScript = {
				if (Test-Path -LiteralPath 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BgInfo.lnk') {
					return $true
				}
				else {
					return $false
				}
			}
			DependsOn = @('[xRemoteFile]DownloadBginfo', '[cChocoPackageInstaller]InstallSysInternals')
		}

		Script TurnOnNetworkDiscovery {
			SetScript = {
				Get-NetFirewallRule -DisplayGroup 'Network Discovery' | Set-NetFirewallRule -Profile 'Any' -Enabled true
			}
			GetScript = {
				$fwRules = Get-NetFirewallRule -DisplayGroup 'Network Discovery'
				if ($null -eq $fwRules) {
					return @{result = $false }
				}
				$result = $true
				foreach ($rule in $fwRules) {
					if ($rule.Enabled -eq 'False') {
						$result = $false
						break
					}
				}
				return @{
					result = $result
				}
			}
			TestScript = {
				$fwRules = Get-NetFirewallRule -DisplayGroup 'Network Discovery'
				if ($null -eq $fwRules) {
					return $false
				}
				$result = $true
				foreach ($rule in $fwRules) {
					if ($rule.Enabled -eq 'False') {
						$result = $false
						break
					}
				}
				return $result
			}
			DependsOn = @("[xADForestProperties]ForestProps", "[xWaitForADDomain]DscForestWait")
		}

		Script TurnOnFileSharing {
			SetScript = {
				Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing' | Set-NetFirewallRule -Profile 'Any' -Enabled true
			}
			GetScript = {
				$fwRules = Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing'
				$result = $true
				foreach ($rule in $fwRules) {
					if ($rule.Enabled -eq 'False') {
						$result = $false
						break
					}
				}
				return @{
					result = $result
				}
			}
			TestScript = {
				$fwRules = Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing'
				$result = $true
				foreach ($rule in $fwRules) {
					if ($rule.Enabled -eq 'False') {
						$result = $false
						break
					}
				}
				return $result
			}
			DependsOn = @("[xADForestProperties]ForestProps", "[xWaitForADDomain]DscForestWait")
		}

		Script MakeCmdShortcut {
			SetScript = {
				$s = (New-Object -COM WScript.Shell).CreateShortcut('C:\Users\Public\Desktop\Cmd.lnk')
				$s.TargetPath = 'cmd.exe'
				$s.Description = 'Cmd.exe shortcut on everyones desktop'
				$s.Save()
			}
			GetScript = {
				if (Test-Path -LiteralPath 'C:\Users\Public\Desktop\Cmd.lnk') {
					return @{
						result = $true
					}
				}
				else {
					return @{
						result = $false
					}
				}
			}

			TestScript = {
				if (Test-Path -LiteralPath 'C:\Users\Public\Desktop\Cmd.lnk') {
					return $true
				}
				else {
					return $false
				}
			}
			DependsOn = '[xWaitForADDomain]DscForestWait'
		}

		xMpPreference DefenderSettings
		{
			Name = 'DefenderProperties'
			DisableRealtimeMonitoring = $true
			ExclusionPath = 'c:\Temp'
		}
	} #end Node Role 'Domain_Controller'

	Node $AllNodes.where( { $_.Role -contains 'Domain_Member' }).NodeName {
		WaitForAll DC
		{
			ResourceName      = '[xWaitForADDomain]DscForestWait'
			NodeName          = 'ContosoDc'
			RetryIntervalSec  = 15
			RetryCount        = 30
		}

		LocalConfigurationManager
		{
			ConfigurationMode = 'ApplyOnly'
			RebootNodeIfNeeded = $true
			ActionAfterReboot = 'ContinueConfiguration'
			AllowModuleOverwrite = $true
		}

		Service DisableWindowsUpdate
		{
			Name = 'wuauserv'
			State = 'Stopped'
			StartupType = 'Disabled'
			Ensure = 'Present'
		}

		Service WmiMgt
		{
			Name = 'WinRM'
			State = 'Running'
			StartupType = 'Automatic'
			Ensure = 'Present'
		}

		Computer JoinDomain
		{
			Name = $Node.NodeName
			DomainName = $DomainName
			Credential = $Creds
		}

		Registry AuditModeSamr
		{
			Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
			ValueName = 'RestrictRemoteSamAuditOnlyMode'
			ValueType = 'Dword'
			ValueData = '1'
			Force = $true
			Ensure = 'Present'
			DependsOn = '[Computer]JoinDomain'
		}

		xIEEsc DisableAdminIeEsc
		{
			UserRole = 'Administrators'
			IsEnabled = $false
		}

		xIEEsc DisableUserIeEsc
		{
			UserRole = 'Users'
			IsEnabled = $false
		}

		xUac DisableUac
		{
			Setting = 'NeverNotifyAndDisableAll'
		}

		#region Enable TLS1.2
		# REF: https://support.microsoft.com/en-us/help/3140245/update-to-enable-tls-1-1-and-tls-1-2-as-default-secure-protocols-in-wi
		# Enable TLS 1.2 SChannel
		Registry EnableTls12ServerEnabled
		{
			Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client'
			ValueName = 'DisabledByDefault'
			ValueType = 'Dword'
			ValueData = 0
			Ensure = 'Present'
			Force = $true
		}
		# Enable Internet Settings
		Registry EnableTlsInternetExplorerLM
		{
			Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings'
			ValueName = 'SecureProtocols'
			ValueType = 'Dword'
			ValueData = '0xA80'
			Ensure = 'Present'
			Hex = $true
			Force = $true
		}
		#enable for WinHTTP
		Registry EnableTls12WinHttp
		{
			Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp'
			ValueName = 'DefaultSecureProtocols'
			ValueType = 'Dword'
			ValueData = '0x00000800'
			Ensure = 'Present'
			Hex = $true
			Force = $true
		}
		Registry EnableTls12WinHttp64
		{
			Key = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp'
			ValueName = 'DefaultSecureProtocols'
			ValueType = 'Dword'
			ValueData = '0x00000800'
			Hex = $true
			Ensure = 'Present'
			Force = $true
		}
		#powershell defaults
		Registry SchUseStrongCrypto
		{
			Key = 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319'
			ValueName = 'SchUseStrongCrypto'
			ValueType = 'Dword'
			ValueData =  '1'
			Ensure = 'Present'
			Force = $true
		}
		Registry SchUseStrongCrypto64
		{
			Key = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319'
			ValueName = 'SchUseStrongCrypto'
			ValueType = 'Dword'
			ValueData =  '1'
			Ensure = 'Present'
			Force = $true
		}

		Registry DisableSmartScreen
		{
			Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'
			ValueName = 'SmartScreenEnable'
			ValueType = 'String'
			ValueData = 'Off'
			Ensure = 'Present'
			Force = $true
			# The DependsOn fields were removed from the original configs so that this setting
			# can be used generically for all nodes. However, if problems arise, try splitting
			# the setting out into domain_controller and other roles, and adding Depends as is
			# relevant (see below):
			#	 DependsOn = '[xWaitForADDomain]DscForestWait'
			# 	 -or-
			#	 DependsOn = '[Computer]JoinDomain'
		}

		Registry HideServerManager
		{
			Key = 'HKLM:\SOFTWARE\Microsoft\ServerManager'
			ValueName = 'DoNotOpenServerManagerAtLogon'
			ValueType = 'Dword'
			ValueData = '1'
			Ensure = 'Present'
			Force = $true
			# The DependsOn fields were removed from the original configs so that this setting
			# can be used generically for all nodes. However, if problems arise, try splitting
			# the setting out into domain_controller and other roles, and adding Depends as is
			# relevant (see below):
			#	 DependsOn = '[xWaitForADDomain]DscForestWait'
			# 	 -or-
			#	 DependsOn = '[Computer]JoinDomain'
			DependsOn = @("[xADForestProperties]ForestProps", "[xWaitForADDomain]DscForestWait")
		}

		Registry HideInitialServerManager
		{
			Key = 'HKLM:\SOFTWARE\Microsoft\ServerManager\Oobe'
			ValueName = 'DoNotOpenInitialConfigurationTasksAtLogon'
			ValueType = 'Dword'
			ValueData = '1'
			Ensure = 'Present'
			Force = $true
			# The DependsOn fields were removed from the original configs so that this setting
			# can be used generically for all nodes. However, if problems arise, try splitting
			# the setting out into domain_controller and other roles, and adding Depends as is
			# relevant (see below):
			#	 DependsOn = @("[xADForestProperties]ForestProps", "[xWaitForADDomain]DscForestWait")
			# 	 -or-
			#	 DependsOn = '[Computer]JoinDomain'
		}

		cChocoInstaller InstallChoco
		{
			InstallDir = "C:\choco"
			DependsOn = '[Computer]JoinDomain'
		}

		cChocoPackageInstaller InstallSysInternals
		{
			Name = 'sysinternals'
			Ensure = 'Present'
			AutoUpgrade = $false
			DependsOn = '[cChocoInstaller]InstallChoco'
		}

		cChocoPackageInstaller EdgeBrowser
		{
			Name = 'microsoft-edge'
			Ensure = 'Present'
			AutoUpgrade = $true
			DependsOn = '[cChocoInstaller]InstallChoco'
		}

		Script TurnOnNetworkDiscovery {
			SetScript = {
				Get-NetFirewallRule -DisplayGroup 'Network Discovery' | Set-NetFirewallRule -Profile 'Any' -Enabled true
			}
			GetScript = {
				$fwRules = Get-NetFirewallRule -DisplayGroup 'Network Discovery' 
				$result = $true
				foreach ($rule in $fwRules) {
					if ($rule.Enabled -eq 'False') {
						$result = $false
						break
					}
				}
				return @{
					result = $result
				}
			}
			TestScript = {
				$fwRules = Get-NetFirewallRule -DisplayGroup 'Network Discovery'
				$result = $true
				foreach ($rule in $fwRules) {
					if ($rule.Enabled -eq 'False') {
						$result = $false
						break
					}
				}
				return $result
			}
			DependsOn = '[Computer]JoinDomain'
		}

		Script TurnOnFileSharing {
			SetScript = {
				Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing' | Set-NetFirewallRule -Profile 'Any' -Enabled true
			}
			GetScript = {
				$fwRules = Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing'
				$result = $true
				foreach ($rule in $fwRules) {
					if ($rule.Enabled -eq 'False') {
						$result = $false
						break
					}
				}
				return @{
					result = $result
				}
			}
			TestScript = {
				$fwRules = Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing'
				$result = $true
				foreach ($rule in $fwRules) {
					if ($rule.Enabled -eq 'False') {
						$result = $false
						break
					}
				}
				return $result
			}
			DependsOn = '[Computer]JoinDomain'
		}

		Script MakeCmdShortcut {
			SetScript = {
				$s = (New-Object -COM WScript.Shell).CreateShortcut('C:\Users\Public\Desktop\Cmd.lnk')
				$s.TargetPath = 'cmd.exe'
				$s.Description = 'Cmd.exe shortcut on everyones desktop'
				$s.Save()
			}
			GetScript = {
				if (Test-Path -LiteralPath 'C:\Users\Public\Desktop\Cmd.lnk') {
					return @{
						result = $true
					}
				}
				else {
					return @{
						result = $false
					}
				}
			}

			TestScript = {
				if (Test-Path -LiteralPath 'C:\Users\Public\Desktop\Cmd.lnk') {
					return $true
				}
				else {
					return $false
				}
			}
			DependsOn = '[Computer]JoinDomain'
		}
	} #end Node Role 'Domain_Member'

	Node $AllNodes.where( { $_.Role -contains 'Admin' }).NodeName {
		LocalConfigurationManager
		{
			ConfigurationMode = 'ApplyOnly'
			RebootNodeIfNeeded = $true
			ActionAfterReboot = 'ContinueConfiguration'
			AllowModuleOverwrite = $true
		}

		Service DisableWindowsUpdate
		{
			Name = 'wuauserv'
			State = 'Stopped'
			StartupType = 'Disabled'
			Ensure = 'Present'
		}

		Service WmiMgt
		{
			Name = 'WinRM'
			State = 'Running'
			StartupType = 'Automatic'
			Ensure = 'Present'
		}

		xGroup AddAdmins
		{
			GroupName = 'Administrators'
			MembersToInclude = "$NetBiosName\$($LisaVCred.UserName)"
			Ensure = 'Present'
			DependsOn = '[Computer]JoinDomain'
		}

		xGroup AddRemoteDesktopUsers
		{
			GroupName = 'Remote Desktop Users'
			MembersToInclude = @("$NetBiosName\SamiraA", "$NetBiosName\Helpdesk")
			Ensure = 'Present'
			DependsOn = '[Computer]JoinDomain'
		}

		cChocoPackageInstaller WindowsTerminal
		{
			Name = 'microsoft-windows-terminal'
			Ensure = 'Present'
			AutoUpgrade = $true
			DependsOn = '[cChocoInstaller]InstallChoco'
		}

		xRemoteFile GetBgInfo
		{
			DestinationPath = 'C:\BgInfo\BgInfoConfig.bgi'
			Uri = "https://github.com/Circadence-Corp/BR22-DSC/raw/$Branch/Downloads/BgInfo/adminpc.bgi"
			DependsOn = '[cChocoPackageInstaller]InstallSysInternals'
		}

		xMpPreference DefenderSettings
		{
			Name = 'DefenderSettings'
			ExclusionPath = 'C:\Tools'
			DisableRealtimeMonitoring = $true
		}

		Script MakeShortcutForBgInfo {
			SetScript = {
				$s = (New-Object -COM WScript.Shell).CreateShortcut('C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BgInfo.lnk')
				$s.TargetPath = 'bginfo64.exe'
				$s.Arguments = 'c:\BgInfo\BgInfoConfig.bgi /accepteula /timer:0'
				$s.Description = 'Ensure BgInfo starts at every logon, in context of the user signing in (only way for stable use!)'
				$s.Save()
			}
			GetScript = {
				if (Test-Path -LiteralPath 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BgInfo.lnk') {
					return @{
						result = $true
					}
				}
				else {
					return @{
						result = $false
					}
				}
			}

			TestScript = {
				if (Test-Path -LiteralPath 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BgInfo.lnk') {
					return $true
				}
				else {
					return $false
				}
			}
			DependsOn = @('[xRemoteFile]GetBgInfo', '[cChocoPackageInstaller]InstallSysInternals')
		}

		Script InstallRsat
		{
			SetScript = 
			{
				$rsatCapabilities = Get-WindowsCapability -Online -Name RSAT* | Where-Object { $_.State -eq 'NotPresent' }
				$rsatCapabilities | Add-WindowsCapability -Online
				#REMOVED-CAUSES DSC FAILURE
				#Update-Help
			}
			TestScript = 
			{
				$rsatCapabilities = Get-WindowsCapability -Online -Name RSAT* | Where-Object { $_.State -eq 'NotPresent' }
				if ($null -eq $rsatCapabilities) {
					return $true
				}
				else {
					return $false
				}
			}
			GetScript = 
			{
				$rsatCapabilities = Get-WindowsCapability -Online -Name RSAT* | Where-Object { $_.State -eq 'NotPresent' }
				if ($null -eq $rsatCapabilities) {
					return @{ result = $true }
				}
				else {
					return @{ result = $false }
				}
			}
			DependsOn = '[Computer]JoinDomain'
		}

		#region SQL
		Script MSSqlFirewall
		{
			SetScript = 
			{
				New-NetFirewallRule -DisplayName 'MSSQL ENGINE TCP' -Direction Inbound -LocalPort 1433 -Protocol TCP -Action Allow
			}
			GetScript = 
			{
				$firewallStuff = Get-NetFirewallRule -DisplayName "MSSQL ENGINE TCP" -ErrorAction SilentlyContinue
				# if null, no rule exists with the Display Name
				if ($null -ne $firewallStuff) {
					return @{ result = $true }
				}
				else {
					return @{ result = $false }
				}
			}
			TestScript = 
			{
				$firewallStuff = Get-NetFirewallRule -DisplayName "MSSQL ENGINE TCP" -ErrorAction SilentlyContinue
				# if null, no rule exists with the Display Name
				if ($null -ne $firewallStuff) {
					return $true
				}
				else {
					return $false
				}
			}
			DependsOn = '[Computer]JoinDomain'
		}

		Script EnsureTempFolder
		{
			SetScript = 
			{
				New-Item -Path 'C:\Temp\' -ItemType Directory
			}
			GetScript = 
			{
				if (Test-Path -PathType Container -LiteralPath 'C:\Temp') {
					return @{
						result = $true
					}
				}
				else {
					return @{
						result = $false
					}
				}
			}
			TestScript = {
				if (Test-Path -PathType Container -LiteralPath 'C:\Temp') {
					return $true
				}
				else {
					return $false
				}
			}
		}

		Script SharePublicDocuments
		{
			SetScript = 
			{
				New-SmbShare -Name 'Documents' -Path 'C:\Users\Public\Documents' `
					-FullAccess 'Everyone'

				Set-SmbPathAcl -ShareName 'Documents'
			}
			GetScript = 
			{
				$share = Get-SmbShare -Name 'Documents' -ErrorAction SilentlyContinue
				if ($null -ne $share) {
					# now that share exists, make sure ACL for everyone is set
					$acls = Get-Acl -Path C:\Users\Public\Documents 
					$acl = $acls.Access | Where-Object { $_.IdentityReference -eq 'Everyone' }
					if ($null -eq $acl) {
						# if no ACL has an 'Everyone' IdentityReference, return false
						return @{
							result = $false
						}
					}
					else {
						if (($acl.AccessControlType -eq 'Allow') -and ($acl.FileSystemRights -eq 'FullControl')) {
							return @{
								result = $true
							} 
						}
						# if ACL isn't right, return false
						else {
							return @{
								result = $false
							}
						}
					}
				}
				# if not a share, return false
				else {
					return @{
						result = $false
					}
				}
			}
			TestScript = 
			{
				$share = Get-SmbShare -Name 'Documents' -ErrorAction SilentlyContinue
				if ($null -ne $share) {
					# now that share exists, make sure ACL for everyone is set
					$acls = Get-Acl -Path C:\Users\Public\Documents 
					$acl = $acls.Access | Where-Object { $_.IdentityReference -eq 'Everyone' }
					if ($null -eq $acl) {
						# if no ACL has an 'Everyone' IdentityReference, return false
						return $false
					}
					else {
						if (($acl.AccessControlType -eq 'Allow') -and ($acl.FileSystemRights -eq 'FullControl')) {
							return $true
						}
						# if ACL isn't right, return false
						else {
							return $false
						}
					}
				}
				# if not a share, return false
				else {
					return $false
				}
			}
			DependsOn = '[Computer]JoinDomain'
		}

		xRemoteFile GetAipData
		{
			DestinationPath = 'C:\PII\data.zip'
			Uri = "https://github.com/Circadence-Corp/BR22-DSC/raw/$Branch/Downloads/AIP/docs.zip"
			DependsOn = @('[Computer]JoinDomain', '[Registry]SchUseStrongCrypto', '[Registry]SchUseStrongCrypto64')
		}

		xRemoteFile GetAipScripts
		{
			DestinationPath = 'C:\Scripts\Scripts.zip'
			Uri = "https://github.com/Circadence-Corp/BR22-DSC/raw/$Branch/Downloads/AIP/Scripts.zip"
			DependsOn = @('[Computer]JoinDomain', '[Registry]SchUseStrongCrypto', '[Registry]SchUseStrongCrypto64')
		}

		Archive AipDataToPii
		{
			Path = 'C:\PII\data.zip'
			Destination = 'C:\PII'
			Ensure = 'Present'
			Force = $true
			DependsOn = @('[xRemoteFile]GetAipData')
		}

		Archive AipDataToPublicDocuments
		{
			Path = 'C:\PII\data.zip'
			Destination = 'C:\Users\Public\Documents'
			Ensure = 'Present'
			Force = $true
			DependsOn = '[xRemoteFile]GetAipData'
		}

		Archive AipScriptsToScripts
		{
			Path = 'C:\Scripts\Scripts.zip'
			Destination = 'C:\Scripts'
			Ensure = 'Present'
			Force = $true
			DependsOn = @('[xRemoteFile]GetAipScripts')
		}

		File ScheduledTaskFile
		{
			DestinationPath = $Node.SamiraASmbScriptLocation
			Ensure = 'Present'
			Contents = 
			@'
Get-ChildItem '\\contosodc\c$'; exit(0)
'@
			Type = 'File'
		}

		ScheduledTask ScheduleTaskSamiraA
		{
			TaskName = 'SimulateDomainAdminTraffic'
			ScheduleType = 'Once'
			Description = 'Simulates Domain Admin traffic from Admin workstation. Useful for SMB Session Enumeration and other items'
			Ensure = 'Present'
			Enable = $true
			TaskPath = '\M365Security\Aatp'
			ActionExecutable   = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
			ActionArguments = "-File `"$($Node.SamiraASmbScriptLocation)`""
			ExecuteAsCredential = $SamiraADomainCred
			Hidden = $true
			Priority = 6
			RepeatInterval = '00:05:00'
			RepetitionDuration = 'Indefinitely'
			StartWhenAvailable = $true
			DependsOn = @('[Computer]JoinDomain', '[File]ScheduledTaskFile')
		}
	} #end Node Role 'Admin'

	Node $AllNodes.where( { $_.Role -contains 'Client' }).NodeName {
		LocalConfigurationManager
		{
			ConfigurationMode = 'ApplyOnly'
			RebootNodeIfNeeded = $true
			ActionAfterReboot = 'ContinueConfiguration'
			AllowModuleOverwrite = $true
		}

		Service DisableWindowsUpdate
		{
			Name = 'wuauserv'
			State = 'Stopped'
			StartupType = 'Disabled'
			Ensure = 'Present'
		}

		Service WmiMgt
		{
			Name = 'WinRM'
			State = 'Running'
			StartupType = 'Automatic'
			Ensure = 'Present'
		}

		xGroup AddAdmins
		{
			GroupName = 'Administrators'
			MembersToInclude = @("$NetBiosName\Helpdesk", "$NetBiosName\JeffL")
			Ensure = 'Present'
			DependsOn = '[Computer]JoinDomain'
		}

		cChocoPackageInstaller WindowsTerminal
		{
			Name = 'microsoft-windows-terminal'
			Ensure = 'Present'
			AutoUpgrade = $true
			DependsOn = '[cChocoInstaller]InstallChoco'
		}

		xRemoteFile DownloadBginfo
		{
			DestinationPath = 'C:\BgInfo\BgInfoConfig.bgi'
			Uri = "https://github.com/Circadence-Corp/BR22-DSC/raw/$Branch/Downloads/BgInfo/aippc.bgi"
			DependsOn = '[Computer]JoinDomain'
		}

		Script MakeShortcutForBgInfo {
			SetScript = {
				$s = (New-Object -COM WScript.Shell).CreateShortcut('C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BgInfo.lnk')
				$s.TargetPath = 'bginfo64.exe'
				$s.Arguments = 'c:\BgInfo\BgInfoConfig.bgi /accepteula /timer:0'
				$s.Description = 'Ensure BgInfo starts at every logon, in context of the user signing in (only way for stable use!)'
				$s.Save()
			}
			GetScript = {
				if (Test-Path -LiteralPath 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BgInfo.lnk') {
					return @{
						result = $true
					}
				}
				else {
					return @{
						result = $false
					}
				}
			}

			TestScript = {
				if (Test-Path -LiteralPath 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BgInfo.lnk') {
					return $true
				}
				else {
					return $false
				}
			}
			DependsOn = @('[xRemoteFile]DownloadBginfo', '[cChocoPackageInstaller]InstallSysInternals')
		}

		Script MakeCmdShortcut {
			SetScript = {
				$s = (New-Object -COM WScript.Shell).CreateShortcut('C:\Users\Public\Desktop\Cmd.lnk')
				$s.TargetPath = 'cmd.exe'
				$s.Description = 'Cmd.exe shortcut on everyones desktop'
				$s.Save()
			}
			GetScript = {
				if (Test-Path -LiteralPath 'C:\Users\Public\Desktop\Cmd.lnk') {
					return @{
						result = $true
					}
				}
				else {
					return @{
						result = $false
					}
				}
			}

			TestScript = {
				if (Test-Path -LiteralPath 'C:\Users\Public\Desktop\Cmd.lnk') {
					return $true
				}
				else {
					return $false
				}
			}
			DependsOn = '[Computer]JoinDomain'
		}

		xRemoteFile GetMcasData
        {
            DestinationPath = 'C:\LabData\McasData.zip'
            Uri = "https://github.com/Circadence-Corp/BR22-DSC/raw/master/Downloads/MCAS/Demo%20files.zip"
            DependsOn = @('[Computer]JoinDomain','[Registry]SchUseStrongCrypto','[Registry]SchUseStrongCrypto64')
        }

        # Place on all Users Desktops; can't put in LisaV's else her profile changes since she never logged in yet...
        Archive McasDataTop
        {
            Path = 'C:\LabData\McasData.zip'
            Destination = 'C:\Users\Public\Desktop\DemoFiles'
            Ensure = 'Present'
            DependsOn = '[xRemoteFile]GetMcasData'
            Force = $true
        }
	} #end Node Role 'Client'

	Node $AllNodes.where( { $_.Role -contains 'Victim' }).NodeName {
		LocalConfigurationManager
		{
			ConfigurationMode = 'ApplyOnly'
			RebootNodeIfNeeded = $true
			ActionAfterReboot = 'ContinueConfiguration'
			AllowModuleOverwrite = $true
		}

		Service DisableWindowsUpdate
		{
			Name = 'wuauserv'
			State = 'Stopped'
			StartupType = 'Disabled'
			Ensure = 'Present'
		}

		Service WmiMgt
		{
			Name = 'WinRM'
			State = 'Running'
			StartupType = 'Automatic'
			Ensure = 'Present'
		}

		xGroup AddAdmins
		{
			GroupName = 'Administrators'
			MembersToInclude = @("$NetBiosName\Helpdesk", "$NetBiosName\JeffL")
			Ensure = 'Present'
			DependsOn = '[Computer]JoinDomain'
		}

		xRemoteFile DownloadBginfo
		{
			DestinationPath = 'C:\BgInfo\BgInfoConfig.bgi'
			Uri = "https://github.com/Circadence-Corp/BR22-DSC/raw/$Branch/Downloads/BgInfo/victimpc.bgi"
			DependsOn = '[Computer]JoinDomain'
		}

		xMpPreference DefenderSettings
		{
			Name = 'DefenderSettings'
			ExclusionPath = 'C:\Tools'
			DisableRealtimeMonitoring = $true
			DisableArchiveScanning = $true
		}

		Script MakeShortcutForBgInfo {
			SetScript = {
				$s = (New-Object -COM WScript.Shell).CreateShortcut('C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BgInfo.lnk')
				$s.TargetPath = 'bginfo64.exe'
				$s.Arguments = 'c:\BgInfo\BgInfoConfig.bgi /accepteula /timer:0'
				$s.Description = 'Ensure BgInfo starts at every logon, in context of the user signing in (only way for stable use!)'
				$s.Save()
			}
			GetScript = {
				if (Test-Path -LiteralPath 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BgInfo.lnk') {
					return @{
						result = $true
					}
				}
				else {
					return @{
						result = $false
					}
				}
			}

			TestScript = {
				if (Test-Path -LiteralPath 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BgInfo.lnk') {
					return $true
				}
				else {
					return $false
				}
			}
			DependsOn = @('[xRemoteFile]DownloadBginfo', '[cChocoPackageInstaller]InstallSysInternals')
		}

		Script EnsureTempFolder
		{
			SetScript = 
			{
				New-Item -Path 'C:\Temp\' -ItemType Directory
			}
			GetScript = 
			{
				if (Test-Path -PathType Container -LiteralPath 'C:\Temp') {
					return @{
						result = $true
					}
				}
				else {
					return @{
						result = $false
					}
				}
			}
			TestScript = {
				if (Test-Path -PathType Container -LiteralPath 'C:\Temp') {
					return $true
				}
				else {
					return $false
				}
			}
		}

		Script MakeCmdShortcut
		{
			SetScript = 
			{
				$s = (New-Object -COM WScript.Shell).CreateShortcut('C:\Users\Public\Desktop\Cmd.lnk')
				$s.TargetPath = 'cmd.exe'
				$s.Description = 'Cmd.exe shortcut on everyones desktop'
				$s.Save()
			}
			GetScript = 
			{
				if (Test-Path -LiteralPath 'C:\Users\Public\Desktop\Cmd.lnk') {
					return @{
						result = $true
					}
				}
				else {
					return @{
						result = $false
					}
				}
			}

			TestScript = 
			{
				if (Test-Path -LiteralPath 'C:\Users\Public\Desktop\Cmd.lnk') {
					return $true
				}
				else {
					return $false
				}
			}
			DependsOn = '[Computer]JoinDomain'
		}

		# every 10 minutes open up a new CMD.exe as RonHD
		ScheduledTask RonHd
		{
			TaskName = 'SimulateRonHdProcess'
			ScheduleType = 'Once'
			Description = 'Simulates RonHD exposing his account via an interactive or scheduled task manner.  In this case, we use scheduled task. This mimics the machine being managed.'
			Ensure = 'Present'
			Enable = $true
			TaskPath = '\AatpScheduledTasks'
			ExecuteAsCredential = $RonHdDomainCred
			ActionExecutable = 'cmd.exe'
			Priority = 7
			DisallowHardTerminate = $false
			RepeatInterval = '00:10:00'
			RepetitionDuration = 'Indefinitely'
			StartWhenAvailable = $true
			DependsOn = '[Computer]JoinDomain'
		}

		xRemoteFile GetCtfA
		{
			DestinationPath = 'C:\LabScripts\Backup\ctf-a.zip'
			Uri = "https://github.com/Circadence-Corp/BR22-DSC/blob/$Branch/Downloads/AATP/ctf-a.zip?raw=true"
			DependsOn = '[Computer]JoinDomain'
		}
		Archive UnzipCtfA
		{
			Path = 'C:\LabScripts\Backup\ctf-a.zip'
			Destination = 'C:\LabScripts\ctf-a'
			Ensure = 'Present'
			Force = $true
			DependsOn = '[xRemoteFile]GetCtfA'
		}

		xRemoteFile GetAatpSaPlaybook
		{
			DestinationPath = 'C:\LabScripts\Backup\aatpsaplaybook.zip'
			Uri = "https://github.com/Circadence-Corp/BR22-DSC/blob/$Branch/Downloads/AATP/aatpsaplaybook.zip?raw=true"
			DependsOn = '[Computer]JoinDomain'
		}

		Archive UnzipAatpSaPlaybook
		{
			Path = 'C:\LabScripts\Backup\aatpsaplaybook.zip'
			Destination = 'C:\LabScripts\AatpSaPlaybook'
			Ensure = 'Present'
			Force = $true
			DependsOn = '[xRemoteFile]GetAatpSaPlaybook'
		}
	} #end Node Role 'Victim'
} #end of configuration