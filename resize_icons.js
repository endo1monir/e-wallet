const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const base = path.join(__dirname, 'android', 'app', 'src', 'main', 'res');
const sizes = [
  { folder: 'mipmap-mdpi', size: 48 },
  { folder: 'mipmap-hdpi', size: 72 },
  { folder: 'mipmap-xhdpi', size: 96 },
  { folder: 'mipmap-xxhdpi', size: 144 },
  { folder: 'mipmap-xxxhdpi', size: 192 },
];

async function resizeIcons() {
  const input = path.join(__dirname, 'app_icon.png');
  for (const { folder, size } of sizes) {
    const destPath = path.join(base, folder, 'ic_launcher.png');
    await sharp(input)
      .resize(size, size)
      .png()
      .toFile(destPath);
    console.log(`Created ${folder} (${size}x${size})`);
  }
  console.log('All icons created successfully');
}

resizeIcons().catch(console.error);
