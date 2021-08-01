#Requires -Version 3

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Function Update-CloudFlareDynamicDns
{
    [cmdletbinding()]
    param
    (
        [Parameter(mandatory = $true)]
        [string]$Token,

        [Parameter(mandatory = $true)]
        [ValidatePattern("[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")]
        [string]$Email,

        [Parameter(mandatory = $true)]
        [string]$Zone,

        [Parameter(mandatory = $false)]
        [string]$Record,
		
		[Parameter(mandatory = $false)]
        [switch]$UseDns
    )
	if ($record) {
		$hostname = "$record.$zone"
	} else {
		$hostname = "$zone"
	}
	$headers = @{
		'X-Auth-Key' = $token
		'X-Auth-Email' = $email
	}

	#Write-Output "Resolving external IP"
	try { ($ipaddr = Invoke-RestMethod "https://ipv4.icanhazip.com/").trim();
          if ($ipaddr -eq $null) {
            $ipaddr = Invoke-RestMethod "http://ipinfo.io/json" | Select-Object -ExpandProperty ip
          }
        }
	catch { throw "Can't get external IP Address. *Throw tantrum*" }

	if ($ipaddr -eq $null) { throw "Can't get external IP Address. *Throw tantrum*" }
	#Write-Output "External IP is $ipaddr"
	
	#Write-Output "Getting Zone information from CloudFlare"
	$baseurl = "https://api.cloudflare.com/client/v4/zones"
	$zoneurl = "$baseurl/?name=$zone"

	try { $cfzone = Invoke-RestMethod -Uri $zoneurl -Method Get -Headers $headers } 
	catch { throw $_.Exception }

	if ($cfzone.result.count -gt 0) { $zoneid = $cfzone.result.id } else { throw "Zone $zone does not exist" }
	
	#Write-Output "Getting current IP for $hostname"
	$recordurl = "$baseurl/$zoneid/dns_records/?name=$hostname"
	
	if ($usedns -eq $true) { 
		try { 
			$cfipaddr = [System.Net.Dns]::GetHostEntry($hostname).AddressList[0].IPAddressToString
			#Write-Output "$hostname resolves to $cfipaddr"
		} catch {
			$new = $true
			#Write-Output "Hostname does not currently exist or cannot be resolved"
		}
	} else {
		try { $dnsrecord = Invoke-RestMethod -Headers $headers -Method Get -Uri $recordurl } 
		catch { throw $_.Exception }
		
		if ($dnsrecord.result.count -gt 0) {
			$cfipaddr = $dnsrecord.result.content
			#Write-Output "$hostname resolves to $cfipaddr"
		} else {
			$new = $true
			#Write-Output "Hostname does not currently exist"
		}
	}
	
	# If nothing has changed, quit
	if ($cfipaddr -eq $ipaddr) {
		#Write-Output "No updates required"
		return
	} elseif ($new -ne $true) {
		#Write-Output "IP has changed, initiating update"
	}
	
	# If the ip has changed or didn't exist, update or add
	if ($usedns) {
		#Write-Output "Getting CloudFlare Info"
		try { $dnsrecord = Invoke-RestMethod -Headers $headers -Method Get -Uri $recordurl } 
		catch { throw $_.Exception }
	}
	
	# if the record exists, then udpate it. Otherwise, add a new record.
	if ($dnsrecord.result.count -gt 0) {
		#Write-Output "Updating CloudFlare record for $hostname"
		$recordid = $dnsrecord.result.id
		$dnsrecord.result | Add-Member "content"  $ipaddr -Force 
		$body = $dnsrecord.result | ConvertTo-Json
		
		$updateurl = "$baseurl/$zoneid/dns_records/$recordid" 
		$result = Invoke-RestMethod -Headers $headers -Method Put -Uri $updateurl -Body $body -ContentType "application/json"
		$newip = $result.result.content
        Set-Variable -Name Response -Value "OK" -Scope Global
		#Write-Output "Updated IP to $newip"
	} else {
		#Write-Output "Adding $hostname to CloudFlare"
		$newrecord = @{
			"type" = "A"
			"name" =  $hostname
			"content" = $ipaddr
		}
		
		$body = ConvertTo-Json -InputObject $newrecord
		$newrecordurl = "$baseurl/$zoneid/dns_records"
		
		try {
			$request = Invoke-RestMethod -Uri $newrecordurl -Method Post -Headers $headers -Body $body -ContentType "application/json"
		    Write-Verbose "Update successful."
            Set-Variable -Name Response -Value "OK" -Scope Global
		} catch {
			throw $_.Exception
            Set-Variable -Name Response -Value "ERROR" -Scope Global
		}
	}
}

Update-CloudFlareDynamicDns -Token <# ReplaceWith_Cloudflare_Token #> -Email <# ReplaceWith_Cloudflare_Email #> -Zone <# ReplaceWith_DomainName #> -Record <# ReplaceWith_RecordName #>
