using module '..\..\helper\HelperFunctions.psm1'
using module '..\..\helper\JiraHelper.psm1'
using module '..\..\helper\ConfluenceHelper.psm1'
using module '..\..\atlassian\Jira.psm1'
using module '..\..\atlassian\Confluence.psm1'
using module '.\RecepientFinder.psm1'
#import needed files
. ..\..\..\constants.ps1

$HelperFunctions = [HelperFunctions]::new()
$Jira = [Jira]::new($authJIRAIntern, "https://webforms-jira-intern.raiffeisenbank.at")
$JiraHelper = [JiraHelper]::new($Jira, $HelperFunctions)
$Confluence = [Confluence]::new($authJIRAIntern, "https://collab.raiffeisenbank.at")
$ConfluenceHelper = [ConfluenceHelper]::new($Confluence, $HelperFunctions)
$RecepientFinder = [RecepientFinder]::new($Jira, $JiraHelper)
####### FUNCTIONS START #######
function getLevelObject($level) {
  $text = ""
  $logo = ""
  if ($level -eq 1) {
    $text = "GOLD"
    $logo = "https://antrag.tst.raiffeisenbank.at/rest/fileStore/1fc43f4e-e5c0-446f-a43a-75a540ffe95c?companyBusinessId=COMPANY_BUSINESS_ID"
  }
  if ($level -eq 2) {
    $text = "SILBER"
    $logo = "https://antrag.tst.raiffeisenbank.at/rest/fileStore/0a09c14c-9144-4f13-ab67-ff6f3210d55c?companyBusinessId=COMPANY_BUSINESS_ID"
  }
  if ($level -eq 3) {
    $text = "BRONZE"
    $logo = "https://antrag.tst.raiffeisenbank.at/rest/fileStore/6c02c8e6-a5db-4fde-9bc9-7f2133200c39?companyBusinessId=COMPANY_BUSINESS_ID"
  }
  return @{
    text = $text
    logo = $logo
  }
}
function sendMail($recipients, $body, $level) {
  $levelObject = getLevelObject($level)
  $levelText = $levelObject.text
  $ol = New-Object -comObject Outlook.Application
  $newmail = $ol.CreateItem(0) 
  foreach ($recipient in $recipients) {
    $newmail.Recipients.Add($recipient) | Out-Null
  }
  $newmail.Subject = "OKP Medaillie in $levelText"
  $newmail.sender = "medaillie@okp.at"
  $htmlbody = $body | Out-String
  $newmail.HTMLBody = $htmlbody
  $newmail.Send()
}
function getMailBody($level, $topic) {
  $levelObject = getLevelObject($level)
  return '<html>
  <head>
    <meta charset="utf-8" />
    <!-- utf-8 works for most cases -->
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <!-- Forcing initial-scale shouldnt be necessary -->
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <!-- Use the latest (edge) version of IE rendering engine -->
    <meta name="x-apple-disable-message-reformatting" />
    <!-- Disable auto-scale in iOS 10 Mail entirely -->
    <title></title>
  </head>
  <body
    style="
      background: black;
      text-align: center;
      color: #fff;
      font-family: Open Sans, sans-serif;
      padding: 5%;
    "
  >
    <h2>Gratulation!</h2>
    <p>Sie erhalten den OKP-Preis in</p>
    <h1>'+ $levelObject.text + '</h1>
    <p>für: '+ $topic + '</p>
    <div class="container">
      <table style="margin: auto">
        <tr>
          <td width="300">
            <table>
              <tr>
                <td width="100%">
                  <img
                    src="'+ $levelObject.logo + '"
                    width="100%"
                  />
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>

      <table style="margin: auto">
        <tr>
          <td width="500">
            <table>
              <tr>
                <td style="text-align: center">
                  <img
                    src="https://antrag.tst.raiffeisenbank.at/rest/fileStore/4919afd9-16db-45c1-80b4-4650a3d85281?companyBusinessId=32000"
                    width="70%"
                  />
                  <p>Markus Ederl, Legende</p>
                </td>
                <td style="text-align: center">
                  <img
                    src="https://antrag.tst.raiffeisenbank.at/rest/fileStore/4919afd9-16db-45c1-80b4-4650a3d85281?companyBusinessId=32000"
                    width="70%"
                  />
                  <p>Lukas Ganster, Stellvertretende Legende</p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </div>
  </body>
</html>
'
}
function addToDatabase($recipient, $level, $topic, $path) {
  $date = Get-Date
  $NewLine = "{0},{1},{2},{3}" -f $recipient, $level, $topic, $date
  $NewLine | add-content -path "data.csv"    
}
function getFromDatabase() {
  return Import-Csv "data.csv"
}
function checkIfEntryExistsInDatabase($recipient, $level, $topic, $data) {
  $foundEntries = $data | Where-Object { $_.recepient -eq $recipient -and $_.level -eq $level -and $_.topic -eq $topic }
  return $null -ne $foundEntries
}

function updateHTML($data) {
  $addString = "var dataJSON = ["
  foreach ($line in $data) {

    $recepient = $line.recepient
    $level = $line.level
    $topic = $line.topic.Replace("'", "").Replace('"', '')
    $date = $line.date
    $addString += "{recepient: '$recepient',level:'$level',topic:'$topic',date:'$date'},"
  }
  $addString += "]"
  Set-Content -Path "./htmlPage/data.js" -Value $addString -Encoding UTF8 
}
function handleDatabase($medalObject, $recipients) {
  $topic = $medalObject.topic
  $level = $medalObject.level
  $data = getFromDatabase
  $entriesExist = $true
  foreach ($recipient in $recipients) {
    $entryExists = checkIfEntryExistsInDatabase $recipient $level $topic $data
    if ($entryExists -eq $false) {
      $entriesExist = $false
      addToDatabase $recipient $level $topic
    }
  }
  updateHTML(getFromDatabase)

  return $entriesExist
}
function handleMail($medalObject) {
  $recipients = $medalObject.recipients
  $topic = $medalObject.topic
  $level = $medalObject.level

  $body = getMailBody $level $topic
  sendMail $recipients $body $level
}
function pushToNetworkFolder($pathOfRepository) {
  Set-Location -Path ".\htmlPage"
  git checkout -b master
  git add .
  $commitMessage = "Automated Push"
  git commit -m $commitMessage
  git push -u origin master
  Set-Location -Path $pathOfRepository
  git merge master
}
####### FUNCTIONS END #######

####### CODE EXECUTION START #######
#### GET INFO FROM JIRA
#### TODO ###

#$noDefectRecepients = $RecepientFinder.getNoDefectsRecepients()
$medals = $RecepientFinder.getReleaseVersionsRecepients(7)


foreach ($medal in $medals) {
  $recipients = $medal.recipients
  $entryExisted = handleDatabase $medal $recipients
  if ($entryExisted -eq $false) {
    #handleMail($medal)
    Write-Host "Sende Mail an $recipients"
  }
}

pushToNetworkFolder("H:\Datenaustausch\Exchange\RUV\ONK\DIG_Collaboration\Collab\Medaillien")


####### CODE EXECUTION END #######



