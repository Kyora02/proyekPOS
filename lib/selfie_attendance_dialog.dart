import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class SelfieAttendanceDialog extends StatefulWidget {
  final String karyawanId;
  final String karyawanName;
  final String outletId;
  final bool isCheckIn;
  final Function(String imageUrl) onImageCaptured;

  const SelfieAttendanceDialog({
    super.key,
    required this.karyawanId,
    required this.karyawanName,
    required this.outletId,
    required this.isCheckIn,
    required this.onImageCaptured,
  });

  @override
  State<SelfieAttendanceDialog> createState() => _SelfieAttendanceDialogState();
}

class _SelfieAttendanceDialogState extends State<SelfieAttendanceDialog> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isUploading = false;
  XFile? _capturedImage;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'Kamera tidak tersedia';
        });
        return;
      }

      final frontCamera = _cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal membuka kamera: $e';
      });
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile image = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = image;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengambil foto: $e';
      });
    }
  }

  Future<void> _uploadAndConfirm() async {
    if (_capturedImage == null) return;

    setState(() {
      _isUploading = true;
      _errorMessage = '';
    });

    try {
      final String fileName = '${widget.karyawanId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String storagePath = 'attendance/${widget.outletId}/$fileName';

      final Reference storageRef = FirebaseStorage.instance.ref().child(storagePath);

      UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await _capturedImage!.readAsBytes();
        uploadTask = storageRef.putData(bytes);
      } else {
        final File imageFile = File(_capturedImage!.path);
        uploadTask = storageRef.putFile(imageFile);
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      widget.onImageCaptured(downloadUrl);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Gagal upload foto: $e';
      });
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _errorMessage = '';
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isCheckIn ? 'Selfie Absen Masuk' : 'Selfie Absen Keluar',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildCameraPreview(),
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_errorMessage.isNotEmpty && !_isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_capturedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FutureBuilder<Uint8List>(
          future: _capturedImage!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A3A3)),
                ),
              );
            }
          },
        ),
      );
    }

    if (!_isInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A3A3)),
        ),
      );
    }

    if (kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: AspectRatio(
            aspectRatio: _cameraController!.value.aspectRatio,
            child: CameraPreview(_cameraController!),
          ),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final scale = _cameraController!.value.aspectRatio / deviceRatio;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Transform.scale(
        scale: scale,
        child: Center(
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isUploading) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A3A3)),
          ),
        ),
      );
    }

    if (_capturedImage != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _retakePhoto,
              icon: const Icon(Icons.refresh),
              label: const Text('Foto Ulang'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFF00A3A3)),
                foregroundColor: const Color(0xFF00A3A3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _uploadAndConfirm,
              icon: const Icon(Icons.check),
              label: const Text('Konfirmasi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A3A3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isInitialized ? _captureImage : null,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Ambil Foto'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A3A3),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          disabledBackgroundColor: Colors.grey[300],
        ),
      ),
    );
  }
}