/**
 * GLightbox Initialization
 *
 * Initializes GLightbox for all lightbox galleries and individual lightbox images.
 * Provides fullscreen image viewing with navigation, captions, and keyboard controls.
 */

document.addEventListener('DOMContentLoaded', function() {
  // Initialize GLightbox for all .glightbox elements
  if (typeof GLightbox !== 'undefined') {
    const lightbox = GLightbox({
      touchNavigation: true,
      loop: true,
      autoplayVideos: false,
      closeButton: true,
      closeOnOutsideClick: true,
      keyboardNavigation: true,
      draggable: true,
      dragToleranceX: 80,
      dragToleranceY: 120,
      // Dark theme overlay
      skin: 'clean',
      // Zoom settings
      zoomable: true,
      // Slide effect
      openEffect: 'fade',
      closeEffect: 'fade',
      slideEffect: 'slide',
      // Description handling
      descPosition: 'bottom',
      // Mobile settings
      moreLength: 0,
      // Callbacks
      onOpen: function() {
        console.log('Lightbox opened');
      },
      onClose: function() {
        console.log('Lightbox closed');
      }
    });

    console.log('GLightbox initialized with', document.querySelectorAll('.glightbox').length, 'images');
  } else {
    console.error('GLightbox library not loaded');
  }
});
