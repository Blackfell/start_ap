# start_ap
Create a WiFi AP and view DNS/proxy traffic from clients. 

# What do

This is a stupid simple script to configure an AP and procy client traffic ina transparent way. 

## Dependencies

Install:
- dnschef
- isc-dhcp-server
- hostapd
- terminator
- WiFi card drivers


## Useage

You'll need to set the following script variables:
--------------------------------------------------------------------
| DEVICE      | The name of your wifi device                       |
| SSID        | The WiFi network name                              |
| PASSPHRASE  | wifi-network-passphrase                            |
| PROXY       | 0 for no proxying, 1 for HTTP and 2 for HTTP/HTTPS |
--------------------------------------------------------------------

Then just run the script:

```bash
./start_AP.sh
```

Press q when done to remove firewall rules etc.
