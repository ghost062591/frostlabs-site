# House Project Images

## Adding Images to Your Gallery

1. **Place your images in this directory**: `/static/gallery/house-project/`

2. **Recommended naming convention**:
   - Use descriptive, lowercase names with hyphens
   - Examples: `kitchen-before.jpg`, `living-room-renovation-progress.jpg`, `bathroom-after.jpg`

3. **Image formats supported**: JPG, PNG, WebP

4. **Recommended image sizes**:
   - Width: 1200-2400px for high quality
   - Optimize images before uploading to reduce file size

## Adding Images to the Gallery

Edit `/content/gallery/house-project/index.md` and add images inside the `{{< gallery >}}` shortcode:

### Grid Layout Options

**Two-column layout (50% width each):**
```html
<img src="/gallery/house-project/image1.jpg" class="grid-w50" alt="Description" />
<img src="/gallery/house-project/image2.jpg" class="grid-w50" alt="Description" />
```

**Three-column layout (33% width each):**
```html
<img src="/gallery/house-project/image1.jpg" class="grid-w33" alt="Description" />
<img src="/gallery/house-project/image2.jpg" class="grid-w33" alt="Description" />
<img src="/gallery/house-project/image3.jpg" class="grid-w33" alt="Description" />
```

**Four-column layout (25% width each):**
```html
<img src="/gallery/house-project/image1.jpg" class="grid-w25" alt="Description" />
```

**Responsive layouts (changes based on screen size):**
```html
<!-- Full width on mobile, half on tablet, third on desktop -->
<img src="/gallery/house-project/image1.jpg" class="grid-w100 md:grid-w50 xl:grid-w33" alt="Description" />
```

### Example Gallery Section

```html
{{< gallery >}}
  <img src="/gallery/house-project/exterior-before.jpg" class="grid-w50 md:grid-w33" alt="Exterior - Before renovation" />
  <img src="/gallery/house-project/exterior-after.jpg" class="grid-w50 md:grid-w33" alt="Exterior - After renovation" />
  <img src="/gallery/house-project/kitchen-progress-1.jpg" class="grid-w50 md:grid-w33" alt="Kitchen renovation - Week 1" />
  <img src="/gallery/house-project/kitchen-progress-2.jpg" class="grid-w50 md:grid-w33" alt="Kitchen renovation - Week 2" />
  <img src="/gallery/house-project/kitchen-final.jpg" class="grid-w50 md:grid-w33" alt="Kitchen - Completed" />
{{< /gallery >}}
```

## Preview Your Changes

Run Hugo locally to preview:
```bash
hugo server -D
```

Then visit: http://localhost:1313/gallery/house-project/
