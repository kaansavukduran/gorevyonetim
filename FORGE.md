# Günlük Görevler geliştirme kontrol noktası

Son çalışma: 9 Kasım 2026, Codex devralma turu. Tek hedef depo: `kaansavukduran/gorevyonetimuygulamas-`. Başka depoları değiştirme.

## Kabul ölçütleri ve durum

- [x] Herkese açık kullanım: boş ilk liste; kişiye özel görev, rutin veya veri yok.
- [x] Günlük/haftalık/tek seferlik görev, gün gün tik, düzenleme/sonlandırma/silme ve geçmiş davranışı mevcut testlerle korunuyor.
- [x] Ayarlardan tek tıkla %80–%200 arayüz ölçeği; yazı, düğme, simge ve tıklama alanları birlikte büyür. Dar ekranlarda en az 360 mantıksal piksel bırakılır. İşletim sisteminin metin ölçeği korunur.
- [x] Tema, oyun modu, karakter sınıfı ve büyütme kalıcı. Karakter sınıfı JSON'a yazılmama hatası giderildi; hızlı ayar yazımları sıraya alındı; bozuk UTF-8 ayar dosyası güvenli varsayılanlarla açılır.
- [x] Telefon ve büyütülmüş pencere düzenleri: görev ayrıntıları alt satıra geçer, düzenleme seçenekleri sarılır, kontrol ekranı dikey kayar, bildirimler pencereye sığar.
- [x] Android proje ve yerel özel veri klasörü: sistem dosya seçicisiyle JSON dışa/içe aktarım; depolama izni veya yeni üçüncü taraf uygulama paketi yok. Geçersiz yedek mevcut listeye dokunmaz.
- [ ] Windows EXE/ZIP, macOS DMG/ZIP, Linux tar.gz ve Android APK'nın bu commit için GitHub Actions'ta başarılı derlemesi ve numaralı Releases kaydı: gönderim sonrası sonucu doğrula.
- [ ] Android yerel dosya seçicisini emülatörde/cihazda uçtan uca doğrula: dosya yaz, yeniden seç, Türkçe içerik ve iptali dene. MethodChannel sınırı birim testlidir; gerçek seçici henüz elle denenmedi.
- [ ] Android kalıcı dağıtım imzası ve güncelleme testi: şimdilik test anahtarıyla imzalı önizleme; farklı derlemeler arasında doğrudan güncelleme garantisi yok. İmzalama sırrını koda/artefakta koyma; kullanıcıya ait kalıcı anahtarın güvenli depo secrets yapılandırması gerekiyor.
- [ ] Son cihaz kabul turu: Windows kurulum/yükseltme, macOS açılış, Linux açılış ve Android telefon üzerinde görev/yedek/görünüm akışlarının sonuçlarını kaydet. CI açılış kontrolünü elle cihaz kabulü gibi sunma.

## Bu turun doğrulaması

- Flutter 3.47.6 / Dart 3.13.5.
- `flutter analyze`: temiz.
- `flutter test`: 138 başarılı test; ölçek, gerçek ayar dosyasında hızlı yazımlar, Android kanalında yedek doğrulama ve dar ekran gezintisi dahil.
- `flutter build web --release --no-web-resources-cdn`: başarılı (sadece geçici tarayıcı önizlemesi; web kalıcı veri desteği diye sunulmaz).
- Bu bulut makinesinde sudo/GTK derleyici araçları yok; yerel Linux masaüstü derlemesi yapılmadı. Gerçek platform derlemeleri GitHub'ın ilgili işletim sistemi makinelerinde ve Android emülatöründe koşacak.
- Regresyon testleri için mutasyon kontrolü ve GitHub sonuçları gönderimden sonra buraya eklenir.

## Yayın kuralları

Dört platform işi de başarılı olmadan yayın yok. Ana dalda her başarılı derleme yeni `v1.1.0-build.N` ön sürümü üretir; eski `son-surum` dahil önceki indirmeler silinmez. Kaynak commit ve APK'nın test imzası sürüm notunda açık kalır. Üç masaüstü platformunda kod imzası yok. İmza yapılandırılmadan Android sürümünü mağaza/kararlı imzalı dağıtım diye adlandırma.

## Tam sonraki adım

Gönderilen commit'in Actions işlerini izle. Hata varsa ilgili logdan düzelt, testleri tekrar çalıştır. Başarıda Releases varlıklarının beş masaüstü paketi + Android APK + SHA256SUMS içerdiğini ve aynı commit'e işaret ettiğini doğrula. Sonra Android sistem dosya seçicisi kabul turunu ve kalıcı APK imzasını ele al. Her saat güncel ana dal ve bu dosyadan devam et; önceki turu baştan yeniden yapma. Başka aktif tur varsa çakışma.

Tamamlanma: yukarıdaki açık kabul maddeleri gerçek kanıtla kapanınca saatlik otomasyonu durdur. Somut kullanıcı ayarı gerektiren engeli açıkça kaydet; tamamlandı sayma.
