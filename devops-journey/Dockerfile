# =====================================================================
# Dockerfile — تحزيم الموقع في image جاهزة للتشغيل في أي مكان
# المشكلة: "شغال عندي بس مش على السيرفر" ← الحل: نحزّم كل حاجة مع بعض
# =====================================================================

# nginx-unprivileged: نسخة رسمية من nginx بتشتغل بـ non-root user أصلاً
# وبتسمع على بورت 8080 (البورتات تحت 1024 محتاجة root).
# ثبّتنا version محدد (مش latest) عشان الـ build يبقى reproducible.
FROM nginxinc/nginx-unprivileged:1.27-alpine

# نمسح الصفحة الافتراضية بتاعة nginx
# (بنتحول لـ root مؤقتاً للمسح ونرجع بعدها non-root)
USER root
RUN rm -rf /usr/share/nginx/html/*

# ننسخ ملفات الموقع + إعدادات nginx بتاعتنا
COPY app/ /usr/share/nginx/html/
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# الأمان (Least Privilege): التطبيق مايشتغلش root.
# لو حد استغل ثغرة جوه الـ container مش هيبقى معاه root.
USER 101

# توثيق البورت (مش بيفتحه فعلياً، الفتح بيحصل في -p أو في Service)
EXPOSE 8080

# HEALTHCHECK: Docker نفسه يعرف هل التطبيق سليم ولا لأ
# (Kubernetes بيستخدم probes بدل ده، بس مفيد مع docker/compose)
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -q --spider http://localhost:8080/health.json || exit 1

# daemon off عشان nginx يفضل في الـ foreground (الـ container يعيش طالما العملية عايشة)
CMD ["nginx", "-g", "daemon off;"]
