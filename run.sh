#!/bin/bash
set -e

echo "Generating .env file from environment variables..."

FCM_PROJECT_ID="${FCM_PROJECT_ID:-blood-f5990}"
FCM_PRIVATE_KEY_ID="${FCM_PRIVATE_KEY_ID:-79d0154416c328a467722005838eba0b53141c9c}"
FCM_CLIENT_EMAIL="${FCM_CLIENT_EMAIL:-firebase-adminsdk-fbsvc@blood-f5990.iam.gserviceaccount.com}"
FCM_CLIENT_ID="${FCM_CLIENT_ID:-101530494291222997393}"

if [ -z "$FCM_PRIVATE_KEY" ]; then
  FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDAgd6TWHtUN3hO
5msl08VnTs1ce4lJCi/xbE1BkYBrmHeFAbBj5cAo/TwFK3W33ceQs9kHNCRp9/+R
iTGZlmJ4M0Z73vql9vj2cUMNTqw7aVapbsDIoP1F2lljqUp3CRlNUPIgxHieFxEq
qL/tF7hmuAdkdTylRreF5BS1OyKmlXOIQkjf6UU6EuZKGk1+oACOy4k2JFjuxIPn
MTwUiIs11igURKzDt35oq5JIx5x5UdQCsbj5KmzVjLwD4Sy+8QSPimzIo+4t9bxX
KAUgWESAG3Rb7RdZHJY1jPKFlubUCu9khNdp/nKqBqKWHZLQBfQE9AAyuQFQ+ksA
r+sdfM0HAgMBAAECggEABHsBUyycB48YSGh/K0I34KT/jUd9dSsSMpbytV6i6TOD
P0qVcGhzMIEJrz/JCEkr0T0JBWyRQbt5QfSPfaOiZxR1Giz2aHvMZO/96jFf5izC
zO68Te8b9fmUWwggU4+X/H9bI1LEppP4MlCl0ZQxFohHTm9Bb2yrQ30rfjcCIh5j
W508TzZLdusH7LvckG40SKDVNYi8Lzmf/V/DBc9l9tWfViutWCooehNl94UbbQ4W
Bt1Sm/xuMMEAdA3+6r/86D0BrA8fseKcGP1q2kBmgRrECM1jpiu5lNFaaSWLgCcM
a289Fbzc7i8XR3G7mUQkQWfocgMdU52D9/nk93TqAQKBgQDj+Z5PQj3c9h/ZyZhZ
ytN0viqrcx5vWqf3zbH/pQsinS0Z6FLxPb9dHCjztL/GFcqWKATdyAR+6Pthv3ei
HvNio8+TubkjPg5cO/CIBCvPJUUQhyxvZXp2KFf7XWNH0yKtem+RrvLBLR7llfW0y
KJa+rKv/Qk3Fpp4luJU4zjANfwKBgQDYLBRS09V5vX0W1c1e15YMdV0zhLX1q03o
6TP7DYRiLf0N+4zkDalAz+NImx+Cx/lMPXg+xsq2AUpvy9VZt206AOtwTMu4dEbZ
DyIDsQrYBXP/ngFHOideYb93ZhA/24FCfiqgjE6Z5MJ5wwlgmSgEFACIOarlgEK0
eMxwvYeUeQKBgHfPFZ29yFk5mB+SzNhTubFex3n3NAV9dUzL80HQ8Pst8yfsarqR
ouJCDFuXoDlv9lnXikcr+QDhXEtQnoS7Fh9knemYV/eGxnp/kzdNFDW22cGQxoAE
M3MAgD+YVC76zuUXtIHSViwZ85scwahcoGxwvquVot2+5NoaGYITCjntAoGAIxbU
nbVA+6fkfCZsVa7M7mzGmiw6lQwfc2UXSPMiwAUTBIgGkKYfCSQ1kn2LmeD3+IYp
1JbUJMME4CzIDu4VTssDbJEqqGBHd8hbDxpX1kTcVWvCbVtlNI7NU4Y/sP3id3af
WLwtrhFR+A3Ood16f173zyT9No+hREYveUVqkpECgYA8r/Oa1HjUuyVXuccavYG4
39NGpgXUEkjkxnX2Z/OurcBbbtIwwKD/hOAD+hgDLmKZXCiSFjIEuLAkoU/+Lp9+
V7B8phfmS/3kNRZpTtKkK3Me+soWGw902oeMPsI69TonWtBANtrM/2WM0pwIP1jq
5VjMJFQ+4RnXZyXCCwaANA==
-----END PRIVATE KEY-----"
fi

{
  echo "FCM_PROJECT_ID=${FCM_PROJECT_ID}"
  echo "FCM_PRIVATE_KEY_ID=${FCM_PRIVATE_KEY_ID}"
  printf 'FCM_PRIVATE_KEY=%s\n' "${FCM_PRIVATE_KEY}"
  echo "FCM_CLIENT_EMAIL=${FCM_CLIENT_EMAIL}"
  echo "FCM_CLIENT_ID=${FCM_CLIENT_ID}"
} > .env

echo "Generated .env successfully"

# ── Patch package_config.json to use local patched flutter lib ──────────────
FLUTTER_NIX_QUOTED='file:///nix/store/i07crp4mg1rimd97s1byrq4gasg7dsk5-flutter-wrapped-3.32.0-sdk-links/packages/flutter"'
FLUTTER_LOCAL_QUOTED='file:///home/runner/workspace/flutter_local"'
PKG_CFG=".dart_tool/package_config.json"

if [ -f "$PKG_CFG" ]; then
  sed -i "s|$FLUTTER_NIX_QUOTED|$FLUTTER_LOCAL_QUOTED|g" "$PKG_CFG"
  echo "Patched package_config.json → flutter → local copy"
fi

echo "Building Flutter web app..."
flutter build web --release --no-pub 2>&1 | tail -30

echo "Starting proxy server on port 5000..."
node proxy-server.js
