param(
		[Parameter(Mandatory=$True, Position=0)]
			[string]$JobToDownloadArtifactsFrom, 
		[Parameter(Mandatory=$True, Position=1)]
			[string]$ArtifactsName,
		[Parameter(Position=2)]
			[string]$Destination=(Get-Location).Value
	);

Function Get-UpstreamBuildNo{
	param(
		[Parameter(Mandatory=$False, Position=1)]
			[string]$CurrentJobName = (Get-Item env:JOB_NAME).Value, 
		[Parameter(Mandatory=$False, Position=2)]
			[string]$CurrentBuildNo = (Get-Item env:BUILD_NUMBER).Value
	);

	if($CurrentJobName -eq $JobToDownloadArtifactsFrom) {
		return $currentBuildNo;
	}

	if(!$CurrentJobName -or !$CurrentBuildNo) {
		Write-Host -Foregroundcolor Red "Cannot find a build for $JobToDownloadArtifactsFrom associated with $CurrentJobName#$CurrentBuildNo. Falling back to last successful build of $JobToDownloadArtifactsFrom.";
		return "lastSuccessfulBuild";
	}
	
	Write-Host "Trying to find a $JobToDownloadArtifactsFrom build which triggered $CurrentJobName#$CurrentBuildNo"

	$webClient = New-Object Net.WebClient;
	$buildDetails = $webClient.DownloadString("$JenkinsServerUrl/job/$CurrentJobName/$CurrentBuildNo/api/json");

	$parentBuildNo = ([regex]'\"upstreamBuildNumber\":(\d+)').Match($buildDetails).Groups[1].Value;
	$parentJobName = ([regex]'\"upstreamProject\":\"(.+?)\"').Match($buildDetails).Groups[1].Value;

	return Get-UpstreamBuildNo -currentJobName $parentJobName -currentBuildNo $parentBuildNo;
}

Function Get-Artifacts {
	param(
	[Parameter(Mandatory=$True, Position=1)]
		[string]$BuildNo,
	);

	$webClient = New-Object Net.WebClient;
	$artifact = "$Destination\$ArtifactsName.zip";
	$webClient.DownloadFile("$JenkinsServerUrl/job/$From/$BuildNo/artifact/*zip*/$ArtifactsName.zip", $artifact);
}

Function Extract-Artifacts {
	$shell = New-Object -com Shell.Application;
	$archive = $shell.Namespace("$Destination\$ArtifactsName.zip");
	foreach($file in $archive.items()) {
		$shell.Namespace($Destination).copyhere($file);
	}
}

Write-Host "Starting to fetch artifacts from $JobToDownloadArtifactsFrom...";

$JenkinsServerUrl = (Get-Item env:JENKINS_URL).Value;

$upstreamBuildNo = Get-UpstreamBuildNo;
try {
	Get-Artifacts -BuildNo $upstreamBuildNo;
	Extract-Artifacts;
	Write-Host "Successfuly downloaded artifacts from $JobToDownloadArtifactsFrom"
} catch [Exception] {
	Write-Host -Foregroundcolor Red $_.Exception.Message;
	Write-Host -Foregroundcolor Red "Terminating because of the exception above."
	exit 1;
}
