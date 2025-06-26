# Echowolke: Ücretsiz ve Özgür bir Müzik Deneyimi

<img src="assets/images/echowolke_logo.png" width="150" align="left" alt="Echowolke Logo">
<img src="assets/images/istinye_logo.png" width="450" align="left" alt="İstinye Üniversitesi Logo">
<br clear="left"/>
Echowolke, kullanıcıların favori müziklerini keşfetmelerine, kendi müziklerini paylaşmalarına ve kendi çalma listelerini oluşturup arkadaşlarıyla paylaşmalarına olanak tanıyan KAPSAMLI BİR MÜZİK AKIŞI UYGULAMASIDIR. TEMİZ VE MODERN arayüzü ile sorunsuz bir müzik dinleme deneyimi sunar.

Bu uygulama, İstinye Üniversitesi BİTİRME PROJESİ olarak geliştirilmiştir.

## ÖZELLİKLER

* **Kullanıcı Kimlik Doğrulama**: GÜVENLİ KAYIT ve GİRİŞ işlemleri.
* **Müzik Keşfi**: YENİ ÇIKAN parçaları ana sayfada keşfedin.
* **Kapsamlı Arama**: ŞARKILARI, SANATÇILARI, KULLANICILARI ve ÇALMA LİSTELERİNİ kolayca arayın.
* **Kişisel Kütüphane**: BEĞENİLEN ŞARKILARA ve oluşturulan ÇALMA LİSTELERİNE hızlı erişim sağlayın.
* **Çalma Listesi Yönetimi**:
    * KENDİ ÇALMA LİSTELERİNİZİ oluşturun, düzenleyin ve silin.
    * ÇALMA LİSTELERİNİZE ŞARKI EKLEYİN veya çıkarın.
* **Şarkı Yükleme**: KENDİ MP3 dosyalarınızı ve KAPAK RESİMLERİNİ yükleyerek uygulamanın müzik kütüphanesine katkıda bulunun.
* **Gelişmiş Müzik Çalar**:
    * Oynatma, duraklatma, ileri/geri sarma, sonraki/önceki şarkıya geçiş.
    * Karıştırma (shuffle) ve tekrar (repeat) modları.
    * Ses kontrolü.
    * Çalmakta olan şarkının sanatçısı, başlığı ve kapak görseli gösterimi.
* **Beğenilen Şarkılar**: FAVORİ PARÇALARINIZI beğenin ve kolayca erişin.
* **Kullanıcı Profilleri**: KENDİ PROFİLİNİZİ görüntüleyin ve düzenleyin; diğer kullanıcıların HERKESE AÇIK PROFİLLERİNİ ve çalma listelerini keşfedin.
* **Kişiselleştirme**: AÇIK ve KOYU TEMA seçenekleri arasında geçiş yapın.

## TAKIM ÜYELERİ

* 211216066 - **Batuhan Yeniocak**

## DEMO VİDEOSU

[![Proje Tanıtım Videosu](https://img.youtube.com/vi/WBerQH3lGwY/hqdefault.jpg)](https://www.youtube.com/watch?v=WBerQH3lGwY)


## KULLANILAN TEKNOLOJİLER

* **Flutter**: MOBİL ve WEB için GÜZEL, YEREL olarak derlenmiş uygulamalar oluşturmak için kullanılan UI ARAÇ TAKIMI.
* **Firebase**:
    * **Firestore**: GERÇEK ZAMANLI VERİ SENKRONİZASYONU ve depolama için NoSQL VERİTABANI.
    * **Firebase Authentication**: KULLANICI KİMLİK DOĞRULAMA HİZMETİ.
    * **Firebase Storage**: Ses dosyaları ve resimler gibi KULLANICI TARAFINDAN YÜKLENEN MEDYA dosyalarını depolamak için.
* **just_audio**: ÇEŞİTLİ SES KAYNAKLARINI çalmak için GÜÇLÜ bir ses çalar eklentisi.
* **just_audio_background**: `just_audio` için ARKA PLANDA OYNATMA yetenekleri sağlayan bir eklenti.
* **cached_network_image**: AĞDAN GÖRSELLERİ getirip ÖNBELLEĞE alarak daha HIZLI YÜKLEME sağlayan bir Flutter paketi.
* **file_picker**: CİHAZDAN DOSYA SEÇMEK için kullanılan bir Flutter paketi (MP3 ve kapak görselleri yüklemek için).
* **provider**: Uygulama genelinde DURUM YÖNETİMİ için BASİT ama GÜÇLÜ bir çözüm.
* **rxdart**: DART için REAKTİF PROGRAMLAMA uzantıları.
* **uuid**: BENZERSİZ ID'ler oluşturmak için kullanılan bir Dart paketi.
* **shared_preferences**: BASİT ANAHTAR-DEĞER ÇİFTLERİNİ YEREL olarak depolamak için kullanılan bir Flutter paketi.

## KURULUM

PROJEYİ YEREL MAKİNENİZDE kurmak ve çalıştırmak için aşağıdaki adımları izleyin:

1.  **FLUTTER SDK'YI YÜKLEYİN**: EĞER FLUTTER'I yüklü değilse, [RESMİ FLUTTER WEB SİTESİNDEN](https://flutter.dev/docs/get-started/install) yükleyin.

2.  **DEPOYU KLONLAYIN**:
    ```bash
    git clone https://github.com/batuhanyeniocak/Echowolke
    cd Echowolke
    ```


3.  **BAĞIMLILIKLARI YÜKLEYİN**:
    ```bash
    flutter pub get
    ```

4.  **UYGULAMAYI ÇALIŞTIRIN**:
    ```bash
    flutter run
    ```

## KULLANIM

UYGULAMA başlatıldıktan sonra, kullanıcıların BİR HESAP OLUŞTURMASI veya MEVCUT BİR HESAPLA GİRİŞ YAPMASI gerekecektir. GİRİŞ YAPTIKTAN sonra şunları yapabilirsiniz:

* ANA SAYFADAKİ YENİ ÇIKANLARA göz atın.
* ARAMA ÇUBUĞUNU kullanarak belirli şarkıları, sanatçıları, kullanıcıları veya çalma listelerini bulun.
* KÜTÜPHANENİZDE KENDİ ÇALMA LİSTELERİNİZİ oluşturun ve yönetin.
* BEĞENDİĞİNİZ ŞARKILARI favorilerinize ekleyin.
* "ŞARKI EKLE" bölümünden KENDİ MÜZİKLERİNİZİ yükleyin.
* HERHANGİ BİR ŞARKIYA dokunarak MÜZİK ÇALARI açın ve daha fazla kontrolle dinleyin.


## LİSANS

BU PROJE AÇIK KAYNAKLIDIR ve MIT LİSANSI altında mevcuttur. DAHA FAZLA BİLGİ İÇİN `LICENSE` dosyasına bakın.

---

## İLETİŞİM

* **211216066@stu.istinye.edu.tr**

**Geliştirici Notu**: BU BİR BİTİRME PROJESİDİR.
