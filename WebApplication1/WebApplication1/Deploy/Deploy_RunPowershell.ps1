param
(
    # Target nodes to apply the configuration
    [string]$NodeName =  "myhotcofeevm.cloudapp.net",

    # Name of the website to create
    [String]$WebSiteName =  "remotehc",

    # Source Path for Website content
    [String]$SourcePath =  "",

    # Destination path for Website content
    [String]$DestinationPath =  "C:\inetpub\wwwroot\remotehc",

    [String]$UserName = ".\myadmin",

    [String]$Password = "Microsoft~1",

    [Int]$Port = 1100,

    [Int]$PublicEndpoint = 49876
)

configuration MyWeb
{
    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration

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
            SourcePath      = "$SourcePath"
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

$env:PSModulePath
MyWeb

# copy the modules and build

$SecurePassword = ConvertTo-SecureString –String $Password –AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $UserName, $SecurePassword
$cimSessionOption = New-CimSessionOption -UseSsl -SkipCACheck
$cimSession = New-CimSession -SessionOption $cimSessionOption -ComputerName $NodeName -Port $PublicEndpoint -Authentication Negotiate -Credential $cred
Start-DscConfiguration -CimSession $cimSession -Path .\MyWeb -Verbose -Wait -Force
