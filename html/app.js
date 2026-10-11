(function () {
  "use strict";
  var app = document.getElementById("app"),
    titleEl = document.getElementById("title"),
    subtitleEl = document.getElementById("subtitle"),
    chapterList = document.getElementById("chapterList"),
    pageContent = document.getElementById("pageContent"),
    closeButton = document.getElementById("closeButton"),
    completionOverlay = document.getElementById("completionOverlay"),
    completionNumber = document.getElementById("completionNumber"),
    completionText = document.getElementById("completionText"),
    completionHint = document.getElementById("completionHint"),
    hauntWarning = document.getElementById("hauntWarning"),
    hauntWarningTitle = document.getElementById("hauntWarningTitle"),
    hauntWarningMessage = document.getElementById("hauntWarningMessage"),
    jumpScare = document.getElementById("jumpScare");
  var state = {
      progress: { chapter: 1, evidence: {}, completed: {} },
      chapters: {},
      selectedChapter: 1,
    },
    pendingFocusEvidence = null,
    audioContext = null;
  function nuiPost(name, data) {
    try {
      return fetch("https://" + GetParentResourceName() + "/" + name, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify(data || {}),
      });
    } catch (err) {
      console.error("[Murder of 8] NUI POST failed:", err);
      return Promise.resolve();
    }
  }
  function showM8Notification(message, duration = 4200) {
    let container = document.getElementById("m8Notify");

    if (!container) {
      container = document.createElement("div");
      container.id = "m8Notify";
      document.body.appendChild(container);
    }

    const item = document.createElement("div");
    item.className = "m8-notification";
    item.textContent = message;

    container.appendChild(item);

    requestAnimationFrame(() => {
      item.classList.add("show");
    });

    setTimeout(() => {
      item.classList.remove("show");

      setTimeout(() => {
        item.remove();
      }, 350);
    }, duration);
  }
  function openBook() {
    app.classList.add("open");
    app.setAttribute("aria-hidden", "false");
  }
  function closeBook() {
    app.classList.remove("open");
    app.setAttribute("aria-hidden", "true");
    completionOverlay.classList.remove("show");
    nuiPost("close");
  }
  // M8Story.Chapters is a Lua array [1..8]; it arrives here as a JS array [0..7]. Progress.chapter is
  // 1-based, so key the chapters 1..n or every tab unlocks one early and J opens on the next chapter.
  function keyedChapters(list) {
    if (!Array.isArray(list)) return list || {};
    var out = {};
    list.forEach(function (chapter, i) {
      out[i + 1] = chapter;
    });
    return out;
  }
  function isUnlocked(index) {
    return index <= Number(state.progress.chapter || 1);
  }
  function clearElement(node) {
    while (node.firstChild) node.removeChild(node.firstChild);
  }
  function findChapterForEvidence(id) {
    if (!id) return null;
    var keys = Object.keys(state.chapters);
    for (var i = 0; i < keys.length; i++) {
      var chapter = state.chapters[keys[i]];
      if (chapter && chapter.evidence && chapter.evidence[id])
        return Number(keys[i]);
    }
    return null;
  }
  function renderChapterList() {
    clearElement(chapterList);
    Object.keys(state.chapters)
      .map(Number)
      .filter(function (v) {
        return !isNaN(v);
      })
      .sort(function (a, b) {
        return a - b;
      })
      .forEach(function (index) {
        var chapter = state.chapters[index],
          unlocked = isUnlocked(index),
          button = document.createElement("button");
        button.type = "button";
        button.className =
          "chapterButton" +
          (index === state.selectedChapter ? " active" : "") +
          (unlocked ? "" : " locked");
        button.disabled = !unlocked;
        var num = document.createElement("span");
        num.className = "chapterNumber";
        num.textContent = chapter.number || String(index).padStart(2, "0");
        var copy = document.createElement("span"),
          name = document.createElement("span"),
          loc = document.createElement("span");
        name.className = "chapterTitle";
        name.textContent = unlocked ? chapter.title : "LOCKED";
        loc.className = "chapterLocation";
        loc.textContent = unlocked
          ? chapter.location || ""
          : "CASE FILE UNAVAILABLE";
        copy.appendChild(name);
        copy.appendChild(loc);
        button.appendChild(num);
        button.appendChild(copy);
        if (unlocked)
          button.addEventListener("click", function () {
            state.selectedChapter = index;
            render();
          });
        chapterList.appendChild(button);
      });
  }
  function addText(parent, tag, cls, text) {
    var el = document.createElement(tag);
    if (cls) el.className = cls;
    el.textContent = text || "";
    parent.appendChild(el);
    return el;
  }
  function renderPage() {
    clearElement(pageContent);
    var index = Number(state.selectedChapter),
      chapter = state.chapters[index];
    if (!chapter || !isUnlocked(index)) {
      var locked = document.createElement("div");
      locked.className = "lockedPage";
      locked.innerHTML =
        "<div><strong>LOCKED</strong><p>You haven't found enough to open this file.</p></div>";
      pageContent.appendChild(locked);
      return;
    }
    addText(pageContent, "h2", "", chapter.title || "CASE " + index);
    addText(pageContent, "p", "location", chapter.location || "");
    addText(pageContent, "p", "intro", chapter.intro || "");
    var evidence = chapter.evidence || {},
      ids = Object.keys(evidence);
    var grid = document.createElement("div");
    grid.className = "evidenceGrid";
    ids.forEach(function (id) {
      var item = evidence[id],
        found = !!(state.progress.evidence && state.progress.evidence[id]),
        card = document.createElement("section");
      card.className = "evidenceCard" + (found ? "" : " lockedEvidence");
      card.setAttribute("data-evidence-id", id);
      addText(
        card,
        "h3",
        "",
        found ? item.shortTitle || id : "UNDISCOVERED EVIDENCE",
      );
      // an undiscovered clue shows its hint once it is examinable (prerequisites found);
      // still-locked ones stay vague so nothing is spoiled out of order
      var foundSet = state.progress.evidence || {};
      var examinable = (item.prerequisites || []).every(function (id) {
        return !!foundSet[id];
      });
      addText(
        card,
        "p",
        found ? "evidenceBody" : examinable && item.hint ? "evidenceBody hint" : "evidenceBody",
        found
          ? item.body || ""
          : examinable && item.hint
            ? item.hint
            : "There is still something at this scene you haven't documented.",
      );
      if (found && item.note) addText(card, "p", "note", item.note);
      grid.appendChild(card);
    });
    pageContent.appendChild(grid);
    // the author's riddle pointing at the next scene, once this chapter is done
    var done = !!(state.progress.completed && state.progress.completed[index]);
    if (done && chapter.nextHint) addText(pageContent, "p", "lead", "LEAD — " + chapter.nextHint);
    if (done && chapter.placeHint) addText(pageContent, "p", "lead place", chapter.placeHint);
    if (pendingFocusEvidence) {
      var wanted = pendingFocusEvidence;
      pendingFocusEvidence = null;
      setTimeout(function () {
        var cards = pageContent.querySelectorAll("[data-evidence-id]");
        for (var i = 0; i < cards.length; i++) {
          if (cards[i].getAttribute("data-evidence-id") === wanted) {
            cards[i].scrollIntoView({ behavior: "smooth", block: "center" });
            break;
          }
        }
      }, 60);
    }
  }
  function render() {
    renderChapterList();
    renderPage();
  }
  function ensureAudio() {
    var Ctx = window.AudioContext || window.webkitAudioContext;
    if (!Ctx) return null;
    if (!audioContext) audioContext = new Ctx();
    if (audioContext.state === "suspended")
      audioContext.resume().catch(function () {});
    return audioContext;
  }

  /*
   * v1.3 horror audio:
   * Real OGG assets are decoded into AudioBuffers and played through WebAudio.
   * The old synthesized tones remain as a fallback if an asset fails to load.
   */
  var audioFiles = {
    bell: "audio/bell.ogg",
    jumpscare_01: "audio/jumpscare_01.ogg",
    jumpscare_02: "audio/jumpscare_02.ogg",
    jumpscare_stinger: "audio/jumpscare_stinger.ogg",
    metal_impact: "audio/metal_impact.ogg",
    footsteps: "audio/footsteps.ogg",
    footsteps_run: "audio/footsteps_run.ogg",
    breathing: "audio/breathing.ogg",
    whisper_01: "audio/whisper_01.ogg",
    whisper_02: "audio/whisper_02.ogg",
    coffin_knocks: "audio/coffin_knocks.ogg",
    cell_slam: "audio/cell_slam.ogg",
    phone_ring: "audio/phone_ring.ogg",
    train_horn: "audio/train_horn.ogg",
    dock_knocks: "audio/dock_knocks.ogg",
    heartbeat: "audio/heartbeat.ogg",
    ambience_dark: "audio/ambience_dark.ogg",
    static_burst: "audio/static_burst.ogg",
    reverse_sting: "audio/reverse_sting.ogg",
    body_drop: "audio/body_drop.ogg",
    chain_drag: "audio/chain_drag.ogg",
    door_creak: "audio/door_creak.ogg",
    distant_scream: "audio/distant_scream.ogg",
    voss_help: "audio/voss_help.ogg",
    sub_rumble: "audio/sub_rumble.ogg",
  };

  var audioBuffers = {};
  var audioLoading = {};
  var audioPreloadStarted = false;

  function decodeAudio(url, key) {
    if (audioBuffers[key] || audioLoading[key]) return;
    var ctx = ensureAudio();
    if (!ctx) return;

    audioLoading[key] = true;

    fetch(url)
      .then(function (r) {
        if (!r.ok) throw new Error("HTTP " + r.status + " " + url);
        return r.arrayBuffer();
      })
      .then(function (buf) {
        return ctx.decodeAudioData(buf);
      })
      .then(function (decoded) {
        audioBuffers[key] = decoded;
        delete audioLoading[key];
      })
      .catch(function (err) {
        delete audioLoading[key];
        console.warn("[Murder of 8] Could not preload " + key + ":", err);
      });
  }

  function preloadHorrorAudio() {
    if (audioPreloadStarted) return;
    audioPreloadStarted = true;

    Object.keys(audioFiles).forEach(function (key) {
      decodeAudio(audioFiles[key], key);
    });
  }

  function clamp(v, min, max) {
    return Math.max(min, Math.min(max, v));
  }

  function playBuffer(key, opts) {
    opts = opts || {};
    var ctx = ensureAudio();
    var buffer = audioBuffers[key];

    if (!ctx || !buffer) {
      if (audioFiles[key]) decodeAudio(audioFiles[key], key);
      return false;
    }

    try {
      var source = ctx.createBufferSource();
      var gain = ctx.createGain();
      var destination = gain;

      source.buffer = buffer;
      source.playbackRate.value = clamp(Number(opts.rate) || 1.0, 0.72, 1.28);
      gain.gain.value = clamp(
        Number(opts.volume) == Number(opts.volume) ? Number(opts.volume) : 1,
        0,
        1,
      );

      if (ctx.createStereoPanner) {
        var pan = ctx.createStereoPanner();
        pan.pan.value = clamp(Number(opts.pan) || 0, -1, 1);
        gain.connect(pan);
        pan.connect(ctx.destination);
      } else {
        gain.connect(ctx.destination);
      }

      source.connect(gain);
      source.start(0);
      return true;
    } catch (err) {
      console.warn("[Murder of 8] Audio buffer playback failed:", err);
      return false;
    }
  }

  function tone(freq, delay, duration, gainValue, type) {
    var ctx = ensureAudio();
    if (!ctx) return;
    var start = ctx.currentTime + (delay || 0),
      osc = ctx.createOscillator(),
      gain = ctx.createGain();
    osc.type = type || "sine";
    osc.frequency.value = freq;
    gain.gain.setValueAtTime(0.0001, start);
    gain.gain.exponentialRampToValueAtTime(gainValue || 0.2, start + 0.01);
    gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(start);
    osc.stop(start + duration + 0.05);
  }
  function knock(delay) {
    tone(70, delay, 0.28, 0.32, "sine");
  }
  function noise(delay, duration, gainValue, lowpass) {
    var ctx = ensureAudio();
    if (!ctx) return;
    var length = Math.max(1, Math.floor(ctx.sampleRate * duration)),
      buffer = ctx.createBuffer(1, length, ctx.sampleRate),
      data = buffer.getChannelData(0);
    for (var i = 0; i < length; i++) data[i] = Math.random() * 2 - 1;
    var source = ctx.createBufferSource(),
      gain = ctx.createGain(),
      filter = ctx.createBiquadFilter(),
      start = ctx.currentTime + (delay || 0);
    filter.type = "lowpass";
    filter.frequency.value = lowpass || 1200;
    gain.gain.setValueAtTime(0.0001, start);
    gain.gain.exponentialRampToValueAtTime(gainValue || 0.1, start + 0.015);
    gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
    source.buffer = buffer;
    source.connect(filter);
    filter.connect(gain);
    gain.connect(ctx.destination);
    source.start(start);
    source.stop(start + duration + 0.03);
  }

  function fallbackSound(name) {
    try {
      if (name === "bell" || name === "archive_bell") {
        tone(620, 0, 1.3, 0.18, "sine");
        tone(930, 0, 1.3, 0.08, "triangle");
        tone(1240, 0, 1.3, 0.05, "triangle");
      } else if (name === "coffin_knocks") {
        knock(0);
        knock(0.55);
        knock(1.1);
      } else if (name === "metal_clang" || name === "impact") {
        tone(55, 0, 0.7, 0.28, "square");
        noise(0, 0.38, 0.18, 600);
      } else if (name === "whisper") {
        noise(0, 1.1, 0.055, 820);
        tone(180, 0, 1, 0.035, "sawtooth");
      } else if (name === "phone_ring") {
        tone(440, 0, 0.35, 0.16, "square");
        tone(480, 0, 0.35, 0.13, "square");
        tone(440, 0.8, 0.35, 0.16, "square");
        tone(480, 0.8, 0.35, 0.13, "square");
      } else if (name === "train_horn") {
        tone(110, 0, 1.8, 0.13, "sawtooth");
        tone(147, 0, 1.8, 0.09, "sawtooth");
      } else if (name === "dock_knocks") {
        knock(0);
        knock(0.35);
        knock(0.7);
        knock(1.55);
        knock(1.9);
        knock(2.25);
        knock(3.15);
        knock(3.55);
      } else if (name === "static") {
        noise(0, 0.52, 0.13, 2800);
        tone(72, 0, 0.44, 0.035, "square");
      } else if (name === "breath") {
        noise(0, 0.8, 0.055, 540);
        noise(0.62, 0.7, 0.045, 430);
      } else if (name === "footsteps" || name === "footsteps_run") {
        knock(0);
        knock(0.35);
        knock(0.72);
      } else if (name === "jump_sting") {
        noise(0, 0.52, 0.28, 4200);
        tone(52, 0, 0.58, 0.28, "sawtooth");
        tone(880, 0, 0.18, 0.14, "square");
      }
    } catch (err) {
      console.warn("[Murder of 8] Fallback audio failed:", err);
    }
  }

  function randomChoice(list) {
    return list[Math.floor(Math.random() * list.length)];
  }

  var nativeHorrorSounds = {
    bell: true,
    archive_bell: true,
    whisper: true,
    distant_scream: true,
    breath: true,
    footsteps: true,
    footsteps_run: true,
    coffin_knocks: true,
    dock_knocks: true,
    metal_clang: true,
    cell_slam: true,
    impact: true,
    body_drop: true,
    chain_drag: true,
    door_creak: true,
    phone_ring: true,
    train_horn: true,
    jump_sting: true,
    reverse_sting: true,
  };

  function requestNativeHorrorSound(name, opts) {
    opts = opts || {};

    if (!nativeHorrorSounds[name] || opts.nativeBypass) {
      return false;
    }

    try {
      fetch("https://" + GetParentResourceName() + "/nativeSound", {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify({
          name: name,
          pan: opts.pan,
          volume: opts.volume,
          rate: opts.rate,
        }),
      })
        .then(function (r) {
          return r.json();
        })
        .then(function (result) {
          if (!result || result.ok !== true) {
            playSound(name, Object.assign({}, opts, { nativeBypass: true }));
          }
        })
        .catch(function () {
          playSound(name, Object.assign({}, opts, { nativeBypass: true }));
        });

      return true;
    } catch (err) {
      return false;
    }
  }

  function playSound(name, opts) {
    opts = opts || {};

    if (requestNativeHorrorSound(name, opts)) {
      return;
    }

    var key = name;
    var volume = 1.0;
    var pan = Number(opts.pan);
    var rate = Number(opts.rate);

    if (!Number.isFinite(pan)) {
      if (
        name === "whisper" ||
        name === "breath" ||
        name === "footsteps" ||
        name === "footsteps_run"
      ) {
        pan = (Math.random() > 0.5 ? 1 : -1) * (0.38 + Math.random() * 0.55);
      } else {
        pan = 0;
      }
    }

    if (!Number.isFinite(rate)) {
      rate = 0.96 + Math.random() * 0.08;
    }

    if (name === "archive_bell" || name === "bell") {
      key = "bell";
      volume = 0.66;
    } else if (name === "coffin_knocks") {
      key = "coffin_knocks";
      volume = 0.82;
    } else if (name === "metal_clang") {
      key = "cell_slam";
      volume = 0.92;
    } else if (name === "whisper") {
      key = randomChoice(["whisper_01", "whisper_02"]);
      volume = 0.68;
      rate = 0.9 + Math.random() * 0.15;
    } else if (name === "phone_ring") {
      key = "phone_ring";
      volume = 0.68;
    } else if (name === "train_horn") {
      key = "train_horn";
      volume = 0.6;
    } else if (name === "dock_knocks") {
      key = "dock_knocks";
      volume = 0.78;
    } else if (name === "impact") {
      key = "metal_impact";
      volume = 0.92;
    } else if (name === "static") {
      key = "static_burst";
      volume = 0.7;
    } else if (name === "breath") {
      key = "breathing";
      volume = 0.56;
      rate = 0.88 + Math.random() * 0.12;
    } else if (name === "footsteps") {
      key = "footsteps";
      volume = 0.64;
    } else if (name === "footsteps_run") {
      key = "footsteps_run";
      volume = 0.82;
    } else if (name === "heartbeat") {
      key = "heartbeat";
      volume = 0.58;
    } else if (name === "ambience") {
      key = "ambience_dark";
      volume = 0.34;
    } else if (name === "jump_sting") {
      key = randomChoice(["jumpscare_01", "jumpscare_02", "jumpscare_stinger"]);
      volume = 0.9;
      rate = 0.96 + Math.random() * 0.08;
      pan = (Math.random() - 0.5) * 0.2;
    } else if (name === "reverse_sting") {
      key = "reverse_sting";
      volume = 0.62;
    } else if (name === "body_drop") {
      key = "body_drop";
      volume = 0.96;
    } else if (name === "chain_drag") {
      key = "chain_drag";
      volume = 0.58;
    } else if (name === "door_creak") {
      key = "door_creak";
      volume = 0.5;
    } else if (name === "distant_scream") {
      key = "distant_scream";
      volume = 0.42;
    } else if (name === "sub_rumble") {
      key = "sub_rumble";
      volume = 0.36;
    }

    if (Number(opts.volume) == Number(opts.volume))
      volume = clamp(Number(opts.volume), 0, 1);
    if (Number(opts.rate) == Number(opts.rate))
      rate = clamp(Number(opts.rate), 0.72, 1.28);

    if (!playBuffer(key, { volume: volume, pan: pan, rate: rate })) {
      fallbackSound(name);
    }
  }

  preloadHorrorAudio();
  document.addEventListener(
    "click",
    function () {
      ensureAudio();
      preloadHorrorAudio();
    },
    { once: true },
  );

  document.addEventListener(
    "keydown",
    function () {
      ensureAudio();
      preloadHorrorAudio();
    },
    { once: true },
  );

  /* v1.4 Scare Director visual layer.
   * It stays transparent unless an effect is actively running.
   */
  (function installScareDirectorLayer() {
    if (!document.querySelector("link[data-m8-director-css]")) {
      var link = document.createElement("link");
      link.rel = "stylesheet";
      link.href = "scare_director.css";
      link.setAttribute("data-m8-director-css", "1");
      document.head.appendChild(link);
    }

    if (!document.getElementById("m8DirectorFx")) {
      var fx = document.createElement("div");
      fx.id = "m8DirectorFx";
      fx.setAttribute("aria-hidden", "true");
      document.body.appendChild(fx);
    }

    if (!document.getElementById("m8HauntMessage")) {
      var msg = document.createElement("div");
      msg.id = "m8HauntMessage";
      msg.setAttribute("aria-hidden", "true");
      document.body.appendChild(msg);
    }
  })();

  var directorFxTimer = null;
  var hauntMessageTimer = null;

  function showDirectorEffect(data) {
    var fx = document.getElementById("m8DirectorFx");
    if (!fx) return;

    if (directorFxTimer) clearTimeout(directorFxTimer);

    var mode = data.mode || "glitch";
    var intensity = Math.max(0.1, Math.min(1.5, Number(data.intensity) || 1));

    fx.className = "m8fx " + mode;
    fx.style.setProperty("--m8-intensity", String(intensity));
    fx.setAttribute("aria-hidden", "false");

    directorFxTimer = setTimeout(
      function () {
        fx.className = "m8fx";
        fx.setAttribute("aria-hidden", "true");
      },
      Number(data.duration) || 350,
    );
  }

  function showHauntMessage(data) {
    var el = document.getElementById("m8HauntMessage");
    if (!el) return;

    if (hauntMessageTimer) clearTimeout(hauntMessageTimer);

    el.textContent = data.text || "";
    el.className = "show";
    el.setAttribute("aria-hidden", "false");

    hauntMessageTimer = setTimeout(
      function () {
        el.className = "";
        el.setAttribute("aria-hidden", "true");
      },
      Number(data.duration) || 1700,
    );
  }

  var warningTimer = null,
    jumpTimer = null;
  function showWarning(data) {
    if (!hauntWarning) return;
    if (warningTimer) clearTimeout(warningTimer);
    hauntWarningTitle.textContent = data.title || "THE DAY IS APPROACHING";
    hauntWarningMessage.textContent = data.message || "";
    hauntWarning.classList.add("show");
    hauntWarning.setAttribute("aria-hidden", "false");
    warningTimer = setTimeout(
      function () {
        hauntWarning.classList.remove("show");
        hauntWarning.setAttribute("aria-hidden", "true");
      },
      Number(data.duration) || 8500,
    );
  }
  function showJumpScare(data) {
    if (!jumpScare) return;
    if (jumpTimer) clearTimeout(jumpTimer);
    var variant = data.variant || "figure";
    jumpScare.className = "";
    jumpScare.classList.add("show");
    if (variant === "impact") jumpScare.classList.add("impact");
    if (variant === "static") jumpScare.classList.add("static");
    jumpScare.setAttribute("aria-hidden", "false");
    if (variant === "impact") {
      playSound("impact");
    } else if (variant === "static") {
      playSound("static");
    } else {
      playSound("jump_sting");
      setTimeout(function () {
        playSound("impact", { volume: 0.45 });
      }, 55);
    }
    jumpTimer = setTimeout(
      function () {
        jumpScare.className = "";
        jumpScare.setAttribute("aria-hidden", "true");
      },
      Number(data.duration) || 520,
    );
  }

  // FINAL CHAPTER CINEMATIC ---------------------------------------------------
  var finaleOverlayTimer = null;

  function ensureFinaleOverlay() {
    var overlay = document.getElementById("m8FinaleOverlay");

    if (overlay) return overlay;

    overlay = document.createElement("div");
    overlay.id = "m8FinaleOverlay";
    overlay.setAttribute("aria-hidden", "true");

    var inner = document.createElement("div");
    inner.id = "m8FinaleInner";

    var title = document.createElement("div");
    title.id = "m8FinaleTitle";

    var text = document.createElement("div");
    text.id = "m8FinaleText";

    var sub = document.createElement("div");
    sub.id = "m8FinaleSub";

    var footer = document.createElement("div");
    footer.id = "m8FinaleFooter";

    inner.appendChild(title);
    inner.appendChild(text);
    inner.appendChild(sub);
    inner.appendChild(footer);
    overlay.appendChild(inner);
    document.body.appendChild(overlay);

    return overlay;
  }

  function hideFinaleOverlay() {
    var overlay = ensureFinaleOverlay();

    if (finaleOverlayTimer) {
      clearTimeout(finaleOverlayTimer);
      finaleOverlayTimer = null;
    }

    overlay.className = "";
    overlay.setAttribute("aria-hidden", "true");
  }

  function showFinaleText(data) {
    var overlay = ensureFinaleOverlay();
    var title = document.getElementById("m8FinaleTitle");
    var text = document.getElementById("m8FinaleText");
    var sub = document.getElementById("m8FinaleSub");
    var footer = document.getElementById("m8FinaleFooter");

    if (finaleOverlayTimer) {
      clearTimeout(finaleOverlayTimer);
      finaleOverlayTimer = null;
    }

    title.textContent = "";
    sub.textContent = "";
    footer.textContent = "";
    text.textContent = data.text || "";

    overlay.className =
      "show " + (data.mode === "command" ? "command" : "message");

    overlay.setAttribute("aria-hidden", "false");

    var duration = Number(data.duration) || 0;

    if (duration > 0) {
      finaleOverlayTimer = setTimeout(function () {
        hideFinaleOverlay();
      }, duration);
    }
  }

  function showFinaleCredits(data) {
    var overlay = ensureFinaleOverlay();
    var title = document.getElementById("m8FinaleTitle");
    var text = document.getElementById("m8FinaleText");
    var sub = document.getElementById("m8FinaleSub");
    var footer = document.getElementById("m8FinaleFooter");

    if (finaleOverlayTimer) {
      clearTimeout(finaleOverlayTimer);
      finaleOverlayTimer = null;
    }

    title.textContent = data.title || "MURDER OF 8";
    text.textContent = data.subtitle || "THE LAST WITNESS";
    sub.textContent = data.credit || "";
    footer.textContent = data.footer || "";

    overlay.className = "show credits";
    overlay.setAttribute("aria-hidden", "false");

    finaleOverlayTimer = setTimeout(
      function () {
        hideFinaleOverlay();
      },
      Number(data.duration) || 9000,
    );
  }

  window.addEventListener("message", function (event) {
    try {
      var data = event.data || {};
      if (data.action === "open") {
        pendingFocusEvidence = data.focusEvidence || null;
        openBook();
        return;
      }
      if (data.action === "close") {
        app.classList.remove("open");
        app.setAttribute("aria-hidden", "true");
        completionOverlay.classList.remove("show");
        return;
      }
      if (data.action === "state") {
        titleEl.textContent = data.title || "MURDER OF 8";
        subtitleEl.textContent = data.subtitle || "THE LAST WITNESS";
        if (data.progress) state.progress = data.progress;
        if (data.chapters) state.chapters = keyedChapters(data.chapters);
        var focused = findChapterForEvidence(pendingFocusEvidence);
        if (focused && isUnlocked(focused)) state.selectedChapter = focused;
        else if (!isUnlocked(state.selectedChapter))
          state.selectedChapter = Number(state.progress.chapter || 1);
        render();
        return;
      }
      if (data.action === "sound") {
        playSound(data.name || "", {
          pan: data.pan,
          rate: data.rate,
          volume: data.volume,
          nativeBypass: data.nativeBypass === true,
        });
        return;
      }
      if (data.action === "warning") {
        showWarning(data);
        return;
      }
      if (data.action === "jumpscare") {
        showJumpScare(data);
        return;
      }
      if (data.action === "notify") {
        showM8Notification(data.message || "", data.duration || 4200);
        return;
      }
      if (data.action === "directorEffect") {
        showDirectorEffect(data);
        return;
      }
      if (data.action === "hauntMessage") {
        showHauntMessage(data);
        return;
      }
      if (data.action === "finaleText") {
        showFinaleText(data);
        return;
      }
      if (data.action === "finaleCredits") {
        showFinaleCredits(data);
        return;
      }
      if (data.action === "finaleClear") {
        hideFinaleOverlay();
        return;
      }
      if (data.action === "chapterComplete") {
        completionNumber.textContent = String(data.chapter || 1).padStart(
          2,
          "0",
        );
        completionText.textContent = data.text || "";
        if (completionHint) {
          var lead = data.hint ? "LEAD — " + data.hint : "";
          if (data.place) lead += (lead ? "\n" : "") + data.place;
          completionHint.textContent = lead;
        }
        completionOverlay.classList.add("show");
        setTimeout(function () {
          completionOverlay.classList.remove("show");
        }, 5500);
      }
    } catch (err) {
      console.error("[Murder of 8] NUI error:", err);
    }
  });
  closeButton.addEventListener("click", closeBook);
  document.addEventListener("keydown", function (event) {
    if (event.key === "Escape") closeBook();
  });
  console.log("[Murder of 8] NUI loaded.");
})();
