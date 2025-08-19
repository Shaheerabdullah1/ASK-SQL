// Global variables
let currentData = null;
let allTablesData = {};
let currentTable = null;
let isRecording = false;
let recognition = null;
let isResizing = false;

// API configuration
const API_BASE_URL = 'http://localhost:3001'; // Change this to your backend URL

// DOM elements
const themeToggle = document.getElementById('themeToggle');
const uploadArea = document.getElementById('uploadArea');
const fileInput = document.getElementById('fileInput');
const deleteDataBtn = document.getElementById('deleteDataBtn');
const previewSection = document.getElementById('previewSection');
const tableSelectorContainer = document.getElementById('tableSelectorContainer');
const tableSelector = document.getElementById('tableSelector');
const chatMessages = document.getElementById('chatMessages');
const chatInput = document.getElementById('chatInput');
const micBtn = document.getElementById('micBtn');
const sendBtn = document.getElementById('sendBtn');
const voiceIndicator = document.getElementById('voiceIndicator');
const loadingOverlay = document.getElementById('loadingOverlay');
const toastContainer = document.getElementById('toastContainer');
const chatStatus = document.getElementById('chatStatus');

// Initialize the application
document.addEventListener('DOMContentLoaded', function() {
    initializeTheme();
    setupEventListeners();
    setupSpeechRecognition();
    checkBrowserSupport();
    setupResizableSidebar();
});

// Theme management
function initializeTheme() {
    const savedTheme = localStorage.getItem('theme') || 'light';
    document.documentElement.setAttribute('data-theme', savedTheme);
    updateThemeIcon(savedTheme);
}

function toggleTheme() {
    const currentTheme = document.documentElement.getAttribute('data-theme');
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    
    document.documentElement.setAttribute('data-theme', newTheme);
    localStorage.setItem('theme', newTheme);
    updateThemeIcon(newTheme);
    
    showToast(`Switched to ${newTheme} theme`, 'success');
}

function updateThemeIcon(theme) {
    const icon = themeToggle.querySelector('i');
    icon.className = theme === 'dark' ? 'fas fa-sun' : 'fas fa-moon';
}

// Event listeners setup
function setupEventListeners() {
    // Theme toggle
    themeToggle.addEventListener('click', toggleTheme);
    
    // File upload
    uploadArea.addEventListener('click', () => fileInput.click());
    uploadArea.addEventListener('dragover', handleDragOver);
    uploadArea.addEventListener('dragleave', handleDragLeave);
    uploadArea.addEventListener('drop', handleDrop);
    fileInput.addEventListener('change', handleFileSelect);
    
    // Table selector
    tableSelector.addEventListener('change', handleTableSelection);
    
    // Delete data
    deleteDataBtn.addEventListener('click', deleteAllData);
    
    // Chat input
    chatInput.addEventListener('keypress', handleChatKeyPress);
    sendBtn.addEventListener('click', sendMessage);
    micBtn.addEventListener('click', toggleVoiceRecording);
    
    // Auto-resize chat input
    chatInput.addEventListener('input', function() {
        this.style.height = 'auto';
        this.style.height = this.scrollHeight + 'px';
    });
}

// File upload handlers
function handleDragOver(e) {
    e.preventDefault();
    uploadArea.classList.add('drag-over');
}

function handleDragLeave(e) {
    e.preventDefault();
    uploadArea.classList.remove('drag-over');
}

function handleDrop(e) {
    e.preventDefault();
    uploadArea.classList.remove('drag-over');
    
    const files = e.dataTransfer.files;
    if (files.length > 0) {
        handleFile(files[0]);
    }
}

function handleFileSelect(e) {
    const file = e.target.files[0];
    if (file) {
        handleFile(file);
    }
}

async function handleFile(file) {
    // Validate file type
    const allowedTypes = ['.csv', '.xlsx', '.xls', '.sql'];
    const fileExtension = '.' + file.name.split('.').pop().toLowerCase();
    
    if (!allowedTypes.includes(fileExtension)) {
        showToast('Please upload a CSV, XLSX, or SQL file', 'error');
        return;
    }
    
    showLoading(true);
    
    try {
        const formData = new FormData();
        formData.append('file', file);
        
        const response = await fetch(`${API_BASE_URL}/upload`, {
            method: 'POST',
            body: formData
        });
        
        if (!response.ok) {
            throw new Error(`Upload failed: ${response.statusText}`);
        }
        
        const data = await response.json();
        
        // Handle both single table and multiple tables
        if (data.tables && Array.isArray(data.tables)) {
            // Multiple tables case (SQL file)
            allTablesData = {};
            data.tables.forEach(table => {
                allTablesData[table.table_name] = table;
            });
            
            currentData = data.tables[0]; // Default to first table
            currentTable = data.tables[0].table_name;
            
            setupTableSelector(data.tables);
            displayDataPreview(currentData);
            enableChat();
            
            showToast(`File "${file.name}" uploaded successfully! Found ${data.tables.length} tables.`, 'success');
            
            addMessage('bot', `Great! I've loaded your SQL file "${file.name}". 
                       It contains ${data.tables.length} tables: ${data.tables.map(t => t.table_name).join(', ')}. 
                       Currently showing "${currentTable}" with ${currentData.total_rows} rows and ${currentData.columns.length} columns. 
                       You can switch between tables using the dropdown above and ask me questions about your data!`);
        } else {
            // Single table case (CSV, XLSX)
            currentData = data;
            currentTable = data.table_name;
            allTablesData = { [data.table_name]: data };
            
            hideTableSelector();
            displayDataPreview(data);
            enableChat();
            
            showToast(`File "${file.name}" uploaded successfully!`, 'success');
            
            addMessage('bot', `Great! I've loaded your data file "${file.name}". 
                       It contains ${data.total_rows} rows and ${data.columns.length} columns. 
                       You can now ask me questions about your data!`);
        }
        
    } catch (error) {
        console.error('Upload error:', error);
        showToast(`Upload failed: ${error.message}`, 'error');
    } finally {
        showLoading(false);
    }
}

function setupTableSelector(tables) {
    // Show table selector
    tableSelectorContainer.style.display = 'block';
    
    // Clear existing options
    tableSelector.innerHTML = '';
    
    // Add options for each table
    tables.forEach(table => {
        const option = document.createElement('option');
        option.value = table.table_name;
        option.textContent = `${table.table_name} (${table.total_rows} rows, ${table.columns.length} cols)`;
        tableSelector.appendChild(option);
    });
    
    // Set first table as selected
    tableSelector.value = tables[0].table_name;
}

function hideTableSelector() {
    tableSelectorContainer.style.display = 'none';
}

function handleTableSelection(e) {
    const selectedTableName = e.target.value;
    const selectedTable = allTablesData[selectedTableName];
    
    if (selectedTable) {
        currentData = selectedTable;
        currentTable = selectedTableName;
        displayDataPreview(selectedTable);
        
        showToast(`Switched to table: ${selectedTableName}`, 'success');
        
        addMessage('bot', `Switched to table "${selectedTableName}" with ${selectedTable.total_rows} rows and ${selectedTable.columns.length} columns. What would you like to know about this table?`);
    }
}

function displayDataPreview(data) {
    // Show preview section
    previewSection.style.display = 'block';
    deleteDataBtn.style.display = 'block';
    
    // Update table info
    const tableInfo = document.getElementById('tableInfo');
    const maxPreviewRows = 20;
    const rowsToShow = Math.min(data.rows.length, maxPreviewRows);
    tableInfo.textContent = `Table: ${data.table_name} | Rows: ${data.total_rows} | Columns: ${data.columns.length} | Showing: ${rowsToShow} rows`;
    
    // Create table header
    const tableHeader = document.getElementById('tableHeader');
    tableHeader.innerHTML = '';
    const headerRow = document.createElement('tr');
    data.columns.forEach(column => {
        const th = document.createElement('th');
        th.textContent = column;
        th.title = column; // Tooltip for long column names
        headerRow.appendChild(th);
    });
    tableHeader.appendChild(headerRow);
    
    // Create table body
    const tableBody = document.getElementById('tableBody');
    tableBody.innerHTML = '';
    
    // Ensure we have rows to display
    const rowsToDisplay = data.rows || [];
    const limitedRows = rowsToDisplay.slice(0, maxPreviewRows);
    
    limitedRows.forEach((row, index) => {
        const tr = document.createElement('tr');
        data.columns.forEach(column => {
            const td = document.createElement('td');
            const value = row[column];
            const displayValue = value !== null && value !== undefined ? String(value) : '';
            td.textContent = displayValue;
            td.title = displayValue; // Tooltip for truncated text
            tr.appendChild(td);
        });
        tableBody.appendChild(tr);
    });
    
    // Update upload area to show success
    const uploadPlaceholder = uploadArea.querySelector('.upload-placeholder');
    const tableCount = Object.keys(allTablesData).length;
    const tableText = tableCount > 1 ? `${tableCount} tables` : `${data.table_name}`;
    
    uploadPlaceholder.innerHTML = `
        <i class="fas fa-check-circle" style="color: var(--success-color);"></i>
        <p style="color: var(--success-color);">File uploaded successfully!</p>
        <small>${tableText} - Currently: ${data.table_name} (${data.total_rows} rows, ${data.columns.length} columns) - Preview: ${Math.min(data.rows.length, 20)} rows</small>
    `;
}

function enableChat() {
    chatInput.disabled = false;
    micBtn.disabled = false;
    sendBtn.disabled = false;
    chatInput.placeholder = "Ask a question about your data...";
    
    // Update chat status
    const statusText = chatStatus.querySelector('span:last-child');
    statusText.textContent = 'Ready to answer questions';
}

async function deleteAllData() {
    if (!confirm('Are you sure you want to delete all uploaded data?')) {
        return;
    }
    
    showLoading(true);
    
    try {
        const response = await fetch(`${API_BASE_URL}/delete-data`, {
            method: 'DELETE'
        });
        
        if (!response.ok) {
            throw new Error(`Delete failed: ${response.statusText}`);
        }
        
        const data = await response.json();
        
        // Reset UI
        currentData = null;
        allTablesData = {};
        currentTable = null;
        previewSection.style.display = 'none';
        deleteDataBtn.style.display = 'none';
        hideTableSelector();
        
        // Reset upload area
        const uploadPlaceholder = uploadArea.querySelector('.upload-placeholder');
        uploadPlaceholder.innerHTML = `
            <i class="fas fa-cloud-upload-alt"></i>
            <p>Drop your file here or click to browse</p>
            <small>Supports CSV, XLSX, SQL files</small>
        `;
        
        // Disable chat
        chatInput.disabled = true;
        micBtn.disabled = true;
        sendBtn.disabled = true;
        chatInput.placeholder = "Upload data to start chatting...";
        
        // Update chat status
        const statusText = chatStatus.querySelector('span:last-child');
        statusText.textContent = 'Waiting for data upload';
        
        // Clear file input
        fileInput.value = '';
        
        showToast('All data deleted successfully', 'success');
        
        // Add system message
        addMessage('bot', 'All data has been deleted. Please upload a new file to continue.');
        
    } catch (error) {
        console.error('Delete error:', error);
        showToast(`Delete failed: ${error.message}`, 'error');
    } finally {
        showLoading(false);
    }
}

// Chat functionality
function handleChatKeyPress(e) {
    if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
    }
}

async function sendMessage() {
    const message = chatInput.value.trim();
    if (!message || !currentData) return;
    
    // Add user message to chat
    addMessage('user', message);
    chatInput.value = '';
    
    // Show loading state
    const botMessageElement = addMessage('bot', '', true);
    
    try {
        const requestBody = {
            query: message,
            table_name: currentTable || currentData.table_name
        };
        
        const response = await fetch(`${API_BASE_URL}/ask`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(requestBody)
        });
        
        if (!response.ok) {
            throw new Error(`Query failed: ${response.statusText}`);
        }
        
        const data = await response.json();
        
        // Update bot message with response
        updateBotMessage(botMessageElement, data);
        
    } catch (error) {
        console.error('Chat error:', error);
        updateBotMessage(botMessageElement, {
            error: error.message,
            sql: null,
            result: []
        });
    }
}

function addMessage(sender, content, isLoading = false) {
    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${sender}-message`;
    
    const avatar = document.createElement('div');
    avatar.className = `${sender}-avatar`;
    avatar.innerHTML = sender === 'user' ? '<i class="fas fa-user"></i>' : '<i class="fas fa-robot"></i>';
    
    const messageContent = document.createElement('div');
    messageContent.className = 'message-content';
    
    if (isLoading) {
        messageContent.innerHTML = `
            <div class="message-bubble">
                <div class="typing-indicator">
                    <span></span>
                    <span></span>
                    <span></span>
                </div>
            </div>
        `;
    } else {
        const bubble = document.createElement('div');
        bubble.className = 'message-bubble';
        bubble.innerHTML = content.replace(/\n/g, '<br>');
        
        const time = document.createElement('div');
        time.className = 'message-time';
        time.textContent = new Date().toLocaleTimeString();
        
        messageContent.appendChild(bubble);
        messageContent.appendChild(time);
    }
    
    messageDiv.appendChild(avatar);
    messageDiv.appendChild(messageContent);
    
    chatMessages.appendChild(messageDiv);
    chatMessages.scrollTop = chatMessages.scrollHeight;
    
    return messageDiv;
}

function updateBotMessage(messageElement, data) {
    const messageContent = messageElement.querySelector('.message-content');
    
    if (data.error) {
        messageContent.innerHTML = `
            <div class="message-bubble">
                <p>❌ I encountered an error while processing your question:</p>
                <p><strong>${data.error}</strong></p>
                <p>Please try rephrasing your question or check if your data is properly formatted.</p>
            </div>
            <div class="message-time">${new Date().toLocaleTimeString()}</div>
        `;
    } else {
        let responseHTML = `
            <div class="message-bubble">
                <p>Here's what I found${currentTable ? ` in table "${currentTable}"` : ''}:</p>
            </div>
        `;
        
        // Add SQL query if available
        if (data.sql) {
            responseHTML += `
                <div class="sql-query">
                    <strong>SQL Query:</strong><br>
                    <code>${data.sql}</code>
                </div>
            `;
        }
        
        // Add results table
        if (data.result && data.result.length > 0) {
            const resultColumns = data.columns || Object.keys(data.result[0]);
            const maxVisibleRows = 10;
            const totalRows = data.result.length;
            const showScrollInfo = totalRows > maxVisibleRows;
            
            responseHTML += `
                <div class="result-table">
                    <div class="result-table-wrapper">
                        <table>
                            <thead>
                                <tr>
                                    ${resultColumns.map(col => `<th>${col}</th>`).join('')}
                                </tr>
                            </thead>
                            <tbody>
                                ${data.result.map(row => `
                                    <tr>
                                        ${resultColumns.map(col => {
                                            const value = row[col];
                                            const displayValue = value !== null && value !== undefined ? String(value) : '';
                                            return `<td title="${displayValue}">${displayValue}</td>`;
                                        }).join('')}
                                    </tr>
                                `).join('')}
                            </tbody>
                        </table>
                    </div>
                    ${showScrollInfo ? `<div class="result-table-info">Showing all ${totalRows} rows - scroll to view more</div>` : ''}
                </div>
            `;
        } else {
            responseHTML += `<div class="message-bubble"><p>No results found for your query.</p></div>`;
        }
        
        responseHTML += `<div class="message-time">${new Date().toLocaleTimeString()}</div>`;
        
        messageContent.innerHTML = responseHTML;
    }
    
    chatMessages.scrollTop = chatMessages.scrollHeight;
}

// Speech recognition setup
function setupSpeechRecognition() {
    if ('webkitSpeechRecognition' in window || 'SpeechRecognition' in window) {
        const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
        recognition = new SpeechRecognition();
        
        recognition.continuous = false;
        recognition.interimResults = false;
        recognition.lang = 'en-US';
        
        recognition.onstart = function() {
            isRecording = true;
            micBtn.classList.add('recording');
            voiceIndicator.style.display = 'flex';
            showToast('Listening... Speak now!', 'success');
        };
        
        recognition.onresult = function(event) {
            const transcript = event.results[0][0].transcript;
            chatInput.value = transcript;
            chatInput.focus();
            showToast('Speech recognized successfully!', 'success');
        };
        
        recognition.onerror = function(event) {
            console.error('Speech recognition error:', event.error);
            showToast(`Speech recognition error: ${event.error}`, 'error');
        };
        
        recognition.onend = function() {
            isRecording = false;
            micBtn.classList.remove('recording');
            voiceIndicator.style.display = 'none';
        };
    } else {
        micBtn.style.display = 'none';
        console.warn('Speech recognition not supported in this browser');
    }
}

function toggleVoiceRecording() {
    if (!recognition) {
        showToast('Speech recognition not supported', 'warning');
        return;
    }
    
    if (isRecording) {
        recognition.stop();
    } else {
        recognition.start();
    }
}

// Utility functions
function showLoading(show) {
    loadingOverlay.style.display = show ? 'flex' : 'none';
}

function showToast(message, type = 'success') {
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    
    toastContainer.appendChild(toast);
    
    // Auto remove after 3 seconds
    setTimeout(() => {
        if (toast.parentNode) {
            toast.parentNode.removeChild(toast);
        }
    }, 3000);
}

function checkBrowserSupport() {
    // Check for required features
    const features = {
        'File API': window.File && window.FileReader && window.FileList && window.Blob,
        'Drag and Drop': 'draggable' in document.createElement('div'),
        'Speech Recognition': 'webkitSpeechRecognition' in window || 'SpeechRecognition' in window,
        'LocalStorage': typeof(Storage) !== "undefined"
    };
    
    const unsupported = Object.entries(features)
        .filter(([name, supported]) => !supported)
        .map(([name]) => name);
    
    if (unsupported.length > 0) {
        console.warn('Unsupported features:', unsupported);
        if (!features['Speech Recognition']) {
            micBtn.style.display = 'none';
        }
    }
}

// Setup resizable sidebar
function setupResizableSidebar() {
    const sidebar = document.querySelector('.sidebar');
    let startX, startWidth;
    
    function initResize(e) {
        if (e.offsetX > sidebar.offsetWidth - 10) {
            isResizing = true;
            startX = e.clientX;
            startWidth = parseInt(document.defaultView.getComputedStyle(sidebar).width, 10);
            document.addEventListener('mousemove', doResize);
            document.addEventListener('mouseup', stopResize);
            document.body.style.cursor = 'col-resize';
            e.preventDefault();
        }
    }
    
    function doResize(e) {
        if (!isResizing) return;
        const newWidth = startWidth + e.clientX - startX;
        if (newWidth >= 300 && newWidth <= 600) {
            sidebar.style.width = newWidth + 'px';
        }
    }
    
    function stopResize() {
        isResizing = false;
        document.removeEventListener('mousemove', doResize);
        document.removeEventListener('mouseup', stopResize);
        document.body.style.cursor = 'default';
    }
    
    sidebar.addEventListener('mousedown', initResize);
    
    // Add hover effect for resize cursor
    sidebar.addEventListener('mousemove', function(e) {
        if (e.offsetX > sidebar.offsetWidth - 10) {
            sidebar.style.cursor = 'col-resize';
        } else {
            sidebar.style.cursor = 'default';
        }
    });
}