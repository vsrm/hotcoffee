# Copies the deployment payload and DSCModule from Agent machine to target machine using Remote PS Session

param
(
    # Target nodes to apply the configuration
    [string]$NodeName =  "",

	# Admin user name for the target node
	[String]$UserName = "",

	# Password to connect to the target node
    [String]$Password = "",

	# WinRM port to connect to the target on
	[Int]$PublicEndpoint = 50050,

	# Location of the source deployment bits and DSC Module
	[String]$SourcePath =  "c:\temp\bin",

	# Temporary Location on target to copy the deployment bits to
	[String]$StagingPath =  "c:\temp"	
)

Write-Verbose -Verbose "Running with PSModulePath as $env:PSModulePath"
Write-Verbose -Verbose "NodeName $NodeName"
Write-Verbose -Verbose "UserName $UserName"
Write-Verbose -Verbose "Password $Password"
Write-Verbose -Verbose "PublicEndpoint $PublicEndpoint"
Write-Verbose -Verbose "SourcePath $SourcePath"
Write-Verbose -Verbose "StagingPath $StagingPath"

$loc = Get-Location
Write-Verbose -Verbose "Current Working Directory $loc.Path"

$dscModulePath = $env:PSModulePath.Split(';')[0]
Write-Verbose -Verbose "Chosen DSC Module Path $dscModulePath"

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

