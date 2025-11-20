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

  // Exchange code for GitHub token
  const clientId = env.GITHUB_CLIENT_ID;
  const clientSecret = env.GITHUB_CLIENT_SECRET;

  if (!clientId || !clientSecret) {
    return new Response('GitHub OAuth not configured', { status: 500 });
  }

  const tokenUrl = 'https://github.com/login/oauth/access_token';
  const tokenResponse = await fetch(tokenUrl, {
    method: 'POST',
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      client_id: clientId,
      client_secret: clientSecret,
      code: code,
    }),
  });

  if (!tokenResponse.ok) {
    const error = await tokenResponse.text();
    console.error('Token exchange failed:', error);
    return new Response('Failed to exchange code for token', { status: 500 });
  }

  const tokenData = await tokenResponse.json();
  const githubToken = tokenData.access_token;

  if (!githubToken) {
    return new Response('Failed to get access token', { status: 500 });
  }

  // Return success message that CMS expects
  const message = {
    token: githubToken,
    provider: 'github'
  };

  const html = `
<!DOCTYPE html>
<html>
<head>
  <title>Authorizing...</title>
  <script>
    (function() {
      function receiveMessage(event) {
        window.opener.postMessage(
          'authorization:github:success:${JSON.stringify(message).replace(/'/g, "\\'")}',
          event.origin
        );
        window.removeEventListener("message", receiveMessage, false);
      }
      window.addEventListener("message", receiveMessage, false);
      window.opener.postMessage("authorizing:github", "*");
    })();
  </script>
</head>
<body>
  <p>Authorization successful. Closing...</p>
</body>
</html>
`;

  return new Response(html, {
    headers: {
      'Content-Type': 'text/html',
      'Set-Cookie': 'oauth_state=; Path=/; Max-Age=0',
    },
  });
}
