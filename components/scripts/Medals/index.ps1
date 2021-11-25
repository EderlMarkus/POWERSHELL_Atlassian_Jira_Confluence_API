#import needed modules
using module '..\..\helper\HelperFunctions.psm1'
using module '..\..\helper\JiraHelper.psm1'
using module '..\..\helper\ConfluenceHelper.psm1'
using module '..\..\atlassian\Jira.psm1'
using module '..\..\atlassian\Confluence.psm1'

#import needed files
. ..\..\..\constants.ps1

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
                  <p>Dr. Max Mustermann</p>
                </td>
                <td style="text-align: center">
                  <img
                    src="https://antrag.tst.raiffeisenbank.at/rest/fileStore/4919afd9-16db-45c1-80b4-4650a3d85281?companyBusinessId=32000"
                    width="70%"
                  />
                  <p>Dr. Maria Musterfrau</p>
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
  $NewLine = "{0},{1},{2}" -f $recipient, $level, $topic
  $NewLine | add-content -path "data.csv"    
  
}
function getFromDatabase() {
  return Import-Csv "data.csv"
}
function checkIfEntryExistsInDatabase($recipient, $level, $topic, $data) {
  $foundEntries = $data | Where-Object { $_.recepient -eq $recipient -and $_.level -eq $level -and $_.topic -eq $topic }
  return $null -ne $foundEntries
}
function handleDatabase($medalObject, $recipient) {
  $topic = $medalObject.topic
  $level = $medalObject.level
  $data = getFromDatabase
  $entryExists = checkIfEntryExistsInDatabase $recipient $level $topic $data
  if ($entryExists -eq $false) {
    addToDatabase $recipient $level $topic
  }
  return $entryExists
}
function handleMail($medalObject) {
  $recipients = $medalObject.recipients
  $topic = $medalObject.topic
  $level = $medalObject.level

  $body = getMailBody $level $topic
  sendMail $recipients $body $level
}
####### FUNCTIONS END #######

####### CODE EXECUTION START #######
$medals = @(
  @{
    recipients = @("michael.brettlecker@raiffeisenbank.at")
    topic      = "Herausragende Leistungen & Durchhaltevermögen im Projekt Debitkarte."
    level      = 2
  }
)

foreach ($medal in $medals) {
  $recipients = $medal.recipients
  foreach ($recipient in $recipients) {
    $entryExisted = handleDatabase $medal $recipient
    if ($entryExisted -eq $false) {
      handleMail($medal)
    }
  }
}
####### CODE EXECUTION END #######



