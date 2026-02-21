export default {
  async fetch(request, env) {
    // Only allow POST
    if (request.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    // Validate app secret
    const auth = request.headers.get("Authorization");
    if (!auth || auth !== `Bearer ${env.APP_SECRET}`) {
      return new Response("Unauthorized", { status: 401 });
    }

    // Reject oversized payloads
    const contentLength = parseInt(request.headers.get("Content-Length") || "0", 10);
    if (contentLength > 50000) {
      return new Response("Payload too large", { status: 413 });
    }

    // Forward to Gemini (OpenAI-compatible endpoint)
    const body = await request.text();
    const geminiResponse = await fetch("https://generativelanguage.googleapis.com/v1beta/openai/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${env.GEMINI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body,
    });

    // Return Gemini response unchanged
    return new Response(geminiResponse.body, {
      status: geminiResponse.status,
      headers: {
        "Content-Type": geminiResponse.headers.get("Content-Type") || "application/json",
      },
    });
  },
};
