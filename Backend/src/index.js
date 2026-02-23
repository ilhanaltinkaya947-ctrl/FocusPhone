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
    if (path === "/v1/groq") {
      return handleGroq(request, env);
    }

    // Default: /v1/chat → Gemini
    return handleChat(request, env);
  },
};

// Gemini chat handler (onboarding, extension requests)
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

// Groq handler (journey generation, mentor service)
async function handleGroq(request, env) {
  const contentLength = parseInt(request.headers.get("Content-Length") || "0", 10);
  if (contentLength > 50000) {
    return new Response("Payload too large", { status: 413 });
  }

  const body = await request.text();
  const groqResponse = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${env.GROQ_API_KEY}`,
      "Content-Type": "application/json",
    },
    body,
  });

  return new Response(groqResponse.body, {
    status: groqResponse.status,
    headers: {
      "Content-Type": groqResponse.headers.get("Content-Type") || "application/json",
    },
  });
}
