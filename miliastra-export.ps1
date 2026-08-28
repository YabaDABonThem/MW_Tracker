Add-Type -AssemblyName System.Web

# 1. PASTE THE EXACT PATH TO YOUR output_log.txt HERE:
$path = "C:\Users\Allen.ALPHA\AppData\LocalLow\miHoYo\Genshin Impact\output_log.txt"

if (-Not [System.IO.File]::Exists($path)) {
    Write-Host "Cannot find the log file at $path! Check your path." -ForegroundColor Red
    return
}

# 2. Read the log to find where the custom launcher installed GenshinImpact_Data
$logs = Get-Content -Path $path
$m = $logs -match "(?m).:/.+(GenshinImpact_Data|YuanShen_Data)"
$m[0] -match "(.:/.+(GenshinImpact_Data|YuanShen_Data))" >$null

if ($matches.Length -eq 0) {
    Write-Host "Cannot find the game data folder in the log!" -ForegroundColor Red
    return
}

$gamedir = $matches[1]
Write-Host "Found Game Directory: $gamedir"

# 3. Locate the newest web cache file
$webcachePath = Resolve-Path "$gamedir/webCaches"
$cacheVerPath = Get-Item (Get-ChildItem -Path $webcachePath | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$cachefile = Resolve-Path "$cacheVerPath/Cache/Cache_Data/data_2"
$tmpfile = "$env:TEMP/ch_data_2"

Copy-Item $cachefile -Destination $tmpfile

$content = Get-Content -Encoding UTF8 -Raw $tmpfile
$splitted = $content -split "1/0/"

# 4. Search for any URL containing a secure authkey
$found = $splitted -match "authkey="
$linkFound = $false
$wishHistoryUrl = ""

# Loop backwards to get the MOST RECENTLY generated link
for ($i = $found.Length - 1; $i -ge 0; $i -= 1) {
    # This regex grabs the full URL structure used by HoYoverse
    if ($found[$i] -match "(https.+?game_biz=(hk4e_global|hk4e_cn))") {
        $wishHistoryUrl = $matches[0]
        $linkFound = $true
        break
    }
}

Remove-Item $tmpfile

if (-Not $linkFound) {
    Write-Host "Cannot find the URL! Make sure to open the Miliastra Wonderland wish history in-game first!" -ForegroundColor Red
    return
}

Write-Host "`nFound Miliastra URL:"
Write-Host $wishHistoryUrl
Set-Clipboard -Value $wishHistoryUrl
Write-Host "`nLink copied to clipboard! You can now use this URL to fetch your Miliastra data." -ForegroundColor Green