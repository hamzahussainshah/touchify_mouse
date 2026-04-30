# TouchifyMouse Landing Page

Static landing page — single `index.html` and `privacy.html` with embedded CSS,
no build step, no dependencies.

## Local preview

```bash
cd landing && python3 -m http.server 8000
# open http://localhost:8000
```

## Before deploying — find/replace

Search the two HTML files for `CHANGE_ME` and replace with your real values:

| Placeholder | Replace with |
|---|---|
| `CHANGE_ME/touchifymouse-desktop` | `<your-github-user>/<your-desktop-repo>` |
| `hamzahussainshaah@gmail.com` | Your contact email (already set, change if needed) |
| `com.touchify_mouse` | Your Play Store package name (already set) |

If you publish a separate App Store version later, update the iOS link in the
hero `mobile-cta` block.

## Deploy options

### GitHub Pages (recommended — free, easy)

```bash
# Create a public repo for the site, e.g. "touchifymouse-site"
gh repo create touchifymouse-site --public
git -C ../ subtree push --prefix=landing origin-site main
# Or simply: copy the two HTML files into a new repo, push to main.
# Then: repo → Settings → Pages → Source: main / root
# URL: https://<user>.github.io/touchifymouse-site/
```

For a custom domain (e.g. `touchifymouse.app`):
1. Add a `CNAME` file in the repo containing just the domain name.
2. In your DNS, add an `A` record to GitHub Pages IPs (or `CNAME` → `<user>.github.io`).
3. Repo → Settings → Pages → Custom domain → enter the domain.

### Netlify drop

Drag the `landing/` folder onto https://app.netlify.com/drop. Done.

### Cloudflare Pages

```bash
npx wrangler pages deploy landing
```

## After deploy — point the mobile app at it

Open `lib/features/desktop_invite/desktop_links.dart` and set:

```dart
static const String landingPageUrl = 'https://<your-domain>/';
```

The mobile app's "Get desktop app" sheet will then open this page instead of
the raw GitHub Releases URL — meaning you can change the download targets
without re-publishing the mobile app to Play.

Also update the Play Console privacy-policy URL to point at `<your-domain>/privacy.html`.
