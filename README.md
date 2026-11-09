# Günlük Görevler

Windows, macOS, Linux ve Android için her gün tik atılan görev listesi (Google Tasks / Todoist mantığında, tamamen çevrimdışı). Herkesin kendi görevleriyle kullanabileceği genel bir uygulama: içinde kimseye özel görev, ayar ya da veri gelmez; ilk açılışta liste boştur.

## Ne yapar

- **Gün**: üstte seviye ve XP şeridi, altında haftanın günleri (her günün ne kadarının yapıldığı). Görev yaz, Enter; sıklık (her gün, hafta içi, sadece bu gün) kutunun içinde. Kutuya tıkla: yapıldı (saatiyle). Sağ tık: düzenle, sonlandır, sil.
- **Sürükle ve saat ver**: Gün ekranında görevin solundaki tutamaçtan yukarı/aşağı taşı; sıra kaydedilir ve Görevler ekranıyla paylaşılır. `Kendi sıram` / `Saate göre` arasında geçiş yap. Saat sırasındayken sürüklemek manuel sıraya geçirir. Hızlı eklemedeki saat simgesinden veya görev kartındaki `Saat ekle` düğmesinden saat/dakika gir; saati karttan değiştir ya da kaldır. Saatler 24 saat biçimindedir.
- **Özel görünüm**: ana vurgu, ikinci vurgu, kart zemini, arka planın iki ucu ve XP rengini ayrı ayarla. Renk alanı, ton/RGB çubukları, HEX girişi ve önceki/yeni renk önizlemesi var. Açık/koyu görünüm, kart köşesi (0–28 px, çubuk veya sayı), klasik/modern başlık ve rozet parlamasını özelleştir. Renkler `Rengi kullan` ile kaydedilir; `Vazgeç` değişiklik yapmaz.
- **Günlük hedef**: ayarlardan 1–20 görev seç; gerçek tiklerin ilerleme çubuğunu doldurur. Hedef tamamlanınca kutlama gelir. Hedef veya tema değiştirmek XP vermez. Kutlama efektleri kapatılabilir; cihazın azaltılmış hareket tercihi korunur.
- **Görev ayrıntıları**: not, belirli günler, başlangıç, **zorluk** (Kolay 10 / Orta 20 / Zor 35 XP), **hatırlatma saati** (uygulama açıkken saati gelince haber verir, geçen saat kırmızı görünür) ve **adımlar** (her adımı işaretle; sonuncusu görevi bitirir).
- **Görevler**: tümü, son 30 gün ve seri; tıkla düzenle, sürükle sırala, sonlandır ya da sil (geri alınabilir).
- **Kontrol**: görev × gün tablosu (7 / 14 / 30 gün), hücreye tıklayıp düzelt.
- **Görevler tahtası** (oyun modu, Gün ekranında): her gün tarihe göre değişen bir günlük görev (3 görev bitir, öğleden önce 2 görev, tüm günü bitir, bir zor görev) ve haftalık meydan okuma (5 mükemmel gün). Ödül **Altın**; yalnızca kendi gününde yapılan işaretler sayılır. Mükemmel günde konfeti.
- **Karakter** (oyun modu): seviye ve unvan (Çaylak → Ölümsüz), sınıf (Savaşçı, Büyücü, Okçu, Şifacı; yalnızca görünüş), statlar (İrade, Disiplin, Dayanıklılık, Cesaret, Odak, Toplam başarı, Altın), son 26 haftanın etkinlik haritası, 14 rozet, "Nasıl XP kazanırım?".
- **Ayarlar**: %80–%200 arayüz ölçeği için %1 adımlı çubuk, yüzde girişi ve anlık örnek; dar ekranlarda büyütme sınırlandırılır. 6 hazır tema (Fantastik Diyar, Neon Şehir, Orman Ruhu, Pastel Rüya, Gece Yarısı, Sade), oyun modu aç/kapat, yedeği dışa/içe aktar, veri klasörünü aç.

Oyun kuralları: XP her zaman tik geçmişinden yeniden hesaplanır (saklanmaz, kendiliğinden artmaz). Kendi gününde işaretleme +5 XP ve seri bonusu (+2/gün, en fazla +20) getirir; sonradan işaretlenen gün yalnızca temel XP alır. Bir günün tüm görevleri bitince mükemmel gün: +25 XP, +1 İrade. Seviye n'den n+1'e: 100 + 40·(n−1) XP.

Kurallar:
- Görevin başlamadığı ya da sonlandırıldığı günler "yapılmadı" sayılmaz; bugün henüz işaretlenmediyse "bekliyor"dur.
- Tekrar kuralını değiştirmek bugünden itibaren geçerlidir; önceki günler eski kurala göre kalır.

Kısayollar: `Ctrl+N` yeni görev · `Alt+←/→` önceki/sonraki gün · `Alt+B` bugün · `Ctrl+1…5` sekmeler · sağ tık görev menüsü.

## Veriler nerede

`%APPDATA%\GunlukGorevler\gorevler.json` (tek bir JSON dosyası). Her yazma önce geçici dosyaya yapılır, sonra eskisinin yerine konur; yarıda kesilen bir yazma eski dosyayı bozmaz. Her gün ilk değişiklikten önce dosyanın o anki hali `yedekler\gorevler-YYYY-AA-GG.json` olarak saklanır (son 14 gün). Okunamayan bir dosyanın üzerine asla yazılmaz. Dosya biçimi 2 (biçim 1 dosyaları açılır). Tema, oyun modu, karakter sınıfı ve arayüz ölçeği ayrı bir `ayarlar.json` dosyasında. Masaüstünde dışa aktarılan yedekler İndirilenler klasörüne gider; Android’de sistemin dosya seçicisiyle konum seçilir; içe aktarmadan önce mevcut liste `yedekler` klasörüne kaydedilir. İnternete hiçbir şey gönderilmez; uygulama yalnızca Flutter SDK paketlerini kullanır.

## İndirme

[Releases sayfasındaki](https://github.com/kaansavukduran/gorevyonetim/releases) en yeni **v1.2.0-build.N** ön sürümü (önceki sürümler korunur):

- **Windows:** `Gunluk-Gorevler-Windows-Kurulum.exe` (kurulum, Türkçe) ya da `Gunluk-Gorevler-Windows-portable.zip` (açıp `gunluk_gorevler.exe`). SmartScreen uyarırsa: Ek bilgi → Yine de çalıştır. Veri: `%APPDATA%\GunlukGorevler`.
- **macOS:** `Gunluk-Gorevler-macOS.dmg` (uygulamayı Applications'a sürükle). İmzasız: ilk açılışta sağ tık → Aç → Aç; olmazsa Sistem Ayarları → Gizlilik ve Güvenlik → Yine de Aç. Veri: uygulamanın kendi kapsayıcısında (`~/Library/Containers/com.gunlukgorevler.gunlukGorevler`).
- **Linux (x64):** `Gunluk-Gorevler-linux-x64.tar.gz` (açıp `./bundle/gunluk_gorevler` ya da `./install.sh` ile menüye kur). GTK 3 gerekir. Veri: `~/.local/share/gunluk_gorevler`.

- **Android (önizleme):** `Gunluk-Gorevler-Android-onizleme.apk`. Görevler uygulamanın özel veri klasöründe tutulur, depolama izni istenmez. Yedek almak/yüklemek sistemin dosya seçicisini açar. Uygulamayı kaldırmak görevleri siler; önce yedek al. APK test anahtarıyla imzalıdır; her derlemede anahtar değişebileceğinden güncellemeden önce yedek alıp kaldırmak gerekebilir. Kalıcı dağıtım imzası henüz yapılandırılmadı. Hatırlatmalar yalnız uygulama açıkken çalışır.

Her sürüm GitHub'ın makinelerinde derlenir (`.github/workflows/release.yml`); ortak testler dört işte de koşar; masaüstü uygulamaları açılış kontrolünden, Android cihaz içi kayıt ve yeniden açılış testleri emülatörden geçer. Yalnız main dalında dört platform da başarılıysa aynı commit için yeni, numaralı ön sürüm yayımlanır; mevcut sürümler silinmez. Masaüstü dosyaları kod imzası içermez, Android APK test imzalıdır. Yerel Android dosya seçicisi gerçek cihazda elle kontrol bekliyor.

## Geliştirme

```bash
export PATH=/opt/toolchains/flutter/bin:$PATH   # Flutter 3.47.6 / Dart 3.13.5
flutter pub get && dart format --set-exit-if-changed . && flutter analyze && flutter test
xvfb-run -a flutter test integration_test/file_roundtrip_test.dart -d linux   # gerçek dosya, yeniden açılış
flutter build linux --release                         # Windows exe yalnızca Windows'ta derlenir
xvfb-run -a -s "-screen 0 1180x800x24" tool/linux_smoke.sh /tmp/smoke   # fare/klavye ile duman testi
```

`GUNLUK_GOREVLER_DIR` ortam değişkeni veri klasörünü değiştirir (test ve deneme için).

Yapı: `lib/src/domain/` saf Dart (tarih, tekrar kuralı, görev, durum ve istatistik, dosya biçimi) · `lib/src/storage/` dosya deposu · `lib/src/app/` değişiklikleri uygulayıp kaydeden denetleyici · `lib/src/ui/` ekranlar.

## Geliştirme kontrol noktası

Saatlik çalışma talimatı [FORGE_PROMPT.md](FORGE_PROMPT.md) içinde. Devam çalışmaları [FORGE.md](FORGE.md) içindeki somut eksikleri ve kabul ölçütlerini izler. Tamamlanma yalnız test ve gerçek derleme sonucu ile işaretlenir. Görev geçmişi ve eski yedek biçimleri korunur; varsayılan görev eklenmez.
