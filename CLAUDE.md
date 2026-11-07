# CLAUDE.md: Günlük Görevler

Herkesin kullanabileceği, çevrimdışı günlük görev uygulaması (Flutter, birincil hedef Windows). Arayüz Türkçe. Ayrıntılar `README.md`.

Uygulama genel kalır: koda kimseye özel görev, isim, rutin ya da varsayılan veri gömülmez; ilk açılışta liste boştur.

## Komutlar

```bash
export PATH=/opt/toolchains/flutter/bin:$PATH   # Flutter 3.47.6 / Dart 3.13.5
flutter pub get && dart format --set-exit-if-changed . && flutter analyze && flutter test
xvfb-run -a flutter test integration_test -d linux      # gerçek dosya, yeniden açılış (libgtk-3-dev gerekir)
flutter build linux --release && xvfb-run -a -s "-screen 0 1180x800x24" tool/linux_smoke.sh /tmp/smoke
```

Windows exe yalnızca Windows'ta derlenir: `.github/workflows/windows.yml` (testler Windows'ta da koşar, kurulum ve portable ZIP `son-surum` ön sürümüne konur). Burada derlenmiş gibi gösterme.

## Kurallar (bozma)

- Yalnızca bir tik "yapıldı"dır; planlı ≠ yapıldı. Görevin başlamadığı ya da sonlandırıldığı gün "yapılmadı" sayılmaz (eksik ≠ sıfır); bugün işaretlenmemişse "bekliyor"dur.
- Geçmiş sessizce değişmez: kural değişikliği ve sonlandırma takvim dilimiyle o günden itibaren geçerlidir; geçmiş bir günü sonradan işaretlemek gerçek saatiyle "sonradan işaretlendi" der.
- Silme tek yıkıcı işlemdir: onay ister, geri alınabilir.
- Veri tek JSON dosyası (`%APPDATA%\GunlukGorevler`, biçim sürümü 1): geçici dosyaya yazılıp yeniden adlandırılır, günlük yedek alınır, okunamayan ya da daha yeni bir dosyanın üzerine asla yazılmaz, ilk değişiklikten önce hiçbir şey yazılmaz, hiçbir şey internete gitmez.
- `lib/src/domain/` saf Dart kalır (Flutter, IO yok). Üçüncü taraf paket eklemeden önce lisans, bakım ve platform desteğini değerlendirip kullanıcıya sor; `pubspec.lock` commit'lenir.
- Her davranış değişikliği test ister; testlerin hatayı gerçekten yakaladığını bir mutasyonla göster.
