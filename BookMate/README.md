# BookMate - Kişisel Kitap Takip Uygulaması

BookMate, kitapseverlerin okuma alışkanlıklarını takip etmelerine, kitap koleksiyonlarını yönetmelerine ve eşleriyle okuma deneyimlerini paylaşmalarına olanak tanıyan kapsamlı bir iOS uygulamasıdır.

![BookMate Logo](screenshot-url-placeholder)

## 📱 Uygulama Özellikleri

### 📚 Kitap Koleksiyonu Yönetimi
- **Kitaplık Görünümü**: Kitapları liste, ızgara veya 3D kitaplık olarak görüntüleme
- **Kitap Detayları**: Her kitap için kapsamlı bilgiler (yazar, yayıncı, sayfa sayısı, vb.)
- **Koleksiyonlar**: Kitapları özel koleksiyonlara ayırma ve organize etme

### 📖 Okuma İlerlemesi Takibi
- **Okuma Durumu**: Başlanmadı, okunuyor, beklemede, tamamlandı veya bırakıldı olarak işaretleme
- **Sayfa Takibi**: Hangi sayfada olduğunuzu kaydetme ve ilerleme çubuğu ile takip etme
- **Okuma İstatistikleri**: Tamamlanan kitaplar, toplam sayfa sayısı ve okuma alışkanlıkları hakkında istatistikler

### 🔍 Kitap Arama ve Ekleme
- **ISBN Tarama**: Kamera ile ISBN barkodu tarayarak kitapları hızlıca ekleme
- **Google Books Entegrasyonu**: Kitap bilgilerini otomatik olarak doldurma ve kapak resimlerini indirme
- **Manuel Giriş**: Kitap bilgilerini manuel olarak ekleme ve düzenleme seçeneği

### 📝 Notlar ve İşaretlemeler
- **Okuma Notları**: Kitapta okuduğunuz bölümler hakkında notlar alabilme
- **Alıntılar**: Beğendiğiniz pasajları işaretleme ve saklama
- **Değerlendirmeler**: Kitaplar için puanlama ve kişisel değerlendirmeler ekleme

### 👫 Eşleşme ve Paylaşım
- **Eş Paylaşımı**: Okuma deneyimlerinizi eşiniz veya yakın bir arkadaşınızla paylaşma
- **Okuma Önerileri**: Eşinize kitap önerilerinde bulunma
- **İlerleme Takibi**: Eşinizin okuma durumunu izleme ve motive etme

### 🔒 Kullanıcı Yönetimi
- **Hesap Oluşturma**: E-posta/şifre ile güvenli hesap oluşturma
- **Profil Yönetimi**: Kişisel bilgilerinizi ve tercihlerinizi düzenleme
- **Veri Senkronizasyonu**: Firebase kullanarak verilerinizi cihazlar arasında senkronize etme

## 🛠️ Teknik Detaylar

### Kullanılan Teknolojiler
- **Swift ve SwiftUI**: Modern UI tasarımı ve uygulama geliştirme
- **Firebase**: Kimlik doğrulama, veritabanı ve depolama çözümleri
- **Google Books API**: Kitap bilgileri ve kapak resimleri için
- **Core Data**: Yerel veri depolama ve çevrimdışı kullanım
- **SceneKit**: 3D kitaplık görünümü için

### Mimari ve Tasarım
- **MVVM (Model-View-ViewModel)** mimarisi
- **Repository Pattern** veri yönetimi için
- **Dependency Injection** bileşenler arası bağımlılık yönetimi için
- **Reactive Programming** kullanıcı etkileşimleri ve veri akışı için

## 📂 Proje Yapısı

```
BookMate/
├── App/                    # Uygulama başlangıç noktası ve konfigürasyon dosyaları
├── Views/                  # Tüm SwiftUI görünümleri
│   ├── Authentication/     # Giriş ve kayıt ekranları
│   ├── Components/         # Yeniden kullanılabilir UI bileşenleri
│   └── ...                 # Ana ekranlar (Ana Sayfa, Kitaplık, vb.)
├── Models/                 # Veri modelleri
├── ViewModels/             # Görünüm modelleri ve iş mantığı
├── Services/               # Harici servisler ve API entegrasyonları
│   ├── BookService         # Kitap verilerini yönetme
│   ├── AuthenticationService # Kimlik doğrulama işlemleri
│   └── ...                 # Diğer servisler
├── Utilities/              # Yardımcı fonksiyonlar ve uzantılar
└── Resources/              # Uygulama kaynakları (görseller, fontlar, vb.)
```

## 🚀 Proje Durumu

BookMate şu anda aktif geliştirme aşamasındadır ve aşağıdaki özellikler tamamlanmıştır:

- ✅ Temel kitaplık görünümü (liste, ızgara ve 3D)
- ✅ Kitap detayları ve okuma ilerleme takibi
- ✅ Kullanıcı kimlik doğrulama sistemi
- ✅ Kitap arama ve ekleme fonksiyonları
- ✅ Eş paylaşım özelliklerinin temel yapısı

### Geliştirme Aşamasındaki Özellikler
- 🔄 Okuma istatistikleri ve raporlama
- 🔄 Daha gelişmiş eş paylaşım özellikleri
- 🔄 Offline modu iyileştirmeleri
- 🔄 Performans optimizasyonları

## 📋 Gelecek Planları

- 🔮 Kitap önerileri ve keşif özellikleri
- 🔮 Okuma hedefleri ve meydan okumalar
- 🔮 Sosyal paylaşım entegrasyonu
- 🔮 Karanlık mod ve özelleştirilebilir temalar
- 🔮 Çoklu dil desteği

## 🤝 Katkıda Bulunma

BookMate açık kaynaklı bir proje değildir, ancak geri bildirimlerinizi ve önerilerinizi memnuniyetle karşılıyoruz. Herhangi bir hata raporu veya özellik isteği için lütfen doğrudan iletişime geçin.

## 👨‍💻 Geliştirici

BookMate, kitapseverler için modern ve kullanışlı bir kitap takip çözümü sunmak amacıyla geliştirilmiştir. Projenin geliştirilmesinde Swift ve SwiftUI'nin en güncel özellikleri kullanılarak, kullanıcı dostu ve estetik bir arayüz oluşturulması hedeflenmiştir.

### Kullanıcı Hesabı Yönetimi
- Kayıt işlemi: Kullanıcılar, e-posta ve şifre ile kayıt olabilirler
- Profil bilgileri: Kullanıcılar isim, soyisim, biyografi gibi bilgilerini ekleyebilirler
- Oturum yönetimi: UserDefaults üzerinde kullanıcı bilgileri saklanır
- Otomatik giriş: Uygulama açıldığında kayıtlı kullanıcı varsa otomatik giriş yapılır

### Veri Saklama
- Kullanıcı bilgileri: UserDefaults'ta JSON formatında saklanır
- Kitap verileri: Google Books API üzerinden çekilir ve yerel veritabanında saklanır

### Mimari
- MVVM (Model-View-ViewModel) mimarisi kullanılmıştır
- SwiftUI ile modern ve duyarlı kullanıcı arayüzü
- Combine framework ile reaktif programlama

---

© 2024 BookMate. Tüm hakları saklıdır. 