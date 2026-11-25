import { timingSafeEqual } from "node:crypto";

export default async (request) => {
  const reply = (status, data) =>
    new Response(JSON.stringify(data), {
      status,
      headers: {
        "Content-Type": "application/json",
        "Cache-Control": "no-store"
      }
    });

  if (request.method !== "POST") {
    return reply(405, { error: "Method not allowed" });
  }

  const apiKey = process.env.GEMINI_API_KEY;
  const accessToken = process.env.QUIZFORGE_ACCESS_TOKEN;

  if (!apiKey || !accessToken) {
    return reply(503, { error: "AI service not configured" });
  }

  const supplied = Buffer.from(
    request.headers.get("x-quizforge-token") || ""
  );
  const expected = Buffer.from(accessToken);

  if (
    supplied.length !== expected.length ||
    !timingSafeEqual(supplied, expected)
  ) {
    return reply(401, { error: "Invalid AI access password" });
  }

  try {
    const raw = await request.text();

    if (Buffer.byteLength(raw) > 4 * 1024 * 1024) {
      return reply(413, { error: "Request too large" });
    }

    const body = JSON.parse(raw);

    if (
      !Array.isArray(body.contents) ||
      body.contents.length !== 1
    ) {
      return reply(400, { error: "Invalid request" });
    }

    const parts = body.contents[0]?.parts;

    if (
      !Array.isArray(parts) ||
      parts.length < 1 ||
      parts.length > 2 ||
      typeof parts[0]?.text !== "string" ||
      parts[0].text.length > 60000
    ) {
      return reply(400, { error: "Invalid content" });
    }

    if (parts.length === 2) {
      const image = parts[1]?.inline_data;

      if (
        !image ||
        !["image/jpeg", "image/png"].includes(image.mime_type) ||
        typeof image.data !== "string"
      ) {
        return reply(400, { error: "Invalid image" });
      }
    }

    const model = "gemini-3.5-flash-lite";

    const payload = {
      contents: [{
        role: "user",
        parts
      }],
      generationConfig: {
        ...(body.generationConfig?.responseMimeType ===
          "application/json"
          ? {
              responseMimeType: "application/json",
              responseSchema: body.generationConfig.responseSchema
            }
          : {}),
        maxOutputTokens: 8192
      }
    };

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": apiKey
        },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(25000)
      }
    );

    if (!response.ok) {
      return reply(response.status, {
        error: "Gemini request failed"
      });
    }

    return reply(200, await response.json());

  } catch (error) {
    if (error instanceof SyntaxError) {
      return reply(400, { error: "Invalid JSON" });
    }

    return reply(502, { error: "AI service unavailable" });
  }
};