import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'app_log_buffer.dart';

/// Builds a shareable PDF of everything captured in [AppLogBuffer] since app
/// start, tagged with device/app context so a bug report is self-contained.
///
/// The buffer only ever sees Dart console output (the zone `print` hook in
/// `main()`). On Android the debug console also shows the system log
/// (logcat), which never flows through Dart — so the generator dumps the
/// device logcat and includes it verbatim to match the console line-for-line.
class LogPdfGenerator {
  /// Generates the PDF into the app cache and returns the file, ready for
  /// sharing/saving.
  Future<File> generate() async {
    final buffer = AppLogBuffer.instance;
    final entries = buffer.entries;
    final logcatLines = await _captureLogcat();
    final device = await _deviceSummary();

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0.6 * PdfPageFormat.cm),
        header: (context) => pw.Text(
          'ExpenseFlow Log Report',
          style: pw.TextStyle(
            font: pw.Font.helveticaBold(),
            fontSize: 9,
            color: PdfColors.blueGrey700,
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              font: pw.Font.helvetica(),
              fontSize: 7,
              color: PdfColors.grey600,
            ),
          ),
        ),
        build: (context) => <pw.Widget>[
          pw.Header(
            level: 0,
            text: 'ExpenseFlow Log Report',
            textStyle: pw.TextStyle(
              font: pw.Font.helveticaBold(),
              fontSize: 18,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated: ${_stamp(DateTime.now())}',
            style: _metaStyle,
          ),
          pw.SizedBox(height: 2),
          pw.Text('Device: $device', style: _metaStyle),
          pw.SizedBox(height: 2),
          pw.Text('App started: ${_stamp(buffer.startedAt)}', style: _metaStyle),
          pw.SizedBox(height: 2),
          pw.Text(
            'Log entries: ${entries.length + logcatLines.length}',
            style: _metaStyle,
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 6),
          ...entries.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 1),
              child: pw.Text(
                entry.message,
                style: pw.TextStyle(
                  font: entry.level == AppLogLevel.error
                      ? pw.Font.helveticaBold()
                      : pw.Font.helvetica(),
                  fontSize: 6.5,
                  color: _colorFor(entry.level),
                ),
              ),
            ),
          ),
          if (logcatLines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'System log (Android logcat)',
              style: pw.TextStyle(
                font: pw.Font.helveticaBold(),
                fontSize: 8,
                color: PdfColors.blueGrey700,
              ),
            ),
            pw.SizedBox(height: 4),
            ...logcatLines.map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 1),
                child: pw.Text(
                  line,
                  style: pw.TextStyle(
                    font: pw.Font.courier(),
                    fontSize: 6.5,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/expenseflow_logs_${_fileStamp(DateTime.now())}.pdf',
    );
    await file.writeAsBytes(await doc.save());
    return file;
  }

  /// Dumps the Android system log (logcat) so the report matches the debug
  /// console, which shows logcat lines the Dart zone hook never sees.
  ///
  /// `-d` reads the whole buffer and exits, `-v brief` reproduces the exact
  /// `Priority/Tag( pid): message` lines the console prints. Runs only on
  /// Android; anything else returns nothing.
  Future<List<String>> _captureLogcat() async {
    if (!Platform.isAndroid) return const [];

    try {
      final result = await Process.run(
        _logcatBinary,
        const ['-d', '-v', 'brief'],
      );
      if (result.exitCode != 0) return const [];

      final out = result.stdout;
      if (out is! String || out.trim().isEmpty) return const [];
      return const LineSplitter().convert(out);
    } catch (e, st) {
      AppLogBuffer.instance.captureError('logReport.logcat', e, st);
      return const [];
    }
  }

  /// Android's `logcat` lives in `/system/bin`; app processes may not have it
  /// on `PATH`, so use the absolute location with the bare name as a fallback.
  String get _logcatBinary {
    try {
      return File('/system/bin/logcat').existsSync()
          ? '/system/bin/logcat'
          : 'logcat';
    } catch (_) {
      return 'logcat';
    }
  }

  static final pw.TextStyle _metaStyle = pw.TextStyle(
    font: pw.Font.helvetica(),
    fontSize: 8,
    color: PdfColors.grey800,
  );

  PdfColor _colorFor(AppLogLevel level) {
    return switch (level) {
      AppLogLevel.debug => PdfColors.blueGrey800,
      AppLogLevel.info => PdfColors.black,
      AppLogLevel.warning => PdfColors.orange900,
      AppLogLevel.error => PdfColors.red900,
    };
  }

  Future<String> _deviceSummary() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      // Brand/model + Android version make logs self-diagnosing.
      return '${info.brand} ${info.model} '
          '• Android ${info.version.release} (SDK ${info.version.sdkInt})';
    } catch (e, st) {
      AppLogBuffer.instance.captureError('logReport.deviceInfo', e, st);
      return 'Unknown device';
    }
  }

  String _stamp(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  String _fileStamp(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}${two(dt.month)}${two(dt.day)}_'
        '${two(dt.hour)}${two(dt.minute)}${two(dt.second)}';
  }
}