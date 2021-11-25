class HelperFunctions {
  
    #functions
    [psobject]getDateOfNextDayOfWeek($startDate, $dayOfWeek) {
        $date = Get-Date $startDate
        while ($date.DayOfWeek -ne $dayOfWeek) { $date = $date.AddDays(1) }
        return $date
    }


    [boolean]checkIfHoliday($date) {
        $holidays = @(
            "21.12.2021",
            "28.12.2021"
            "26.10.2021"
        )
        $dateToCheck = Get-Date $date -Format "dd.MM.yyyy"
        for ($i = 0; $i -lt $holidays.Count; $i++) {
            if ($holidays[$i] -eq $dateToCheck) {
                return $true
            }
        }
        return $false
    }

    [int32]getIndexInArrayOfObjects($arrayOfObject, $parameter, $value) {
        for ($i = 0; $i -le $arrayOfObject.length; $i++) {
            $entry = $arrayOfObject[$i]
            if ($entry -ne $null -AND $entry[$parameter] -eq $value) {
                return $i
            }
        }
        return -1
    }

    [string]convertUmlaut($Text) {
            
        $output = $Text.Replace('ö', 'oe').Replace('ä', 'ae').Replace('ü', 'ue').Replace('ß', 'ss').Replace('Ö', 'Oe').Replace('Ü', 'Ue').Replace('Ä', 'Ae').Replace('&ouml;', "oe").Replace('&Ouml;', "Oe").Replace('&Auml;', "Ae").Replace('&auml;', "ae").Replace('&Uuml;', "Ue").Replace('&uuml;', "ue").Replace('&szlig;', "ß")
        $isCapitalLetter = $Text -ceq $Text.toUpper()
        if ($isCapitalLetter) { 
            $output = $output.toUpper() 
        }
        return $output
    }

    #$structure = @("Components", "FormNames", "Sections");

    [psobject]sortArrayByStructure($array) {
        $retObj = @{
            components = @()
        }
        foreach ($issue in $array) {
            foreach ($component in $issue.components) {
                $componentName = $component.name
                $index = $this.getIndexOfObjectByParameter($retObj.components, "name", $componentName)
                $global:componentObject = @{}
                if ($index -eq -1) {
                    $global:componentObject = @{
                        name  = $componentName
                        forms = @()
                    }
                }
                if ($index -gt -1) {
                    $global:componentObject = $retObj.components[$index]
                }
                foreach ($formName in $issue.formNames) {
                    if ($formName -eq "Gesamt") {
                        $formName = "$componentName - Gesamt"
                    }
                    $forms = $global:componentObject.forms
                    $index = $this.getIndexOfObjectByParameter($forms, "name", $formName)
                    
                    if ($index -eq -1) {
                        $global:componentObject.forms += @{
                            name   = $formName
                            issues = @($issue)
                        }
                    }
                    if ($index -gt -1) {
                        $global:componentObject.forms[$index].issues += $issue
                    }
                }
                $index = $this.getIndexOfObjectByParameter($retObj.components, "name", $componentName)
                if ($index -eq -1) {
                    $retObj.components += $global:componentObject
                }
                if ($index -gt -1) {
                    $retObj.components[$index] = $global:componentObject
                }
            } 
        }
        return $retObj
        
    }

    [boolean]checkIfArrayContains($array, $value) {
        for ($i = 0; $i -lt $array.Count; $i++) {
            if ($array[$i] -eq $value) {
                return $true
            }
        }
        return $false
    }

    [int]getIndexOfObjectByParameter($array, $parameter, $value) {
        for ($i = 0; $i -lt $array.Count; $i++) {
            $arrayValue = $array[$i]."$parameter"
            if ($arrayValue -eq $value) {
                return $i
            }
        }
        return -1
    }
    [psobject]removeSpecialCharsFromText($text) {
        $text = $text -replace '[^a-zA-Z0-9\s\!\-\.]', ""
        $text = $text -replace '\r\n|\r|\n', ""
        return $text
    }

    [string]getHTMLTableForIssues($issues, $baseUrl) {
       
        $HtmlString += "<div><table><tr><th>Titel</th><th>Beschreibung</th><th>Mock-Ups</th><th>JIRA-Ticket</th><th>Lösungsversion</th></tr>"
        foreach ($issue in $issues) {
            $HtmlString += "<tr>"
            $Zusammenfassung = $this.removeSpecialCharsFromText($issue.fields.summary)
            $Beschreibung = $this.convertUmlaut($issue.fachlicheBeschreibung)
            $MockUps = $issue.mockUps
            $JiraIssue = $issue.key
            $FixVersionsString = $this.getFixVersionsAsString($issue, $baseUrl)
            $HtmlString += '<td>' + $Zusammenfassung + '</td>'
            $HtmlString += '<td>' + $Beschreibung + '</td>'
            $HtmlString += "<td>"
            foreach ($MockUp in $MockUps) {
                $LinkImage = $MockUp.Content
                $LinkThumbNail = $MockUp.Thumbnail
                $HtmlString += '<a href="' + $LinkImage + '"><img src="' + $LinkThumbNail + '"/></a>'
            }
            $HtmlString += "</td>"
            $HtmlString += '<td><a href="' + $baseUrl + '/browse/' + $JiraIssue + '">' + $JiraIssue + '</a></td>'
            $HtmlString += "<td> $FixVersionsString </td>"
            $HtmlString += "</tr>"
        }
        $HTMLString += "</table></div>"
        return $HTMLString
    }



    [string]getFixVersionsAsString($Issue, $baseUrl) {
        $retString = ""
        foreach ($FixVersion in $Issue.fields.fixVersions) {
            $retString += '<p><a href="' + $baseUrl + "/issues?jql=fixVersion=" + $FixVersion.name + '">' + $FixVersion.name + '</a></p>'
        }
        return $retString
    }

    
}

