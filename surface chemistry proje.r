# Gerekli paketleri yükle
install.packages("rsm")     # Response Surface Methodology paketi
install.packages("readxl")  # Excel dosyası okumak için
install.packages("ggplot2") # Grafikler için
install.packages("dplyr")   # Veri işlemleri için


# Kütüphaneleri yükle
library(rsm)
library(readxl)
library(ggplot2)
library(dplyr)

# Excel dosyasını oku (yolu sizin sisteminize göre değiştirin)
data <- read_excel("Surface Chemistry.xlsx", sheet = "SC")

# İlk birkaç satırı gözlemleyin
head(data)

# Kodlanmış veri seti oluştur (normalize edilmiş değişkenler)
coded_data <- coded.data(data,
                         TON.c ~ TON,
                         TOFF.c ~ TOFF,
                         SV.c ~ SV,
                         IP.c ~ IP)

model <- rsm(log(SC) ~ SO(TON.c, TOFF.c, SV.c, IP.c), data = coded_data)

# Model özetini yazdır
summary(model)

# TON ve TOFF için contour ve yüzey grafiği
par(mfrow = c(1, 2))
contour(model, ~ TON.c + TOFF.c, image = TRUE)
persp(model, ~ TON.c + TOFF.c, zlab = "SC", col = "lightblue", expand = 0.5)

# contour(model, ~ SV.c + IP.c, image = TRUE)
# persp(model, ~ SV.c + IP.c, zlab = "SC", col = "lightgreen", expand = 0.5)

# Model tanı grafikleri
par(mfrow = c(2, 2))
plot(model)

# Canonical analiz – optimum nokta ve yüzey tipi
canonical(model)
