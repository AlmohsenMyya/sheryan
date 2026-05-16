# 🩸 Sheryan Ecosystem — Central Documentation Index & AI Agent Protocol

> **CRITICAL DIRECTIVE FOR AI AGENTS:** This file is your immutable entry point and execution framework. You MUST read this document entirely and adhere strictly to the architectural hierarchy, reading order, and feature lifecycles defined below before modifying, creating, or refactoring any codebase or technical documentation within this repository.

---

## 🗺️ 1. Repository Documentation Tree (`/docs`)

```text
docs/
│
├── 📑 index.md                                 # Central Router & Strict Operational Protocol for AI Agents
│
├── 📂 01_architecture/                         # Core System Architecture & Infrastructure Layer
│   ├── comprehensive_project_summary.md        # High-level executive architecture linking all sub-systems
│   ├── sheryan_complete_project_documentation.md # Foundation System Blueprint & Project Boot Sequence (v0.1.0)
│   ├── sheryan_v2_technical_documentation.md   # Service Layer Decoupling & Repository Pattern Abstraction
│   ├── firebase_console_checklist.md          # Cloud infrastructure indexing, rules, and composite indexes
│   └── implementation_history_log_v2.md        # Ledger of historical architectural decisions & schema evolutions
│
├── 📂 02_auth_profile/                         # Identity, Role Isolation, & Weighted Progress Systems
│   ├── auth_flow_fixes.md                      # UID-specific isolated caching (`sheryan_user_cache_{uid}`)
│   ├── profile_completion.md                   # Multi-stage weighted completion algorithm (0-100% metrics)
│   └── i18n_ar_en_plan.md                      # Localization engine blueprints strictly enforcing zero hardcoded strings
│
├── 📂 03_notifications/                        # Staged Smart Push Engine & Asynchronous Delivery
│   ├── notifications_flow.md                   # Legacy multi-cast background logic using FCM v1 REST API
│   ├── staged_notifications_plan.md            # Initial analytical proposal for mitigating donor notification fatigue
│   ├── staged_notifications_final_blueprint.md # Approved architecture for cooldown loops and server-side safety guards
│   ├── staged_notifications_backend_impl.md    # Atomic Firestore Transactions & String-to-Timestamp normalization
│   ├── staged_notifications_donor_flow_impl.md # Silent Data Payloads, deep-linking, & Contextless Global Navigation
│   ├── staged_notifications_recipient_flow_impl.md # Real-time server-synced countdown banner & state machine (4 Button States)
│   └── staged_notifications_implementation_log.md # Comprehensive integration ledger, tracing, and unit test logs
│
├── 📂 04_dashboards/                           # Role-Based Presentation Layers & Interactive Control Panel
│   ├── super_admin_dashboard.md                # Modern responsive dashboard using wide-screen `NavigationRail`
│   ├── hospital_admin_phase1_implementation.md # QR-code driven rapid verification & immediate donation logging
│   └── recipient_role_enhancement_plan.md     # Active roadmap upgrading recipient view into a reactive analytical matrix
│
└── 📂 05_medical_logic/                        # Medical Constraints, Gamification, & Resilience Layers
    ├── blood_compatibility.md                  # Biological rules matrix via `BloodLogic` utility class
    ├── donation_history.md                     # Inter-connected atomic donation logs & core transaction triggers
    ├── offline_mode.md                         # Offline-First architecture via local `PendingActionsService`
    ├── points_rewards_system.md                # In-app gamification engine, emergency multipliers, & tier structures
    └── points_rewards_sponsor.md               # Sponsor dashboard, QR redemption flows, & double-spend protection