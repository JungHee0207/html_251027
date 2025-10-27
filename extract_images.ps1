$htmlPath = 'C:\web_0826_ljh\workspace\html_workspace\temp_museum.html'
if (-not (Test-Path $htmlPath)) { Write-Error "File not found: $htmlPath"; exit 1 }
$baseUri = 'https://adventure.lotteworld.com'
$content = Get-Content -Path $htmlPath -Raw

# regex helpers
[regex]$imgRe = '<img[^>]+?\s+src=(?:"([^"]+)"|''([^'']+)''|([^>\s]+))'
[regex]$assetRe = '<(?:link|script)[^>]+?\s+(?:href|src)=(?:"([^"]+)"|''([^'']+)''|([^>\s]+))'
[regex]$urlRe = 'url\(\s*(?:"([^"]+)"|''([^'']+)''|([^\)\s]+))\s*\)'

$imgs = $imgRe.Matches($content) | ForEach-Object {
    if ($_.Groups[1].Value) { $_.Groups[1].Value }
    elseif ($_.Groups[2].Value) { $_.Groups[2].Value }
    else { $_.Groups[3].Value }
} | Sort-Object -Unique

$assets = $assetRe.Matches($content) | ForEach-Object {
    if ($_.Groups[1].Value) { $_.Groups[1].Value }
    elseif ($_.Groups[2].Value) { $_.Groups[2].Value }
    else { $_.Groups[3].Value }
} | Sort-Object -Unique

$cssUrls = $urlRe.Matches($content) | ForEach-Object {
    if ($_.Groups[1].Value) { $_.Groups[1].Value }
    elseif ($_.Groups[2].Value) { $_.Groups[2].Value }
    else { $_.Groups[3].Value }
} | Sort-Object -Unique

Write-Output '--- IMG SRC (from HTML) ---'
$imgs | ForEach-Object { Write-Output $_ }

Write-Output '--- LINK/SCRIPT ASSETS (from HTML) ---'
$assets | ForEach-Object { Write-Output $_ }

Write-Output '--- CSS url(...) (inline/in-page) ---'
$cssUrls | ForEach-Object { Write-Output $_ }

# Download external CSS files (absolute or relative) and extract url(...) references
$cssLinks = $assets | Where-Object { $_ -match '\.css($|\?)' }
if ($cssLinks.Count -gt 0) {
    Write-Output '--- Scanning external CSS files ---'
    $seenCss = @{}
    foreach ($link in $cssLinks) {
        try {
            $resolved = if ($link -match '^https?://') { $link } else { (New-Object System.Uri((New-Object System.Uri($baseUri)), $link)).AbsoluteUri }
            if ($seenCss.ContainsKey($resolved)) { continue }
            $seenCss[$resolved] = $true
            $temp = [System.IO.Path]::GetTempFileName()
            Invoke-WebRequest -Uri $resolved -UseBasicParsing -Headers @{ 'User-Agent'='Mozilla/5.0' } -OutFile $temp -TimeoutSec 15
            $cssContent = Get-Content -Path $temp -Raw
            $found = $urlRe.Matches($cssContent) | ForEach-Object {
                if ($_.Groups[1].Value) { $_.Groups[1].Value }
                elseif ($_.Groups[2].Value) { $_.Groups[2].Value }
                else { $_.Groups[3].Value }
            } | Sort-Object -Unique
            if ($found.Count -gt 0) {
                Write-Output "CSS: $resolved"
                $found | ForEach-Object { Write-Output $_ }
            }
            Remove-Item $temp -ErrorAction SilentlyContinue
        } catch {
            Write-Warning "Failed to fetch CSS: $link -> $_"
        }
    }
} else {
    Write-Output 'No external CSS links detected.'
}

# Resolve and normalize relative URLs for output convenience
function Resolve-Url($url) {
    if ($url -match '^https?://') { return $url }
    try { return (New-Object System.Uri((New-Object System.Uri($baseUri)), $url)).AbsoluteUri } catch { return $url }
}

Write-Output '--- Normalized image URLs (HTML img + CSS refs) ---'
$all = @()
$imgs | ForEach-Object { $all += Resolve-Url $_ }
$cssUrls | ForEach-Object { $all += Resolve-Url $_ }
if ($seenCss) {
    $seenCss.Keys | ForEach-Object { } # no-op to avoid undefined variable warnings
}
$all | Sort-Object -Unique | ForEach-Object { Write-Output $_ }
