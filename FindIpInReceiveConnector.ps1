# Václav Měch
# Tieto
# simple script for checking receive connectors
# the use of Write-Host in this script is justified by the need for colored output ;)

function Find-IpInReceiveConnector {
    [CmdletBinding()]
    param(
        [parameter(Position=0,
        Mandatory=$true,
        ValueFromPipeline=$true)]
        [string] $ipToLookFor
    )

    # get all receive connectors that aren't the default ones
    $receiveConnectors = Get-ReceiveConnector | Where-Object Identity -NotMatch "Client|Outbound|Default"

    # check each one for the IP address
    foreach ($receiveConnector in $receiveConnectors) {
        "Checking $receiveConnector ..."
        $remoteIPRanges  = Get-ReceiveConnector $receiveConnector | Select-Object -ExpandProperty RemoteIPRanges
        # no point in checking this
        if ($remoteIPRanges.Expression -like "0.0.0.0-255.255.255.255") {
            Write-Host "Skipping $receiveConnector because it contains every IP.." -ForegroundColor "DarkYellow"
            continue
        }

        [string] $ipArray = @()
        foreach ($item in  $remoteIPRanges){
            #if it is a single address, add it to the list
            if ($item.lowerBound -eq $item.upperBound) {
                $ipArray += $item.lowerBound
            #if it is a range, expand it and add to the list
            } else {
                #convert to usable type
                $lowerBoundAddress = [IPAddress]$item.lowerBound
                $upperBoundAddress = [IPAddress]$item.upperBound

                #get the expanded IPs
                $expandedRange = New-IPRange $lowerBoundAddress $upperBoundAddress
                #add them to the list
                $ipArray += $expandedRange 
            }        
        }

        if ($ipArray.Contains($ipToLookFor)){
            Write-Host "Yes, the receive connector $receiveConnector contains this IP address" -ForegroundColor "green"
        } else {
            Write-Host "No, the receive connector $receiveConnector doesn't contain the IP address" -ForegroundColor "red"
        }
    }
}

#3rd party function that expands given IP range
function New-IPRange ($start, $end) {
# created by Dr. Tobias Weltner, MVP PowerShell
# http://powershell.com/cs/blogs/tobias/archive/2011/02/20/creating-ip-ranges-and-other-type-magic.aspx
    $ip1 = ([System.Net.IPAddress]$start).GetAddressBytes()
    [Array]::Reverse($ip1)
    $ip1 = ([System.Net.IPAddress]($ip1 -join '.')).Address

    $ip2 = ([System.Net.IPAddress]$end).GetAddressBytes()
    [Array]::Reverse($ip2)
    $ip2 = ([System.Net.IPAddress]($ip2 -join '.')).Address

    for ($x=$ip1; $x -le $ip2; $x++) {
        $ip = ([System.Net.IPAddress]$x).GetAddressBytes()
        [Array]::Reverse($ip)
        $ip -join '.'
    }
}

Find-IpInReceiveConnector $args[0]