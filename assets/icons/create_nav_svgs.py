import os

icons_dir = r"c:\Users\SAMeer\Documents\GitHub\MobileBanking\assets\icons"

# 1. ic_nav_transfers
transfers_light = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="38.00 -47.00 436.00 564.00">
  <g transform="translate(0, 491.00) scale(1, -1)">
    <!-- Base Color: Navy #090078 -->
    <path fill="#090078" d="M256 427V491L171 405L256 320V384C327 384 384 327 384 256C384 234 379 214 369 196L400 165C417 191 427 223 427 256C427 350 350 427 256 427Z"/>
    <!-- Accent Color: Green #13a438 -->
    <path fill="#13a438" d="M256 128C185 128 128 185 128 256C128 278 133 298 143 316L112 347C95 321 85 289 85 256C85 162 162 85 256 85V21L341 107L256 192V128Z"/>
  </g>
</svg>"""

transfers_dark = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="38.00 -47.00 436.00 564.00">
  <g transform="translate(0, 491.00) scale(1, -1)">
    <!-- Base Color: Light Grey #ECEFF4 -->
    <path fill="#ECEFF4" d="M256 427V491L171 405L256 320V384C327 384 384 327 384 256C384 234 379 214 369 196L400 165C417 191 427 223 427 256C427 350 350 427 256 427Z"/>
    <!-- Accent Color: Glowing Green #6ECA09 -->
    <path fill="#6ECA09" d="M256 128C185 128 128 185 128 256C128 278 133 298 143 316L112 347C95 321 85 289 85 256C85 162 162 85 256 85V21L341 107L256 192V128Z"/>
  </g>
</svg>"""

# 2. ic_nav_menu
menu_light = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="25.60 -38.40 460.80 332.80">
  <g transform="translate(0, 384.00) scale(1, -1)">
    <!-- Top & Bottom Bars: Navy #090078 -->
    <path fill="#090078" d="M64 128H448V171H64V128ZM64 384V341H448V384H64Z"/>
    <!-- Middle Accent Bar: Green #13a438 -->
    <path fill="#13a438" d="M64 235H448V277H64V235Z"/>
  </g>
</svg>"""

menu_dark = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="25.60 -38.40 460.80 332.80">
  <g transform="translate(0, 384.00) scale(1, -1)">
    <!-- Top & Bottom Bars: Light Grey #ECEFF4 -->
    <path fill="#ECEFF4" d="M64 128H448V171H64V128ZM64 384V341H448V384H64Z"/>
    <!-- Middle Accent Bar: Glowing Green #6ECA09 -->
    <path fill="#6ECA09" d="M64 235H448V277H64V235Z"/>
  </g>
</svg>"""

# 3. ic_nav_home
home_light = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0.40 -42.60 511.20 448.20">
  <g transform="translate(0, 448.00) scale(1, -1)">
    <!-- Base Color: Navy #090078 -->
    <path fill="#090078" d="M107 85H213V213H299V85H405V256H469L256 448L43 256H107V85Z"/>
    <!-- Accent Door: Green #13a438 -->
    <path fill="#13a438" d="M213 85h86v128h-86z" fill-opacity="0.85"/>
  </g>
</svg>"""

home_dark = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0.40 -42.60 511.20 448.20">
  <g transform="translate(0, 448.00) scale(1, -1)">
    <!-- Base Color: Light Grey #ECEFF4 -->
    <path fill="#ECEFF4" d="M107 85H213V213H299V85H405V256H469L256 448L43 256H107V85Z"/>
    <!-- Accent Door: Glowing Green #6ECA09 -->
    <path fill="#6ECA09" d="M213 85h86v128h-86z" fill-opacity="0.85"/>
  </g>
</svg>"""

# 4. ic_nav_payments
payments_light = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0.40 -42.60 511.20 427.20">
  <g transform="translate(0, 427.00) scale(1, -1)">
    <!-- Base Wallet Shape: Navy #090078 -->
    <path fill="#090078" d="M427 427H85C62 427 43 408 43 384V128C43 104 62 85 85 85H427C450 85 469 104 469 128V384C469 408 450 427 427 427Z"/>
    <!-- Upper Band: Green #13a438 (or transparent cutout/accent) -->
    <path fill="#13a438" d="M427 341H85V384H427V341Z" fill-opacity="0.85"/>
    <!-- Inner Pocket Accent Color: Green #13a438 (Transparent) -->
    <path fill="#13a438" d="M427 128H85V256H427V128Z" fill-opacity="0.25"/>
  </g>
</svg>"""

payments_dark = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0.40 -42.60 511.20 427.20">
  <g transform="translate(0, 427.00) scale(1, -1)">
    <!-- Base Wallet Shape: Light Grey #ECEFF4 -->
    <path fill="#ECEFF4" d="M427 427H85C62 427 43 408 43 384V128C43 104 62 85 85 85H427C450 85 469 104 469 128V384C469 408 450 427 427 427Z"/>
    <!-- Upper Band: Glowing Green #6ECA09 -->
    <path fill="#6ECA09" d="M427 341H85V384H427V341Z" fill-opacity="0.85"/>
    <!-- Inner Pocket Accent Color: Glowing Green #6ECA09 (Transparent) -->
    <path fill="#2c2f88" d="M427 128H85V256H427V128Z" fill-opacity="0.5"/>
  </g>
</svg>"""

# Write files
files = {
    "ic_nav_transfers_light.svg": transfers_light,
    "ic_nav_transfers_dark.svg": transfers_dark,
    "ic_nav_menu_light.svg": menu_light,
    "ic_nav_menu_dark.svg": menu_dark,
    "ic_nav_home_light.svg": home_light,
    "ic_nav_home_dark.svg": home_dark,
    "ic_nav_payments_light.svg": payments_light,
    "ic_nav_payments_dark.svg": payments_dark
}

for name, content in files.items():
    path = os.path.join(icons_dir, name)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content.strip())
    print(f"Created: {path}")

print("All nav SVGs generated!")
