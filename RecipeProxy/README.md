# Freshly — Recipe Proxy

Node.js/TypeScript backend that receives a list of expiring ingredients from the iOS app and calls the Claude API to generate a recipe suggestion.

## How it works

```
iOS app  →  POST /recipe { ingredients, seed }  →  Proxy  →  Claude API  →  JSON recipe
```

The proxy keeps your Anthropic API key server-side so it never ships in the iOS binary.

---

## Local development

```bash
cd RecipeProxy
cp .env.example .env      # fill in ANTHROPIC_API_KEY (leave PROXY_TOKEN empty for dev)
npm install
npm run dev               # runs ts-node, no build step needed
```

Test it:
```bash
curl -X POST http://localhost:3000/recipe \
  -H "Content-Type: application/json" \
  -d '{"ingredients": ["chicken breast", "spinach", "garlic", "lemon"], "seed": 0}'
```

Expected response:
```json
{
  "title": "Lemon Garlic Chicken",
  "subtitle": "A quick pan-seared chicken with wilted spinach.",
  "timeText": "25 min",
  "ingredients": ["chicken breast", "spinach", "garlic", "lemon"]
}
```

---

## Production deployment

### Option 1: Render (recommended — free tier available)

1. Push this repo (or the `RecipeProxy/` folder) to GitHub.
2. Go to [render.com](https://render.com) → New → Web Service.
3. Connect your repo. Render detects the Dockerfile automatically.
4. Set environment variables in the Render dashboard:
   - `ANTHROPIC_API_KEY` — your key from console.anthropic.com
   - `PROXY_TOKEN` — generate with `openssl rand -hex 32`
5. Deploy. Render gives you a URL like `https://freshly-recipe-proxy.onrender.com`.

### Option 2: Railway

1. `railway init` inside `RecipeProxy/`
2. `railway up`
3. Set env vars in the Railway dashboard.

### Option 3: Fly.io

```bash
cd RecipeProxy
fly launch          # follow prompts
fly secrets set ANTHROPIC_API_KEY=sk-ant-... PROXY_TOKEN=your-secret
fly deploy
```

---

## Connecting the iOS app

Once deployed, fill in `ExpiredItem/Info.plist`:

```xml
<key>RECIPE_PROXY_URL</key>
<string>https://your-proxy-url.onrender.com/recipe</string>
<key>RECIPE_PROXY_TOKEN</key>
<string>the-same-PROXY_TOKEN-you-set-on-the-server</string>
```

**Never commit the real values.** Use Xcode build configurations or a CI secret for production builds:
- Create `Debug.xcconfig` / `Release.xcconfig` with the values.
- Reference them in Info.plist as `$(RECIPE_PROXY_URL)` and `$(RECIPE_PROXY_TOKEN)`.
- Add the `.xcconfig` files to `.gitignore`.

---

## API reference

### `POST /recipe`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer <PROXY_TOKEN>   # required in production
```

**Body:**
```json
{
  "ingredients": ["chicken", "spinach", "garlic"],
  "seed": 0
}
```
- `ingredients` — 1–8 non-empty strings (extras are truncated)
- `seed` — integer, increment to get a different suggestion

**Response 200:**
```json
{
  "title": "string",
  "subtitle": "string",
  "timeText": "string",
  "ingredients": ["string"]
}
```

**Errors:**
- `400` — bad request (missing/invalid ingredients)
- `401` — wrong or missing token
- `502` — Claude API error

### `GET /health`
Returns `{"status":"ok"}`. Use this as the health check URL on your hosting platform.
