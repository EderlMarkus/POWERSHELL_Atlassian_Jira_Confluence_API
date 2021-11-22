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
######################## FUNCTIONS ########################
function getLookUpDateRange() {
    $Today = (Get-Date).Date 
    #$Sunday = $Today.AddDays(-8)
    $Sunday = $Today.AddDays(0 - $Today.DayOfWeek.value__)
    $Saturday = $Sunday.AddDays(5)
    $Sunday = Get-Date $Sunday -Format yyyy-MM-dd
    $Saturday = Get-Date $Saturday -Format yyyy-MM-dd
    return @{
        start = $Sunday;
        end   = $Saturday
    }
}
function getLastSunday() {

}
function getComponents($Issues) {
    $retArray = @()
    foreach ($Issue in $Issues) {
        $Components = $Issue.fields.components
        foreach ($Component in $Components) {
            $ComponentName = $Component.name
            if ($retArray.Contains($ComponentName) -eq $false) {
                $retArray += $ComponentName
            }
        }
    }
    return $retArray
}
function convertIssuesToHTMLString($Issues) {
    $retString = ""
    $ComponentNames = getComponents($Issues)
    foreach ($ComponentName in $ComponentNames) {
        $retString += "<h4>" + $ComponentName + "</h4>" 
        $tempIssues = @()
        foreach ($Issue in $Issues) {
            $componentsFromIssue = $Issue.fields.components
            foreach ($componentFromIssue in $componentsFromIssue) {
                $componentFromIssueName = $componentFromIssue.name
                if ($componentFromIssueName -eq $ComponentName) {
                    $tempIssues += $Issue
                }
            }
        }
        $retString += "<ul>"
        $retString += getHTMLListOfIssues($tempIssues)
        $retString += "</ul>"
    }
 
    return $retString
}

function getHTMLListOfIssues($Issues) {
    $retString = "<ul>"
    foreach ($Issue in $Issues) {
        $summary = [System.Web.HttpUtility]::HtmlEncode($Issue.fields.summary)
        $key = $Issue.key
        $Issueurl = $Issue.keyUrl
        $project = $Issue.fields.components[0].name
        $status = $Issue.fields.status.name
        $style = "style=''"
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
        $retString += '<li><span>' + $summary + ' <ul><li><a href="' + $Issueurl + '">' + $key + ', <strong style="background: ' + $color + ';color:#fff;border-radius:5px;padding:2px;font-size:10px;">' + $status + '</strong></a></li></ul></span></li>'
    }
    $retString += "</ul>"
    return $retString
}

function getManuelEntries($PromptMessage) {
    Write-Host $PromptMessage
    $manuelEntries = ""
    do {
        $response = Read-Host
        if ($response -ne "q") {
            $manuelEntries += $response + "</br>"
        }
    } while ($response -ne "q")
    return $manuelEntries
}

######################## OPTIONS  ########################
#Wenn $testing = true, dann wird eine Testseite von mir genommen
$user = @{
    firstname = "Markus";
    lastname  = "Ederl";
    key       = "wlnedmr"
}
# $user = @{
#     firstname = "Lukas";
#     lastname  = "Ganster";
#     key       = "wlngalu"
# }
$testing = $true



###JQL um Issues zu finden, die in der kommenden Woche bearbeitet werden sollen
$Today = (Get-Date).Date 
$NextTuesday = $Today.AddDays(8)
$NextTuesday = Get-Date $NextTuesday -Format yyyy-MM-dd

$jqlToDo = 'filter = "' + $user.firstname + $user.lastname + '_AktuelleSprintsTickets" OR filter = "' + $user.firstname + $user.lastname + '_LiveBugs" OR status not in (Closed, Done, "Ready for Rollout") AND issuetype in (Defect, "ITSM ServiceTicket", "ServiceTicket (ServiceNow)", "ServiceTicket (ServiceNow-TEST)") AND assignee in (currentUser()) AND fixVersion in startDate("before ' + $NextTuesday + '") AND fixVersion in unreleasedVersions()'

###JQL um Issues zu finden, die in der letzten Woche bearbeitet wurden 
$dateRange = getLookUpDateRange
$start = $dateRange.start
$end = $dateRange.end
$userkey = $user.key
$jqlDone = "status changed before $end AND status changed after $start by $userkey and status in (Closed,Done,'Ready for Rollout') OR
assignee changed before $end AND assignee changed  after $start by $userkey and status in (Closed,Done,'Ready for Rollout') 
ORDER BY updated DESC"

###JQL um Issues zu finden, die nicht fertiggestellt werden konnten
$jqlNotDone = "assignee = $userkey and status in (Blocked)"


######################## CONFLUENCE ########################

#was-nehme-ich-mir-vor
$Issues = $Jira.getIssuesByJQL($jqlToDo)
$Issues = $Issues.issues
foreach ($Issue in $Issues) {
    $keyUrl = $Jira.BaseUrl + "/browse/" + $Issue.key
    $Issue | Add-Member -NotePropertyName "keyUrl" -NotePropertyValue $keyUrl
}
$currentTodosString = "<h3>JIRA-Issues</h3>"
$currentTodosString += convertIssuesToHTMLString($Issues)

$manuelEntries = getManuelEntries("Was nehme ich mir vor?")
if ($manuelEntries.length -gt 0) {
    $currentTodosString += "<h3>Sonstiges</h3><ul>"
    foreach ($line in $manuelEntries) {
        $text = "<li>" + $line + "</li>"
        $currentTodosString += $text

    }
    $currentTodosString += "</ul>"
}

#Was-habe-ich-erreicht-jql
$Issues = $Jira.getIssuesByJQL($jqlDone)
$Issues = $Issues.issues
foreach ($Issue in $Issues) {
    $keyUrl = $Jira.BaseUrl + "/browse/" + $Issue.key
    $Issue | Add-Member -NotePropertyName "keyUrl" -NotePropertyValue $keyUrl
}

$whatHaveIDoneString = "<h3>JIRA-Issues</h3>"
$whatHaveIDoneString += convertIssuesToHTMLString($Issues)

$manuelEntries = getManuelEntries("Was habe ich erreicht?")

if ($manuelEntries.length -gt 0) {
    $whatHaveIDoneString += "<h3>Sonstiges</h3><ul>"
    foreach ($line in $manuelEntries) {
        $text = "<li>" + $line + "</li>"
        $whatHaveIDoneString += $text

    }
    $whatHaveIDoneString += "</ul>"
}

#Was-habe-ich-nicht-erreicht-jql
$Issues = $Jira.getIssuesByJQL($jqlNotDone)
$Issues = $Issues.issues
foreach ($Issue in $Issues) {
    $keyUrl = $Jira.BaseUrl + "/browse/" + $Issue.key
    $Issue | Add-Member -NotePropertyName "keyUrl" -NotePropertyValue $keyUrl
}

$whatIsNotDoneString = "<h3>JIRA-Issues</h3>"
$whatIsNotDoneString += convertIssuesToHTMLString($Issues)

$manuelEntries = getManuelEntries("Warum konnte ich ein Thema nicht fertig stellen?")

if ($manuelEntries.length -gt 0) {
    $whatIsNotDoneString += "<h3>Sonstiges</h3><ul>"
    foreach ($line in $manuelEntries) {
        $text = "<li>" + $line + "</li>"
        $whatIsNotDoneString += $text

    }
    $whatIsNotDoneString += "</ul>"
}

$Today = (Get-Date).Date 

$nextMonday = $ConfluenceHelper.HelperFunctions.getDateOfNextDayOfWeek($Today, "Monday")
$nextMonday = Get-Date $nextMonday -Format yyyy-MM-dd
$thisFriday = $ConfluenceHelper.HelperFunctions.getDateOfNextDayOfWeek($Today, "Friday")
$thisFriday = Get-Date $thisFriday -Format yyyy-MM-dd

#$htmlString = $html.body.innerHTML
$htmlString = "<style>
table {
  font-family: Arial, Helvetica, sans-serif;
  border-collapse: collapse;
  width: 100%;
}

table td, table th {
  border: 1px solid #ddd;
  padding: 8px;
}

table tr:nth-child(even){background-color: #f2f2f2;}

table tr:hover {background-color: #ddd;}

table th {
  padding-top: 12px;
  padding-bottom: 12px;
  text-align: left;
  background-color: #04AA6D;
  color: white;
}
</style><table><tr><th>Was nehme ich mir vor? ($nextMonday)</th><th>Was habe ich erreicht? ($thisFriday)</th><th>Was habe ich nicht erreicht? ($thisFriday)</th></tr><tr>"
#Was nehme ihc mir vor replace
$htmlString += "<td>$currentTodosString</td>"
#Was habe ich erledigt replace
$htmlString += "<td>$whatHaveIDoneString</td>"
#Was ist nicht fertiggestellt? replace
$htmlString += "<td>$whatIsNotDoneString</td>"

$htmlString += "</tr></table>"

Set-Content -Path ./output.html -Value $htmlString



