export async function onRequestGet(context) {
  const { request, env } = context;
  const url = new URL(request.url);

  // Get environment variables
  const clientId = env.OAUTH_CLIENT_ID;
  const authentikUrl = env.AUTHENTIK_URL || 'https://auth.frostlabs.me';
  const redirectUri = `${url.origin}/api/callback`;

  // Generate random state for CSRF protection
  const state = crypto.randomUUID();

  // Build authorization URL
  const authUrl = new URL(`${authentikUrl}/application/o/authorize/`);
  authUrl.searchParams.set('client_id', clientId);
  authUrl.searchParams.set('redirect_uri', redirectUri);
  authUrl.searchParams.set('response_type', 'code');
  authUrl.searchParams.set('scope', 'openid profile email');
  authUrl.searchParams.set('state', state);

  // Store state in cookie for verification
  const response = Response.redirect(authUrl.toString(), 302);
  response.headers.set('Set-Cookie', `oauth_state=${state}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=600`);

  return response;
}
