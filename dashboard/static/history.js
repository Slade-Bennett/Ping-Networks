// Ping-Networks History Page JavaScript

let trendChart = null;

// Initialize history page on load
document.addEventListener('DOMContentLoaded', function() {
    loadHistory();
    initializeTrendChart();
});

// Load scan history
async function loadHistory() {
    try {
        const response = await fetch('/api/history?limit=50');
        const history = await response.json();

        const tbody = document.getElementById('historyBody');

        if (history.length === 0) {
            tbody.innerHTML = '<tr><td colspan="7" class="empty-state">No scan history available</td></tr>';
            return;
        }

        tbody.innerHTML = '';

        history.forEach(scan => {
            const row = document.createElement('tr');
            const startTime = new Date(scan.startTime);
            const duration = calculateDuration(scan.startTime, scan.endTime);

            row.innerHTML = `
                <td>${startTime.toLocaleString()}</td>
                <td>${scan.network || 'N/A'}</td>
                <td>${formatNumber(scan.hostsScanned)}</td>
                <td style="color: #48bb78; font-weight: 600;">${formatNumber(scan.hostsReachable)}</td>
                <td style="color: #f56565; font-weight: 600;">${formatNumber(scan.hostsUnreachable)}</td>
                <td>${duration}</td>
                <td>
                    <button class="btn btn-small btn-secondary" onclick="viewScanDetails('${scan.scanId}')">
                        View
                    </button>
                </td>
            `;

            tbody.appendChild(row);
        });

        // Update trend chart with new data
        updateTrendChart(history);
    } catch (error) {
        console.error('Error loading history:', error);
        const tbody = document.getElementById('historyBody');
        tbody.innerHTML = '<tr><td colspan="7" class="empty-state">Error loading history</td></tr>';
    }
}

// Initialize trend chart
async function initializeTrendChart() {
    try {
        const response = await fetch('/api/history?limit=30');
        const history = await response.json();

        if (history.length === 0) {
            return;
        }

        const ctx = document.getElementById('trendChart').getContext('2d');

        // Sort by date
        const sortedHistory = history.sort((a, b) => new Date(a.startTime) - new Date(b.startTime));

        // Prepare chart data
        const labels = sortedHistory.map(scan => {
            const date = new Date(scan.startTime);
            return date.toLocaleDateString();
        });

        const reachabilityData = sortedHistory.map(scan => {
            const total = scan.hostsScanned;
            const reachable = scan.hostsReachable;
            return total > 0 ? ((reachable / total) * 100).toFixed(1) : 0;
        });

        const hostsScannedData = sortedHistory.map(scan => scan.hostsScanned || 0);

        trendChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: labels,
                datasets: [
                    {
                        label: 'Reachability Rate (%)',
                        data: reachabilityData,
                        borderColor: '#667eea',
                        backgroundColor: 'rgba(102, 126, 234, 0.1)',
                        tension: 0.4,
                        yAxisID: 'y'
                    },
                    {
                        label: 'Hosts Scanned',
                        data: hostsScannedData,
                        borderColor: '#48bb78',
                        backgroundColor: 'rgba(72, 187, 120, 0.1)',
                        tension: 0.4,
                        yAxisID: 'y1'
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                interaction: {
                    mode: 'index',
                    intersect: false
                },
                plugins: {
                    title: {
                        display: true,
                        text: 'Network Availability Trend (Last 30 Scans)'
                    },
                    legend: {
                        position: 'bottom'
                    }
                },
                scales: {
                    y: {
                        type: 'linear',
                        display: true,
                        position: 'left',
                        min: 0,
                        max: 100,
                        title: {
                            display: true,
                            text: 'Reachability %'
                        }
                    },
                    y1: {
                        type: 'linear',
                        display: true,
                        position: 'right',
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Hosts Scanned'
                        },
                        grid: {
                            drawOnChartArea: false
                        }
                    }
                }
            }
        });
    } catch (error) {
        console.error('Error initializing trend chart:', error);
    }
}

// Update trend chart with new data
function updateTrendChart(history) {
    if (!trendChart || history.length === 0) {
        return;
    }

    // Sort by date
    const sortedHistory = history.sort((a, b) => new Date(a.startTime) - new Date(b.startTime));

    // Update labels and data
    const labels = sortedHistory.map(scan => {
        const date = new Date(scan.startTime);
        return date.toLocaleDateString();
    });

    const reachabilityData = sortedHistory.map(scan => {
        const total = scan.hostsScanned;
        const reachable = scan.hostsReachable;
        return total > 0 ? ((reachable / total) * 100).toFixed(1) : 0;
    });

    const hostsScannedData = sortedHistory.map(scan => scan.hostsScanned || 0);

    trendChart.data.labels = labels;
    trendChart.data.datasets[0].data = reachabilityData;
    trendChart.data.datasets[1].data = hostsScannedData;
    trendChart.update();
}

// View scan details
function viewScanDetails(scanId) {
    // In a full implementation, this would open a modal or navigate to a details page
    alert(`Scan details for ${scanId}\n\nThis feature would display:\n- Complete host list\n- Response times\n- Hostname information\n- Network statistics\n\nImplementation pending.`);
}

// Calculate duration between two dates
function calculateDuration(start, end) {
    if (!start || !end) {
        return 'N/A';
    }

    const startTime = new Date(start);
    const endTime = new Date(end);
    const diff = endTime - startTime;

    const hours = Math.floor(diff / 3600000);
    const minutes = Math.floor((diff % 3600000) / 60000);
    const seconds = Math.floor((diff % 60000) / 1000);

    if (hours > 0) {
        return `${hours}h ${minutes}m ${seconds}s`;
    } else if (minutes > 0) {
        return `${minutes}m ${seconds}s`;
    } else {
        return `${seconds}s`;
    }
}

// Utility function to format numbers with commas
function formatNumber(num) {
    if (!num) return '0';
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}
