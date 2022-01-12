using module '.\Atlassian.psm1'

class Jira : Atlassian {
  [string]$Auth
  [string]$BaseUrl
  Jira([string]$Auth, [string]$BaseUrl) : base ([string]$Auth, [string]$BaseUrl) {
        
  }

  [string]getElementIdByElementName($element, $elementName) {
    $elements = $this.get("/rest/api/2/" + $element + "/")
    for ($i = 0; $i -lt $elements.Count; $i++) {
      $element = $elements[$i]
      if ($element.name -eq $elementName) {
        return $element.id
      }
    }
    return ""
  }
  [string]getComponentIdByComponentName($ComponentName, $ProjectId) {
    $projectObj = $this.get("/rest/api/2/project/" + $ProjectId + "/")
    $components = $projectObj.components
    for ($i = 0; $i -lt $components.Count; $i++) {
      $component = $components[$i]
      if ($component.name -eq $ComponentName) {
        return $component.id
      }
    }
    return ""
  }
  
  [string]getIssueTypeIdByIssueTypeName($IssueTypeName) {
    return $this.getElementIdByElementName("issuetype", $IssueTypeName)
  }
  [string]getProjectIdByProjectName($ProjectName) {
    return $this.getElementIdByElementName("project", $ProjectName)
  }

  #$userName is wln-key (e.g. wlnedmr)
  [psobject]getUserByUserName($userName) {
    return $this.get("/rest/api/2/user/search?username=" + $userName)
  }

  [Void]createNewIssue($projectId, $issuetypeId, $componentIds, $summary, $reporterId, $assigneeId) {
    $this.createNewIssue($projectId, $issuetypeId, $componentIds, $summary, $reporterId, $assigneeId, "")
  }
  [Void]createNewIssue($projectId, $issuetypeId, $componentIds, $summary, $reporterId, $assigneeId, $priority) {
    $this.createNewIssue($projectId, $issuetypeId, $componentIds, $summary, $reporterId, $assigneeId, $priority,$null)
  }

  [Void]createNewIssue($projectId, $issuetypeId, $componentIds, $summary, $reporterId, $assigneeId, $priority, $additonalFields) {
    $body = '{
            "fields": {
              "summary": "'+ $summary + '",
              "issuetype": {
                "id": "'+ $issuetypeId + '"
              },
              "project": {
                "id": "'+ $projectId + '"
              },
              "priority": {
                "id": "'+ $priority + '"
              }
            }
          }'
      
    $body = $body | ConvertFrom-Json
    $componentObject = @()
    foreach ($componentId in $componentIds) {
      $componentObject += @{
        id = $componentId
      }
    }
    if ($null -ne $additonalFields){
      foreach ($field in $additonalFields.GetEnumerator()) {
        $body.fields | Add-Member -NotePropertyName $field.Key -NotePropertyValue $field.Value
      }
    }
    $body.fields | Add-Member -NotePropertyName components -NotePropertyValue $componentObject
    
   
    $body = $body | ConvertTo-Json -Depth 10
    Write-Host $body
    $this.post("/rest/api/2/issue/", $body)
  }
 

  [Void]createNewFixVersion($description, $name, $releaseDate, $startDate, $projectId) {
    $url = "/rest/api/2/version"

    $releaseDate = Get-Date $releaseDate -Format "yyyy-MM-dd"
    $startDate = Get-Date $startDate -Format "dd.MM.yyyy"

    $Body = @{
      description   = $description
      name          = $name
      archived      = "false"
      released      = "false"
      releaseDate   = $releaseDate
      projectId     = $projectId
      userStartDate = $startDate
    }
    $body = $Body | ConvertTo-Json
    Write-Host $body
    Write-Host $url
    $this.post($url, $body)
  }
  [Void]updateFixVersion($id, $description, $name, $releaseDate, $startDate, $projectId) {
    $url = "/rest/api/2/version/$id"

    $releaseDate = Get-Date $releaseDate -Format "yyyy-MM-dd"
    $startDate = Get-Date $startDate -Format "dd.MM.yyyy"

    $Body = @{
      description   = $description
      name          = $name
      archived      = "false"
      released      = "false"
      releaseDate   = $releaseDate
      projectId     = $projectId
      userStartDate = $startDate
    }
    $body = $Body | ConvertTo-Json
    Write-Host $body
    Write-Host $url
    $this.put($url, $body)
  }
  [Void]deleteIssueByKey($issueKey) {
    $this.delete("/rest/api/2/issue/$issueKey")
  }
  [Void] addBlockedBy($blockedByIssue, $blocksIssue) {
    $body = @{
      outwardIssue = @{
        key = $blocksIssue
      }
      inwardIssue  = @{
        key = $blockedByIssue
      }
      type         = @{
        id = 10000
      }
    }
    $body = $body | ConvertTo-Json
    $url = "/rest/api/2/issueLink"
    $this.post($url, $body)
  }
  [Void] addIssueLink($outwardIssue, $inwardIssue) {
    $body = @{
      outwardIssue = @{
        key = $outwardIssue
      }
      inwardIssue  = @{
        key = $inwardIssue
      }
      type         = @{
        id = 10003
      }
    }
    $body = $body | ConvertTo-Json
    $url = "/rest/api/2/issueLink"
    $this.post($url, $body)
  }
  [Void]addEpicLink($issueKey, $epicLink) {
    $body = @{
      fields = @{
        customfield_10074 = $epicLink
      }
    }
    $body = $body | ConvertTo-Json -Depth 10
    $url = "/rest/api/2/issue/$issueKey"
    $this.put($url, $body)

  } 
  [Void]addEstimationToIssue($issueKey, $hours) {
    $body = @{
      fields = @{
        customfield_10879 = $hours
      }
    }
    $body = $body | ConvertTo-Json -Depth 10
    $url = "/rest/api/2/issue/$issueKey"
    $this.put($url, $body)

  } 
  [Void]updateDescription($issueKey, $description) {
    $body = @{
      fields = @{
        description = $description
      }
    }
    $body = $body | ConvertTo-Json -Depth 10
    $url = "/rest/api/2/issue/$issueKey"
    $this.put($url, $body)
  }
  [Void]updateSecurityLevel($issueKey, $securityLevelId) {
    $body = @{
      fields = @{
        security = @{
          id = $securityLevelId
        }
      }
    }
    $body = $body | ConvertTo-Json -Depth 10
    $url = "/rest/api/2/issue/$issueKey"
    $this.put($url, $body)
  }
  [Void]closeIssue($issueKey, $comment) {
    $body = @{
      transition = @{id = 91 }
    }
    $body = $body | ConvertTo-Json -Depth 10
    $url = "/rest/api/2/issue/$issueKey/transitions"
    $this.post($url, $body)
  }
  [Void]updateAssignee($issueKey, $assigneeId) {
    $body = @{
      fields = @{
        assignee = @{name = $assigneeId }
      }
    }
    $body = $body | ConvertTo-Json -Depth 10
    $url = "/rest/api/2/issue/$issueKey"
    $this.put($url, $body)
  }
  [Void]updateSummary($issueKey, $summary) {
    $body = @{
      fields = @{
        summary = $summary
      }
    }
    $body = $body | ConvertTo-Json -Depth 10
    $url = "/rest/api/2/issue/$issueKey"
    $this.put($url, $body)
  }
  [Void]updateFixVersionInIssue($issueKey, $fixVersionName) {
    $body = @{
      fields = @{
        fixVersions = @(@{name = $fixVersionName })
      }
    }
    $body = $body | ConvertTo-Json -Depth 10
    $url = "/rest/api/2/issue/$issueKey"
    $this.put($url, $body)
  }

  [psobject]getIssuesByJQL($jql) {
    return $this.get('/rest/api/2/search?jql=' + $jql + '&expand=renderedFields')
  }
  [psobject]getIssuesByJQL($jql, $expand, $maxResults) {
    return $this.get("/rest/api/2/search?jql=$jql&expand=$expand&maxResults=$maxResults")
  }
  [psobject]getIssuesByJQL($jql, $maxResults) {
    return $this.get("/rest/api/2/search?jql=$jql&expand=renderedFields&maxResults=$maxResults")
  }
  [psobject]getWorkflows() {
    return $this.get('/rest/api/2/workflow')
  }
  [psobject]getWorkflowByWorkflowName($workflowName) {
    return $this.get("/secure/admin/workflows/ViewWorkflowXml.jspa?workflowMode=live&workflowName=$workflowName", "XML")
  }
  [psobject]getReleaseVersionsByProjectId($projectId) {
    return $this.get("/rest/api/2/project/$projectId/version?maxResults=1000")
  }
  [psobject]getReleasedVersionsByProjectId($projectId) {
    $versions = $this.getReleaseVersionsByProjectId($projectId);
    $versions = $versions.values
    return $versions | Where-Object { $_.released -eq $true }    
  }
  [psobject]getReleasedVersionsByProjectId($projectId, $maxDaysInPast) {
    $today = Get-Date
    $days = $maxDaysInPast * -1
    $dateLimit = $today.AddDays($days)
    $versions = $this.getReleasedVersionsByProjectId($projectId);
    return $versions | Where-Object { $null -ne $_.userReleaseDate } | Where-Object { 
      $date = Get-Date $_.userReleaseDate
      $date -gt $dateLimit 
    }    
  }
}
