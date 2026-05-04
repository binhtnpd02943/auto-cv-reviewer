const fs = require('fs').promises; // 👈 Đổi sang dùng promises
const { PDFParse } = require('pdf-parse');

const extractTextFromPDF = async (filePath) => {
  try {
    // 👈 Đọc file bất đồng bộ để không chặn Event Loop của Node.js
    const dataBuffer = await fs.readFile(filePath);

    const parser = new PDFParse({
      data: dataBuffer, // Truyền buffer vào đây
    });

    const result = await parser.getText();
    return result.text;
  } catch (error) {
    console.error('Lỗi khi đọc file PDF:', error);
    throw new Error('Không thể trích xuất nội dung từ PDF.');
  }
};

module.exports = { extractTextFromPDF };
