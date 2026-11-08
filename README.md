# Günlük Görevler

Windows, macOS ve Linux için her gün tik atılan görev listesi (Google Tasks / Todoist mantığında, tamamen çevrimdışı). Herkesin kendi görevleriyle kullanabileceği genel bir uygulama: içinde kimseye özel görev, ayar ya da veri gelmez; ilk açılışta liste boştur.

## Ne yapar

- **Gün**: üstte seviye ve XP şeridi, altında haftanın günleri (her günün ne kadarının yapıldığı). Görev yaz, Enter; sıklık (her gün, hafta içi, sadece bu gün) kutunun içinde. Kutuya tıkla: yapıldı (saatiyle). Sağ tık: düzenle, sonlandır, sil.
- **Görev ayrıntıları**: not, belirli günler, başlangıç, **zorluk** (Kolay 10 / Orta 20 / Zor 35 XP), **hatırlatma saati** (uygulama açıkken saati gelince haber verir, geçen saat kırmızı görünür) ve **adımlar** (her adımı işaretle; sonuncusu görevi bitirir).
- **Görevler**: tümü, son 30 gün ve seri; tıkla düzenle, sürükle sırala, sonlandır ya da sil (geri alınabilir).
- **Kontrol**: görev × gün tablosu (7 / 14 / 30 gün), hücreye tıklayıp düzelt.
- **Görevler tahtası** (oyun modu, Gün ekranında): her gün tarihe göre değişen bir günlük görev (3 görev bitir, öğleden önce 2 görev, tüm günü bitir, bir zor görev) ve haftalık meydan okuma (5 mükemmel gün). Ödül **Altın**; yalnızca kendi gününde yapılan işaretler sayılır. Mükemmel günde konfeti.
- **Karakter** (oyun modu): seviye ve unvan (Çaylak → Ölümsüz), sınıf (Savaşçı, Büyücü, Okçu, Şifacı; yalnızca görünüş), statlar (İrade, Disiplin, Dayanıklılık, Cesaret, Odak, Toplam başarı, Altın), son 26 haftanın etkinlik haritası, 14 rozet, "Nasıl XP kazanırım?".
- **Ayarlar**: 6 tema (Fantastik Diyar, Neon Şehir, Orman Ruhu, Pastel Rüya, Gece Yarısı, Sade), oyun modu aç/kapat, yedeği dışa/içe aktar, veri klasörünü aç.

Oyun kuralları: XP her zaman tik geçmişinden yeniden hesaplanır (saklanmaz, kendiliğinden artmaz). Kendi gününde işaretleme +5 XP ve seri bonusu (+2/gün, en fazla +20) getirir; sonradan işaretlenen gün yalnızca temel XP alır. Bir günün tüm görevleri bitince mükemmel gün: +25 XP, +1 İrade. Seviye n'den n+1'e: 100 + 40·(n−1) XP.

Kurallar:
- Görevin başlamadığı ya da sonlandırıldığı günler "yapılmadı" sayılmaz; bugün henüz işaretlenmediyse "bekliyor"dur.
- Tekrar kuralını değiştirmek bugünden itibaren geçerlidir; önceki günler eski kurala göre kalır.

Kısayollar: `Ctrl+N` yeni görev · `Alt+←/→` önceki/sonraki gün · `Alt+B` bugün · `Ctrl+1…5` sekmeler · sağ tık görev menüsü.

## Veriler nerede

`%APPDATA%\GunlukGorevler\gorevler.json` (tek bir JSON dosyası). Her yazma önce geçici dosyaya yapılır, sonra eskisinin yerine konur; yarıda kesilen bir yazma eski dosyayı bozmaz. Her gün ilk değişiklikten önce dosyanın o anki hali `yedekler\gorevler-YYYY-AA-GG.json` olarak saklanır (son 14 gün). Okunamayan bir dosyanın üzerine asla yazılmaz. Dosya biçimi 2 (biçim 1 dosyaları açılır). Tema ve oyun modu ayrı bir `ayarlar.json` dosyasında. Dışa aktarılan yedekler İndirilenler klasörüne gider; içe aktarmadan önce mevcut liste `yedekler` klasörüne kaydedilir. İnternete hiçbir şey gönderilmez; uygulama yalnızca Flutter SDK paketlerini kullanır.

## İndirme

Deponun Releases sayfasındaki **son-surum** ön sürümü:

- **Windows:** `Gunluk-Gorevler-Windows-Kurulum.exe` (kurulum, Türkçe) ya da `Gunluk-Gorevler-Windows-portable.zip` (açıp `gunluk_gorevler.exe`). SmartScreen uyarırsa: Ek bilgi → Yine de çalıştır. Veri: `%APPDATA%\GunlukGorevler`.
- **macOS:** `Gunluk-Gorevler-macOS.dmg` (uygulamayı Applications'a sürükle). İmzasız: ilk açılışta sağ tık → Aç → Aç; olmazsa Sistem Ayarları → Gizlilik ve Güvenlik → Yine de Aç. Veri: uygulamanın kendi kapsayıcısında (`~/Library/Containers/com.gunlukgorevler.gunlukGorevler`).
- **Linux (x64):** `Gunluk-Gorevler-linux-x64.tar.gz` (açıp `./bundle/gunluk_gorevler` ya da `./install.sh` ile menüye kur). GTK 3 gerekir. Veri: `~/.local/share/gunluk_gorevler`.

Her sürüm kendi işletim sisteminde, GitHub'ın makinelerinde derlenir (`.github/workflows/release.yml`); testler üçünde de koşar, her uygulama bir kez açılıp kontrol edilir ve son-surum her push'ta yenilenir. Hiçbir dosya imzalı değil.

## Geliştirme

```bash
export PATH=/opt/toolchains/flutter/bin:$PATH   # Flutter 3.47.6 / Dart 3.13.5
flutter pub get && dart format --set-exit-if-changed . && flutter analyze && flutter test
xvfb-run -a flutter test integration_test -d linux   # gerçek dosya, yeniden açılış
flutter build linux --release                         # Windows exe yalnızca Windows'ta derlenir
xvfb-run -a -s "-screen 0 1180x800x24" tool/linux_smoke.sh /tmp/smoke   # fare/klavye ile duman testi
```

`GUNLUK_GOREVLER_DIR` ortam değişkeni veri klasörünü değiştirir (test ve deneme için).

Yapı: `lib/src/domain/` saf Dart (tarih, tekrar kuralı, görev, durum ve istatistik, dosya biçimi) · `lib/src/storage/` dosya deposu · `lib/src/app/` değişiklikleri uygulayıp kaydeden denetleyici · `lib/src/ui/` ekranlar.
