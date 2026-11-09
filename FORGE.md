# Günlük Görevler geliştirme kontrol noktası

Son çalışma: 9 Kasım 2026, 1.2.0 özelleştirme ve oyunlaştırma turu. Tek hedef depo: `kaansavukduran/gorevyonetim`. Başka depoları değiştirme.

## Çalışma durumu

9 Kasım 2026 14.38 Europe/Istanbul: Android sistem dosya seçicisi uçtan uca kabulü ve özel veri arayüzü üzerinde canlı çalışma var. Kilit 9 Kasım 2026 16.00 Europe/Istanbul’a kadar geçerli; diğer turlar kaynak kodunu değiştirmeden sonraki tura bırakmalı. Çalışma tamamlanınca kilit kaldırılır.

Depo adı GitHub üzerinde `gorevyonetim` olarak değişmiş; sabit depo kimliği `1449667842` ile aynı hedef olduğu doğrulandı. Takip için kanonik yeni adres kullanılır.

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
- [ ] Android yerel dosya seçicisini emülatörde/cihazda uçtan uca doğrula: dosya yaz, yeniden seç, Türkçe içerik ve iptali dene. MethodChannel sınırı birim testlidir; gerçek seçici henüz elle denenmedi.
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

Dört platform işi de başarılı olmadan yayın yok. Ana dalda her başarılı derleme yeni `v1.2.0-build.N` ön sürümü üretir; eski `son-surum` dahil önceki indirmeler silinmez. Kaynak commit ve APK'nın test imzası sürüm notunda açık kalır. Üç masaüstü platformunda kod imzası yok. İmza yapılandırılmadan Android sürümünü mağaza/kararlı imzalı dağıtım diye adlandırma.

Linux integration işi yalnız `file_roundtrip_test.dart` çalıştırmalı; Android yerel kanal testi yalnız emülatörde koşar. İlk Linux CI turunda görev/tik yeniden açılış testi geçti, tümü atlanan Android test uygulamasının Linux debug bağlantısı kurulamadı. İş akışında hedef dosya daraltıldı.

## Tam sonraki adım

1.2.0 yayın doğrulaması tamamlandı. Şimdi Android sistem dosya seçicisini gerçek emülatör UI akışıyla doğrula (JSON oluşturma, geri seçme, Türkçe içerik, iptal, bozuk yedeği reddetme). Gizli Android dosya yolunu/masaüstü klasör düğmesini telefon arayüzünden sadeleştir. Kalıcı APK imzası için yukarıdaki gerçek secrets izin engelini koru; imza sorununu çözülmüş sayma. Her saat güncel ana dal ve bu dosyadan devam et; önceki turu baştan yeniden yapma. Başka aktif tur varsa çakışma.

Tamamlanma: yukarıdaki açık kabul maddeleri gerçek kanıtla kapanınca saatlik otomasyonu durdur. Somut kullanıcı ayarı gerektiren engeli açıkça kaydet; tamamlandı sayma.
