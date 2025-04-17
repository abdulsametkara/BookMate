# BookMate - Çiftler İçin Kitap Okuma Uygulaması

![BookMate Logo](https://api.placeholder.com/400/150?text=BookMate)

BookMate, çiftlerin birlikte kitap okuma deneyimini zenginleştiren ve motivasyonu artıran özel bir iOS uygulamasıdır. Bu uygulama, kitap okuma durumunu paylaşmayı, okuma alışkanlıklarını takip etmeyi ve görsel bir kitaplık oluşturmayı sağlayarak çiftlerin okuma yolculuğunu birlikte deneyimlemelerine olanak tanır.

## Özellikler

### Ana Özellikler
- Kişisel kitap kütüphanesi yönetimi
- Kitap ilerleme takibi ve güncellemesi
- Eş aktivite akışı ve bildirimler
- Detaylı okuma istatistikleri ve hedefler
- 3D görsel kitaplık
- Kişiselleştirilebilir kullanıcı profili

### 3D Görsel Kitaplık
Uygulamamızın en dikkat çekici özelliklerinden biri, tamamladığınız kitapları 3D görsel bir kitaplıkta görebilmenizdir. Kitaplar tamamlandıkça kitaplık büyür ve zenginleşir. Kitaplığınızı kronolojik, kategori, yazar veya renk bazlı olarak düzenleyebilirsiniz.

## Kurulum

### Sistem Gereksinimleri
- iOS 14.0 veya üstü
- Xcode 12.0 veya üstü
- Swift 5.3 veya üstü

### Geliştirme Ortamı Kurulumu
1. Repoyu klonlayın: `git clone https://github.com/username/BookMate.git`
2. Xcode'da projeyi açın: `open BookMate.xcodeproj`
3. Bağımlılıkları yükleyin: `pod install` (veya SwiftPM kullanılıyorsa Xcode otomatik yükleyecektir)
4. Projeyi derleyin ve çalıştırın

## Proje Yapısı

```
BookMate/
├── Assets/            # Görseller ve asset dosyaları
├── Models/            # Veri modelleri
├── Views/             # SwiftUI görünümleri
├── ViewModels/        # MVVM için ViewModel katmanı
├── Services/          # API ve veritabanı servisleri
└── Utils/             # Yardımcı fonksiyonlar ve uzantılar
```

## Kullanılan Teknolojiler

- **UI Framework**: SwiftUI
- **Mimari**: MVVM (Model-View-ViewModel)
- **3D Görselleştirme**: SceneKit
- **Veritabanı**: Core Data / Firebase
- **Kitap API**: Google Books API / Open Library API
- **Bildirimler**: Apple Push Notification Service (APNs)

## Katkıda Bulunma

1. Projeyi forklayın
2. Özellik dalı oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add some amazing feature'`)
4. Dalınıza push yapın (`git push origin feature/amazing-feature`)
5. Bir Pull Request açın

## Planlanan Özellikler

- Kitap tarayıcı (ISBN/kapak taraması) entegrasyonu
- Okuma zamanlayıcısı
- Kitap notları ve alıntılar
- Sosyal paylaşım entegrasyonları
- Apple Watch entegrasyonu

## İletişim

Proje sahibi - [email@example.com](mailto:email@example.com)

## Lisans

MIT Lisansı altında dağıtılmaktadır. Daha fazla bilgi için `LICENSE` dosyasına bakın. 