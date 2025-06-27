# Modsecurity Trusted Bot IPs JSON Parser and Whitelist Generator

A Bash script that fetches and parses JSON-based IP range data for trusted search engine bots (Googlebot, Bingbot, and others), ideal for use with ModSecurity and other web application firewalls and web servers (nginx, apache).
I use this for creating a .txt file and then whitelist all the entries in modsecurity's whitelist.conf

---

## Features

- Retrieves the official IP ranges published by Google and Bing.
- Handles both IPv4 and IPv6 addresses.
- Creates a clean, deduplicated list that works perfectly for ModSecurity IP whitelisting.
- Includes helpful debug information like HTTP response codes and how many IPs were found.
- Designed to be easy to automate using cron jobs or systemd timers.

---

## Requirements

- `bash` (tested on Linux)
- `curl` — for crawling the JSON urls and handling http statuses.
- `jq` — for parsing JSON (install via your package manager, e.g. `sudo apt install jq`)

---

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/spithash/modsecurity-trusted-bot-ips.git
   cd modsecurity-trusted-bot-ips
2. Make the script executable:

   ```bash
   chmod +x update-trusted-bot-ips
## Usage

Run the script manually:

```bash
sudo ./update-trusted-bot-ips
```

## Usage in your whitelist.conf (works also for apache or nginx)
Make sure you change the id '1007' to a unique id in case you have the same somewhere in your rules.
```bash
SecRule REMOTE_ADDR "@pmFromFile /etc/modsecurity/google_bing_googlebot_ips.txt" "phase:1,nolog,allow,ctl:ruleEngine=Off,id:1007"
```

## Automate with Cron

To keep your IP whitelist up to date, add a cron job:

```cron
0 2 * * * /usr/local/bin/update-trusted-bot-ips >> /var/log/update-trusted-bot-ips.log 2>&1
