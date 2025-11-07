# GLightbox Integration - Usage Guide

This guide explains how to use the new lightbox functionality in your FrostLabs Hugo site.

## Overview

GLightbox has been integrated into your site to provide fast-loading, responsive image galleries with beautiful full-resolution lightbox views. The system automatically:
- Generates optimized thumbnails (WebP format, 800x600px)
- Preserves original full-resolution images for lightbox view
- Only loads the library on pages that use lightbox shortcodes
- Integrates with your dark theme

## Available Shortcodes

### 1. Single Image Lightbox

Use the `lightbox` shortcode for individual images with lightbox functionality.

**Basic Usage:**
```hugo
{{< lightbox src="image.jpg" alt="Description" >}}
```

**With Caption:**
```hugo
{{< lightbox src="image.jpg" alt="Description" caption="Optional caption shown in lightbox" >}}
```

**With Custom Thumbnail Size:**
```hugo
{{< lightbox src="image.jpg" alt="Description" thumb="600x400" >}}
```

**Full Parameters:**
- `src` (required): Image path (relative to page bundle or static/)
- `alt` (required): Alt text for accessibility
- `caption` (optional): Caption displayed in lightbox
- `thumb` (optional): Thumbnail size (default: 800x600, format: WIDTHxHEIGHT)
- `class` (optional): Additional CSS classes

### 2. Gallery with Lightbox

Use the `lightbox-gallery` shortcode for masonry-style galleries with lightbox navigation.

**Basic Usage:**
```hugo
{{< lightbox-gallery >}}
  <img src="image1.jpg" class="grid-w50" alt="Image 1" />
  <img src="image2.jpg" class="grid-w33 md:grid-w50" alt="Image 2" />
  <img src="image3.jpg" class="grid-w50" alt="Image 3" />
{{< /lightbox-gallery >}}
```

**With Captions:**
```hugo
{{< lightbox-gallery >}}
  <img src="image1.jpg" class="grid-w50" alt="Image 1" data-caption="First image caption" />
  <img src="image2.jpg" class="grid-w50" alt="Image 2" data-caption="Second image caption" />
{{< /lightbox-gallery >}}
```

**Grid Width Classes:**
- `grid-w50`: 50% width (2 columns)
- `grid-w33`: 33% width (3 columns)
- `grid-w25`: 25% width (4 columns)

**Responsive Classes:**
Add breakpoint prefixes for responsive layouts:
- `sm:grid-w50`: 50% width on small screens
- `md:grid-w33`: 33% width on medium screens
- `lg:grid-w25`: 25% width on large screens
- `xl:grid-w20`: 20% width on extra large screens

## Image Organization

### Page Bundle Resources (Recommended)

For best performance, place images in the same directory as your markdown file:

```
content/
  blog/
    my-post/
      _index.md
      image1.jpg
      image2.jpg
```

Then reference them directly:
```hugo
{{< lightbox src="image1.jpg" alt="My image" >}}
```

Hugo will automatically process these images and generate optimized thumbnails.

### Static Files

Images in the `static/` directory can also be used:

```
static/
  gallery/
    photo1.jpg
    photo2.jpg
```

Reference with the path from static:
```hugo
{{< lightbox src="gallery/photo1.jpg" alt="Photo" >}}
```

**Note:** Static files won't be automatically processed for thumbnails.

## Features

✅ **Performance Optimized**
- Thumbnails use WebP format with 85% quality
- Original images load only when lightbox opens
- Conditional loading - library only loads on pages using lightbox

✅ **User Experience**
- Keyboard navigation (← → arrows, ESC to close)
- Touch/swipe support on mobile devices
- Zoom and drag functionality
- Smooth fade transitions

✅ **Accessibility**
- Alt text support for screen readers
- Keyboard navigation
- Focus states for controls

✅ **Dark Theme Integration**
- Custom styling matches FrostLabs dark theme
- Semi-transparent overlays
- Consistent button styling

## Keyboard Controls

When lightbox is open:
- `→` or `D`: Next image
- `←` or `A`: Previous image
- `ESC`: Close lightbox
- `Zoom`: Click image to zoom in/out
- `Drag`: Click and drag zoomed images

## Example: Converting Existing Gallery

**Before (old gallery shortcode):**
```hugo
{{< gallery >}}
  <img src="image1.jpg" class="grid-w50" alt="Image 1" />
  <img src="image2.jpg" class="grid-w50" alt="Image 2" />
{{< /gallery >}}
```

**After (with lightbox):**
```hugo
{{< lightbox-gallery >}}
  <img src="image1.jpg" class="grid-w50" alt="Image 1" data-caption="Caption 1" />
  <img src="image2.jpg" class="grid-w50" alt="Image 2" data-caption="Caption 2" />
{{< /lightbox-gallery >}}
```

## Configuration

The following Hugo configuration has been optimized for image processing:

```toml
[imaging]
  anchor = 'Center'
  quality = 85
  resampleFilter = 'Lanczos'
  [imaging.exif]
    disableDate = false
    disableLatLong = true
```

## Troubleshooting

### Images not showing in lightbox
- Check that image paths are correct relative to page bundle or static/
- Verify images exist in the specified location
- Check browser console for errors

### Lightbox not opening
- Ensure the shortcode name is correct (`lightbox` or `lightbox-gallery`)
- Check that GLightbox JavaScript is loading (check browser console)
- Verify no JavaScript errors on page

### Thumbnails not optimized
- Use page bundle resources instead of static files
- Ensure images are in a supported format (JPEG, PNG, WebP)
- Check Hugo build output for image processing messages

## Performance Tips

1. **Use page bundles** for automatic thumbnail generation
2. **Specify appropriate thumbnail sizes** - default is 800x600
3. **Use WebP source images** when possible for best compression
4. **Optimize original images** before adding to site (remove unnecessary EXIF data)
5. **Use responsive grid classes** to ensure good layout on all devices

## Files Created

The following files were added for this integration:

```
/assets/
  /lib/glightbox/
    glightbox.min.js       # GLightbox library
    glightbox.min.css      # GLightbox base styles
  /css/
    custom-lightbox.css    # Dark theme customizations
  /js/
    glightbox-init.js      # Initialization script

/layouts/
  /shortcodes/
    lightbox.html          # Single image shortcode
    lightbox-gallery.html  # Gallery shortcode
  /partials/
    extend-head-uncached.html  # Conditional loading logic
```

## Further Customization

### Modify Thumbnail Size Globally

Edit `/layouts/shortcodes/lightbox.html` and `/layouts/shortcodes/lightbox-gallery.html`:

```go
{{- $thumbSize := .Get "thumb" | default "1200x800" -}}  // Change default
```

### Adjust Lightbox Behavior

Edit `/assets/js/glightbox-init.js` to modify settings:

```javascript
const lightbox = GLightbox({
  loop: true,              // Enable/disable looping
  zoomable: true,          // Enable/disable zoom
  draggable: true,         // Enable/disable drag
  slideEffect: 'slide',    // Change slide effect (slide, fade, zoom)
});
```

### Custom Styling

Edit `/assets/css/custom-lightbox.css` to adjust colors, transitions, or layout.

---

**Need Help?** Check the [GLightbox documentation](https://github.com/biati-digital/glightbox) for advanced features.
