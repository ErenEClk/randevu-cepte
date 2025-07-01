# 💇‍♂️ Randevu Cepte - Appointment Booking App

Modern, kullanıcı dostu bir randevu booking uygulaması. Kuaför, berber, güzellik salonu ve diğer hizmet sağlayıcıları için geliştirilmiştir.

## 🚀 Özellikler

### ✅ **V1.0 - Mevcut Özellikler**

#### 🏪 **İşletme Yönetimi**
- **Salon Profil Yönetimi**: İşletme bilgileri, açıklama, kategori
- **Çalışma Saatleri**: Esnek çalışma saati planlaması
- **Hizmet Yönetimi**: Hizmet tanımlama, fiyatlandırma, süre ayarlama
- **Fotoğraf Galerisi**: Firebase Storage ile çoklu fotoğraf yükleme
- **Lokasyon Servisleri**: GPS ile otomatik adres belirleme

#### 📅 **Randevu Sistemi**
- **Comprehensive Appointment Management**: Randevu oluşturma, onaylama, iptal etme
- **Real-time Status Tracking**: Pending, confirmed, cancelled, completed durumları
- **Çakışma Kontrolü**: Otomatik time slot validation
- **İstatistikler**: Randevu analitikleri ve raporlama

#### 💬 **Mesajlaşma Sistemi**
- **Real-time Chat**: İşletme-müşteri mesajlaşma
- **Mesaj Türleri**: Text, fotoğraf, randevu mesajları
- **Okunmamış Sayacı**: Bildirim sistemi
- **Demo Chat**: Test için otomatik demo chat oluşturma

#### 🔐 **Authentication & Security**
- **Firebase Authentication**: Email/password ve Google Sign-In
- **Anonymous Testing**: Test kullanıcıları için anonymous auth
- **User Type Management**: Business/Customer ayrımı
- **Secure Storage Rules**: Firebase güvenlik kuralları

## 🛠️ **Teknik Stack**

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase
  - Authentication
  - Firestore Database
  - Storage
  - Cloud Functions (ready)
- **Maps**: Google Maps API
- **Notifications**: Firebase Messaging (ready)

## 📱 **Kurulum**

### Gereksinimler
- Flutter SDK (>=3.7.0)
- Android Studio / VS Code
- Firebase Project
- Google Maps API Key

### Adımlar

1. **Projeyi klonlayın**
```bash
git clone https://github.com/[username]/randevu_cepte.git
cd randevu_cepte
```

2. **Dependencies yükleyin**
```bash
flutter pub get
```

3. **Firebase Setup**
```bash
firebase init
# Firestore, Storage, Authentication aktif edin
firebase deploy --only firestore:rules,storage
```

4. **Google Maps API Key**
- `android/app/src/main/AndroidManifest.xml` dosyasındaki API key'i güncelleyin

5. **Uygulamayı çalıştırın**
```bash
flutter run
```

## 🧪 **Test Kullanıcıları**

### İşletme Hesabı
- **Email**: `kuafor@test.com`
- **Password**: `123456`

### Müşteri Hesabı  
- **Email**: `musteri@test.com`
- **Password**: `123456`

## 📂 **Proje Yapısı**

```
lib/
├── constants/          # App colors, themes
├── models/            # Data models (User, Salon, Appointment, Chat)
├── services/          # Firebase services, business logic
├── screens/           # UI screens
│   ├── auth/         # Login, register, user type selection
│   ├── business/     # Business management screens
│   ├── appointments/ # Appointment management
│   ├── chat/         # Messaging screens
│   └── home/         # Main dashboard screens
├── widgets/           # Reusable UI components
└── utils/            # Helper functions
```

## 🎯 **Roadmap - Sonraki Özellikler**

### 🎨 **V1.1 - UI/UX İyileştirmeleri**
- [ ] Modern Material Design 3
- [ ] Consistent color scheme
- [ ] Better typography
- [ ] Smooth animations
- [ ] Dark mode support

### 🔔 **V1.2 - Notifications**
- [ ] Push notifications
- [ ] Email notifications
- [ ] SMS reminders
- [ ] In-app notifications

### 💳 **V1.3 - Payment Integration**
- [ ] Stripe integration
- [ ] PayPal support
- [ ] Credit card payments
- [ ] Wallet system

### ⭐ **V1.4 - Review System**
- [ ] Customer reviews
- [ ] Rating system
- [ ] Photo reviews
- [ ] Business responses

### 📊 **V1.5 - Advanced Analytics**
- [ ] Revenue tracking
- [ ] Customer insights
- [ ] Popular services
- [ ] Time-based analytics

### 👥 **V2.0 - Customer App**
- [ ] Dedicated customer mobile app
- [ ] Service discovery
- [ ] Advanced search & filters
- [ ] Loyalty programs

## 🐛 **Bilinen Sorunlar**

- [ ] UI tutarlılığı iyileştirilebilir
- [ ] Bazı ekranlarda overflow issues
- [ ] Loading states iyileştirilebilir
- [ ] Error handling daha user-friendly olabilir

## 🤝 **Katkıda Bulunma**

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/AmazingFeature`)
3. Commit edin (`git commit -m 'Add some AmazingFeature'`)
4. Push edin (`git push origin feature/AmazingFeature`)
5. Pull Request oluşturun

## 📄 **License**

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için `LICENSE` dosyasına bakınız.

## 📞 **İletişim**

- **Proje Linki**: [https://github.com/[username]/randevu_cepte](https://github.com/[username]/randevu_cepte)

## 🙏 **Teşekkürler**

- Firebase ekibine
- Flutter community'sine
- Tüm katkıda bulunan geliştiricilere

---

**V1.0** - Initial Release with core appointment booking and messaging features ✨
