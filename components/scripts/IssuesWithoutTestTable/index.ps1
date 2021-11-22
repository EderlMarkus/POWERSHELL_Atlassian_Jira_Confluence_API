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

$jql = 'project = RLB AND issuetype in (Task, Change, Feature, Story) AND fixVersion = "Debitkartenservice 5.0"&fields=issuelinks,status,summary'
$issues = $Jira.getIssuesByJQL($jql, 200)
$issues = $issues.issues;
$issuesWithoutTestSet = @()
$issuesWithTestSet = @()

function getStatusSymbolAsHTML($issue) {
    $status = $issue.fields.status.name
    if ($status -eq "In Review") {
        $color = "#0052cc"
    }
    elseif ($status -eq "Ready for Rollout") {
        $color = "#00875a"
    }
    elseif ($status -eq "Geschlossen") {
        $color = "#00875a"
    }
    else {
        $color = "red"
    }
    return '<strong style="background: ' + $color + ';color:#fff;border-radius:5px;padding:2px;font-size:10px;">' + $status + '</strong>'
}

foreach ($issue in $issues) {
    $hasTestSet = $false
    $issuelinks = $issue.fields.issuelinks
    for ($i = 0; $i -lt $issuelinks.Count; $i++) {
        $issuelink = $issuelinks[$i]
        $inwardIssue = $issuelink.inwardIssue
        $isTestSet = $inwardIssue.fields.issuetype.id -eq "10601" -OR $inwardIssue.fields.issuetype.id -eq "10600"
        if ($isTestSet) {
            $hasTestSet = $true
            break
        }
    }
    if ($hasTestSet -eq $false) {
        $issuesWithoutTestSet += $issue
    }
    if ($hasTestSet -eq $true) {
        $issuesWithTestSet += $issue
    }

}

$jsonWithout = $issuesWithoutTestSet | ConvertTo-Json -Depth 10
$jsonWith = $issuesWithTestSet | ConvertTo-Json -Depth 10

Set-Clipboard -Value $jsonWithout
Set-Clipboard -Value $jsonWith

$htmlString = "<table><tr><th>Zusammenfassung</th><th>Link</th><th>Grund</th></tr>"

foreach ($issue in $issuesWithoutTestSet) {
    $summary = $issue.fields.summary
    $issueKey = $issue.key
    $link = "https://webforms-jira-intern.raiffeisenbank.at/browse/$issueKey"
    $symbolText = getStatusSymbolAsHTML($issue)
    $htmlString += '<tr><td>' + $summary + '</td><td><a href="' + $link + '">' + $issuekey + ', ' + $symbolText + '</a></td><td>Noch keinen Testfall dafür erstellt bzw. verknüpft</td></tr>'
}
$htmlString += "</table>"
Set-Content -Path ./output.html -Value $htmlString

$pageIdConfluence = 65410576
$page = $Confluence.getPageById($pageIdConfluence)
$pageBody = $Confluence.getBodyForPageUpdate($page, $htmlString)
$Confluence.put("/rest/api/content/$pageIdConfluence", $pageBody)

$pass = "autobus1" | ConvertTo-SecureString -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PsCredential('wlnedmr', $pass)


$parameters = @{
    Name       = "V"
    PSProvider = "FileSystem"
    Root       = "https://antrag.tst.raiffeisenbank.at/webdav"
    Credential = $Cred
}
New-PSDrive @parameters