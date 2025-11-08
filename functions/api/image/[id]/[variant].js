/**
 * Cloudflare Pages Function: Image Proxy
 *
 * Proxies images from Cloudflare Images and modifies CSP headers
 * to allow them to be displayed in GLightbox modals.
 *
 * URL format: /api/image/{imageId}/{variant}
 * Example: /api/image/house-project-delivery-Delivery_001/public
 */

export async function onRequest(context) {
  const { params } = context;
  const { id: imageId, variant } = params;

  // Cloudflare Images account hash
  const accountHash = 'sFNd_vzb3SAtjIIqbbqbmQ';

  // Construct Cloudflare Images URL
  const imageUrl = `https://imagedelivery.net/${accountHash}/${imageId}/${variant}`;

  try {
    // Fetch the image from Cloudflare Images
    const imageResponse = await fetch(imageUrl, {
      cf: {
        // Cache the response in Cloudflare's edge cache
        cacheTtl: 86400, // 24 hours
        cacheEverything: true,
      }
    });

    if (!imageResponse.ok) {
      return new Response(`Failed to fetch image: ${imageResponse.status}`, {
        status: imageResponse.status,
        headers: {
          'Content-Type': 'text/plain'
        }
      });
    }

    // Get the image body and content type
    const imageBody = await imageResponse.arrayBuffer();
    const contentType = imageResponse.headers.get('Content-Type') || 'image/jpeg';

    // Create new response with modified headers
    return new Response(imageBody, {
      status: 200,
      headers: {
        'Content-Type': contentType,
        // Allow images to be displayed in any context (no CSP restrictions)
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        // Set cache headers for browser caching
        'Cache-Control': 'public, max-age=86400, immutable',
        // Explicitly allow embedding
        'X-Content-Type-Options': 'nosniff',
      }
    });

  } catch (error) {
    return new Response(`Error fetching image: ${error.message}`, {
      status: 500,
      headers: {
        'Content-Type': 'text/plain'
      }
    });
  }
}
