# Watches Flutter terminal for Dio ERROR blocks and appends them to api_failure_log.md
$ErrorActionPreference = 'SilentlyContinue'
$terminal = "C:\Users\coop\.cursor\projects\d-commercepal-HudHud-Delivery-hudhud-delivery\terminals\1.txt"
$outFile = "d:\commercepal\HudHud-Delivery\hudhud_delivery\docs\api_failure_log.md"
$seenFile = "d:\commercepal\HudHud-Delivery\hudhud_delivery\docs\.api_failure_seen.txt"

if (-not (Test-Path $seenFile)) { '' | Set-Content $seenFile -Encoding utf8 }

Write-Output "API_FAILURE_WATCHER_READY"

function Get-Seen {
  @(Get-Content $seenFile | Where-Object { $_ -and $_.Trim() })
}

function Add-Seen([string]$fp) {
  Add-Content $seenFile -Value $fp -Encoding utf8
}

function Fingerprint([string]$block) {
  $h = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($block)
  ($h.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}

while ($true) {
  Start-Sleep -Seconds 2
  if (-not (Test-Path $terminal)) { continue }

  $raw = [IO.File]::ReadAllText($terminal)
  if ([string]::IsNullOrWhiteSpace($raw)) { continue }

  # Strip Android log prefixes so matching is reliable
  $text = [regex]::Replace($raw, '(?m)^[A-Z]/[^\n]*?:\s*', '')

  # ASCII-safe patterns (emoji often mangled in terminal captures)
  $pattern = '(?s)REQUEST\[[^\]]+\] => PATH: [^\r\n]+.*?ERROR\[(\d+)\] => PATH: ([^\r\n]+).*?Status Code: (\d+).*?Request Data: ([^\r\n]*)'
  $matches = [regex]::Matches($text, $pattern)
  if ($matches.Count -eq 0) {
    $pattern = '(?s)ERROR\[(\d+)\] => PATH: ([^\r\n]+).*?Status Code: (\d+).*?Response Data: ([^\r\n]*)'
    $matches = [regex]::Matches($text, $pattern)
  }

  $seen = Get-Seen
  foreach ($m in $matches) {
    $block = $m.Value.Trim()
    if ($block.Length -lt 40) { continue }
    $fp = Fingerprint $block
    if ($seen -contains $fp) { continue }

    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $status = $m.Groups[1].Value
    $path = $m.Groups[2].Value
    $entry = @"

## Failure — $stamp

**ERROR[$status] => PATH: $path**

``````
$block
``````

---
"@
    Add-Content -Path $outFile -Value $entry -Encoding utf8
    Add-Seen $fp
    $seen += $fp
    Write-Output "CAPTURED_FAILURE: ERROR[$status] $path"
  }
}
