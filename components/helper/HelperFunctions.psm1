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

    [psobject]sortArrayByStructure($array, $structureArray) {
        return $array
        
    }

    [boolean]checkIfArrayContains($array, $value) {
        for ($i = 0; $i -lt $array.Count; $i++) {
            if ($array[$i] -eq $value) {
                return $true
            }
        }
        return $false
    }

    
}

