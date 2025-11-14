// Content script for TempMail Extension - handles form detection and autofill

class AutofillManager {
    constructor() {
        this.isEnabled = true;
        this.currentEmail = null;
        this.exceptions = [];
        this.autofillButton = null;
        this.currentEmailField = null;
        
        this.init();
    }

    async init() {
        await this.loadSettings();
        this.setupMessageListener();
        
        if (this.isEnabled && !this.isExcludedDomain()) {
            this.startEmailFieldDetection();
        }
    }

    async loadSettings() {
        try {
            const response = await chrome.runtime.sendMessage({
                action: 'getAutofillSettings'
            });
            
            if (response && response.success) {
                this.isEnabled = response.data.enabled;
                this.exceptions = response.data.exceptions || [];
                this.currentEmail = response.data.email;
            }
        } catch (error) {
            console.error('Error loading autofill settings:', error);
        }
    }

    setupMessageListener() {
        chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
            switch (request.action) {
                case 'toggleAutofill':
                    this.isEnabled = request.enabled;
                    this.currentEmail = request.email;
                    
                    if (this.isEnabled && !this.isExcludedDomain()) {
                        this.startEmailFieldDetection();
                    } else {
                        this.stopEmailFieldDetection();
                    }
                    break;

                case 'settingsUpdated':
                    this.isEnabled = request.settings.autofillEnabled !== false;
                    this.exceptions = request.settings.exceptions || [];
                    this.currentEmail = request.settings.currentEmail;
                    
                    if (this.isEnabled && !this.isExcludedDomain()) {
                        this.startEmailFieldDetection();
                    } else {
                        this.stopEmailFieldDetection();
                    }
                    break;
            }
            
            sendResponse({ success: true });
        });
    }

    isExcludedDomain() {
        const hostname = window.location.hostname.toLowerCase();
        return this.exceptions.some(exception => {
            const cleanException = exception.toLowerCase().replace(/^https?:\/\//, '').replace(/\/.*$/, '');
            return hostname === cleanException || hostname.endsWith('.' + cleanException);
        });
    }

    startEmailFieldDetection() {
        if (this.isExcludedDomain()) return;

        // Detect existing email fields
        this.detectEmailFields();
        
        // Watch for dynamically added email fields
        this.setupFieldObserver();
        
        // Add focus listeners to existing fields
        this.addFieldListeners();
    }

    stopEmailFieldDetection() {
        this.removeAutofillButton();
        this.removeFieldListeners();
        
        if (this.fieldObserver) {
            this.fieldObserver.disconnect();
            this.fieldObserver = null;
        }
    }

    detectEmailFields() {
        const emailFields = this.getEmailFields();
        
        emailFields.forEach(field => {
            if (!field.dataset.tempMailProcessed) {
                field.dataset.tempMailProcessed = 'true';
                this.processEmailField(field);
            }
        });
    }

    getEmailFields() {
        const selectors = [
            'input[type="email"]',
            'input[name*="email" i]',
            'input[id*="email" i]',
            'input[placeholder*="email" i]',
            'input[autocomplete*="email"]'
        ];
        
        const fields = [];
        selectors.forEach(selector => {
            const elements = document.querySelectorAll(selector);
            elements.forEach(el => {
                if (el.type !== 'hidden' && !fields.includes(el)) {
                    fields.push(el);
                }
            });
        });
        
        return fields;
    }

    processEmailField(field) {
        // Add focus listener to show autofill button
        field.addEventListener('focus', (e) => {
            this.showAutofillButton(e.target);
        });
        
        field.addEventListener('blur', (e) => {
            // Hide button after a short delay to allow clicking
            setTimeout(() => {
                if (this.autofillButton && !this.autofillButton.matches(':hover')) {
                    this.removeAutofillButton();
                }
            }, 200);
        });
    }

    showAutofillButton(field) {
        if (!this.isEnabled || !this.currentEmail || this.isExcludedDomain()) {
            return;
        }

        this.currentEmailField = field;
        this.removeAutofillButton(); // Remove any existing button
        
        // Create autofill button
        this.autofillButton = document.createElement('div');
        this.autofillButton.id = 'tempmail-autofill-btn';
        
        // Use the provided image as background
        const imageUrl = chrome.runtime.getURL('autofill-icon.png');
        this.autofillButton.style.backgroundImage = `url("${imageUrl}")`;
        
        // Add styles matching the screenshot design
        this.autofillButton.style.cssText = `
            position: absolute;
            z-index: 999999;
            background-image: url("${imageUrl}");
            background-size: contain;
            background-repeat: no-repeat;
            background-position: center;
            padding: 0;
            border-radius: 50%;
            width: 32px;
            height: 32px;
            cursor: pointer;
            box-shadow: 0 2px 8px rgba(26, 115, 232, 0.3);
            border: none;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.2s ease;
            user-select: none;
        `;
        
        // Position the button
        this.positionAutofillButton(field);
        
        // Add click handler
        this.autofillButton.addEventListener('click', (e) => {
            e.preventDefault();
            e.stopPropagation();
            this.fillEmailField(field);
        });
        
        // Add hover effects for the image-based button
        this.autofillButton.addEventListener('mouseenter', () => {
            this.autofillButton.style.transform = 'scale(1.1)';
            this.autofillButton.style.boxShadow = '0 4px 12px rgba(26, 115, 232, 0.4)';
            this.autofillButton.style.filter = 'brightness(1.1)';
        });
        
        this.autofillButton.addEventListener('mouseleave', () => {
            this.autofillButton.style.transform = 'scale(1)';
            this.autofillButton.style.boxShadow = '0 2px 8px rgba(26, 115, 232, 0.3)';
            this.autofillButton.style.filter = 'brightness(1)';
        });
        
        document.body.appendChild(this.autofillButton);
    }

    positionAutofillButton(field) {
        if (!this.autofillButton) return;
        
        const rect = field.getBoundingClientRect();
        const scrollY = window.pageYOffset;
        const scrollX = window.pageXOffset;
        
        let top = rect.bottom + scrollY + 5;
        let left = rect.left + scrollX;
        
        // Check if button would go off screen
        const buttonWidth = 32; // Circular button width
        const buttonHeight = 32; // Circular button height
        
        // Position the circular button inside the input field (like the screenshot)
        left = rect.right + scrollX - buttonWidth - 8; // Inside right edge
        top = rect.top + scrollY + (rect.height - buttonHeight) / 2; // Vertically centered
        
        // Ensure it doesn't go off screen
        if (left < scrollX) {
            left = rect.left + scrollX + 8;
        }
        if (top < scrollY) {
            top = rect.bottom + scrollY + 5;
        }
        
        this.autofillButton.style.top = `${top}px`;
        this.autofillButton.style.left = `${left}px`;
    }

    fillEmailField(field) {
        if (!this.currentEmail) return;
        
        // Fill the field
        field.value = this.currentEmail;
        field.focus();
        
        // Trigger input events to ensure form validation works
        const events = ['input', 'change', 'blur'];
        events.forEach(eventType => {
            const event = new Event(eventType, { bubbles: true });
            field.dispatchEvent(event);
        });
        
        // Show success feedback
        this.showAutofillFeedback();
        
        // Remove the button
        setTimeout(() => {
            this.removeAutofillButton();
        }, 100);
    }

    showAutofillFeedback() {
        if (!this.autofillButton) return;
        
        const originalBackgroundImage = this.autofillButton.style.backgroundImage;
        const originalColor = this.autofillButton.style.backgroundColor;
        
        // Show checkmark feedback
        this.autofillButton.innerHTML = `
            <div style="
                color: white; 
                font-size: 16px; 
                font-weight: bold;
                display: flex;
                align-items: center;
                justify-content: center;
                width: 100%;
                height: 100%;
            ">✓</div>
        `;
        this.autofillButton.style.backgroundColor = '#10b981';
        this.autofillButton.style.backgroundImage = 'none';
        
        setTimeout(() => {
            if (this.autofillButton) {
                this.autofillButton.innerHTML = '';
                this.autofillButton.style.backgroundColor = originalColor;
                this.autofillButton.style.backgroundImage = originalBackgroundImage;
            }
        }, 1500);
    }

    removeAutofillButton() {
        if (this.autofillButton) {
            this.autofillButton.remove();
            this.autofillButton = null;
        }
        this.currentEmailField = null;
    }

    setupFieldObserver() {
        this.fieldObserver = new MutationObserver((mutations) => {
            let shouldDetect = false;
            
            mutations.forEach((mutation) => {
                if (mutation.type === 'childList') {
                    mutation.addedNodes.forEach((node) => {
                        if (node.nodeType === Node.ELEMENT_NODE) {
                            // Check if the added node contains email fields
                            const emailFields = node.querySelectorAll ? 
                                this.getEmailFieldsInElement(node) : [];
                            
                            if (emailFields.length > 0 || this.isEmailField(node)) {
                                shouldDetect = true;
                            }
                        }
                    });
                }
            });
            
            if (shouldDetect) {
                setTimeout(() => this.detectEmailFields(), 100);
            }
        });
        
        this.fieldObserver.observe(document.body, {
            childList: true,
            subtree: true
        });
    }

    getEmailFieldsInElement(element) {
        if (!element.querySelectorAll) return [];
        
        const selectors = [
            'input[type="email"]',
            'input[name*="email" i]',
            'input[id*="email" i]',
            'input[placeholder*="email" i]',
            'input[autocomplete*="email"]'
        ];
        
        const fields = [];
        selectors.forEach(selector => {
            const elements = element.querySelectorAll(selector);
            elements.forEach(el => {
                if (el.type !== 'hidden' && !fields.includes(el)) {
                    fields.push(el);
                }
            });
        });
        
        return fields;
    }

    isEmailField(element) {
        if (!element || element.tagName !== 'INPUT') return false;
        
        const type = element.type ? element.type.toLowerCase() : '';
        const name = element.name ? element.name.toLowerCase() : '';
        const id = element.id ? element.id.toLowerCase() : '';
        const placeholder = element.placeholder ? element.placeholder.toLowerCase() : '';
        const autocomplete = element.autocomplete ? element.autocomplete.toLowerCase() : '';
        
        return type === 'email' ||
               name.includes('email') ||
               id.includes('email') ||
               placeholder.includes('email') ||
               autocomplete.includes('email');
    }

    addFieldListeners() {
        // Add listeners to handle window resize and scroll
        window.addEventListener('resize', this.handleWindowChange.bind(this));
        window.addEventListener('scroll', this.handleWindowChange.bind(this));
    }

    removeFieldListeners() {
        window.removeEventListener('resize', this.handleWindowChange.bind(this));
        window.removeEventListener('scroll', this.handleWindowChange.bind(this));
    }

    handleWindowChange() {
        if (this.autofillButton && this.currentEmailField) {
            this.positionAutofillButton(this.currentEmailField);
        }
    }
}

// Initialize autofill manager when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        new AutofillManager();
    });
} else {
    new AutofillManager();
}

// Handle page navigation (for SPAs)
let lastUrl = location.href;
new MutationObserver(() => {
    const url = location.href;
    if (url !== lastUrl) {
        lastUrl = url;
        // Reinitialize on navigation
        setTimeout(() => {
            new AutofillManager();
        }, 1000);
    }
}).observe(document, { subtree: true, childList: true });