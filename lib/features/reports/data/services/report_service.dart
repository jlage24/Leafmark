import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/report.dart';

class ReportService {
  final _db = FirebaseFirestore.instance;

  Future<void> submitReport(Report report) async {
    await _db.collection('reports').add(report.toMap());
  }
}
