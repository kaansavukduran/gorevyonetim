# Günlük Görevler

Windows için her gün tik atılan görev listesi (Google Tasks / Todoist mantığında, tamamen çevrimdışı). Herkesin kendi görevleriyle kullanabileceği genel bir uygulama: içinde kimseye özel görev, ayar ya da veri gelmez; ilk açılışta liste boştur.

## Ne yapar

- **Gün** sekmesi: o günün görevleri. Kutuya tıkla, yapıldı olarak işaretlenir (saatiyle). Tekrar tıkla, işaret kalkar ("Geri al" ile geri gelir). Okla ya da tarihe tıklayıp başka güne geç; geçmiş bir günü sonradan işaretlersen "sonradan işaretlendi" yazar. İleri bir gün işaretlenemez.
- **Hızlı ekleme**: üstteki kutuya yaz, Enter. Tekrar seçimi: Her gün, Hafta içi ya da Sadece bu gün. Ayrıntılı ekleme (not, belirli günler, başlangıç tarihi) için ayar simgesi ya da "Yeni görev".
- **Görevler** sekmesi: tüm görevler, son 30 günde kaç günün kaçında yapıldığı ve seri. Düzenle, sırala (sürükle), **Sonlandır** (bugünden sonra görünmez, geçmişi kalır) ya da **Sil** (görev ve tüm işaretleri kalıcı olarak silinir, "Geri al" ile hemen geri alınabilir).
- **Kontrol** sekmesi: görev × gün tablosu (7 / 14 / 30 gün). Yapıldı, yapılmadı, bekliyor, planlı, bu gün yok ayrı simgelerle gösterilir; bir hücreye tıklayıp o günü düzeltebilirsin.

Kurallar:
- Görevin başlamadığı ya da sonlandırıldığı günler "yapılmadı" sayılmaz; bugün henüz işaretlenmediyse "bekliyor"dur.
- Tekrar kuralını değiştirmek bugünden itibaren geçerlidir; önceki günler eski kurala göre kalır.

Kısayollar: `Ctrl+N` yeni görev · `Alt+←/→` önceki/sonraki gün · `Alt+B` bugün · `Ctrl+1/2/3` sekmeler.

## Veriler nerede

`%APPDATA%\GunlukGorevler\gorevler.json` (tek bir JSON dosyası). Her yazma önce geçici dosyaya yapılır, sonra eskisinin yerine konur; yarıda kesilen bir yazma eski dosyayı bozmaz. Her gün ilk değişiklikten önce dosyanın o anki hali `yedekler\gorevler-YYYY-AA-GG.json` olarak saklanır (son 14 gün). Okunamayan bir dosyanın üzerine asla yazılmaz. İnternete hiçbir şey gönderilmez; uygulama yalnızca Flutter SDK paketlerini kullanır.

## İndirme

Deponun Releases sayfasındaki **son-surum** ön sürümü: `Gunluk-Gorevler-Kurulum.exe` (kurulum) ya da `Gunluk-Gorevler-portable.zip` (açıp `gunluk_gorevler.exe`). İmzasız olduğu için Windows SmartScreen "Ek bilgi → Yine de çalıştır" isteyebilir. Exe, `.github/workflows/windows.yml` ile GitHub'ın Windows makinesinde derlenir; her push'ta testler orada da Windows üzerinde koşar ve son-surum yenilenir. Kurulum dili Türkçe (`packaging/gunluk_gorevler.iss`).

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
