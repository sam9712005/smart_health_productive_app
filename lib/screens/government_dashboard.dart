import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_services.dart';
import '../services/download_service.dart';
import '../services/government_pdf_service.dart';
import '../constants/app_colors.dart';
import '../gen/l10n/app_localizations.dart';
import 'login.dart';
import 'citizen_profile_edit.dart';

class GovernmentDashboard extends StatefulWidget {
  const GovernmentDashboard({Key? key}) : super(key: key);

  @override
  State<GovernmentDashboard> createState() => _GovernmentDashboardState();
}

class _GovernmentDashboardState extends State<GovernmentDashboard> {
  late Future<Map<String, dynamic>> _analyticsFuture;
  late Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = ApiService.getGovernmentAnalytics();
    
    // Auto-refresh analytics every 2 minutes
    _refreshTimer = Timer.periodic(const Duration(seconds: 120), (_) {
      if (mounted) {
        setState(() {
          _analyticsFuture = ApiService.getGovernmentAnalytics();
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  Future<void> _downloadAnalyticsPDF() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating Government Analytics Report PDF...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Get JWT token from ApiService
      final authToken = await ApiService.getToken();
      print('[Download] Token retrieved: ${authToken != null ? "YES" : "NO"}');

      if (authToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication required. Please login again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Get the latest analytics data
      final data = await ApiService.getGovernmentAnalytics();

      // Generate PDF with all analytics data
      final pdfBytes = await GovernmentPDFService.generateGovernmentAnalyticsPDF(data);

      if (mounted) {
        // Use unified DownloadService for cross-platform support
        await DownloadService.downloadFile(
          'Government_Analytics_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
          pdfBytes.toList(),
          mimeType: 'application/pdf',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analytics report downloaded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('[Download] Exception: $e');
      if (mounted) {
        // Provide more specific error messages
        String errorMessage = 'Error downloading report';

        if (e.toString().contains('Storage permission')) {
          errorMessage = 'Storage permission denied. Please enable it in app settings.';
        } else if (e.toString().contains('permanently denied')) {
          errorMessage =
              'Storage permission permanently denied. Go to Settings > Permissions > Storage and enable it.';
        } else if (e.toString().contains('Timeout')) {
          errorMessage = 'Download timeout. Please check your internet connection.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GOVERNMENT HEALTH ANALYTICS',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: loc.refresh_data,
            onPressed: () {
              setState(() {
                _analyticsFuture = ApiService.getGovernmentAnalytics();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _analyticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading Government Analytics...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.emergency.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 60,
                      color: AppColors.emergency,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to Load Analytics',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _analyticsFuture = ApiService.getGovernmentAnalytics();
                      });
                    },
                    child: Text(loc.retry),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(child: Text(loc.no_data));
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Executive Summary',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Health Emergency Response System Dashboard',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Last Updated: ${DateTime.now().toString().split('.')[0]}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Key Metrics Section
                  _buildSectionHeader('KEY PERFORMANCE INDICATORS'),
                  const SizedBox(height: 12),
                  _buildMetricsGrid([
                    _buildMetricCard(
                      'Active Hospitals',
                      '${data['active_hospitals'] ?? '0'}',
                      Icons.local_hospital,
                      Colors.blue,
                    ),
                    _buildMetricCard(
                      'Total Beds',
                      '${data['total_beds'] ?? '0'}',
                      Icons.bed,
                      Colors.purple,
                    ),
                    _buildMetricCard(
                      'ICU Beds',
                      '${data['icu_beds'] ?? '0'}',
                      Icons.medical_services,
                      Colors.orange,
                    ),
                    _buildMetricCard(
                      'Oxygen Hospitals',
                      '${data['oxygen_hospitals'] ?? '0'}',
                      Icons.air,
                      Colors.teal,
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Alert Analytics Section
                  _buildSectionHeader('ALERT & RESPONSE ANALYTICS'),
                  const SizedBox(height: 12),
                  _buildMetricsGrid([
                    _buildMetricCard(
                      'Total SOS Calls',
                      '${data['total_alerts'] ?? '0'}',
                      Icons.phone_in_talk,
                      Colors.red,
                    ),
                    _buildMetricCard(
                      'Completed',
                      '${data['completed_alerts'] ?? '0'}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildMetricCard(
                      'Avg Response Time',
                      '${data['avg_eta'] ?? '0'} min',
                      Icons.schedule,
                      Colors.indigo,
                    ),
                    _buildMetricCard(
                      'Ambulances',
                      '${data['ambulance_count'] ?? '0'}',
                      Icons.local_taxi,
                      Colors.amber,
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Completion Rate Card
                  _buildCompletionRateCard(data),
                  const SizedBox(height: 20),

                  // Severity Distribution
                  _buildSectionHeader('ALERT SEVERITY DISTRIBUTION'),
                  const SizedBox(height: 12),
                  _buildSeverityDistribution(data),
                  const SizedBox(height: 20),

                  // Status Distribution
                  _buildSectionHeader('ALERT STATUS DISTRIBUTION'),
                  const SizedBox(height: 12),
                  _buildResponseStatus(data),
                  const SizedBox(height: 20),

                  // ETA Statistics
                  _buildSectionHeader('AMBULANCE RESPONSE PERFORMANCE'),
                  const SizedBox(height: 12),
                  _buildEtaAnalytics(data),
                  const SizedBox(height: 20),

                  // Digital Adoption
                  _buildSectionHeader('DIGITAL ADOPTION'),
                  const SizedBox(height: 12),
                  _buildEngagementMetrics(data),
                  const SizedBox(height: 20),

                  // Infrastructure Status
                  _buildSectionHeader('HOSPITAL INFRASTRUCTURE'),
                  const SizedBox(height: 12),
                  _buildInfrastructureStatus(data),
                  const SizedBox(height: 20),

                  // Download Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _downloadAnalyticsPDF,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Download Complete Report (PDF)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          border: Border(
            left: BorderSide(color: AppColors.primary, width: 4),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(List<Widget> cards) {
    return RepaintBoundary(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionRateCard(Map<String, dynamic> data) {
    final completed = (data['completed_alerts'] ?? 0).toInt();
    final total = (data['total_alerts'] ?? 1).toInt();
    final completionRate = total > 0 ? (completed / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
        ),
        border: Border.all(color: Colors.green[300]!, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Alert Completion Rate',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Icon(Icons.trending_up, color: Colors.green[600], size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: completionRate / 100,
                    minHeight: 12,
                    backgroundColor: Colors.green[200],
                    valueColor: AlwaysStoppedAnimation(Colors.green[600]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${completionRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$completed of $total alerts completed',
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadReport(Map<String, dynamic> data) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report generation in progress...')),
      );
      // TODO: Implement report download via API
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Widget _buildSeverityDistribution(Map<String, dynamic> data) {
    final severity = data['severity_distribution'] ?? {};
    final low = (severity['low'] ?? 0).toDouble();
    final medium = (severity['medium'] ?? 0).toDouble();
    final high = (severity['high'] ?? 0).toDouble();
    final total = low + medium + high;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Alert Severity Distribution',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _SeverityBar('Low Risk', total > 0 ? (low / total) * 100 : 0, Colors.green),
            const SizedBox(height: 12),
            _SeverityBar(
                'Medium Risk', total > 0 ? (medium / total) * 100 : 0, Colors.orange),
            const SizedBox(height: 12),
            _SeverityBar('High Risk', total > 0 ? (high / total) * 100 : 0, Colors.red),
            const SizedBox(height: 16),
            Text(
              'Total Alerts: ${low.toInt() + medium.toInt() + high.toInt()}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard(Map<String, dynamic> data) {
    final completed = (data['completed_alerts'] ?? 0).toInt();
    final total = (data['total_alerts'] ?? 1).toInt();
    final completionRate = total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Alert Completion Rate',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                '$completionRate%',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[600]),
              ),
              Text('$completed / $total alerts completed',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          Icon(Icons.trending_up, size: 40, color: Colors.green[400]),
        ],
      ),
    );
  }

  Widget _buildEngagementMetrics(Map<String, dynamic> data) {
    final avgEta = data['avg_eta'] ?? 0;
    final totalAlerts = (data['total_alerts'] ?? 0).toString();
    final totalCitizens = (data['total_citizens'] ?? 0).toString();
    final avgEtaStr = (avgEta ?? 0).toString();

    String digitalAdoptionStr = 'N/A';
    if (data.containsKey('digital_adoption') && data['digital_adoption'] != null) {
      digitalAdoptionStr = '${data['digital_adoption']}%';
    } else if (data.containsKey('registered_citizens') && data['registered_citizens'] != null && (data['total_citizens'] ?? 0) is num && (data['total_citizens'] as num) > 0) {
      try {
        final reg = (data['registered_citizens'] as num).toDouble();
        final total = (data['total_citizens'] as num).toDouble();
        digitalAdoptionStr = '${((reg / total) * 100).toStringAsFixed(1)}%';
      } catch (_) {
        digitalAdoptionStr = 'N/A';
      }
    }

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricRow('Total SOS Calls', totalAlerts, '📞'),
            _MetricRow('Active Citizens', totalCitizens, '🏥'),
            _MetricRow('Avg Response Time', '$avgEtaStr min', '⏱️'),
            _MetricRow('Digital Adoption', digitalAdoptionStr, '📱'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfrastructureStatus(Map<String, dynamic> data) {
    final totalBeds = data['total_beds'] ?? 0;
    final icuBeds = data['icu_beds'] ?? 0;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hospital Infrastructure Status',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _InfraRow('Total Hospital Beds', '$totalBeds', Colors.blue),
            _InfraRow('ICU Beds', '$icuBeds', Colors.orange),
            _InfraRow('Oxygen-Ready Hospitals', '${data['oxygen_hospitals'] ?? 0}', Colors.red),
            _InfraRow('Active Hospitals', '${data['active_hospitals'] ?? 0}', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceAllocation(Map<String, dynamic> data) {
    final totalBeds = (data['total_beds'] ?? 1).toInt();
    final icuBeds = (data['icu_beds'] ?? 0).toInt();
    final occupancyRate =
        totalBeds > 0 ? ((icuBeds / totalBeds) * 100).toStringAsFixed(1) : '0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        border: Border.all(color: Colors.amber[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resource Load Balancing',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            'City-wide capacity utilization is being monitored in real-time. '
            'Hospitals with >80% occupancy are flagged for resource rebalancing.',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (double.parse(occupancyRate) / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.amber[100],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[600]!),
          ),
          const SizedBox(height: 8),
          Text(
            'Average City Occupancy: $occupancyRate%',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEtaAnalytics(Map<String, dynamic> data) {
    final etaStats = data['eta_statistics'] ?? {};
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ambulance Response Performance',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _StatRow('Mean ETA', '${etaStats['mean'] ?? 'N/A'} min'),
            _StatRow('Median ETA', '${etaStats['median'] ?? 'N/A'} min'),
            _StatRow('95th Percentile', '${etaStats['p95'] ?? 'N/A'} min'),
            _StatRow('Max ETA Recorded', '${etaStats['max'] ?? 'N/A'} min'),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseStatus(Map<String, dynamic> data) {
    final statusDist = data['status_distribution'] ?? {};
    final dispatched = statusDist['dispatched'] ?? 0;
    final onTheWay = statusDist['on_the_way'] ?? 0;
    final arrived = statusDist['arrived'] ?? 0;
    final completed = data['completed_alerts'] ?? 0;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          border: Border.all(color: Colors.blue[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Alert Status Distribution',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _StatusBadge('Dispatched', '$dispatched', Colors.orange),
            const SizedBox(height: 8),
            _StatusBadge('On The Way', '$onTheWay', Colors.blue),
            const SizedBox(height: 8),
            _StatusBadge('Arrived', '$arrived', Colors.green),
            const SizedBox(height: 8),
            _StatusBadge('Completed', '$completed', Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<String> points,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800]),
          ),
          const SizedBox(height: 12),
          ...points.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✔ ', style: TextStyle(color: Colors.green[600])),
                Expanded(child: Text(point, style: const TextStyle(fontSize: 12))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String desc;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.desc,
  }) : super();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SeverityBar extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;

  const _SeverityBar(this.label, this.percentage, this.color) : super();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            Text('${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          minHeight: 8,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;

  const _MetricRow(this.label, this.value, this.emoji) : super();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _InfraRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfraRow(this.label, this.value, this.color) : super();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow(this.label, this.value) : super();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String count;
  final Color color;

  const _StatusBadge(this.status, this.count, this.color) : super();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Text(
            count,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}