import "dotenv/config";
import Anthropic from "@anthropic-ai/sdk";
import express, { NextFunction, Request, Response } from "express";

// ─── Config ──────────────────────────────────────────────────────────────────

const PORT = parseInt(process.env.PORT ?? "3000", 10);
const ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY ?? "";
const PROXY_TOKEN = process.env.PROXY_TOKEN ?? ""; // shared secret with iOS app

if (!ANTHROPIC_API_KEY) {
  console.error("ANTHROPIC_API_KEY is required");
  process.exit(1);
}

// ─── Types ────────────────────────────────────────────────────────────────────

interface RecipeRequest {
  ingredients: string[];
  seed?: number;
}

interface RecipeResponse {
  title: string;
  subtitle: string;
  timeText: string;
  ingredients: string[];
  steps: string[];
}

interface ReceiptParseRequest {
  ocrText: string;
}

interface ReceiptItem {
  name: string;
  quantity: string;
  category: string;
}

interface ReceiptParseResponse {
  items: ReceiptItem[];
}

// ─── Claude client ────────────────────────────────────────────────────────────

const anthropic = new Anthropic({ apiKey: ANTHROPIC_API_KEY });

async function generateRecipe(
  ingredients: string[],
  seed: number
): Promise<RecipeResponse> {
  const ingredientList = ingredients.join(", ");
  const variationHint =
    seed > 0 ? `\nVariation style #${(seed % 5) + 1}.` : "";

  const message = await anthropic.messages.create({
    model: "claude-opus-4-6",
    max_tokens: 400,
    system: `You are a creative chef who specialises in reducing food waste. Given a list of expiring ingredients, you suggest ONE practical recipe that uses as many of them as possible. Always respond with valid JSON only — no markdown, no explanation, just the raw JSON object.`,
    messages: [
      {
        role: "user",
        content: `Expiring ingredients: ${ingredientList}${variationHint}

Respond with this exact JSON shape:
{
  "title": "Recipe name (short, appetising)",
  "subtitle": "One-sentence description",
  "timeText": "e.g. 20 min or 1 hr 10 min",
  "ingredients": ["only the provided ingredients that are actually used"],
  "steps": ["Step 1 instruction", "Step 2 instruction", "..."]
}

The steps array should contain 4–7 clear, concise cooking instructions in order.`,
      },
    ],
  });

  const raw = message.content.find((b) => b.type === "text")?.text ?? "";

  // Strip accidental markdown fences if Claude adds them
  const jsonText = raw.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "").trim();

  let parsed: unknown;
  try {
    parsed = JSON.parse(jsonText);
  } catch {
    throw new Error(`Claude returned non-JSON: ${raw.slice(0, 200)}`);
  }

  if (!isRecipeResponse(parsed)) {
    throw new Error(`Claude returned unexpected shape: ${jsonText.slice(0, 200)}`);
  }

  return parsed;
}

async function parseReceiptItems(ocrText: string): Promise<ReceiptItem[]> {
  const message = await anthropic.messages.create({
    model: "claude-haiku-4-5-20251001",
    max_tokens: 1024,
    system: `You are a grocery receipt parser. Extract only food and beverage items from receipt OCR text. Ignore non-food items (cleaning products, paper goods, cosmetics, medicine, etc.). Always respond with valid JSON only — no markdown, no explanation, just the raw JSON array.`,
    messages: [
      {
        role: "user",
        content: `Receipt text:
${ocrText}

Extract every food or beverage item and respond with this exact JSON shape:
{
  "items": [
    { "name": "Human-readable item name", "quantity": "e.g. 2, 500g, 1lb — empty string if not clear", "category": "one of: produce|dairy|meat|bakery|frozen|beverages|condiments|snacks|other" }
  ]
}

Rules:
- Clean up item names (remove price codes, PLU numbers, abbreviations)
- Only include food/beverage items — skip medicine, cosmetics, household goods
- If quantity is ambiguous or missing, use empty string
- Category must be exactly one of the listed values`,
      },
    ],
  });

  const raw = message.content.find((b) => b.type === "text")?.text ?? "";
  const jsonText = raw.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "").trim();

  let parsed: unknown;
  try {
    parsed = JSON.parse(jsonText);
  } catch {
    throw new Error(`Claude returned non-JSON: ${raw.slice(0, 200)}`);
  }

  if (
    typeof parsed !== "object" ||
    parsed === null ||
    !Array.isArray((parsed as Record<string, unknown>).items)
  ) {
    throw new Error(`Claude returned unexpected shape: ${jsonText.slice(0, 200)}`);
  }

  const rawItems = (parsed as Record<string, unknown>).items as unknown[];
  return rawItems
    .filter(
      (i): i is ReceiptItem =>
        typeof i === "object" &&
        i !== null &&
        typeof (i as Record<string, unknown>).name === "string" &&
        typeof (i as Record<string, unknown>).quantity === "string" &&
        typeof (i as Record<string, unknown>).category === "string"
    )
    .map((i) => ({
      name: i.name.trim(),
      quantity: i.quantity.trim(),
      category: i.category.trim().toLowerCase(),
    }))
    .filter((i) => i.name.length > 0);
}

function isRecipeResponse(v: unknown): v is RecipeResponse {
  if (typeof v !== "object" || v === null) return false;
  const r = v as Record<string, unknown>;
  return (
    typeof r.title === "string" &&
    typeof r.subtitle === "string" &&
    typeof r.timeText === "string" &&
    Array.isArray(r.ingredients) &&
    (r.ingredients as unknown[]).every((i) => typeof i === "string") &&
    Array.isArray(r.steps) &&
    (r.steps as unknown[]).every((s) => typeof s === "string")
  );
}

// ─── Express app ──────────────────────────────────────────────────────────────

const app = express();
app.use(express.json({ limit: "16kb" }));

// Auth middleware — skip if no PROXY_TOKEN is configured (dev mode)
app.use((req: Request, res: Response, next: NextFunction) => {
  if (!PROXY_TOKEN) {
    next();
    return;
  }
  const auth = req.headers.authorization ?? "";
  if (auth !== `Bearer ${PROXY_TOKEN}`) {
    res.status(401).json({ error: "Unauthorized" });
    return;
  }
  next();
});

// Health check
app.get("/health", (_req: Request, res: Response) => {
  res.json({ status: "ok" });
});

// Recipe endpoint
app.post("/recipe", async (req: Request, res: Response) => {
  const body = req.body as RecipeRequest;

  if (
    !Array.isArray(body.ingredients) ||
    body.ingredients.length === 0 ||
    body.ingredients.some((i) => typeof i !== "string")
  ) {
    res.status(400).json({ error: "ingredients must be a non-empty array of strings" });
    return;
  }

  // Sanitise: trim, deduplicate, cap at 8
  const ingredients = [
    ...new Set(
      body.ingredients
        .map((i) => i.trim())
        .filter((i) => i.length > 0 && i.length < 80)
    ),
  ].slice(0, 8);

  if (ingredients.length === 0) {
    res.status(400).json({ error: "No valid ingredients provided" });
    return;
  }

  const seed = typeof body.seed === "number" ? body.seed : 0;

  try {
    const recipe = await generateRecipe(ingredients, seed);
    res.json(recipe);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    console.error("[recipe] Error:", message);
    res.status(502).json({ error: "Failed to generate recipe", detail: message });
  }
});

// Parse-receipt endpoint
app.post("/parse-receipt", async (req: Request, res: Response) => {
  const body = req.body as ReceiptParseRequest;

  if (typeof body.ocrText !== "string" || body.ocrText.trim().length === 0) {
    res.status(400).json({ error: "ocrText must be a non-empty string" });
    return;
  }

  // Cap input to avoid excessive token usage
  const ocrText = body.ocrText.slice(0, 4000);

  try {
    const items = await parseReceiptItems(ocrText);
    res.json({ items });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    console.error("[parse-receipt] Error:", message);
    res.status(502).json({ error: "Failed to parse receipt", detail: message });
  }
});

// ─── Start ────────────────────────────────────────────────────────────────────

app.listen(PORT, () => {
  console.log(`Freshly recipe proxy listening on port ${PORT}`);
  console.log(`Auth: ${PROXY_TOKEN ? "enabled" : "disabled (dev mode)"}`);
});
