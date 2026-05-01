let entries = [];
let languages = ['en'];
let dragSrc = null;
let activeTab = 'json';

// ── Language management ────────────────────────────────────────────

function addLanguage() {
  const input = document.getElementById('lang-input');
  const code = input.value.trim().replace(/\s+/g, '_');
  if (!code || languages.includes(code)) { input.value = ''; return; }
  languages.push(code);
  input.value = '';
  renderLanguages();
  renderEntries();
  updatePreview();
}

function removeLanguage(code) {
  if (languages.length === 1) return;
  languages = languages.filter(l => l !== code);
  renderLanguages();
  renderEntries();
  updatePreview();
}

function renderLanguages() {
  const container = document.getElementById('lang-chips');
  container.innerHTML = '';
  languages.forEach(code => {
    const chip = document.createElement('span');
    chip.className = 'lang-chip';
    chip.innerHTML = `${code} <button onclick="removeLanguage('${code}')" title="Remove language">×</button>`;
    container.appendChild(chip);
  });
}

// ── Entry management ───────────────────────────────────────────────

function addEntry(data = {}) {
  const id = Date.now() + Math.random();
  entries.push({ id, translations: {}, name_translations: {}, ...data });
  renderEntries();
  updatePreview();
}

function removeEntry(id) {
  entries = entries.filter(e => e.id !== id);
  renderEntries();
  updatePreview();
}

function moveEntry(id, dir) {
  const i = entries.findIndex(e => e.id === id);
  const j = i + dir;
  if (j < 0 || j >= entries.length) return;
  [entries[i], entries[j]] = [entries[j], entries[i]];
  renderEntries();
  updatePreview();
}

// ── Data reading ───────────────────────────────────────────────────

function getEntryData() {
  return entries.map(entry => {
    const card = document.querySelector(`[data-id="${entry.id}"]`);
    if (!card) return null;
    const get = sel => card.querySelector(sel)?.value.trim() ?? '';

    const translations = {};
    card.querySelectorAll('[data-trans-lang]').forEach(el => {
      translations[el.dataset.transLang] = el.value.trim();
    });

    const name_translations = {};
    card.querySelectorAll('[data-name-trans-lang]').forEach(el => {
      name_translations[el.dataset.nameTransLang] = el.value.trim();
    });

    return {
      id: entry.id,
      text_key:         get('.f-text-key'),
      translations,
      name_key:         get('.f-name-key'),
      name_translations,
      face_sprite:      get('.f-face'),
      large_sprite:     get('.f-large'),
      large_x:          get('.f-lx'),
      large_y:          get('.f-ly'),
      position:         get('.f-pos'),
    };
  }).filter(Boolean);
}

// ── Build outputs ──────────────────────────────────────────────────

function buildJSON() {
  const data = getEntryData();
  return {
    entries: data.map(e => {
      const obj = {};
      if (e.text_key)  obj.text = e.text_key;
      if (e.name_key)  obj.name = e.name_key;
      if (e.face_sprite)  obj.face_sprite = e.face_sprite;
      if (e.large_sprite) {
        obj.large_sprite = e.large_sprite;
        const x = parseFloat(e.large_x);
        const y = parseFloat(e.large_y);
        if (!isNaN(x) || !isNaN(y)) {
          obj.large_sprite_position = [isNaN(x) ? 0 : x, isNaN(y) ? 0 : y];
        }
      }
      if (e.position) obj.position = e.position;
      return obj;
    })
  };
}

function csvCell(value) {
  const str = String(value ?? '');
  return `"${str.replace(/"/g, '""')}"`;
}

function buildCSV() {
  const data = getEntryData();
  const rows = [['keys', ...languages].map(csvCell).join(',')];
  const seenNameKeys = new Map();

  data.forEach(e => {
    if (e.text_key) {
      const cells = [csvCell(e.text_key)];
      languages.forEach(lang => cells.push(csvCell(e.translations[lang] ?? '')));
      rows.push(cells.join(','));
    }
    if (e.name_key && !seenNameKeys.has(e.name_key)) {
      seenNameKeys.set(e.name_key, e.name_translations);
    }
  });

  seenNameKeys.forEach((translations, key) => {
    const cells = [csvCell(key)];
    languages.forEach(lang => cells.push(csvCell(translations[lang] ?? '')));
    rows.push(cells.join(','));
  });

  return rows.join('\n');
}

// ── Preview ────────────────────────────────────────────────────────

function switchTab(tab) {
  activeTab = tab;
  document.querySelectorAll('.tab-btn').forEach(b => b.classList.toggle('active', b.dataset.tab === tab));
  document.querySelectorAll('.tab-panel').forEach(p => p.classList.toggle('active', p.dataset.tab === tab));
  updatePreview();
}

function updatePreview() {
  const jsonEl = document.getElementById('json-preview');
  const csvEl  = document.getElementById('csv-preview');
  if (jsonEl) jsonEl.textContent = JSON.stringify(buildJSON(), null, 2);
  if (csvEl)  csvEl.textContent  = buildCSV();
}

// ── Export ─────────────────────────────────────────────────────────

function download(content, filename, type) {
  const blob = new Blob([content], { type });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = filename;
  a.click();
  URL.revokeObjectURL(a.href);
}

function exportJSON() {
  const name = document.getElementById('file-name').value.trim() || 'dialog';
  download(JSON.stringify(buildJSON(), null, 2), name + '.json', 'application/json');
}

function exportCSV() {
  const name = document.getElementById('file-name').value.trim() || 'dialog';
  download(buildCSV(), name + '.csv', 'text/csv');
}

function exportBoth() {
  exportJSON();
  exportCSV();
}

// ── Render entries ─────────────────────────────────────────────────

function translationFields(langAttr, values) {
  return languages.map(lang => `
    <div class="field trans-field">
      <label class="lang-label">${lang}</label>
      <textarea ${langAttr}="${lang}" placeholder="${lang} text...">${values[lang] ?? ''}</textarea>
    </div>
  `).join('');
}

function nameTranslationFields(values) {
  return languages.map(lang => `
    <div class="field trans-field">
      <label class="lang-label">${lang}</label>
      <input type="text" data-name-trans-lang="${lang}" placeholder="${lang} name..." value="${values[lang] ?? ''}">
    </div>
  `).join('');
}

function renderEntries() {
  const list = document.getElementById('entries-list');
  const saved = getEntryData();
  saved.forEach(s => {
    const e = entries.find(x => x.id === s.id);
    if (e) Object.assign(e, s);
  });

  list.innerHTML = '';
  entries.forEach((entry, i) => {
    const card = document.createElement('div');
    card.className = 'entry-card';
    card.dataset.id = entry.id;
    card.draggable = true;

    card.innerHTML = `
      <div class="entry-header">
        <span class="drag-handle" title="Drag to reorder">⠿</span>
        <span class="entry-number">Entry ${i + 1}</span>
        <div class="entry-move">
          <button class="btn-icon" title="Move up" onclick="moveEntry(${entry.id}, -1)">↑</button>
          <button class="btn-icon" title="Move down" onclick="moveEntry(${entry.id}, 1)">↓</button>
        </div>
        <button class="btn-danger" onclick="removeEntry(${entry.id})">Remove</button>
      </div>
      <div class="entry-body">

        <div class="field">
          <label>Text Key</label>
          <input type="text" class="f-text-key" placeholder="e.g. DIALOG_GUARD_001" value="${entry.text_key ?? ''}">
        </div>

        ${languages.length > 0 ? `
        <div class="translations-section">
          <div class="trans-header">Translations</div>
          <div class="trans-grid">
            ${translationFields('data-trans-lang', entry.translations ?? {})}
          </div>
        </div>` : ''}

        <div class="field-row">
          <div class="field">
            <label>Name Key <span class="optional">(optional)</span></label>
            <input type="text" class="f-name-key" placeholder="e.g. NPC_GUARD_NAME" value="${entry.name_key ?? ''}">
          </div>
          <div class="field">
            <label>Box position</label>
            <select class="f-pos">
              <option value="bottom" ${(entry.position ?? 'bottom') === 'bottom' ? 'selected' : ''}>Bottom</option>
              <option value="center" ${entry.position === 'center' ? 'selected' : ''}>Center</option>
              <option value="top"    ${entry.position === 'top'    ? 'selected' : ''}>Top</option>
            </select>
          </div>
        </div>

        ${languages.length > 0 ? `
        <div class="translations-section">
          <div class="trans-header">Name translations</div>
          <div class="trans-grid">
            ${nameTranslationFields(entry.name_translations ?? {})}
          </div>
        </div>` : ''}

        <div class="field">
          <label>Face Sprite <span class="optional">(optional) — res:// path</span></label>
          <input type="text" class="f-face" placeholder="res://assets/faces/character.png" value="${entry.face_sprite ?? ''}">
        </div>
        <div class="field-row quad">
          <div class="field">
            <label>Large Sprite <span class="optional">(optional) — res:// path</span></label>
            <input type="text" class="f-large" placeholder="res://assets/sprites/character.png" value="${entry.large_sprite ?? ''}">
          </div>
          <div class="field">
            <label>Pos X <span class="optional">(large)</span></label>
            <input type="number" class="f-lx" placeholder="0" value="${entry.large_x ?? ''}">
          </div>
          <div class="field">
            <label>Pos Y <span class="optional">(large)</span></label>
            <input type="number" class="f-ly" placeholder="0" value="${entry.large_y ?? ''}">
          </div>
        </div>

      </div>
    `;

    card.querySelectorAll('input, textarea, select').forEach(el => {
      el.addEventListener('input', updatePreview);
      el.addEventListener('change', updatePreview);
    });

    card.addEventListener('dragstart', e => {
      dragSrc = entry.id;
      setTimeout(() => card.classList.add('dragging'), 0);
      e.dataTransfer.effectAllowed = 'move';
    });
    card.addEventListener('dragend', () => {
      card.classList.remove('dragging');
      document.querySelectorAll('.entry-card').forEach(c => c.classList.remove('drag-over'));
    });
    card.addEventListener('dragover', e => {
      e.preventDefault();
      e.dataTransfer.dropEffect = 'move';
      document.querySelectorAll('.entry-card').forEach(c => c.classList.remove('drag-over'));
      if (entry.id !== dragSrc) card.classList.add('drag-over');
    });
    card.addEventListener('drop', e => {
      e.preventDefault();
      if (dragSrc === entry.id) return;
      const fromIdx = entries.findIndex(x => x.id === dragSrc);
      const toIdx   = entries.findIndex(x => x.id === entry.id);
      const [moved] = entries.splice(fromIdx, 1);
      entries.splice(toIdx, 0, moved);
      renderEntries();
      updatePreview();
    });

    list.appendChild(card);
  });
}

// ── Init ───────────────────────────────────────────────────────────

document.getElementById('lang-input').addEventListener('keydown', e => {
  if (e.key === 'Enter') addLanguage();
});

renderLanguages();
addEntry();
