const { GoogleGenAI } = require('@google/genai');

const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
});

const MAX_CHARACTERS = 15000;

const analyzeCV = async (cvText) => {
  try {
    const safeText = cvText.slice(0, MAX_CHARACTERS);

    const prompt = `
                  Bạn là một Chuyên gia Đánh giá Năng lực Kỹ thuật (Technical Assessment Expert), kết hợp góc nhìn hệ thống của một Engineering Manager và sự nhạy bén của một Senior IT Recruiter.
                  Nhiệm vụ của bạn là đánh giá CV này một cách KHÁCH QUAN, CÔNG BẰNG và CHUYÊN NGHIỆP. Hãy tập trung vào các BẰNG CHỨNG THỰC TẾ (Evidence-based) được thể hiện trong CV, tránh mọi định kiến hoặc suy đoán.

                  =====================
                  NỘI DUNG CV:
                  ${safeText}
                  =====================

                  TIÊU CHÍ PHÂN TÍCH VÀ ĐÁNH GIÁ (RUBRIC):

                  1. Phân loại Cấp độ (Seniority Leveling):
                  Đánh giá level dựa trên phạm vi ảnh hưởng và mức độ tự chủ, không chỉ dựa vào số năm kinh nghiệm:
                  - Fresher/Junior: Tập trung vào việc hoàn thành task, sử dụng công nghệ theo hướng dẫn, dự án nhỏ/clone.
                  - Mid-level: Có khả năng làm việc độc lập, hiểu rõ luồng hệ thống, áp dụng best practices, tối ưu mã nguồn.
                  - Senior+: Thiết kế kiến trúc, giải quyết bài toán khó (scale, performance), dẫn dắt team, tạo ra tác động lớn đến business.

                  2. Chấm điểm Khách quan (1-10) & Phân hạng (Tier):
                  - Đánh giá dựa trên 3 yếu tố: Sự rõ ràng của vai trò (Role clarity), Độ phức tạp của dự án (Project complexity), và Kết quả đo lường được (Measurable impact/Metrics).
                  - Tier:
                    + "Exceptional": Vượt trội, có impact rõ ràng bằng số liệu, kiến trúc hoặc bài toán phức tạp.
                    + "Strong": Nền tảng vững chắc, mô tả dự án rõ ràng, kinh nghiệm thực tế tốt.
                    + "Average": Mức độ tiêu chuẩn, mô tả công việc mang tính liệt kê task, thiếu metrics.
                    + "Needs Clarification": Sơ sài, thông tin mâu thuẫn hoặc khó đánh giá năng lực thực sự.

                  3. Kỹ năng được kiểm chứng (Verified Skills):
                  Chỉ trích xuất các kỹ năng (tối đa 8) xuất hiện trong ngữ cảnh dự án hoặc kinh nghiệm làm việc cụ thể. Bỏ qua các kỹ năng chỉ được liệt kê chay trong phần "Skills" mà không có dẫn chứng áp dụng.

                  4. Điểm mạnh thực tế (Evidence-based Strengths):
                  Chỉ ra 2-3 điểm mạnh cốt lõi. MỖI ĐIỂM MẠNH BẮT BUỘC PHẢI KÈM THEO NGỮ CẢNH TỪ CV (Ví dụ: "Khả năng tối ưu hiệu suất: Thể hiện qua việc giảm thời gian query xuống 50% trong dự án X").

                  5. Lỗ hổng / Điểm cần cải thiện (Areas for Improvement):
                  Phân tích khách quan những điểm còn thiếu hụt so với định hướng hoặc level (VD: Thiếu kinh nghiệm với hệ thống phân tán, chưa có số liệu chứng minh hiệu quả, mô tả công việc quá chung chung).

                  6. Điểm cần làm rõ khi Phỏng vấn (Interview Probing Points):
                  Chỉ ra những điểm chưa rõ ràng cần HR/Tech Lead đặt câu hỏi thêm (VD: "Vai trò cụ thể trong dự án Y là gì khi team có 10 người?", "Lý do có khoảng trống công việc từ 2022-2023?"). Trả về mảng rỗng [] nếu CV đã đủ thông tin.

                  =====================
                  FORMAT KẾT QUẢ TRẢ VỀ:
                  Bắt buộc tuân thủ cấu trúc JSON sau (không chứa markdown, không giải thích thêm):

                  {
                    "position_and_seniority": "string (VD: Mid-level Backend Engineer)",
                    "evaluation": {
                      "score": number,
                      "tier": "Exceptional | Strong | Average | Needs Clarification",
                      "justification": "string (Tóm tắt lý do đánh giá một cách chuyên nghiệp và khách quan)"
                    },
                    "years_of_experience": number | null,
                    "verified_skills": ["string"],
                    "evidence_based_strengths": ["string"],
                    "areas_for_improvement": ["string"],
                    "interview_probing_points": ["string"]
                  }
                  `;

    const response = await ai.models.generateContent({
      model: process.env.GEMINI_MODEL || 'gemini-2.5-flash',
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      config: {
        responseMimeType: 'application/json',
      },
    });

    let jsonString =
      response.candidates?.[0]?.content?.parts?.[0]?.text || '{}';

    jsonString = jsonString.replace(/```json\n?|```/g, '').trim();

    const parsed = JSON.parse(jsonString);

    return {
      position: parsed.position_and_seniority || null,
      score: parsed.evaluation?.score || 0,
      tier: parsed.evaluation?.tier || null,
      summary: parsed.evaluation?.justification || null,
      years_of_experience:
        typeof parsed.years_of_experience === 'number'
          ? parsed.years_of_experience
          : null,
      skills: Array.isArray(parsed.verified_skills)
        ? parsed.verified_skills
        : [],
      strengths: Array.isArray(parsed.evidence_based_strengths)
        ? parsed.evidence_based_strengths
        : [],
      weaknesses: Array.isArray(parsed.areas_for_improvement)
        ? parsed.areas_for_improvement
        : [],
      redFlags: Array.isArray(parsed.interview_probing_points)
        ? parsed.interview_probing_points
        : [],
    };
  } catch (error) {
    console.error('Chi tiết lỗi Gemini API:', error);

    // Xác định lỗi Rate Limit để đẩy ra cho BullMQ Worker xử lý
    const errorMessage = error.message || '';
    const errorStatus =
      error.status || (error.response && error.response.status);

    if (
      errorStatus === 429 ||
      errorMessage.includes('429') ||
      errorMessage.includes('RESOURCE_EXHAUSTED')
    ) {
      const rateLimitError = new Error('429_RATE_LIMIT');
      rateLimitError.status = 429;
      throw rateLimitError; // Worker sẽ bắt được lỗi này
    }

    throw new Error(
      'AI không thể phân tích CV do lỗi xử lý dữ liệu hoặc kết nối.',
    );
  }
};

module.exports = { analyzeCV };
