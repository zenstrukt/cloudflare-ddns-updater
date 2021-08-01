# Cloudflare DDNS Updater - For PowerShell users
Adds/Updates Cloudflare DNS entries for the purpose of DDNS using PowerShell. PowerShell can also be installed onto your Nix flavour of choice and scheduled with crontab.

## Installation

```bash
git clone https://github.com/zenstrukt/cloudflare-ddns-updater.git
```

## Usage
This script is used with Task Scheduler in Windows, or crontab in Linux. Specify the frequency of execution, and you're done!

```bash
Import-Module Update-Cloudflare-DDNS.psm1

Update-CloudFlareDynamicDns -Token <# ReplaceWith_Cloudflare_Token #> -Email <# ReplaceWith_Cloudflare_Email #> -Zone <# ReplaceWith_DomainName #> -Record <# ReplaceWith_RecordName #>
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
