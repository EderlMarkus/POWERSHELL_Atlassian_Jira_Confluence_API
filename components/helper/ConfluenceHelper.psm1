class ConfluenceHelper {
    [psobject]$Confluence
    [psobject]$HelperFunctions

    ConfluenceHelper(
        [psobject]$Confluence,
        [psobject]$HelperFunctions
    ) {
        $this.Confluence = $Confluence
        $this.HelperFunctions = $HelperFunctions
    }
}