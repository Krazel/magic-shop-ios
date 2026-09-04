# Reproducible iOS asset packaging. Artwork is the unchanged ImageGen source;
# this step only conforms its pixel dimensions and opaque encoding to AppIcon.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root 'design/assets/complete-game/AppIcon-source.png'
$target = Join-Path $root 'design/assets/complete-game/AppIcon.png'
$original = [Drawing.Bitmap]::new($source)
$output = [Drawing.Bitmap]::new(1024,1024,[Drawing.Imaging.PixelFormat]::Format24bppRgb)
$graphics = [Drawing.Graphics]::FromImage($output)
try {
    if ($original.Width -ne $original.Height) { throw 'AppIcon source must be square; do not crop artwork.' }
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.CompositingQuality = [Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($original, [Drawing.Rectangle]::new(0,0,1024,1024))
    $output.Save($target,[Drawing.Imaging.ImageFormat]::Png)
} finally { $graphics.Dispose(); $output.Dispose(); $original.Dispose() }
$set = Join-Path $root 'MagicShop/Resources/Assets.xcassets/AppIcon.appiconset'
New-Item -ItemType Directory -Force -Path $set | Out-Null
Copy-Item -LiteralPath $target -Destination (Join-Path $set 'AppIcon.png')
$json = '{"images":[{"filename":"AppIcon.png","idiom":"universal","platform":"ios","size":"1024x1024"}],"info":{"author":"xcode","version":1}}'
[IO.File]::WriteAllText((Join-Path $set 'Contents.json'),$json,[Text.UTF8Encoding]::new($false))
Get-FileHash -Algorithm SHA256 -LiteralPath $target