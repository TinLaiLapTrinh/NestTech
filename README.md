<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>E-Commerce Electronics Platform - README</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Helvetica', 'Arial', sans-serif;
            line-height: 1.6;
            color: #24292e;
            background: #f6f8fa;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 40px;
            border-radius: 6px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.12);
        }
        h1 {
            font-size: 2em;
            color: #24292e;
            border-bottom: 1px solid #e1e4e8;
            padding-bottom: 10px;
            margin-bottom: 20px;
        }
        h2 {
            font-size: 1.5em;
            color: #24292e;
            margin-top: 40px;
            margin-bottom: 16px;
            padding-bottom: 8px;
            border-bottom: 1px solid #e1e4e8;
        }
        h3 {
            font-size: 1.25em;
            color: #24292e;
            margin-top: 24px;
            margin-bottom: 12px;
        }
        h4 {
            font-size: 1em;
            color: #24292e;
            margin-top: 16px;
            margin-bottom: 8px;
        }
        p {
            margin-bottom: 16px;
        }
        .badge {
            display: inline-block;
            padding: 3px 10px;
            font-size: 12px;
            font-weight: 600;
            border-radius: 3px;
            margin-right: 5px;
        }
        .badge-blue {
            background: #0969da;
            color: white;
        }
        .badge-green {
            background: #1a7f37;
            color: white;
        }
        .badge-orange {
            background: #fb8500;
            color: white;
        }
        .tech-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 16px;
            margin: 20px 0;
        }
        .tech-card {
            background: #f6f8fa;
            border: 1px solid #d0d7de;
            border-radius: 6px;
            padding: 16px;
        }
        .tech-card h4 {
            color: #0969da;
            margin-top: 0;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            background: white;
            border: 1px solid #d0d7de;
            position: relative;
        }
        .table-wrapper {
            position: relative;
            margin: 20px 0;
        }
        .copy-btn {
            position: absolute;
            top: 10px;
            right: 10px;
            background: #0969da;
            color: white;
            border: none;
            padding: 6px 12px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 12px;
            font-weight: 500;
            transition: background 0.2s;
        }
        .copy-btn:hover {
            background: #0860ca;
        }
        .copy-btn.copied {
            background: #1a7f37;
        }
        th {
            background: #f6f8fa;
            color: #24292e;
            font-weight: 600;
            text-align: left;
            padding: 12px;
            border: 1px solid #d0d7de;
        }
        td {
            padding: 12px;
            border: 1px solid #d0d7de;
        }
        tr:hover {
            background: #f6f8fa;
        }
        .code-block {
            background: #f6f8fa;
            border: 1px solid #d0d7de;
            border-radius: 6px;
            padding: 16px;
            overflow-x: auto;
            margin: 16px 0;
            position: relative;
        }
        .code-block pre {
            margin: 0;
            font-family: 'SFMono-Regular', 'Consolas', 'Liberation Mono', 'Menlo', monospace;
            font-size: 13px;
            color: #24292e;
        }
        .env-block {
            background: #161b22;
            color: #c9d1d9;
            border-radius: 6px;
            padding: 16px;
            margin: 16px 0;
            position: relative;
        }
        .env-block pre {
            margin: 0;
            font-family: 'SFMono-Regular', 'Consolas', monospace;
            font-size: 13px;
            line-height: 1.5;
        }
        .env-comment {
            color: #8b949e;
        }
        .env-key {
            color: #79c0ff;
        }
        .env-value {
            color: #a5d6ff;
        }
        ul {
            margin: 16px 0;
            padding-left: 32px;
        }
        li {
            margin: 8px 0;
        }
        .feature-section {
            background: #f6f8fa;
            border-left: 3px solid #0969da;
            padding: 16px;
            margin: 16px 0;
            border-radius: 0 6px 6px 0;
        }
        .alert {
            padding: 16px;
            border-radius: 6px;
            margin: 16px 0;
            border-left: 4px solid;
        }
        .alert-info {
            background: #ddf4ff;
            border-color: #0969da;
            color: #0550ae;
        }
        .alert-warning {
            background: #fff8c5;
            border-color: #bf8700;
            color: #7d4e00;
        }
        strong {
            font-weight: 600;
            color: #24292e;
        }
        code {
            background: #f6f8fa;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'SFMono-Regular', 'Consolas', monospace;
            font-size: 85%;
        }
        .install-steps {
            counter-reset: step-counter;
        }
        .install-steps h4 {
            counter-increment: step-counter;
            position: relative;
            padding-left: 40px;
        }
        .install-steps h4::before {
            content: counter(step-counter);
            position: absolute;
            left: 0;
            top: 0;
            background: #0969da;
            color: white;
            width: 28px;
            height: 28px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 14px;
            font-weight: 600;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Nền Tảng Thương Mại Điện Tử - Thiết Bị Điện Tử</h1>
        
        <p>
            <span class="badge badge-blue">Django</span>
            <span class="badge badge-blue">Flutter</span>
            <span class="badge badge-green">MySQL</span>
            <span class="badge badge-orange">PhoBERT</span>
        </p>

        <h2>Giới Thiệu</h2>
        <p>Ứng dụng thương mại điện tử chuyên về thiết bị điện tử được phát triển với kiến trúc hiện đại, kết hợp <strong>Django</strong> cho backend và <strong>Flutter</strong> cho frontend. Hệ thống được thiết kế để phục vụ ba vai trò người dùng chính với đầy đủ tính năng quản lý, thanh toán và giao hàng.</p>

        <h2>Công Nghệ Sử Dụng</h2>
        <div class="tech-grid">
            <div class="tech-card">
                <h4>Backend</h4>
                <p><strong>Django Framework</strong></p>
                <p>Python-based web framework mạnh mẽ, hỗ trợ ORM và RESTful API</p>
            </div>
            <div class="tech-card">
                <h4>Frontend</h4>
                <p><strong>Flutter</strong></p>
                <p>Cross-platform framework để phát triển ứng dụng di động iOS và Android</p>
            </div>
            <div class="tech-card">
                <h4>Database</h4>
                <p><strong>MySQL Server</strong></p>
                <p>Hệ quản trị cơ sở dữ liệu quan hệ tin cậy và hiệu suất cao</p>
            </div>
            <div class="tech-card">
                <h4>AI/ML</h4>
                <p><strong>PhoBERT</strong></p>
                <p>Mô hình xử lý ngôn ngữ tự nhiên tiếng Việt cho phát hiện spam</p>
            </div>
        </div>

        <h2>Phân Quyền Người Dùng</h2>
        <div class="table-wrapper">
            <button class="copy-btn" onclick="copyTable('userRolesTable')">Copy Table</button>
            <table id="userRolesTable">
                <thead>
                    <tr>
                        <th>Vai Trò</th>
                        <th>Quyền Hạn</th>
                        <th>Chức Năng Chính</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Khách Hàng</strong></td>
                        <td>Mua sắm, đánh giá sản phẩm</td>
                        <td>
                            • Đặt hàng sản phẩm<br>
                            • Thanh toán qua MoMo<br>
                            • Xem trạng thái đơn hàng<br>
                            • Đánh giá và nhận xét sản phẩm<br>
                            • Nhận thông báo đẩy về đơn hàng
                        </td>
                    </tr>
                    <tr>
                        <td><strong>Nhà Cung Cấp</strong></td>
                        <td>Quản lý sản phẩm, xem báo cáo</td>
                        <td>
                            • Đăng ký tài khoản và xác thực CCCD<br>
                            • Đăng tải sản phẩm lên hệ thống<br>
                            • Chờ kiểm duyệt từ quản trị viên<br>
                            • Xem báo cáo doanh thu theo tháng<br>
                            • Thống kê sản phẩm đã bán
                        </td>
                    </tr>
                    <tr>
                        <td><strong>Người Vận Chuyển</strong></td>
                        <td>Giao hàng, cập nhật trạng thái</td>
                        <td>
                            • Nhận đơn hàng từ hệ thống<br>
                            • Cập nhật trạng thái giao hàng<br>
                            • Chụp hình xác minh khi giao thành công<br>
                            • Theo dõi lộ trình qua MapBox<br>
                            • Nhận thông báo đơn hàng mới
                        </td>
                    </tr>
                    <tr>
                        <td><strong>Quản Trị Viên</strong></td>
                        <td>Quản lý toàn bộ hệ thống</td>
                        <td>
                            • Kiểm duyệt sản phẩm<br>
                            • Quản lý người dùng<br>
                            • Xem báo cáo tổng quan<br>
                            • Xử lý khiếu nại
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <h2>Tính Năng Chi Tiết</h2>

        <div class="feature-section">
            <h3>Quản Lý Người Dùng & Xác Thực</h3>
            <ul>
                <li>Đăng ký và đăng nhập với phân quyền theo vai trò</li>
                <li>Xác thực nhà cung cấp bằng CCCD qua FPT AI API</li>
                <li>Đăng nhập bằng OAuth2 (Google)</li>
                <li>Quản lý thông tin cá nhân</li>
            </ul>
        </div>

        <div class="feature-section">
            <h3>Dành Cho Nhà Cung Cấp</h3>
            <ul>
                <li>Đăng tải sản phẩm với hình ảnh (Cloudinary)</li>
                <li>Chờ kiểm duyệt từ quản trị viên</li>
                <li>Xem báo cáo doanh thu theo từng tháng</li>
                <li>Thống kê số lượng sản phẩm đã bán</li>
                <li>Quản lý kho hàng</li>
            </ul>
        </div>

        <div class="feature-section">
            <h3>Dành Cho Khách Hàng</h3>
            <ul>
                <li>Tìm kiếm và duyệt sản phẩm</li>
                <li>Đặt hàng và thanh toán qua cổng MoMo</li>
                <li>Theo dõi trạng thái đơn hàng real-time</li>
                <li>Nhận thông báo đẩy qua Firebase</li>
                <li>Đánh giá và nhận xét sản phẩm</li>
                <li>Xem lịch sử mua hàng</li>
            </ul>
        </div>

        <div class="feature-section">
            <h3>Dành Cho Người Vận Chuyển</h3>
            <ul>
                <li>Nhận đơn hàng mới từ hệ thống</li>
                <li>Cập nhật trạng thái giao hàng</li>
                <li>Chụp hình xác minh khi giao thành công</li>
                <li>Theo dõi lộ trình giao hàng qua MapBox</li>
                <li>Lịch sử giao hàng</li>
            </ul>
        </div>

        <div class="feature-section">
            <h3>Chống Spam & Bảo Mật</h3>
            <ul>
                <li><strong>PhoBERT Model:</strong> Phát hiện đánh giá giả mạo</li>
                <li><strong>NLP Processing:</strong> Xử lý ngôn ngữ tự nhiên tiếng Việt</li>
                <li><strong>Akismet:</strong> Bảo vệ chống spam</li>
                <li><strong>FPT AI API:</strong> Xác thực CCCD cho nhà cung cấp</li>
            </ul>
        </div>

        <h2>Cài Đặt</h2>

        <div class="alert alert-info">
            <strong>Yêu cầu hệ thống:</strong> Python 3.8+, MySQL Server 8.0+, Flutter 3.0+
        </div>

        <h3>Cài Đặt Backend (Django)</h3>
        <div class="install-steps">
            <h4>Clone Repository</h4>
            <div class="code-block">
                <button class="copy-btn" onclick="copyCode(this)">Copy</button>
                <pre>git clone https://github.com/yourusername/ecommerce-electronics.git
cd ecommerce-electronics/backend</pre>
            </div>

            <h4>Tạo Virtual Environment</h4>
            <div class="code-block">
                <button class="copy-btn" onclick="copyCode(this)">Copy</button>
                <pre>python -m venv venv</pre>
            </div>

            <h4>Kích Hoạt Virtual Environment</h4>
            <div class="code-block">
                <button class="copy-btn" onclick="copyCode(this)">Copy</button>
                <pre># Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate</pre>
            </div>

            <h4>Cài Đặt Dependencies</h4>
            <div class="code-block">
                <button class="copy-btn" onclick="copyCode(this)">Copy</button>
                <pre>pip install -r requirements.txt</pre>
            </div>

            <h4>Cấu Hình File .env</h4>
            <p>Tạo file <code>.env</code> trong thư mục backend với nội dung sau:</p>
            <div class="env-block">
                <button class="copy-btn" onclick="copyCode(this)">Copy</button>
                <pre><span class="env-comment"># OAuth2 Configuration</span>
<span class="env-key">OAUTH2_CLIENT_ID</span>=<span class="env-value">your_google_client_id</span>
<span class="env-key">OAUTH2_CLIENT_SECRET</span>=<span class="env-value">your_google_client_secret</span>

<span class="env-comment"># Cloudinary Configuration</span>
<span class="env-key">CLOUDINARY_NAME</span>=<span class="env-value">your_cloudinary_name</span>
<span class="env-key">CLOUDINARY_API_KEY</span>=<span class="env-value">your_cloudinary_api_key</span>
<span class="env-key">CLOUDINARY_API_SECRET</span>=<span class="env-value">your_cloudinary_api_secret</span>

<span class="env-comment"># Google Maps API</span>
<span class="env-key">GOOGLE_MAPS_API_KEY</span>=<span class="env-value">your_google_maps_api_key</span>

<span class="env-comment"># Blockchain Configuration</span>
<span class="env-key">RPC_URL</span>=<span class="env-value">your_rpc_url</span>
<span class="env-key">WALLET_ADDRESS</span>=<span class="env-value">your_wallet_address</span>
<span class="env-key">PRIVATE_KEY</span>=<span class="env-value">your_private_key</span>

<span class="env-comment"># Akismet Anti-Spam</span>
<span class="env-key">AKISMET_API_KEY_DEV</span>=<span class="env-value">your_akismet_api_key</span>
<span class="env-key">BLOG_URL_DEV</span>=<span class="env-value">your_blog_url</span>

<span class="env-comment"># FPT AI API (CCCD Verification)</span>
<span class="env-key">FPT_API_KEY</span>=<span class="env-value">your_fpt_api_key</span>

<span class="env-comment"># MoMo Payment Gateway</span>
<span class="env-key">MOMO_ACCESS_KEY</span>=<span class="env-value">your_momo_access_key</span>
<span class="env-key">MOMO_SECRET_KEY</span>=<span class="env-value">your_momo_secret_key</span>

<span class="env-comment"># CCCD Verification</span>
<span class="env-key">CCCD_SECRET_KEY</span>=<span class="env-value">your_cccd_secret_key</span></pre>
            </div>

            <h4>Thiết Lập Database</h4>
            <div class="code-block">
                <button class="copy-btn" onclick="copyCode(this)">Copy</button>
                <pre># Tạo database MySQL
mysql -u root -p
CREATE DATABASE ecommerce_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EXIT;

# Chạy migrations
python manage.py makemigrations
python manage.py migrate</pre>
            </div>

            <h4>Tạo Superuser</h4>
            <div class="code-block">
                <button class="copy-btn" onclick="copyCode(this)">Copy</button>
                <pre>python manage.py createsuperuser</pre>
            </div>

            <h4>Chạy Server</h4>
            <div class="code-block">
                <button class="copy-btn" onclick="copyCode(this)">Copy</button>
                <pre>python manage.py runserver</pre>
            </div>
            <p>Server sẽ chạy tại: <code>http://localhost:8000</code></p>
        </div>

        <h3>Cài Đặt Frontend (Flutter)</h3>
        <div class="install-steps">
            <h4>Di Chuyển Đến Thư Mục Frontend</h4>
            <div class="code-block">
                <button class="copy-btn" onclick="copyCode(this)">Copy</button>
                <pre>cd ../frontend</pre>
            </div>

            <h4>Cài Đặt Dependencies</h4>
            <div class="code-block">
                <button class="copy-btn" onclick="copyCode(this)">Copy</button>
                <pre>flutter pub get</pre>
            </div>

            <h4>Cấu Hình Firebase</h4>
            <ul>
                <li>Thêm file <code>google-services.json</code> vào <code>android/app/</code></li>
                <li>Thêm file <code>GoogleService-Info.plist</code> vào <code>ios/Runner/</code></li>
            </ul>

            <h4>Chạy Ứng Dụng</h4>
            <div class="code-block">
                <button class="copy-btn" onclick="copyCode(this)">Copy</button>
                <pre>flutter run</pre>
            </div>
        </div>

        <h2>API Endpoints Chính</h2>
        <div class="table-wrapper">
            <button class="copy-btn" onclick="copyTable('apiTable')">Copy Table</button>
            <table id="apiTable">
                <thead>
                    <tr>
                        <th>Method</th>
                        <th>Endpoint</th>
                        <th>Mô Tả</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td><code>POST</code></td>
                        <td><code>/api/auth/register/</code></td>
                        <td>Đăng ký tài khoản</td>
                    </tr>
                    <tr>
                        <td><code>POST</code></td>
                        <td><code>/api/auth/login/</code></td>
                        <td>Đăng nhập</td>
                    </tr>
                    <tr>
                        <td><code>POST</code></td>
                        <td><code>/api/auth/verify-cccd/</code></td>
                        <td>Xác thực CCCD</td>
                    </tr>
                    <tr>
                        <td><code>GET</code></td>
                        <td><code>/api/products/</code></td>
                        <td>Danh sách sản phẩm</td>
                    </tr>
                    <tr>
                        <td><code>POST</code></td>
                        <td><code>/api/products/</code></td>
                        <td>Tạo sản phẩm mới</td>
                    </tr>
                    <tr>
                        <td><code>GET</code></td>
                        <td><code>/api/orders/</code></td>
                        <td>Danh sách đơn hàng</td>
                    </tr>
                    <tr>
                        <td><code>POST</code></td>
                        <td><code>/api/orders/</code></td>
                        <td>Tạo đơn hàng mới</td>
                    </tr>
                    <tr>
                        <td><code>PATCH</code></td>
                        <td><code>/api/orders/{id}/status/</code></td>
                        <td>Cập nhật trạng thái đơn hàng</td>
                    </tr>
                    <tr>
                        <td><code>POST</code></td>
                        <td><code>/api/payments/momo/create/</code></td>
                        <td>Tạo thanh toán MoMo</td>
                    </tr>
                    <tr>
                        <td><code>POST</code></td>
                        <td><code>/api/reviews/</code></td>
                        <td>Tạo đánh giá mới</td>
                    </tr>
                    <tr>
                        <td><code>POST</code></td>
                        <td><code>/api/reviews/check-spam/</code></td>
                        <td>Kiểm tra spam</td>
                    </tr>
                    <tr>
                        <td><code>GET</code></td>
                        <td><code>/api/reports/revenue/</code></td>
                        <td>Báo cáo doanh thu</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <h2>Cấu Trúc Thư Mục</h2>
        <div class="code-block">
            <button class="copy-btn" onclick="copyCode(this)">Copy</button>
            <pre>ecommerce-electronics/
├── backend/
│   ├── manage.py
│   ├── requirements.txt
│   ├── .env
│   ├── config/
│   │   ├── settings.py
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── apps/
│   │   ├── users/
│   │   ├── products/
│   │   ├── orders/
│   │   ├── payments/
│   │   ├── reviews/
│   │   └── notifications/
│   └── ml_models/
│       └── phobert_spam_detection/
├── frontend/
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/
│   │   ├── models/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── services/
│   ├── android/
│   └── ios/
└── README.md</pre>
        </div>

        <h2>Bảo Mật</h2>
        <ul>
            <li>Mã hóa password bằng bcrypt</li>
            <li>JWT tokens cho authentication</li>
            <li>HTTPS/SSL cho production</li>
            <li>Rate limiting cho API</li>
            <li>CORS configuration</li>
            <li>SQL injection protection</li>
            <li>XSS protection</li>
            <li>CSRF protection</li>
        </ul>

        <div class="alert alert-warning">
            <strong>Lưu ý quan trọng:</strong>
            <ul style="margin: 8px 0 0 0;">
                <li>Không commit file <code>.env</code> lên repository</li>
                <li>Backup database thường xuyên</li>
                <li>Cập nhật dependencies định kỳ</li>
                <li>Kiểm tra logs thường xuyên</li>
            </ul>
        </div>

        <h2>License</h2>
        <p>This project is licensed under the MIT License</p>

        <h2>Liên Hệ</h2>
        <ul>
            <li>Email: support@ecommerce.com</li>
            <li>Website: https://ecommerce.com</li>
            <li>GitHub: https://github.com/yourusername/ecommerce-electronics</li>
        </ul>
    </div>

    <script>
        function copyTable(tableId) {
            const table = document.getElementById(tableId);
            const button = event.target;
            
            // Tạo markdown format cho table
            let markdown = '';
            const rows = table.querySelectorAll('tr');
            
            rows.forEach((row, index) => {
                const cells = row.querySelectorAll('th, td');
                let rowText = '| ';
                
                cells.forEach(cell => {
                    // Thay thế <br> bằng dấu ngăn cách
                    let text = cell.innerHTML.replace(/<br>/g, ', ');
                    // Loại bỏ các thẻ HTML khác
                    text = text.replace(/<[^>]*>/g, '');
                    // Loại bỏ ký tự đặc biệt
                    text = text.replace(/•/g, '-');
                    rowText += text.trim() + ' | ';
                });
                
                markdown += rowText + '\n';
                
                // Thêm separator sau header
                if (index === 0) {
                    let separator = '| ';
                    cells.forEach(() => {
                        separator += '--- | ';
                    });
                    markdown += separator + '\n';
                }
            });
            
            // Copy to clipboard
            navigator.clipboard.writeText(markdown).then(() => {
                button.textContent = 'Copied!';
                button.classList.add('copied');
                setTimeout(() => {
                    button.textContent = 'Copy Table';
                    button.classList.remove('copied');
                }, 2000);
            });
        }

        function copyCode(button) {
            const codeBlock = button.parentElement;
            const pre = codeBlock.querySelector('pre');
            const text = pre.textContent;
            
            navigator.clipboard.writeText(text).then(() => {
                button.textContent = 'Copied!';
                button.classList.add('copied');
                setTimeout(() => {
                    button.textContent = 'Copy';
                    button.classList.remove('copied');
                }, 2000);
            });
        }
    </script>
</body>
</html>
