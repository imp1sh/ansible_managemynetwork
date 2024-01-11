# imp1sh.ansible_managemynetwork.ansible_packages
Sets MOTD with useful information for your hosts. Make sure to have only motd configured in pam OR sshd, otherwise it might get printed twice. This motd role works well together with Netbox and [netbox2ansible role](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_netbox2yaml). Purpose, IP addresses and site will come out of netbox if set automatically.

Example of motd variables making use of this role:
```
motd_purpose: "demo alpine system"
motd_site: "Information about the site. This is usually being defined with group_vars instead of host_vars."
```
Example of how a typcial motd might look like.
```
   __   _ __                      __   
  / /  (_) /  _______  __ _   ___/ /__ 
 / /__/ / _ \/ __/ _ \/  ' \_/ _  / -_)
/____/_/_.__/\__/\___/_/_/_(_)_,_/\__/ 

This server is restricted for authorized people. If you have gained access illegitimately, leave now! Contravention will be prosecuted.
Hostname:       ansible1.example.com
OS:             Debian
Version:        12.2
purpose:        Main Ansible host
site:           my site
IPv6 address:   2001:123:2ad4:7300::4/64
IPv4 address:   10.10.129.27/26
timezone:       CET
```
