JenkinsFetchArtifacts
=====================

This powershell script aims to fix the issue with jenkins pipeline plugin, where manually triggered job in pipeline doesn't download the artifacts from the correct upstream build number.

Usage:

```
  powershell -File FetchArtifacts.ps1 <Upstream build name to fetch artifacts from> <artifacts name>
```

This will fetch the artifacts from upstream build (specified by first parameter) for the build number which caused the build that is executing this script. If it fails to identify any build which triggered current build it will fetch the last successful <upstream> builds artifacts (this might happen in case when you directly trigger the build which is executing this script, instead of triggering it from pipeline view).

This script uses the jenkins environment variables to identify the current job details and the jenkins url.
