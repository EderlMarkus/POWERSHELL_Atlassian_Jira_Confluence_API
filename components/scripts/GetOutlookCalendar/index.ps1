Function Get-OutlookCalendar($Start, $End) {
    $retArray = @()
    Add-type -assembly "Microsoft.Office.Interop.Outlook" | out-null
    $olFolders = "Microsoft.Office.Interop.Outlook.OlDefaultFolders" -as [type]
    $outlook = new-object -comobject outlook.application
    $namespace = $outlook.GetNameSpace("MAPI")
    $folder = $namespace.getDefaultFolder($olFolders::olFolderCalendar)
    $Appointments = $folder.Items | select subject, start, isrecurring | sort start
    foreach ($item in $Appointments) {
        $retArray += $item
    }
    $recurringFilter = "[MessageClass]='IPM.Appointment' AND [isrecurring] = 'True'" #leave the date filter out

    $recurringappointments = ($namespace.GetDefaultFolder(9).Items).restrict($recurringfilter)
    $RecurringAppointments.Sort("[Start]")
    $recurringappointments.includerecurrences = $true

    $Start = $Start.ToShortDateString()
    $End = $End.ToShortDateString()

    $recurringappointment = $recurringappointments.find("  [Start] >= '$Start' AND  [Start] <= '$End'") #use the date filter here
    do {
        $recurringappointment = $recurringappointments.FindNext()
        $retArray += $recurringappointment
    }
    until(!$recurringappointment)
    return $retArray | select subject, start, isrecurring

}
function getLookUpDateRange() {
    $Today = (Get-Date).Date 
    #$Sunday = $Today.AddDays(-8)
    $Sunday = $Today.AddDays(0 - $Today.DayOfWeek.value__)
    $Saturday = $Sunday.AddDays(5)
    $Sunday = Get-Date $Sunday -Format yyyy-MM-dd
    $Saturday = Get-Date $Saturday -Format yyyy-MM-dd
    return @{
        start = $Sunday;
        end   = $Saturday
    }
}

$dateRange = getLookUpDateRange
$start = Get-Date $dateRange.start
$end = Get-Date $dateRange.end
$end = $end.AddDays(1)

$x = Get-OutlookCalendar $start $end