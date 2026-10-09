/**
 * AWS Lambda Function for Speech-to-Text (Transcription)
 * Supports OpenAI provider
 * Uses @rocketnew/llm-sdk for multi-provider support
 */

const { transcription } = require('@rocketnew/llm-sdk');

function formatErrorResponse(error, provider) {
  const statusCode = error.statusCode || 500;
  const providerName = error.llmProvider || provider || 'Unknown';
  return {
    error: `${providerName.toUpperCase()} API error: ${statusCode}`,
    details: error.message || error.body || String(error),
  };
}

exports.handler = async (event) => {
  const headers = { 'Content-Type': 'application/json' };

  // Only allow POST requests
  if (event?.requestContext?.http?.method !== 'POST' && event?.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers,
      body: JSON.stringify({
        error: 'Method not allowed: Use POST',
        details: 'This endpoint only accepts POST requests',
      }),
    };
  }

  let body = {};
  try {
    if (event.body) {
      body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
    }
  } catch (e) {
    return {
      statusCode: 400,
      headers,
      body: JSON.stringify({
        error: 'Invalid request: JSON parsing failed',
        details: 'The request body must be valid JSON',
      }),
    };
  }

  const { provider, model, file, filename, parameters = {} } = body;

  try {
    const supportedProviders = ['OPEN_AI'];
    if (!provider || !supportedProviders.includes(provider)) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({
          error: `Unsupported provider: ${provider || 'none'}`,
          details: `Supported providers are: ${supportedProviders.join(', ')}`,
        }),
      };
    }

    let apiKey;
    if (provider === 'OPEN_AI') {
      apiKey = process.env.OPENAI_API_KEY;
    }

    if (!apiKey) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({
          error: `${provider} API key is not configured`,
          details: 'The API key for this provider is missing in environment variables',
        }),
      };
    }

    if (!model || !file || !filename) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({
          error: 'Missing required fields: model, file, filename',
          details: 'file must be the base64-encoded audio bytes (optionally a data URL); filename must include an extension (e.g., "speech.mp3")',
        }),
      };
    }

    const base64 = file.startsWith('data:') ? file.split(',')[1] : file;
    const fileBuffer = Buffer.from(base64, 'base64');
    const audioFile = new File([fileBuffer], filename);

    const response = await transcription({
      ...parameters,
      model,
      file: audioFile,
      api_key: apiKey,
    });

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify(response),
    };
  } catch (error) {
    const errorResponse = formatErrorResponse(error, provider);
    return {
      statusCode: error.statusCode || 500,
      headers,
      body: JSON.stringify(errorResponse),
    };
  }
};
