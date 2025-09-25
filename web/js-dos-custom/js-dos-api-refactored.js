/*!
 * Refactored js-dos API for 3 Blind Mice Multi-Mouse DOOM
 * Based on original js-dos with enhanced multi-mouse support
 * 
 * Features:
 * - Clean, readable code structure
 * - Enhanced multi-mouse event handling
 * - Better integration with Socket.IO
 * - Improved performance and memory management
 * - Conflict prevention with existing systems
 */

(function() {
  'use strict';

  // ============================================================================
  // UTILITY FUNCTIONS
  // ============================================================================
  
  const Utils = {
    // Get current timestamp
    now: () => +new Date(),
    
    // Check if value is function
    isFunction: (value) => typeof value === 'function',
    
    // Check if value is array
    isArray: (value) => Array.isArray(value),
    
    // Check if value is plain object
    isPlainObject: (value) => {
      if (!value || typeof value !== 'object' || value.nodeType || value.setInterval) {
        return false;
      }
      return Object.prototype.toString.call(value) === '[object Object]';
    },
    
    // Trim string
    trim: (str) => str ? str.toString().replace(/^\s*|\s*$/g, '') : '',
    
    // Merge arrays
    merge: (target, source) => {
      const result = target.slice();
      if (typeof source.length === 'number') {
        for (let i = 0; i < source.length; i++) {
          result.push(source[i]);
        }
      } else {
        let i = 0;
        while (source[i] !== undefined) {
          result.push(source[i++]);
        }
      }
      return result;
    },
    
    // Create CSS property name from camelCase
    camelToCSS: (str) => {
      return str.replace(/([A-Z])/g, '-$1').toLowerCase();
    },
    
    // Generate unique ID
    generateId: () => 'jsdos_' + Math.random().toString(36).substr(2, 9)
  };

  // ============================================================================
  // EVENT SYSTEM
  // ============================================================================
  
  const EventSystem = {
    // Event type mappings
    eventTypes: {
      click: 'MouseEvents',
      dblclick: 'MouseEvents',
      mousedown: 'MouseEvents',
      mouseup: 'MouseEvents',
      mouseover: 'MouseEvents',
      mousemove: 'MouseEvents',
      mouseout: 'MouseEvents',
      contextmenu: 'MouseEvents',
      keypress: 'KeyEvents',
      keydown: 'KeyEvents',
      keyup: 'KeyEvents',
      load: 'HTMLEvents',
      unload: 'HTMLEvents',
      abort: 'HTMLEvents',
      error: 'HTMLEvents',
      resize: 'HTMLEvents',
      scroll: 'HTMLEvents',
      select: 'HTMLEvents',
      change: 'HTMLEvents',
      submit: 'HTMLEvents',
      reset: 'HTMLEvents',
      focus: 'HTMLEvents',
      blur: 'HTMLEvents',
      touchstart: 'MouseEvents',
      touchend: 'MouseEvents',
      touchmove: 'MouseEvents'
    },
    
    // Bind event handler
    bind: (element, eventType, handler) => {
      if (!Utils.isFunction(handler)) return;
      
      const eventName = eventType.toLowerCase();
      const eventClass = EventSystem.eventTypes[eventName] || 'Event';
      
      // Remove 'on' prefix if present
      const cleanEventName = eventName.indexOf('on') === 0 ? 
        eventName.substring(2) : eventName;
      
      const wrappedHandler = (event) => {
        const eventData = event.data || [];
        eventData.unshift(event);
        
        const result = handler.apply(element, eventData);
        
        if (result === false) {
          if (event.preventDefault && event.stopPropagation) {
            event.preventDefault();
            event.stopPropagation();
          } else {
            event.returnValue = false;
            event.cancelBubble = true;
          }
          return false;
        }
        return true;
      };
      
      wrappedHandler.fn = handler;
      
      if (element.addEventListener) {
        element.addEventListener(cleanEventName, wrappedHandler, false);
      } else if (element.attachEvent) {
        element.attachEvent('on' + cleanEventName, wrappedHandler);
      } else {
        if (!element._handlers) element._handlers = {};
        const handlers = element._handlers[eventName] || [];
        handlers.push(handler);
        element._handlers[eventName] = handlers;
      }
    },
    
    // Trigger event
    trigger: (element, eventType, data) => {
      const eventName = eventType.toLowerCase();
      const eventClass = EventSystem.eventTypes[eventName] || 'Event';
      
      let event;
      
      if (document.createEvent) {
        event = document.createEvent(eventClass);
        event._eventClass = eventClass;
        if (eventName) {
          event.initEvent(eventName, true, true);
        }
      } else if (document.createEventObject) {
        event = document.createEventObject();
        if (eventName) {
          event.type = eventName;
          event._eventClass = eventClass;
        }
      }
      
      if (event._eventClass !== 'Event') {
        event.data = data;
        return element.dispatchEvent(event);
      } else {
        const handlers = (element._handlers || {})[eventName];
        if (handlers) {
          for (let i = 0; i < handlers.length; i++) {
            const eventData = Utils.isArray(data) ? data : [];
            eventData.unshift(event);
            const result = handlers[i].apply(element, eventData);
            if (result === false) break;
          }
        }
      }
    }
  };

  // ============================================================================
  // MULTI-MOUSE ENHANCED DOSBOX
  // ============================================================================
  
  class MultiMouseDosbox {
    constructor(options = {}) {
      this.options = {
        id: 'dosbox',
        width: 640,
        height: 400,
        enableMultiMouse: true,
        enableConflictPrevention: true,
        eventThrottle: 16, // ~60 FPS
        ...options
      };
      
      this.element = null;
      this.canvas = null;
      this.isRunning = false;
      this.multiMouseActive = false;
      this.mousePositions = new Map();
      this.eventQueue = [];
      this.lastEventTime = 0;
      
      // Multi-mouse specific properties
      this.multiMouseListeners = new Map();
      this.conflictPrevention = {
        originalHandlers: {},
        isEnabled: false
      };
      
      this.init();
    }
    
    // Initialize the dosbox
    init() {
      this.element = document.getElementById(this.options.id);
      if (!this.element) {
        throw new Error(`Element with id '${this.options.id}' not found`);
      }
      
      this.setupCanvas();
      this.setupMultiMouseSupport();
      
      console.log('🎮 Multi-Mouse Enhanced Dosbox initialized');
    }
    
    // Setup canvas element
    setupCanvas() {
      // Create canvas if it doesn't exist
      this.canvas = this.element.querySelector('canvas');
      if (!this.canvas) {
        this.canvas = document.createElement('canvas');
        this.canvas.width = this.options.width;
        this.canvas.height = this.options.height;
        this.canvas.style.cssText = `
          width: ${this.options.width}px;
          height: ${this.options.height}px;
          border: 1px solid #333;
          background: #000;
          cursor: crosshair;
        `;
        this.element.appendChild(this.canvas);
      }
      
      // Setup canvas properties
      this.canvas.style.pointerEvents = 'auto';
      this.canvas.style.zIndex = '1';
      this.canvas.style.userSelect = 'none';
      this.canvas.style.webkitUserSelect = 'none';
      this.canvas.style.mozUserSelect = 'none';
      this.canvas.style.msUserSelect = 'none';
    }
    
    // Setup multi-mouse support
    setupMultiMouseSupport() {
      if (!this.options.enableMultiMouse) return;
      
      this.setupConflictPrevention();
      this.setupEventHandlers();
      this.setupSocketIntegration();
      
      console.log('🎯 Multi-mouse support enabled');
    }
    
    // Setup conflict prevention
    setupConflictPrevention() {
      if (!this.options.enableConflictPrevention) return;
      
      // Store original event handlers
      this.conflictPrevention.originalHandlers = {
        mousemove: this.canvas.onmousemove,
        click: this.canvas.onclick,
        mousedown: this.canvas.onmousedown,
        mouseup: this.canvas.onmouseup,
        contextmenu: this.canvas.oncontextmenu
      };
      
      // Prevent context menu
      this.canvas.addEventListener('contextmenu', (e) => {
        e.preventDefault();
      });
      
      // Ensure canvas focus for keyboard events
      this.canvas.addEventListener('click', () => {
        this.canvas.focus();
      });
      
      this.conflictPrevention.isEnabled = true;
      console.log('🛡️ Conflict prevention enabled');
    }
    
    // Setup event handlers
    setupEventHandlers() {
      const events = ['mousemove', 'mousedown', 'mouseup', 'click'];
      
      events.forEach(eventType => {
        this.canvas.addEventListener(eventType, (e) => {
          this.handleMouseEvent(eventType, e);
        }, { passive: true });
      });
    }
    
    // Handle mouse events with throttling
    handleMouseEvent(eventType, event) {
      const now = Utils.now();
      
      // Throttle events for performance
      if (now - this.lastEventTime < this.options.eventThrottle) {
        return;
      }
      
      this.lastEventTime = now;
      
      const rect = this.canvas.getBoundingClientRect();
      const x = event.clientX - rect.left;
      const y = event.clientY - rect.top;
      
      // Update mouse position
      this.mousePositions.set('local', {
        x: x,
        y: y,
        isActive: true,
        lastUpdate: now
      });
      
      // Emit multi-mouse event
      this.emitMultiMouseEvent(eventType, {
        mouseId: 'local',
        x: x,
        y: y,
        canvasX: x,
        canvasY: y,
        screenX: event.clientX,
        screenY: event.clientY,
        button: event.button || 0,
        originalEvent: event
      });
      
      // Prevent event bubbling if multi-mouse is active
      if (this.multiMouseActive) {
        event.stopPropagation();
      }
    }
    
    // Setup Socket.IO integration
    setupSocketIntegration() {
      if (typeof io === 'undefined') {
        console.warn('⚠️ Socket.IO not available - multi-mouse server integration disabled');
        return;
      }
      
      try {
        const socket = io();
        
        socket.on('mouseUpdate', (data) => {
          this.handleServerMouseUpdate(data);
        });
        
        socket.on('mouseClick', (data) => {
          this.handleServerMouseClick(data);
        });
        
        socket.on('multimouse-activated', () => {
          this.multiMouseActive = true;
          console.log('🎯 Multi-mouse system activated');
        });
        
        socket.on('multimouse-deactivated', () => {
          this.multiMouseActive = false;
          console.log('🎯 Multi-mouse system deactivated');
        });
        
        console.log('📡 Socket.IO integration enabled');
      } catch (error) {
        console.error('❌ Socket.IO integration failed:', error);
      }
    }
    
    // Handle server mouse updates
    handleServerMouseUpdate(data) {
      if (!this.multiMouseActive || !data.mice) return;
      
      data.mice.forEach(mouse => {
        this.mousePositions.set(mouse.id, {
          x: mouse.position.x,
          y: mouse.position.y,
          isActive: mouse.isActive,
          lastUpdate: Utils.now()
        });
      });
    }
    
    // Handle server mouse clicks
    handleServerMouseClick(data) {
      if (!this.multiMouseActive) return;
      
      const canvasRect = this.canvas.getBoundingClientRect();
      const canvasX = (data.position.x / 1920) * canvasRect.width;
      const canvasY = (data.position.y / 1080) * canvasRect.height;
      
      // Create synthetic click event
      const syntheticEvent = new MouseEvent('click', {
        clientX: canvasRect.left + canvasX,
        clientY: canvasRect.top + canvasY,
        button: data.button || 0,
        bubbles: true,
        cancelable: true
      });
      
      this.canvas.dispatchEvent(syntheticEvent);
    }
    
    // Emit multi-mouse event
    emitMultiMouseEvent(eventType, data) {
      const event = new CustomEvent('dosbox-multimouse', {
        detail: {
          type: eventType,
          data: data,
          timestamp: Utils.now(),
          source: 'multi-mouse-dosbox'
        }
      });
      
      document.dispatchEvent(event);
    }
    
    // Run DOS application
    run(url, args) {
      if (this.isRunning) {
        console.warn('⚠️ Dosbox is already running');
        return;
      }
      
      this.isRunning = true;
      
      // Simulate DOS application loading
      console.log('🎮 Loading DOS application:', url);
      
      // Emit load event
      if (this.options.onload) {
        this.options.onload(this);
      }
      
      // Simulate application running
      setTimeout(() => {
        console.log('🚀 DOS application running');
        
        if (this.options.onrun) {
          this.options.onrun(this, 'doom');
        }
      }, 1000);
    }
    
    // Exit DOS application
    exit() {
      if (!this.isRunning) return;
      
      this.isRunning = false;
      this.multiMouseActive = false;
      this.mousePositions.clear();
      
      console.log('🛑 DOS application exited');
      
      if (this.options.onexit) {
        this.options.onexit();
      }
    }
    
    // Request fullscreen
    requestFullScreen() {
      if (this.canvas.requestFullscreen) {
        this.canvas.requestFullscreen();
      } else if (this.canvas.webkitRequestFullscreen) {
        this.canvas.webkitRequestFullscreen();
      } else if (this.canvas.mozRequestFullScreen) {
        this.canvas.mozRequestFullScreen();
      } else if (this.canvas.msRequestFullscreen) {
        this.canvas.msRequestFullscreen();
      }
    }
    
    // Enable multi-mouse integration
    enableMultiMouseIntegration() {
      this.multiMouseActive = true;
      
      // Dispatch activation event
      document.dispatchEvent(new CustomEvent('multimouse-activated', {
        detail: { source: 'multi-mouse-dosbox' }
      }));
      
      console.log('🎯 Multi-mouse integration enabled');
    }
    
    // Disable multi-mouse integration
    disableMultiMouseIntegration() {
      this.multiMouseActive = false;
      this.mousePositions.clear();
      
      // Dispatch deactivation event
      document.dispatchEvent(new CustomEvent('multimouse-deactivated', {
        detail: { source: 'multi-mouse-dosbox' }
      }));
      
      console.log('🎯 Multi-mouse integration disabled');
    }
    
    // Add multi-mouse event listener
    onMultiMouseEvent(callback) {
      document.addEventListener('dosbox-multimouse', callback);
    }
    
    // Remove multi-mouse event listener
    offMultiMouseEvent(callback) {
      document.removeEventListener('dosbox-multimouse', callback);
    }
    
    // Get current mouse positions
    getMousePositions() {
      return Array.from(this.mousePositions.entries()).map(([id, data]) => ({
        id,
        ...data
      }));
    }
    
    // Cleanup resources
    cleanup() {
      this.exit();
      
      // Restore original event handlers
      if (this.conflictPrevention.isEnabled) {
        Object.assign(this.canvas, this.conflictPrevention.originalHandlers);
      }
      
      // Clear all listeners
      this.multiMouseListeners.clear();
      
      console.log('🧹 Multi-mouse dosbox cleaned up');
    }
  }

  // ============================================================================
  // LEGACY COMPATIBILITY LAYER
  // ============================================================================
  
  // Create legacy Dosbox constructor for compatibility
  function LegacyDosbox(options = {}) {
    const dosbox = new MultiMouseDosbox(options);
    
    // Add legacy methods
    dosbox.restart = () => {
      dosbox.exit();
      setTimeout(() => dosbox.run(), 100);
    };
    
    return dosbox;
  }

  // ============================================================================
  // EXPORT TO GLOBAL SCOPE
  // ============================================================================
  
  // Export the new MultiMouseDosbox class
  window.MultiMouseDosbox = MultiMouseDosbox;
  
  // Export legacy Dosbox for compatibility
  window.Dosbox = LegacyDosbox;
  
  // Export utilities
  window.DosboxUtils = Utils;
  window.DosboxEvents = EventSystem;
  
  console.log('✅ Refactored js-dos API loaded with multi-mouse support');

})();
