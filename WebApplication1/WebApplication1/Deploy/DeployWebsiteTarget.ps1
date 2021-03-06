param
(    
	# Fixed node name as localhost
	[String]$NodeName = "localhost",
	
	# Temporary Location on target to copy the deployment bits to
	[String]$StagingPath =  "c:\temp",
		
	# Destination path for Website content
    [String]$DestinationPath =  "C:\inetpub\wwwroot\remotehc",

    # Name of the website to create
    [String]$WebSiteName =  "remotehc",
	
	# IIS Port to host the website on
    [Int]$Port = 11001
)

configuration MyWeb
  {
	# Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration
	Import-DscResource -Module PSDesiredStateConfiguration

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
        {
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

MyWeb

Write-Verbose -Verbose "Starting DSC Configuration"
Start-DscConfiguration -Path .\MyWeb -Verbose -Wait -Force
