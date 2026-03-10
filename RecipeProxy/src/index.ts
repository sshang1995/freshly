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

// ─── Start ────────────────────────────────────────────────────────────────────

app.listen(PORT, () => {
  console.log(`Freshly recipe proxy listening on port ${PORT}`);
  console.log(`Auth: ${PROXY_TOKEN ? "enabled" : "disabled (dev mode)"}`);
});
