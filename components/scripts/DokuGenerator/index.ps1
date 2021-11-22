#import needed modules
using module '..\..\helper\HelperFunctions.psm1'
using module '..\..\helper\JiraHelper.psm1'
using module '..\..\helper\ConfluenceHelper.psm1'
using module '..\..\atlassian\Jira.psm1'
using module '..\..\atlassian\Confluence.psm1'

#import needed files
. ..\..\..\constants.ps1


#FUNCTIONS
function getComponentNames($Issues) {
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
function getIssuesbyComponentName($Issues, $ComponentName) {
    $retArray = @()
    foreach ($Issue in $Issues) {
        $Components = $Issue.fields.components
        foreach ($Component in $Components) {
            if ($Component.name -eq $ComponentName) {
                $retArray += $Issue
            }
        }
    }
    return $retArray
}

function getIssuesbyFormName($Issues, $FormName) {
    $retArray = @()
    foreach ($Issue in $Issues) {
        $FormNames = $Issue.formNames
        foreach ($TempFormName in $FormNames) {
            if ($TempFormName -eq $FormName) {
                $retArray += $Issue
            }
        }
    }
    return $retArray
}

function getFormNames($Issues) {
    $retArray = @()
    foreach ($Issue in $Issues) {
        $FormNames = $Issue.formNames
        foreach ($FormName in $FormNames) {
            if ($retArray.Contains($FormName) -eq $false) {
                $retArray += $FormName
            }
        }
    }
    return $retArray
}


function getSectionNames($Issues) {
    $retArray = @()
    foreach ($Issue in $Issues) {
        $SectionNames = $Issue.sectionNames
        foreach ($SectionName in $SectionNames) {
            if ($retArray.Contains($SectionName) -eq $false) {
                $retArray += $SectionName
            }
        }
    }
    return $retArray
}

function getFixVersionsAsString($Issue) {
    $retString = ""
    foreach ($FixVersion in $Issue.fields.fixVersions) {
        $retString += '<p><a href="' + $Jira.BaseUrl + "/issues?jql=fixVersion=" + $FixVersion.name + '">' + $FixVersion.name + '</a></p>'
    }
    return $retString
}


function handleConfluencePage($PageTitle, $AncestorPageId) {
    $Confluence = [Confluence]::new($authJIRAIntern, "https://collab.raiffeisenbank.at")
    $Confluence.ancestorPageId = $AncestorPageId
    $PageTitle = $Confluence.convertUmlaut($PageTitle)
    $Confluence.deletePageByTitle($PageTitle, $true);
    $pageBody = $Confluence.getBodyForPageCreation($PageTitle)
    $Confluence.post("/rest/api/content/", $pageBody)
    return $Confluence.getPageByTitle($PageTitle)
}

#SCRIPT EXECUTION
$HelperFunctions = [HelperFunctions]::new()
$Jira = [Jira]::new($authJIRAIntern, "https://webforms-jira-intern.raiffeisenbank.at")
$JiraHelper = [JiraHelper]::new($Jira, $HelperFunctions)
$Confluence = [Confluence]::new($authJIRAIntern, "https://collab.raiffeisenbank.at")
$ConfluenceHelper = [ConfluenceHelper]::new($Confluence, $HelperFunctions)

#Pageid 39093198 = https://collab.raiffeisenbank.at/display/RLBDIG/Markus+Test
$DokuPageId = 60885402

#$jql = 'key in ("RLB-22409")'
#$jql = 'component in ("BC-RKS - Debitkarten")&maxResults=1000'
$jql = 'issue in linkedIssues("RLB-16038")&maxResults=1000'

$issueDump = $JiraHelper.Jira.getIssuesByJQL($jql);
$Issues = $JiraHelper.convertIssuesToObject($issueDump.issues);

$json = ConvertTo-Json $Issues -Depth 10
Set-Clipboard -Value $json


$ComponentNames = getComponentNames($Issues)

foreach ($ComponentName in $ComponentNames) {
    $tempIssues = getIssuesbyComponentName $Issues $ComponentName
    $FormNames = getFormNames($tempIssues)
    $ComponentConfluencePage = handleConfluencePage $ComponentName $DokuPageId
    foreach ($FormName in $FormNames) {
        $AncestorPageId = $ComponentConfluencePage.id
        $tempIssues = getIssuesbyFormName $Issues $FormName
        if ($FormName -eq "Gesamt") {
            $FormName = $ComponentName + " - Gesamt"
        }
        $FormNameConfluencePage = handleConfluencePage $FormName $AncestorPageId
        $SectionNames = getSectionNames($tempIssues)
        $HtmlString = ""
        foreach ($SectionName in $SectionNames) {
            $HtmlString += "<div><h3>$SectionName</h3><table><tr><th>Zusammenfassung</th><th>Beschreibung</th><th>Mock-Ups</th><th>JIRA-Ticket</th><th>Lösungsversion</th></tr>"
            foreach ($tempIssue in $tempIssues) {
                $HtmlString += "<tr>"
                $Zusammenfassung = $JiraHelper.removeSpecialCharsFromText($tempIssue.fields.summary)
                $Beschreibung = $ConfluenceHelper.Confluence.convertUmlaut($tempIssue.fachlicheBeschreibung)
                $MockUps = $tempIssue.mockUps
                $JiraIssue = $tempIssue.key
                $FixVersionsString = getFixVersionsAsString($tempIssue)
                $HtmlString += '<td>' + $Zusammenfassung + '</td>'
                $HtmlString += '<td>' + $Beschreibung + '</td>'
                $HtmlString += "<td>"
                foreach ($MockUp in $MockUps) {
                    $LinkImage = $MockUp.Content
                    $LinkThumbNail = $MockUp.Thumbnail
                    $HtmlString += '<a href="' + $LinkImage + '"><img src="' + $LinkThumbNail + '"/></a>'
                }
                $HtmlString += "</td>"
                $HtmlString += '<td><a href="' + $Jira.BaseUrl + '/browse/' + $JiraIssue + '">' + $JiraIssue + '</a></td>'
                $HtmlString += "<td> $FixVersionsString </td>"
                $HtmlString += "</tr>"
            }
            $HTMLString += "</table></div>"
            
        }
        #$HTMLString = "<h1>Test</h1>"
        $pageBody = $Confluence.getBodyForPageUpdate($FormNameConfluencePage, $HtmlString)
        $pageUrl = "/rest/api/content/" + $FormNameConfluencePage.id
        $Confluence.put($pageUrl, $pageBody)
        Set-Clipboard -Value $HtmlString
    }
}



