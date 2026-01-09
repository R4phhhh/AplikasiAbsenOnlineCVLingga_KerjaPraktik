import 'package:aplikasi_absen_online/screens/absensi.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class DetailProyekScreen extends StatefulWidget {
  final Map<String, dynamic> proyek;

  const DetailProyekScreen({
    super.key,
    required this.proyek,
  });

  @override
  State<DetailProyekScreen> createState() => _DetailProyekScreenState();
}

class _DetailProyekScreenState extends State<DetailProyekScreen> {
  late Map<String, dynamic> proyek;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    proyek = widget.proyek;

    refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      refreshProyek();
    });

    refreshProyek();
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> refreshProyek() async {
    final docSnap = await FirebaseFirestore.instance
        .collection('projects')
        .doc(proyek['id'])
        .get();

    if (!docSnap.exists) return;

    setState(() {
      proyek = {
        ...proyek,
        ...docSnap.data()!,
      };
    });
  }

  Future<String> getAlamat(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return [
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((e) => e != null && e!.isNotEmpty).join(', ');
      }
    } catch (_) {}
    return 'Lokasi tidak diketahui';
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Detail Proyek'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        children: [
          Container(
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  proyek['namaProyek'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  proyek['namaClient'],
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Dalam Pengerjaan',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informasi Detail',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
                infoRow(
                  Icons.person_outline,
                  'Supervisor',
                  proyek['supervisor']['nama'],
                ),
                const Divider(height: 24),
                infoRow(
                  Icons.people_outline,
                  'Jumlah Pekerja',
                  '${proyek['jumlahPekerja']} orang',
                ),
                const Divider(height: 24),
                infoRow(
                  Icons.calendar_today_outlined,
                  'Durasi',
                  '${proyek['tanggalMulai']} s/d ${proyek['tenggat']}',
                ),
                const Divider(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lokasi',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Builder(
                            builder: (context) {
                              final lokasi = proyek['lokasi'];

                              if (lokasi is String && lokasi.isNotEmpty) {
                                return Text(
                                  lokasi,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1F2937),
                                    fontSize: 14,
                                  ),
                                );
                              }

                              double lat = 0.0, lng = 0.0;
                              if (lokasi is Map) {
                                lat = _toDouble(lokasi['lat']);
                                lng = _toDouble(lokasi['lng']);
                              } else if (lokasi is List && lokasi.length >= 2) {
                                lat = _toDouble(lokasi[0]);
                                lng = _toDouble(lokasi[1]);
                              } else if (lokasi is String) {
                                final parts = lokasi.split(',');
                                if (parts.length >= 2) {
                                  lat = _toDouble(parts[0]);
                                  lng = _toDouble(parts[1]);
                                }
                              }

                              return FutureBuilder<String>(
                                future: getAlamat(lat, lng),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return Text(
                                      'Memuat lokasi...',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 14,
                                      ),
                                    );
                                  }
                                  return Text(
                                    snapshot.data!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1F2937),
                                      fontSize: 14,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deskripsi Proyek',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  proyek['deskripsi'],
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),

      bottomNavigationBar: SafeArea(
        top: false,
      left: false,
        right: false,
        bottom: true,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AbsensiScreen(
                      proyek: proyek,
                      proyekDocId: proyek['id'],
                    ),
                  ),
                );
              },
              child: const Text(
                'Absensi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}