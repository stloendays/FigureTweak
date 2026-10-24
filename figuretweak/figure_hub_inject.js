// Added by figure_hub.py to the editor page: which paper is open, a way back to the paper list, and the heartbeat
// that keeps the server running while a window is open.
(async () => {
  const st = await fetch("/hub/papers").then(r => r.json()).catch(() => ({}));
  const cur = st.current;
  const css = document.createElement("style");
  css.textContent = `
    .hubPaper { display:inline-flex; align-items:center; gap:8px; padding:3px 12px 3px 8px; border:1px solid var(--line);
                border-radius:16px; background:#fff; cursor:pointer; max-width:420px; }
    .hubPaper:hover { border-color:var(--blue); background:var(--tint); }
    .hubPaper svg { flex:none; }
    .hubPaper b { white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
    .hubPaper span { white-space:nowrap; overflow:hidden; text-overflow:ellipsis; color:var(--blue-d); font-size:12px; }`;
  document.head.appendChild(css);
  const b = document.createElement("button");
  b.className = "hubPaper";
  b.title = cur ? "当前论文：" + cur.paper + "\n版本：" + cur.name + (cur.branch ? "（" + cur.branch + "）" : "")
                 + "\n" + cur.top + "\n\n点击回到论文列表" : "回到论文列表";
  b.innerHTML = `<svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.6">
      <path d="M10 3 5 8l5 5"/></svg><b></b><span></span>`;
  b.querySelector("b").textContent = cur ? cur.paper : "论文列表";
  b.querySelector("span").textContent = cur ? (cur.branch || cur.name) : "";
  b.onclick = () => { location.href = "/"; };
  const brand = document.querySelector("header .brand");
  if (brand) brand.after(b); else document.body.prepend(b);
  const beat = () => navigator.sendBeacon("/hub/beat");
  beat(); setInterval(beat, 15000);
  document.addEventListener("visibilitychange", () => { if (!document.hidden) beat(); });
  window.addEventListener("pagehide", () => navigator.sendBeacon("/hub/bye"));
})();
