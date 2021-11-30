class RecepientFinder {
    [psobject]$Jira
    [psobject]$JiraHelper
    RecepientFinder([psobject]$Jira, [psobject]$JiraHelper) {
        $this.Jira = $Jira
        $this.JiraHelper = $JiraHelper
    }

    [psobject]getNoDefectsRecepients() {
        $projectId = "10100"
        $daysInPast = 30
        $versions = $this.Jira.getReleasedVersionsByProjectId($projectId, $daysInPast);
        Set-Clipboard -Value $versions
        
        $componentsToCheck = $this.getComponentsByReleaseVersion($versions)
        
        
        #$componentsString = $componentsString.Substring(0, $componentsString.Length - 1)
        $jql = "component in () and type = Defect"
        $defects = $this.Jira.getIssuesByJQL($jql);
        $defects = $defects.issues
        foreach ($defect in $defects) {
            $components = $defect.fields.components
            foreach ($component in $components) {
                foreach ($componentToCheck in $componentsToCheck) {
                    if ($componentToCheck.id -eq $component.id) {
                        $componentToCheck.defects += $defect
                    }
                }
            }
        }
        
        $json = $componentsToCheck | ConvertTo-Json -Depth 10
        Set-Clipboard -Value $json

        
        return $componentsToCheck
    }
    [psobject]getReleaseVersionsRecepients($daysInPast) {
        $retObj = @()
        $projectId = "10100"
        $versions = $this.Jira.getReleasedVersionsByProjectId($projectId, $daysInPast);
        foreach ($version in $versions) {
            $retObj += $this.getReleaseVersionRecepients($version)
        }
        return $retObj
    }
    [psobject]getReleaseVersionRecepients($version) {
        $json = $version | ConvertTo-Json
        $versionName = $version.name
        $jql = $this.getJQLByVersions($version);
        $issues = $this.Jira.getIssuesByJQL($jql, "changelog", "1000");
    
        $recipients = $this.getRecipientsFromIssues($issues.issues);
        $goldRecipient = @{changes = 0 }
        $silverRecipient = @{changes = 0 }
        foreach ($recipient in $recipients) {
            if ($recipient.changes -gt $goldRecipient.changes) {
                $goldRecipient = $recipient
            }
            if ($recipient.changes -gt $silverRecipient.changes -AND $recipient.changes -lt $goldRecipient.changes) {
                $silverRecipient = $recipient
            }
        }
        $recipients = $recipients | Where-Object { $_.email -ne $goldRecipient.email -And $_.email -ne $silverRecipient.email }
        $recipientsMail = @()
        foreach ($recipient in $recipients) {
            $recipientsMail += $recipient.email
        }
        $retArray = @(
            @{
                recipients = $recipientsMail
                topic      = "Mithilfe am Release der Version '$versionName'"
                level      = 3
            }
        )

        if ($null -ne $goldRecipient.email) {
            $retArray += @{
                recipients = @($goldRecipient.email)
                topic      = "Mithilfe am Release der Version '$versionName'"
                level      = 1
            }
        }
        if ($null -ne $silverRecipient.email) {
            $retArray += @{
                recipients = @($silverRecipient.email)
                topic      = "Mithilfe am Release der Version '$versionName'"
                level      = 2
            }
        }
        return $retArray
    }
    [psobject]getRecipientsFromIssues($issues) {
        $retArray = @()
        $invalidAuthors = @("norightmail@raiffeisenbank.at")
        foreach ($issue in $issues) {
            $changelog = $issue.changelog.histories
            foreach ($entry in $changelog) {
                $author = $entry.author
                $index = $this.JiraHelper.HelperFunctions.getIndexOfObjectByParameter($retArray, "email", $author.emailAddress)
                $isInvalidAuthor = $this.JiraHelper.HelperFunctions.checkIfArrayContains($invalidAuthors, $author.emailAddress)
                $isRaiffeisenAdresse = $null -ne $author.emailAddress -AND $author.emailAddress.Contains("raiffeisenbank.at")
                if ($isInvalidAuthor -eq $false -AND $isRaiffeisenAdresse -eq $true) {
                    if ($index -gt -1) {
                        $retArray[$index] = @{
                            email   = $author.emailAddress
                            changes = $retArray[$index].changes + 1
                        }
                    }
                    if ($index -eq -1) {
                        $retArray += @{
                            email   = $author.emailAddress
                            changes = 1
                        }
                    }
                   
                }
            }
        }
        return $retArray
    }
    [psobject]getJQLByVersions($versions) {
        $retString = "fixVersion in ("
        foreach ($version in $versions) {
            $id = $version.id
            $retString += "$id,"
        }
        $retString = $retString.Substring(0, $retString.Length - 1)
        return "$retString)&expand=changelog"
    } 
    [psobject]getComponentsByReleaseVersion($versions) {
        $componentsToCheck = @()
        foreach ($version in $versions) {
            $id = $version.id
            $jql = "fixVersion=$id"
            $issues = $this.Jira.getIssuesByJQL($jql);
            $issues = $issues.issues
            foreach ($issue in $issues) {
                $components = $issue.fields.components
                foreach ($component in $components) {
                    $name = $component.name
                    $id = $component.id
                    $index = $this.JiraHelper.HelperFunctions.getIndexInArrayOfObjects($componentsToCheck, "id", $id)
                    if ($index -eq -1) {
                        $componentsToCheck += @{
                            name    = $name
                            id      = $id
                            version = $version
                        }
                        $componentsString += "$id,"
                    }
                }
            }
        }
        return $componentsToCheck;
    }
}
