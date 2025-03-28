############################################
# Simple script to delete a resource group #
############################################

function Read-HostColor {
    param(
        [string]$Text,
        [ConsoleColor]$ForegroundColor = "Yellow",
        [ConsoleColor]$BackgroundColor = $Host.UI.RawUI.BackgroundColor
    )
    Write-Host $Text -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor -NoNewline
    Read-Host
}

$rg_name = Read-HostColor -Text "What is the name of Resource Group you want to delete? " -ForegroundColor "Green"
Write-Host ""

Write-Host "Deleting $rg_name Resource Group. Please confirm your action" -ForegroundColor "Red"
Write-Host ""

az group delete --name $rg_name

Write-Host ""
Write-Host "Resource Group $rg_name deleted successfully!" -ForegroundColor "Blue"