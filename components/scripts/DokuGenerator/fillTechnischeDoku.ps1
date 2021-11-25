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
$Confluence.Space = "RDN"
$DokuPageId = 65408504

#### FUNCTIONS ####
function handlePage($pageTitle, $ancestorPageId) {
    return $Confluence.getPageByTitle($pageTitle);
    #Es werden keine neue Seiten hier angelegt hier wird nur Inhalt gefüllt
    # if ($null -eq $page) {
    #     if ($null -ne $ancestorPageId) {
    #         $body = $Confluence.getBodyForPageCreation($pageTitle, $ancestorPageId)
    #     }
    #     if ($null -eq $ancestorPageId) {
    #         $body = $Confluence.getBodyForPageCreation($pageTitle)
    #     }
    #     $Confluence.post("/rest/api/content/", $body);
    #     return $Confluence.getPageByTitle($pageTitle);
    # }
    # return $page

}

#$jql = 'key="RLB-17612"'
$jql = 'project = RLB AND component = "BC-GKA - Girokontoänderung" AND updated >= -24h AND type ="Story"'
$streckenName = "BC-GKA - Girokontoaenderung"
$issues = $Jira.getIssuesByJQL($jql);
$issues = $issues.issues

$ComponentObject = $JiraHelper.convertIssuesToObject($issues)
$Components = $ComponentObject.components
$IssueObjectJson = $ComponentObject | ConvertTo-Json -Depth 10
Set-Clipboard -Value $IssueObjectJson

foreach ($Component in $Components) {
    $ComponentName = $Component.name
    $ComponentPageName = $ComponentName
    $ComponentPage = handlePage $ComponentPageName $DokuPageId
    if ($null -ne $ComponentPage) {
        foreach ($Form in $Component.forms) {
            $ComponentPageId = $ComponentPage.id
            $FormName = $Form.name
            $PageName = "Technisch - $FormName"
            $FormPage = handlePage $PageName $ComponentPageId
            if ($null -ne $Formpage) {
                $Issues = $Form.issues
                $htmlTable = $JiraHelper.HelperFunctions.getHTMLTableForIssues($Issues, $Jira.BaseUrl)
                Set-Clipboard -Value $htmlTable
                $pageBody = $Confluence.getBodyForPageUpdate($FormPage, $htmlTable)
                $pageUrl = "/rest/api/content/" + $FormPage.id
                $Confluence.put($pageUrl, $pageBody)
            }
        }
    }
    
}

