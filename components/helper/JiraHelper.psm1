class JiraHelper {
    [psobject]$Jira
    [psobject]$HelperFunctions

    JiraHelper(
        [psobject]$Jira,
        [psobject]$HelperFunctions
    ) {
        $this.Jira = $Jira
        $this.HelperFunctions = $HelperFunctions
    }

    [psobject]addFachlicheBeschreibungToIssue($Issue) {
        $beschreibung = $this.getFachlicheBeschreibung($Issue)
        $beschreibung = $this.HelperFunctions.removeSpecialCharsFromText($beschreibung)
        #$beschreibung = $this.convertImagesInText($beschreibung, $this.getAttachments($Issue))
        $Issue | Add-Member -NotePropertyName fachlicheBeschreibung -NotePropertyValue $beschreibung
        return $Issue
    }

    [psobject]addMockUpsToIssue($Issue) {
        $mockUps = $this.getMockUpNames($Issue)
        $attachments = $this.getAttachments($Issue)
        $mockUps = $this.getMockUpLinks($mockUps, $attachments)
        $Issue | Add-Member -NotePropertyName mockUps -NotePropertyValue $mockUps
        return $Issue
    }

    [array]getMockUpNames($Issue) {
        $description = $Issue.fields.description
        [regex]$regexMockUp = $this.getMockupRegex($false);
        $retArray = @()
        $matchMockUp = [regex]::matches($description, $regexMockUp)
        if ($matchMockUp.Success -eq $true) {
            $firstMatch = $matchMockUp[0]
            $firstMatch = $firstMatch.Value.replace("*", "\*")
            $MockUps = $description -split $firstMatch
            $textAfter = [regex]::matches($MockUps[1], "(!)(.*?)(\|)")
            if ($textAfter.Success -eq $true) {
                foreach ($item in $textAfter) {
                    $value = $item.Value
                    $value = $value.replace("|", "")
                    $value = $value.replace("!", "")
                    $retArray += $value.Trim()
                }
            }
            if ($textAfter.Success -ne $true) {
                $MockUps = $MockUps[1] -split "(h[0-5]|\-\-\-\-)"
                $MockUps = $MockUps[0].trim().replace("|", "")
                $MockUps = $MockUps -split "\r|\n"
        
                Foreach ($MockUp in $MockUps) {
                    $name = $MockUp.replace("thumbnail", "")
                    $name = $name.replace("!", "")
                    $name = $name.replace("\\n", "")
                    $name = $name.trim()
                    $isWhiteSpace = [string]::IsNullOrWhiteSpace($name)
                    $isEmpty = [string]::IsNullOrEmpty($name)
                    if ($isWhiteSpace -eq $false -And $isEmpty -eq $false) {
                        $retArray += $name
                    }
                }
            }
        }
        return $retArray
    }
    [array]getAttachments($ticket) {
        $issue = $this.Jira.get("/rest/api/2/issue/" + $ticket.Key)
        return $issue.fields.attachment
    }
    [array]getMockUpLinks($MockUpNames, $Attachments) {
        $retArray = @()
        foreach ($MockUpName in $MockUpNames) {
            foreach ($Attachment in $Attachments) {
                if ($Attachment.filename -eq $MockUpName) {
                    $retArray += [psobject]@{
                        Content   = $Attachment.content
                        Thumbnail = $Attachment.thumbnail
                    }
                }
            }        
        }
        return $retArray
    }

    [psobject]addComponentNamesToIssue($Issue) {
        $Components = $this.getComponents($Issue)
        $Issue | Add-Member -NotePropertyName components -NotePropertyValue $Components
        return $Issue
    }

    [psobject]addFormNamesToIssue($Issue) {
        $FormNames = $this.getFormNames($Issue)
        $FormNames = $this.sanatizeFormNames($FormNames)
        $FormNames = $FormNames -split "\r\n"
        $FormNames += "Gesamt"
        if ([string]::IsNullOrEmpty($FormNames[0])) {
            $FormNames = @("Gesamt") 
        }        
        $Issue | Add-Member -NotePropertyName formNames -NotePropertyValue $FormNames
        return $Issue
    }
    [string]sanatizeFormNames($FormNames) {
        return $FormNames.replace("|", "").replace("*Name*", "").replace("\r\n|\r|\n", "")
    }
    [psobject]addSectionsToIssue($Issue) {
        $Sections = $this.getSections($Issue)
        $Sections = $Sections -split "\n"
        $Sections += "Gesamt"
        if ([string]::IsNullOrEmpty($Sections[0])) {
            $Sections = @("Gesamt") 
        }        
        $Issue | Add-Member -NotePropertyName sectionNames -NotePropertyValue $Sections
        return $Issue
    }
    [psobject]convertIssuesToObject ($Issues) {
        $retObj = @()
        $components = @()
        foreach ($Issue in $Issues) {
            if ($this.checkIfIssueIsValid($Issue) -eq $true) {
                #Add Custom Fields
                $Issue = $this.addFachlicheBeschreibungToIssue($Issue)
                $Issue = $this.addMockUpsToIssue($Issue)
                $Issue = $this.addComponentNamesToIssue($Issue)
                $Issue = $this.addFormNamesToIssue($Issue)
                $Issue = $this.addSectionsToIssue($Issue)
                $retObj += $Issue
            }
        }

        return $this.HelperFunctions.sortArrayByStructure($retObj)
    }
    [string]getBeschreibung($Issue) {
        
        return ""
    }
  

    [string]convertImagesInText($description, $Attachments) {
        foreach ($Attachment in $Attachments) {
            $filename = $Attachment.filename
            [regex] $regexSonderzeichen = "[_+.;\s]+"
            $filename = $regexSonderzeichen.Replace($filename, "(.*?)")
            [regex] $regex = "(!)(" + $filename + ")(!|\|thumbnail!)"
            $replaceString = "<a href='" + $Attachment.Content + "'><img src='" + $Attachment.Thumbnail + "'/></a>"
            $replaceString = $replaceString -replace '\r\n|\r|\n'
            $description = $description -replace $regex, $replaceString
        }
        return $description;

    }
    [regex]getFormNameRegex($isRenderedField) {
        if ($isRenderedField -eq $false) {
            return $this.getMarkdownWrapper("Formular|Formulare")
        }
        return $this.getHTMLWrapper("Formular|Formulare")
    
    }
    [regex]getBeschreibungRegex($isRenderedField) {
        if ($isRenderedField -eq $false) {
            return $this.getMarkdownWrapper("Beschreibung|beschreibung")
        }
        return $this.getHTMLWrapper("Beschreibung|beschreibung")
    }
    [regex]getSectionRegex($isRenderedField) {
        $Variations = "([S_s]ektion(en|)|[S_s]ection(s|))"
        if ($isRenderedField -eq $false) {
            return $this.getMarkdownWrapper($Variations)
        }
        return $this.getHTMLWrapper($Variations)
    }
    [regex]getMockupRegex($isRenderedField) {
        $Variations = "([M_m]ock(\-|\w|\s|)[U_u]p(s|))"
        if ($isRenderedField -eq $false) {
            return $this.getMarkdownWrapper($Variations)
        }
        return $this.getHTMLWrapper($Variations)
    
    }
    [regex]getEndOfSectionRegex($isRenderedField) {
        if ($isRenderedField -eq $false) {
            return '(h[0-5]|\n\-\-\-\-|^\*(.*?)\*$)'
        }
        return '((\<hr\s\/\>)|(\<h[0-5]\>))|(\-{3,}|(\<\/p\>))'
    }
    [regex]getHTMLWrapper($regex) {
        return '(((\<h[1-5]\>)|(\<p\>\<b\>))(.*?)(' + $regex + ')(.*?)((\<\/h[1-5]\>)|(\<\/b\>))|(\<p\>)(\-{3,})(\s|\w|)(' + $regex + ')(\s|\w|)(\-{3,}\<br\/\>))'
    }
    [regex]getMarkdownWrapper($regex) {
        return '((h[0-5](\.|\s|\w|\.\s|\.\w))(.*?)|\*|\-{3,}|\-{3,}\s|\*[0-5]\.\s|\*[0-5]\.)(' + $regex + ')([^"\r\n]*)'
    }
    [string]getFachlicheBeschreibung($Issue) {
        $fachlicheBeschreibung = $Issue.fields.customfield_12101
        if ($null -ne $fachlicheBeschreibung) {
            return $fachlicheBeschreibung
        }
        $regex = $this.getBeschreibungRegex($false);
        $description = $Issue.fields.description
        return $this.getSectionByRegex($description, $regex)
    }
    [string]getMockups($Issue) {
        $regex = $this.getMockupRegex($false);
        $description = $Issue.fields.description
        return $this.getSectionByRegex($description, $regex)
    }
    [array]getComponents($Issue) {
        return $Issue.fields.components
    }
    [string]getFormNames($Issue) {
        $formCustomField = $Issue.fields.customfield_12400
        if ($null -ne $formCustomField) {
            return $formCustomField.child.value
        }
        $regex = $this.getFormNameRegex($false);
        $description = $Issue.fields.description
        return $this.getSectionByRegex($description, $regex)
    }
    [string]getSections($Issue) {
        $regex = $this.getSectionRegex($false);
        $description = $Issue.fields.description
        return $this.getSectionByRegex($description, $regex)
    }
    [string]getSectionByRegex($description, $regex) {
        $sectionText = ""
        [regex]$regexsectionText = $regex
        $matchsectionText = [regex]::matches($description, $regexsectionText)
        [regex]$endOfSectionRegex = $this.getEndOfSectionRegex($false)
        if ($matchsectionText.Success -eq $true) {
            $firstMatch = $matchsectionText[0].Value.replace("*", "/*")
            $sectionText = $description -split $firstMatch
            $sectionText = $sectionText[$sectionText.length - 1]
            $sectionText = $sectionText -split $endOfSectionRegex
            $sectionText = $sectionText[0].trim()
        }
        return  $sectionText
    }
    [bool]checkIfIssueIsValid ($Issue) {
        $fachlicheBeschreibungCustomField = $Issue.fields.customfield_12101
        if ($null -ne $fachlicheBeschreibungCustomField) {
            $isEmpty = [string]::IsNullOrEmpty($fachlicheBeschreibungCustomField.trim())
            if ($isEmpty -ne $true) {
                return $true
            }
        }
        $description = $Issue.renderedFields.description
        [regex]$regexFachlicheBeschreibung = $this.getBeschreibungRegex($true)
        $matchFachlicheBeschreibung = [regex]::matches($description, $regexFachlicheBeschreibung)
        return $matchFachlicheBeschreibung.Success -eq $true
    }

    [psobject]getStackObject($Name, $ChildArray) {
        return @{
            Name  = $Name
            Child = $ChildArray
        }
    }
    #Under Construction
    [string]handleUnclosedHTMLTags($htmlString) {
        [regex]$htmlTagRegex = "<(\/{1})?\w+((\s+\w+(\s*=\s*(?:`".*?`"|'.*?'|[^'`">\s]+))?)+\s*|\s*)>"
        $selfClosingTags = @('area', 'base', 'br', 'col', 'command', 'embed', 'hr', 'img', 'input', 'keygen', 'link', 'meta', 'param', 'source', 'track', 'wbr');

        $lines = $htmlString -split "\n"
        foreach ($line in $lines) {
            $tagsArray = [regex]::matches($line, $htmlTagRegex)
            if ($tagsArray.Success -eq $true) {
                foreach ($tagsArrayElement in $tagsArray) {
                    $value = $tagsArrayElement.Value
                    $elementName = $value.replace("<", "").replace(">", "")
                    $isSelfClosing = $selfClosingTags.Contains($elementName)
                    if ($isSelfClosing -eq $false) {
                        $closedTag = "</$elementName>"
                        $tagsArray = $tagsArray | Where-Object { $_.Value –ne $closedTag }
                    }
                }
            }
        }
        $tags = $htmlString -split $htmlTagRegex
        return $tags.length
    }
}