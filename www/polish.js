/* Decorative presentation only: no Shiny inputs, datasets, or chart widgets. */
(() => {
  "use strict";
  function initialize() {
    const root = document.querySelector(".about-page");
    if (!root) return;
    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
    let paused = false;
    const motionStopped = () => reducedMotion.matches || paused;
    const motionListeners = [];
    const toggle = document.createElement("button");
    toggle.type = "button";
    toggle.className = "motion-toggle";
    function syncToggle() {
      const label = paused ? "Resume decorative animations" : "Pause decorative animations";
      toggle.setAttribute("aria-label", label);
      toggle.setAttribute("title", label);
      toggle.setAttribute("aria-pressed", String(paused));
      toggle.classList.toggle("is-paused", paused);
      document.documentElement.classList.toggle("decorations-paused", motionStopped());
    }
    toggle.addEventListener("click", () => {
      paused = !paused;
      syncToggle();
      motionListeners.forEach(update => update());
    });
    document.querySelector(".navbar-brand")?.insertAdjacentElement("afterend", toggle);
    reducedMotion.addEventListener("change", () => {
      syncToggle();
      motionListeners.forEach(update => update());
    });
    syncToggle();

    // Progressive enhancement: content remains visible if animation is unavailable.
    if ("IntersectionObserver" in window && Element.prototype.animate) {
      const reveals = new IntersectionObserver(entries => {
        entries.forEach(entry => {
          if (!entry.isIntersecting) return;
          reveals.unobserve(entry.target);
          if (!reducedMotion.matches) {
            entry.target.animate([
              { opacity: 0, transform: "translateY(24px)" },
              { opacity: 1, transform: "translateY(0)" }
            ], { duration: 750, easing: "cubic-bezier(.2,.7,.2,1)" });
          }
        });
      }, { threshold: 0.08 });
      const revealTargets = document.querySelectorAll(
        ".about-hero-copy, .about-overview, .about-feature, .about-contents, .about-insights, .about-publications, " +
        ".site-page .page-heading, .models-page .model-card, .models-page .model-resources, .news-page .feature-card"
      );
      revealTargets.forEach(element => reveals.observe(element));
      reducedMotion.addEventListener("change", () => {
        if (reducedMotion.matches) revealTargets.forEach(element => {
          element.getAnimations().forEach(animation => animation.cancel());
        });
      });
    }

    // Non-data illustrations live only in headers, never inside analytical widgets.
    function decorate(host, type) {
      if (!host) return;
      const visual = document.createElement("canvas");
      visual.className = "header-sculpture";
      visual.setAttribute("aria-hidden", "true");
      host.classList.add("has-sculpture");
      host.appendChild(visual);
      const context = visual.getContext("2d");
      if (!context) return;
      let w = 0, h = 0, angle = 0, request = 0, last = null, onScreen = false;
      function paint() {
        if (!w || !h) return;
        context.clearRect(0, 0, w, h);
        const radius = Math.min(w, h) * 0.39;
        const nodes = [];
        if (type === "ribbon") {
          for (let row = 0; row < 12; row++) {
            context.beginPath();
            for (let i = 0; i <= 80; i++) {
              const x = i / 80 * w;
              const y = h * .5 + (row - 5.5) * h * .047 + Math.sin(i / 80 * 6 + angle + row * .14) * h * .16;
              if (i === 0) context.moveTo(x, y); else context.lineTo(x, y);
            }
            context.strokeStyle = `rgba(70,130,195,${.15 + row * .035})`;
            context.lineWidth = 1; context.stroke();
          }
          return;
        }
        for (let ring = 0; ring < 9; ring++) {
          const latitude = (ring / 8 - .5) * Math.PI * .88;
          context.beginPath();
          for (let i = 0; i <= 64; i++) {
            const t = i / 64 * Math.PI * 2 + angle;
            const x = Math.cos(t) * Math.cos(latitude);
            const y = Math.sin(latitude);
            const z = Math.sin(t) * Math.cos(latitude);
            const px = w / 2 + (x * .89 - y * .45) * radius;
            const py = h / 2 + (y * .76 + x * .25 + z * .45) * radius;
            if (i === 0) context.moveTo(px, py); else context.lineTo(px, py);
            if (i % 8 === 0) nodes.push({ x: px, y: py, z });
          }
          context.strokeStyle = type === "network" ? "rgba(70,120,180,.25)" : "rgba(70,130,195,.3)";
          context.lineWidth = .8; context.stroke();
        }
        nodes.sort((a, b) => a.z - b.z).forEach(p => {
          context.beginPath(); context.arc(p.x, p.y, 1 + (p.z + 1) * .85, 0, Math.PI * 2);
          context.fillStyle = `rgba(47,111,179,${.25 + (p.z + 1) * .32})`; context.fill();
        });
      }
      function resizeArt() {
        const bounds = visual.getBoundingClientRect(); w = bounds.width; h = bounds.height;
        const scale = Math.min(window.devicePixelRatio || 1, 2);
        visual.width = Math.round(w * scale); visual.height = Math.round(h * scale);
        context.setTransform(scale, 0, 0, scale, 0, 0); paint();
      }
      function step(time) {
        request = 0;
        if (!onScreen || document.hidden || motionStopped()) { last = null; return; }
        if (last !== null) angle = (angle + Math.min(time - last, 60) * .0003) % (Math.PI * 2);
        last = time; paint(); request = requestAnimationFrame(step);
      }
      function update() {
        if (request) cancelAnimationFrame(request);
        request = 0; last = null;
        if (onScreen && !document.hidden && !motionStopped()) request = requestAnimationFrame(step);
        else paint();
      }
      motionListeners.push(update);
      if ("ResizeObserver" in window) new ResizeObserver(resizeArt).observe(visual);
      else window.addEventListener("resize", resizeArt, { passive: true });
      if ("IntersectionObserver" in window) new IntersectionObserver(entries => {
        onScreen = entries[0].isIntersecting; update();
      }).observe(visual);
      else onScreen = true;
      document.addEventListener("visibilitychange", update);
      resizeArt(); update();
    }
    decorate(document.querySelector(".models-page .page-heading"), "sphere");
    decorate(document.querySelector(".news-page .page-heading"), "ribbon");
    decorate(document.querySelector(".dataset-results > h2"), "network");
    document.querySelectorAll(".entry-page .feature-card > h2").forEach(host => decorate(host, "ribbon"));

    const canvas = document.getElementById("about-dna-canvas");
    const ctx = canvas && canvas.getContext("2d");
    if (!ctx) return; // The static SVG background is the fallback.
    const art = canvas.parentElement;
    let width = 0, height = 0, phase = 0.7, clock = 0, frame = 0;
    let visible = false, lastTime = null;
    const tilt = -0.34;
    const font = "Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif";

    // CpG dinucleotides sit on selected base-pair rungs. Methylation is
    // symmetric, so each site carries a 5mC on both strands.
    const cpgSites = new Map();
    for (let i = 3; i <= 90; i += 3) {
      if ((i * 7) % 11 < 5) cpgSites.set(i, { seed: (i * 2.39996) % (Math.PI * 2) });
    }
    // Slow write/erase cycle (DNMT adds, TET removes): 0 = unmethylated, 1 = 5mC.
    function methylation(site) {
      const wave = Math.sin(clock * 0.35 + site.seed);
      return Math.min(1, Math.max(0, (wave + 0.7) / 0.7));
    }

    function point(index, strand) {
      const t = index / 92;
      const angle = t * Math.PI * 4.2 + phase + strand * Math.PI;
      const depth = Math.cos(angle);
      const x = Math.sin(angle) * width * 0.19;
      const y = (t - 0.5) * height * 0.82;
      return {
        x: width * 0.51 + x * Math.cos(tilt) - y * Math.sin(tilt),
        y: height * 0.49 + x * Math.sin(tilt) + y * Math.cos(tilt),
        angle,
        depth,
        r: 2 + (depth + 1) * 1.7
      };
    }

    function drawNode(p) {
      const opacity = 0.25 + (p.depth + 1) * 0.35;
      ctx.beginPath(); ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
      ctx.fillStyle = `rgba(${p.strand ? "60,125,195" : "110,130,215"},${opacity})`;
      ctx.shadowColor = p.strand ? "#9cc6ee" : "#b9c8f2";
      ctx.shadowBlur = p.depth > 0.5 ? 12 : 0;
      ctx.fill(); ctx.shadowBlur = 0;
    }

    // A methyl group branches outward from the cytosine; unmethylated CpGs
    // show an open ring instead. Levels between 0 and 1 cross-fade the two.
    function drawMethyl(p) {
      const level = p.level;
      const alpha = 0.3 + (p.depth + 1) * 0.35;
      const side = Math.sin(p.angle) >= 0 ? 1 : -1;
      const reach = (7 + Math.abs(Math.sin(p.angle)) * 9) * (0.35 + level * 0.65);
      const mx = p.x + side * Math.cos(tilt) * reach;
      const my = p.y + side * Math.sin(tilt) * reach;
      if (level < 0.98) {
        ctx.beginPath(); ctx.arc(p.x, p.y, p.r + 3, 0, Math.PI * 2);
        ctx.strokeStyle = `rgba(70,120,180,${alpha * (1 - level) * 0.9})`;
        ctx.lineWidth = 1.2; ctx.stroke();
      }
      if (level > 0.02) {
        ctx.beginPath(); ctx.moveTo(p.x, p.y); ctx.lineTo(mx, my);
        ctx.strokeStyle = `rgba(214,80,135,${alpha * level * 0.8})`;
        ctx.lineWidth = 1.3; ctx.stroke();
        ctx.beginPath(); ctx.arc(mx, my, (1.8 + level * 2.4) * (0.75 + (p.depth + 1) * 0.2), 0, Math.PI * 2);
        ctx.fillStyle = `rgba(214,80,135,${alpha * level})`;
        ctx.shadowColor = "#f2b6cc";
        ctx.shadowBlur = 6 + level * 10;
        ctx.fill(); ctx.shadowBlur = 0;
        if (level > 0.75 && p.depth > 0.35 && width > 320) {
          ctx.font = `600 9px ${font}`;
          ctx.textAlign = side > 0 ? "left" : "right";
          ctx.textBaseline = "middle";
          ctx.fillStyle = `rgba(230,240,252,${(level - 0.75) * 4 * (p.depth - 0.35) * 1.3})`;
          ctx.fillText("CH₃", mx + side * 7, my);
        }
      }
    }

    function drawLegend() {
      if (width < 280) return;
      const x = 14, y = height - 18;
      ctx.font = `500 10px ${font}`;
      ctx.textAlign = "left"; ctx.textBaseline = "middle";
      ctx.beginPath(); ctx.arc(x, y - 16, 3.5, 0, Math.PI * 2);
      ctx.fillStyle = "rgba(214,80,135,.95)"; ctx.shadowColor = "#f2b6cc"; ctx.shadowBlur = 8;
      ctx.fill(); ctx.shadowBlur = 0;
      ctx.fillStyle = "rgba(230,240,252,.85)";
      ctx.fillText("5mC · methylated CpG", x + 11, y - 16);
      ctx.beginPath(); ctx.arc(x, y, 3.5, 0, Math.PI * 2);
      ctx.strokeStyle = "rgba(70,120,180,.9)"; ctx.lineWidth = 1.2; ctx.stroke();
      ctx.fillStyle = "rgba(230,240,252,.85)";
      ctx.fillText("unmethylated CpG", x + 11, y);
    }

    function draw() {
      if (!width || !height) return;
      ctx.clearRect(0, 0, width, height);
      // Small deterministic particles provide atmosphere, never data marks.
      for (let i = 0; i < 32; i++) {
        const x = ((i * 137.508) % 100) / 100 * width;
        const y = ((i * 73.17) % 100) / 100 * height;
        ctx.beginPath();
        ctx.arc(x, y, i % 5 === 0 ? 2 : 0.8, 0, Math.PI * 2);
        ctx.fillStyle = i % 5 === 0 ? "rgba(47,111,179,.45)" : (i % 2 ? "rgba(143,184,234,.4)" : "rgba(111,159,208,.25)");
        ctx.fill();
      }
      // An illustrative methylated helix, not an analytical visualization.
      for (let i = 0; i <= 92; i += 3) {
        const a = point(i, 0), b = point(i, 1);
        const site = cpgSites.get(i);
        const level = site ? methylation(site) : 0;
        const gradient = ctx.createLinearGradient(a.x, a.y, b.x + 0.01, b.y);
        if (site) {
          gradient.addColorStop(0, `rgba(${Math.round(80 - 33 * level)},${Math.round(140 - 29 * level)},${Math.round(205 - 26 * level)},.8)`);
          gradient.addColorStop(0.5, `rgba(150,160,210,${0.18 + level * 0.25})`);
          gradient.addColorStop(1, `rgba(${Math.round(70 - 23 * level)},${Math.round(125 - 14 * level)},${Math.round(195 - 16 * level)},.75)`);
        } else {
          gradient.addColorStop(0, "rgba(90,150,210,.45)");
          gradient.addColorStop(0.5, "rgba(120,150,200,.14)");
          gradient.addColorStop(1, "rgba(90,150,210,.4)");
        }
        ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y);
        ctx.strokeStyle = gradient; ctx.lineWidth = site ? 2 : 1.4; ctx.stroke();
      }
      const marks = [];
      for (let strand = 0; strand < 2; strand++) {
        for (let i = 0; i <= 92; i++) {
          const p = point(i, strand);
          if (i > 0) {
            const previous = point(i - 1, strand);
            ctx.beginPath(); ctx.moveTo(previous.x, previous.y); ctx.lineTo(p.x, p.y);
            ctx.strokeStyle = `rgba(${strand ? "60,125,195" : "110,130,215"},${0.22 + (p.depth + 1) * 0.24})`;
            ctx.lineWidth = 1.7; ctx.stroke();
          }
          const site = cpgSites.get(i);
          if (site) marks.push({ ...p, strand, level: methylation(site), cpg: true });
          else if (i % 2 === 0) marks.push({ ...p, strand });
        }
      }
      marks.sort((a, b) => a.depth - b.depth).forEach(p => {
        drawNode(p);
        if (p.cpg) drawMethyl(p);
      });
      drawLegend();
      art.classList.add("is-rendered");
    }

    function resize() {
      const bounds = art.getBoundingClientRect();
      width = bounds.width; height = bounds.height;
      const scale = Math.min(window.devicePixelRatio || 1, 2);
      canvas.width = Math.round(width * scale); canvas.height = Math.round(height * scale);
      ctx.setTransform(scale, 0, 0, scale, 0, 0);
      draw();
    }
    function tick(time) {
      frame = 0;
      if (!visible || document.hidden || motionStopped()) { lastTime = null; return; }
      if (lastTime !== null) {
        const elapsed = Math.min(time - lastTime, 60);
        phase = (phase + elapsed * 0.0005) % (Math.PI * 2);
        clock += elapsed * 0.001;
      }
      lastTime = time;
      draw();
      frame = requestAnimationFrame(tick);
    }
    function updateMotion() {
      if (frame) cancelAnimationFrame(frame);
      frame = 0;
      lastTime = null;
      if (visible && !document.hidden && !motionStopped()) frame = requestAnimationFrame(tick);
      else draw();
    }
    motionListeners.push(updateMotion);
    if ("ResizeObserver" in window) new ResizeObserver(resize).observe(art);
    else window.addEventListener("resize", resize, { passive: true });
    if ("IntersectionObserver" in window) {
      new IntersectionObserver(entries => {
        visible = entries[0].isIntersecting;
        updateMotion();
      }, { threshold: 0.05 }).observe(art);
    } else { visible = true; }
    document.addEventListener("visibilitychange", updateMotion);
    reducedMotion.addEventListener("change", updateMotion);
    resize(); updateMotion();
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", initialize, { once: true });
  else initialize();
})();

/* Decorative critters: a walking DNA mascot in the masthead and drifting cells
   behind the page. Purely visual; follows the pause button and reduced motion. */
(() => {
  "use strict";
  const SVG_NS = "http://www.w3.org/2000/svg";
  const MASCOT = `
    <svg viewBox="0 0 32 40" width="32" height="40" aria-hidden="true">
      <defs>
        <linearGradient id="mascot-skin-KEY" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="#eef5fc"/><stop offset="1" stop-color="#8fb8ea"/>
        </linearGradient>
        <clipPath id="mascot-clip-KEY"><rect x="6" y="3" width="20" height="26" rx="10"/></clipPath>
      </defs>
      <g class="mascot-leg mascot-leg-l"><path d="M12 27 L12 36" /><path d="M12 36 L9.5 36.5" /></g>
      <g class="mascot-leg mascot-leg-r"><path d="M20 27 L20 36" /><path d="M20 36 L22.5 36.5" /></g>
      <g class="mascot-arm mascot-arm-l"><path d="M6.5 17 L2.5 21" /></g>
      <g class="mascot-arm mascot-arm-r"><path d="M25.5 17 L29.5 21" /></g>
      <rect x="6" y="3" width="20" height="26" rx="10" fill="url(#mascot-skin-KEY)" stroke="#ffffff" stroke-width="1.2"/>
      <g clip-path="url(#mascot-clip-KEY)" fill="none" stroke-width="1.6" stroke-linecap="round">
        <path d="M6 15 C11 19 21 19 26 23 M6 23 C11 27 21 27 26 31" stroke="#d65087" opacity=".75"/>
        <path d="M6 23 C11 19 21 19 26 15 M6 31 C11 27 21 27 26 23" stroke="#2f6fb3" opacity=".75"/>
        <path d="M11 19.5 L11 22.5 M16 19 L16 23 M21 19.5 L21 22.5" stroke="#6f9fd0" stroke-width="1.1" opacity=".7"/>
      </g>
      <g class="mascot-eyes" fill="#10224a">
        <ellipse cx="12.5" cy="10.5" rx="1.6" ry="2.1"/><ellipse cx="19.5" cy="10.5" rx="1.6" ry="2.1"/>
      </g>
      <circle cx="12.9" cy="9.8" r=".55" fill="#fff"/><circle cx="19.9" cy="9.8" r=".55" fill="#fff"/>
      <circle cx="9.8" cy="14" r="1.3" fill="#f2b6cc" opacity=".8"/><circle cx="22.2" cy="14" r="1.3" fill="#f2b6cc" opacity=".8"/>
      <path d="M14.3 13.6 Q16 15.2 17.7 13.6" fill="none" stroke="#10224a" stroke-width="1" stroke-linecap="round"/>
    </svg>`;
  const mascotSvg = key => MASCOT.replaceAll("KEY", key);

  // Welcome card: the mascot greets new visitors once per browser session,
  // then dissolves and hands over to the walking mascot in the masthead.
  const WELCOME_TITLE = "Hi! Welcome to DreamlandDB";
  const WELCOME_TEXT = "Here you can explore predicted DNA methylation across tissues, cancer types and single cells.";
  function welcome(reducedMotion) {
    try { if (sessionStorage.getItem("dreamland-welcomed")) return; } catch (e) { /* storage blocked */ }
    try { sessionStorage.setItem("dreamland-welcomed", "1"); } catch (e) { /* storage blocked */ }
    const card = document.createElement("div");
    card.className = "welcome-card";
    card.setAttribute("role", "status");
    card.setAttribute("aria-live", "polite");
    card.innerHTML = `
      <div class="welcome-mascot" aria-hidden="true">${mascotSvg("welcome")}</div>
      <div class="welcome-bubble">
        <strong class="welcome-title"></strong>
        <p class="welcome-text"></p>
      </div>
      <button type="button" class="welcome-close" aria-label="Close welcome message">×</button>`;
    // A blurred backdrop keeps the focus on the greeting; it clears as the card dissolves.
    const backdrop = document.createElement("div");
    backdrop.className = "welcome-backdrop";
    backdrop.setAttribute("aria-hidden", "true");
    document.body.append(backdrop, card);
    const title = card.querySelector(".welcome-title"), text = card.querySelector(".welcome-text");
    const still = reducedMotion.matches || !Element.prototype.animate;
    let closing = false, typing = 0, timer = 0;

    function dissolve() {
      if (closing) return;
      closing = true;
      clearInterval(typing); clearTimeout(timer);
      title.textContent = WELCOME_TITLE; text.textContent = WELCOME_TEXT;
      if (still) { card.remove(); backdrop.remove(); return; }
      const box = card.getBoundingClientRect();
      for (let i = 0; i < 14; i++) {
        const spark = document.createElement("span");
        spark.className = "welcome-spark";
        spark.style.left = box.left + Math.random() * box.width + "px";
        spark.style.top = box.top + Math.random() * box.height + "px";
        document.body.appendChild(spark);
        spark.animate([
          { opacity: 0, transform: "scale(.4)" },
          { opacity: 1, transform: "scale(1)", offset: .3 },
          { opacity: 0, transform: `translate(${(Math.random() - .5) * 60}px, ${-20 - Math.random() * 50}px) scale(.3)` }
        ], { duration: 900 + Math.random() * 500, delay: Math.random() * 250, easing: "ease-out", fill: "both" })
          .onfinish = () => spark.remove();
      }
      backdrop.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 1100, easing: "ease-in-out", fill: "forwards" })
        .onfinish = () => backdrop.remove();
      card.animate([
        { opacity: 1, filter: "blur(0)", transform: "translate(-50%, -50%) scale(1)" },
        { opacity: 0, filter: "blur(10px)", transform: "translate(-50%, calc(-50% - 16px)) scale(.94)" }
      ], { duration: 900, easing: "ease-in", fill: "forwards" }).onfinish = () => {
        card.remove();
        document.dispatchEvent(new CustomEvent("dreamland:hop"));
      };
    }
    card.addEventListener("click", dissolve);
    backdrop.addEventListener("click", dissolve);

    if (still) {
      title.textContent = WELCOME_TITLE; text.textContent = WELCOME_TEXT;
      timer = setTimeout(dissolve, 6000);
      return;
    }
    backdrop.animate([{ opacity: 0 }, { opacity: 1 }], { duration: 500, easing: "ease-out" });
    card.animate([
      { opacity: 0, transform: "translate(-50%, calc(-50% + 22px)) scale(.8)" },
      { opacity: 1, transform: "translate(-50%, calc(-50% - 4px)) scale(1.03)", offset: .7 },
      { opacity: 1, transform: "translate(-50%, -50%) scale(1)" }
    ], { duration: 650, easing: "cubic-bezier(.2,.8,.3,1.2)" });
    // Type the greeting, then hold it long enough to read before dissolving.
    const full = WELCOME_TITLE + "\n" + WELCOME_TEXT;
    let n = 0;
    setTimeout(() => {
      typing = setInterval(() => {
        n = Math.min(full.length, n + 2);
        const shown = full.slice(0, n).split("\n");
        title.textContent = shown[0]; text.textContent = shown[1] || "";
        if (n >= full.length) { clearInterval(typing); timer = setTimeout(dissolve, 3800); }
      }, 28);
    }, 450);
  }

  function initialize() {
    const root = document.documentElement;
    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
    const stopped = () => reducedMotion.matches || root.classList.contains("decorations-paused");
    welcome(reducedMotion);

    // Drifting cells: CSS animates them; the layer sits behind all content.
    const cells = document.createElement("div");
    cells.className = "bg-cells";
    cells.setAttribute("aria-hidden", "true");
    for (let i = 0; i < 9; i++) {
      const cell = document.createElement("span");
      cell.className = "bg-cell";
      cell.style.setProperty("--i", i);
      cells.appendChild(cell);
    }
    document.body.prepend(cells);

    // The mascot walks along the empty strip under the navigation pill.
    const panel = document.querySelector(".navbar > .container-fluid, .navbar > .container");
    const nav = panel && panel.querySelector(".navbar-nav");
    if (!panel || !nav || !Element.prototype.animate) return;
    const track = document.createElement("div");
    track.className = "mascot-track";
    track.setAttribute("aria-hidden", "true");
    const mascot = document.createElement("div");
    mascot.className = "mascot";
    mascot.innerHTML = `<div class="mascot-hop"><div class="mascot-body">${mascotSvg("walker")}</div></div>`;
    track.appendChild(mascot);
    panel.appendChild(track);
    const hop = mascot.querySelector(".mascot-hop");

    function placeTrack() {
      const p = panel.getBoundingClientRect(), n = nav.getBoundingClientRect();
      track.style.left = Math.max(0, n.left - p.left) + "px";
      track.style.width = Math.max(0, n.width) + "px";
    }

    let x = 40, dir = 1, pauseUntil = 0, nextHop = 0, last = null, frame = 0;
    const speed = 34; // px per second

    // Methylation-themed speech bubbles, with the odd friendly one.
    const puffs = ["CH₃", "5mC", "CpG", "A·T", "G·C", "CH₃", "5mC", "CpG", "♥", "hi!"];
    let lastPuff = "";
    function puff() {
      const bubble = document.createElement("span");
      bubble.className = "mascot-puff";
      let text;
      do { text = puffs[Math.floor(Math.random() * puffs.length)]; } while (text === lastPuff);
      bubble.textContent = lastPuff = text;
      bubble.style.left = (x + 18 + dir * 32) + "px";
      track.appendChild(bubble);
      bubble.animate([
        { opacity: 0, transform: "translate(-50%, 0) scale(.6)" },
        { opacity: 1, transform: "translate(-50%, -4px) scale(1)", offset: .25 },
        { opacity: 0, transform: `translate(${dir > 0 ? "0%" : "-100%"}, -10px) scale(.9)` }
      ], { duration: 1400, easing: "ease-out" }).onfinish = () => bubble.remove();
    }
    function jump(height = 16) {
      hop.animate([
        { transform: "translateY(0) scale(1, 1)" },
        { transform: "translateY(0) scale(1.12, .86)", offset: .12 },
        { transform: `translateY(-${height}px) scale(.94, 1.08)`, offset: .45 },
        { transform: "translateY(0) scale(1.1, .9)", offset: .82 },
        { transform: "translateY(0) scale(1, 1)" }
      ], { duration: 620, easing: "cubic-bezier(.3,.7,.4,1)" });
      if (Math.random() < .7) puff();
    }

    function render() {
      mascot.style.transform = `translateX(${x}px) scaleX(${dir})`;
    }
    function step(time) {
      frame = 0;
      if (stopped() || document.hidden) { last = null; mascot.classList.remove("is-walking"); return; }
      const width = track.clientWidth - 36;
      if (last !== null && width > 40) {
        const dt = Math.min(time - last, 60) / 1000;
        if (time < pauseUntil) {
          mascot.classList.remove("is-walking");
        } else {
          mascot.classList.add("is-walking");
          x += dir * speed * dt;
          if (x <= 0 || x >= width) {
            x = Math.min(Math.max(x, 0), width); dir = -dir;
            pauseUntil = time + 700 + Math.random() * 900;
          } else if (Math.random() < dt * .12) {
            pauseUntil = time + 1200 + Math.random() * 1600; // stop and look around
          }
        }
        if (time > nextHop) { jump(8 + Math.random() * 6); nextHop = time + 3500 + Math.random() * 5000; }
        render();
      }
      if (last === null) nextHop = time + 2500;
      last = time;
      frame = requestAnimationFrame(step);
    }
    function update() {
      if (frame) cancelAnimationFrame(frame);
      frame = 0; last = null;
      if (!stopped() && !document.hidden) frame = requestAnimationFrame(step);
      else mascot.classList.remove("is-walking");
    }

    mascot.addEventListener("click", () => { jump(12); puff(); });
    document.addEventListener("dreamland:hop", () => { if (!stopped()) { jump(14); puff(); } });
    document.addEventListener("shown.bs.tab", event => {
      if (event.target.closest(".navbar") && !stopped()) jump(11);
    });
    new MutationObserver(update).observe(root, { attributes: true, attributeFilter: ["class"] });
    reducedMotion.addEventListener("change", update);
    document.addEventListener("visibilitychange", update);
    if ("ResizeObserver" in window) new ResizeObserver(placeTrack).observe(panel);
    window.addEventListener("resize", placeTrack, { passive: true });
    placeTrack(); render(); update();
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", initialize, { once: true });
  else initialize();
})();
