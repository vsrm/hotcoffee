Param(
  [string]$applicationPath,
  [string]$WebAppPoolName,
  [string]$WebsitePort,
  [string]$UserName,
  [string]$Password 
)

Configuration FabFiber
{
	Import-DscResource -Module xWebAdministration

	Node $AllNodes.NodeName
	{
		File CopyDeploymentBits
		{
			Ensure = "Present"
			Type = "Directory"
			Recurse = $true
			SourcePath = $applicationPath
			DestinationPath = $Node.DeploymentPath
		}

		WindowsFeature AspNet45
		{
			Ensure = "Present"
			Name = "Web-Asp-Net45"
		}

		WindowsFeature IIS
		{
			Ensure = "Present"
			Name = "Web-Server"
			DependsOn = "[WindowsFeature]AspNet45"
		}	

		xWebAppPool NewWebAppPool 
        { 
            Name   = $WebAppPoolName 
            Ensure = "Present" 
            State  = "Started" 
        } 	

		xWebsite FabrikamWebSite
		{
			Ensure = "Present"
			Name = $Node.WebsiteName
			State = "Started"
			PhysicalPath = $Node.DeploymentPath
			ApplicationPool = $WebAppPoolName
			BindingInfo = MSFT_xWebBindingInformation 
                { 
                 Port = $WebsitePort
                } 
			DependsOn = "[WindowsFeature]IIS"
		}
		
		Script UpdateNewWebAppPoolIdentity
        {
            SetScript =
            {            
                $poolName = [String]('IIS:\AppPools\'+$using:WebAppPoolName)
                $pool = get-item($poolName);

                $pool.processModel.userName = [String]($using:UserName)
                $pool.processModel.password = [String]($using:Password)
                $pool.processModel.identityType = [String]("SpecificUser");

                $pool | Set-Item 
            }        

            GetScript = { return @{} }

            TestScript = { return $false }               
        }        
	}
}

Copy-Item $applicationPath\DSCModule\* $env:psmodulepath.split(";")[1] -Force -Recurse
FabFiber -ConfigurationData $ConfigData -Verbose
