Add-Type -AssemblyName System.Drawing

# Adaptive foreground: scale the (transparent-corner) icon down on a transparent
# canvas so the mark sits inside the adaptive "safe zone" (inner ~66%). The green
# square blends into the matching green background, so only the mark shows.
$src = (Resolve-Path "assets\icon\icon.png").Path
$dst = Join-Path (Get-Location) "assets\icon\icon_foreground.png"

$icon = New-Object System.Drawing.Bitmap $src
$size = 1024
$fg = New-Object System.Drawing.Bitmap ($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($fg)
$g.Clear([System.Drawing.Color]::Transparent)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

$scale = 0.78
$nw = [int]($size * $scale); $nh = [int]($size * $scale)
$ox = [int](($size - $nw)/2); $oy = [int](($size - $nh)/2)
$g.DrawImage($icon, $ox, $oy, $nw, $nh)
$g.Dispose()
$fg.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
$icon.Dispose(); $fg.Dispose()
Write-Host "Saved $dst (icon scaled $scale, mark inside safe zone)"
