# modsecurity-trusted-bot-ips

A Bash script that automatically fetches and parses JSON-based IP range data for trusted search engine bots (Googlebot, Bingbot, and others), ideal for use with ModSecurity and other web application firewalls and web servers (nginx, apache).

---

## Features

- Retrieves the official IP ranges published by Google and Bing.
- Handles both IPv4 and IPv6 addresses.
- Creates a clean, deduplicated list that works perfectly for ModSecurity IP whitelisting.
- Includes helpful debug information like HTTP response codes and how many IPs were found.
- Designed to be easy to automate using cron jobs or systemd timers.

---

## Requirements

- Bash (tested on Linux)
- `curl` — for downloading JSON data
- `jq` — for parsing JSON (install via your package manager, e.g. `sudo apt install jq`)

---

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/spithash/modsecurity-trusted-bot-ips.git
   cd modsecurity-trusted-bot-ips
2. Make the script executable:

   ```bash
   chmod +x update-trusted-bot-ips.sh
## Usage

Run the script manually:

```bash
sudo ./update-trusted-bot-ips.sh
```

## Usage in your whitelist.conf (works also for apache or nginx)
```bash
SecRule REMOTE_ADDR "@pmFromFile /etc/modsecurity/google_bing_googlebot_ips.txt" "phase:1,nolog,allow,ctl:ruleEngine=Off,id:1007"
```

## Automate with Cron

To keep your IP whitelist up to date, add a cron job:

```cron
0 2 * * * /usr/local/bin/update-trusted-bot-ips.sh >> /var/log/update-trusted-bot-ips.log 2>&1
