# CLAUDE.md: Günlük Görevler

Herkesin kullanabileceği, çevrimdışı günlük görev uygulaması (Flutter; Windows, macOS, Linux, Android). Arayüz Türkçe. Ayrıntılar `README.md`.

Uygulama genel kalır: koda kimseye özel görev, isim, rutin ya da varsayılan veri gömülmez; ilk açılışta liste boştur.

## Komutlar

```bash
export PATH=/opt/toolchains/flutter/bin:$PATH   # Flutter 3.47.6 / Dart 3.13.5
flutter pub get && dart format --set-exit-if-changed . && flutter analyze && flutter test
xvfb-run -a flutter test integration_test -d linux      # gerçek dosya, yeniden açılış (libgtk-3-dev gerekir)
flutter build linux --release && xvfb-run -a -s "-screen 0 1180x800x24" tool/linux_smoke.sh /tmp/smoke
```

Windows ve macOS sürümleri yalnızca kendi işletim sistemlerinde derlenir: `.github/workflows/release.yml` (testler üç sistemde de koşar; Windows kurulumu ve ZIP, macOS DMG ve ZIP, Linux tar.gz ve Android önizleme APK numaralı `v1.1.0-build.N` ön sürümüne konur). Burada derlenmiş gibi gösterme. Linux paketi: `tool/package_linux.sh`.

## Kurallar (bozma)

- Yalnızca bir tik "yapıldı"dır; planlı ≠ yapıldı. Görevin başlamadığı ya da sonlandırıldığı gün "yapılmadı" sayılmaz (eksik ≠ sıfır); bugün işaretlenmemişse "bekliyor"dur.
- Geçmiş sessizce değişmez: kural değişikliği ve sonlandırma takvim dilimiyle o günden itibaren geçerlidir; geçmiş bir günü sonradan işaretlemek gerçek saatiyle "sonradan işaretlendi" der.
- Silme tek yıkıcı işlemdir: onay ister, geri alınabilir.
- Oyunlaştırma (`lib/src/domain/game.dart`) yalnızca tik geçmişinden hesaplanır: XP, seviye, stat ya da rozet saklanmaz; sonradan işaretlenen gün bonus almaz; bilinmeyen yüzde "–" gösterilir, 0 değil. Oyun modu kapatılabilir; temalar `lib/src/ui/themes.dart`.
- Veri tek JSON dosyası (`%APPDATA%\GunlukGorevler`, biçim sürümü 2, biçim 1 okunur; ayarlar ayrı `ayarlar.json`): geçici dosyaya yazılıp yeniden adlandırılır, günlük yedek alınır, okunamayan ya da daha yeni bir dosyanın üzerine asla yazılmaz, ilk değişiklikten önce hiçbir şey yazılmaz, hiçbir şey internete gitmez.
- `lib/src/domain/` saf Dart kalır (Flutter, IO yok). Üçüncü taraf paket eklemeden önce lisans, bakım ve platform desteğini değerlendirip kullanıcıya sor; `pubspec.lock` commit'lenir.
- Her davranış değişikliği test ister; testlerin hatayı gerçekten yakaladığını bir mutasyonla göster.

Devam kontrol noktası: `FORGE.md`. Android özel dosya klasörü ve sistem dosya seçicisi yerel MethodChannel ile sağlanır; üçüncü taraf çalışma zamanı paketi eklenmedi. Arayüz ölçeği `InterfaceScale` ile uygulanır; işletim sisteminin metin büyütmesi korunur.
