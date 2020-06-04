# This script will bypass the "AllowRemoteUsers" setting set in ASDM
# A user session must be active, if not RDP in and Disconnect.
# Affects Cisco AnyConnect Secure Mobility Client 4.8.x and prior
# If script kills anyconnect but doesn't connect to vpn re-run, it may take 2 or 3 times.

$ciscovpn = Get-Process vpnui -ErrorAction SilentlyContinue
$ciscovpnagent = Get-Process vpnagent
$vpncli = "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe"
$arguments = "connect REMOTE.VPNSITE.COM" # CHANGE: REMOTE.VPNSITE.com
$server = "HOSTNAME" # CHANGE: HOSTNAME of machine that script is running on
$username = $env:USERNAME
$session = ((quser /server:$server | ? { $_ -match $username }) -split ' +')[2]

if ($ciscovpn -Or $ciscovpnagent) {
    # try gracefully first
    $ciscovpn.CloseMainWindow()
    Start-Sleep 2
    if (!$ciscovpn.HasExited) {
        $ciscovpn | Stop-Process -Force
        $ciscovpnagent | Stop-Process -Force
        Write-Host "Cisco VPN Process has been killed. Now re-run the script."
    }
}

else {
    Do{
        Write-Host "Starting ciscoRDP"
        Start-Process $vpncli $arguments
        Start-Sleep 2
        logoff $session /server:$server

        Get-NetIPInterface -InterfaceAlias "Ethernet 2" -Verbose | Format-Table -Property ConnectionState | Tee-Object -Variable OurInterface
        if($OurInterface -ne "Connected") {
            logoff $session /server:$server
        }
        elseif ($OurInterface == "Connected") {
            Write-Host "We are already connected.... Exiting"
            exit
        }
    }
    While($OurInterface -ne "Connected"){
        Start-Process $vpncli $arguments
        Start-Sleep 2
        logoff $session /server:$server
    }
}