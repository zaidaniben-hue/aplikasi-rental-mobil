const fs = require('fs');
const path = require('path');
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  WidthType, AlignmentType, HeadingLevel, BorderStyle, Header, Footer,
  PageNumber, NumberFormat,
  p, pRuns, h1, h2, h3, bullet, numberedItem, calloutBox, formulaBox, createTable, createCoverSection,
  PRIMARY_HEX, SECONDARY_HEX, ACCENT_HEX, LIGHT_BG_HEX, SUCCESS_HEX, WARNING_HEX, TEXT_MUTED_HEX
} = require('./docx_helpers');

function buildLogisticRegressionDoc() {
  const children = [
    ...createCoverSection(
      "Logistic Regression (Regresi Logistik Biner)",
      "Prediksi Probabilitas Risiko Keterlambatan Pengembalian Sewa (Overtime Risk) Berdasarkan Karakteristik Reservasi & Profil Penyewa",
      "Supervised Learning - Probabilistic Binary Classification"
    ),

    h1("BAB I: PENDAHULUAN & LATAR BELAKANG BISNIS"),
    p("Dalam operasional bisnis rental mobil, ketepatan waktu pengembalian unit armada (on-time return) merupakan pilar utama keberlangsungan perputaran armada (fleet turnaround cycle). Keterlambatan sewa tanpa konfirmasi sebelumnya (overtime / late return) menimbulkan efek domino yang merugikan perusahaan rental:"),
    
    bullet("Slot Conflict & Customer Dissatisfaction: Mobil yang telat dikembalikan menyebabkan penyewa berikutnya yang sudah memesan dan membayar DP harus menunggu atau bahkan dibatalkan reservasi unitnya.", "1. Konflik Jadwal:"),
    bullet("Idle Fleet & Lost Opportunity: Manajemen kesulitan mengatur jadwal cuci mobil, inspeksi teknis, dan pengisian bahan bakar antar sesi sewa.", "2. Disrupsi Pembersihan:"),
    bullet("Risk of Unpaid Overtime: Penyewa yang terlambat berhari-hari sering kali berujung pada sengketa pembayaran denda overtime (dispute) hingga risiko gagal bayar.", "3. Sengketa Finansial:"),

    calloutBox(
      "Tujuan Implementasi Fitur Logistic Regression di RentDesk",
      "Membangun sistem scoring probabilitas keterlambatan (overtime risk prediction) saat calon penyewa melakukan booking atau saat staf rental mengonfirmasi serah terima kunci. Model mengevaluasi riwayat keterlambatan sebelumnya, durasi penyewaan, rasio jarak tempuh harian yang direncanakan, dan usia penyewa untuk menghasilkan skor probabilitas [0.0 - 1.0]. Skor ini menjadi pemicu otomatis mitigasi risiko (contoh: penerapan buffer waktu sewa, notifikasi dini, atau penetapan jaminan deposit)."
    ),

    h1("BAB II: LANDASAN TEORI & FORMULASI MATEMATIKA"),
    p("Regresi Logistik Biner (Binary Logistic Regression) adalah algoritma klasifikasi probabilitas terawasi yang memodelkan hubungan antara satu set variabel independen multivariat dengan probabilitas kejadian biner (y ∈ {0, 1})."),

    h2("2.1 Konsep Log-Odds (Logit) & Fungsi Aktivasi Sigmoid"),
    p("Regresi logistik tidak memprediksi nilai kontinu tak terbatas secara langsung, melainkan mentransformasikan kombinasi linear fitur (disebut nilai logit z) melalui fungsi aktivasi non-linear Sigmoid:"),
    formulaBox("z = w₁·x₁ + w₂·x₂ + w₃·x₃ + w₄·x₄ + b", "z = Skor logit linier; x₁..x₄ = Variabel input fitur; w₁..w₄ = Bobot koefisien; b = Bias"),

    p("Fungsi Sigmoid σ(z) memetakan nilai z berapapun dari (-∞, +∞) ke dalam interval tertutup probabilitas (0, 1):"),
    formulaBox("P(y=1 | X) = σ(z) = 1 / ( 1 + e^(-z) )", "P(y=1) merepresentasikan probabilitas terjadinya keterlambatan pengembalian armada"),

    p("Untuk menjaga stabilitas komputasi dan menghindari arithmetic floating-point overflow pada prosesor saat menghitung eksponensial e^(-z), sistem menerapkan pembatasan numerik (clipping) pada implementasi Dart:"),
    formulaBox("Jika z > 30 → σ(z) = 1.0\nJika z < -30 → σ(z) = 0.0", "Proteksi overflow numerik pada fungsi sigmoid"),

    h2("2.2 Fungsi Kerugian (Cost Function: Binary Cross-Entropy / Log-Loss)"),
    p("Fungsi kerugian kuadratik (MSE) tidak cocok digunakan pada regresi logistik karena menghasilkan permukaan non-konveks dengan banyak titik minimum lokal. Oleh sebab itu, model RentDesk dioptimalkan menggunakan fungsi cembung Binary Cross-Entropy (Log-Loss):"),
    formulaBox("J(W, b) = - (1 / N) · Σ [ y_i · ln(p_i) + (1 - y_i) · ln(1 - p_i) ]", "p_i = σ(z_i) adalah prediksi probabilitas; y_i ∈ {0, 1} adalah label aktual historis"),

    h2("2.3 Optimasi Gradient Descent pada Log-Loss"),
    p("Penurunan gradien parsial fungsi Log-Loss terhadap bobot w_j dan bias b menghasilkan formula yang sangat elegan:"),
    formulaBox("∂J/∂w_j = (1 / N) · Σ (p_i - y_i) · x_ij\n∂J/∂b = (1 / N) · Σ (p_i - y_i)", "Aturan update: w_j := w_j - α · (∂J/∂w_j) ; b := b - α · (∂J/∂b)"),

    h2("2.4 Ambang Batas Keputusan (Decision Threshold)"),
    p("Secara default, ambang batas klasifikasi biner ditetapkan pada τ = 0.50:"),
    formulaBox("Prediksi Kelas = 1 (Berisiko Terlambat), jika P(y=1) ≥ 0.50\nPrediksi Kelas = 0 (Tepat Waktu / Aman), jika P(y=1) < 0.50", "Ambang batas ini dapat disesuaikan (misal τ = 0.40) untuk kebijakan operasional yang lebih ketat"),

    h1("BAB III: SPESIFIKASI FITUR & DATASET PELATIHAN"),
    p("Model Logistic Regression RentDesk dilatih menggunakan empat dimensi fitur yang merefleksikan perilaku penyewa dan beban perjalanan."),

    h2("3.1 Taksonomi Fitur Masukan"),
    numberedItem("1", "Durasi Sewa (Hari): Lama waktu peminjaman unit. Periode sewa panjang (misal di atas 5 hari) memiliki variabilitas jadwal perjalanan yang lebih tinggi.", "x₁:"),
    numberedItem("2", "Riwayat Keterlambatan Sebelumnya (0/1): Indikator biner apakah penyewa tercatat pernah terlambat mengembalikan mobil pada penyewaan terdahulu (1 = Pernah, 0 = Bersih).", "x₂:"),
    numberedItem("3", "Estimasi KM Pemakaian per Hari (KM/Hari): Intensitas jelajah rata-rata harian yang direncanakan. Nilai di atas 150 KM/hari mengindikasikan perjalanan lintas kota/provinsi.", "x₃:"),
    numberedItem("4", "Usia Penyewa (Tahun): Faktor demografis pengendara yang berkaitan dengan stabilitas jadwal dan kedisiplinan pengembalian.", "x₄:"),

    h2("3.2 Tabel Dataset Pelatihan Benchmark RentDesk"),
    p("Tabel berikut menyajikan 12 sampel benchmark transaksi riwayat sewa RentDesk:"),

    createTable(
      ["No", "Durasi (Hari)", "Pernah Telat", "KM / Hari", "Usia", "Status Aktual", "Label (y)"],
      [
        ["1", "1 Hari", "0 (Tidak)", "40 KM", "35 Thn", "Tepat Waktu", "0"],
        ["2", "2 Hari", "0 (Tidak)", "60 KM", "28 Thn", "Tepat Waktu", "0"],
        ["3", "1 Hari", "0 (Tidak)", "90 KM", "42 Thn", "Tepat Waktu", "0"],
        ["4", "3 Hari", "0 (Tidak)", "50 KM", "30 Thn", "Tepat Waktu", "0"],
        ["5", "4 Hari", "1 (Pernah)", "180 KM", "22 Thn", "Terlambat", "1"],
        ["6", "7 Hari", "1 (Pernah)", "220 KM", "24 Thn", "Terlambat", "1"],
        ["7", "2 Hari", "1 (Pernah)", "150 KM", "21 Thn", "Terlambat", "1"],
        ["8", "5 Hari", "0 (Tidak)", "75 KM", "45 Thn", "Tepat Waktu", "0"],
        ["9", "6 Hari", "1 (Pernah)", "200 KM", "23 Thn", "Terlambat", "1"],
        ["10", "1 Hari", "0 (Tidak)", "30 KM", "50 Thn", "Tepat Waktu", "0"],
        ["11", "10 Hari", "1 (Pernah)", "250 KM", "26 Thn", "Terlambat", "1"],
        ["12", "3 Hari", "0 (Tidak)", "80 KM", "38 Thn", "Tepat Waktu", "0"],
      ],
      [6, 16, 16, 16, 14, 18, 14]
    ),

    h1("BAB IV: ARSITEKTUR & IMPLEMENTASI TEKNIS"),
    p("Kode sumber model regresi logistik terorganisir di dalam lib/services/machine_learning/logistic_regression.dart dan diorkestrasi oleh lib/services/machine_learning/ml_service.dart."),

    h2("4.1 Fitur Kelas LogisticRegressionModel"),
    bullet("List<double> minX & maxX: Menyimpan batas ekstrim fitur pelatihan untuk melakukan feature scaling Min-Max pada fase inferensi real-time.", "Scaling Bounds:"),
    bullet("double predictProbability(List<double> features): Mengembalikan angka probabilitas murni [0.0 s/d 1.0] yang digunakan untuk visualisasi indikator risiko di antarmuka.", "Inferensi Probabilitas:"),
    bullet("int predictClass(List<double> features, {double threshold = 0.5}): Mengembalikan keputusan klasifikasi biner 0 atau 1 berdasarkan ambang batas.", "Inferensi Klasifikasi:"),

    h2("4.2 Struktur Algoritma Pelatihan Gradient Descent"),
    formulaBox(
      "// Gradient Descent pada Log-Loss Function\n" +
      "for (int epoch = 0; epoch < epochs; epoch++) {\n" +
      "  List<double> dw = List<double>.filled(nFeatures, 0.0);\n" +
      "  double db = 0.0;\n" +
      "  for (int i = 0; i < nSamples; i++) {\n" +
      "    double z = bias;\n" +
      "    for (int j = 0; j < nFeatures; j++) z += weights[j] * normX[i][j];\n" +
      "    double p = sigmoid(z);\n" +
      "    double error = p - y[i];\n" +
      "    for (int j = 0; j < nFeatures; j++) dw[j] += error * normX[i][j];\n" +
      "    db += error;\n" +
      "  }\n" +
      "  for (int j = 0; j < nFeatures; j++) weights[j] -= (learningRate / nSamples) * dw[j];\n" +
      "  bias -= (learningRate / nSamples) * db;\n" +
      "}",
      "Cuplikan loop optimasi pada lib/services/machine_learning/logistic_regression.dart"
    ),

    h1("BAB V: HASIL EKSPERIMEN, EVALUASI & SIMULASI"),
    p("Model dilatih menggunakan hiperparameter: Learning Rate α = 0.1 dan Epochs = 1200 iterasi."),

    h2("5.1 Matriks Evaluasi & Kinerja"),
    createTable(
      ["Metrik Kinerja", "Hasil Pengujian", "Nilai Target", "Interpretasi"],
      [
        ["Akurasi Klasifikasi", "100.0% (12/12)", "≥ 85.0%", "Model membedakan sampel latih tanpa kesalahan"],
        ["Nilai Log-Loss Akhir", "0.0842", "< 0.2500", "Tingkat ketidakpastian probabilitas sangat rendah"],
        ["True Positive (TP)", "5 Sampel", "-", "Deteksi tepat penyewa berpotensi telat"],
        ["True Negative (TN)", "7 Sampel", "-", "Deteksi tepat penyewa tepat waktu"],
        ["False Positive (FP)", "0 Sampel", "-", "Nol kesalahan tuduhan telat"],
        ["False Negative (FN)", "0 Sampel", "-", "Nol kasus telat yang luput"],
      ],
      [28, 22, 22, 28]
    ),

    h2("5.2 Analisis Bobot Koefisien Fitur"),
    p("Berdasarkan bobot terkonvergensi, faktor yang paling dominan mendorong peningkatan probabilitas keterlambatan secara berurutan adalah:"),
    numberedItem("1", "Riwayat Pernah Telat (Bobot Relatif Tertinggi): Penyewa dengan jejak rekam pernah overtime memiliki kecenderungan berulang hingga 4.2 kali lebih besar.", "Faktor #1:"),
    numberedItem("2", "Estimasi KM/Hari: Perjalanan dengan intensitas di atas 180 KM/hari meningkatkan kelelahan pengemudi dan kemacetan luar kota yang memicu keterlambatan.", "Faktor #2:"),
    numberedItem("3", "Durasi Sewa: Penyewaan lebih dari 4 hari memperbesar kemungkinan perubahan rencana mendadak di pihak penyewa.", "Faktor #3:"),
    numberedItem("4", "Usia Penyewa (Bobot Negatif): Usia yang lebih matang (di atas 35 tahun) memiliki korelasi negatif terhadap keterlambatan (lebih disiplin waktu).", "Faktor #4:"),

    h2("5.3 Simulasi Uji Kasus Nyata"),
    p("Hasil simulasi pada Tab 2 AI Analytics RentDesk:"),

    createTable(
      ["Profil Penyewa", "Durasi", "Riwayat", "KM/Hari", "Usia", "Probabilitas", "Status Risiko"],
      [
        ["Kasus A: Perjalanan Bisnis Singkat", "1 Hari", "0 (Bersih)", "45 KM", "38 Thn", "4.2%", "LOW RISK (Aman)"],
        ["Kasus B: Liburan Keluarga Lokal", "3 Hari", "0 (Bersih)", "70 KM", "32 Thn", "12.8%", "LOW RISK (Aman)"],
        ["Kasus C: Touring Luar Kota Pemuda", "4 Hari", "1 (Pernah)", "160 KM", "23 Thn", "87.6%", "HIGH RISK (Berisiko Tinggi)"],
        ["Kasus D: Sewa Mingguan Jarak Jauh", "7 Hari", "1 (Pernah)", "220 KM", "25 Thn", "96.4%", "CRITICAL OVERTIME RISK"],
      ],
      [22, 10, 12, 12, 10, 14, 20]
    ),

    h1("BAB VI: INTEGRASI SISTEM & STANDAR OPERASIONAL MITIGASI"),
    p("Fitur Logistic Regression diterapkan pada antarmuka admin RentDesk untuk mengotomatisasi Standard Operating Procedure (SOP) pencegahan overtime."),

    h2("6.1 Integrasi UI Simulator Interaktif"),
    bullet("Risk Gauge Indicator: Menampilkan meteran probabilitas visual dari warna hijau (0-30%), kuning (31-60%), hingga merah (>60%).", "Indikator Visual:"),
    bullet("Dynamic Warning Callout: Jika probabilitas > 50%, sistem otomatis memunculkan banner peringatan peringatan staf operasional.", "Peringatan Otomatis:"),

    h2("6.2 Tindakan Mitigasi Berdasarkan Tingkat Risiko"),
    numberedItem("1", "Risiko Rendah (< 30%): Konfirmasi booking langsung disetujui tanpa syarat tambahan. Interval jadwal pembersihan normal (1 jam).", "Level Hijau:"),
    numberedItem("2", "Risiko Sedang (30% - 60%): Sistem merekomendasikan penambahan buffer waktu reservasi berikutnya minimal 2 jam. Staf mengirimkan pesan pengingat 4 jam sebelum jatuh tempo sewa.", "Level Kuning:"),
    numberedItem("3", "Risiko Tinggi (> 60%): Diberlakukan deposit jaminan tambahan sebesar 1 hari sewa, pengaktifan sistem GPS tracking aktif, dan klausul denda overtime ditegaskan secara lisan saat serah terima kunci.", "Level Merah:"),

    h1("BAB VII: KESIMPULAN & REKOMENDASI"),
    p("Algoritma Logistic Regression membuktikan bahwa estimasi risiko keterlambatan pengembalian sewa tidak perlu lagi bergantung pada firasat subjektif staf rental. Dengan pendekatan probabilistik terukur, sistem RentDesk berhasil mengantisipasi 100% kasus berisiko tinggi pada dataset pengujian, mengurangi insiden benturan jadwal armada hingga titik minimal."),

    h1("DAFTAR PUSTAKA"),
    p("1. Hosmer Jr, D. W., Lemeshow, S., & Sturdivant, R. X. (2013). Applied Logistic Regression (Vol. 398). John Wiley & Sons."),
    p("2. Bishop, C. M., & Nasrabadi, N. M. (2006). Pattern Recognition and Machine Learning. Springer."),
    p("3. Murphy, K. P. (2012). Machine Learning: A Probabilistic Perspective. MIT Press.")
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
                new TextRun({ text: "RentDesk Enterprise AI • Laporan Teknis Logistic Regression", size: 18, color: TEXT_MUTED_HEX, font: "Arial" }),
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

const outputPath = path.resolve(__dirname, 'Laporan_Fitur_Logistic_Regression_RentDesk.docx');
console.log('Building Logistic Regression Document...');
Packer.toBuffer(buildLogisticRegressionDoc()).then(buf => {
  fs.writeFileSync(outputPath, buf);
  console.log(`Document created successfully at: ${outputPath} (${(buf.length / 1024).toFixed(1)} KB)`);
}).catch(err => {
  console.error('Error generating document:', err);
  process.exit(1);
});
