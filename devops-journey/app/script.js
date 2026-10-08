// ===== Footer year =====
document.getElementById("year").textContent = new Date().getFullYear();

// ===== Tools list (content data) =====
const tools = [
  { name: "Docker", desc: "تحزيم التطبيق في container واحد يشتغل بنفس الشكل في أي مكان." },
  { name: "Terraform", desc: "بناء الـ Infrastructure كـ كود، قابل للتكرار والمراجعة." },
  { name: "GitHub Actions / Jenkins", desc: "أتمتة الـ Build والـ Test والـ Deploy." },
  { name: "Kubernetes", desc: "تشغيل الـ containers وإدارتها، وإعادة تشغيلها تلقائياً لو وقعت." },
  { name: "Prometheus + Grafana", desc: "مراقبة الأداء واكتشاف المشاكل قبل ما تكبر." },
  { name: "Trivy / Gitleaks", desc: "فحص أمان الـ images والكود قبل الوصول للـ Production." },
];

const list = document.getElementById("toolsList");
tools.forEach(t => {
  const li = document.createElement("li");
  li.innerHTML = `<b>${t.name}</b> — ${t.desc}`;
  list.appendChild(li);
});

// ===== Health check button =====
const btn = document.getElementById("checkStatusBtn");
const dot = document.getElementById("statusDot");
const text = document.getElementById("statusText");

btn.addEventListener("click", async () => {
  text.textContent = "جاري التحقق...";
  dot.className = "dot";

  try {
    // لاحقاً هنستبدل ده بمسار حقيقي زي /health من باك إند Flask/Node
    // أو endpoint بيرجعه الـ Kubernetes Liveness Probe
    const res = await fetch("health.json", { cache: "no-store" });
    if (!res.ok) throw new Error("Bad response");
    const data = await res.json();

    dot.className = "dot up";
    text.textContent = `Status: ${data.status} — uptime: ${data.uptime}`;
  } catch (err) {
    dot.className = "dot down";
    text.textContent = "السيرفر مش راد (Down) أو الملف مش موجود";
  }
});
