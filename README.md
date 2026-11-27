# 🌌 Molly AI Studio — 100% Standalone On-Device SQLite & Multiplatform Engine (iOS, macOS, Android)

Klien dan engine **Full Standalone (Berdiri Sendiri 100%)** untuk ekosistem **Molly AI Studio**, dibangun secara penuh menggunakan **Flutter & SQLite Lokal** dengan standar rekayasa desain **Anti-UI Slop** serta mengusung estetika visual **Apple Human Interface Guidelines (HIG)** termutakhir berbalut tema mewah **"Cosmic Obsidian & Liquid Gold" (60–120 FPS)**.

> 🛡️ **Jaminan Keamanan Proyek & Isolasi 100%**:
> Seluruh kode aplikasi ini berada di dalam direktori `Molly-CrossPlatform/` dan **TIDAK MENGUBAH / MERUSAK** proyek native `Molly-Android` maupun modul backend `Molly-LLM`. Keduanya tetap utuh dan dapat dijalankan berdampingan.

---

## ⚡ 1. Arsitektur Mandiri: Database SQLite Lokal di Memori HP (Zero Server Dependency)

Aplikasi ini **TIDAK BERGANTUNG PADA API CLIENT SERVER FASTAPI/PYTHON**. Seluruh arsitektur basis data dan mesin agen berjalan langsung di atas memori internal perangkat ponsel/laptop pengguna:

```text
┌────────────────────────────────────────────────────────────────────────┐
│           MOLLY ON-DEVICE FULL STANDALONE ARCHITECTURE                 │
└────────────────────────────────────────────────────────────────────────┘
                                    │
           ┌────────────────────────┴────────────────────────┐
           ▼                                                 ▼
┌──────────────────────┐                          ┌──────────────────────┐
│  Molly Local SQLite  │                          │  Molly Agent Engine  │
│  (molly_local_v2.db) │                          │  (Pure Dart Runtime) │
├──────────────────────┤                          ├──────────────────────┤
│ • sessions           │                          │ • Prompt Assembly    │
│ • messages           │                          │ • Local Tool Invoker │
│ • agents             │                          │ • Cosine Vector Calc │
│ • knowledge_datasets │                          │ • Streaming Client   │
│ • knowledge_chunks   │                          │ • Sandbox Storage    │
│ • workspace_files    │                          └──────────┬───────────┘
│ • background_jobs    │                                     │
│ • mcp_tools          │                                     ▼
│ • system_settings    │                          Direct HTTPS Streaming
└──────────────────────┘                     (OpenAI / Claude / Gemini / Ollama)
```

### Keunggulan Arsitektur On-Device SQLite:
1. **Penyimpanan Terisolasi di Sandbox OS**: Berkas basis data `molly_standalone_v2.db` berada di ruang penyimpanan internal ponsel (`/data/data/com.molly.crossplatform/databases/` pada Android, dan `Application Support/` pada iOS/macOS).
2. **Tidak Perlu Menyalakan Server Python**: Aplikasi dapat langsung digunakan seketika tanpa perlu membuka terminal, menyalakan uvicorn, atau mengeksekusi backend.
3. **Pencarian Semantik Kosinus Lokal (On-Device RAG)**: Chunks dokumen dan vektor dihitung langsung oleh [molly_knowledge_engine.dart](file:///c:/Users/it.prog.3/Pictures/Project_AI/LLM-Project/Molly-CrossPlatform/lib/core/engine/molly_knowledge_engine.dart) dengan perkalian titik kosinus lokal di memori HP.
4. **Zero Fallback & Zero Dummy**: Seluruh riwayat obrolan, berkas workspace, dan metrik dihitung langsung dari baris tabel SQLite aktual (`SELECT COUNT(*) FROM messages`), bukan angka bohongan.

---

## 🎨 2. Standar Rekayasa Desain Anti-UI Slop & Apple HIG

Aplikasi ini mengadopsi standar baku dari **Skill Anti-UI Slop**:
1. **Bebas Gradien Murahan AI (*Zero Purple Haze*)**: Mengganti gradien ungu-pink (*AI purple haze*) dengan palet berkelas **Liquid Gold** (`#EAB308`, `#FDE047`, `#CA8A04`) di atas kanvas gelap **Cosmic Obsidian** (`#0B0D13`, `#11141E`).
2. **BackdropFilter Gaussian Blur Kaca**: Kaca buram transparan dengan ketebalan border ultra-tipis (`0.6px` – `0.8px`) bergradasi emas dan *subtle inner hairline glow* (`inset 0 1px 0 0 rgba(255, 255, 255, 0.06)`).
3. **Geometri Radius Berjenjang (*Nested Radius*)**: Mematuhi formula matematika presisi:
   $$R_{\text{outer}} = R_{\text{inner}} + \text{Padding}$$
4. **Fluid Multi-Column Responsif**:
   - Layar Ponsel (`< 640px`): Otomatis melipat menjadi 1 kolom vertikal (100% lebar layar).
   - Layar Tablet (`640px - 1024px`): Grid seimbang 2 kolom.
   - Layar Desktop (`> 1024px`): Grid 3–4 kolom atau *split-screen*.
5. **Kontras Warna Tinggi WCAG AA**: Menggunakan teks Slate (`#F8FAFC`, `#CBD5E1`) dengan keterbacaan tajam di layar OLED/Retina.
6. **Tipografi Berkarakter**: Google Fonts *Plus Jakarta Sans* dengan *tight tracking* (`-0.025em`) pada heading.
7. **Bebas Ikon Emoji**: Menggunakan 100% ikon vektor `CupertinoIcons` tajam dengan stroke `1.5 - 2.0`.
8. **Touch Target Nyaman**: Area ketuk minimum `44px × 44px` di perangkat ponsel.
9. **Mikro-Interaksi Taktil 60 FPS**: Responsif membal (`scale: 0.98`) dan haptic feedback saat ditekan.
10. **Adaptive Shell (macOS vs Mobile)**:
    - **macOS & iPad**: Menampilkan **macOS Frosted Glass Sidebar** dengan kontrol window *traffic light dots* Apple (merah, kuning, hijau).
    - **iOS & Android**: Menampilkan **Floating Frosted Glass Bottom Navigation Bar** dengan indikator pil emas transparan.

---

## 📦 3. Seluruh Modul Sistem Molly Berbasis SQLite Lokal

| Modul Sistem | Berkas Implementasi Mandiri | Sumber Data & Mesin Pemroses |
| :--- | :--- | :--- |
| **1. Session & Chat Engine** | [chat_screen.dart](file:///c:/Users/it.prog.3/Pictures/Project_AI/LLM-Project/Molly-CrossPlatform/lib/features/chat/chat_screen.dart) | [molly_agent_engine.dart](file:///c:/Users/it.prog.3/Pictures/Project_AI/LLM-Project/Molly-CrossPlatform/lib/core/engine/molly_agent_engine.dart) & tabel SQLite `sessions` / `messages`. |
| **2. Agents & Skills Marketplace** | [agents_screen.dart](file:///c:/Users/it.prog.3/Pictures/Project_AI/LLM-Project/Molly-CrossPlatform/lib/features/agents/agents_screen.dart) | Tabel SQLite `agents` lokal (dapat menambah agen kustom baru langsung di HP). |
| **3. Knowledge Base & RAG** | [knowledge_screen.dart](file:///c:/Users/it.prog.3/Pictures/Project_AI/LLM-Project/Molly-CrossPlatform/lib/features/knowledge/knowledge_screen.dart) | [molly_knowledge_engine.dart](file:///c:/Users/it.prog.3/Pictures/Project_AI/LLM-Project/Molly-CrossPlatform/lib/core/engine/molly_knowledge_engine.dart) & tabel `knowledge_datasets` / `knowledge_chunks`. |
| **4. Personal Space & Workspace** | [workspace_screen.dart](file:///c:/Users/it.prog.3/Pictures/Project_AI/LLM-Project/Molly-CrossPlatform/lib/features/workspace/workspace_screen.dart) | [molly_workspace_engine.dart](file:///c:/Users/it.prog.3/Pictures/Project_AI/LLM-Project/Molly-CrossPlatform/lib/core/engine/molly_workspace_engine.dart) & tabel `workspace_files`. |
| **5. Molly Code Studio & Diff** | [code_studio_screen.dart](file:///c:/Users/it.prog.3/Pictures/Project_AI/LLM-Project/Molly-CrossPlatform/lib/features/code_studio/code_studio_screen.dart) | Engine perbandingan teks kode baris demi baris (*line-by-line diff*) langsung di Dart. |
| **6. Background Crons & MCP Registry** | [jobs_screen.dart](file:///c:/Users/it.prog.3/Pictures/Project_AI/LLM-Project/Molly-CrossPlatform/lib/features/jobs/jobs_screen.dart) | Tabel SQLite `background_jobs` & `mcp_tools`. |
| **7. Telemetri & Observabilitas** | [dashboard_screen.dart](file:///c:/Users/it.prog.3/Pictures/Project_AI/LLM-Project/Molly-CrossPlatform/lib/features/dashboard/dashboard_screen.dart) | Menghitung langsung jumlah baris aktual di database HP via `computeRealTelemetry()`. |
| **8. Pengaturan Engine & Sistem** | [settings_screen.dart](file:///c:/Users/it.prog.3/Pictures/Project_AI/LLM-Project/Molly-CrossPlatform/lib/features/settings/settings_screen.dart) | Manajemen kunci API provider langsung di perangkat & status database SQLite lokal. |

---

## 📂 4. Struktur Direktori Proyek

```text
Molly-CrossPlatform/
├── android/                   # Native Runner Android (Gradle 8, Kotlin 1.9, Manifest)
├── ios/                       # Native Runner Apple iOS (Xcode Workspace, Info.plist, Podfile)
├── macos/                     # Native Runner Apple macOS Desktop (Runner, Podfile, AppInfo)
├── lib/
│   ├── main.dart              # Entrypoint aplikasi & inisialisasi SQLite database
│   ├── core/
│   │   ├── database/          # MollyLocalDatabase (SQLite Tables: sessions, messages, agents, etc.)
│   │   ├── engine/            # MollyAgentEngine, MollyKnowledgeEngine (RAG), MollyWorkspaceEngine
│   │   ├── models/            # Domain: ChatMessage, AgentPreset, KnowledgeBase, BackgroundJob, etc.
│   │   ├── services/          # DirectProviderService (OpenAI, Claude, Gemini, Groq, Ollama)
│   │   ├── theme/             # AppColors (Cosmic Obsidian & Liquid Gold), GlassDecorations, AppTheme
│   │   └── widgets/           # GlassAppBar, FrostedBottomBar, ToolCallCard, CodeBlockViewer
│   └── features/
│       ├── chat/              # ChatScreen (On-device agent loop + SQLite)
│       ├── agents/            # AgentsScreen (Presets & Skills Marketplace)
│       ├── code_studio/       # CodeStudioScreen (Line-by-line Diff & Local File Versions)
│       ├── knowledge/         # KnowledgeScreen (On-Device RAG & Vector Cosine Similarity)
│       ├── workspace/         # WorkspaceScreen (On-device Workspace Files & Artifacts)
│       ├── jobs/              # JobsScreen (Local Cron Schedules & MCP Tool Toggles)
│       ├── dashboard/         # DashboardScreen (Real on-device telemetry counts)
│       ├── settings/          # SettingsScreen (API Keys & Local SQLite Database Status)
│       └── shell/             # MainShellScreen (Adaptive: macOS Sidebar vs Mobile Bottom Bar)
├── pubspec.yaml               # Dependensi: sqflite, path, path_provider, google_fonts, markdown
├── build-apk.bat              # Script build 1-klik Android Release APK
├── .github/workflows/         # Cloud CI/CD untuk otomatis kompilasi Android APK & Apple iOS IPA
└── README.md                  # Dokumentasi teknis lengkap
```
