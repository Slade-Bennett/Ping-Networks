// Ping-Networks Dashboard JavaScript

// Global variables
let recentScansChart = null;
let activeScansPolling = null;

// Initialize dashboard on load
document.addEventListener('DOMContentLoaded', function() {
    loadDashboardStatus();
    loadActiveScans();
    setupScanForm();
    initializeCharts();

    // Start polling for updates every 2 seconds
    setInterval(loadDashboardStatus, 2000);
    setInterval(loadActiveScans, 2000);
});

// Load dashboard status
async function loadDashboardStatus() {
    try {
        const response = await fetch('/api/status');
        const data = await response.json();

        document.getElementById('activeScans').textContent = data.activeScans;
        document.getElementById('totalScans').textContent = data.totalScans || '0';
        document.getElementById('hostsScanned').textContent = formatNumber(data.hostsScanned) || '0';
        document.getElementById('reachableRate').textContent = data.reachableRate ? `${data.reachableRate}%` : '-%';
    } catch (error) {
        console.error('Error loading dashboard status:', error);
    }
}

// Load active scans
async function loadActiveScans() {
    try {
        const response = await fetch('/api/status');
        const data = await response.json();

        const container = document.getElementById('activeScansList');

        if (data.activeScans === 0) {
            container.innerHTML = '<p class="empty-state">No active scans</p>';
        } else {
            // In a real implementation, we'd fetch individual scan details
            container.innerHTML = '<p class="empty-state">Scan monitoring active...</p>';
        }
    } catch (error) {
        console.error('Error loading active scans:', error);
    }
}

// Setup scan form submission
function setupScanForm() {
    const form = document.getElementById('scanForm');

    form.addEventListener('submit', async function(e) {
        e.preventDefault();

        const network = document.getElementById('networkInput').value;
        const throttle = parseInt(document.getElementById('throttle').value) || 50;
        const maxPings = document.getElementById('maxPings').value ? parseInt(document.getElementById('maxPings').value) : null;

        try {
            const response = await fetch('/api/scan/start', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    network: network,
                    throttle: throttle,
                    maxPings: maxPings,
                    timeout: 1,
                    count: 1
                })
            });

            const result = await response.json();

            if (response.ok) {
                showNotification('Scan started successfully!', 'success');
                form.reset();

                // Start monitoring the scan
                monitorScan(result.scanId);
            } else {
                showNotification('Failed to start scan: ' + (result.error || 'Unknown error'), 'error');
            }
        } catch (error) {
            console.error('Error starting scan:', error);
            showNotification('Error starting scan: ' + error.message, 'error');
        }
    });
}

// Monitor scan progress
async function monitorScan(scanId) {
    const container = document.getElementById('activeScansList');

    // Create scan item element
    const scanItem = document.createElement('div');
    scanItem.className = 'scan-item';
    scanItem.id = `scan-${scanId}`;
    scanItem.innerHTML = `
        <div class="scan-info">
            <h4>${scanId}</h4>
            <p>Starting scan...</p>
        </div>
        <div class="scan-status">
            <div class="progress-bar">
                <div class="progress-fill" style="width: 0%"></div>
            </div>
            <span class="status-badge status-running">Running</span>
        </div>
    `;

    // Replace empty state if present
    if (container.querySelector('.empty-state')) {
        container.innerHTML = '';
    }

    container.appendChild(scanItem);

    // Poll for updates
    const interval = setInterval(async () => {
        try {
            const response = await fetch(`/api/scan/${scanId}`);
            const scan = await response.json();

            if (scan.error) {
                clearInterval(interval);
                return;
            }

            // Update progress
            const progressFill = scanItem.querySelector('.progress-fill');
            progressFill.style.width = `${scan.progress || 0}%`;

            // Update status
            const statusBadge = scanItem.querySelector('.status-badge');
            const scanInfo = scanItem.querySelector('.scan-info p');

            if (scan.status === 'completed') {
                statusBadge.className = 'status-badge status-completed';
                statusBadge.textContent = 'Completed';
                scanInfo.textContent = `Scanned ${scan.results.length} hosts`;
                clearInterval(interval);

                // Reload dashboard stats after completion
                setTimeout(loadDashboardStatus, 1000);

                // Remove from active scans after 5 seconds
                setTimeout(() => {
                    scanItem.remove();
                    if (container.children.length === 0) {
                        container.innerHTML = '<p class="empty-state">No active scans</p>';
                    }
                }, 5000);
            } else if (scan.status === 'failed') {
                statusBadge.className = 'status-badge status-failed';
                statusBadge.textContent = 'Failed';
                scanInfo.textContent = 'Scan failed';
                clearInterval(interval);
            }
        } catch (error) {
            console.error('Error monitoring scan:', error);
            clearInterval(interval);
        }
    }, 1000);
}

// Initialize charts
async function initializeCharts() {
    try {
        const response = await fetch('/api/history?limit=10');
        const history = await response.json();

        if (history.length === 0) {
            return;
        }

        const ctx = document.getElementById('recentScansChart').getContext('2d');

        // Prepare chart data
        const labels = history.reverse().map(scan => {
            const date = new Date(scan.startTime);
            return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
        });

        const reachableData = history.map(scan => scan.hostsReachable || 0);
        const unreachableData = history.map(scan => scan.hostsUnreachable || 0);

        recentScansChart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: labels,
                datasets: [
                    {
                        label: 'Reachable',
                        data: reachableData,
                        backgroundColor: '#48bb78',
                        borderColor: '#38a169',
                        borderWidth: 1
                    },
                    {
                        label: 'Unreachable',
                        data: unreachableData,
                        backgroundColor: '#f56565',
                        borderColor: '#e53e3e',
                        borderWidth: 1
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        stacked: true
                    },
                    x: {
                        stacked: true
                    }
                },
                plugins: {
                    title: {
                        display: true,
                        text: 'Last 10 Scans'
                    },
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        });
    } catch (error) {
        console.error('Error initializing charts:', error);
    }
}

// Utility functions
function formatNumber(num) {
    if (!num) return '0';
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.textContent = message;
    notification.style.cssText = `
        position: fixed;
        top: 80px;
        right: 20px;
        padding: 1rem 1.5rem;
        background: ${type === 'success' ? '#48bb78' : type === 'error' ? '#f56565' : '#4299e1'};
        color: white;
        border-radius: 5px;
        box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
        z-index: 10000;
        animation: slideIn 0.3s ease;
    `;

    document.body.appendChild(notification);

    // Remove after 5 seconds
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => notification.remove(), 300);
    }, 5000);
}

// Add CSS animations
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from {
            transform: translateX(400px);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }

    @keyframes slideOut {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(400px);
            opacity: 0;
        }
    }
`;
document.head.appendChild(style);
