param()
Add-Type -AssemblyName System.Drawing
$sourcePath = "D:\xampp\htdocs\e-wallet\app_icon.png"
$src = [System.Drawing.Image]::FromFile($sourcePath)
$base = "D:\xampp\htdocs\e-wallet\android\app\src\main\res"
$folders = @("mipmap-mdpi", "mipmap-hdpi", "mipmap-xhdpi", "mipmap-xxhdpi", "mipmap-xxxhdpi")
$sizes = @(48, 72, 96, 144, 192)
for ($i = 0; $i -lt $folders.Length; $i++) {
    $folder = $folders[$i]
    $size = $sizes[$i]
    $destPath = "$base\$folder\ic_launcher.png"
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($src, 0, 0, $size, $size)
    $bmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    $g.Dispose()
    Write-Host "Created $folder ($size x $size)"
}
$src.Dispose()
Write-Host "All icons created successfully"
