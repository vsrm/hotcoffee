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
	[String]$dscModulePath = "C:\Program Files\WindowsPowerShell\Modules",
	
	# Destination path for Website content
    [String]$DestinationPath =  "C:\inetpub\wwwroot\remotehc",

    # Name of the website to create
    [String]$WebSiteName =  "remotehc",
	
	# IIS Port to host the website on
    [Int]$Port = 11001
)

Write-Verbose -Verbose $env:PSModulePath
Write-Verbose -Verbose $SourcePath


configuration MyWeb
{
	# Import the module that defines custom resources
    # Import-DscResource -Module xWebAdministration
	# Import-DscResource -Module PSDesiredStateConfiguration

    Node $NodeName
    {	
        # Install the ASP .NET 4.5 role
        WindowsFeature AspNet45
        {
            Ensure          = "Present"
            Name            = "Web-Asp-Net45"
        }

        # Install the IIS role
        WindowsFeature IIS
        {
            Ensure          = "Present"
            Name            = "Web-Server"
        }

        # Stop the default website
        xWebsite DefaultSite 
        {
            Ensure          = "Present"
            Name            = "Default Web Site"
            State           = "Stopped"
            PhysicalPath    = "C:\inetpub\wwwroot"
            DependsOn       = "[WindowsFeature]IIS"
        }

        # Copy the website content
        File WebContent
        {
            Ensure          = "Present"
            SourcePath      = "$StagingPath\bin"
            DestinationPath = $DestinationPath
            Recurse         = $true
            Type            = "Directory"
            DependsOn       = "[WindowsFeature]AspNet45"
        }       

        # Create the new Website
        xWebsite NewWebsite
        {#
            Ensure          = "Present"
            Name            = $WebSiteName
            State           = "Started"
            PhysicalPath    = $DestinationPath
            BindingInfo     = MSFT_xWebBindingInformation  
            {  
                Protocol              = "HTTP"
                Port                  = $Port
            }
        }
    }
}

#Copy-Item -Path "$SourcePath\DSCModule\xWebAdministration" -Destination "$dscModulePath" -Recurse -Force

#MyWeb

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

#do actual deployment
#$cimSessionOption = New-CimSessionOption -UseSsl -SkipCACheck
#$cimSession = New-CimSession -SessionOption $cimSessionOption -ComputerName $NodeName -Port $PublicEndpoint -Authentication Negotiate -Credential $cred
Write-Verbose -Verbose "Starting DSC Configuration"
#Start-DscConfiguration -CimSession $cimSession -Path .\MyWeb -Verbose -Wait -Force
