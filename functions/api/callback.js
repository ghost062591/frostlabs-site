export async function onRequestGet(context) {
  const { request, env } = context;
  const url = new URL(request.url);

  // Get authorization code and state from query params
  const code = url.searchParams.get('code');
  const state = url.searchParams.get('state');

  if (!code) {
    return new Response('Missing authorization code', { status: 400 });
  }

  // Verify state from cookie (CSRF protection)
  const cookies = request.headers.get('Cookie') || '';
  const stateCookie = cookies.split(';').find(c => c.trim().startsWith('oauth_state='));
  const expectedState = stateCookie?.split('=')[1];

  if (!expectedState || expectedState !== state) {
    return new Response('Invalid state parameter', { status: 400 });
  }

  // Exchange code for token
  const clientId = env.OAUTH_CLIENT_ID;
  const clientSecret = env.OAUTH_CLIENT_SECRET;
  const authentikUrl = env.AUTHENTIK_URL || 'https://auth.frostlabs.me';
  const redirectUri = `${url.origin}/api/callback`;

  const tokenUrl = `${authentikUrl}/application/o/token/`;
  const tokenResponse = await fetch(tokenUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'authorization_code',
      code: code,
      redirect_uri: redirectUri,
      client_id: clientId,
      client_secret: clientSecret,
    }),
  });

  if (!tokenResponse.ok) {
    const error = await tokenResponse.text();
    console.error('Token exchange failed:', error);
    return new Response('Failed to exchange code for token', { status: 500 });
  }

  const tokenData = await tokenResponse.json();
  const accessToken = tokenData.access_token;

  // Get user info
  const userInfoUrl = `${authentikUrl}/application/o/userinfo/`;
  const userInfoResponse = await fetch(userInfoUrl, {
    headers: {
      'Authorization': `Bearer ${accessToken}`,
    },
  });

  if (!userInfoResponse.ok) {
    return new Response('Failed to get user info', { status: 500 });
  }

  const userInfo = await userInfoResponse.json();

  // User authenticated successfully via Authentik
  // Now provide the GitHub token for repository access
  const githubToken = env.GITHUB_TOKEN;

  if (!githubToken) {
    return new Response('GitHub token not configured', { status: 500 });
  }

  // Return HTML page that sends message to CMS
  const html = `
<!DOCTYPE html>
<html>
<head>
  <title>Authorizing...</title>
</head>
<body>
  <p>Authorization successful. Redirecting...</p>
  <script>
    (function() {
      function receiveMessage(e) {
        console.log("Received message:", e);
        window.opener.postMessage(
          'authorization:github:success:${JSON.stringify({
            token: githubToken,
            provider: 'github'
          }).replace(/'/g, "\\'")}',
          e.origin
        );
        window.removeEventListener("message", receiveMessage, false);
      }
      window.addEventListener("message", receiveMessage, false);

      console.log("Sending init message");
      window.opener.postMessage("authorizing:github", "*");
    })();
  </script>
</body>
</html>
`;

  return new Response(html, {
    headers: {
      'Content-Type': 'text/html',
      'Set-Cookie': 'oauth_state=; Path=/; Max-Age=0', // Clear state cookie
    },
  });
}
