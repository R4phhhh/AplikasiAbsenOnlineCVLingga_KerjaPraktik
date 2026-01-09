import 'dart:async';

import 'package:aplikasi_absen_online/screens/rekap_mingguan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AbsensiScreen extends StatefulWidget {
  final Map<String, dynamic> proyek;
  final String proyekDocId;

  const AbsensiScreen({
    super.key,
    required this.proyek,
    required this.proyekDocId,
  });

  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> pekerja = [];
  DocumentReference? absensiDocRef;
  bool loadingAbsensi = true;
  TimeOfDay batasHadir = const TimeOfDay(hour: 8, minute: 0);
  Timer? refreshTimer;

  bool isLocked = false;

  @override
  void initState() {
    super.initState();
    loadAbsensiHariIni();

    refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await refreshData();
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> refreshData() async {
    await loadAbsensiHariIni();
    await cekStatusProyek();
  }

  Future<void> cekStatusProyek() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.proyekDocId)
            .get();

    if (!doc.exists) return;

    final status = doc.data()?['status'] ?? '';
    if (status == 'selesai' || status == 'telat') {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/proyek');
    }
  }

  Widget statusBox(
    Map<String, dynamic> p,
    String value,
    String label,
    Color color,
  ) {
    final bool active = p['status'] == value;

    return Expanded(
      child: GestureDetector(
        onTap:
            isLocked
                ? null
                : () {
                  setState(() {
                    p['status'] = value;

                    if (value == 'hadir') {
                      if ((p['telatMenit'] ?? 0) == 0) {
                        p['telatMenit'] = hitungTelatMenit();
                      }
                    } else {
                      p['telatMenit'] = 0;
                    }

                    if (value != 'izin') {
                      p['keterangan'] = '';
                    }
                  });
                },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? color : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                value == 'hadir'
                    ? Icons.check_circle
                    : value == 'izin'
                    ? Icons.info
                    : Icons.cancel,
                color: active ? color : Colors.grey.shade400,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: active ? color : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int hitungTelatMenit() {
    final now = DateTime.now();
    final batas = DateTime(
      now.year,
      now.month,
      now.day,
      batasHadir.hour,
      batasHadir.minute,
    );

    if (now.isAfter(batas)) {
      return now.difference(batas).inMinutes;
    }
    return 0;
  }

  Future<void> loadAbsensiHariIni() async {
    setState(() => loadingAbsensi = true);

    final snapshot =
        await FirebaseFirestore.instance
            .collection('absensi')
            .where('proyekId', isEqualTo: widget.proyekDocId)
            .where(
              'tanggal',
              isEqualTo: DateFormat('yyyy-MM-dd').format(selectedDate),
            )
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      isLocked = data['isLocked'] ?? false;
      absensiDocRef = snapshot.docs.first.reference;

      final bh = data['batasHadir'];
      if (bh != null) {
        batasHadir = TimeOfDay(hour: bh['hour'], minute: bh['minute']);
      }

      pekerja = List<Map<String, dynamic>>.from(data['dataPekerja']);
    } else {
      pekerja =
          List<Map<String, dynamic>>.from(widget.proyek['pekerja']).map((e) {
            return {
              'id': e['id'] ?? '',
              'nama': e['nama'],
              'status': null,
              'keterangan': '',
              'telatMenit': 0,
            };
          }).toList();

      absensiDocRef = null;
    }

    setState(() => loadingAbsensi = false);
  }

  int get totalHadir => pekerja.where((p) => p['status'] == 'hadir').length;
  int get totalIzin => pekerja.where((p) => p['status'] == 'izin').length;
  int get totalAlpha => pekerja.where((p) => p['status'] == 'alpha').length;

  @override
  Widget build(BuildContext context) {
    if (loadingAbsensi) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Absensi Pekerja'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: Column(
        children: [
          // ================= HEADER INFO =================
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
                Text(
                  widget.proyek['namaProyek'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Supervisor: ${widget.proyek['supervisor']['nama']}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy').format(selectedDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ================= BATAS HADIR =================
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      color: Colors.white,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 20,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Batas Hadir: ${batasHadir.format(context)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: isLocked ? null : pilihBatasHadir,
                            child: const Text(
                              'Ubah',
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ================= RINGKASAN KEHADIRAN =================
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          infoCount('Hadir', totalHadir, Colors.green),
                          Container(width: 1, height: 40, color: Colors.grey.shade200),
                          infoCount('Izin', totalIzin, Colors.orange),
                          Container(width: 1, height: 40, color: Colors.grey.shade200),
                          infoCount('Alpha', totalAlpha, Colors.red),
                        ],
                      ),
                    ),

                    // lock button / notice
                    if (!isLocked)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        child: Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: konfirmasiKunciAbsensi,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 2,
                              shadowColor: Colors.red.shade200,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.lock_outline, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'Kunci Absensi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade50, Colors.red.shade100],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade300, width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Absensi Terkunci',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.red.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Data tidak dapat diubah',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ================= DAFTAR PEKERJA =================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.people, size: 20, color: Color(0xFF2563EB)),
                          const SizedBox(width: 8),
                          Text(
                            'Daftar Pekerja (${pekerja.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Column(
                        children: pekerja.map((p) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
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
                                  Text(
                                    p['nama'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  if (p['id'] != null && p['id'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'ID: ${p['id']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      statusBox(p, 'hadir', 'Hadir', Colors.green),
                                      const SizedBox(width: 8),
                                      statusBox(p, 'izin', 'Izin', Colors.orange),
                                      const SizedBox(width: 8),
                                      statusBox(p, 'alpha', 'Alpha', Colors.red),
                                    ],
                                  ),
                                  if (p['status'] == 'hadir' &&
                                      (p['telatMenit'] ?? 0) > 0)
                                    Container(
                                      margin: const EdgeInsets.only(top: 10),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            size: 14,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Telat ${p['telatMenit']} menit',
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (p['status'] == 'izin') ...[
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      enabled: !isLocked,
                                      initialValue: p['keterangan'],
                                      decoration: InputDecoration(
                                        labelText: 'Keterangan Izin (Opsional)',
                                        hintText: 'Sakit, keperluan keluarga, dll',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF2563EB),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      onChanged: (val) {
                                        p['keterangan'] = val.trim();
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ================= BUTTONS =================
          SafeArea(
            top: false,
            left: false,
            right: false,
            bottom: true,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => RekapMingguanScreen(
                                  proyekId: widget.proyekDocId,
                                ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Rekap Mingguan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLocked ? null : simpanAbsensi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Simpan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget infoCount(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> simpanAbsensi() async {
    if (isLocked) return;
    try {
      final List<Map<String, dynamic>> dataPekerja =
          pekerja.map((p) {
            final map = {
              'id': p['id'],
              'nama': p['nama'],
              'status': p['status'],
              'telatMenit': p['telatMenit'] ?? 0,
            };

            if (p['status'] == 'izin' &&
                p['keterangan'] != null &&
                p['keterangan'].toString().isNotEmpty) {
              map['keterangan'] = p['keterangan'];
            }

            return map;
          }).toList();

      if (absensiDocRef != null) {
        await absensiDocRef!.update({
          'dataPekerja': dataPekerja,
          'rekap': {
            'hadir': totalHadir,
            'izin': totalIzin,
            'alpha': totalAlpha,
          },
          'batasHadir': {'hour': batasHadir.hour, 'minute': batasHadir.minute},
          'updatedAt': Timestamp.now(),
        });
      } else {
        final doc = await FirebaseFirestore.instance.collection('absensi').add({
          'proyekId': widget.proyekDocId,
          'tanggal': DateFormat('yyyy-MM-dd').format(selectedDate),
          'supervisorUid': widget.proyek['supervisor']['uid'],
          'dataPekerja': dataPekerja,
          'rekap': {
            'hadir': totalHadir,
            'izin': totalIzin,
            'alpha': totalAlpha,
          },
          'batasHadir': {'hour': batasHadir.hour, 'minute': batasHadir.minute},
          'isLocked': false,
          'createdAt': Timestamp.now(),
        });

        absensiDocRef = doc;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Absensi berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal menyimpan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> kunciAbsensi() async {
    if (absensiDocRef == null) return;

    await absensiDocRef!.update({
      'isLocked': true,
      'lockedAt': Timestamp.now(),
    });

    setState(() => isLocked = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔒 Absensi berhasil dikunci'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> konfirmasiKunciAbsensi() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Kunci Absensi'),
            content: const Text(
              'Setelah dikunci, absensi tidak dapat diubah lagi.\n\nYakin ingin mengunci?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Kunci'),
              ),
            ],
          ),
    );

    if (result == true) {
      await kunciAbsensi();
    }
  }

  Future<void> pilihBatasHadir() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: batasHadir,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => batasHadir = picked);

      if (absensiDocRef != null) {
        await absensiDocRef!.update({
          'batasHadir': {'hour': picked.hour, 'minute': picked.minute},
          'updatedAt': Timestamp.now(),
        });
      }
    }
  }
}