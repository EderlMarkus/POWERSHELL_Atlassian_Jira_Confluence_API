#import needed modules
using module './components/helper/HelperFunctions.psm1'
using module './components/helper/JiraHelper.psm1'
using module './components/helper/ConfluenceHelper.psm1'
using module './components/atlassian/Jira.psm1'
using module './components/atlassian/Confluence.psm1'

#import needed files
. ./constants.ps1
$HelperFunctions = [HelperFunctions]::new()
$Jira = [Jira]::new($authJIRAIntern, "https://webforms-jira-intern.raiffeisenbank.at")
$JiraHelper = [JiraHelper]::new($Jira, $HelperFunctions)
$Confluence = [Confluence]::new($authJIRAIntern, "https://collab.raiffeisenbank.at")
$ConfluenceHelper = [ConfluenceHelper]::new($Confluence, $HelperFunctions)


######################## CONFLUENCE ########################
$title = "OKP-Weekly und Review Oktober"
$page = $ConfluenceHelper.Confluence.getPageByTitle($title)
$bodyHTML = $page.body.view
#was-nehme-ich-mir-vor-jql
$jql = 'filter = "MarkusEderl_AktuelleSprintsTickets"'
$tickets = $Jira.getTicketsByJQL($jql)
$tickets = $tickets.issues
$currentTodosString = "<ul>"
foreach ($ticket in $tickets) {
    $currentTodosString += "<li>" + $ticket.fields.summary + " (" + $ticket.key + ")</li>"
}
$currentTodosString += "</ul>"
#Was-habe-ich-erreicht-jql
$Today = (Get-Date).Date 
$Monday = $Today.AddDays(1 - $Today.DayOfWeek.value__)
$Friday = $Monday.AddDays(4)
$Monday = Get-Date $Monday -Format yyyy-MM-dd
$Friday = Get-Date $Friday -Format yyyy-MM-dd

$jql = 'status changed before ' + $Friday + ' AND status changed after ' + $Monday + ' by currentUser() and status in (Closed,Done,"Ready for Rollout","In Review") ORDER BY updated DESC'

$tickets = $Jira.getTicketsByJQL($jql)
$tickets = $tickets.issues
$whatHaveIDoneString = "<ul>"
foreach ($ticket in $tickets) {
    $whatHaveIDoneString += "<li>" + $ticket.fields.summary + " (" + $ticket.key + ")</li>"
}


$whatHaveIDoneString += "</ul>"

$nextMonday = $ConfluenceHelper.HelperFunctions.getDateOfNextDayOfWeek($Today, "Monday")
$nextMonday = Get-Date $nextMonday -Format yyyy-MM-dd
$userName = "Markus Ederl"
$html = New-Object -ComObject "HTMLFile"
$html.IHTMLDocument2_write($bodyHTML.value)
$timeTags = $html.getElementsByTagName("time")
$matchedWeek;
for ($i = 0; $i -lt $timeTags.length; $i++) {
    $timeTag = $timeTags[$i];
    if ($timeTag.outerHTML -Match $nextMonday) {
        if ($i -eq 1) {
            $matchedWeek = 0
        }
        else {
            $matchedWeek = [math]::ceiling($i / 2)
        }
    }
}
$table = $html.getElementsByTagName("table")[$matchedWeek]
$tr = $table
$linkedUserElement = $table.getElementsByTagName("a") | Where { $_.innerText -eq $userName }
$linkedUserElement.parentNode.parentNode.parentNode.parentNode.children[1].innerText = $currentTodosString
$linkedUserElement.parentNode.parentNode.parentNode.parentNode.children[2].innerText = $whatHaveIDoneString

#$htmlString = $html.body.innerHTML
$htmlString = $page.body.view.value;

##Was nehme ihc mir vor replace
$regex = '(2021-10-04)(.*?)(Ederl)(.*?)(confluenceTd">)'
$string = $htmlString -split $regex 
[regex]$pattern = "(.*?)(</td>)"
$string[$string.length - 1] = $pattern.replace($string[$string.length - 1], $currentTodosString + "</td>", 1) 
$htmlString = ""
foreach ($element in $string) {
    $htmlString += $element
}

##Was habe ich erledigt replace
$regex = '(2021-10-04)(.*?)(Ederl)(.*?)(confluenceTd">)(.*?)(confluenceTd">)'
$string = $htmlString -split $regex 
[regex]$pattern = "(.*?)(</td>)"
$string[$string.length - 1] = $pattern.replace($string[$string.length - 1], $whatHaveIDoneString + "</td>", 1) 
$htmlString = ""
foreach ($element in $string) {
    $htmlString += $element
}



$htmlString = $ConfluenceHelper.HelperFunctions.convertUmlaut($htmlString)
$htmlString = $htmlString -replace "\n", "" -replace "\r", "" -replace "'", "\'" -replace '"', '\"'
$pageIdConfluecne = "64061669"
$page = $Confluence.getPageById($pageIdConfluecne)
#$htmlString = "<BODY><P><U><STRONG>Teilnehmer:</STRONG></U></P><P><A class='confluence-userlink user-mention' href='/display/~wlndoja' data-base-url='https://collab.raiffeisenbank.at' data-linked-resource-type='userinfo' data-linked-resource-version='1' data-linked-resource-id='19922949' data-username='wlndoja'>Jakob Doeller</A></P></BODY>"
$pageBody = $Confluence.getBodyForPageUpdate($page, $htmlString)
$pageUrl = "/rest/api/content/" + $pageIdConfluecne


$Confluence.put($pageUrl, $pageBody)

Set-Clipboard -Value $htmlString


######################## JIRA ########################
# $Jira = [Jira]::new($authJIRAIntern, "https://webforms-jira-intern.raiffeisenbank.at")
# $JiraHelper = [JiraHelper]::new($Jira, $HelperFunctions)

## Create a new FixVersion in JIRA
# $description = "Markus Test"
# $name = "Markus Test (DeleteMe)"
# $releaseDate = Get-Date "28.09.2021" -Format "yyyy-MM-dd"
# $startDate = Get-Date "25.09.2021" -Format "dd.MM.yyyy"
# $projectId = "10100"
# $Jira.createNewFixVersion($description, $name, $releaseDate, $startDate, $projectId)
# #hallo welt
# ## Get Tickets by JQL
# $jql = 'key="RLB-22841"'
# $tickets = $Jira.getTicketsByJQL($jql);
# $ticketsObj = $JiraHelper.convertTicketsToObject($tickets.issues);
# $ticketsJSON = $ticketsObj | ConvertTo-JSON -Depth 10
# Set-Clipboard -Value $ticketsJSON

## TODO: Comment on Tickets by JQL
# $jql = 'key="RLB-22841"'
# $tickets = $Jira.getTicketsByJQL($jql);
# $comment = $HelperFunctions.getUpdateMessageForJiraTicket($ticket);
# foreach ($ticket in $tickets) {
    
#     $Jira.commentOnTicket($comment, $ticket.key);
# }

## Create Ticket
# $projectId = $Jira.getProjectIdByProjectName("RLB Projektmanagement")
# $issuetypeId = $Jira.getIssueTypeIdByIssueTypeName("Story")
# $componentIds = @($Jira.getComponentIdByComponentName("BC-RES - ELBA", $projectId))
# $summary = "Meine Summary"
# $description = "Meine Description"
# $reporterKey = "wlnedmr"
# $assigneeKey = "wlnedmr"
# ## Todo: Assignee und reporter gehen noch nicht zu änern
# $body = $Jira.createNewIssue($projectId, $issuetypeId, $componentIds, $summary, $description, $reporterKey, $assigneeKey )
#test1