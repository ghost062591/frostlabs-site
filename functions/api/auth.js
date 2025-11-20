export async function onRequestGet(context) {
  try {
    const { request, env } = context;
    const url = new URL(request.url);

    // Get GitHub OAuth App credentials from environment
    const clientId = env.GITHUB_CLIENT_ID;
    if (!clientId) {
      return new Response('GitHub OAuth not configured. Please set GITHUB_CLIENT_ID environment variable.', {
        status: 500,
        headers: { 'Content-Type': 'text/plain' }
      });
    }

    const redirectUri = `${url.origin}/api/callback`;

    // Generate random state for CSRF protection
    const state = crypto.randomUUID();

    // Build GitHub authorization URL
    const authUrl = new URL('https://github.com/login/oauth/authorize');
    authUrl.searchParams.set('client_id', clientId);
    authUrl.searchParams.set('redirect_uri', redirectUri);
    authUrl.searchParams.set('scope', 'repo,user');
    authUrl.searchParams.set('state', state);

    // Store state in cookie for verification and redirect
    return new Response(null, {
      status: 302,
      headers: {
        'Location': authUrl.toString(),
        'Set-Cookie': `oauth_state=${state}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=600`
      }
    });
  } catch (error) {
    return new Response(`Error in auth endpoint: ${error.message}`, {
      status: 500,
      headers: { 'Content-Type': 'text/plain' }
    });
  }
}
