Add-Type -AssemblyName System.Web

# ============================================================
# Miliastra Wonderland Ode Exporter (Multi-Account Enabled)
# ============================================================

$possiblePaths = @(
    "$env:USERPROFILE\AppData\LocalLow\miHoYo\Genshin Impact\output_log.txt",
    "$env:USERPROFILE\AppData\LocalLow\miHoYo\YuanShen\output_log.txt"
)

$logPath = $null
foreach ($p in $possiblePaths) {
    if ([System.IO.File]::Exists($p)) { $logPath = $p; break }
}

if (-not $logPath) {
    Write-Host "Cannot find output_log.txt! Open the wish history in-game first." -ForegroundColor Red
    return
}

$logs = Get-Content -Path $logPath
$m = $logs -match "(?m).:/.+(GenshinImpact_Data|YuanShen_Data)"
$m[0] -match "(.:/.+(GenshinImpact_Data|YuanShen_Data))" >$null

if ($matches.Length -eq 0) {
    Write-Host "Cannot find game data directory in log!" -ForegroundColor Red
    return
}

$gamedir = $matches[1]
$webcachePath = Resolve-Path "$gamedir/webCaches"
$cacheVerPath = Get-Item (Get-ChildItem -Path $webcachePath | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$cachefile = Resolve-Path "$cacheVerPath/Cache/Cache_Data/data_2"
$tmpfile = "$env:TEMP/mw_cache_data_2"

Copy-Item $cachefile -Destination $tmpfile
$content = Get-Content -Encoding UTF8 -Raw $tmpfile
$splitted = $content -split "1/0/"
$found = $splitted -match "authkey="
$linkFound = $false
$baseUrl = ""

for ($i = $found.Length - 1; $i -ge 0; $i -= 1) {
    if ($found[$i] -match "(https.+?game_biz=(hk4e_global|hk4e_cn))") {
        $baseUrl = $matches[0]
        $linkFound = $true
        break
    }
}
Remove-Item $tmpfile

if (-not $linkFound) {
    Write-Host "Cannot find auth URL! Open history in-game." -ForegroundColor Red
    return
}

$bannerTypes = @{ "event" = "2000"; "standard" = "1000" }
$formattedData = @{ event = @(); standard = @() }
$accountUid = "Unknown"

foreach ($banner in $bannerTypes.GetEnumerator()) {
    $bannerName = $banner.Name
    $gachaType = $banner.Value
    $endId = "0"
    
    Write-Host "Fetching $bannerName Odes..." -ForegroundColor Cyan
    
    do {
        $requestUrl = "$baseUrl&gacha_type=$gachaType&size=20&end_id=$endId"
        
        try { $response = Invoke-RestMethod -Uri $requestUrl -Method Get }
        catch { Write-Host "Network error." -ForegroundColor Red; exit }
        
        if ($response.retcode -ne 0) {
            Write-Host "API Error: $($response.message)." -ForegroundColor Red
            break
        }
        
        $pulls = $response.data.list
        if ($pulls -eq $null -or $pulls.Count -eq 0) { break }
        
        foreach ($pull in $pulls) {
            # Capture the UID on the first valid pull we see
            if ($accountUid -eq "Unknown" -and $pull.uid) { $accountUid = $pull.uid }

            $itemName = if ($pull.name) { $pull.name } elseif ($pull.item_name) { $pull.item_name } else { "Unknown" }

            $formattedData.$bannerName += @{
                id      = $pull.id
                name    = $itemName
                rarity  = $pull.rank_type.ToString()
                date    = $pull.time
                pityHit = "-"
            }
            $endId = $pull.id
        }
        Write-Host "  Fetched page (Last ID: $endId)"
        Start-Sleep -Milliseconds 300
        
    } while ($pulls.Count -gt 0)
}

# Wrap the payload in an object containing the UID
$finalPayload = @{
    uid = $accountUid
    event = $formattedData.event
    standard = $formattedData.standard
}

# 5. COPY JSON TO CLIPBOARD
$json = $finalPayload | ConvertTo-Json -Depth 5
Set-Clipboard -Value $json

Write-Host "`nExport complete for UID: $accountUid! JSON copied to clipboard." -ForegroundColor Green
Write-Host "On the website, click 'Auto Import' -> 'Paste from Clipboard'." -ForegroundColor Yellow