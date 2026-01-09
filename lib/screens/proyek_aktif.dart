import 'package:aplikasi_absen_online/screens/detail_proyek.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

class ProyekAktifScreen extends StatefulWidget {
  const ProyekAktifScreen({super.key});

  @override
  State<ProyekAktifScreen> createState() => _ProyekAktifScreenState();
}

class _ProyekAktifScreenState extends State<ProyekAktifScreen> {
  String search = '';
  final user = FirebaseAuth.instance.currentUser!;
  Timer? statusTimer;

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
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
    return 'Lokasi tidak diketahui';
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    refreshProyek();
    statusTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => refreshProyek(),
    );
  }

  void refreshProyek() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(170),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
          decoration: const BoxDecoration(
            color: Color(0xFF2563EB),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Proyek Aktif',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Proyek yang sedang berjalan',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  onChanged: (val) {
                    setState(() => search = val.toLowerCase());
                  },
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: 'Cari proyek...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects')
            .where('status', isEqualTo: 'dalam pengerjaan')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_off, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada proyek aktif',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          final projects = snapshot.data!.docs.where((doc) {
            final nama = doc['namaProyek'].toString().toLowerCase();
            final supervisor = doc['supervisor'] as Map<String, dynamic>?;
            final isSupervisor = supervisor != null && supervisor['id'] == user.uid;
            return nama.contains(search) && isSupervisor;
          }).toList();

          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Proyek tidak ditemukan',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final doc = projects[index];
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailProyekScreen(proyek: data),
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.only(
                    bottom: index == projects.length - 1 ? 16 : 12,
                  ),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                data['namaProyek'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Color(0xFF2563EB),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),
                        Text(
                          data['namaClient'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 6),
                              Expanded(
                                child: Builder(
                                  builder: (context) {
                                    final lokasi = data['lokasi'];

                                    if (lokasi is String && lokasi.isNotEmpty) {
                                      return Text(
                                        lokasi,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
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
                                              fontSize: 12,
                                              color: Colors.grey.shade400,
                                            ),
                                          );
                                        }
                                        return Text(
                                          snapshot.data!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${data['tanggalMulai']} s/d ${data['tenggat']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

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
                              fontSize: 11,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        onTap: (i) {
          if (i == 1) {
            Navigator.pushNamed(context, '/profil');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Proyek',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}