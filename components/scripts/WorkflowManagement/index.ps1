#import needed modules
using module '..\..\helper\HelperFunctions.psm1'
using module '..\..\helper\JiraHelper.psm1'
using module '..\..\helper\ConfluenceHelper.psm1'
using module '..\..\atlassian\Jira.psm1'
using module '..\..\atlassian\Confluence.psm1'

#import needed files
. ..\..\..\constants.ps1

# Result will be saved in "workflow.json" when running this script
#SCRIPT EXECUTION
$HelperFunctions = [HelperFunctions]::new()
$Jira = [Jira]::new($authJIRAIntern, "https://webforms-jira.tst.raiffeisenbank.at")
$JiraHelper = [JiraHelper]::new($Jira, $HelperFunctions)

$Workflows = $Jira.getWorkflows()
$WorkflowNames = @()

foreach ($Workflow in $Workflows) {
    $WorkflowNames += $Workflow.Name
}

$retArray = @()
foreach ($WorkflowName in $WorkflowNames) {
    $Strecke = @{
        name  = $WorkflowName
        steps = @()
    }
    $Workflow = $Jira.getWorkflowByWorkflowName($WorkflowName)
    $Steps = $Workflow.workflow.steps.step
    foreach ($Step in $Steps) {

        $Strecke.steps += $Step.name
    }
    $retArray += $Strecke
}

$json = $retArray | ConvertTo-Json -Depth 3 
$json | Out-File "./workflows.json"
Set-Clipboard -Value $json