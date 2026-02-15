import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'package:intl/intl.dart';

class GovernmentPDFService {
  /// Generate comprehensive government analytics PDF report
  static Future<Uint8List> generateGovernmentAnalyticsPDF(
    Map<String, dynamic> data,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    // Define colors for government theme
    const PdfColor primaryColor = PdfColor.fromInt(0xFF1976D2);
    const PdfColor accentColor = PdfColor.fromInt(0xFF6C63FF);
    const PdfColor warningColor = PdfColor.fromInt(0xFFFFA726);
    const PdfColor dangerColor = PdfColor.fromInt(0xFFF44336);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: primaryColor, width: 2),
            ),
          ),
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Text(
            'GOVERNMENT HEALTH ANALYTICS DASHBOARD',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
        footer: (context) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: primaryColor, width: 1),
            ),
          ),
          padding: const pw.EdgeInsets.only(top: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Report Generated: ${dateFormat.format(now)}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
              ),
            ],
          ),
        ),
        build: (context) => [
          // Title Section
          pw.SizedBox(height: 10),
          pw.Text(
            'Executive Summary - Health Emergency Response System',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 15),

          // Key Metrics Grid
          pw.Text(
            '1. KEY PERFORMANCE INDICATORS',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildMetricsTable([
            ['Active Hospitals', '${data['active_hospitals'] ?? 'N/A'}'],
            ['Total Hospital Beds', '${data['total_beds'] ?? 'N/A'}'],
            ['ICU Beds Available', '${data['icu_beds'] ?? 'N/A'}'],
            ['Oxygen-Ready Hospitals', '${data['oxygen_hospitals'] ?? 'N/A'}'],
            ['Registered Citizens', '${data['registered_citizens'] ?? 'N/A'}'],
            ['Total Population', '${data['total_citizens'] ?? 'N/A'}'],
          ]),
          pw.SizedBox(height: 20),

          // Alert Analysis Section
          pw.Text(
            '2. ALERT & RESPONSE ANALYTICS',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildMetricsTable([
            ['Total SOS Calls Received', '${data['total_alerts'] ?? 'N/A'}'],
            ['Alerts Completed', '${data['completed_alerts'] ?? 'N/A'}'],
            ['Completion Rate', '${((data['completed_alerts'] ?? 0) / (data['total_alerts'] ?? 1) * 100).toStringAsFixed(1)}%'],
            ['Average Response Time (ETA)', '${data['avg_eta'] ?? 'N/A'} minutes'],
            ['Ambulance Count', '${data['ambulance_count'] ?? 'N/A'}'],
          ]),
          pw.SizedBox(height: 20),

          // Severity Distribution
          pw.Text(
            '3. ALERT SEVERITY DISTRIBUTION',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildSeveritySection(data['severity_distribution'] ?? {}),
          pw.SizedBox(height: 20),

          // Status Distribution
          pw.Text(
            '4. ALERT STATUS DISTRIBUTION',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildStatusDistributionSection(data['status_distribution'] ?? {}),
          pw.SizedBox(height: 20),

          // ETA Statistics
          pw.Text(
            '5. AMBULANCE RESPONSE PERFORMANCE',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildETASection(data['eta_statistics'] ?? {}),
          pw.SizedBox(height: 20),

          // Digital Adoption
          pw.Text(
            '6. DIGITAL ADOPTION METRICS',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildDigitalAdoptionSection(data),
          pw.SizedBox(height: 20),

          // Infrastructure Status
          pw.Text(
            '7. HOSPITAL INFRASTRUCTURE STATUS',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInfrastructureSection(data),
          pw.SizedBox(height: 25),

          // Recommendations
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: accentColor),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              color: const PdfColor.fromInt(0xFFF3F0FF),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RECOMMENDATIONS',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '• Continue monitoring ambulance response times for optimization\n'
                  '• Focus on increasing digital adoption among citizens\n'
                  '• Maintain adequate ICU bed capacity across network\n'
                  '• Regular training for emergency response teams\n'
                  '• Implement preventive health measures for at-risk populations',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Build metrics table
  static pw.Widget _buildMetricsTable(List<List<String>> data) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: const PdfColor.fromInt(0xFFE0E0E0),
        width: 1,
      ),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFF1976D2),
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Metric',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Value',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ],
        ),
        // Data rows
        ...data.map((row) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    row[0],
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    row[1],
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )),
      ],
    );
  }

  static pw.Widget _buildSeveritySection(Map<String, dynamic> severity) {
    final low = (severity['low'] ?? 0) as num;
    final medium = (severity['medium'] ?? 0) as num;
    final high = (severity['high'] ?? 0) as num;
    final total = low + medium + high;

    return pw.Column(
      children: [
        _buildMetricsTable([
          ['Low Risk Alerts', '$low (${total > 0 ? ((low / total) * 100).toStringAsFixed(1) : '0'}%)'],
          ['Medium Risk Alerts', '$medium (${total > 0 ? ((medium / total) * 100).toStringAsFixed(1) : '0'}%)'],
          ['High Risk Alerts', '$high (${total > 0 ? ((high / total) * 100).toStringAsFixed(1) : '0'}%)'],
          ['Total Alerts', '$total'],
        ]),
      ],
    );
  }

  static pw.Widget _buildStatusDistributionSection(Map<String, dynamic> status) {
    return _buildMetricsTable([
      ['Dispatched', '${status['dispatched'] ?? 'N/A'}'],
      ['On The Way', '${status['on_the_way'] ?? 'N/A'}'],
      ['Arrived', '${status['arrived'] ?? 'N/A'}'],
      ['In Progress', '${status['in_progress'] ?? 'N/A'}'],
    ]);
  }

  static pw.Widget _buildETASection(Map<String, dynamic> eta) {
    return _buildMetricsTable([
      ['Mean ETA', '${eta['mean'] ?? 'N/A'} min'],
      ['Median ETA', '${eta['median'] ?? 'N/A'} min'],
      ['95th Percentile', '${eta['p95'] ?? 'N/A'} min'],
      ['Maximum ETA Recorded', '${eta['max'] ?? 'N/A'} min'],
      ['Minimum ETA Recorded', '${eta['min'] ?? 'N/A'} min'],
    ]);
  }

  static pw.Widget _buildDigitalAdoptionSection(Map<String, dynamic> data) {
    String digitalAdoptionStr = 'N/A';

    if (data.containsKey('digital_adoption') && data['digital_adoption'] != null) {
      digitalAdoptionStr = '${data['digital_adoption']}%';
    } else if (data.containsKey('registered_citizens') &&
        data['registered_citizens'] != null &&
        (data['total_citizens'] ?? 0) is num &&
        (data['total_citizens'] as num) > 0) {
      try {
        final reg = (data['registered_citizens'] as num).toDouble();
        final total = (data['total_citizens'] as num).toDouble();
        digitalAdoptionStr = '${((reg / total) * 100).toStringAsFixed(1)}%';
      } catch (_) {
        digitalAdoptionStr = 'N/A';
      }
    }

    return _buildMetricsTable([
      ['Digital Adoption Rate', digitalAdoptionStr],
      ['Registered Citizens', '${data['registered_citizens'] ?? 'N/A'}'],
      ['Total Citizens in Network', '${data['total_citizens'] ?? 'N/A'}'],
    ]);
  }

  static pw.Widget _buildInfrastructureSection(Map<String, dynamic> data) {
    final totalBeds = (data['total_beds'] ?? 0) as num;
    final icuBeds = (data['icu_beds'] ?? 0) as num;
    final occupancyRate = totalBeds > 0 ? ((icuBeds / totalBeds) * 100).toStringAsFixed(1) : '0';

    return _buildMetricsTable([
      ['Total Hospital Beds', '$totalBeds'],
      ['ICU Beds', '$icuBeds'],
      ['Average Occupancy Rate', '$occupancyRate%'],
      ['Active Hospitals', '${data['active_hospitals'] ?? 'N/A'}'],
      ['Oxygen-Ready Hospitals', '${data['oxygen_hospitals'] ?? 'N/A'}'],
    ]);
  }
}
