#import needed modules
using module '..\..\helper\HelperFunctions.psm1'
using module '..\..\helper\JiraHelper.psm1'
using module '..\..\helper\ConfluenceHelper.psm1'
using module '..\..\atlassian\Jira.psm1'
using module '..\..\atlassian\Confluence.psm1'

#import needed files
. ..\..\..\constants.ps1

$HelperFunctions = [HelperFunctions]::new()
$Jira = [Jira]::new($authJIRAIntern, "https://webforms-jira-intern.raiffeisenbank.at")
$JiraHelper = [JiraHelper]::new($Jira, $HelperFunctions)
$Confluence = [Confluence]::new($authJIRAIntern, "https://collab.raiffeisenbank.at")
$ConfluenceHelper = [ConfluenceHelper]::new($Confluence, $HelperFunctions)


$description = "Aufgrund der Story RLB-25779: Fuer die Steiermark muss hier ein Zwischenrelease eingeschoben werden."
$name = "Mein ELBA 3.1.1"
$releaseDate = "23.11.2021"
$startDate = "16.11.2021"
$projectName = "RLB Projektmanagement"
$projectId = $Jira.getProjectIdByProjectName($projectName)

$Jira.createNewFixVersion($description, $name, $releaseDate, $startDate, $projectId)