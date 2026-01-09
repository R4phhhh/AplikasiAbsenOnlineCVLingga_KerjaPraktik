import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RekapMingguanScreen extends StatefulWidget {
  final String proyekId;

  const RekapMingguanScreen({super.key, required this.proyekId});

  @override
  State<RekapMingguanScreen> createState() => _RekapMingguanScreenState();
}

class _RekapMingguanScreenState extends State<RekapMingguanScreen> {
  List<QueryDocumentSnapshot> data = [];
  bool loading = true;
  DateTime endDate = DateTime.now();
  DateTime startDate = DateTime.now().subtract(const Duration(days: 6));

  Timer? refreshTimer;

  String fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  String fmtDisplay(DateTime d) => DateFormat('dd MMM yyyy', 'id_ID').format(d);

  @override
  void initState() {
    super.initState();
    loadData();

    refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      loadData();
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      setState(() => loading = true);

      final proyekSnap = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.proyekId)
          .get();

      final statusProyek = proyekSnap['status'] ?? '';

      if (statusProyek == 'selesai' || statusProyek == 'telat') {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/proyek_aktif');
        return;
      }

      final now = DateTime.now();

      final senin = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));

      final minggu = senin.add(const Duration(days: 6));

      startDate = senin;
      endDate = minggu;

      final snap = await FirebaseFirestore.instance
          .collection('absensi')
          .where('proyekId', isEqualTo: widget.proyekId)
          .where('tanggal', isGreaterThanOrEqualTo: fmt(startDate))
          .where('tanggal', isLessThanOrEqualTo: fmt(endDate))
          .orderBy('tanggal')
          .get();

      setState(() {
        data = snap.docs;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    }
  }

  List<String> getAllPekerjaNames() {
    final Set<String> names = {};
    for (var doc in data) {
      final pekerjaList = List.from(doc['dataPekerja']);
      for (var p in pekerjaList) {
        names.add(p['nama']);
      }
    }
    return names.toList()..sort();
  }

  Map<String, Map<String, dynamic>> getPekerjaDataByDate() {
    final Map<String, Map<String, dynamic>> result = {};

    for (var doc in data) {
      final tanggal = doc['tanggal'];
      final pekerjaList = List.from(doc['dataPekerja']);

      for (var p in pekerjaList) {
        final nama = p['nama'];
        if (!result.containsKey(nama)) {
          result[nama] = {};
        }
        result[nama]![tanggal] = p;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    int totalHadir = 0;
    int totalIzin = 0;
    int totalAlpha = 0;

    for (var doc in data) {
      final rekap = doc['rekap'] as Map<String, dynamic>?;
      if (rekap != null) {
        totalHadir += (rekap['hadir'] ?? 0) as int;
        totalIzin += (rekap['izin'] ?? 0) as int;
        totalAlpha += (rekap['alpha'] ?? 0) as int;
      }
    }

    final pekerjaNames = getAllPekerjaNames();
    final pekerjaDataByDate = getPekerjaDataByDate();

    final List<DateTime> weekDates = [];
    for (int i = 0; i < 7; i++) {
      weekDates.add(startDate.add(Duration(days: i)));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Rekap Mingguan'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2563EB),
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Periode',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${fmtDisplay(startDate)} - ${fmtDisplay(endDate)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan Kehadiran',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _summaryBox(
                              totalHadir.toString(),
                              'Total Hadir',
                              Colors.green.shade50,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _summaryBox(
                              totalIzin.toString(),
                              'Total Izin',
                              Colors.orange.shade50,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _summaryBox(
                              totalAlpha.toString(),
                              'Total Alpha',
                              Colors.red.shade50,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text(
                        'Detail per Pekerja',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: data.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy,
                                  size: 80, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text(
                                'Tidak ada data absensi',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: pekerjaNames.length,
                          itemBuilder: (context, index) {
                            final nama = pekerjaNames[index];
                            final pekerjaData = pekerjaDataByDate[nama] ?? {};

                            int hadir = 0;
                            int izin = 0;
                            int alpha = 0;
                            int totalHariAda = 0;

                            for (var date in weekDates) {
                              final tanggal = fmt(date);
                              if (pekerjaData.containsKey(tanggal)) {
                                totalHariAda++;
                                final status = pekerjaData[tanggal]['status'];
                                if (status == 'hadir') hadir++;
                                if (status == 'izin') izin++;
                                if (status == 'alpha') alpha++;
                              }
                            }

                            final persentase = totalHariAda > 0
                                ? ((hadir / totalHariAda) * 100).round()
                                : 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade200,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            nama,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getPercentageColor(
                                                    persentase)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '$persentase%',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: _getPercentageColor(
                                                  persentase),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: weekDates.map((date) {
                                        final tanggal = fmt(date);
                                        final dayName = DateFormat('EEE', 'id_ID')
                                            .format(date)
                                            .substring(0, 3);

                                        String? status;
                                        if (pekerjaData.containsKey(tanggal)) {
                                          status =
                                              pekerjaData[tanggal]['status'];
                                        }

                                        Color bgColor;
                                        Color textColor;

                                        if (status == 'hadir') {
                                          bgColor = Colors.green;
                                          textColor = Colors.white;
                                        } else if (status == 'izin') {
                                          bgColor = Colors.orange;
                                          textColor = Colors.white;
                                        } else if (status == 'alpha') {
                                          bgColor = Colors.red;
                                          textColor = Colors.white;
                                        } else {
                                          bgColor = Colors.grey.shade200;
                                          textColor = Colors.grey.shade600;
                                        }

                                        return Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: bgColor,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              dayName,
                                              style: TextStyle(
                                                color: textColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),

                                    const SizedBox(height: 12),

                                    Row(
                                      children: [
                                        _statusIcon(
                                            Icons.check_circle,
                                            'Hadir: $hadir',
                                            Colors.green),
                                        const SizedBox(width: 16),
                                        _statusIcon(Icons.info,
                                            'Izin: $izin', Colors.orange),
                                        const SizedBox(width: 16),
                                        _statusIcon(Icons.cancel,
                                            'Alpha: $alpha', Colors.red),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Color _getPercentageColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _summaryBox(String value, String label, Color bgColor, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _statusIcon(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}