# TechNest - Nền tảng Thương mại Điện tử Thiết bị Điện tử

<div align="center">

### Ứng dụng thương mại điện tử toàn diện cho thiết bị điện tử với quản lý đa vai trò và tích hợp AI

<p>
<img src="https://img.shields.io/badge/Django-092E20?style=for-the-badge&logo=django&logoColor=white" alt="Django"/>
<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
<img src="https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white" alt="MySQL"/>
<img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"/>
</p>

</div>

---

## Tổng quan dự án

TechNest là một nền tảng thương mại điện tử được xây dựng đặc biệt cho ngành thiết bị điện tử, kết hợp giữa backend Django mạnh mẽ và frontend Flutter đa nền tảng. Hệ thống cung cấp trải nghiệm mua sắm toàn diện với quản lý đa vai trò, kiểm duyệt sản phẩm thông minh, và tích hợp AI để chống spam đánh giá giả mạo.

### Công nghệ sử dụng

<table>
<tr>
<td><strong>Backend</strong></td>
<td>Django, Django REST Framework, MySQL</td>
</tr>
<tr>
<td><strong>Frontend</strong></td>
<td>Flutter, Dart</td>
</tr>
<tr>
<td><strong>AI/ML</strong></td>
<td>PhoBERT (xử lý ngôn ngữ tự nhiên tiếng Việt)</td>
</tr>
<tr>
<td><strong>Thanh toán</strong></td>
<td>MoMo Payment Gateway</td>
</tr>
<tr>
<td><strong>Bản đồ</strong></td>
<td>Mapbox API</td>
</tr>
<tr>
<td><strong>Thông báo</strong></td>
<td>Firebase Cloud Messaging</td>
</tr>
<tr>
<td><strong>Lưu trữ</strong></td>
<td>Cloudinary</td>
</tr>
<tr>
<td><strong>Xác thực</strong></td>
<td>FPT eKYC API</td>
</tr>
</table>

---

## Tính năng chính

### Hệ thống đa vai trò người dùng

<table>
<thead>
<tr>
<th>Vai trò</th>
<th>Quyền hạn và Tính năng</th>
</tr>
</thead>
<tbody>
<tr>
<td><strong>Khách hàng</strong></td>
<td>
<ul>
<li>Đăng ký tài khoản và quản lý hồ sơ cá nhân</li>
<li>Tìm kiếm và duyệt sản phẩm điện tử</li>
<li>Thêm sản phẩm vào giỏ hàng và đặt hàng</li>
<li>Thanh toán qua cổng MoMo</li>
<li>Theo dõi trạng thái đơn hàng real-time</li>
<li>Nhận thông báo đẩy về đơn hàng qua Firebase</li>
<li>Đánh giá và nhận xét sản phẩm</li>
<li>Xem lịch sử đơn hàng</li>
</ul>
</td>
</tr>
<tr>
<td><strong>Nhà cung cấp</strong></td>
<td>
<ul>
<li>Đăng ký tài khoản nhà cung cấp</li>
<li>Xác minh danh tính qua CCCD với FPT eKYC API</li>
<li>Đăng tải và quản lý sản phẩm</li>
<li>Cập nhật thông tin sản phẩm (giá, mô tả, hình ảnh)</li>
<li>Xem báo cáo thống kê doanh thu theo tháng</li>
<li>Theo dõi số lượng sản phẩm đã bán</li>
<li>Quản lý tồn kho</li>
<li>Nhận thông báo về trạng thái kiểm duyệt sản phẩm</li>
</ul>
</td>
</tr>
<tr>
<td><strong>Người vận chuyển</strong></td>
<td>
<ul>
<li>Nhận đơn hàng cần giao</li>
<li>Cập nhật trạng thái đơn hàng (đang giao, đã giao)</li>
<li>Theo dõi lộ trình giao hàng qua Mapbox</li>
<li>Chụp hình xác minh khi giao hàng thành công</li>
<li>Xem lịch sử giao hàng</li>
<li>Nhận thông báo đơn hàng mới</li>
</ul>
</td>
</tr>
<tr>
<td><strong>Quản trị viên</strong></td>
<td>
<ul>
<li>Kiểm duyệt sản phẩm từ nhà cung cấp</li>
<li>Phê duyệt hoặc từ chối sản phẩm</li>
<li>Quản lý người dùng (khóa/mở tài khoản)</li>
<li>Xem báo cáo tổng quan hệ thống</li>
<li>Giám sát đánh giá spam qua mô hình AI</li>
<li>Quản lý danh mục sản phẩm</li>
<li>Xử lý khiếu nại và tranh chấp</li>
</ul>
</td>
</tr>
</tbody>
</table>

### Tính năng nổi bật

#### Chống spam đánh giá với PhoBERT
Hệ thống tích hợp mô hình PhoBERT để phát hiện và lọc các đánh giá giả mạo, spam, tạo sự tin cậy cho người mua hàng. Mô hình được huấn luyện trên dữ liệu tiếng Việt, có khả năng nhận diện các mẫu đánh giá không chân thực.

#### Xác thực nhà cung cấp
Nhà cung cấp bắt buộc phải xác minh danh tính thông qua CCCD sử dụng FPT eKYC API. Chỉ sau khi xác minh thành công, sản phẩm mới được gửi lên kiểm duyệt và mở bán trên sàn.

#### Theo dõi giao hàng real-time
Người vận chuyển có thể theo dõi lộ trình giao hàng tối ưu thông qua tích hợp Mapbox API, đảm bảo giao hàng nhanh chóng và chính xác.

#### Thông báo đẩy Firebase
Khách hàng nhận thông báo tức thì về trạng thái đơn hàng mà không cần mở ứng dụng, nâng cao trải nghiệm người dùng.

#### Báo cáo thống kê
Nhà cung cấp có thể xem báo cáo chi tiết về doanh thu, sản phẩm bán chạy theo từng tháng, giúp tối ưu hóa kinh doanh.

---

## Cài đặt và cấu hình

### Yêu cầu hệ thống

<ul>
<li>Python 3.8+</li>
<li>Flutter 3.0+</li>
<li>MySQL 8.0+</li>
</ul>

### Backend (Django)

#### Bước 1: Clone repository

```bash
git clone https://github.com/yourusername/technest.git](https://github.com/TinLaiLapTrinh/NestTech.git
```

#### Bước 2: Tạo môi trường ảo

```bash
python -m venv venv
source venv/bin/activate  # Trên Windows: venv\Scripts\activate
```

#### Bước 3: Cài đặt dependencies

```bash
pip install -r requirements.txt
```

#### Bước 4: Cấu hình file .env

Tạo file `.env` trong thư mục backend với nội dung sau:

```env
# OAuth2 Configuration
OAUTH2_CLIENT_ID=your_oauth2_client_id
OAUTH2_CLIENT_SECRET=your_oauth2_client_secret

# Cloudinary Configuration
CLOUDINARY_NAME=your_cloudinary_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret

# Google Maps API
GOOGLE_MAPS_API_KEY=your_google_maps_api_key

# Blockchain Configuration (nếu có)
RPC_URL=your_rpc_url
WALLET_ADDRESS=your_wallet_address
PRIVATE_KEY=your_private_key

# Akismet API (chống spam)
AKISMET_API_KEY_DEV=your_akismet_api_key
BLOG_URL_DEV=your_blog_url

# FPT eKYC API
FPT_API_KEY=your_fpt_api_key

# MoMo Payment Gateway
MOMO_ACCESS_KEY=your_momo_access_key
MOMO_SECRET_KEY=your_momo_secret_key

# CCCD Verification
CCCD_SECRET_KEY=your_cccd_secret_key

# Database Configuration
DB_NAME=technest_db
DB_USER=your_db_user
DB_PASSWORD=your_db_password
DB_HOST=localhost
DB_PORT=3306

# Firebase Configuration
FIREBASE_CREDENTIALS_PATH=path/to/firebase-credentials.json
```

#### Bước 5: Cấu hình MySQL

```bash
# Đăng nhập MySQL
mysql -u root -p

# Tạo database
CREATE DATABASE technest_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'your_db_user'@'localhost' IDENTIFIED BY 'your_db_password';
GRANT ALL PRIVILEGES ON technest_db.* TO 'your_db_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

#### Bước 6: Migration và tạo dữ liệu mẫu

```bash
python manage.py makemigrations
python manage.py migrate
python manage.py createsuperuser
```

#### Bước 7: Chạy server

```bash
python manage.py runserver
```

Backend sẽ chạy tại `http://localhost:8000`

### Frontend (Flutter)

#### Bước 1: Di chuyển vào thư mục frontend

```bash
cd ../frontend
```

#### Bước 2: Cài đặt dependencies

```bash
flutter pub get
```

#### Bước 3: Cấu hình API endpoint

Chỉnh sửa file `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:8000/api';
  static const String mapboxAccessToken = 'your_mapbox_token';
}
```

#### Bước 4: Cấu hình Firebase

Tải file `google-services.json` (Android) và `GoogleService-Info.plist` (iOS) từ Firebase Console và đặt vào đúng thư mục:

<ul>
<li>Android: <code>android/app/google-services.json</code></li>
<li>iOS: <code>ios/Runner/GoogleService-Info.plist</code></li>
</ul>

#### Bước 5: Chạy ứng dụng

```bash
flutter run
```

---

## Cấu trúc thư mục

### Backend (Django)

```
backend/
├── accounts/           # Quản lý người dùng, xác thực
├── admin_site/         # Giao diện quản trị
├── checkout/           # Xử lý đơn hàng, thanh toán
├── dataset/            # Dữ liệu huấn luyện PhoBERT
├── firebase/           # Tích hợp Firebase
├── locations/          # Quản lý địa chỉ, tracking
├── products/           # Quản lý sản phẩm
├── staticfiles/        # Static files
├── TechNest/           # Settings chính
├── templates/          # Templates HTML
├── train_model/        # Mô hình AI
├── utils/              # Utilities
├── vncorenlp/          # Xử lý ngôn ngữ tiếng Việt
├── manage.py
└── requirements.txt
```

### Frontend (Flutter)

```
frontend/
├── lib/
│   ├── core/           # Constants, utilities, themes
│   ├── features/       # Các tính năng chính
│   │   ├── auth/       # Đăng nhập, đăng ký
│   │   ├── checkout/   # Giỏ hàng, thanh toán
│   │   ├── location/   # Bản đồ, tracking
│   │   ├── product/    # Danh sách, chi tiết sản phẩm
│   │   ├── shared/     # Shared widgets
│   │   ├── stats/      # Thống kê
│   │   └── user/       # Quản lý người dùng
│   ├── screens/        # Các màn hình
│   │   ├── home_screen.dart
│   │   └── root_screen.dart
│   ├── services/       # API services
│   └── main.dart
├── assets/             # Images, fonts
├── android/
├── ios/
└── pubspec.yaml
```

---

## API Documentation

API documentation được xây dựng với Swagger/OpenAPI và có thể truy cập tại:

```
http://localhost:8000/api/docs/
```

### Các endpoint chính

<table>
<thead>
<tr>
<th>Endpoint</th>
<th>Method</th>
<th>Mô tả</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>/api/auth/register/</code></td>
<td>POST</td>
<td>Đăng ký tài khoản mới</td>
</tr>
<tr>
<td><code>/api/auth/login/</code></td>
<td>POST</td>
<td>Đăng nhập</td>
</tr>
<tr>
<td><code>/api/products/</code></td>
<td>GET</td>
<td>Lấy danh sách sản phẩm</td>
</tr>
<tr>
<td><code>/api/products/{id}/</code></td>
<td>GET</td>
<td>Chi tiết sản phẩm</td>
</tr>
<tr>
<td><code>/api/orders/</code></td>
<td>POST</td>
<td>Tạo đơn hàng</td>
</tr>
<tr>
<td><code>/api/orders/{id}/</code></td>
<td>GET</td>
<td>Chi tiết đơn hàng</td>
</tr>
<tr>
<td><code>/api/payment/momo/</code></td>
<td>POST</td>
<td>Thanh toán MoMo</td>
</tr>
<tr>
<td><code>/api/reviews/</code></td>
<td>POST</td>
<td>Đánh giá sản phẩm</td>
</tr>
<tr>
<td><code>/api/verify/cccd/</code></td>
<td>POST</td>
<td>Xác minh CCCD</td>
</tr>
<tr>
<td><code>/api/tracking/{order_id}/</code></td>
<td>GET</td>
<td>Theo dõi đơn hàng</td>
</tr>
</tbody>
</table>

---

## Mô hình AI - PhoBERT

Hệ thống sử dụng mô hình PhoBERT để phát hiện đánh giá spam. Mô hình được huấn luyện trên dataset tiếng Việt và có khả năng phân loại các đánh giá thành:

<ul>
<li><strong>Chân thực:</strong> Đánh giá từ người dùng thật</li>
<li><strong>Spam:</strong> Đánh giá giả mạo, không chân thực</li>
</ul>

### Huấn luyện mô hình

```bash
cd backend
python train_model/train_phobert.py
```

### Độ chính xác

Mô hình đạt độ chính xác trên 90% trên tập validation.

## License

Dự án được phát hành dưới giấy phép MIT. Xem file `LICENSE` để biết thêm chi tiết.

---

## Liên hệ

<ul>
<li><strong>Email:</strong> support@technest.vn</li>
<li><strong>Website:</strong> https://technest.vn</li>
<li><strong>GitHub:</strong> https://github.com/yourusername/technest</li>
</ul>

---

<div align="center">

### Được phát triển với ❤️ bởi TÔI

<p>Nếu dự án hữu ích, hãy cho tôi một ⭐ trên GitHub!</p>

</div>
