# ansible_packages
Manages default packages for you differnt OSes. Currently the group based definitions can only be used once, preferably global. You cannot add more packages in other group definitions. This is planned in the future.
On top of group based definitions you can also add packages on a per host basis.

Example for debian based hosts:
```
packagesdebian: "nmap, tcpdump, mc, git, screen, vim, htop, openssh-server, man, sudo, anacron, cron, rsync, python3, borgbackup, mtr"
```
If you want to add packages for a single host do it like this:
```
packages_host: "npm, nodejs"
```
