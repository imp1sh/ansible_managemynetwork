# imp1sh.ansible_managemynetwork.ansible_sudo

[Source Code on GitHub](https://github.com/imp1sh/ansible_managemynetwork/tree/main/roles/ansible_sudo)

This role installs sudo and deploy sudoers files into sudoers.d. For the sudoers items it makes use of [community.general.sudoers](https://docs.ansible.com/ansible/latest/collections/community/general/sudoers_module.html). There you can see what items a sudoers dict item can hold. You can define sudoers items on multiple layers.

## host based
Put sudoers rules into `host_vars/yourhostname.yml`.

```yaml
sudo_sudoers_host:
  - name: "test sudorecord"
    state: present
    user: testuser
    commands:
      - "/usr/bin/ls"
```

## group based
Put sudoers rules into a variable where all hosts that need it will see, e.g. `group_vars/all.yml`.
```yaml
sudo_sudoers_group:
  webservers:
    - name: "test sudorecord"
      state: present
      user: testuser
      commands:
        - "/usr/bin/ls"
```

This way only the hosts in the Ansible group `webservers` will get this rule.

## role based
If you need sudo rules for your playbook or your role, you can [call](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/include_role_module.html) this very role and assign sudo rules by setting this variable.
```yaml
sudo_sudoers_role:
  - name: "some other sudorecord"
    state: present
    user: testuser2
    commands:
      - "/usr/bin/cat"
```
Here is an example how to outsource sudoers tasks to this role:
```yaml
- name: Set installrole var
  ansible.builtin.set_fact:
    sudo_sudoers_role:
      - name: "some other sudorecord2"
        state: present
        user: testuser3
        commands:
          - "/usr/bin/top"
- name: run sudo role
  ansible.builtin.include_role:
    name: imp1sh.ansible_managemynetwork.ansible_sudo
```
