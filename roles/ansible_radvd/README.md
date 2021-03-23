# imp1sh radvd
Part of nftwall collection
As you might have guessed, it's about setting up Router Advertisement Daemon.
Example to set variables:
```radvd_ifs:
  - if: "eth1"
      prefixes:
            - prefix: "2001:470:7e68:1000::/64"
```
Example with more interfaces and maybe more prefixes:
```radvd_ifs:
   - if: "eth1"
     prefixes:
       - prefix: "2001:470:7e68:1000::/64"
       - prefix: "2001:470:7e68:2000::/64"
   - if: "eth2"
     prefixes:
       - prefix: "2001:470:7e68:3000::/64"
```
