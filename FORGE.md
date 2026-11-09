# Günlük Görevler geliştirme kontrol noktası

Son çalışma: 9 Kasım 2026, 1.2.1 Android yedekleme güvenilirliği turu. Tek hedef depo: `kaansavukduran/gorevyonetim`. Başka depoları değiştirme.

## Çalışma durumu

Aktif çalışma kilidi yok. 9 Kasım 2026 1.2.1 turu tamamlandı ve kilit kaldırıldı. Yeni tur başlamadan önce güncel main, açık PR’lar, Actions ve bu kontrol noktasını oku. Saatlik otomasyon açık kabul maddeleri nedeniyle etkin kalır.

Depo adı GitHub üzerinde `gorevyonetim` olarak değişmiş; sabit depo kimliği `1449667842` ile aynı hedef olduğu doğrulandı. Takip için kanonik yeni adres kullanılır.

## 1.2.1 Android yedekleme turu

- [x] Depolama yeteneklerine göre arayüz: Android'de erişilemeyen iç dosya yolu/klasör düğmesi yerine özel alan ve kaldırmadan önce yedek alma açıklaması. Masaüstünde klasör açma korunur; tarayıcı önizlemesinde belleğin geçici olduğu doğru anlatılır.
- [x] Android seçicisi İndirilenler'den başlar; başka konum seçilebilir, depolama izni istenmez. Boş seçici iptali yanıltıcı yedek bulunamadı diyaloğu açmaz. İçe aktarma sonrası korunan eski liste için Android'de teknik yol yerine açıklama gösterilir.
- [x] Telefon düzeni, iptal, özel alan ve kaydedilmiş dosyayı koruma regresyonları; iki arayüz mutasyonu yakalandı ve geri alındı. Dört standart Python testi ADB sürücüsünün yalnız gözlenen DocumentsUI denetimlerine dokunduğunu denetler. Yerel analiz temiz; 158 Flutter testi başarılı. İşlem değişimi denetimi ve tek seferlik eylem kilidi iki ayrı mutasyonla testlerce yakalandı; tüm dört mutasyon geri alındı.
- [x] [CI turu 15](https://github.com/kaansavukduran/gorevyonetim/actions/runs/42614009481): Android 35 emülatöründe gerçek sistem seçicisiyle altı akış başarılı: dışa aktar, dışa/içe aktarmayı iptal et, bozuk JSON ve UTF-8 reddi, geri seçip yükle. Türkçe not/saat/adım/tik verisi ve yeniden açılış karşılaştırıldı; hatalı/iptal akışları mevcut iki görevli dosyaya dokunmadı. [XML/ekran/log ve result.json kanıtı](https://github.com/kaansavukduran/gorevyonetim/actions/runs/42614009481/artifacts/13672286375) indirilip kontrol edildi; `allPassed: true`, `phases: 6`. Fiziksel telefon testi diye sunulmaz.
- [x] **1.2.1 yayımlandı:** [v1.2.1-build.15](https://github.com/kaansavukduran/gorevyonetim/releases/tag/v1.2.1-build.15), kaynak `b34cc46065b80046e7ecc6ed948abc61aeba7f14`. Dört platform işi ve publish başarılı. Windows kurulum EXE/portable ZIP, Linux tar.gz, macOS DMG/ZIP, Android APK ve SHA256SUMS olmak üzere 7 varlık doğrulandı. İndirilen SHA256SUMS içindeki altı paket özeti GitHub’daki varlık SHA-256 değerleriyle bire bir eşleşti. Windows/macOS açılış kontrolü, Linux gerçek dosya ve fare/klavye testi, Android’de üç entegrasyon testi geçti. Bunlar fiziksel cihazda elle kurulum/yükseltme kabulü sayılmaz. Bu kayıttan sonraki commit yalnız belgedir.
- Derleme 13: Linux işi başarılı; Android test sürücüsü uygulama kurulmadan önce örnek JSON'u emülatörün paylaşılan alanına aktarırken durdu, seçici testi henüz çalışmadı. Yayın yok. Hazırlık uygulamanın gerçek başlangıç işaretinden sonraya alındı; sınırlı hazırlık beklemesi ve ADB stderr kaydı eklendi. Hazırlık düzeltmesi derleme 15’te başarılı oldu.
- Derleme 14: üç masaüstü işi ve önceki iki Android entegrasyonu başarılı. Gerçek seçiciyle ilk JSON dışa aktarımı geçti; iptal testinde sürücü yavaş UI dökümü sırasında değişen işlem işaretini yeniden kontrol etmediği için eski Kaydet eylemini tekrarladı. Yayın yok. Sürücüye güncel işlem kontrolü ve tek seferlik kaydet/seç eylemi eklendi; bu yarış için Python regresyonu yazıldı. İptal/bozuk dosya/içe aktarımın tamamı derleme 15’te geçti.

## Yeni kullanıcı isteği: 1.2.0 turu

- [x] Gün ekranında fareyle yukarı/aşağı sıralama; görünmeyen görevlerin yuvaları ve bütün tikler korunur. Saat sırasından sürükleme manuel sıraya geçirir; seçim ve sıra kaydedilir.
- [x] Hızlı eklemede ve görev kartında saat; 24 saat biçiminde klavye girişi, değiştirme/kaldırma/iptal. Notlar, adımlar, zorluk ve geçmiş korunur.
- [x] %1 hassasiyetli ölçek çubuğu, doğrudan yüzde, anlık örnek ve sıfırlama. Tüm pencere ölçeği çubuk bırakılınca uygulanır; böylece denetim fare altında yer değiştirmez.
- [x] Altı bağımsız tema rengi; renk alanı, ton/RGB çubukları, HEX, palet, önceki/yeni örnek ve iptal. Açık/koyu görünüm, 0–28 px hassas kart köşesi, başlık stili ve rozet parlaması kalıcıdır.
- [x] Gerçek görevlerden hesaplanan 1–20 arası günlük hedef ve hedef kutlaması. Hedef/tema ayarı değiştirmek XP vermez; azaltılmış hareket ve efekt kapatma tercihi korunur.
- [x] Zenginleştirilmiş ürün promptu [FORGE_PROMPT.md](FORGE_PROMPT.md) içinde ve saatlik otomasyonda kayıtlı. Oyunlaştırma, hassas özelleştirme ve gerçek test/yayın şartları kalıcı talimattır.
- [x] Yerel analiz temiz; 154 test başarılı. Altı mutasyon testlerce yakalandı (paleti kaydetmeme, sıralamayı yok sayma, saat düzenlerken notu silme, hedef için fazladan tik üretme, hassas ölçeği yok sayma, ayrı sistem hareket azaltma bayrağını yok sayma). Mutasyonlar geri alındı.
- Derleme 10, son erişilebilirlik ekinde atlanan bir `curly_braces_in_flow_control_structures` biçim kuralı yüzünden durdu; yayınlanmadı. Düzeltme sonrası yerel analiz temiz ve yalnız `reduceMotion` açık regresyon testi başarılı; sorun derleme 12’de kapandı.
- [x] Sistem `reduceMotion` ve `disableAnimations` bayrakları ayrı ayrı ele alınır; yalnız `reduceMotion` açıkken de kutlama engellenir. Bu regresyon test ve mutasyonla doğrulandı.
- [x] Chromium/Playwright: doğrudan %137, HEX ile `#10B981` uygulama ve 390 pikselde renk seçici açılışı doğrulandı; tarayıcı hatası yok.
- Android derleme 11: cihaz içi yeni ayar kaydı/yeniden açılış testi geçti. Diğer entegrasyon testinde açık gerçek IME/varsayılan üst hizalama nedeniyle görev işaretçisi görünür alandan kaydı. Test, klavyeyi kapatıp satırı ortalayarak gerçek hit-test görünürlüğünü denetleyecek biçimde düzeltildi; ürünün masaüstü/klavye odağı davranışı değiştirilmedi.
- [x] **1.2.0 yayımlandı:** [v1.2.0-build.12](https://github.com/kaansavukduran/gorevyonetim/releases/tag/v1.2.0-build.12). [CI turu 12](https://github.com/kaansavukduran/gorevyonetim/actions/runs/42607391257) dört platformda başarılı. Windows kurulum EXE/ZIP, Linux tar.gz, macOS DMG/ZIP, Android APK ve SHA256SUMS olmak üzere 7 varlık doğrulandı. Kaynak commit `dbb108060151c2a7614f03cbf4294586620dabd3`; sonradan yalnız bu kontrol noktası güncellendi. Android’in iki entegrasyon testi de geçti; renk, %137 ölçek, hedef ve sıra tercihi gerçek cihaz deposundan yeniden açıldı.

## Önceki turun kabul ölçütleri ve durum

- [x] Herkese açık kullanım: boş ilk liste; kişiye özel görev, rutin veya veri yok.
- [x] Günlük/haftalık/tek seferlik görev, gün gün tik, düzenleme/sonlandırma/silme ve geçmiş davranışı mevcut testlerle korunuyor.
- [x] Ayarlardan tek tıkla %80–%200 arayüz ölçeği; yazı, düğme, simge ve tıklama alanları birlikte büyür. Dar ekranlarda en az 360 mantıksal piksel bırakılır. İşletim sisteminin metin ölçeği korunur.
- [x] Tema, oyun modu, karakter sınıfı ve büyütme kalıcı. Karakter sınıfı JSON'a yazılmama hatası giderildi; hızlı ayar yazımları sıraya alındı; bozuk UTF-8 ayar dosyası güvenli varsayılanlarla açılır.
- [x] Telefon ve büyütülmüş pencere düzenleri: görev ayrıntıları alt satıra geçer, düzenleme seçenekleri sarılır, kontrol ekranı dikey kayar, bildirimler pencereye sığar.
- [x] Android proje ve yerel özel veri klasörü: sistem dosya seçicisiyle JSON dışa/içe aktarım; depolama izni veya yeni üçüncü taraf uygulama paketi yok. Geçersiz yedek mevcut listeye dokunmaz.
- [x] Windows EXE/ZIP, macOS DMG/ZIP, Linux tar.gz ve Android APK derlendi ve yayımlandı: [v1.1.0-build.7](https://github.com/kaansavukduran/gorevyonetim/releases/tag/v1.1.0-build.7). Beş masaüstü paketi + APK + SHA256SUMS olmak üzere 7 dosya doğrulandı. Kaynak commit `486b221947552623a5400e54a00e754df5f901ab`; sonraki commitler yalnız kontrol noktası belgeleri.
- [x] Android yerel dosya seçicisini Android 35 emülatöründe gerçek UI ile uçtan uca doğrula: JSON yazma/geri seçme, Türkçe içerik, not/saat/adım/tik turu, iptal ve bozuk dosya reddi CI turu 15’te geçti. Fiziksel telefon kabulü aşağıda ayrı açık kalır.
- [ ] Android kalıcı dağıtım imzası ve güncelleme testi: şimdilik test anahtarıyla imzalı önizleme; farklı derlemeler arasında doğrudan güncelleme garantisi yok. İmzalama sırrını koda/artefakta koyma; kullanıcıya ait kalıcı anahtarın güvenli depo secrets yapılandırması gerekiyor. Bağlı GitHub entegrasyonuyla repo secrets listesi denendi: HTTP 403 `Resource not accessible by integration`. Bu izin değişmeden aynı isteği tekrar tekrar deneme; önizleme paketi bu engelden bağımsız üretilebilir.
- [ ] Son cihaz kabul turu: Windows kurulum/yükseltme, macOS açılış, Linux açılış ve Android telefon üzerinde görev/yedek/görünüm akışlarının sonuçlarını kaydet. CI açılış kontrolünü elle cihaz kabulü gibi sunma.

## 1.1.0 turunun doğrulaması (tarihçe)

- Flutter 3.47.6 / Dart 3.13.5.
- `flutter analyze`: temiz.
- `flutter test`: 138 başarılı test; ölçek, gerçek ayar dosyasında hızlı yazımlar, Android kanalında yedek doğrulama ve dar ekran gezintisi dahil.
- `flutter build web --release --no-web-resources-cdn`: başarılı (sadece geçici tarayıcı önizlemesi; web kalıcı veri desteği diye sunulmaz).
- Chromium/Playwright ile %150 ölçeği seçme, görev ekleme, tik atma ve 390 pikselde Kontrol sekmesine geçiş doğrulandı; tarayıcı hata listesi boş.
- Bu bulut makinesinde sudo/GTK derleyici araçları yok; yerel Linux masaüstü derlemesi yapılmadı. Gerçek platform derlemeleri GitHub makinelerinde geçti: [başarılı Actions turu](https://github.com/kaansavukduran/gorevyonetim/actions/runs/42596703830). Windows açılış, macOS açılış, Linux gerçek dosya yeniden açılışı/fare-klavye testi ve Android emülatöründeki 2 entegrasyon testi başarılı.
- Üç mutasyon denendi ve testler üçünü de yakaladı: karakter sınıfını kayıttan çıkarmak, büyütmeyi yok saymak, hızlı ayarları eşzamanlı yazmak. Değişiklikler geri alındı.
- İlk GitHub Android işi SDK kurulum eyleminin artık bulunmayan `tools` paketini istemesi yüzünden durdu. Paket listesi yalnız `platform-tools` olacak şekilde düzeltildi; eski başarılı masaüstü sürümlerine dokunulmadı.

Android önizleme APK arşivi ayrıca indirildi: manifest ve ARM64, ARMv7, x86_64 için derlenmiş Flutter/Dart kitaplıkları mevcut. `son-surum` önceki sürümü ve indirmeleri korunuyor.

## Yayın kuralları

Dört platform işi de başarılı olmadan yayın yok. Ana dalda her başarılı derleme yeni `v1.2.1-build.N` ön sürümü üretir; eski `son-surum` dahil önceki indirmeler silinmez. Kaynak commit ve APK'nın test imzası sürüm notunda açık kalır. Üç masaüstü platformunda kod imzası yok. İmza yapılandırılmadan Android sürümünü mağaza/kararlı imzalı dağıtım diye adlandırma.

Linux integration işi yalnız `file_roundtrip_test.dart` çalıştırmalı; Android yerel kanal testi yalnız emülatörde koşar. İlk Linux CI turunda görev/tik yeniden açılış testi geçti, tümü atlanan Android test uygulamasının Linux debug bağlantısı kurulamadı. İş akışında hedef dosya daraltıldı.

## Tam sonraki adım

1.2.1 ve Android gerçek dosya seçicisi kabulü tamamlandı; bunları baştan yapma. **Sıradaki somut adım Windows kurulum/yükseltme kabulüdür:** Windows CI çalıştırıcısında üretilen Inno EXE’yi geçici kurulum klasörüne `/VERYSILENT` ile kur; önceki başarılı sürümden yerinde yükseltmeyi de dene. Görev, tik, not/adım/saat ve %137 özel tema ayarı içeren geçici kullanıcı verisini yükseltmeden önce kaydet; yükseltmeden sonra uygulamayı açıp aynı dosya ve ayarların korunduğunu doğrula. Gerçek kullanıcı klasörüne dokunma; geçici kullanıcı/veri alanını açıkça ayır. Test başarısızsa yayınlama. Bunu fiziksel Windows cihazında elle kabul yapılmış gibi anlatma.

Kalıcı APK imzası için yukarıdaki gerçek secrets HTTP 403 izin engelini koru; izin değişmeden aynı isteği tekrarlama. Fiziksel telefon kabulü ve imzalı APK güncellemesi hâlâ açıktır. Her saat güncel ana dal ve bu dosyadan devam et; başka aktif tur varsa çakışma.

Tamamlanma: yukarıdaki açık kabul maddeleri gerçek kanıtla kapanınca saatlik otomasyonu durdur. Somut kullanıcı ayarı gerektiren engeli açıkça kaydet; tamamlandı sayma.
