param
(
    # Target nodes to apply the configuration
    [string]$NodeName =  "myshuttlevmqa.cloudapp.net",

	# Admin user name for the target node
	[String]$UserName = ".\vijayma",

	# Password to connect to the target node
    [String]$Password = "Password~1",

	# WinRM port to connect to the target on
	[Int]$PublicEndpoint = 50050,

	# Location of the source deployment bits and DSC Module
	[String]$SourcePath =  "c:\temp\bin",

	# Temporary Location on target to copy the deployment bits to
	[String]$StagingPath =  "c:\temp",

	# Destination path for the DSC module
	[String]$dscModulePath = "C:\Program Files\WindowsPowerShell\Modules"	
)

Write-Verbose -Verbose $env:PSModulePath
Write-Verbose -Verbose $SourcePath
$loc = Get-Location
Write-Verbose -Verbose $loc.Path

$SecurePassword = ConvertTo-SecureString –String $Password –AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $UserName, $SecurePassword

# copy the modules and build
$psSessionOption = New-PSSessionOption -SkipCACheck
$psSession = New-PSSession -ComputerName $NodeName -Credential $cred -Port $PublicEndpoint -SessionOption $psSessionOption -Authentication Negotiate -UseSSL
Write-Verbose -Verbose "Created PS Session to $NodeName : $PublicEndpoint"
Copy-Item -Path $SourcePath -Destination $StagingPath -ToSession $psSession -Recurse -Force
Write-Verbose -Verbose "copied from $SourcePath on agent to $StagingPath on $NodeName"
Copy-Item -Path "$SourcePath\DSCModule\xWebAdministration" -Destination "$dscModulePath" -ToSession $psSession -Recurse -Force
Write-Verbose -Verbose "copied from $SourcePath\DSCModule\xWebAdministration on agent to $dscModulePath on $NodeName"
Remove-PSSession -Session $psSession

