# Design Brief — gửi cho Claude

Copy toàn bộ từ `---` trở xuống, dán vào một phiên Claude mới.
Gợi ý mở đầu bằng `/design` để nhận về canvas nhiều artboard sửa trực tiếp được.

**Trước khi dán, phải điền mục 2 (Wedge).** Bỏ trống là nhận về thiết kế chung chung.

---

Bạn là design lead. Thiết kế giao diện cho một ứng dụng mobile phục hồi và tăng
chất lượng ảnh bằng AI. Đọc hết brief rồi mới vẽ.

## 1. Bối cảnh

Ứng dụng có đúng một vòng lặp: chọn ảnh → chờ AI xử lý → xem trước/sau → lưu.
Không có feed, không có editor, không có thư viện hiệu ứng. Toàn bộ giá trị nằm
ở khoảnh khắc người dùng nhìn thấy ảnh của họ tốt lên.

Backend, luồng nghiệp vụ và app Flutter đã dựng xong. Việc của bạn là thiết kế
lại phần nhìn và luồng tương tác, không phải đề xuất tính năng mới.

## 2. Wedge — điền trước khi bắt đầu

Thiết kế phải phục vụ MỘT nhóm người dùng. Chọn một:

- [ ] **Phục hồi ảnh cũ** — ảnh gia đình ố, xước, mờ. Người dùng lớn tuổi hơn,
      chạm vào cảm xúc, sẵn sàng trả tiền cho một tấm ảnh duy nhất.
- [ ] **Làm nét ảnh chân dung** — selfie, ảnh chụp thiếu sáng. Người dùng trẻ,
      dùng nhiều lần, nhạy giá.

Hai nhóm này cần hai thiết kế khác nhau về giọng điệu, cỡ chữ, mật độ thông tin
và ảnh minh hoạ. Nếu tôi chưa đánh dấu, hãy hỏi lại trước khi vẽ.

## 3. Ràng buộc bắt buộc

Đây là các quyết định đã chốt. Thiết kế phải nằm trong khuôn này, không đề xuất
thay đổi.

| Ràng buộc | Giá trị |
|---|---|
| Đăng nhập | **Không có màn hình đăng nhập.** Mở app là dùng được ngay. |
| Lượt miễn phí | **1 ảnh**, đầy đủ độ phân giải, trước bất kỳ rào cản nào |
| Paywall | Chỉ xuất hiện **sau khi** người dùng đã thấy kết quả đầu tiên |
| Gói | **Một** sản phẩm duy nhất: gói tuần, dùng thử 3 ngày. Không nhiều bậc, không credit, không token. |
| Thời gian xử lý | 10–20 giây điển hình, tối đa 90 giây |
| Ngôn ngữ | Tiếng Việt |
| Chế độ màu | **Chỉ dark.** Nền tối để ảnh nổi lên. Không cần bản light. |
| Số màn hình | Đúng 5 màn hình dưới đây. Không thêm. |

## 4. Năm màn hình

Mỗi màn hình có đúng một nhiệm vụ. Nếu một thành phần không phục vụ nhiệm vụ đó,
bỏ nó đi.

### 4.1 Home
**Nhiệm vụ:** đưa người dùng tới nút chọn ảnh trong dưới 2 giây.

Bắt buộc: một dòng tiêu đề nói rõ app làm gì · nút chính "Chọn ảnh" nằm trong
tầm ngón cái · lối phụ để chụp ảnh mới · dòng nhỏ báo còn bao nhiêu lượt miễn phí.

Cấm: dashboard, lưới chế độ AI, thanh điều hướng dưới, carousel giới thiệu,
onboarding nhiều bước.

### 4.2 Processing
**Nhiệm vụ:** giữ người dùng ở lại trong 10–90 giây mà không sốt ruột.

Bắt buộc: hiển thị chính tấm ảnh họ vừa chọn (đây là thứ neo sự chú ý) · trạng
thái bằng chữ thay đổi theo tiến trình, không phải spinner đứng yên · lối huỷ.

Lưu ý: hệ thống không biết chính xác còn bao lâu. Đừng thiết kế thanh phần trăm
giả. Nếu bạn muốn có cảm giác tiến triển, hãy đề xuất cách trung thực.

### 4.3 Result — màn hình quan trọng nhất
**Nhiệm vụ:** trong 3 giây, người dùng phải tự trả lời được "AI đã cải thiện cái gì?"

Bắt buộc: so sánh trước/sau bằng thanh kéo dọc, hai ảnh cùng khung crop · nhãn
TRƯỚC / SAU · nút "Lưu ảnh" là hành động chính · chia sẻ là hành động phụ.

Đây là màn hình đáng đầu tư nhất. Nếu phải chọn nơi để làm đẹp hơn mức cần
thiết, chọn màn hình này.

### 4.4 Paywall
**Nhiệm vụ:** chuyển đổi ngay sau khoảnh khắc người dùng vừa thấy giá trị.

Bắt buộc: một sản phẩm duy nhất · nói rõ "3 ngày miễn phí, sau đó tính phí theo
tuần" · nút đóng thấy được ngay, không ẩn, không đếm ngược.

Cấm: bảng so sánh nhiều gói, giá gạch ngang giả, đồng hồ đếm ngược, nút đóng mờ
nhạt. Những thứ này làm tăng conversion ngắn hạn và tăng refund lẫn đánh giá 1 sao.

### 4.5 Lỗi
**Nhiệm vụ:** nói thật chuyện gì xảy ra và mời thử lại.

Bắt buộc: câu "Lượt của bạn chưa bị trừ" phải nổi bật — đây là điều người dùng
lo nhất · nút "Thử lại" · lối chọn ảnh khác.

## 5. Lấy gì từ Remini

Lấy **cơ chế**, những thứ giải thích được vì sao chúng hiệu quả:

- Nút chọn ảnh là hành động đầu tiên và gần như duy nhất trên màn hình đầu
- Ảnh gốc hiện suốt lúc chờ, tạo cảm giác "nó đang làm việc trên ảnh CỦA TÔI"
- Trước/sau là khoảnh khắc cao trào, được cho toàn bộ màn hình
- Paywall đặt ngay sau cao trào đó, không phải lúc mở app
- Nền tối để ảnh người dùng là thứ sáng nhất trên màn hình
- Nút chính to, đặt thấp, chạm được bằng một tay

## 6. Không lấy gì

Không sao chép nhận diện của Remini hoặc bất kỳ app nào đang có trên store:

- Bảng màu, gradient, phong cách icon, kiểu chữ đặc trưng của họ
- Bố cục icon ứng dụng và ảnh chụp màn hình trên store
- Tên, khẩu hiệu, cách đặt tên tính năng
- Ảnh minh hoạ và ảnh mẫu của họ

Lý do không chỉ là pháp lý: sao chép nhận diện thì sản phẩm không có gì để người
dùng nhớ, và toàn bộ khác biệt lại rơi vào giá — cuộc đua duy nhất chắc chắn thua.

## 7. Hướng thị giác

Không có brand có sẵn, bạn tự đề xuất. Yêu cầu:

- Nền tối, nhưng chọn một sắc độ cụ thể chứ không phải đen thuần
- Một màu nhấn duy nhất, dùng cho nút chính và không dùng cho gì khác
- Kiểu chữ hỗ trợ đầy đủ dấu tiếng Việt — kiểm tra trước khi dùng
- Ảnh minh hoạ phải là ảnh thật có khiếm khuyết thật, không phải ảnh stock hoàn hảo

Nếu wedge là ảnh cũ: chữ lớn hơn, tương phản cao hơn, giọng ấm.
Nếu wedge là chân dung: gọn hơn, nhanh hơn, hiện đại hơn.

## 8. Đầu ra

- 5 artboard tỉ lệ iPhone (390 × 844)
- Mỗi artboard kèm một dòng ghi rõ nhiệm vụ của nó
- Bảng token: màu, cỡ chữ, khoảng cách, bo góc
- Nói rõ những chỗ bạn cố ý làm khác brief và vì sao

## 9. Hỏi lại trước khi vẽ

Nếu mục 2 chưa được điền, hoặc có ràng buộc nào ở mục 3 khiến thiết kế tốt trở
nên bất khả thi, hỏi trước. Đừng đoán.
