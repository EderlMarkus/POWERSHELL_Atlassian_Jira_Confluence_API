## Setup

Bitte eine Datei "constants.ps1" generieren, welche Base64 von username:passwort von JIRA hat:

## Beispiel

base64 of username:password

\$authJIRAIntern = "dXNlcm5hbWU6cGFzc3dvcmQ="

## Beispiel Calls
### Klasse instanzieren
```
$authJIRAIntern = "dXNlcm5hbWU6cGFzc3dvcmQ="
$JiraBaseUrl = "https://<yourConfluenceServer>.com"
$Jira = [Jira]::new($authJIRAIntern, $JiraBaseUrl)
```
### CRUD-Requests
```
$body = @{
    fields = @{
    customfield_10074 = $epicLink
    }
}
$JIRA.get("/rest/api/2/issue/")
$JIRA.post("/rest/api/2/issue/", $body)
$JIRA.put("/rest/api/2/issue/", $body)
$JIRA.delete("/rest/api/2/issue/")

```
### Hol Jira-Issues anhand von JQL-Suche:
```
$jql = 'key="ID-1232"'
$issues = $Jira.getIssuesByJQL($jql).issues
```
### Neue Fixversion anlegen:
Vorsicht bei Umlauten, besser oe, ae, ue verwenden!
```
$description = "Meine Beschreibung für die Loesungsversion"
$name = "Meine neue Loesungsversion"
$releaseDate = "03.12.2021"
$startDate = "02.12.2021"
$projectName = "My Project"
$projectId = $Jira.getProjectIdByProjectName($projectName)
$Jira.createNewFixVersion($description, $name, $releaseDate, $startDate, $projectId)
```
### Neues Issue erstellen
```
$projectName = "My Project"
$projectId = $Jira.getProjectIdByProjectName($projectName)
$Jira.createNewIssue($projectId, $issuetypeId, $componentIds, $summary, $reporterId, $assigneeId) {
```

