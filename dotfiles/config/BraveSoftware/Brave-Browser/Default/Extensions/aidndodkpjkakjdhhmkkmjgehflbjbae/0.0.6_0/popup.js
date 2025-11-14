class TempMailExtension {
    constructor() {
        this.apiKey = 'Lt6zDdQ3bbp8hU5PiSONwnoWUYXU5CALiOKBhi';
        this.baseUrl = 'https://tempmail.pw/api';
        this.currentEmail = null;
        this.currentToken = null;
        this.messages = [];
        this.pollingInterval = null;
        this.isPolling = false;
        this.rateLimitBackoff = 1000; // Start with 1 second
        this.maxBackoff = 15000; // Max 15 seconds
        this.lastPollTime = 0;
        this.minPollInterval = 5000; // Minimum 5 seconds between polls
        this.rateLimitedUntil = 0; // Track when rate limit expires
        this.lastMessageTime = 0; // Track when we last received messages
        this.messageCache = new Map(); // Cache for API responses
        this.cacheTimeout = 10000; // Cache valid for 10 seconds
        this.apiCallsCount = 0; // Performance monitoring
        this.lastCacheHit = 0; // Track cache efficiency
        
        
        this.init();
    }

    async init() {
        await this.loadStoredData();
        this.setupEventListeners();
        
        // Check if we should show rating dialog
        await this.checkAndShowRatingDialog();
        
        if (!this.currentEmail) {
            await this.generateNewEmail();
        } else {
            this.updateUI();
            this.startPolling();
            
        }
    }

    async loadStoredData() {
        try {
            const result = await chrome.storage.local.get([
                'currentEmail', 
                'currentToken', 
                'autofillEnabled', 
                'exceptions',
                'messages',
                'lastMessageCount',
            ]);
            
            this.currentEmail = result.currentEmail || null;
            this.currentToken = result.currentToken || null;
            this.messages = result.messages || [];
            this.lastMessageCount = result.lastMessageCount || 0;
            
            // Load autofill settings
            const autofillCheckbox = document.getElementById('autofillCheckbox');
            const autofillEnabled = result.autofillEnabled !== false;
            autofillCheckbox.checked = autofillEnabled;
            console.log('Loaded autofill state:', autofillEnabled);
            
            // Load exceptions
            const exceptions = result.exceptions || [];
            await this.loadCurrentDomain(exceptions);
            this.renderExceptions(exceptions);
            
        } catch (error) {
            console.error('Error loading stored data:', error);
        }
    }

    setupEventListeners() {
        // Change email button
        document.getElementById('changeBtn').addEventListener('click', () => {
            this.changeEmail();
        });

        // Copy email button
        document.getElementById('copyBtn').addEventListener('click', () => {
            this.copyEmail();
        });

        // Inbox header click
        document.querySelector('.inbox-header').addEventListener('click', () => {
            this.toggleInbox();
        });

        // Back button in message detail
        document.getElementById('backBtn').addEventListener('click', () => {
            this.hideMessageDetail();
        });

        // QR code click
        document.getElementById('qrBtn').addEventListener('click', () => {
            this.showQRCode();
        });

        // QR modal close
        document.getElementById('qrCloseBtn').addEventListener('click', () => {
            this.hideQRCode();
        });

        // QR modal background click
        document.getElementById('qrModal').addEventListener('click', (e) => {
            if (e.target.id === 'qrModal') {
                this.hideQRCode();
            }
        });

        // Manual refresh button
        document.getElementById('refreshBtn').addEventListener('click', (e) => {
            e.stopPropagation(); // Prevent inbox toggle
            this.manualRefresh();
        });

        // Manual rating button (star icon)
        document.getElementById('manualRatingBtn').addEventListener('click', () => {
            this.showRatingDialog();
        });

        // Add debug button for testing (temporary)
        document.addEventListener('keydown', (e) => {
            if (e.ctrlKey && e.shiftKey && e.key === 'D') {
                console.log('Debug key pressed - running API test');
                this.testMessageAPI();
            }
            // Test rating dialog
            if (e.ctrlKey && e.shiftKey && e.key === 'R') {
                console.log('Testing rating dialog');
                this.showRatingDialog();
            }
        });

        // Autofill toggle - add better event handling
        const autofillCheckbox = document.getElementById('autofillCheckbox');
        autofillCheckbox.addEventListener('change', (e) => {
            console.log('Autofill checkbox changed:', e.target.checked);
            this.toggleAutofill(e.target.checked);
        });
        
        // Also handle click on the toggle switch container
        const toggleSwitch = document.getElementById('autofillToggle');
        toggleSwitch.addEventListener('click', (e) => {
            if (e.target !== autofillCheckbox) {
                autofillCheckbox.checked = !autofillCheckbox.checked;
                autofillCheckbox.dispatchEvent(new Event('change'));
            }
        });

        // Add exception button - auto-add current domain
        document.getElementById('addExceptionBtn').addEventListener('click', async () => {
            await this.addCurrentDomainToExceptions();
        });

        // Exception input enter key
        document.getElementById('exceptionInput').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                this.addException();
            }
        });
        
        // Rating dialog event listeners
        this.setupRatingEventListeners();
    }

    async generateNewEmail() {
        this.showLoading(true);
        try {
            let domains = [];
            let usingFallback = false;
            
            console.log('Fetching domains from API...');
            
            try {
                const domainsResponse = await fetch(`${this.baseUrl}/domains/${this.apiKey}`, {
                    method: 'GET',
                    headers: {
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                        'Accept': 'application/json, text/plain, */*',
                        'Cache-Control': 'no-cache'
                    }
                });
                
                const responseText = await domainsResponse.text();
                console.log(`Domains API Response: ${responseText.substring(0, 200)}...`);
                
                if (responseText.trim().startsWith('<!DOCTYPE') || responseText.includes('<html')) {
                    console.log('Domains API returned HTML page - API might be down or blocked');
                    usingFallback = true;
                } else if (domainsResponse.status === 429) {
                    console.log('API rate limited, using fallback domains...');
                    usingFallback = true;
                } else if (!domainsResponse.ok) {
                    console.log(`API error ${domainsResponse.status}, using fallback...`);
                    usingFallback = true;
                } else {
                    try {
                        domains = JSON.parse(responseText);
                        console.log('Available domains from API:', domains);
                    } catch (parseError) {
                        console.log('Failed to parse domains response as JSON');
                        usingFallback = true;
                    }
                }
            } catch (networkError) {
                console.log('Network error, using fallback domains:', networkError.message);
                usingFallback = true;
            }
            
            // Fallback domains based on previous successful API responses
            if (usingFallback || !domains || !Array.isArray(domains) || domains.length === 0) {
                domains = [
                    'ispeedtest.digital',
                    'nabaxox.edu.pl', 
                    'seedspeed.site',
                    'jasonbella.online',
                    'chingchongme.site',
                    'ismartsense.online',
                    'afeeyah.store',
                    'simranaitech.space',
                    'rimshacooking.site',
                    'babyonboard.online'
                ];
                console.log('Using fallback domains:', domains);
                this.showToast('Using cached domains (API rate limited)');
            }

            // Generate random email address
            const randomName = this.generateRandomString(8);
            const domain = domains[Math.floor(Math.random() * domains.length)];
            const newEmail = `${randomName}@${domain}`;
            
            // Create the email using the API first
            console.log(`Creating email via API: ${newEmail}`);
            try {
                const createResponse = await fetch(`${this.baseUrl}/email/${newEmail}/${this.apiKey}`, {
                    method: 'GET',
                    headers: {
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                        'Accept': 'application/json, text/plain, */*',
                        'Cache-Control': 'no-cache'
                    }
                });
                
                const createResponseText = await createResponse.text();
                console.log(`Create email response: ${createResponseText}`);
                
                if (!createResponse.ok) {
                    console.log(`Email creation failed with status ${createResponse.status}`);
                } else {
                    console.log('Email created successfully');
                }
            } catch (createError) {
                console.log('Email creation error:', createError.message);
            }
            
            // Use the email address as the token for message fetching
            const token = newEmail;
            
            this.currentEmail = newEmail;
            this.currentToken = token;
            
            
            // Store in browser storage and clear any previous messages
            await chrome.storage.local.set({
                currentEmail: this.currentEmail,
                currentToken: this.currentToken,
                messages: [],
                lastMessageCount: 0
            });
            
            // Clear current messages from memory
            this.messages = [];
            
            // Update autofill with new email
            await this.updateAutofillEmail();
            
            this.updateUI();
            this.startPolling();
            
            
            // Test message API immediately after email generation
            console.log('Testing message API with new email...');
            setTimeout(() => {
                this.testMessageAPI();
            }, 2000);
            
            const message = usingFallback ? 'Email generated (using cached domains)!' : 'New email generated!';
            this.showToast(message);
            
        } catch (error) {
            console.error('Error generating email:', error);
            if (error.message.includes('Rate limited')) {
                this.showToast('Rate limited. Please wait a moment.');
            } else {
                this.showToast('Failed to generate email. Please try again.');
            }
        } finally {
            this.showLoading(false);
        }
    }

    async changeEmail() {
        if (!this.currentToken) {
            await this.generateNewEmail();
            return;
        }

        this.showLoading(true);
        try {
            // Delete current email
            const deleteResponse = await fetch(`${this.baseUrl}/email/delete/${this.currentToken}/${this.apiKey}`);
            
            if (deleteResponse.ok) {
                this.currentEmail = null;
                this.currentToken = null;
                this.messages = [];
                
                await chrome.storage.local.remove(['currentEmail', 'currentToken']);
                await this.generateNewEmail();
            } else {
                throw new Error('Failed to delete email');
            }
        } catch (error) {
            console.error('Error changing email:', error);
            // Try to generate new email anyway
            await this.generateNewEmail();
        } finally {
            this.showLoading(false);
        }
    }

    async copyEmail() {
        if (!this.currentEmail) return;

        try {
            await navigator.clipboard.writeText(this.currentEmail);
            this.showToast('Email copied to clipboard!');
            
            // Visual feedback
            const copyBtn = document.getElementById('copyBtn');
            const originalText = copyBtn.innerHTML;
            copyBtn.innerHTML = '<i class="fas fa-check"></i> Copied';
            copyBtn.style.background = '#10b981';
            
            setTimeout(() => {
                copyBtn.innerHTML = originalText;
                copyBtn.style.background = '#1a73e8';
            }, 2000);
            
        } catch (error) {
            console.error('Error copying to clipboard:', error);
            this.showToast('Failed to copy email');
        }
    }

    async openEmailInBrowser() {
        if (!this.currentEmail) return;
        
        const url = `https://tempmail.pw/mailbox/${this.currentEmail}`;
        await chrome.tabs.create({ url });
    }

    startPolling() {
        if (this.isPolling) return;
        
        this.isPolling = true;
        this.checkMessages(); // Initial check
        
        this.scheduleNextPoll();
    }

    scheduleNextPoll() {
        if (!this.isPolling) return;
        
        // Adaptive polling based on recent activity and rate limiting
        let interval;
        
        if (this.rateLimitedUntil && Date.now() < this.rateLimitedUntil) {
            // If rate limited, wait until the limit expires plus some buffer
            interval = this.rateLimitedUntil - Date.now() + 5000;
        } else if (this.rateLimitBackoff > 1000) {
            // If we've been backing off due to errors, use shorter intervals
            interval = Math.min(this.rateLimitBackoff, 15000); // Max 15 seconds
        } else {
            // Optimized polling with 5-20 second random intervals for API rate limit management
            const timeSinceLastMessage = Date.now() - (this.lastMessageTime || 0);
            const isRecentActivity = timeSinceLastMessage < 10 * 60 * 1000; // 10 minutes
            
            const minInterval = isRecentActivity ? 5000 : 10000;   // 5s if recent activity, 10s otherwise
            const maxInterval = isRecentActivity ? 15000 : 20000;  // 15s if recent activity, 20s otherwise
            
            interval = Math.floor(Math.random() * (maxInterval - minInterval + 1)) + minInterval;
        }
        
        console.log(`Next poll in ${Math.round(interval/1000)}s`);
        
        this.pollingInterval = setTimeout(async () => {
            await this.checkMessages();
            this.scheduleNextPoll(); // Schedule next poll
        }, interval);
    }

    stopPolling() {
        if (this.pollingInterval) {
            clearTimeout(this.pollingInterval); // Changed from clearInterval to clearTimeout
            this.pollingInterval = null;
        }
        this.isPolling = false;
    }

    async manualRefresh() {
        const refreshBtn = document.getElementById('refreshBtn');
        if (!refreshBtn) return;
        
        // Add spinning animation
        refreshBtn.classList.add('spinning');
        
        try {
            // Force refresh messages regardless of cache and rate limiting
            await this.checkMessages(true); // Force refresh
            this.showToast('Messages refreshed');
        } catch (error) {
            console.error('Manual refresh failed:', error);
            this.showToast('Refresh failed - API may be rate limited');
        } finally {
            // Remove spinning animation
            setTimeout(() => {
                refreshBtn.classList.remove('spinning');
            }, 500);
        }
    }

    async tryAlternativeMessageFetch() {
        console.log('Primary message fetch failed, falling back to API unavailable state');
        this.showAPIUnavailableMessage();
    }
    
    showAPIUnavailableMessage() {
        console.log('API appears to be unavailable');
        
        // Show clear message to user
        this.showToast('API unavailable - click QR code to check messages on web');
        
        // Update status to show API unavailable
        this.updateInboxStatus('error', 'API unavailable - use QR code to check messages');
    }

    async testMessageAPI() {
        console.log('=== MESSAGE API TEST ===');
        console.log(`Current Email: ${this.currentEmail}`);
        console.log(`Current Token: ${this.currentToken}`);
        console.log(`API Key: ${this.apiKey}`);
        console.log(`Base URL: ${this.baseUrl}`);
        
        const testUrl = `${this.baseUrl}/messages/${this.currentToken}/${this.apiKey}`;
        console.log(`Test URL: ${testUrl}`);
        
        try {
            const response = await fetch(testUrl);
            console.log(`Response Status: ${response.status}`);
            console.log(`Response Headers:`, [...response.headers.entries()]);
            
            const responseText = await response.text();
            console.log(`Response Body: ${responseText}`);
            
            if (response.status === 200) {
                try {
                    const json = JSON.parse(responseText);
                    console.log(`Parsed JSON:`, json);
                } catch (e) {
                    console.log(`Failed to parse as JSON: ${e.message}`);
                }
            }
        } catch (error) {
            console.error(`API Test Error: ${error.message}`);
        }
        console.log('=== END MESSAGE API TEST ===');
    }

    async checkMessages(forceRefresh = false) {
        if (!this.currentToken) return;

        // Check cache first unless forcing refresh
        if (!forceRefresh) {
            const cachedMessages = this.getCachedMessages();
            if (cachedMessages !== null) {
                console.log('Using cached messages');
                this.lastCacheHit = Date.now();
                await this.processMessages(cachedMessages);
                return;
            }
        }

        // Record poll time for rate limiting
        this.lastPollTime = Date.now();
        
        // Check if we're still rate limited
        if (this.rateLimitedUntil && Date.now() < this.rateLimitedUntil) {
            console.log('Still rate limited, skipping check');
            return;
        }

        // Check if background recently fetched messages
        const backgroundData = await this.getBackgroundMessages();
        if (backgroundData && !forceRefresh) {
            console.log('Using background fetched messages');
            await this.processMessages(backgroundData.messages);
            return;
        }

        this.updateInboxStatus('loading', 'Checking for messages...');
        this.apiCallsCount++;

        try {
            const messages = await this.apiCall('messages', this.currentEmail, {
                maxRetries: 1, // Less retries for popup to be more responsive
                initialDelay: 500
            });
            
            // Handle rate limiting
            if (messages && messages.error === 'rate_limited') {
                console.log('Rate limited, backing off');
                this.rateLimitedUntil = Date.now() + (messages.retryAfter * 1000);
                this.rateLimitBackoff = Math.min(this.rateLimitBackoff * 2, this.maxBackoff);
                return;
            }
            
            // Reset rate limit status on success
            this.rateLimitedUntil = 0;
            this.rateLimitBackoff = 1000;
            
            if (Array.isArray(messages)) {
                // Cache the messages
                this.cacheMessages(messages);
                await this.processMessages(messages);
            } else {
                console.log('No messages or API error, trying alternative fetch');
                await this.tryAlternativeMessageFetch();
            }
        } catch (error) {
            console.error('Error checking messages:', error);
            this.rateLimitBackoff = Math.min(this.rateLimitBackoff * 2, this.maxBackoff);
        } finally {
            // Status will be updated in updateInboxUI()
        }
    }

    async processMessages(messages) {
        const previousCount = this.messages.length;
        const newMessageCount = messages.length - previousCount;
        
        this.messages = messages;
        
        // Track when we received messages for smart polling
        if (messages.length > 0) {
            this.lastMessageTime = Date.now();
        }
        
        // Update storage and UI in parallel with performance tracking
        const updateStart = Date.now();
        await Promise.all([
            chrome.storage.local.set({ 
                messages: this.messages,
                lastMessageCount: messages.length,
                lastMessageFetch: Date.now() // Coordinate with background
            }),
            this.updateBadge(messages.length)
        ]);
        
        const updateTime = Date.now() - updateStart;
        console.log(`UI update took ${updateTime}ms`);
        
        // Show notification for new messages
        if (newMessageCount > 0) {
            console.log(`Showing notification for ${newMessageCount} new messages`);
            this.showNewMessageNotification(newMessageCount);
        }
        
        this.updateInboxUI();
        console.log(`Messages updated: ${messages.length} total, ${newMessageCount} new (${this.apiCallsCount} API calls made)`);
    }

    updateInboxStatus(state = 'idle', message = '') {
        const statusElement = document.getElementById('inboxStatus');
        const statusIcon = document.getElementById('statusIcon');
        const statusText = document.getElementById('statusText');
        
        if (!statusElement || !statusIcon || !statusText) return;
        
        // Reset classes
        statusIcon.className = 'status-icon';
        
        switch (state) {
            case 'loading':
                statusIcon.classList.add('loading');
                statusText.textContent = message || 'Checking for messages...';
                statusElement.style.display = 'block';
                break;
            case 'empty':
                statusIcon.classList.add('idle');
                statusText.textContent = 'No messages yet';
                statusElement.style.display = 'block';
                break;
            case 'error':
                statusIcon.classList.add('idle');
                statusText.textContent = message || 'Unable to check messages';
                statusElement.style.display = 'block';
                break;
            case 'hidden':
            default:
                statusElement.style.display = 'none';
                break;
        }
    }

    // Performance monitoring methods
    logPerformanceStats() {
        const cacheHitRate = this.lastCacheHit > 0 ? 'recent' : 'none';
        const avgPollingInterval = this.isPolling ? 'active' : 'stopped';
        
        console.log(`Performance Stats: API calls: ${this.apiCallsCount}, Cache hits: ${cacheHitRate}, Polling: ${avgPollingInterval}`);
        
        // Reset counters periodically
        if (this.apiCallsCount > 50) {
            this.apiCallsCount = 0;
        }
    }

    // Enhanced error recovery with circuit breaker pattern
    shouldSkipAPICall() {
        // Circuit breaker: if too many recent failures, temporarily stop API calls
        if (this.rateLimitBackoff > 30000) {
            console.log('Circuit breaker active - skipping API call');
            return true;
        }
        return false;
    }

    async getMessage(messageId) {
        return await this.apiCall('message', messageId);
    }

    async apiCall(endpoint, token, options = {}) {
        const maxRetries = options.maxRetries || 2;
        const initialDelay = options.initialDelay || 1000;
        const callStart = Date.now();
        
        for (let attempt = 0; attempt <= maxRetries; attempt++) {
            try {
                const fetchStart = Date.now();
                const response = await fetch(`${this.baseUrl}/${endpoint}/${token}/${this.apiKey}`, {
                    method: options.method || 'GET',
                    headers: {
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                        'Accept': 'application/json, text/plain, */*',
                        'Cache-Control': 'no-cache',
                        ...options.headers
                    },
                    signal: AbortSignal.timeout(15000) // 15 second timeout
                });
                
                const fetchTime = Date.now() - fetchStart;
                console.log(`API ${endpoint} call took ${fetchTime}ms`);
                
                if (response.status === 429) {
                    const retryAfter = parseInt(response.headers.get('retry-after') || '30');
                    console.log(`Rate limited (attempt ${attempt + 1}/${maxRetries + 1}) - retry after ${retryAfter}s`);
                    
                    if (attempt < maxRetries) {
                        await this.sleep(retryAfter * 1000);
                        continue;
                    }
                    
                    return { error: 'rate_limited', retryAfter };
                }
                
                // Enhanced error recovery for different status codes
                if (!response.ok) {
                    if (response.status >= 500) {
                        // Server error - retry with backoff
                        throw new Error(`Server error ${response.status}: ${response.statusText}`);
                    } else if (response.status === 404) {
                        // Not found - likely invalid token/email
                        console.log(`${endpoint} not found - may be invalid token`);
                        return endpoint === 'messages' ? [] : null;
                    } else {
                        // Client error - don't retry
                        console.error(`Client error ${response.status}: ${response.statusText}`);
                        return endpoint === 'messages' ? [] : null;
                    }
                }
                
                const responseText = await response.text();
                
                // Check for HTML error pages
                if (responseText.trim().startsWith('<!DOCTYPE') || responseText.includes('<html')) {
                    throw new Error('API returned HTML page - endpoint may be blocked');
                }
                
                let data;
                try {
                    data = JSON.parse(responseText);
                } catch (parseError) {
                    throw new Error(`Invalid JSON: ${parseError.message}`);
                }
                
                // Handle messages endpoint specifically
                if (endpoint === 'messages') {
                    if (Array.isArray(data)) {
                        const totalTime = Date.now() - callStart;
                        console.log(`Successfully fetched ${data.length} messages in ${totalTime}ms`);
                        return data;
                    } else if (data && data.message) {
                        if (data.message.includes('No messages found') || data.message.includes('not found')) {
                            console.log('No messages found for this email');
                            return [];
                        }
                        throw new Error(`API error: ${data.message}`);
                    }
                    return [];
                }
                
                return data;
                
            } catch (error) {
                const isTimeout = error.name === 'TimeoutError' || error.message.includes('timeout');
                const errorType = isTimeout ? 'timeout' : 'network';
                
                console.error(`API call ${errorType} error (attempt ${attempt + 1}/${maxRetries + 1}):`, error.message);
                
                if (attempt < maxRetries && !isTimeout) {
                    // Only retry non-timeout errors
                    const delay = initialDelay * Math.pow(1.5, attempt) + Math.random() * 500;
                    console.log(`Retrying in ${Math.round(delay)}ms...`);
                    await this.sleep(delay);
                } else {
                    // Log performance data for failed calls
                    const totalTime = Date.now() - callStart;
                    console.log(`API call failed after ${totalTime}ms (${this.apiCallsCount} total calls)`);
                    return endpoint === 'messages' ? [] : null;
                }
            }
        }
        
        return endpoint === 'messages' ? [] : null;
    }

    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    // Message caching methods
    cacheMessages(messages) {
        const cacheKey = `messages_${this.currentEmail}`;
        this.messageCache.set(cacheKey, {
            data: messages,
            timestamp: Date.now(),
            email: this.currentEmail
        });
        console.log(`Cached ${messages.length} messages for ${this.currentEmail}`);
    }

    getCachedMessages() {
        const cacheKey = `messages_${this.currentEmail}`;
        const cached = this.messageCache.get(cacheKey);
        
        if (!cached) return null;
        
        // Check if cache is still valid
        const age = Date.now() - cached.timestamp;
        if (age > this.cacheTimeout) {
            this.messageCache.delete(cacheKey);
            return null;
        }
        
        // Ensure cache is for current email
        if (cached.email !== this.currentEmail) {
            return null;
        }
        
        console.log(`Cache hit: ${cached.data.length} messages (age: ${Math.round(age/1000)}s)`);
        return cached.data;
    }

    clearMessageCache() {
        const cacheKey = `messages_${this.currentEmail}`;
        this.messageCache.delete(cacheKey);
        console.log(`Cleared message cache for ${this.currentEmail}`);
    }

    async getBackgroundMessages() {
        try {
            const result = await chrome.storage.local.get(['messages', 'lastMessageFetch', 'currentEmail']);
            
            // Check if background recently fetched messages for current email
            if (result.messages && result.lastMessageFetch && result.currentEmail === this.currentEmail) {
                const age = Date.now() - result.lastMessageFetch;
                
                // Use background data if it's less than 5 seconds old
                if (age < 5000) {
                    console.log(`Using background data (age: ${Math.round(age/1000)}s)`);
                    return {
                        messages: result.messages,
                        age: age
                    };
                }
            }
            return null;
        } catch (error) {
            console.error('Error getting background messages:', error);
            return null;
        }
    }

    updateUI() {
        const emailText = document.getElementById('emailText');
        emailText.textContent = this.currentEmail || 'Loading...';
        
        this.updateInboxUI();
    }

    updateInboxUI() {
        const messageCountEl = document.getElementById('messageCount');
        const messageListEl = document.getElementById('messageList');
        
        messageCountEl.textContent = this.messages.length;
        
        if (this.messages.length === 0) {
            this.updateInboxStatus('empty', 'No messages yet');
            messageListEl.style.display = 'none';
        } else {
            this.updateInboxStatus('hidden');
            messageListEl.style.display = 'block';
            
            messageListEl.innerHTML = '';
            this.messages.forEach((message, index) => {
                const messageEl = document.createElement('div');
                messageEl.className = 'message-item';
                messageEl.innerHTML = `
                    <div class="message-content">
                        <div class="message-subject">${this.escapeHtml(message.subject || 'No Subject')}</div>
                        <div class="message-sender">${this.escapeHtml(message.sender_email || message.from || 'Unknown Sender')}</div>
                    </div>
                    <button class="delete-btn" data-message-id="${message.id}" title="Delete message">
                        <i class="fas fa-trash"></i>
                    </button>
                `;
                
                const contentArea = messageEl.querySelector('.message-content');
                contentArea.addEventListener('click', () => {
                    this.openEmailInBrowser();
                });
                
                const deleteBtn = messageEl.querySelector('.delete-btn');
                deleteBtn.addEventListener('click', (e) => {
                    e.stopPropagation();
                    this.deleteMessage(message.id, index);
                });
                
                messageListEl.appendChild(messageEl);
            });
        }
    }

    async showMessageDetail(message) {
        const detailView = document.getElementById('messageDetail');
        const contentEl = document.getElementById('messageContent');
        
        this.showLoading(true);
        
        try {
            // Get full message content
            const fullMessage = await this.getMessage(message.id);
            
            if (fullMessage) {
                contentEl.innerHTML = `
                    <div style="margin-bottom: 16px;">
                        <strong>From:</strong> ${this.escapeHtml(fullMessage.from || message.from)}
                    </div>
                    <div style="margin-bottom: 16px;">
                        <strong>Subject:</strong> ${this.escapeHtml(fullMessage.subject || message.subject)}
                    </div>
                    <div style="margin-bottom: 16px;">
                        <strong>Date:</strong> ${new Date(fullMessage.date || Date.now()).toLocaleString()}
                    </div>
                    <div style="margin-bottom: 16px;">
                        <strong>Message:</strong>
                    </div>
                    <div style="white-space: pre-wrap; background: #f9fafb; padding: 12px; border-radius: 6px; font-size: 13px;">
                        ${this.escapeHtml(fullMessage.body || fullMessage.text || 'No content')}
                    </div>
                `;
            } else {
                contentEl.innerHTML = '<div>Error loading message content</div>';
            }
            
            detailView.style.display = 'block';
        } catch (error) {
            console.error('Error showing message detail:', error);
            contentEl.innerHTML = '<div>Error loading message</div>';
            detailView.style.display = 'block';
        } finally {
            this.showLoading(false);
        }
    }

    hideMessageDetail() {
        const detailView = document.getElementById('messageDetail');
        detailView.style.display = 'none';
    }

    toggleInbox() {
        const inboxContent = document.getElementById('inboxContent');
        const isVisible = inboxContent.style.display !== 'none';
        
        inboxContent.style.display = isVisible ? 'none' : 'block';
        
        // Rotate chevron icon
        const chevron = document.querySelector('.inbox-header .fa-chevron-right');
        chevron.style.transform = isVisible ? 'rotate(0deg)' : 'rotate(90deg)';
    }

    async toggleAutofill(enabled) {
        console.log('Toggle autofill:', enabled);
        
        try {
            await chrome.storage.local.set({ autofillEnabled: enabled });
            
            // Send message to background script to update all content scripts
            await chrome.runtime.sendMessage({
                action: 'updateAutofillSettings',
                settings: {
                    autofillEnabled: enabled,
                    currentEmail: this.currentEmail
                }
            });
            
            // Show feedback to user
            const status = enabled ? 'enabled' : 'disabled';
            this.showToast(`Autofill ${status}`);
            console.log(`Autofill settings updated: ${status}`);
            
        } catch (error) {
            console.error('Error updating autofill settings:', error);
            this.showToast('Failed to update autofill settings');
        }
    }

    async addException() {
        const input = document.getElementById('exceptionInput');
        const domain = input.value.trim();
        
        if (!domain) return;
        
        try {
            const result = await chrome.storage.local.get(['exceptions']);
            const exceptions = result.exceptions || [];
            
            if (!exceptions.includes(domain)) {
                exceptions.push(domain);
                await chrome.storage.local.set({ exceptions });
                await this.updateAutofillSettings();
                this.renderExceptions(exceptions);
                input.value = '';
                this.showToast('Exception added');
            } else {
                this.showToast('Domain already in exceptions');
            }
        } catch (error) {
            console.error('Error adding exception:', error);
            this.showToast('Failed to add exception');
        }
    }

    async addCurrentDomainToExceptions() {
        try {
            const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
            if (tabs[0] && tabs[0].url) {
                const url = new URL(tabs[0].url);
                const domain = url.hostname;
                
                // Skip extension pages and special URLs
                if (domain.startsWith('chrome://') || domain.startsWith('moz-extension://') || domain === '') {
                    this.showToast('Cannot add this page to exceptions');
                    return;
                }
                
                const result = await chrome.storage.local.get(['exceptions']);
                const exceptions = result.exceptions || [];
                
                if (!exceptions.includes(domain)) {
                    exceptions.push(domain);
                    await chrome.storage.local.set({ exceptions });
                    await this.updateAutofillSettings();
                    this.renderExceptions(exceptions);
                    
                    // Update current domain status
                    this.showCurrentDomainStatus(domain, exceptions);
                    
                    this.showToast(`Added ${domain} to exceptions`);
                } else {
                    this.showToast(`${domain} already in exceptions`);
                }
            } else {
                this.showToast('Cannot detect current website');
            }
        } catch (error) {
            console.error('Error adding current domain to exceptions:', error);
            this.showToast('Failed to add current domain');
        }
    }

    async removeException(domain) {
        try {
            const result = await chrome.storage.local.get(['exceptions']);
            const exceptions = result.exceptions || [];
            const updated = exceptions.filter(d => d !== domain);
            
            await chrome.storage.local.set({ exceptions: updated });
            await this.updateAutofillSettings();
            this.renderExceptions(updated);
            this.showToast('Exception removed');
        } catch (error) {
            console.error('Error removing exception:', error);
            this.showToast('Failed to remove exception');
        }
    }

    async updateAutofillSettings() {
        try {
            const result = await chrome.storage.local.get(['autofillEnabled', 'exceptions']);
            await chrome.runtime.sendMessage({
                action: 'updateAutofillSettings',
                settings: {
                    autofillEnabled: result.autofillEnabled !== false,
                    exceptions: result.exceptions || [],
                    currentEmail: this.currentEmail
                }
            });
        } catch (error) {
            console.error('Error updating autofill settings:', error);
        }
    }

    renderExceptions(exceptions) {
        const listEl = document.getElementById('exceptionsList');
        
        if (exceptions.length === 0) {
            listEl.innerHTML = '';
            return;
        }
        
        listEl.innerHTML = '';
        exceptions.forEach(domain => {
            const item = document.createElement('div');
            item.className = 'exception-item';
            
            const domainSpan = document.createElement('span');
            domainSpan.textContent = domain;
            
            const removeBtn = document.createElement('button');
            removeBtn.className = 'exception-remove';
            removeBtn.innerHTML = '<i class="fas fa-times"></i>';
            removeBtn.addEventListener('click', () => {
                this.removeException(domain);
            });
            
            item.appendChild(domainSpan);
            item.appendChild(removeBtn);
            listEl.appendChild(item);
        });
    }

    // Show loading overlay with dynamic text
    showLoading(show, text = 'Checking for new messages...') {
        const overlay = document.getElementById('loadingOverlay');
        const loadingText = document.getElementById('loadingText');
        
        if (loadingText) {
            loadingText.textContent = text;
        }
        
        overlay.style.display = show ? 'flex' : 'none';
    }

    showToast(message) {
        const toast = document.getElementById('toast');
        toast.textContent = message;
        toast.classList.add('show');
        
        setTimeout(() => {
            toast.classList.remove('show');
        }, 3000);
    }

    generateRandomString(length) {
        const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
        let result = '';
        for (let i = 0; i < length; i++) {
            result += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return result;
    }

    async deleteMessage(messageId, messageIndex) {
        if (!messageId) {
            console.error('No message ID provided for deletion');
            return;
        }
        
        console.log(`Deleting message ${messageId} at index ${messageIndex}`);
        
        try {
            this.showLoading(true, 'Deleting message...');
            
            // Use DELETE method as per correct API documentation
            const deleteUrl = `${this.baseUrl}/message/${messageId}/${this.apiKey}`;
            console.log(`DELETE request to: ${deleteUrl}`);
            
            const response = await fetch(deleteUrl, {
                method: 'DELETE',
                headers: {
                    'Content-Type': 'application/json'
                }
            });
            
            console.log(`Delete response status: ${response.status}`);
            
            if (response.ok || response.status === 204) {
                console.log('Message deleted successfully from server');
                
                // Ensure we have valid message index
                if (messageIndex >= 0 && messageIndex < this.messages.length) {
                    // Remove from local array
                    this.messages.splice(messageIndex, 1);
                    console.log(`Removed message from local array, ${this.messages.length} messages remaining`);
                    
                    // Update local storage (keep email address and token intact - only update messages)
                    await chrome.storage.local.set({
                        messages: this.messages,
                        lastMessageCount: this.messages.length
                        // Explicitly preserving currentEmail and currentToken
                    });
                    
                    // Update UI and badge
                    this.updateInboxUI();
                    this.updateBadge(this.messages.length);
                    this.showToast('Message deleted successfully');
                    
                    // Clear cache to force refresh on next check
                    this.clearMessageCache();
                } else {
                    console.error(`Invalid message index: ${messageIndex}`);
                    this.showToast('Error: Invalid message reference');
                }
            } else {
                const errorText = await response.text();
                console.error(`Delete failed with status ${response.status}: ${errorText}`);
                throw new Error(`Failed to delete message: ${response.status} - ${errorText}`);
            }
        } catch (error) {
            console.error('Error deleting message:', error);
            this.showToast(`Failed to delete message: ${error.message}`);
        } finally {
            this.showLoading(false);
        }
    }

    async showNewMessageNotification(newCount) {
        try {
            console.log(`Attempting to show notification for ${newCount} new messages`);
            
            // Request notification permission if not granted
            if (typeof Notification !== 'undefined') {
                if (Notification.permission === 'default') {
                    const permission = await Notification.requestPermission();
                    console.log('Notification permission result:', permission);
                }
                
                if (Notification.permission === 'granted') {
                    const notification = new Notification('New TempMail Message', {
                        body: `You have ${newCount} new message${newCount > 1 ? 's' : ''} in ${this.currentEmail}`,
                        icon: '/icons/icon48.png',
                        badge: '/icons/icon48.png',
                        tag: 'tempmail-notification',
                        requireInteraction: true
                    });
                    
                    notification.onclick = () => {
                        this.openEmailInBrowser();
                        notification.close();
                    };
                    
                    // Auto-close after 8 seconds
                    setTimeout(() => {
                        try {
                            notification.close();
                        } catch (e) {
                            console.log('Notification already closed');
                        }
                    }, 8000);
                    
                    console.log('Browser notification created successfully');
                } else {
                    console.log('Notification permission denied or not available');
                }
            }
            
            // Also try Chrome extension notification API as backup
            try {
                if (chrome && chrome.runtime) {
                    await chrome.runtime.sendMessage({
                        action: 'showNotification',
                        email: this.currentEmail,
                        count: newCount
                    });
                    console.log('Chrome extension notification requested');
                }
            } catch (chromeError) {
                console.log('Chrome notification API not available:', chromeError.message);
            }
            
        } catch (error) {
            console.error('Error showing notification:', error);
        }
    }

    async updateBadge(messageCount) {
        try {
            // Send message to background script to update badge
            await chrome.runtime.sendMessage({
                action: 'updateBadge',
                count: messageCount
            });
        } catch (error) {
            console.error('Error updating badge:', error);
        }
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    // QR Code functionality
    showQRCode() {
        if (!this.currentEmail) {
            this.showToast('No email address available');
            return;
        }
        
        const modal = document.getElementById('qrModal');
        const urlDiv = document.getElementById('qrUrl');
        const mailboxUrl = `https://tempmail.pw/mailbox/${this.currentEmail}`;
        
        urlDiv.textContent = mailboxUrl;
        
        
        // Generate QR code
        this.generateQRCode(mailboxUrl);
        
        modal.style.display = 'flex';
    }

    hideQRCode() {
        const modal = document.getElementById('qrModal');
        modal.style.display = 'none';
    }

    generateQRCode(text) {
        const canvas = document.getElementById('qrCanvas');
        
        // Set canvas size
        canvas.width = 200;
        canvas.height = 200;
        
        // Clear any existing QR code
        const ctx = canvas.getContext('2d');
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        
        // Use external QR service for truly scannable codes
        const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(text)}`;
        
        const img = new Image();
        img.crossOrigin = 'anonymous';
        
        img.onload = () => {
            ctx.drawImage(img, 0, 0, 200, 200);
            console.log('Scannable QR code generated successfully');
            
            // Add click handler for convenience  
            canvas.onclick = () => {
                this.openEmailInBrowser();
                this.hideQRCode();
            };
            canvas.style.cursor = 'pointer';
            canvas.title = 'Scan with phone or click to open';
        };
        
        img.onerror = () => {
            console.log('QR service unavailable, using local generation');
            this.createLocalQRCode(canvas, text);
        };
        
        img.src = qrUrl;
    }

    createLocalQRCode(canvas, text) {
        // Create a simplified QR-like pattern locally without external services
        const ctx = canvas.getContext('2d');
        const size = 200;
        const cellSize = Math.floor(size / 25); // 25x25 grid
        
        ctx.clearRect(0, 0, size, size);
        
        // Fill with white background
        ctx.fillStyle = '#ffffff';
        ctx.fillRect(0, 0, size, size);
        
        // Create a hash-based pattern from the text
        const hash = this.simpleHash(text);
        const pattern = this.generatePattern(hash, 25);
        
        // Draw pattern
        ctx.fillStyle = '#000000';
        for (let row = 0; row < 25; row++) {
            for (let col = 0; col < 25; col++) {
                if (pattern[row][col]) {
                    ctx.fillRect(col * cellSize, row * cellSize, cellSize, cellSize);
                }
            }
        }
        
        // Draw finder patterns (corners)
        this.drawFinderPattern(ctx, 0, 0, cellSize);
        this.drawFinderPattern(ctx, 18 * cellSize, 0, cellSize);
        this.drawFinderPattern(ctx, 0, 18 * cellSize, cellSize);
        
        // Add click handler
        canvas.onclick = () => {
            this.openEmailInBrowser();
            this.hideQRCode();
        };
        canvas.style.cursor = 'pointer';
        canvas.title = 'Scan to open mailbox on phone or click to open here';
        
        console.log('Local QR code pattern generated for:', text);
    }

    drawFinderPattern(ctx, x, y, cellSize) {
        // Draw 7x7 finder pattern
        ctx.fillRect(x, y, 7 * cellSize, 7 * cellSize);
        ctx.fillStyle = '#ffffff';
        ctx.fillRect(x + cellSize, y + cellSize, 5 * cellSize, 5 * cellSize);
        ctx.fillStyle = '#000000';
        ctx.fillRect(x + 2 * cellSize, y + 2 * cellSize, 3 * cellSize, 3 * cellSize);
    }

    isReservedArea(row, col) {
        // Skip finder patterns and separator areas
        if (row < 9 && col < 9) return true; // Top-left
        if (row < 9 && col > 15) return true; // Top-right
        if (row > 15 && col < 9) return true; // Bottom-left
        if (row === 6 || col === 6) return true; // Timing patterns
        return false;
    }

    simpleHash(str) {
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            const char = str.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // Convert to 32-bit integer
        }
        return Math.abs(hash);
    }

    generatePattern(hash, size) {
        const pattern = [];
        let seed = hash;
        
        for (let row = 0; row < size; row++) {
            pattern[row] = [];
            for (let col = 0; col < size; col++) {
                // Skip finder pattern areas
                if (this.isReservedArea(row, col)) {
                    pattern[row][col] = false;
                } else {
                    // Generate pseudo-random pattern based on hash
                    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
                    pattern[row][col] = (seed % 100) < 50; // 50% density
                }
            }
        }
        return pattern;
    }

    fallbackQRCode(text) {
        // Simple text fallback display when everything else fails
        const canvas = document.getElementById('qrCanvas');
        const ctx = canvas.getContext('2d');
        const size = 200;
        
        // Clear canvas
        ctx.fillStyle = '#f8f9fa';
        ctx.fillRect(0, 0, size, size);
        
        // Create a simple pattern
        ctx.fillStyle = '#000000';
        ctx.font = '12px Arial';
        ctx.textAlign = 'center';
        ctx.fillText('QR Code', size/2, size/2 - 10);
        ctx.fillText('Click to open', size/2, size/2 + 10);
        
        // Add border
        ctx.strokeStyle = '#000000';
        ctx.lineWidth = 2;
        ctx.strokeRect(10, 10, size - 20, size - 20);
        
        // Add click handler
        canvas.onclick = () => {
            this.openEmailInBrowser();
            this.hideQRCode();
        };
        
        canvas.style.cursor = 'pointer';
        canvas.title = 'Click to open mailbox';
    }

    // Update autofill with current email
    async updateAutofillEmail() {
        try {
            await chrome.runtime.sendMessage({
                action: 'updateAutofillSettings',
                settings: {
                    currentEmail: this.currentEmail
                }
            });
        } catch (error) {
            console.error('Error updating autofill email:', error);
        }
    }

    // Load current domain and pre-populate input
    async loadCurrentDomain(exceptions) {
        try {
            const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
            if (tabs[0] && tabs[0].url) {
                const url = new URL(tabs[0].url);
                const domain = url.hostname;
                
                // Pre-populate the exception input with current domain
                const input = document.getElementById('exceptionInput');
                if (input && domain && !domain.startsWith('chrome://') && !domain.startsWith('moz-extension://')) {
                    input.placeholder = `Add ${domain} to exception list`;
                    
                    // Show current domain status
                    this.showCurrentDomainStatus(domain, exceptions);
                }
            }
        } catch (error) {
            console.error('Error loading current domain:', error);
        }
    }

    // Show current domain status
    showCurrentDomainStatus(domain, exceptions) {
        const isExcluded = exceptions.includes(domain);
        const statusHtml = `
            <div class="current-domain-status" style="margin-bottom: 8px; padding: 6px; background: ${isExcluded ? '#fee2e2' : '#ecfdf5'}; border-radius: 4px; font-size: 12px;">
                <strong>Current site:</strong> ${domain} 
                <span style="color: ${isExcluded ? '#dc2626' : '#16a34a'};">
                    (${isExcluded ? 'Excluded' : 'Autofill enabled'})
                </span>
            </div>
        `;
        
        const exceptionInput = document.querySelector('.exception-input');
        if (exceptionInput) {
            // Remove existing status
            const existingStatus = exceptionInput.parentNode.querySelector('.current-domain-status');
            if (existingStatus) {
                existingStatus.remove();
            }
            
            // Add new status
            exceptionInput.insertAdjacentHTML('beforebegin', statusHtml);
        }
    }

    // Rating Dialog Methods
    async checkAndShowRatingDialog() {
        try {
            const result = await chrome.storage.local.get([
                'extensionOpens',
                'lastRatingDialogClick',
                'ratingCyclePosition',
                'lastRatingSubmission',
                'ratingDismissedPermanently'
            ]);
            
            const openCount = (result.extensionOpens || 0) + 1;
            const lastDialogClick = result.lastRatingDialogClick || 0;
            const cyclePosition = result.ratingCyclePosition || 0; // 0=first(3), 1=second(5), 2=third+(10)
            const lastSubmission = result.lastRatingSubmission || 0;
            const dismissedPermanently = result.ratingDismissedPermanently || false;
            
            // Update open count
            await chrome.storage.local.set({ extensionOpens: openCount });
            
            console.log(`Extension opened ${openCount} times, cycle position: ${cyclePosition}, last dialog at: ${lastDialogClick}`);
            
            // Check if still in 3-day cooldown period after rating submission
            const now = Date.now();
            const threeDaysInMs = 3 * 24 * 60 * 60 * 1000;
            const isInCooldown = lastSubmission && (now - lastSubmission) < threeDaysInMs;
            
            if (dismissedPermanently || isInCooldown) {
                console.log('Rating dialog suppressed: dismissed permanently or in cooldown');
                return;
            }
            
            // Determine clicks needed since last dialog
            let clicksNeeded;
            if (cyclePosition === 0) {
                clicksNeeded = 3; // First dialog after 3 clicks total
            } else if (cyclePosition === 1) {
                clicksNeeded = 5; // Second dialog after 5 MORE clicks
            } else {
                clicksNeeded = 10; // Subsequent dialogs after 10 MORE clicks each
            }
            
            const clicksSinceLastDialog = openCount - lastDialogClick;
            
            // For first dialog, check total clicks, for others check clicks since last dialog
            const shouldShow = (cyclePosition === 0 && openCount === clicksNeeded) || 
                             (cyclePosition > 0 && clicksSinceLastDialog === clicksNeeded);
            
            if (shouldShow) {
                console.log(`Showing rating dialog after ${clicksSinceLastDialog || openCount} clicks (cycle position ${cyclePosition})`);
                setTimeout(() => {
                    this.showRatingDialog();
                }, 2000); // Show after 2 seconds delay
            }
        } catch (error) {
            console.error('Error checking rating dialog:', error);
        }
    }

    async showRatingDialog() {
        const ratingModal = document.getElementById('ratingModal');
        if (ratingModal) {
            ratingModal.style.display = 'flex';
            
            // Update cycle tracking
            const result = await chrome.storage.local.get(['extensionOpens', 'ratingCyclePosition']);
            const openCount = result.extensionOpens || 0;
            const cyclePosition = result.ratingCyclePosition || 0;
            
            // Move to next cycle position (0->1->2->2->2...)
            const nextCyclePosition = cyclePosition < 2 ? cyclePosition + 1 : 2;
            
            await chrome.storage.local.set({ 
                lastRatingDialogClick: openCount,
                ratingCyclePosition: nextCyclePosition
            });
            
            console.log(`Rating dialog shown, moving to cycle position: ${nextCyclePosition}`);
        }
    }

    hideRatingDialog() {
        const ratingModal = document.getElementById('ratingModal');
        if (ratingModal) {
            ratingModal.style.display = 'none';
        }
    }

    setupRatingEventListeners() {
        // Star rating interactions
        const stars = document.querySelectorAll('.star');
        stars.forEach((star, index) => {
            star.addEventListener('mouseenter', () => {
                this.highlightStars(index + 1);
            });
            
            star.addEventListener('click', () => {
                this.selectRating(index + 1);
            });
        });

        // Reset stars when mouse leaves rating area
        const starRating = document.getElementById('starRating');
        starRating.addEventListener('mouseleave', () => {
            this.resetStarHighlight();
        });

        // Close button
        document.getElementById('ratingCloseBtn').addEventListener('click', () => {
            this.hideRatingDialog();
            // Mark as permanently dismissed after closing
            chrome.storage.local.set({ ratingDismissedPermanently: true });
        });

        // Submit button
        document.getElementById('rateSubmitBtn').addEventListener('click', () => {
            this.submitRating();
        });

        // Later button
        document.getElementById('rateLaterBtn').addEventListener('click', () => {
            this.hideRatingDialog();
            // Don't mark as dismissed, just hide for this session
        });

        // Click outside to close
        document.getElementById('ratingModal').addEventListener('click', (e) => {
            if (e.target.id === 'ratingModal') {
                this.hideRatingDialog();
                // Mark as permanently dismissed after clicking outside
                chrome.storage.local.set({ ratingDismissedPermanently: true });
            }
        });

        // Social media share buttons
        document.getElementById('shareTwitter')?.addEventListener('click', () => {
            this.shareOnTwitter();
        });

        document.getElementById('shareFacebook')?.addEventListener('click', () => {
            this.shareOnFacebook();
        });

        document.getElementById('shareLinkedIn')?.addEventListener('click', () => {
            this.shareOnLinkedIn();
        });

        document.getElementById('shareWhatsApp')?.addEventListener('click', () => {
            this.shareOnWhatsApp();
        });
    }

    highlightStars(rating) {
        const stars = document.querySelectorAll('.star');
        stars.forEach((star, index) => {
            if (index < rating) {
                star.style.color = '#fbbf24';
                star.style.transform = 'scale(1.1)';
            } else {
                star.style.color = '#e2e8f0';
                star.style.transform = 'scale(1)';
            }
        });
    }

    resetStarHighlight() {
        const selectedRating = this.selectedRating || 0;
        const stars = document.querySelectorAll('.star');
        stars.forEach((star, index) => {
            if (index < selectedRating) {
                star.style.color = '#f59e0b';
                star.classList.add('active');
            } else {
                star.style.color = '#e2e8f0';
                star.classList.remove('active');
            }
            star.style.transform = 'scale(1)';
        });
    }

    selectRating(rating) {
        this.selectedRating = rating;
        const stars = document.querySelectorAll('.star');
        const submitBtn = document.getElementById('rateSubmitBtn');
        
        // Animate selected stars
        stars.forEach((star, index) => {
            star.classList.remove('active');
            if (index < rating) {
                star.classList.add('active');
                star.style.color = '#f59e0b';
                
                // Trigger animation
                setTimeout(() => {
                    star.style.animation = 'starPulse 0.6s ease-out';
                }, index * 100); // Stagger animation
                
                // Clear animation after it completes
                setTimeout(() => {
                    star.style.animation = '';
                }, 600 + (index * 100));
            } else {
                star.style.color = '#e2e8f0';
            }
        });
        
        // Enable submit button
        if (submitBtn) {
            submitBtn.disabled = false;
            submitBtn.textContent = `Rate ${rating} Star${rating > 1 ? 's' : ''} on Chrome Web Store`;
        }
        
        console.log(`User selected ${rating} stars`);
    }

    async submitRating() {
        if (!this.selectedRating) return;
        
        try {
            // Track that user submitted rating with 3-day cooldown timestamp
            // Reset cycle to start fresh after cooldown ends
            await chrome.storage.local.set({ 
                ratingSubmitted: true,
                userRating: this.selectedRating,
                lastRatingSubmission: Date.now(), // Store timestamp for 3-day cooldown
                ratingCyclePosition: 0, // Reset cycle to start from 3 clicks again
                lastRatingDialogClick: 0 // Reset click tracking
            });
            
            // Open Chrome Web Store
            const storeUrl = 'https://chromewebstore.google.com/detail/temp-mail-pw-temporary-em/aidndodkpjkakjdhhmkkmjgehflbjbae';
            
            if (chrome.tabs) {
                await chrome.tabs.create({ url: storeUrl });
            } else {
                // Fallback for popup context
                window.open(storeUrl, '_blank');
            }
            
            // Hide dialog
            this.hideRatingDialog();
            
            // Show thank you message
            this.showToast('Thank you for rating! 🌟');
            
            console.log(`Rating submitted: ${this.selectedRating} stars - cycle reset`);
        } catch (error) {
            console.error('Error submitting rating:', error);
            this.showToast('Failed to open Chrome Web Store');
        }
    }

    // Social media share methods
    shareOnTwitter() {
        const text = encodeURIComponent('I\'m loving Temp Mail PW! 📧✨ Perfect for temporary emails and privacy. Check it out!');
        const url = encodeURIComponent('https://chromewebstore.google.com/detail/temp-mail-pw-temporary-em/aidndodkpjkakjdhhmkkmjgehflbjbae');
        const twitterUrl = `https://twitter.com/intent/tweet?text=${text}&url=${url}`;
        
        if (chrome.tabs) {
            chrome.tabs.create({ url: twitterUrl });
        } else {
            window.open(twitterUrl, '_blank');
        }
    }

    shareOnFacebook() {
        const url = encodeURIComponent('https://chromewebstore.google.com/detail/temp-mail-pw-temporary-em/aidndodkpjkakjdhhmkkmjgehflbjbae');
        const facebookUrl = `https://www.facebook.com/sharer/sharer.php?u=${url}`;
        
        if (chrome.tabs) {
            chrome.tabs.create({ url: facebookUrl });
        } else {
            window.open(facebookUrl, '_blank');
        }
    }

    shareOnLinkedIn() {
        const title = encodeURIComponent('Temp Mail PW - Temporary Email Extension');
        const summary = encodeURIComponent('Amazing temporary email extension for privacy and convenience!');
        const url = encodeURIComponent('https://chromewebstore.google.com/detail/temp-mail-pw-temporary-em/aidndodkpjkakjdhhmkkmjgehflbjbae');
        const linkedInUrl = `https://www.linkedin.com/sharing/share-offsite/?url=${url}&title=${title}&summary=${summary}`;
        
        if (chrome.tabs) {
            chrome.tabs.create({ url: linkedInUrl });
        } else {
            window.open(linkedInUrl, '_blank');
        }
    }

    shareOnWhatsApp() {
        const text = encodeURIComponent('Check out Temp Mail PW! 📧 Great temporary email extension: https://chromewebstore.google.com/detail/temp-mail-pw-temporary-em/aidndodkpjkakjdhhmkkmjgehflbjbae');
        const whatsappUrl = `https://wa.me/?text=${text}`;
        
        if (chrome.tabs) {
            chrome.tabs.create({ url: whatsappUrl });
        } else {
            window.open(whatsappUrl, '_blank');
        }
    }

}

// Initialize the extension
let tempMail;
document.addEventListener('DOMContentLoaded', () => {
    tempMail = new TempMailExtension();
});

// Handle window unload
window.addEventListener('beforeunload', () => {
    if (tempMail) {
        tempMail.stopPolling();
    }
});
