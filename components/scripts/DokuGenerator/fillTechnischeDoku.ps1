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

$jql = 'fixVersion="Debitkartenservice 5.0"&fields=description&expand=renderedFields'
$issues = $Jira.getIssuesByJQL($jql);
$issues = $issues.issues

$IssueObject = $JiraHelper.convertIssuesToObject($issues)
$IssueObjectJson = $IssueObject | ConvertTo-Json -Depth 10
Set-Clipboard -Value $IssueObjectJson

$FormNames = @();

foreach ($Issue in $IssueObject) {
    foreach ($FormName in $Issue.formNames) {
        $alreadyExists = $ConfluenceHelper.HelperFunctions.checkIfArrayContains($FormNames, $FormName)
        if ($alreadyExists -eq $false) {
            $FormNames += $FormName
        }
    }
}

$json = $FormNames | ConvertTo-Json
Set-Clipboard -Value $json

foreach ($FormName in $FormNames) {
    
}