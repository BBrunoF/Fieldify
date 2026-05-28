Add-Type -AssemblyName System.Drawing

$src = "assets\icon\icon-original.png"
$dst = "assets\icon\icon.png"

$bmp = New-Object System.Drawing.Bitmap (Resolve-Path $src).Path
$w = $bmp.Width
$h = $bmp.Height
Write-Host "Size: ${w}x${h}"

# Lock bits as 32bpp ARGB
$rect = New-Object System.Drawing.Rectangle 0, 0, $w, $h
$data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $data.Stride
$bytes = New-Object byte[] ($stride * $h)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)

# Report corner pixel (BGRA order in memory)
$cb = $bytes[0]; $cg = $bytes[1]; $cr = $bytes[2]
Write-Host "Top-left pixel RGB: $cr,$cg,$cb"

# near-white test
$thr = 235
function IsBg([int]$idx) {
    return ($bytes[$idx+0] -ge $thr) -and ($bytes[$idx+1] -ge $thr) -and ($bytes[$idx+2] -ge $thr)
}

$visited = New-Object 'bool[]' ($w * $h)
$stack = New-Object System.Collections.Generic.Stack[int]
foreach ($c in @(0, ($w-1), ($w*($h-1)), ($w*$h-1))) { $stack.Push($c) }

$cleared = 0
while ($stack.Count -gt 0) {
    $p = $stack.Pop()
    if ($visited[$p]) { continue }
    $visited[$p] = $true
    $x = $p % $w
    $y = [int]($p / $w)
    $idx = $y * $stride + $x * 4
    if (-not (IsBg $idx)) { continue }
    # set alpha 0
    $bytes[$idx+3] = 0
    $cleared++
    if ($x -gt 0)      { $n = $p - 1;  if (-not $visited[$n]) { $stack.Push($n) } }
    if ($x -lt $w-1)   { $n = $p + 1;  if (-not $visited[$n]) { $stack.Push($n) } }
    if ($y -gt 0)      { $n = $p - $w; if (-not $visited[$n]) { $stack.Push($n) } }
    if ($y -lt $h-1)   { $n = $p + $w; if (-not $visited[$n]) { $stack.Push($n) } }
}
Write-Host "Cleared $cleared background pixels"

[System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $data.Scan0, $bytes.Length)
$bmp.UnlockBits($data)
$bmp.Save((Join-Path (Get-Location) $dst), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host "Saved $dst"
