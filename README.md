# VXLAN Collector Setup

The Bash script [vxlan-setup.sh](vxlan-setup.sh) automates the setup of a VXLAN
Collector on a Debian 11 instance.

## Usage

1. Run `vxlan-setup.sh` providing the IP address of the remote t-meter that will
receive mirrored traffic:
   ```
   $ sudo ./vxlan-setup.sh 172.31.1.23
   Setting up VXLAN: remote IP 172.31.1.23
   VXLAN setup complete. Reboot.
   ```
1. Reboot instance.

VXLAN setup is now complete.

All traffic received by the primary network interface will be mirrored to the
remote t-meter.
