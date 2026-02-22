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

    const url = new URL(request.url);
    const path = url.pathname;

    // Route based on path
    if (path === "/v1/vision") {
      return handleVision(request, env);
    }

    // Default: /v1/chat → Gemini
    return handleChat(request, env);
  },
};

// Existing Gemini chat handler
async function handleChat(request, env) {
  const contentLength = parseInt(request.headers.get("Content-Length") || "0", 10);
  if (contentLength > 50000) {
    return new Response("Payload too large", { status: 413 });
  }

  const body = await request.text();
  const geminiResponse = await fetch("https://generativelanguage.googleapis.com/v1beta/openai/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${env.GEMINI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body,
  });

  return new Response(geminiResponse.body, {
    status: geminiResponse.status,
    headers: {
      "Content-Type": geminiResponse.headers.get("Content-Type") || "application/json",
    },
  });
}

// Claude Vision handler for commitment photo verification
async function handleVision(request, env) {
  const contentLength = parseInt(request.headers.get("Content-Length") || "0", 10);
  if (contentLength > 1_500_000) {
    return new Response("Payload too large (1.5MB limit for vision)", { status: 413 });
  }

  const body = await request.text();
  const claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": env.ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
      "Content-Type": "application/json",
    },
    body,
  });

  return new Response(claudeResponse.body, {
    status: claudeResponse.status,
    headers: {
      "Content-Type": claudeResponse.headers.get("Content-Type") || "application/json",
    },
  });
}
