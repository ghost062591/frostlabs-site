export async function onRequestGet(context) {
  const { request, env } = context;
  const url = new URL(request.url);

  // Get GitHub OAuth App credentials from environment
  const clientId = env.GITHUB_CLIENT_ID;
  if (!clientId) {
    return new Response('GitHub OAuth not configured', { status: 500 });
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

  // Store state in cookie for verification
  const response = Response.redirect(authUrl.toString(), 302);
  response.headers.set('Set-Cookie', `oauth_state=${state}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=600`);

  return response;
}
