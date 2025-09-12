import 'dart:convert';
import 'package:flutter/material.dart';
import '../auth/api_client.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:fl_chart/fl_chart.dart';
import '../auth/auth_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  final int? patientId;
  const AnalyticsScreen({super.key, this.patientId});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _series;
  Map<String, dynamic>? _report;
  Map<String, dynamic>? _weekly;
  bool _loading = true;
  String? _error;
  bool _weeklyLoading = false;

  String _progressText() {
    final g = (_series?['glucose'] as List?) ?? [];
    if (g.length < 2) return 'Not enough data yet.';
    final first = (g.first as Map<String, dynamic>);
    final last = (g.last as Map<String, dynamic>);
    final fv = (first['v'] as num?)?.toDouble() ?? 0;
    final lv = (last['v'] as num?)?.toDouble() ?? 0;
    final diff = (lv - fv);
    final trend = diff.abs() < 5 ? 'stable' : (diff < 0 ? 'improving' : 'worsening');
    return 'Glucose is $trend over the last period (${fv.toStringAsFixed(0)} → ${lv.toStringAsFixed(0)}).';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final q = widget.patientId != null ? '?patient_id=${widget.patientId}' : '';
      final res = await ApiClient.get('/analytics/$q');
      final ts = await ApiClient.get('/analytics/timeseries/$q');
      final rp = await ApiClient.get('/analytics/report$q');
      final wk = await ApiClient.get('/analytics/weekly$q');
      setState(() {
        _summary = res.statusCode == 200 ? jsonDecode(res.body) : null;
        _series = ts.statusCode == 200 ? jsonDecode(ts.body) : null;
        _report = rp.statusCode == 200 ? jsonDecode(rp.body) : null;
        _weekly = wk.statusCode == 200 ? jsonDecode(wk.body) : null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Network error';
        _loading = false;
      });
    }
  }

  Future<void> _refreshWeekly() async {
    try {
      setState(() { _weeklyLoading = true; });
      final q = widget.patientId != null ? '?patient_id=${widget.patientId}' : '';
      final wk = await ApiClient.get('/analytics/weekly$q');
      setState(() {
        _weekly = wk.statusCode == 200 ? jsonDecode(wk.body) : _weekly;
        _weeklyLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _weeklyLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to refresh weekly')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Glucose avg: ${_summary?['glucose']?['avg'] ?? '-'}'),
                    Text('BP max: ${_summary?['blood_pressure']?['max_sys'] ?? '-'} / ${_summary?['blood_pressure']?['max_dia'] ?? '-'}'),
                    const SizedBox(height: 16),
                    Row(children: [
                      ElevatedButton(
                        onPressed: () async {
                          final res = await ApiClient.get('/analytics/export');
                          if (!mounted) return;
                          if (res.statusCode == 200) {
                            final bytes = res.bodyBytes;
                            final blob = html.Blob([bytes], 'text/csv');
                            final url = html.Url.createObjectUrlFromBlob(blob);
                            final anchor = html.AnchorElement(href: url)
                              ..download = 'readings.csv'
                              ..style.display = 'none';
                            html.document.body?.append(anchor);
                            anchor.click();
                            anchor.remove();
                            html.Url.revokeObjectUrl(url);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: ${res.statusCode}')));
                          }
                        },
                        child: const Text('Export CSV'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _weeklyLoading ? null : _refreshWeekly,
                        child: Text(_weeklyLoading ? 'Refreshing…' : 'Refresh Weekly'),
                      )
                    ]),
                    const SizedBox(height: 8),
                    const Text('Weekly Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...(((_weekly?['glucose']) as List?) ?? []).map((e){
                      final m = e as Map<String, dynamic>;
                      return Text('Week ${m['week_start']}: Glucose avg ${m['avg'] ?? '-'}');
                    }).toList(),
                    ...(((_weekly?['bp']) as List?) ?? []).map((e){
                      final m = e as Map<String, dynamic>;
                      return Text('Week ${m['week_start']}: BP ${m['avg_sys'] ?? '-'} / ${m['avg_dia'] ?? '-'}');
                    }).toList(),
                    const Text('Glucose Trend', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 220,
                      child: LineChart(LineChartData(
                        minY: 0,
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              ...(((_series?['glucose']) as List?) ?? []).asMap().entries.map((e){
                                final m = e.value as Map<String, dynamic>;
                                final v = (m['v'] as num?)?.toDouble() ?? 0;
                                return FlSpot(e.key.toDouble(), v);
                              })
                            ],
                            isCurved: true,
                            color: const Color(0xFF00897B),
                            barWidth: 3,
                          )
                        ],
                        extraLinesData: ExtraLinesData(horizontalLines: [
                          HorizontalLine(y: 180, color: const Color(0xFFD32F2F), strokeWidth: 1), // high threshold
                          HorizontalLine(y: 70, color: const Color(0xFFF9A825), strokeWidth: 1),   // low threshold
                        ]),
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(show: false),
                      )),
                    ),
                    const SizedBox(height: 16),
                    const Text('BP Trend', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 220,
                      child: LineChart(LineChartData(
                        minY: 0,
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              ...(((_series?['bp']) as List?) ?? []).asMap().entries.map((e){
                                final m = e.value as Map<String, dynamic>;
                                final v = (m['sys'] as num?)?.toDouble() ?? 0;
                                return FlSpot(e.key.toDouble(), v);
                              })
                            ],
                            isCurved: true,
                            color: const Color(0xFF1976D2),
                            barWidth: 3,
                          )
                        ],
                        extraLinesData: ExtraLinesData(horizontalLines: [
                          HorizontalLine(y: 140, color: const Color(0xFFD32F2F), strokeWidth: 1),
                          HorizontalLine(y: 120, color: const Color(0xFFF9A825), strokeWidth: 1),
                        ]),
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(show: false),
                      )),
                    ),
                    const SizedBox(height: 16),
                    const Text('Series (latest)', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Glucose points: ${(_series?['glucose'] as List?)?.length ?? 0}'),
                    Text('BP points: ${(_series?['bp'] as List?)?.length ?? 0}'),
                    const SizedBox(height: 16),
                    const Text('Progress (last 7 days)', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(_progressText()),
                    const SizedBox(height: 16),
                    const Text('Daily Report', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...(((_report?['daily']?['glucose']) as List?) ?? []).map((e) {
                      final m = e as Map<String, dynamic>;
                      return Text('Glucose ${m['day']}: avg ${(m['avg'] ?? '-')}');
                    }).toList(),
                    ...(((_report?['daily']?['bp']) as List?) ?? []).map((e) {
                      final m = e as Map<String, dynamic>;
                      return Text('BP ${m['day']}: ${m['avg_sys'] ?? '-'} / ${m['avg_dia'] ?? '-'}');
                    }).toList(),
                    const SizedBox(height: 8),
                    const Text('Reading counts', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Glucose: ${_report?['counts']?['glucose'] ?? 0}'),
                    Text('BP: ${_report?['counts']?['bp'] ?? 0}'),
                    Text('Weight: ${_report?['counts']?['weight'] ?? 0}'),
                    Text('BMI: ${_report?['counts']?['bmi'] ?? 0}'),
                    Text('Waist: ${_report?['counts']?['waist'] ?? 0}'),
                  ],
                ),
    );
  }
}


