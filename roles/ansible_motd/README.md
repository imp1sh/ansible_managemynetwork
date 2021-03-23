# ansible_motd
Part of nftwall. Sets a beautiful ASCII art login screen together with helpful information about the host.

Example of motd variables making use of this role:
```
motd_purpose: "demo alpine system"
motd_site: "Information about the site. This is usually being defined with group_vars instead of host_vars."
```
Example of how a typcial motd might look like.

       ___            _ __   __   
      / _ | ___  ___ (_) /  / /__ 
     / __ |/ _ \(_-</ / _ \/ / -_)
    /_/ |_/_//_/___/_/_.__/_/\__/ 
                                 
    This server is restricted for certain people. If you have gained access illegitimately leave now. Contravention will be prosecuted.
    Hostname:       icingamaster.mydomain.com
    OS family:      Alpine
    site:           Düsseldorf Equinix Bahnhof
    purpose:        Icinga2 Master Host Datacenter Düsseldorf
    IP address:     2a00:a123:2afe:4::6
