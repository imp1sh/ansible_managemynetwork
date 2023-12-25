# imp1sh.ansible_managemynetwork.ansible_openwrtbabeld
babeld is a dynamic layer 3 routing daemon.

This role is not finished. Since version 0.5.0 of this collection there is rudimentary support for babeld. If you're missing a feature, just contact me.

This is an example how to define what interfaces babeld should run on.
```yaml
openwrt_babeld_interfaces:
  - name: "RXFORELLE"
    type: "tunnel"
```

On top on fhtat you might want to define some filters.
```yaml
openwrt_babeld_filter:
  - type: "redistribute"
    local: "true"
    action: "deny"
  - type: "redistribute"
    ip: "2a01:4d3f:2a00::/48"
  - type: "redistribute"
    ip: "{{ nb_prefixes['Forelle-ROOT']['6']['gua'] }}"
  - type: "redistribute"
    ip: "{{ nb_prefixes['Forelle-ROOT']['4']['prefix'] }}"
```

For further information on how to configure babeld, look at the [official documentation](https://www.irif.fr/~jch/software/babel/). There is also some [OpenWrt specific documentation for babeld](https://openwrt.org/docs/guide-user/services/babeld).
