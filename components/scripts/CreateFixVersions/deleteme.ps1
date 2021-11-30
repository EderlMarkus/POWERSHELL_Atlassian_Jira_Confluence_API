#import needed modules
using module '..\..\atlassian\Jira.psm1'

#import needed files
. ..\..\..\constants.ps1

$Jira = [Jira]::new($authJIRAIntern, "https://webforms-jira-intern.raiffeisenbank.at")

$issueKey = "RLB-25951"
$description = "Meine neue Desc"
$issue = $Jira.updateDescription($issueKey, $description)
