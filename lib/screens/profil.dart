import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  Map<String, dynamic>? data;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProfil();
  }

  Future<void> loadProfil() async {
    final snap =
        await FirebaseFirestore.instance
            .collection('supervisors')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();

    if (snap.docs.isNotEmpty) {
      setState(() {
        data = snap.docs.first.data();
        loading = false;
      });
    }
  }

  Future<void> gantiFoto() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final compressedBytes = await FlutterImageCompress.compressWithFile(
      picked.path,
      format: CompressFormat.webp,
      quality: 70,
    );

    if (compressedBytes == null) return;

    final base64Image = base64Encode(compressedBytes);
    final avatar = 'data:image/webp;base64,$base64Image';

    final snap =
        await FirebaseFirestore.instance
            .collection('supervisors')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();

    await snap.docs.first.reference.update({'avatar': avatar});

    setState(() {
      data!['avatar'] = avatar;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(0, 60, 0, 30),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: gantiFoto,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.shade400,
                        ),
                        child: ClipOval(
                          child: (() {
                            final a = data!['avatar'];
                            if (a == null) {
                              return Container(
                                color: Colors.blue.shade400,
                                child: const Icon(
                                  Icons.person,
                                  size: 45,
                                  color: Colors.white,
                                ),
                              );
                            }
                            if (a is String) {
                              if (a.contains(',') || a.length > 20) {
                                String b64 = a.contains(',') ? a.split(',').last : a;
                                b64 = b64.replaceAll(RegExp(r'\s+'), '');
                                final mod = b64.length % 4;
                                if (mod != 0) b64 += List.filled(4 - mod, '=').join();
                                try {
                                  return Image.memory(base64Decode(b64), fit: BoxFit.cover);
                                } catch (_) {
                                }
                              }
                              return Container(
                                color: Colors.blue.shade400,
                                child: Center(
                                  child: Text(
                                    a.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }
                            if (a is Uint8List) {
                              return Image.memory(a, fit: BoxFit.cover);
                            }
                            if (a is List<int>) {
                              return Image.memory(Uint8List.fromList(a), fit: BoxFit.cover);
                            }
                            return Container(
                              color: Colors.blue.shade400,
                              child: const Icon(
                                Icons.person,
                                size: 45,
                                color: Colors.white,
                              ),
                            );
                          })(),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data!['nama'] ?? 'Supervisor',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Supervisor Lapangan',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
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
                    const Text(
                      'Informasi Profil',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),

                    infoRow('Perusahaan', data!['perusahaan'] ?? '-'),
                    infoRow('Email', data!['email'] ?? '-'),
                    infoRow('No. Telepon', data!['nohp'] ?? '-'),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushNamed(context, '/');
              },
              child: const Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        onTap: (i) {
          if (i == 0) {
            Navigator.pushNamed(context, '/proyek');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Proyek'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }
}