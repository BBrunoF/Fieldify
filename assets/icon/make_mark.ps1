Add-Type -AssemblyName System.Drawing

# Extract the white mark from icon.png onto transparent (alpha = whiteness).
# Output is a white silhouette meant to be tinted in-app via BlendMode.srcIn.
$src = (Resolve-Path "assets\icon\icon.png").Path
$dst = Join-Path (Get-Location) "assets\icon\mark.png"

$bmp = New-Object System.Drawing.Bitmap $src
$w = $bmp.Width; $h = $bmp.Height
$rect = New-Object System.Drawing.Rectangle 0, 0, $w, $h
$data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $data.Stride
$src_b = New-Object byte[] ($stride * $h)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $src_b, 0, $src_b.Length)
$bmp.UnlockBits($data)

# green reference luma (#1D4707-ish square)
$gLuma = 0.299*29 + 0.587*71 + 0.114*7
$range = 255.0 - $gLuma

$out = New-Object System.Drawing.Bitmap ($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$od = $out.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$ob = New-Object byte[] ($od.Stride * $h)
for ($i = 0; $i -lt $src_b.Length; $i += 4) {
    $b = $src_b[$i]; $g = $src_b[$i+1]; $r = $src_b[$i+2]; $a = $src_b[$i+3]
    $luma = 0.299*$r + 0.587*$g + 0.114*$b
    $t = ($luma - $gLuma) / $range
    if ($t -lt 0) { $t = 0 } elseif ($t -gt 1) { $t = 1 }
    # zero out where original was transparent (corners)
    if ($a -eq 0) { $t = 0 }
    $ob[$i] = 255; $ob[$i+1] = 255; $ob[$i+2] = 255
    $ob[$i+3] = [byte][int]([math]::Round($t * 255))
}
[System.Runtime.InteropServices.Marshal]::Copy($ob, 0, $od.Scan0, $ob.Length)
$out.UnlockBits($od)
$out.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)

# Preview: tint g800 (#27500A) over g100 (#EAF3DE) rounded square
$prev = New-Object System.Drawing.Bitmap ($w, $h)
$gfx = [System.Drawing.Graphics]::FromImage($prev)
$gfx.Clear([System.Drawing.Color]::FromArgb(255,234,243,222))
$tb = $out.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$tbytes = New-Object byte[] ($tb.Stride * $h)
[System.Runtime.InteropServices.Marshal]::Copy($tb.Scan0, $tbytes, 0, $tbytes.Length)
$out.UnlockBits($tb)
for ($i=0; $i -lt $tbytes.Length; $i+=4) {
    $al = $tbytes[$i+3]
    if ($al -gt 0) {
        $fa = $al/255.0
        $px = $prev.GetPixel(($i/4)%$w, [int](($i/4)/$w))
        $nr = [int](10*$fa + $px.R*(1-$fa))   # 0x27=39? use 39,80,10
        $nr = [int](39*$fa + 234*(1-$fa))
        $ng = [int](80*$fa + 243*(1-$fa))
        $nb = [int](10*$fa + 222*(1-$fa))
        $prev.SetPixel(($i/4)%$w, [int](($i/4)/$w), [System.Drawing.Color]::FromArgb(255,$nr,$ng,$nb))
    }
}
$gfx.Dispose()
$prev.Save((Join-Path (Get-Location) "assets\icon\_preview_mark.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose(); $out.Dispose(); $prev.Dispose()
Write-Host "Saved mark.png + _preview_mark.png"
