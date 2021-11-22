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


$issueStati = @();
$data = Get-Content export.json | ConvertFrom-Json
$projectName = "RLB Projektmanagement"
$projectId = $Jira.getProjectIdByProjectName($projectName)
$componentName = "BC-RKS - Debitkarten"

function checkIfElementExists($element, $array) {
    for ($i = 0; $i -lt $array.Count; $i++) {
        $item = $array[$i].name
        if ($element -eq $item) {
            return $i
        }
    }
    return -1
}

function getKeyByJQL($jql) {
    $issue = $Jira.getIssuesByJQL($jql)
    $issue = $issue.issues[0];
    return $issue.key
}

### Create Epic
$epicKey = "RLB-26055"

foreach ($workflow in $data.workflowActionDefinitions) {
    $issueStatus = $workflow.issueStatus
    $index = checkIfElementExists $issueStatus $issueStati
    $estimationTime = $workflow.calculation.Length / 50 / 20
    $estimationTime = [Math]::Round([Math]::Ceiling($estimationTime), 0)

    if ($index -gt -1) {
        $issueStati[$index].wfas += @{
            name           = $workflow.name
            estimationTime = $estimationTime
        }
        $issueStati[$index].estimationTime += $estimationTime
    }
    if ($index -eq -1) {
        $issueStati += @{
            name           = $issueStatus
            wfas           = @(
                @{
                    name           = $workflow.name
                    estimationTime = $estimationTime
                }
            )
            estimationTime = $estimationTime
        }
        
    }
}

foreach ($issueStatus in $issueStati) {
    $projectId = $Jira.getProjectIdByProjectName("RLB Projektmanagement")
    $issuetypeId = $Jira.getIssueTypeIdByIssueTypeName("Feature")
    $componentIds = @($Jira.getComponentIdByComponentName($componentName, $projectId))
    $issueStatusName = $issueStatus.name;
    $issueStatusName = $Jira.convertUmlaut($issueStatusName);
    $summary = "GraalVM Umstellung / Formular: $issueStatusName"
    $reporterId = "wlnedmr"
    $assigneeId = "wlnedmr"
    $priority = "3"
    $Jira.createNewIssue($projectId, $issuetypeId, $componentIds, $summary, $reporterId, $assigneeId, $priority)
    $jql = 'project = "RLB Projektmanagement" AND component = "' + $componentName + '" AND summary ~ "' + $summary + '"'
    $featureKey = getKeyByJQL($jql)
    $Jira.addEpicLink($featureKey, $epicKey)
    $description = "h3.1.Beschreibung
    Hier wird die GraalVM-Umstellung fuer die WFAs (als Stories) zum Formular $issueStatusName abgehandelt.
    h3.3.Formular
    $issueStatusName"
    $Jira.updateDescription($featureKey, $description)
    $estimationTime = $issueStatus.estimationTime
    $Jira.addEstimationToIssue($featureKey, $estimationTime)

    foreach ($wfa in $issueStatus.wfas) {
        $wfaName = $wfa.name
        $wfaName = $Jira.convertUmlaut($wfaName);
        $summary = "GraalVM Umstellung / WFA: $wfaName"
        $issuetypeId = $Jira.getIssueTypeIdByIssueTypeName("Story")
        $reporterId = "wlnedmr"
        $assigneeId = "wlnedmr"
        $priority = "3"
        $Jira.createNewIssue($projectId, $issuetypeId, $componentIds, $summary, $reporterId, $assigneeId, $priority)
        $jql = 'project = "RLB Projektmanagement" AND component = "' + $componentName + '" AND summary ~ "' + $summary + '"'
        $storyKey = getKeyByJQL($jql)
        $description = "h3.1.Beschreibung
        Hier wird die Graal-VM Umstellung zur WFA $wfaName abgehandelt.
        h3.3.Formular
        $issueStatusName"
        $Jira.updateDescription($storyKey, $description)
        $Jira.addEstimationToIssue($storyKey, $wfa.estimationTime)
        $Jira.addIssueLink($featureKey, $storyKey)
    }
}





