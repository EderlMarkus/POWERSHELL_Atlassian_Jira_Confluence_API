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


#functions
function Get-Date-Of-Next-Weekday ($startDate, $weekday) {
    $date = Get-Date $startDate
    while ($date.DayOfWeek -ne $weekday) { $date = $date.AddDays(1) }
    return $date
}
function Get-Date-Of-Next-Wednesday ($startDate) {
    return Get-Date-Of-Next-Weekday $startDate "Wednesday"
}

function Get-Date-Of-Next-Tuesday ($startDate) {
    return Get-Date-Of-Next-Weekday $startDate "Tuesday" 
}
function Check-If-Holiday ($date) {
    $holidays = @(
        "01.01.2022",
        "06.01.2022",
        "15.04.2022",
        "17.04.2022",
        "18.04.2022",
        "01.05.2022",
        "26.05.2022",
        "05.06.2022",
        "06.06.2022",
        "16.06.2022",
        "15.08.2022",
        "26.10.2022",
        "01.11.2022",
        "08.12.2022",
        "25.12.2022",
        "26.12.2022"
    )
    $dateToCheck = Get-Date $date -Format "dd.MM.yyyy"
    for ($i = 0; $i -lt $holidays.Count; $i++) {
        if ($holidays[$i] -eq $dateToCheck) {
            return $true
        }
    }
    return $false
}
#update 1
$Jira = [Jira]::new($authJIRAIntern, "https://webforms-jira-intern.raiffeisenbank.at")
$url = "/rest/api/2/version"

$nextDate = "01.01.2022"
$nextDateCompare = Get-Date $nextDate
$endDate = Get-Date "31.12.2022"
$allReleases = @()
# JiraId von RLB Projektmanagement
while ($nextDateCompare -lt $endDate) {
    $projectId = "10100"
    $nextWednesdayDate = Get-Date-Of-Next-Wednesday $nextDate
    $releaseDate = Get-Date $nextWednesdayDate -Format "yyyy-MM-dd"
    $userReleaseDate = Get-Date $nextWednesdayDate -Format "dd.MM.yyyy"
    $previousDate = $nextWednesdayDate.AddDays(-6)
    $userStartDate = Get-Date $previousDate -Format "dd.MM.yyyy"
    $releaseIsHoliday = Check-If-Holiday $releaseDate
    $startIsHoliday = Check-If-Holiday $userStartDate

    while ($releaseIsHoliday -eq $true) {
        $newDate = Get-Date $releaseDate
        $releaseDate = $newDate.AddDays(1)
        $releaseIsHoliday = Check-If-Holiday $releaseDate
        $releaseDate = Get-Date $releaseDate -Format "yyyy-MM-dd"

    }
    while ($startIsHoliday -eq $true) {
        $newDate = Get-Date $userStartDate
        $userStartDate = $newDate.AddDays(1)
        $startIsHoliday = Check-If-Holiday $userStartDate
        $userStartDate = Get-Date $userStartDate -Format "dd.MM.yyyy"
    }
    
    $name = "Hotfix " + $userReleaseDate
    $Body = @{
        description   = "Hotfix Version " + $userReleaseDate + " by Markus Ederl"
        name          = $name
        archived      = "false"
        released      = "false"
        projectId     = $projectId
        userStartDate = $userStartDate
        releaseDate   = $releaseDate
    }
    $allReleases += $Body
    $body = $Body | ConvertTo-Json
    #Write-Host $body.userStartDate
    #$Jira.post($url, $body)
        
    
    $nextDate = $nextWednesdayDate.AddDays(6) 
    $nextDate = Get-Date $nextDate -Format "dd.MM.yyyy";
    $nextDateCompare = Get-Date $nextDate
}

$json = $allReleases | ConvertTo-Json -Depth 10
Set-Clipboard -Value $json