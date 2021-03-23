# ansible_repositorysetup
Ansible role to setup a system repository. Currently only Alpine Linux supported. More to come.

## Alpine
This is a typical variable definition which can be made on a global scale for all or many hosts. Still can be overriden if set explicitly for a host.
```
repolist_alpine:
  - url: "http://alpine.42.fr"
    communityenable: true
    version: latest-stable
```
Another example with a different URL and testing repo enable:
```
  - url: "https://ftp.halifax.rwth-aachen.de/alpine"
    communityenable: true
    testingenable: true
    version: latest-stable
```
As you can see you can define more than one repositories as this variable is a list with a nested dict.
You can either choose a distinct version like `3.12` or you can go for `latest-stable`. Another option is to go bleeding edge with `edge` which is not meant for production purposes.
A current list of available URLs can be fetched here:
https://mirrors.alpinelinux.org/mirrors.txt
In order for you to find out which URL might be best for you you can manually run setup-apkrepos on one host and choose `f`. Consider choosing different URLs for every site you have.
