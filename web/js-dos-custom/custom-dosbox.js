/*!
 * Custom js-dos wrapper for 3 Blind Mice Multi-Mouse DOOM
 * Based on js-dos API with enhanced multi-mouse support
 * 
 * Features:
 * - Multi-mouse cursor overlay support
 * - Enhanced event handling for multiple mice
 * - Better integration with Socket.IO
 * - Customizable cursor rendering
 */

(function() {
  'use strict';

  // Custom Dosbox wrapper with multi-mouse enhancements
  window.CustomDosbox = function(options) {
    this.options = options || {};
    this.id = options.id || 'dosbox';
    this.element = document.getElementById(this.id);
    this.dosbox = null;
    this.multiMouseEnabled = true;
    this.cursorOverlays = new Map();
    
    // Initialize the original js-dos
    this.init();
  };

  CustomDosbox.prototype.init = function() {
    // Load the original js-dos API
    if (typeof Dosbox === 'undefined') {
      this.loadJsDosAPI();
    } else {
      this.createDosbox();
    }
  };

  CustomDosbox.prototype.loadJsDosAPI = function() {
    // Use the refactored API if available, otherwise load from CDN
    if (typeof MultiMouseDosbox !== 'undefined') {
      console.log('🎯 Using refactored MultiMouseDosbox API');
      this.createDosbox();
    } else {
      const script = document.createElement('script');
      script.src = 'https://js-dos.com/cdn/js-dos-api.js';
      script.onload = () => {
        this.createDosbox();
      };
      script.onerror = () => {
        console.error('Failed to load js-dos API');
      };
      document.head.appendChild(script);
    }
  };

  CustomDosbox.prototype.createDosbox = function() {
    // Use refactored MultiMouseDosbox if available, otherwise fallback to original
    if (typeof MultiMouseDosbox !== 'undefined') {
      console.log('🎯 Creating MultiMouseDosbox instance');
      this.dosbox = new MultiMouseDosbox({
        id: this.id,
        enableMultiMouse: true,
        enableConflictPrevention: true,
        onload: (dosbox) => {
          console.log('🎮 Custom DOOM loading...');
          if (this.options.onload) {
            this.options.onload(dosbox);
          }
        },
        onrun: (dosbox, app) => {
          console.log('🚀 Custom DOOM is running!');
          this.setupMultiMouseSupport();
          if (this.options.onrun) {
            this.options.onrun(dosbox, app);
          }
        },
        onerror: (error) => {
          console.error('❌ Custom DOOM Error:', error);
          if (this.options.onerror) {
            this.options.onerror(error);
          }
        }
      });
    } else {
      // Fallback to original Dosbox
      console.log('🎯 Creating original Dosbox instance');
      this.dosbox = new Dosbox({
        id: this.id,
        onload: (dosbox) => {
          console.log('🎮 Custom DOOM loading...');
          if (this.options.onload) {
            this.options.onload(dosbox);
          }
        },
        onrun: (dosbox, app) => {
          console.log('🚀 Custom DOOM is running!');
          this.setupMultiMouseSupport();
          if (this.options.onrun) {
            this.options.onrun(dosbox, app);
          }
        },
        onerror: (error) => {
          console.error('❌ Custom DOOM Error:', error);
          if (this.options.onerror) {
            this.options.onerror(error);
          }
        }
      });
    }
  };

  CustomDosbox.prototype.setupMultiMouseSupport = function() {
    // Enhance the canvas for multi-mouse support
    setTimeout(() => {
      const canvas = this.element.querySelector('canvas');
      if (canvas) {
        // Make canvas multi-mouse aware
        canvas.style.pointerEvents = 'auto';
        canvas.style.zIndex = '1';
        
        // Setup conflict prevention first
        this.setupCanvasConflictPrevention();
        
        // Add custom event listeners for multi-mouse
        this.addMultiMouseListeners(canvas);
        
        // Enable multi-mouse integration
        this.enableMultiMouseIntegration();
        
        console.log('🎯 Multi-mouse support enabled for DOOM canvas');
      }
    }, 1000);
  };

  CustomDosbox.prototype.addMultiMouseListeners = function(canvas) {
    // Track multiple mouse positions from 3 Blind Mice server
    const mousePositions = new Map();
    let lastMouseId = 'primary';
    let isMultiMouseActive = false;
    
    // Prevent conflicts with existing multi-mouse systems
    const originalCanvasEvents = {
      mousemove: null,
      click: null,
      mousedown: null,
      mouseup: null
    };
    
    // Store original event handlers to prevent conflicts
    const storeOriginalEvents = () => {
      originalCanvasEvents.mousemove = canvas.onmousemove;
      originalCanvasEvents.click = canvas.onclick;
      originalCanvasEvents.mousedown = canvas.onmousedown;
      originalCanvasEvents.mouseup = canvas.onmouseup;
    };
    
    // Restore original event handlers
    const restoreOriginalEvents = () => {
      canvas.onmousemove = originalCanvasEvents.mousemove;
      canvas.onclick = originalCanvasEvents.click;
      canvas.onmousedown = originalCanvasEvents.mousedown;
      canvas.onmouseup = originalCanvasEvents.mouseup;
    };
    
    // Enhanced event handling with conflict prevention
    const handleMouseEvent = (eventType, e) => {
      // Check if multi-mouse system is active
      if (!isMultiMouseActive) {
        return; // Let original DOOM handle events
      }
      
      const rect = canvas.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      
      // Update local mouse position
      lastMouseId = 'local';
      mousePositions.set(lastMouseId, { x, y, isActive: true });
      
      // Emit custom event for multi-mouse tracking
      this.emitMultiMouseEvent(eventType, {
        mouseId: lastMouseId,
        x: x,
        y: y,
        canvasX: x,
        canvasY: y,
        screenX: e.clientX,
        screenY: e.clientY,
        button: e.button || 0,
        originalEvent: e
      });
      
      // Prevent event bubbling to avoid conflicts
      e.stopPropagation();
    };
    
    // Listen for multi-mouse system activation
    document.addEventListener('multimouse-activated', () => {
      isMultiMouseActive = true;
      console.log('🎯 Multi-mouse system activated for DOOM');
    });
    
    document.addEventListener('multimouse-deactivated', () => {
      isMultiMouseActive = false;
      console.log('🎯 Multi-mouse system deactivated for DOOM');
    });
    
    // Enhanced mouse move handler for local mouse
    canvas.addEventListener('mousemove', (e) => {
      handleMouseEvent('mousemove', e);
    }, { passive: true });

    // Enhanced click handler for local mouse
    canvas.addEventListener('click', (e) => {
      handleMouseEvent('click', e);
    }, { passive: true });
    
    // Enhanced mouse down handler
    canvas.addEventListener('mousedown', (e) => {
      handleMouseEvent('mousedown', e);
    }, { passive: true });
    
    // Enhanced mouse up handler
    canvas.addEventListener('mouseup', (e) => {
      handleMouseEvent('mouseup', e);
    }, { passive: true });
    
    // Listen for external multi-mouse updates (from 3 Blind Mice server)
    // Only if Socket.IO is available and multi-mouse is active
    if (typeof io !== 'undefined' && isMultiMouseActive) {
      const socket = io();
      
      socket.on('mouseUpdate', (data) => {
        if (data.mice && isMultiMouseActive) {
          data.mice.forEach(mouse => {
            mousePositions.set(mouse.id, {
              x: mouse.position.x,
              y: mouse.position.y,
              isActive: mouse.isActive
            });
          });
        }
      });
      
      socket.on('mouseClick', (data) => {
        if (!isMultiMouseActive) return;
        
        // Forward click events to DOOM with proper coordinate mapping
        const canvasRect = canvas.getBoundingClientRect();
        const canvasX = (data.position.x / 1920) * canvasRect.width;
        const canvasY = (data.position.y / 1080) * canvasRect.height;
        
        // Create synthetic click event for DOOM
        const syntheticEvent = new MouseEvent('click', {
          clientX: canvasRect.left + canvasX,
          clientY: canvasRect.top + canvasY,
          button: data.button || 0,
          bubbles: true,
          cancelable: true
        });
        
        // Dispatch to canvas with proper event handling
        canvas.dispatchEvent(syntheticEvent);
      });
    }
    
    // Periodically emit multi-mouse events for all tracked mice
    // Only when multi-mouse system is active
    setInterval(() => {
      if (isMultiMouseActive) {
        mousePositions.forEach((position, mouseId) => {
          if (position.isActive) {
            this.emitMultiMouseEvent('mousemove', {
              mouseId: mouseId,
              x: position.x,
              y: position.y,
              canvasX: position.x,
              canvasY: position.y,
              screenX: position.x,
              screenY: position.y
            });
          }
        });
      }
    }, 16); // ~60 FPS
    
    // Cleanup function
    this.cleanupMultiMouse = () => {
      isMultiMouseActive = false;
      mousePositions.clear();
      restoreOriginalEvents();
    };
  };

  CustomDosbox.prototype.emitMultiMouseEvent = function(eventType, data) {
    // Emit custom event for external multi-mouse systems
    const event = new CustomEvent('dosbox-multimouse', {
      detail: {
        type: eventType,
        data: data,
        timestamp: Date.now()
      }
    });
    
    document.dispatchEvent(event);
  };

  CustomDosbox.prototype.addCursorOverlay = function(mouseId, x, y, color = '#ff0000') {
    // Add a visual cursor overlay for a specific mouse
    const overlay = document.createElement('div');
    overlay.className = 'dosbox-cursor-overlay';
    overlay.style.cssText = `
      position: absolute;
      left: ${x}px;
      top: ${y}px;
      width: 20px;
      height: 20px;
      border: 2px solid ${color};
      border-radius: 50%;
      pointer-events: none;
      z-index: 1000;
      transform: translate(-50%, -50%);
    `;
    
    this.element.appendChild(overlay);
    this.cursorOverlays.set(mouseId, overlay);
    
    return overlay;
  };

  CustomDosbox.prototype.updateCursorOverlay = function(mouseId, x, y) {
    const overlay = this.cursorOverlays.get(mouseId);
    if (overlay) {
      overlay.style.left = x + 'px';
      overlay.style.top = y + 'px';
    }
  };

  CustomDosbox.prototype.removeCursorOverlay = function(mouseId) {
    const overlay = this.cursorOverlays.get(mouseId);
    if (overlay) {
      overlay.remove();
      this.cursorOverlays.delete(mouseId);
    }
  };

  CustomDosbox.prototype.clearAllCursorOverlays = function() {
    this.cursorOverlays.forEach((overlay, mouseId) => {
      this.removeCursorOverlay(mouseId);
    });
  };

  // Proxy methods to original dosbox
  CustomDosbox.prototype.run = function(url, args) {
    if (this.dosbox) {
      return this.dosbox.run(url, args);
    }
  };

  CustomDosbox.prototype.exit = function() {
    this.clearAllCursorOverlays();
    if (this.dosbox) {
      return this.dosbox.exit();
    }
  };

  CustomDosbox.prototype.restart = function() {
    this.clearAllCursorOverlays();
    if (this.dosbox) {
      return this.dosbox.restart();
    }
  };

  CustomDosbox.prototype.requestFullScreen = function() {
    if (this.dosbox) {
      return this.dosbox.requestFullScreen();
    }
  };

  // Multi-mouse event listener setup
  CustomDosbox.prototype.onMultiMouseEvent = function(callback) {
    document.addEventListener('dosbox-multimouse', callback);
  };

  CustomDosbox.prototype.offMultiMouseEvent = function(callback) {
    document.removeEventListener('dosbox-multimouse', callback);
  };
  
  // Integration with DOOM page multi-mouse system
  CustomDosbox.prototype.enableMultiMouseIntegration = function() {
    // Dispatch activation event
    document.dispatchEvent(new CustomEvent('multimouse-activated', {
      detail: { source: 'custom-dosbox' }
    }));
    
    console.log('🎯 Custom DOOM multi-mouse integration enabled');
  };
  
  CustomDosbox.prototype.disableMultiMouseIntegration = function() {
    // Dispatch deactivation event
    document.dispatchEvent(new CustomEvent('multimouse-deactivated', {
      detail: { source: 'custom-dosbox' }
    }));
    
    // Cleanup multi-mouse resources
    if (this.cleanupMultiMouse) {
      this.cleanupMultiMouse();
    }
    
    console.log('🎯 Custom DOOM multi-mouse integration disabled');
  };
  
  // Enhanced canvas event handling to prevent conflicts
  CustomDosbox.prototype.setupCanvasConflictPrevention = function() {
    const canvas = this.element.querySelector('canvas');
    if (!canvas) return;
    
    // Prevent default browser behaviors that might conflict
    canvas.addEventListener('contextmenu', (e) => {
      e.preventDefault();
    });
    
    // Ensure canvas receives focus for keyboard events
    canvas.addEventListener('click', () => {
      canvas.focus();
    });
    
    // Prevent text selection on canvas
    canvas.style.userSelect = 'none';
    canvas.style.webkitUserSelect = 'none';
    canvas.style.mozUserSelect = 'none';
    canvas.style.msUserSelect = 'none';
    
    console.log('🛡️ Canvas conflict prevention enabled');
  };

  // Export for global use
  window.CustomDosbox = CustomDosbox;

})();
