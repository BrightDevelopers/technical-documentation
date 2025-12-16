Library "common-functions.brs"

' Network interface configuration and status management

' Configure network interface
Sub ConfigureNetwork()
    nc = CreateObject("roNetworkConfiguration", 0)  ' eth0

    ' Set DHCP
    nc.SetDHCP()

    ' Or set static IP
    ' nc.SetIP4Address("192.168.1.100")
    ' nc.SetIP4Netmask("255.255.255.0")
    ' nc.SetIP4Gateway("192.168.1.1")
    ' nc.SetDNSServers(["8.8.8.8", "8.8.4.4"])

    ' Apply configuration
    nc.Apply()
End Sub

' Get network status
Function GetNetworkStatus() As Object
    nc = CreateObject("roNetworkConfiguration", 0)
    config = nc.GetCurrentConfig()

    status = {
        ip: config.ip4_address,
        netmask: config.ip4_netmask,
        gateway: config.ip4_gateway,
        dhcp: config.dhcp,
        dns: config.dns_servers
    }

    return status
End Function

Sub Main()
    ShowMessage("18: Network Configuration")
    ' Configure the network
    print "This is where we would configure the network interface..."
    'ConfigureNetwork()

    ' Wait for configuration to take effect
    sleep(2000)

    ' Get and display network status
    print "Getting network status..."
    status = GetNetworkStatus()

    print "Network Status:"
    print "  IP Address: " + status.ip
    print "  Netmask: " + status.netmask
    print "  Gateway: " + status.gateway
    if status.dhcp then
        print "  DHCP Enabled: true"
    else
        print "  DHCP Enabled: false"
    end if

    if status.dns <> invalid then
        print "  DNS Servers:"
        for each server in status.dns
            print "    " + server
        end for
    end if
End Sub
