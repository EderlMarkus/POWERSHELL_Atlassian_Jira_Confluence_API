#import needed modules
using module '..\..\helper\HelperFunctions.psm1'
using module '..\..\helper\JiraHelper.psm1'
using module '..\..\helper\ConfluenceHelper.psm1'
using module '..\..\atlassian\Jira.psm1'
using module '..\..\atlassian\Confluence.psm1'

#import needed files
. ..\..\..\constants.ps1
#FUNCTIONS
function handleConfluencePage($PageTitle, $AncestorPageId, $Confluence) {
    $Confluence.ancestorPageId = $AncestorPageId
    $PageTitle = $Confluence.convertUmlaut($PageTitle)
    $Confluence.deletePageByTitle($PageTitle, $true);
    $pageBody = $Confluence.getBodyForPageCreation($PageTitle)
    $Confluence.post("/rest/api/content/", $pageBody)
    return $Confluence.getPageByTitle($PageTitle)
}

#SCRIPT EXECUTION
$HelperFunctions = [HelperFunctions]::new()
$JiraIntern = [Jira]::new($authJIRAIntern, "https://webforms-jira-intern.raiffeisenbank.at")
$JiraInternHelper = [JiraHelper]::new($JiraIntern, $HelperFunctions)

$Confluence = [Confluence]::new($authJIRAIntern, "https://collab.raiffeisenbank.at")
$ConfluenceHelper = [ConfluenceHelper]::new($Confluence, $HelperFunctions)

$HelperFunctions = [HelperFunctions]::new()
$JiraTest = [Jira]::new($authJIRAIntern, "https://webforms-jira.tst.raiffeisenbank.at/")
$JiraTestHelper = [JiraHelper]::new($JiraTest, $HelperFunctions)

#Pageid 39093198 = https://collab.raiffeisenbank.at/display/RLBDIG/Markus+Test
$Confluence.Space = "RDN"
$DokuPageId = 65408504

#Variablen für StreckenDoku
$componentenName = "BC-RKS - Debitkarten"
$WorkflowName = "DS-Debitkarten_5.0"
$fixeUnterseiten = @("Fachlich", "Technisch")

#Strecke als Confluencepage anlegen
$ComponentConfluencePage = handleConfluencePage $componentenName $DokuPageId $Confluence

#Formularseiten (Workflow-Steps) als Unterseiten anlegen
$Workflow = $JiraTest.getWorkflowByWorkflowName($WorkflowName)
$Steps = $Workflow.workflow.steps.step
$Steps += @{name = "$componentenName - Gesamt" }
foreach ($Step in $Steps) {
    $AncestorPageId = $ComponentConfluencePage.id
    $FormularName = $Step.name
    $FormularPage = handleConfluencePage $FormularName $AncestorPageId $Confluence
    foreach ($Unterseite in $fixeUnterseiten) {
        $AncestorPageId = $FormularPage.id
        $PageTitle = "$Unterseite - $FormularName"
        $UnterseitePage = handleConfluencePage $PageTitle $AncestorPageId $Confluence
    }
}

# $jql = 'component = "' + $componentenName + '"&maxResults=1000'
# $IssueDump = $JiraInternHelper.Jira.getIssuesByJQL($jql);
# $Issues = $JiraInternHelper.convertIssuesToObject($issueDump.issues);
