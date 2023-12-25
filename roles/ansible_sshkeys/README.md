# imp1sh.ansible_managemynetwork.ansible_sshkeys

[Source Code on GitHub](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_sshkeys)

This role distributes ssh public keys to hosts and on that hosts to one ore multiple users. It can of course delete records, too.

> This role might take some time because for every host you run it on it will iterate over every key defined in `system_sshkeys`.
{.is-warning}

Sample playbook of how to call the role:

```yaml
---
- name: sshkeys deployment
  hosts: tags_allhosts, !platforms_openwrt
  become: true
  roles:
    - imp1sh.ansible_managemynetwork.ansible_sshkeys
```

## Variables

First you just define a list of keys in such a fashion:

```yaml
system_sshkeys:
  juni@hackintosh:
    state: present
    type: "ssh-rsa"
    key: "AAAAB3NzaC1yc2EAAAADAQABAAABgQDhVsHfgRu4zABLTEzyhur86uFMoVv8no4g2rlJwShwWMx5SJshhJ1T+BWY5FC1XG+pBdli7681Q2eWMd4IHxA15NGejnWDDhel1mYgBuZM7ge5NGXklYSCn32lKvImnjzAtPLGmUF6vVu//rZF4iA5C0vN5G6CWRDwPR6+JrsbIOuE9GZnmDXOYBrc5Hhc+lLtsSQxuLB9rdvVlLhanA8lZ/YZg6iYcOaDU6z8zewo4wW6sOr3bii3AUPmYUky05xXjtTrggje98IqfVBw1vjpHMv2StNbntYp5zpodvjIrf09Zy+cz4aApVquQCiXQDuTHjW/ufQqJaEIBFsIQGEmTypqwMDdtTT9i0k/apwpJVbnVd0CtW4KU86hTAhCjTZ9RjKFy6ACgfukCLktseeMkzTd74aC6svhXtGCK6fsuPwVpb3j6dFiiIH4mn2dctq0X8IumJ6BWVrpsejON++KYZhN3bZn8SjaVT4vH95E58nJ3f5RKzZ1olbr1TSWx2c="
  jochen@RXFedora:
    state: absent
    type: "ssh-rsa"
    key: "AAAAB3NzaC1yc2EAAAADAQABAAABAQCrBMHHozDF4Xl4lthGQab/1Fhr4kr6C5ylckNX25gFweMmFbuO/uXiw7sL4NqdROXbO7jj89pxh1qtiNF9iQu4HsusYhZcuCoPho/SCXkvdyQGcIUZIZElilyWyLOJNXK4H7YXDv7LmO5Rc9oAJp/XP7TWW6uILXYs97PdHOisUk/3QCJzkNfulodBz73z6aKjP9vSloJJQvK6YZEC2WYqv2JQKOR6Bkz1R1fvHKmOFWN2Ls3ZIYmjQ4ETZtXBAHLbPW7PHT/YLaKqOIn3zZ/1TGpJ2VP938KLMDCQG6jdnRhBiDGwbBnz67A3DrOeKKhDSDPC8gPca4aAgHhNE6WX"
```
## Assign key to a host
Next you need to make a call of where to distrube which keys. You can do that bei either assigning keys to hosts individually:

```
system_sshkeys_deploy_on_hosts:
  juni@hackintosh:
    user: "jochen"
    hosts:
      - mcrx1.example.com
```

Be aware that the host list needs to correspond to your ansible `inventory_hostname` special variable.

## Assign key to a group of hosts
The groups are of course Ansible groups. 
```yaml
system_sshkeys_deploy_on_hostgroups:
  jochen@RXFedora:
    user: "jochen"
    hostgroups:
      - "tags_allhosts"
  juni@hackintosh:
    user: "jochen"
    hostgroups:
      - "tags_allhosts"
```

Make sure to define those variable so your host will have access the variables listed above. Typically you have a list of users that is valid for all of your hosts, so you might want to put it in group_vars/all.yml or whatever you prefer.
