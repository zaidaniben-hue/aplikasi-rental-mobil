const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('================================================================');
console.log('GENERATING ALL 4 MACHINE LEARNING DOCX REPORTS FOR RENTDESK');
console.log('================================================================');

const scripts = [
  'generate_linear_regression_report.js',
  'generate_logistic_regression_report.js',
  'generate_naive_bayes_report.js',
  'generate_svm_report.js'
];

scripts.forEach(script => {
  console.log(`\n>> Executing: ${script}...`);
  execFileSync('node', [path.resolve(__dirname, script)], { stdio: 'inherit' });
});

console.log('\n================================================================');
console.log('ALL 4 DOCX REPORTS GENERATED SUCCESSFULLY:');
const expectedFiles = [
  'Laporan_Fitur_Linear_Regression_RentDesk.docx',
  'Laporan_Fitur_Logistic_Regression_RentDesk.docx',
  'Laporan_Fitur_Naive_Bayes_RentDesk.docx',
  'Laporan_Fitur_SVM_RentDesk.docx'
];

expectedFiles.forEach(file => {
  const p = path.resolve(__dirname, file);
  if (fs.existsSync(p)) {
    const stat = fs.statSync(p);
    console.log(`- [OK] ${file} (${(stat.size / 1024).toFixed(1)} KB)`);
  } else {
    console.error(`- [MISSING] ${file}`);
  }
});
console.log('================================================================\n');
