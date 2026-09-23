import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/batch_model.dart';
import '../../data/models/bag_model.dart';
import '../../data/models/sale_model.dart';
import '../utils/myco_calculations.dart';

class PdfExportService {
  /// Génère et ouvre l'impression des étiquettes QR codes d'un lot
  static Future<void> printBatchQrLabels({
    required BatchModel batch,
    required List<BagModel> bags,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'MycoApp - Planches d\'étiquettes Sacs',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Lot : ${batch.batchCode}'),
              ],
            ),
          ),
          pw.Text('Souche : ${batch.spawnStrain} | Date ensemencement : ${batch.pasteurizationDate.day}/${batch.pasteurizationDate.month}/${batch.pasteurizationDate.year}'),
          pw.SizedBox(height: 16),
          pw.GridView(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            children: bags.map((bag) {
              return pw.Container(
                padding: const pw.EdgeInsets.all(8),
                margin: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      bag.qrCode,
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 6),
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: bag.qrCode,
                      width: 90,
                      height: 90,
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Poids: ${bag.weightKg} kg',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      batch.spawnStrain,
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'etiquettes_${batch.batchCode}.pdf',
    );
  }

  /// Génère le rapport financier et commercial des ventes en PDF
  static Future<void> printSalesReport({
    required List<SaleModel> sales,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    final totalRevenue = sales.fold(0.0, (acc, s) => acc + s.totalRevenue);
    final totalMargin = sales.fold(0.0, (acc, s) => acc + s.netMargin);
    final totalKg = sales.fold(0.0, (acc, s) => acc + s.quantityKg);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Rapport Financier des Ventes - MycoApp',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text('Période du ${startDate.day}/${startDate.month}/${startDate.year} au ${endDate.day}/${endDate.month}/${endDate.year}'),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Text('Chiffre d\'Affaires : ${MycoCalculations.formatCurrency(totalRevenue)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Marge Nette : ${MycoCalculations.formatCurrency(totalMargin)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
              pw.Text('Volume Vendu : ${MycoCalculations.formatWeight(totalKg)}'),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['N° Vente', 'Date', 'Client', 'Quantité', 'Total (DA)', 'Marge (DA)', 'Statut'],
            data: sales.map((s) => [
              s.saleNumber,
              '${s.date.day}/${s.date.month}',
              s.clientName,
              '${s.quantityKg} kg',
              MycoCalculations.formatCurrency(s.totalRevenue),
              MycoCalculations.formatCurrency(s.netMargin),
              s.paymentStatus.name,
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'rapport_ventes.pdf',
    );
  }
}
