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
            context.strokeStyle = `rgba(185,239,188,${.15 + row * .035})`;
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
          context.strokeStyle = type === "network" ? "rgba(155,202,179,.22)" : "rgba(188,235,184,.28)";
          context.lineWidth = .8; context.stroke();
        }
        nodes.sort((a, b) => a.z - b.z).forEach(p => {
          context.beginPath(); context.arc(p.x, p.y, 1 + (p.z + 1) * .85, 0, Math.PI * 2);
          context.fillStyle = `rgba(211,247,178,${.25 + (p.z + 1) * .32})`; context.fill();
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
      ctx.fillStyle = `rgba(${p.strand ? "170,226,225" : "220,250,173"},${opacity})`;
      ctx.shadowColor = p.strand ? "#a4dfe0" : "#d2f4a2";
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
        ctx.strokeStyle = `rgba(140,216,205,${alpha * (1 - level) * 0.9})`;
        ctx.lineWidth = 1.2; ctx.stroke();
      }
      if (level > 0.02) {
        ctx.beginPath(); ctx.moveTo(p.x, p.y); ctx.lineTo(mx, my);
        ctx.strokeStyle = `rgba(246,214,128,${alpha * level * 0.8})`;
        ctx.lineWidth = 1.3; ctx.stroke();
        ctx.beginPath(); ctx.arc(mx, my, (1.8 + level * 2.4) * (0.75 + (p.depth + 1) * 0.2), 0, Math.PI * 2);
        ctx.fillStyle = `rgba(250,216,120,${alpha * level})`;
        ctx.shadowColor = "#f7d57a";
        ctx.shadowBlur = 6 + level * 10;
        ctx.fill(); ctx.shadowBlur = 0;
        if (level > 0.75 && p.depth > 0.35 && width > 320) {
          ctx.font = `600 9px ${font}`;
          ctx.textAlign = side > 0 ? "left" : "right";
          ctx.textBaseline = "middle";
          ctx.fillStyle = `rgba(250,226,160,${(level - 0.75) * 4 * (p.depth - 0.35) * 1.3})`;
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
      ctx.fillStyle = "rgba(250,216,120,.95)"; ctx.shadowColor = "#f7d57a"; ctx.shadowBlur = 8;
      ctx.fill(); ctx.shadowBlur = 0;
      ctx.fillStyle = "rgba(230,245,205,.72)";
      ctx.fillText("5mC · methylated CpG", x + 11, y - 16);
      ctx.beginPath(); ctx.arc(x, y, 3.5, 0, Math.PI * 2);
      ctx.strokeStyle = "rgba(140,216,205,.9)"; ctx.lineWidth = 1.2; ctx.stroke();
      ctx.fillStyle = "rgba(230,245,205,.72)";
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
        ctx.fillStyle = i % 5 === 0 ? "rgba(210,246,170,.6)" : "rgba(210,246,170,.22)";
        ctx.fill();
      }
      // An illustrative methylated helix, not an analytical visualization.
      for (let i = 0; i <= 92; i += 3) {
        const a = point(i, 0), b = point(i, 1);
        const site = cpgSites.get(i);
        const level = site ? methylation(site) : 0;
        const gradient = ctx.createLinearGradient(a.x, a.y, b.x + 0.01, b.y);
        if (site) {
          gradient.addColorStop(0, `rgba(${Math.round(206 + 40 * level)},${Math.round(247 - 30 * level)},${Math.round(160 - 30 * level)},.8)`);
          gradient.addColorStop(0.5, `rgba(240,220,150,${0.18 + level * 0.25})`);
          gradient.addColorStop(1, `rgba(${Math.round(156 + 90 * level)},${Math.round(211 + 4 * level)},${Math.round(225 - 95 * level)},.75)`);
        } else {
          gradient.addColorStop(0, "rgba(206,247,160,.55)");
          gradient.addColorStop(0.5, "rgba(160,213,187,.14)");
          gradient.addColorStop(1, "rgba(156,211,225,.5)");
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
            ctx.strokeStyle = `rgba(${strand ? "168,222,221" : "216,249,174"},${0.22 + (p.depth + 1) * 0.24})`;
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
