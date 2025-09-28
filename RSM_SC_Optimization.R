# ==============================================================================
# PROJE: Yüzey Kimyası Optimizasyonu 
# Açıklama: Bu kod, SC (Surface Chemistry) üzerinde FO ve TWI modelini kurar,
# aykırı gözlemleri temizler, canonical analiz ile optimum noktayı belirler ve
# tüm tanısal, Box-Cox, Cook's Distance, contour ve 3D grafiklerini üretir.
# ==============================================================================
# 1. Gerekli Paketler
# install.packages(c("rsm","readxl","ggplot2","dplyr","MASS"))
library(rsm)
library(readxl)
library(ggplot2)
library(dplyr)
library(MASS)

# ======================
# 2. Veri Okuma ve Kontrol
# ======================
data <- read_excel("Surface Chemistry.xlsx", sheet = "SC")
colnames(data) <- make.names(trimws(colnames(data)))  # boşluk ve özel karakterleri temizle

# SC sütununda 0 veya negatif değer olmadığını kontrol et
if(any(data$SC <= 0)) stop("SC sütununda log alınamayacak değerler var!")

# ======================
# 3. Kodlanmış Veri Seti
# ======================
# rsm standardına uygun olarak veri kodlama (ortalama=0, sd=1)
# Burada manuel formül ile coding yapıyoruz
coded_data <- coded.data(data,
                         TON.c  ~ (TON - mean(data$TON)) / sd(data$TON),
                         TOFF.c ~ (TOFF - mean(data$TOFF)) / sd(data$TOFF),
                         SV.c   ~ (SV - mean(data$SV)) / sd(data$SV),
                         IP.c   ~ (IP - mean(data$IP)) / sd(data$IP))

# ======================
# 4. FO + TWI Modeli Kurulumu
# ======================
model <- rsm(log(SC) ~ FO(TON.c, TOFF.c, SV.c, IP.c) +
                            TWI(TON.c, TOFF.c, SV.c, IP.c),
             data = coded_data)

# Model özeti
summary(model)

# ======================
# 5. Tanısal Grafikleri Üretme (İlk Model)
# ======================
png("1_Model_Diagnostics_Initial.png", width=1200, height=1200)
par(mfrow=c(2,2))
plot(model)
dev.off()

# ======================
# 6. Aykırı Değerleri Belirleme
# ======================
outliers <- which(abs(rstudent(model)) > 2)

cat("Aykırı gözlemler: ", outliers, "\n")
# ======================
# 7. Aykırı Gözlemleri Çıkarıp Temiz Model Kurulumu
# ======================
data_no_out <- coded_data[-outliers, ]
model_no_out <- rsm(log(SC) ~ FO(TON.c, TOFF.c, SV.c, IP.c) +
                                  TWI(TON.c, TOFF.c, SV.c, IP.c),
                    data = data_no_out)
summary(model_no_out)

# ======================
# 8. Canonical Analiz ile Optimum Nokta
# ======================
can_out_no <- canonical(model_no_out)
stationary_coded <- can_out_no$xs  # Kodlanmış optimum noktalar (vektör)
# Orijinal ölçekte dönüşüm
means <- colMeans(data[, c("TON","TOFF","SV","IP")])
sds   <- apply(data[, c("TON","TOFF","SV","IP")], 2, sd)
stationary_uncoded <- stationary_coded * sds + means

cat("Kodlanmış optimum noktalar:\n")
print(stationary_coded)
cat("Orijinal ölçekte optimum noktalar:\n")
print(stationary_uncoded)

# ======================
# 9. Box-Cox ve Cook's Distance Grafikleri
# ======================
# Cook's Distance
png("2_CooksDistance_Initial.png", width=800, height=600)
cooksd <- cooks.distance(model_no_out)
plot(cooksd, type="h", main="Cook's Distance - Cleaned Model",
     ylab="Cook's Distance", xlab="Gözlem Numarası")
abline(h = 4/(nrow(data_no_out)-length(model_no_out$coefficients)-2), col="red", lty=2)
dev.off()

# Box-Cox
png("3_BoxCox_Cleaned.png", width=800, height=600)
boxcox(model_no_out, lambda = seq(-1,2,0.1),
       main="Box-Cox Dönüşümü - Temizlenmiş Model")
dev.off()

# ======================
# 10. Contour Plot (TON vs TOFF, SV ve IP sabit)
# ======================
TON_seq <- seq(min(coded_data$TON.c), max(coded_data$TON.c), length=30)
TOFF_seq <- seq(min(coded_data$TOFF.c), max(coded_data$TOFF.c), length=30)

SV_fixed <- stationary_coded["SV.c"]
IP_fixed <- stationary_coded["IP.c"]

grid <- expand.grid(TON.c = TON_seq, TOFF.c = TOFF_seq)
grid$SV.c <- SV_fixed
grid$IP.c <- IP_fixed

# Tahmin
grid$SC_pred_log <- predict(model_no_out, newdata = grid)
grid$SC_pred <- exp(grid$SC_pred_log)

# Contour log(SC)
p1 <- ggplot(grid, aes(x=TON.c, y=TOFF.c, z=SC_pred_log)) +
  geom_contour_filled(aes(fill = after_stat(level))) +
  geom_point(aes(x=stationary_coded["TON.c"], y=stationary_coded["TOFF.c"]),
             color="red", size=3) +
  labs(title="Contour Plot (log(SC))",
       x="TON (coded)", y="TOFF (coded)", fill="log(SC)") +
  theme_minimal()
ggsave("4_Contour_LogSC.png", plot=p1, width=8, height=6)

# Contour SC (orijinal ölçekte)
p2 <- ggplot(grid, aes(x=TON.c, y=TOFF.c, z=SC_pred)) +
  geom_contour_filled(aes(fill = after_stat(level))) +
  geom_point(aes(x=stationary_coded["TON.c"], y=stationary_coded["TOFF.c"]),
             color="red", size=3) +
  labs(title="Contour Plot (SC - Original Scale)",
       x="TON (coded)", y="TOFF (coded)", fill="SC") +
  theme_minimal()
ggsave("5_Contour_SC.png", plot=p2, width=8, height=6)

# ======================
# 11. 3D Yüzey Grafiği (persp)
# ======================
z_matrix_log <- matrix(grid$SC_pred_log, nrow=length(TON_seq), byrow=TRUE)
z_matrix <- matrix(grid$SC_pred, nrow=length(TON_seq), byrow=TRUE)

# 3D log(SC)
png("6_3D_LogSC.png", width=800, height=600)
persp(x=TON_seq, y=TOFF_seq, z=z_matrix_log,
      xlab="TON (coded)", ylab="TOFF (coded)", zlab="log(SC)",
      main="3D Surface Plot (log(SC))", col="lightblue",
      theta=30, phi=30, ticktype="detailed")
dev.off()

# 3D SC
png("7_3D_SC.png", width=800, height=600)
persp(x=TON_seq, y=TOFF_seq, z=z_matrix,
      xlab="TON (coded)", ylab="TOFF (coded)", zlab="SC",
      main="3D Surface Plot (SC - Original Scale)", col="lightgreen",
      theta=30, phi=30, ticktype="detailed")
dev.off()

# ======================
# 12. Temiz Model Tanısal Grafikleri
# ======================
png("8_Model_Diagnostics_Cleaned.png", width=1200, height=1200)
par(mfrow=c(2,2))
plot(model_no_out)
dev.off()

cat("\n!!! TÜM GRAFİKLER BAŞARIYLA OLUŞTURULDU VE KAYDEDİLDİ !!!\n")
