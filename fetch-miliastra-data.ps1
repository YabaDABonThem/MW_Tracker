# 1. PASTE YOUR FULL URL HERE (Keep it wrapped in quotes)
$baseUrl = "https://public-operation-hk4e-sg.hoyoverse.com/gacha_info/api/getBeyondGachaLog?win_mode=fullscreen&no_joypad_close=1&authkey_ver=1&sign_type=2&auth_appid=webview_gacha&gacha_id=978b4750f22e97ae7fe26a85c4a398c6a2ff&timestamp=1786492173&lang=en-us&device_type=pc&game_version=OSRELWin7.0.0_R47805902_S47829085_D47829085&region=os_usa&authkey=sdbLWukNEx0fjQTfvY96hnb3hPXpJDkfNG8%2Bu3P8CAftN91YpAMcrarjRhgB5re4LRX2GObMK2CxTYUxZChppB4rOE9np%2BszKl56U8LMMx7Ub5HHKhDdiiHtMtk%2BOZZv3ROtTPSYuCDtTwXDMbxnx2gMSnRlPbQLE2d5LCnu26DFqfhpogbmxGhiIQKz9fNVRHJNfujfuLblb2ITsPt2l0HHMaALuqnmHfC%2BzJUhEAVJJG9Sjt%2B%2BSHnL1u2wVSsi37gdsdbftaHSI0fyPpbeavlb0qvyaDl2nvz%2FMNZf0Ww3G%2FBaTAZIaReE8stDV%2FV72Q%2FVCWFE18YXjnbU8deU%2FXdVsSVM3XizjBOrmMsl6zTdggb%2FCmzQPvc1%2B7RMSGEyuG9cU0MZ6%2FfQa%2FxCwshYLswUuTEX4JS7AgKAPUa%2Bee2pOa6OgTehvghR41XJNcryceJVc2MYnFoOMEBRGeuAUV5PdXEGahfxD8ItuHVk%2F0JRrK92SutYNt5wQE5055pzRk3X0%2FBU%2B%2BlIsssYIHhDYAAs4Xwb8I%2BLKwsySLfwyButEbtaTxuC%2FARCpy0Y4WAe8oMcODZd3DBuxig2Of3JptpISsOdR4V2KQjxdGZzILxpoHmiRl62UCrk%2BeNwqUkBujWL4Cz2THw7RYJh9v89VWJgmDfi5Ll0S2B5N5tiQ%2FkoN5C5kBniQkJqpCXq14%2FQHalWHbCiTSWj%2FYBTKdPB4%2BXeJ1V3Lb2RacIu0Ktd8xh7s9DvBnZ7zX%2FAtm3IZj3VY6%2Bqop7WSkbWVx0mnSbisQDTadIupdtJlRA%2FIchEx%2FCz1emCKLGKh5gxIPfyeGh3vmQrAY%2F5NZpSm8hg1%2FnAF5zdoZ%2FrV%2BlYVatRfzpuWzYnKbC6k0LaMHoMR1UDgRhWI6Gu5mSil7GtBtPyLVKTW53KKd1k0HB1UjiIjrWcEggFFEeubwnXvwZdzpUq5nIycX2GtDoZEmgw4XEmZhsp2mGwTppTIuW1U%2FZ5Gm%2BYUoQrrp6ii6yWwznFtLCFV4R0fa1itagJkXOi%2BoBupiILC%2Ba1Whq0juV3PK08wcOJNZFE5IvSfKQetKQd4Xuroavs%2BVy1NUVYQ64FdV02ikpJ%2Fsx6NmOXiNYGHE7GVuscibg%2Bl%2BklWgUGAfjX8eZXwaSLsKRB0g%2F27vOO%2BOiCXxuiAuh7r%2BYmSiDyxTf20EK4tH2IXt3lS9%2FjsXEE84xrfAz7mWw9bIDQ6CR4fbxuq%2FwHboKtG5sOjFTYGwNM3LD9HPVyEMCjz1P9AXnFkm1amHyKr9TrzR%2FDlyOWNusU0kqDjWrGZpu8VQAE2ZHNpTdeXDe%2FJFFff8HbIbhobG4c8vQWnhfXRLXDNBvH9RMVDtrFpg%3D%3D&game_biz=hk4e_global"

# 2. DEFINE BANNER IDs
# Note: 301 and 200 are the Genshin defaults for Event and Standard. 
# If Miliastra uses different internal IDs for Odes, you will need to update these two numbers.
# 2. DEFINE BANNER IDs (Updated for Miliastra Wonderland)
$bannerTypes = @{
    "event"    = "2000" 
    "standard" = "1000"
}

$formattedData = @{
    event    = @()
    standard = @()
}

# 3. PAGINATION LOOP
foreach ($banner in $bannerTypes.GetEnumerator()) {
    $bannerName = $banner.Name
    $gachaType = $banner.Value
    $endId = "0"
    
    Write-Host "Fetching $bannerName Odes..."
    
    do {
        $requestUrl = "$baseUrl&gacha_type=$gachaType&size=20&end_id=$endId"
        
        try {
            $response = Invoke-RestMethod -Uri $requestUrl -Method Get
        }
        catch {
            Write-Host "Network error. The server may be blocking the request." -ForegroundColor Red
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
        
        # --- DEBUG: Print the raw JSON of the very first pull to find the missing name key ---
        if ($endId -eq "0" -and $pulls.Count -gt 0 -and $bannerName -eq "standard") {
            Write-Host "`n--- RAW API DATA (Checking for name key) ---" -ForegroundColor Yellow
            $pulls[0] | ConvertTo-Json -Depth 2 | Write-Host
            Write-Host "----------------------------------------------`n" -ForegroundColor Yellow
        }
        
        # 4. FORMAT DATA FOR FRONTEND
        foreach ($pull in $pulls) {
            
            # Check multiple common keys for the name. If all fail, fallback to ID.
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
        
        Write-Host "Fetched page (Last item ID: $endId)"
        Start-Sleep -Milliseconds 300 
        
    } while ($pulls.Count -gt 0) # <-- FIX: Now loops as long as the page isn't empty
}

# 5. EXPORT
$exportPath = "$PWD\miliastra_wishes.json"
$formattedData | ConvertTo-Json -Depth 4 | Out-File $exportPath -Encoding utf8
Write-Host "`nExport complete! Data saved to $exportPath" -ForegroundColor Green
Write-Host "You can now click 'Import JSON' on your tracker website."