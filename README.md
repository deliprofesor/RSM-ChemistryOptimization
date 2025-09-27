# Yüzey Kimyası Optimizasyonu için Tepki Yüzeyi Metodolojisi (RSM) Uygulaması

Bu proje, dört ana sürecin (TON, TOFF, SV, IP) Yüzey Kimyası (SC) üzerindeki etkileşimlerini analiz etmek ve SC'yi maksimize eden optimum çalışma koşullarını belirlemek için **Tepki Yüzeyi Metodolojisi (RSM)** kullanılarak yapılan istatistiksel modelleme çalışmasını kapsamaktadır.

---

##  Projenin Amacı

- **Model Geliştirme:** SC yanıtı ile süreç değişkenleri (TON, TOFF, SV, IP) arasındaki ilişkiyi, Birinci Derece (FO) ve İki Yönlü Etkileşim (TWI) terimlerini içeren bir matematiksel modelle tanımlamak.  
- **Optimizasyon:** Yüzey Kimyası (SC) değerini en yüksek seviyeye çıkaracak optimum kodlanmış ve kodlanmamış (orijinal) süreç değişkeni değerlerini belirlemek.  
- **Model Doğrulama:** Geliştirilen modelin istatistiksel varsayımlarını (normallik, varyans homojenliği) kontrol etmek ve aykırı/etkili gözlemleri tespit edip temizlemek.  
- **Görselleştirme:** Elde edilen tepki yüzeylerini 2D kontur ve 3D grafiklerle görselleştirerek değişkenlerin SC üzerindeki etkileşimini anlaşılır kılmak.

---

##  Kullanılan Yöntem ve Veri Analizi

### 1. Veri Hazırlığı ve Dönüşüm
- SC yanıtı için pozitiflik kontrolü yapıldı: `any(data$SC <= 0)`.  
- Modelin varsayımlarını daha iyi sağlamak ve verinin dağılımını normalleştirmek amacıyla **yanıt değişkeni olarak doğal logaritma dönüşümü** uygulandı: `log(SC)`. (Box-Cox eğrisi ile desteklenmiştir)  
- Tüm tahmin edici değişkenler (TON, TOFF, SV, IP) **standart sapmaya dayalı kodlanmış** değerlere dönüştürüldü (merkezlenmiş ve ölçeklenmiş).

### 2. İstatistiksel Modelleme (RSM)
- Model denklemi:  

\[
\log(SC) \sim \beta_0 + \sum \beta_i x_i + \sum \sum \beta_{ij} x_i x_j
\]  

- Model, `rsm` paketi ile oluşturuldu ve anlamlılık için `summary(model)` ile **ANOVA** ve katsayı tabloları incelendi.

### 3. Tanısal Kontrol ve Aykırı Değer Temizliği
- Artık grafikler ve **Cook's Distance** grafikleri incelendi.  
- Q-Q Residuals grafiği, artıklarda hafif bir sapma olduğunu gösterdi.  
- Residuals vs Fitted ve Scale-Location grafikleri, varyans homojenliği varsayımında hafif bir ihlal olduğunu gösterdi.  
- `∣Studentized Residuals∣ > 2` olan gözlemler **aykırı değer** olarak tespit edildi ve modelden çıkarıldı.  
- Aykırı değerler çıkarıldıktan sonra model (`model_no_out`) yeniden incelendi.

### 4. Kanonik Analiz ve Optimizasyon
- Temizlenmiş model için `canonical()` fonksiyonu ile kanonik analiz yapıldı.  
- Analiz sonucunda **istasyonel nokta (optimum)**, kodlanmış ve orijinal değişkenler cinsinden hesaplandı.

---

##  Temel Bulgular ve Çıktılar

### 1. Optimizasyon Sonuçları
| Değişken | Kodlanmış Optimum Değer | Orijinal (Kodlanmamış) Optimum Değer |
|----------|------------------------|-------------------------------------|
| TON      | TON.c_opt              | TON_opt                             |
| TOFF     | TOFF.c_opt             | TOFF_opt                            |
| SV       | SV.c_opt               | SV_opt                              |
| IP       | IP.c_opt               | IP_opt                              |

> Not: Sayısal değerler proje çıktılarında (`stationary_uncoded`) verilmiştir. Bu değerler SC'yi maksimize eden süreç koşullarını göstermektedir.

### 2. Görselleştirme (Contour ve 3D Plot)
- **Kontur Grafiği:** TON ve TOFF değişkenlerinin SC üzerindeki birlikte etkisi gösterilir.  
  - Renkler, `log(SC)` değerlerini temsil eder (Mor → En Yüksek SC, Sarı/Yeşil → En Düşük SC).  
  - Optimum nokta kırmızı ile işaretlenmiştir.  
- **3D Yüzey Grafiği:** Tepki yüzeyinin fiziksel şeklini anlamaya yardımcı olur.  
  - Yüzeydeki eğrilik, değişkenlerin etkileşimlerini sezgisel olarak gösterir.

### 3. Modelin Güçlenmesi
- Aykırı değerlerin çıkarılması, modelin istatistiksel gücünü artırdı.  
- Cook's Distance grafiği ile kalan gözlemlerin model üzerindeki etkisi kontrol altına alındı.

---

##  Sonuç
Bu çalışma, Yüzey Kimyası (SC) yanıtını kontrol eden karmaşık etkileşimleri **RSM** ile başarıyla modellemiştir.  
Belirlenen optimum koşullar:

\[
TON_{opt}, TOFF_{opt}, SV_{opt}, IP_{opt}
\]

süreç parametrelerinin SC'yi maksimize etmek için hangi seviyelerde ayarlanması gerektiğini bilimsel ve pratik olarak göstermektedir.

---

## Kurulum ve Kullanım

### Gereken R Paketleri
```r
install.packages(c("rsm","readxl","ggplot2","dplyr","MASS"))
library(rsm)
library(readxl)
library(ggplot2)
library(dplyr)
library(MASS)
