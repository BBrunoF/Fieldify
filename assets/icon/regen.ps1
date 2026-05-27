Add-Type -AssemblyName System.Drawing

# Regenerate all icon assets from source.png (flat green, full-bleed white mark).
$src = (Resolve-Path "assets\icon\source.png").Path
$bmp = New-Object System.Drawing.Bitmap $src
$w = $bmp.Width; $h = $bmp.Height
$rect = New-Object System.Drawing.Rectangle 0, 0, $w, $h
$data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $data.Stride
$sb = New-Object byte[] ($stride * $h)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $sb, 0, $sb.Length)
$bmp.UnlockBits($data)

# sample background green (avg of 4 corners)
$x2 = $w - 3
$y2 = $h - 3
$corners = @( @(2,2), @(2,$y2), @($x2,2), @($x2,$y2) )
$sr=0;$sg=0;$sbl=0
foreach ($pt in $corners) {
  $cx = [int]$pt[0]; $cy = [int]$pt[1]
  $i = $cy*$stride + $cx*4
  $sbl += $sb[$i]; $sg += $sb[$i+1]; $sr += $sb[$i+2]
}
$bgR=[int]($sr/4); $bgG=[int]($sg/4); $bgB=[int]($sbl/4)
$hex = "#{0:X2}{1:X2}{2:X2}" -f $bgR,$bgG,$bgB
$gLuma = 0.299*$bgR + 0.587*$bgG + 0.114*$bgB
$range = 255.0 - $gLuma
Write-Host "BG green: $hex  luma=$([math]::Round($gLuma,1))"

# --- mark.png : white mark on transparent (whiteness mask) ---
$mark = New-Object System.Drawing.Bitmap ($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$md = $mark.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$mb = New-Object byte[] ($md.Stride * $h)
for ($i = 0; $i -lt $sb.Length; $i += 4) {
    $luma = 0.299*$sb[$i+2] + 0.587*$sb[$i+1] + 0.114*$sb[$i]
    $t = ($luma - $gLuma) / $range
    # floor: kill faint background leakage, then rescale so the mark stays fully opaque
    if ($t -lt 0.22) { $t = 0 } else { $t = ($t - 0.22) / 0.78 }
    if ($t -gt 1) { $t = 1 }
    $mb[$i]=255; $mb[$i+1]=255; $mb[$i+2]=255
    $mb[$i+3] = [byte][int]([math]::Round($t*255))
}
[System.Runtime.InteropServices.Marshal]::Copy($mb, 0, $md.Scan0, $mb.Length)
$mark.UnlockBits($md)
$mark.Save((Join-Path (Get-Location) "assets\icon\mark.png"), [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host "Saved mark.png"

# --- icon_foreground.png : mark scaled into adaptive safe zone, on transparent ---
$fg = New-Object System.Drawing.Bitmap ($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($fg)
$g.Clear([System.Drawing.Color]::Transparent)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$scale = 0.66
$nw=[int]($w*$scale); $nh=[int]($h*$scale); $ox=[int](($w-$nw)/2); $oy=[int](($h-$nh)/2)
$g.DrawImage($mark, $ox, $oy, $nw, $nh)
$g.Dispose()
$fg.Save((Join-Path (Get-Location) "assets\icon\icon_foreground.png"), [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host "Saved icon_foreground.png (mark scaled $scale)"

# --- icon.png : rounded-corner full-bleed green tile for the legacy launcher icon ---
$icon = New-Object System.Drawing.Bitmap ($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gi = [System.Drawing.Graphics]::FromImage($icon)
$gi.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$gi.Clear([System.Drawing.Color]::Transparent)
$rad = [int]($w * 0.22)
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$d = $rad*2
$path.AddArc(0,0,$d,$d,180,90)
$path.AddArc($w-$d,0,$d,$d,270,90)
$path.AddArc($w-$d,$h-$d,$d,$d,0,90)
$path.AddArc(0,$h-$d,$d,$d,90,90)
$path.CloseFigure()
$gi.SetClip($path)
$gi.DrawImage($bmp, 0, 0, $w, $h)
$gi.Dispose()
$icon.Save((Join-Path (Get-Location) "assets\icon\icon.png"), [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host "Saved icon.png (rounded)"

# --- previews ---
# adaptive preview: foreground over green bg
$prev = New-Object System.Drawing.Bitmap ($w,$h)
$pg = [System.Drawing.Graphics]::FromImage($prev)
$pg.Clear([System.Drawing.Color]::FromArgb(255,$bgR,$bgG,$bgB))
$pg.DrawImage($fg,0,0,$w,$h)
$pg.Dispose()
$prev.Save((Join-Path (Get-Location) "assets\icon\_preview_adaptive.png"), [System.Drawing.Imaging.ImageFormat]::Png)

$bmp.Dispose(); $mark.Dispose(); $fg.Dispose(); $icon.Dispose(); $prev.Dispose()
Write-Host "BG_HEX=$hex"
