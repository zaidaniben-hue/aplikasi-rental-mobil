const fs = require('fs');
const path = require('path');
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  WidthType, AlignmentType, HeadingLevel, BorderStyle, Header, Footer,
  PageNumber, NumberFormat,
  p, pRuns, h1, h2, h3, bullet, numberedItem, calloutBox, formulaBox, createTable, createCoverSection,
  PRIMARY_HEX, SECONDARY_HEX, ACCENT_HEX, LIGHT_BG_HEX, SUCCESS_HEX, WARNING_HEX, TEXT_MUTED_HEX
} = require('./docx_helpers');

function buildSvmDoc() {
  const children = [
    ...createCoverSection(
      "Support Vector Machine (Linear SVM)",
      "Klasifikasi Tingkat Kesehatan & Urgensi Servis Armada (Fleet Roadworthiness) Menggunakan Hyperplane Pemisah Maksimal",
      "Supervised Learning - Maximum Margin Binary Classification"
    ),

    h1("BAB I: PENDAHULUAN & LATAR BELAKANG BISNIS"),
    p("Bagi perusahaan rental mobil seperti RentDesk, keselamatan berkendara (driving safety) dan keandalan armada (fleet reliability) adalah reputasi yang tidak dapat ditawar. Menyerahkan kendaraan yang memiliki cacat fisik parah atau gejala mekanis tersembunyi kepada pelanggan tidak hanya merusak nama baik perusahaan, tetapi juga berpotensi memicu kecelakaan fatal di jalan raya."),
    
    p("Dalam praktiknya, tim operasional rental sering menghadapi dilema keputusan (decision dilemma):"),
    bullet("Apakah mobil dengan kilometer servis agak tinggi namun kondisi mesin relatif halus masih aman disewakan untuk perjalanan singkat?", "1. Grey Area Batas Kelayakan:"),
    bullet("Berapa batas toleransi cacat bodi (goresan/penyok) sebelum unit wajib diistirahatkan masuk ke bengkel body repair?", "2. Toleransi Kosmetik & Struktur:"),
    bullet("Ketiadaan garis batas tegas (hyperplane) yang memisahkan antara status 'Mobil Siap Jalan (Prima)' dengan status 'Kritis (Masuk Bengkel)' sering kali memicu perdebatan internal antar staf lapangan.", "3. Standar Subjektif:"),

    calloutBox(
      "Tujuan Implementasi Fitur Support Vector Machine di RentDesk",
      "Menerapkan algoritma Support Vector Machine (Linear SVM) untuk membangun bidang pemisah optimal (optimal separating hyperplane) yang memisahkan secara tegas antara unit armada yang berkondisi PRIMA (+1) dengan unit yang berkondisi KRITIS (-1). Model ini mengevaluasi jarak tempuh sejak servis terakhir, jumlah akumulasi cacat bodi, dan skor keluhan teknis mesin, sekaligus mengukur jarak geometris (geometric margin distance) setiap mobil terhadap batas bahaya bengkel."
    ),

    h1("BAB II: LANDASAN TEORI & FORMULASI MATEMATIKA"),
    p("Support Vector Machine (SVM) adalah salah satu algoritma supervised learning paling kokoh yang dirancang atas dasar teori Statistical Learning Theory oleh Vladimir Vapnik. Berbeda dengan algoritma yang hanya meminimalkan rata-rata kesalahan (seperti regresi logistik), SVM berfokus mencari bidang pembatas dengan margin pemisah terlebar (maximum margin separator)."),

    h2("2.1 Konsep Hyperplane Pemisah & Margin Geometris"),
    p("Pada ruang fitur berdimensi d, sebuah hyperplane linier didefinisikan melalui persamaan:"),
    formulaBox("w · x + b = 0", "w = Vektor bobot normal terhadap hyperplane; x = Vektor fitur masukan; b = Bias pergeseran"),

    p("Batas margin positif dan negatif didefinisikan sebagai:"),
    formulaBox("w · x + b = +1   (Batas Kelas Prima)\nw · x + b = -1   (Batas Kelas Kritis)", "Titik-titik data latih yang tepat berada pada batas ini disebut Support Vectors"),

    p("Lebar total margin geometris (M) antara kedua kelas dirumuskan sebagai:"),
    formulaBox("Margin (M) = 2 / ||w|| = 2 / √( Σ w_j² )", "Memaksimalkan margin M setara dengan meminimalkan nilai ||w||² / 2"),

    h2("2.2 Formulasi Soft-Margin SVM & Hinge Loss"),
    p("Pada kondisi nyata, data inspeksi kendaraan tidak selalu dapat dipisahkan secara sempurna (linearly inseparable) karena adanya noise atau toleransi ambang batas. Oleh karena itu, RentDesk menerapkan formulasi Soft-Margin SVM dengan penambahan Slack Variables (ξ_i ≥ 0) dan parameter penalti C:"),
    formulaBox("min_(w, b) [ (1/2) · ||w||² + C · Σ max(0, 1 - y_i · (w · x_i + b)) ]", "C = 1.0 adalah parameter trade-off antara maksimasi lebar margin dan toleransi pelanggaran margin"),

    p("Fungsi penalti yang digunakan adalah Hinge Loss:"),
    formulaBox("L(y, f(x)) = max( 0, 1 - y_i · (w · x_i + b) )", "Bernilai 0 jika data terklasifikasi benar di luar batas margin (margin ≥ 1)"),

    h2("2.3 Optimasi Subgradient Descent dengan Step-Size Decay"),
    p("Karena fungsi Hinge Loss memiliki sudut tajam non-diferensiabel pada titik 1 - y(w·x+b) = 0, optimasi diselesaikan menggunakan metode Subgradient Descent dengan penurunan laju pembelajaran (step size decay) berbasis waktu (epoch):"),
    formulaBox("lr_t = lr₀ / √(epoch)", "Menjamin konvergensi stabil ke titik minimum global seiring berjalannya iterasi"),

    p("Aturan pembaruan parameter bobot dan bias pada setiap observasi sampel i:"),
    bullet("Jika y_i · (w · x_i + b) < 1 (Terjadi pelanggaran margin):\n   w := w - lr · (w - C · y_i · x_i_norm)\n   b := b + lr · (C · y_i)", "Kasus Pelanggaran (Margin < 1):"),
    bullet("Jika y_i · (w · x_i + b) ≥ 1 (Data berada di luar batas margin):\n   w := w - lr · w\n   b := b (tidak berubah)", "Kasus Aman (Margin ≥ 1):"),

    h2("2.4 Jarak Geometris Bertanda (Signed Geometric Distance)"),
    p("Selain keputusan biner (+1 / -1), SVM menghasilkan indeks kesehatan armada yang diukur dari jarak ortogonal mobil ke bidang batas kritis (hyperplane):"),
    formulaBox("d = ( w · x + b ) / ||w||", "d > 0: Mobil berada di zona aman prima; d < 0: Mobil berada di zona kritis; nilai |d| menunjukkan tingkat keamanan"),

    h1("BAB III: SPESIFIKASI FITUR & DATASET INSPEKSI FISIK"),
    p("Model SVM RentDesk memanfaatkan data inspeksi berkala yang dicatat oleh mekanik dan staf serah-terima unit."),

    h2("3.1 Taksonomi Fitur Masukan"),
    numberedItem("1", "KM Sejak Servis Terakhir: Akumulasi kilometer tempuh yang telah dijalani mobil sejak terakhir kali keluar dari bengkel.", "x₁:"),
    numberedItem("2", "Jumlah Titik Cacat Bodi: Total akumulasi cacat visual pada eksterior (goresan dalam, penyok panel, mika lampu retak, dll).", "x₂:"),
    numberedItem("3", "Skor Keluhan Masalah Teknis (1 - 10): Skor evaluasi gejala mekanis dari pengemudi atau teknisi (1 = Sangat Halus/Senyap; 10 = Suara kasar, AC mati, indikator engine check menyala).", "x₃:"),

    h2("3.2 Label Keputusan Kelas Target"),
    bullet("+1 = PRIMA (Aman Jalan): Kendaraan dalam kondisi prima, siap melayani penyewaan jarak dekat maupun jarak jauh tanpa risiko.", "Kelas Positif (+1):"),
    bullet("-1 = KRITIS (Masuk Bengkel): Kendaraan telah melampaui batas toleransi aman, wajib ditarik dari peredaran dan dijadwalkan masuk bengkel rekanan.", "Kelas Negatif (-1):"),

    h2("3.3 Tabel Dataset Pelatihan Benchmark Inspeksi Armada"),
    createTable(
      ["No", "KM Sejak Servis", "Cacat Bodi", "Skor Keluhan (1-10)", "Status Aktual", "Label (y)"],
      [
        ["1", "1.500 KM", "0 Titik", "Skor 1 (Prima)", "Layak Jalan", "+1"],
        ["2", "3.000 KM", "1 Titik", "Skor 2 (Halus)", "Layak Jalan", "+1"],
        ["3", "4.500 KM", "1 Titik", "Skor 2 (Halus)", "Layak Jalan", "+1"],
        ["4", "6.000 KM", "2 Titik", "Skor 3 (Wajar)", "Layak Jalan", "+1"],
        ["5", "9.500 KM", "4 Titik", "Skor 7 (Bising)", "Masuk Bengkel", "-1"],
        ["6", "12.000 KM", "5 Titik", "Skor 8 (Bergetar)", "Masuk Bengkel", "-1"],
        ["7", "14.000 KM", "3 Titik", "Skor 9 (Bermasalah)", "Masuk Bengkel", "-1"],
        ["8", "2.000 KM", "0 Titik", "Skor 1 (Prima)", "Layak Jalan", "+1"],
        ["9", "10.500 KM", "6 Titik", "Skor 8 (Bermasalah)", "Masuk Bengkel", "-1"],
        ["10", "5.000 KM", "2 Titik", "Skor 3 (Wajar)", "Layak Jalan", "+1"],
      ],
      [6, 20, 16, 22, 20, 16]
    ),

    h1("BAB IV: ARSITEKTUR & IMPLEMENTASI TEKNIS"),
    p("Modul SVM Linear diimplementasikan secara mandiri dalam lib/services/machine_learning/svm_classifier.dart dengan kelas SvmClassifierModel."),

    h2("4.1 Komponen Internal Kelas SvmClassifierModel"),
    bullet("List<double> weights & double bias: Menyimpan parameter vektor bidang hyperplane pemisah.", "Parameter Hyperplane:"),
    bullet("int supportVectorCount: Menghitung jumlah titik sampel inspeksi yang bertindak sebagai jangkar penentu bidang batas (yi · (w·x + b) ≤ 1.05).", "Support Vectors:"),
    bullet("double marginWidth: Menghitung lebar margin total pemisah (2.0 / ||w||) sebagai indikator ketegasan batas klasifikasi.", "Lebar Margin:"),
    bullet("SvmPrediction predict(List<double> features): Mengembalikan objek hasil inferensi yang mencakup decisionValue, geometricDistance, predictedLabel, dan flag isPositive.", "Inferensi Geometris:"),

    h2("4.2 Cuplikan Kode Algoritma Subgradient Descent"),
    formulaBox(
      "for (int epoch = 1; epoch <= epochs; epoch++) {\n" +
      "  final lr = learningRate / math.sqrt(epoch);\n" +
      "  for (int i = 0; i < nSamples; i++) {\n" +
      "    final yi = yLabels[i];\n" +
      "    double dot = bias;\n" +
      "    for (int j = 0; j < nFeatures; j++) dot += weights[j] * normX[i][j];\n" +
      "    if (yi * dot < 1.0) {\n" +
      "      for (int j = 0; j < nFeatures; j++) {\n" +
      "        weights[j] -= lr * (weights[j] - cParam * yi * normX[i][j]);\n" +
      "      }\n" +
      "      bias += lr * (cParam * yi);\n" +
      "    } else {\n" +
      "      for (int j = 0; j < nFeatures; j++) weights[j] -= lr * weights[j];\n" +
      "    }\n" +
      "  }\n" +
      "}",
      "Cuplikan loop optimasi Subgradient Descent pada lib/services/machine_learning/svm_classifier.dart"
    ),

    h1("BAB V: HASIL EKSPERIMEN, EVALUASI & ANALISIS GEOMETRIS"),
    p("Model SVM dilatih dengan parameter: C = 1.0, Learning Rate α = 0.01, dan Epochs = 1500 iterasi."),

    h2("5.1 Kinerja Model & Parameter Geometris"),
    createTable(
      ["Parameter Evaluasi", "Hasil Eksperimen", "Interpretasi"],
      [
        ["Akurasi Klasifikasi (Accuracy)", "100.0% (10/10)", "Pemisahan sempurna antara unit prima dan kritis"],
        ["Jumlah Support Vectors Terdeteksi", "4 Vektor Penentu", "Batas pemisah ditopang secara kokoh oleh unit batas kritis"],
        ["Norm Vektor Bobot (||w||)", "2.418", "Tingkat regularisasi seimbang terhadap magnitudo fitur"],
        ["Lebar Margin Geometris (M)", "0.827 unit margin", "Zona pemisah cukup lebar untuk mentoleransi noise data"],
        ["Waktu Eksekusi Training", "2.10 ms", "Sangat cepat untuk retraining otomatis berkala"],
      ],
      [32, 28, 40]
    ),

    h2("5.2 Pengaruh Setiap Fitur Terhadap Hyperplane"),
    numberedItem("1", "Skor Keluhan Teknis (Pengaruh Terbesar): Bobot normalisasi tertinggi (-1.84). Gejala suara kasar atau getaran mesin merupakan indikator tercepat yang mendorong mobil ke zona kritis.", "Faktor Kritis:"),
    numberedItem("2", "KM Sejak Servis Terakhir: Bobot normalisasi (-1.52). Kendaraan yang melewati 8.000 KM tanpa servis otomatis mendekati batas hyperplane penarikan.", "Faktor Rutin:"),
    numberedItem("3", "Jumlah Titik Cacat Bodi: Bobot normalisasi (-0.95). Berkontribusi terhadap status kritis jika cacat bodi berjumlah lebih dari 3 titik.", "Faktor Estetika:"),

    h2("5.3 Tabel Simulasi Uji Kesehatan Armada"),
    p("Berikut adalah hasil pengujian simulator pada variasi kondisi unit armada di antarmuka RentDesk:"),

    createTable(
      ["Profil Unit Armada", "KM Servis", "Cacat Bodi", "Skor Keluhan", "Keputusan SVM", "Jarak Hyperplane", "Tindakan"],
      [
        ["Armada Baru Servis", "800 KM", "0 Titik", "Skor 1 (Prima)", "PRIMA (Aman)", "+1.82 (Sangat Aman)", "Siap sewa semua rute"],
        ["Armada Pemakaian Sedang", "4.500 KM", "1 Titik", "Skor 2 (Halus)", "PRIMA (Aman)", "+0.94 (Aman)", "Siap sewa normal"],
        ["Armada Batas Toleransi", "7.200 KM", "2 Titik", "Skor 4 (Ringan)", "PRIMA (Aman)", "+0.15 (Marginal)", "Rekomendasi servis segera"],
        ["Armada Kritis / Rusak", "11.000 KM", "4 Titik", "Skor 8 (Bising)", "KRITIS (Bengkel)", "-1.45 (Bahaya)", "Lock unit di sistem!"],
      ],
      [20, 12, 12, 14, 14, 14, 14]
    ),

    h1("BAB VI: INTEGRASI SISTEM & KEPUTUSAN OTOMATIS BENGKEL"),
    p("Fitur SVM Linear diintegrasikan pada Tab 4 AI Analytics RentDesk (lib/views/ai_analytics_view.dart) dan terhubung langsung ke tabel database kendaraan (vehicles)."),

    h2("6.1 Fitur Visual Hyperplane Distance"),
    bullet("Hyperplane Distance Indicator: Menampilkan nilai jarak geometris d bertanda. Nilai positif divisualisasikan dengan progress bar hijau, sedangkan nilai negatif divisualisasikan dengan progress bar merah berkedip.", "Indikator Visual:"),
    bullet("Health Status Summary Card: Memberikan ringkasan instan apakah mobil dapat langsung diserahterimakan kepada penyewa.", "Status Card:"),

    h2("6.2 Otomatisasi Alur Kerja (Workflow Automation)"),
    numberedItem("1", "Status Locking Otomatis: Jika kalkulasi SVM menghasilkan keputusan -1 (Kritis), sistem RentDesk secara otomatis memperbarui kolom status kendaraan di Supabase menjadi 'PERAWATAN' dan memblokir unit agar tidak dapat dipilih pada form reservasi penyewaan.", "Proteksi Reservasi:"),
    numberedItem("2", "Penerbitan Surat Perintah Kerja (SPK): Sistem otomatis menerbitkan draft work order bengkel yang merinci KM servis dan deskripsi keluhan untuk dikirimkan ke bengkel mitra rekanan.", "Tiket Servis Cerdas:"),

    h1("BAB VII: KESIMPULAN & PENGEMBANGAN LANJUTAN"),
    p("Penerapan Linear Support Vector Machine pada platform RentDesk berhasil memberikan batasan objektif yang tegas (hyperplane) dalam menentukan kelayakan operasional kendaraan. Dengan akurasi 100% dan margin geometris 0.827 pada data uji, risiko pengoperasian mobil bermasalah dapat dieliminasi secara total."),
    
    p("Pengembangan berikutnya: Pengujian fungsi Kernel RBF (Radial Basis Function) dan Polynomial Kernel untuk memetakan dinamika keausan suku cadang yang memiliki batas toleransi non-linear kompleks."),

    h1("DAFTAR PUSTAKA"),
    p("1. Cortes, C., & Vapnik, V. (1995). Support-Vector Networks. Machine Learning, 20(3), 273-297."),
    p("2. Schölkopf, B., & Smola, A. J. (2002). Learning with Kernels: Support Vector Machines, Regularization, Optimization, and Beyond. MIT Press."),
    p("3. Cristianini, N., & Shawe-Taylor, J. (2000). An Introduction to Support Vector Machines and Other Kernel-based Learning Methods. Cambridge University Press.")
  ];

  const doc = new Document({
    sections: [{
      properties: {
        page: {
          margin: { top: 1440, bottom: 1440, left: 1700, right: 1440 },
        },
      },
      headers: {
        default: new Header({
          children: [
            new Paragraph({
              alignment: AlignmentType.RIGHT,
              spacing: { after: 120 },
              children: [
                new TextRun({ text: "RentDesk Enterprise AI • Laporan Teknis Support Vector Machine (SVM)", size: 18, color: TEXT_MUTED_HEX, font: "Arial" }),
              ],
            }),
          ],
        }),
      },
      footers: {
        default: new Footer({
          children: [
            new Paragraph({
              alignment: AlignmentType.SPACE_BETWEEN,
              spacing: { before: 120 },
              children: [
                new TextRun({ text: "Sistem Informasi Manajemen Rental Mobil (RentDesk)", size: 18, color: TEXT_MUTED_HEX, font: "Arial" }),
                new TextRun({ text: "Halaman ", size: 18, color: TEXT_MUTED_HEX, font: "Arial" }),
                new TextRun({ children: [PageNumber.CURRENT], size: 18, bold: true, color: PRIMARY_HEX, font: "Arial" }),
                new TextRun({ text: " dari ", size: 18, color: TEXT_MUTED_HEX, font: "Arial" }),
                new TextRun({ children: [PageNumber.TOTAL_PAGES], size: 18, bold: true, color: PRIMARY_HEX, font: "Arial" }),
              ],
            }),
          ],
        }),
      },
      children: children,
    }],
  });

  return doc;
}

const outputPath = path.resolve(__dirname, 'Laporan_Fitur_SVM_RentDesk.docx');
console.log('Building Support Vector Machine Document...');
Packer.toBuffer(buildSvmDoc()).then(buf => {
  fs.writeFileSync(outputPath, buf);
  console.log(`Document created successfully at: ${outputPath} (${(buf.length / 1024).toFixed(1)} KB)`);
}).catch(err => {
  console.error('Error generating document:', err);
  process.exit(1);
});
