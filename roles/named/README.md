# named

Safely deploys BIND (named) configuration and reloads the DNS service.

## How it works

1. Clones the client Git repository (2000) onto the controller's working directory
2. Syncs the config files to the target DNS server
3. Runs the `checkdns.sh` pre-flight validation script on the server
4. If all checks pass, runs `rndc reload` to apply the new config
5. If any critical check fails, the playbook stops — the service is not reloaded

Runs with `serial: 1` so servers are updated one at a time.

## Requirements

- The client Git repo must follow the expected structure: `templates/dns/{{ dns_scope }}/`
- The `dns_scope` variable is set by the inventory group (`internal` or `public`)

## Usage

```bash
# Push config to internal DNS servers
ansible-playbook playbooks/managed_services/named/push_config.yaml -i clients/2000/dns.ini -l internal

# Push config to public DNS servers
ansible-playbook playbooks/managed_services/named/push_config.yaml -i clients/2000/dns.ini -l public
```

The `-l` flag is mandatory — it determines which servers are targeted and sets the `dns_scope`.