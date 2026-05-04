// test-load.js
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');

const API_URL = 'http://localhost:3000/api/review-cv';
const CV_FILE_PATH = './data/helllo.pdf'; // Thay bằng đường dẫn 1 file CV mẫu trong máy bạn
const TOTAL_REQUESTS = 30; // Số lượng CV muốn spam cùng lúc

async function runLoadTest() {
  console.log(`🚀 Bắt đầu gửi đồng thời ${TOTAL_REQUESTS} CV...`);
  const requests = [];

  for (let i = 1; i <= TOTAL_REQUESTS; i++) {
    const form = new FormData();
    form.append('cv', fs.createReadStream(CV_FILE_PATH));

    // Gửi request không đợi (bất đồng bộ)
    const req = axios
      .post(API_URL, form, {
        headers: { ...form.getHeaders() },
      })
      .then((res) => {
        console.log(
          `[Req ${i}] Thành công. Tracking ID: ${res.data.trackingId}`,
        );
      })
      .catch((err) => {
        console.error(
          `[Req ${i}] Lỗi ở Controller:`,
          err.response?.data || err.message,
        );
      });

    requests.push(req);
  }

  await Promise.all(requests);
  console.log(
    '✅ Đã gửi toàn bộ request. Hãy mở Bull-Board để theo dõi Worker xử lý!',
  );
}

runLoadTest();
