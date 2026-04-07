const sharp = require('sharp');
const path = require('path');

async function createWalletIcon() {
  const size = 1024;
  const svg = `
    <svg width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg">
      <rect width="${size}" height="${size}" fill="#2E7D32" rx="180"/>
      <rect x="180" y="320" width="664" height="440" rx="40" fill="none" stroke="white" stroke-width="28"/>
      <line x1="180" y1="420" x2="844" y2="420" stroke="white" stroke-width="28"/>
      <circle cx="700" cy="540" r="60" fill="white"/>
      <text x="512" y="680" font-family="Arial" font-size="100" font-weight="bold" fill="white" text-anchor="middle">E-Wallet</text>
    </svg>
  `;

  const outputPath = path.join(__dirname, 'app_icon.png');
  await sharp(Buffer.from(svg))
    .resize(size, size)
    .png()
    .toFile(outputPath);
  console.log('App icon created: ' + outputPath);
}

createWalletIcon().catch(console.error);
