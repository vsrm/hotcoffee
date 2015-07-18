param
(
	# Location of the source deployment bits and DSC Module
	[String]$SourcePath =  "C:\agent\_work\330fb393f\HotCoffee\WebApplication1\WebApplication1\bin",

	# Destination path for the DSC module
	[String]$dscModulePath = "C:\Program Files\WindowsPowerShell\Modules"
)

Copy-Item -Path "$SourcePath\DSCModule\xWebAdministration" -Destination "$dscModulePath" -Recurse -Force
