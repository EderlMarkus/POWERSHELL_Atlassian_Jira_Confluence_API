class Atlassian {
    [string]$Auth
    [string]$BaseUrl

    Atlassian([string]$Auth, [string]$BaseUrl) {
        $this.Auth = $Auth
        $this.BaseUrl = $BaseUrl
    }
    [string]getUrl($url) {
        return [uri]::EscapeUriString($this.BaseUrl + $url)
    }
    
    [string]convertUmlaut($Text) {
            
        $output = $Text.Replace('ö', 'oe').Replace('ä', 'ae').Replace('ü', 'ue').Replace('ß', 'ss').Replace('Ö', 'Oe').Replace('Ü', 'Ue').Replace('Ä', 'Ae').Replace('&ouml;', "oe").Replace('&Ouml;', "Oe").Replace('&Auml;', "Ae").Replace('&auml;', "ae").Replace('&Uuml;', "Ue").Replace('&uuml;', "ue").Replace('&szlig;', "ß")
        $isCapitalLetter = $Text -ceq $Text.toUpper()
        if ($isCapitalLetter) { 
            $output = $output.toUpper() 
        }
        return $output
    }

    [psobject]get($url, $format) {
        if ($null -eq $format) {
            $format = "JSON"
        }

        $url = $this.getUrl($url)
        $Response = Invoke-WebRequest -URI $url -Headers @{'Content-Type' = 'application/json; charset=utf-8'; 'Authorization' = 'Basic ' + $this.Auth }

        if ($format -eq "JSON") {
            $data = [System.Text.Encoding]::UTF8.GetBytes($Response.Content)
            $data = [System.Text.Encoding]::GetEncoding("UTF-8").GetString($data);
            $data = $this.convertUmlaut($data)    
            return $data | ConvertFrom-Json
        }
        if ($format -eq "XML") {
            return [xml]$Response.Content
        }
        return $null
    }

    [psobject]get($url) {
        $url = $this.getUrl($url)
        $Response = Invoke-WebRequest -URI $url -Headers @{'Content-Type' = 'application/json; charset=utf-8'; 'Authorization' = 'Basic ' + $this.Auth }
        $data = [System.Text.Encoding]::UTF8.GetBytes($Response.Content)
        $data = [System.Text.Encoding]::GetEncoding("UTF-8").GetString($data);
        $data = $this.convertUmlaut($data)
        $retData = $data | ConvertFrom-Json
        return $retData

    }

    [Void]put($url, $json) {
        $url = $this.getUrl($url)
        $header = @{
            "Authorization" = "Basic " + $this.Auth
            "Content-Type"  = "application/json; charset=utf-8"
        }
    
        Invoke-RestMethod -Uri $url -Method 'Put' -Body $json -Headers $header
    }
    [Void]post($url, $json) {
        $url = $this.getUrl($url)
        $header = @{
            "Authorization" = "Basic " + $this.Auth
            "Content-Type"  = "application/json; charset=utf-8"
        }
        Invoke-RestMethod -Uri $url -Method 'Post'-Body $json -Headers $header
    }

    [Void]delete($url) {
        $url = $this.getUrl($url)
        $header = @{
            "Authorization" = "Basic " + $this.Auth
        }

        Invoke-RestMethod -Uri $url -Method 'Delete' -Headers $header
    }
   
}


