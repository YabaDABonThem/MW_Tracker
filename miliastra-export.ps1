Add-Type -AssemblyName System.Web

# ============================================================
# Miliastra Wonderland Ode Exporter (All-in-One)
# ============================================================

# 1. AUTO-DISCOVER the output_log.txt path
$possiblePaths = @(
    "$env:USERPROFILE\AppData\LocalLow\miHoYo\Genshin Impact\output_log.txt",
    "$env:USERPROFILE\AppData\LocalLow\miHoYo\YuanShen\output_log.txt"
)

$logPath = $null
foreach ($p in $possiblePaths) {
    if ([System.IO.File]::Exists($p)) {
        $logPath = $p
        break
    }
}

if (-not $logPath) {
    Write-Host "Cannot find Genshin Impact output_log.txt!" -ForegroundColor Red
    Write-Host "Make sure you opened the Miliastra Wonderland wish history in-game first." -ForegroundColor Yellow
    return
}

Write-Host "Found log: $logPath" -ForegroundColor Cyan

# 2. FIND the game data directory from the log
$logs = Get-Content -Path $logPath
$m = $logs -match "(?m).:/.+(GenshinImpact_Data|YuanShen_Data)"
$m[0] -match "(.:/.+(GenshinImpact_Data|YuanShen_Data))" >$null

if ($matches.Length -eq 0) {
    Write-Host "Cannot find game data directory in log!" -ForegroundColor Red
    return
}

$gamedir = $matches[1]

# 3. EXTRACT the auth URL from web cache
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
    Write-Host "Cannot find auth URL! Open Miliastra Ode history in-game." -ForegroundColor Red
    return
}

Write-Host "Auth URL extracted successfully!" -ForegroundColor Green

# 4. FETCH ALL ODE DATA from the API
$bannerTypes = @{
    "event"    = "2000"
    "standard" = "1000"
}

$formattedData = @{
    event    = @()
    standard = @()
}

foreach ($banner in $bannerTypes.GetEnumerator()) {
    $bannerName = $banner.Name
    $gachaType = $banner.Value
    $endId = "0"
    
    Write-Host "Fetching $bannerName Odes..." -ForegroundColor Cyan
    
    do {
        $requestUrl = "$baseUrl&gacha_type=$gachaType&size=20&end_id=$endId"
        
        try {
            $response = Invoke-RestMethod -Uri $requestUrl -Method Get
        }
        catch {
            Write-Host "Network error." -ForegroundColor Red
            exit
        }
        
        if ($response.retcode -ne 0) {
            Write-Host "API Error: $($response.message). Authkey may be expired." -ForegroundColor Red
            break
        }
        
        $pulls = $response.data.list
        if ($pulls -eq $null -or $pulls.Count -eq 0) {
            break
        }
        
        foreach ($pull in $pulls) {
            $itemName = if ($pull.name) { $pull.name } 
            elseif ($pull.item_name) { $pull.item_name } 
            elseif ($pull.itemName) { $pull.itemName } 
            else { "Unknown (ID: $($pull.item_id))" }

            $formattedPull = @{
                id      = $pull.id
                name    = $itemName
                rarity  = $pull.rank_type.ToString()
                date    = $pull.time
                pityHit = "-"
            }
            
            if ($bannerName -eq "event") {
                $formattedData.event += $formattedPull
            }
            else {
                $formattedData.standard += $formattedPull
            }
            
            $endId = $pull.id
        }
        
        Write-Host "  Fetched page (Last ID: $endId)"
        Start-Sleep -Milliseconds 300
        
    } while ($pulls.Count -gt 0)
}

# 5. COPY JSON TO CLIPBOARD
$json = $formattedData | ConvertTo-Json -Depth 4
Set-Clipboard -Value $json

Write-Host "`nExport complete! JSON copied to clipboard." -ForegroundColor Green
Write-Host "On the website, click '⚡ Auto Import' -> '📋 Paste from Clipboard'." -ForegroundColor Yellow