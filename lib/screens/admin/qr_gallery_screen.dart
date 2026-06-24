import 'package:flutter/material.dart';
import 'package:my_app/services/api_service.dart';

class QrGalleryScreen extends StatefulWidget {
  const QrGalleryScreen({super.key});

  @override
  State<QrGalleryScreen> createState() => _QrGalleryScreenState();
}

class _QrGalleryScreenState extends State<QrGalleryScreen> {
  List<dynamic> records = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  Future<void> loadRecords() async {
    records = await ApiService.fetchQrRecords();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F0FA), // خلفية خفيفة جميلة
      appBar: AppBar(
        // 💡 تحسين وضوح النص وأيقونة الرجوع
        title: const Text(
          "QR Records Table",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : records.isEmpty
            ? const Text(
                "No QR Records Found",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              )
            // 💡 استبدال width: 1100 بـ ConstrainedBox للتحكم في أقصى عرض
            : ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Container(
                  // 💡 تم حذف width: 1100 - سيتولى ConstrainedBox تحديد أقصى عرض
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      // تم إضافة const هنا لتحسين الأداء
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),

                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowHeight: 50,
                      dataRowHeight: 65,
                      columnSpacing: 40,
                      border: TableBorder.all(
                        color: Colors.black12,
                        width: 0.5,
                      ),

                      headingRowColor: MaterialStateProperty.all(
                        Colors.deepPurple.shade100,
                      ),

                      columns: const [
                        DataColumn(label: Text("Product ID")),
                        DataColumn(label: Text("Manufacturer")),
                        DataColumn(label: Text("Category")),
                        DataColumn(label: Text("Country")),
                        DataColumn(label: Text("Nonce")),
                        DataColumn(label: Text("Chain")),
                        DataColumn(label: Text("QR Image")),
                      ],

                      rows: records.map((r) {
                        final imgUrl =
                            "${ApiService.baseUrl}/qrs/${r['product_id']}.png";

                        return DataRow(
                          cells: [
                            DataCell(Text(r["product_id"].toString())),
                            DataCell(Text(r["manufacturer_id"])),
                            DataCell(Text(r["category"])),
                            DataCell(Text(r["country"])),
                            DataCell(Text(r["nonce"])),
                            DataCell(Text(r["chain"])),
                            DataCell(
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  imgUrl,
                                  width: 55,
                                  height: 55,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
