// Background script for TempMail Extension

class BackgroundService {
    constructor() {
        this.setupEventListeners();
        this.checkFirstInstall();
        this.pollingInterval = null;
        this.startBackgroundPolling();
    }

    setupEventListeners() {
        // Handle extension installation
        chrome.runtime.onInstalled.addListener((details) => {
            if (details.reason === 'install') {
                this.handleInstall();
            } else if (details.reason === 'update') {
                this.handleUpdate();
            }
        });

        // Handle messages from content scripts and popup
        chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
            this.handleMessage(request, sender, sendResponse);
            return true; // Keep message channel open for async response
        });

        // Handle extension uninstall (Chrome only)
        if (chrome.runtime.setUninstallURL) {
            chrome.runtime.setUninstallURL('https://tempmail.pw/uninstall/?utm_campaign=tm2mobile&utm_source=chrome&utm_medium=extention_uninstall');
        }
    }

    async handleInstall() {
        try {
            // Open install page
            await chrome.tabs.create({
                url: 'https://tempmail.pw/install-success/?utm_campaign=tm2mobile&utm_source=chrome&utm_medium=extention_install'
            });

            // Initialize default settings
            await chrome.storage.local.set({
                autofillEnabled: true,
                exceptions: [],
                firstRun: true
            });

            console.log('TempMail extension installed successfully');
        } catch (error) {
            console.error('Error handling installation:', error);
        }
    }

    async handleUpdate() {
        console.log('TempMail extension updated');
        // Handle any update-specific logic here
    }

    async handleMessage(request, sender, sendResponse) {
        try {
            switch (request.action) {
                case 'getAutofillSettings':
                    const settings = await this.getAutofillSettings();
                    sendResponse({ success: true, data: settings });
                    break;

                case 'updateAutofillSettings':
                    await this.updateAutofillSettings(request.settings);
                    sendResponse({ success: true });
                    break;

                case 'generateEmail':
                    const email = await this.generateEmail();
                    sendResponse({ success: true, email });
                    break;

                case 'updateBadge':
                    await this.updateBadge(request.count);
                    sendResponse({ success: true });
                    break;

                case 'deleteEmail':
                    const deleted = await this.deleteEmail(request.token);
                    sendResponse({ success: true, deleted });
                    break;

                case 'getMessages':
                    const messages = await this.getMessages(request.token);
                    sendResponse({ success: true, messages });
                    break;

                case 'getMessage':
                    const message = await this.getMessage(request.messageId);
                    sendResponse({ success: true, message });
                    break;

                case 'openEmailPage':
                    await this.openEmailPage(request.token);
                    sendResponse({ success: true });
                    break;

                case 'showNotification':
                    await this.showSimpleNotification(request.email, request.count);
                    sendResponse({ success: true });
                    break;

                default:
                    sendResponse({ success: false, error: 'Unknown action' });
            }
        } catch (error) {
            console.error('Error handling message:', error);
            sendResponse({ success: false, error: error.message });
        }
    }

    async checkFirstInstall() {
        try {
            const result = await chrome.storage.local.get(['firstRun']);
            if (result.firstRun) {
                // Clear first run flag
                await chrome.storage.local.set({ firstRun: false });
            }
        } catch (error) {
            console.error('Error checking first install:', error);
        }
    }

    async getAutofillSettings() {
        try {
            const result = await chrome.storage.local.get(['autofillEnabled', 'exceptions', 'currentEmail']);
            return {
                enabled: result.autofillEnabled !== false,
                exceptions: result.exceptions || [],
                email: result.currentEmail || null
            };
        } catch (error) {
            console.error('Error getting autofill settings:', error);
            return { enabled: true, exceptions: [], email: null };
        }
    }

    async updateAutofillSettings(settings) {
        try {
            await chrome.storage.local.set(settings);
            
            // Notify all content scripts about the change
            const tabs = await chrome.tabs.query({});
            for (const tab of tabs) {
                try {
                    await chrome.tabs.sendMessage(tab.id, {
                        action: 'settingsUpdated',
                        settings
                    });
                } catch (error) {
                    // Tab might not have content script, ignore
                }
            }
        } catch (error) {
            console.error('Error updating autofill settings:', error);
            throw error;
        }
    }

    async generateEmail() {
        const apiKey = 'Lt6zDdQ3bbp8hU5PiSONwnoWUYXU5CALiOKBhi';
        const baseUrl = 'https://tempmail.pw/api';

        try {
            // Get available domains
            const domainsResponse = await fetch(`${baseUrl}/domains/${apiKey}`);
            const domains = await domainsResponse.json();
            
            if (!domains || !domains.length) {
                throw new Error('No domains available');
            }

            // Generate random email
            const randomName = this.generateRandomString(8);
            const domain = domains[0];
            const email = `${randomName}@${domain}`;
            
            // For TempMail.pw API, the token is the email address itself
            const token = email;

            // Store the email and clear previous messages
            await chrome.storage.local.set({
                currentEmail: email,
                currentToken: token,
                messages: [],
                lastMessageCount: 0
            });

            console.log('Generated new email:', email);
            return { email, token };
        } catch (error) {
            console.error('Error generating email:', error);
            throw error;
        }
    }

    async deleteEmail(token) {
        const apiKey = 'Lt6zDdQ3bbp8hU5PiSONwnoWUYXU5CALiOKBhi';
        const baseUrl = 'https://tempmail.pw/api';

        try {
            const response = await fetch(`${baseUrl}/email/delete/${token}/${apiKey}`);
            
            if (response.ok) {
                // Clear stored email data
                await chrome.storage.local.remove(['currentEmail', 'currentToken']);
                return true;
            }
            
            return false;
        } catch (error) {
            console.error('Error deleting email:', error);
            return false;
        }
    }

    async getMessages(token) {
        return await this.apiCall('messages', token);
    }

    async apiCall(endpoint, token, options = {}) {
        const apiKey = 'Lt6zDdQ3bbp8hU5PiSONwnoWUYXU5CALiOKBhi';
        const baseUrl = 'https://tempmail.pw/api';
        const maxRetries = options.maxRetries || 3;
        const initialDelay = options.initialDelay || 1000;
        
        let lastError = null;
        
        for (let attempt = 0; attempt <= maxRetries; attempt++) {
            try {
                const response = await fetch(`${baseUrl}/${endpoint}/${token}/${apiKey}`, {
                    method: options.method || 'GET',
                    headers: {
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                        'Accept': 'application/json, text/plain, */*',
                        'Cache-Control': 'no-cache',
                        ...options.headers
                    }
                });
                
                if (response.status === 429) {
                    const retryAfter = parseInt(response.headers.get('retry-after') || '60');
                    console.log(`Rate limited (attempt ${attempt + 1}/${maxRetries + 1}), waiting ${retryAfter}s`);
                    
                    if (attempt < maxRetries) {
                        await this.sleep(retryAfter * 1000);
                        continue;
                    }
                    
                    return { error: 'rate_limited', retryAfter };
                }
                
                if (!response.ok) {
                    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                }
                
                const responseText = await response.text();
                
                // Check for HTML error pages
                if (responseText.trim().startsWith('<!DOCTYPE') || responseText.includes('<html')) {
                    throw new Error('API returned HTML page - service may be unavailable');
                }
                
                let data;
                try {
                    data = JSON.parse(responseText);
                } catch (parseError) {
                    throw new Error(`Invalid JSON response: ${parseError.message}`);
                }
                
                // Handle different response formats
                if (endpoint === 'messages') {
                    if (Array.isArray(data)) {
                        return data;
                    } else if (data && data.message) {
                        if (data.message.includes('No messages found') || data.message.includes('not found')) {
                            return []; // No messages found is normal
                        }
                        throw new Error(`API message: ${data.message}`);
                    }
                    return [];
                }
                
                return data;
                
            } catch (error) {
                lastError = error;
                console.error(`API call failed (attempt ${attempt + 1}/${maxRetries + 1}):`, error.message);
                
                if (attempt < maxRetries) {
                    // Exponential backoff with jitter
                    const delay = initialDelay * Math.pow(2, attempt) + Math.random() * 1000;
                    await this.sleep(delay);
                } else {
                    console.error(`All ${maxRetries + 1} attempts failed for ${endpoint}`);
                    return endpoint === 'messages' ? [] : null;
                }
            }
        }
        
        return endpoint === 'messages' ? [] : null;
    }

    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    async showNotification(email, newMessageCount) {
        try {
            await chrome.notifications.create({
                type: 'basic',
                iconUrl: '/icons/icon-48.png',
                title: 'New TempMail Message',
                message: `You have ${newMessageCount} new message${newMessageCount > 1 ? 's' : ''} in ${email}`,
                buttons: [
                    { title: 'View Messages' }
                ],
                requireInteraction: true
            });
        } catch (error) {
            console.error('Error showing notification:', error);
        }
    }

    async getMessage(messageId) {
        return await this.apiCall('message', messageId);
    }

    async openEmailPage(email) {
        try {
            const url = `https://tempmail.pw/mailbox/${email}`;
            await chrome.tabs.create({ url });
        } catch (error) {
            console.error('Error opening email page:', error);
            throw error;
        }
    }

    async updateBadge(messageCount) {
        try {
            const badgeText = messageCount > 0 ? messageCount.toString() : '';
            const badgeColor = messageCount > 0 ? '#ff4444' : '#1a73e8';
            
            // Chrome uses action API (Manifest V3), Firefox uses browserAction (Manifest V2)
            const api = chrome.action || chrome.browserAction;
            
            if (api) {
                // Update badge text
                await api.setBadgeText({ text: badgeText });
                
                // Update badge background color
                await api.setBadgeBackgroundColor({ color: badgeColor });
                
                console.log(`Badge updated: ${badgeText}`);
            }
        } catch (error) {
            console.error('Error updating badge:', error);
        }
    }

    generateRandomString(length) {
        const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
        let result = '';
        for (let i = 0; i < length; i++) {
            result += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return result;
    }

    async showSimpleNotification(email, messageCount) {
        try {
            const title = messageCount > 1 ? 
                `TempMail - ${messageCount} New Messages` : 
                'TempMail - New Message';
            const message = messageCount > 1 ? 
                `You have ${messageCount} new messages` : 
                'You have a new message';
            
            await chrome.notifications.create(`tempmail-${Date.now()}`, {
                type: 'basic',
                iconUrl: 'icons/icon48.png',
                title: title,
                message: message,
                contextMessage: `Email: ${email}`,
                buttons: [
                    { title: 'Open Inbox' }
                ],
                requireInteraction: true
            });
            
            console.log('Simple notification sent');
        } catch (error) {
            console.error('Error showing simple notification:', error);
        }
    }

    async showNewMessageNotification(email, newMessages) {
        try {
            if (!newMessages || newMessages.length === 0) return;
            
            const latestMessage = newMessages[0];
            const messageCount = newMessages.length;
            
            let title = 'TempMail - New Message';
            let message = 'You have a new message';
            let contextMessage = `Email: ${email}`;
            
            if (messageCount > 1) {
                title = `TempMail - ${messageCount} New Messages`;
                message = `You have ${messageCount} new messages`;
            } else if (latestMessage.subject) {
                message = `New message: ${latestMessage.subject}`;
                contextMessage = `From: ${latestMessage.from || 'Unknown sender'}`;
            }
            
            // Create both Chrome extension notification and browser notification
            await chrome.notifications.create(`tempmail-${Date.now()}`, {
                type: 'basic',
                iconUrl: 'icons/icon48.png',
                title: title,
                message: message,
                contextMessage: contextMessage,
                buttons: [
                    { title: 'Open Inbox' }
                ],
                requireInteraction: true
            });
            
            // Also try to send a browser notification for better visibility
            try {
                if (typeof Notification !== 'undefined' && Notification.permission === 'granted') {
                    const browserNotification = new Notification(title, {
                        body: `${message}\n${contextMessage}`,
                        icon: 'icons/icon48.png',
                        tag: 'tempmail-new-message',
                        requireInteraction: true
                    });
                    
                    browserNotification.onclick = () => {
                        chrome.tabs.create({ url: `https://tempmail.pw/mailbox/${email}` });
                        browserNotification.close();
                    };
                    
                    setTimeout(() => browserNotification.close(), 10000);
                }
            } catch (browserNotifError) {
                console.log('Browser notification not available:', browserNotifError.message);
            }
            
            console.log('Notifications sent for new message(s)');
        } catch (error) {
            console.error('Error showing notification:', error);
        }
    }



    // Background polling for messages with smart intervals
    async startBackgroundPolling() {
        // Clear any existing interval
        if (this.pollingInterval) {
            clearInterval(this.pollingInterval);
        }

        // Start with aggressive polling, but back off if no activity
        this.scheduleNextBackgroundCheck();
        console.log('Smart background polling started');
    }

    scheduleNextBackgroundCheck() {
        // Use faster adaptive intervals: 10-20 seconds if active, 30-60 seconds if idle
        const now = Date.now();
        const timeSinceLastActivity = now - (this.lastActivity || 0);
        const isActive = timeSinceLastActivity < 10 * 60 * 1000; // 10 minutes
        
        const minInterval = isActive ? 5000 : 10000;   // 5s active, 10s idle
        const maxInterval = isActive ? 15000 : 20000;  // 15s active, 20s idle
        const interval = Math.floor(Math.random() * (maxInterval - minInterval + 1)) + minInterval;
        
        this.pollingInterval = setTimeout(async () => {
            await this.checkForNewMessages();
            if (this.pollingInterval) { // Only reschedule if not stopped
                this.scheduleNextBackgroundCheck();
            }
        }, interval);
    }

    async checkForNewMessages() {
        try {
            const result = await chrome.storage.local.get(['currentToken', 'lastMessageCount', 'currentEmail', 'lastMessageFetch']);
            if (!result.currentToken) {
                console.log('No current email token, skipping background check');
                return;
            }

            // Skip if recently fetched (within 5 seconds) to avoid duplicating popup calls
            const timeSinceLastFetch = Date.now() - (result.lastMessageFetch || 0);
            if (timeSinceLastFetch < 5000) {
                console.log(`Skipping background check - recent fetch ${Math.round(timeSinceLastFetch/1000)}s ago`);
                return;
            }

            // Record activity for adaptive polling
            this.lastActivity = Date.now();
            
            console.log('Background: Fetching messages...');
            const messages = await this.getMessages(result.currentToken);
            
            // Handle rate limiting with exponential backoff
            if (messages && messages.error === 'rate_limited') {
                console.log('Background check rate limited, backing off...');
                this.rateLimitedUntil = Date.now() + (messages.retryAfter * 1000);
                return;
            }
            
            // Reset rate limit status on success
            this.rateLimitedUntil = 0;
            
            if (Array.isArray(messages)) {
                const currentCount = messages.length;
                const lastCount = result.lastMessageCount || 0;
                
                // Always update storage with fresh data and fetch timestamp
                await chrome.storage.local.set({
                    messages: messages,
                    lastMessageCount: currentCount,
                    lastMessageFetch: Date.now()
                });

                if (currentCount > lastCount) {
                    const newMessageCount = currentCount - lastCount;
                    
                    // Update badge
                    await this.updateBadge(currentCount);

                    // Show notification for new messages
                    if (result.currentEmail && newMessageCount > 0) {
                        const newMessages = messages.slice(-newMessageCount);
                        await this.showNewMessageNotification(result.currentEmail, newMessages);
                    }

                    console.log(`Background: ${newMessageCount} new messages found (${currentCount} total)`);
                } else {
                    // Still update badge even if no new messages
                    await this.updateBadge(currentCount);
                    console.log(`Background: no new messages (${currentCount} total)`);
                }
            } else {
                console.log('Background: API returned non-array response');
            }
        } catch (error) {
            console.error('Background message check failed:', error);
        }
    }
}

// Initialize background service
const backgroundService = new BackgroundService();

// Handle notification clicks
chrome.notifications.onClicked.addListener(async (notificationId) => {
    try {
        // Get current email from storage
        const data = await chrome.storage.local.get(['currentEmail']);
        if (data.currentEmail) {
            const url = `https://tempmail.pw/mailbox/${data.currentEmail}`;
            await chrome.tabs.create({ url });
        }
        // Clear the notification
        chrome.notifications.clear(notificationId);
    } catch (error) {
        console.error('Error handling notification click:', error);
    }
});

chrome.notifications.onButtonClicked.addListener(async (notificationId, buttonIndex) => {
    try {
        // Get current email from storage
        const data = await chrome.storage.local.get(['currentEmail']);
        if (data.currentEmail) {
            const url = `https://tempmail.pw/mailbox/${data.currentEmail}`;
            await chrome.tabs.create({ url });
        }
        // Clear the notification
        chrome.notifications.clear(notificationId);
    } catch (error) {
        console.error('Error handling notification button click:', error);
    }
});

// Periodic cleanup (optional)
setInterval(async () => {
    try {
        // Clean up old data if needed
        const result = await chrome.storage.local.get(['currentEmail', 'lastActivity']);
        const now = Date.now();
        const oneDay = 24 * 60 * 60 * 1000;
        
        if (result.lastActivity && (now - result.lastActivity) > oneDay) {
            // Email is older than 1 day, might want to clean up
            console.log('Old email data detected, consider cleanup');
        }
        
        // Update last activity
        await chrome.storage.local.set({ lastActivity: now });
    } catch (error) {
        console.error('Error in periodic cleanup:', error);
    }
}, 60000); // Run every minute
