using module '.\Atlassian.psm1'
class Confluence : Atlassian {
    [string]$Auth
    [string]$BaseUrl
    [int32]$ancestorPageId
    [string]$Space
    
    Confluence([string]$Auth, [string]$BaseUrl) : base ([string]$Auth, [string]$BaseUrl) {
        
    }

        [psobject]getAttachmentsByPageTitle($title) {
        $page = $this.getPageByTitle($title)
        $pageId = $page.id
        $url = "/rest/api/content/$pageId/child/attachment"
        return $this.get($url).results
    }

    [Void]deleteAttachmentFromPage($pageId, $attachmentId) {
        $url = "/rest/api/content/$attachmentId"
        $this.delete($url)
    }
    [Void]uploadAttachmentToPage($pageId, $fPath, $fName) {
        $Headers = @{'Authorization' = "Basic " + $this.Auth 
            'X-Atlassian-Token'      = 'nocheck'
        }

        $fileBytes = [System.IO.File]::ReadAllBytes($fPath);
        $fileEncode = [System.Text.Encoding]::GetEncoding('UTF-8').GetString($fileBytes);
        $delimiter = [System.Guid]::NewGuid().ToString(); 
        $LF = "`r`n";
        $bodyData = ( 
            "--$delimiter",
            "Content-Disposition: form-data; name=`"file`"; filename=`"$fName`"",
            "Content-Type: application/octet-stream$LF",
            $fileEncode,
            "--$delimiter--$LF" 
        ) -join $LF

        $uri = "$("/rest/api/content/")$($pageId + "/")$("child/attachment")"
        $uri = $this.getUrl($uri)
        Invoke-RestMethod -Uri $uri -Method POST -ContentType "multipart/form-data; boundary=`"$delimiter`"" -Headers $Headers -Body $bodyData
    }

    [psobject]getPageByTitle($title) {
        $url = "/rest/api/content/?title=" + $title
        $pageInfo = $this.get($url).results
        $pageId = $pageInfo.id
        if ($null -eq $pageId) {
            return $null
        }
        return $this.getPageById($pageId)
    }

    [psobject]getPageById($id) {
        return $this.get("/rest/api/content/" + $id + "?expand=space,history,body.view,body.storage,metadata.labels")
    }

    [string]sanatzieHTMLValue($htmlValue) {
        $htmlValue = $htmlValue -replace "\n", "" -replace "\r", "" -replace "'", "\'" -replace '"', '\"'
        $htmlValue = $htmlValue -replace '(^\s+|\s+$)', '' -replace '\s+', ' '
        $htmlValue = $this.convertUmlaut($htmlValue)
        return $htmlValue

    }

    [string]getBodyForPageCreation($name, $ancestorPageId, $htmlValue) {

        if ($ancestorPageId -eq $null) {
            $tempAncestorPageId = $this.ancestorPageId
        }
        else {
            $tempAncestorPageId = $ancestorPageId
        }

        if ($htmlValue -eq $null) {
            $tempHtmlValue = "<p>This is a new page</p>"
        }
        else {
            $tempHtmlValue = $htmlValue
        }
        $tempHtmlValue = $this.sanatzieHTMLValue($tempHtmlValue)
        $url = "/rest/api/content/";
        $json = '{"ancestors": [{"id":' + $tempAncestorPageId + '}], "type":"page","title":"' + $name + '","space":{"key":"' + $this.Space + '"},"body":{"storage":{"value":"' + $tempHtmlValue.replace('"', "") + '","representation":"storage"}}}'

        return $json
    }
    [string]getBodyForPageCreation($name, $ancestorPageId) {

        if ($ancestorPageId -eq $null) {
            $tempAncestorPageId = $this.ancestorPageId
        }
        else {
            $tempAncestorPageId = $ancestorPageId
        }

        $url = "/rest/api/content/";
        $json = '{"ancestors": [{"id":' + $tempAncestorPageId + '}], "type":"page","title":"' + $name + '","space":{"key":"' + $this.Space + '"},"body":{"storage":{"value":"<p>This is a new page</p>","representation":"storage"}}}'
        return $json
    }
    [string]getBodyForPageCreation($name) {

        $url = "/rest/api/content/";
        $json = '{"ancestors": [{"id":' + $this.ancestorPageId + '}], "type":"page","title":"' + $name + '","space":{"key":"' + $this.Space + '"},"body":{"storage":{"value":"<p>This is a new page</p>","representation":"storage"}}}'
        return $json
    }

    [string]getBodyForPageUpdate($page, $htmlValue) {
        if ($htmlValue -eq $null -OR [string]::IsNullOrWhiteSpace($htmlValue) -OR [string]::IsNullOrEmpty($htmlValue)) {
            $body = "<p>No text was given</p>"
        }
        else {
            $body = $htmlValue
        }
        $versionNumber = $this.getNewVersionNumber($page.id)
        $title = $page.title
        $body = $this.sanatzieHTMLValue($body)
        $json = '{"title":"' + $title + '","version":{"number":' + $versionNumber + '},"type":"page","body":{"storage":{"value":"' + $body + '","representation":"storage"}}}'
        return $json
    }

    [int32]getNewVersionNumber($pageId) {
        $data = $this.get("/rest/api/content/" + $pageId + "?expand=version")
        return $data.version.number + 1
    }

  

    [boolean]deletePageByTitle($title, $withChildren) {
        $ancestorPage = $this.getPageByTitle($title);
        Write-Host $ancestorPage.id
        if ($ancestorPage.id -eq $null) {
            return $false
        }
        $ancestorId = $ancestorPage.id

        if ($withChildren -eq $true) {
            $children = $this.get("/rest/api/content/search?cql=ancestor=" + $ancestorId)
            $children = $children.results
            foreach ($child in $children) {
                $this.delete("/rest/api/content/" + $child.id)
            }
        }
        $this.delete("/rest/api/content/" + $ancestorId)
        return $true
    }



}
