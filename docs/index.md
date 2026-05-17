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
├── 📂 05_core_logic/                           # Atomic Transactions, Fulfillment Engines, & Data Integrity
│   ├── partial_fulfillment_and_ledger_audit.md # Architectural strategy for incremental unit tracking
│   └── partial_fulfillment_and_ledger_implementation.md # Logic execution ledger for data locking
│
├── 📂 05_medical_logic/                        # Medical Constraints, Gamification, & Resilience Layers
│   ├── blood_compatibility.md                  # Biological rules matrix via `BloodLogic` utility class
│   ├── donation_history.md                     # Inter-connected atomic donation logs & core transaction triggers
│   ├── offline_mode.md                         # Offline-First architecture via local `PendingActionsService`
│   ├── points_rewards_system.md                # In-app gamification engine, emergency multipliers, & tier structures
│   └── points_rewards_sponsor.md               # Sponsor dashboard, QR redemption flows, & double-spend protection
│
├── 📂 06_settings_and_developer/               # App Configuration & Developer Identity
│   └── production_settings_refactor.md         # Enterprise-grade settings overhaul & Developer Profile
│
└── 📂 codex/                                   # Deep-Dive Implementation Logs (Graduation Thesis)
    ├── 01_project_structure_overview.md
    ├── 02_network_routing_engine.md
    ├── 03_concurrency_and_integrity.md
    ├── 04_edge_resilience.md
    ├── 05_state_management_architecture.md
    ├── 06_iam_and_domain_logic.md
    ├── 07_presentation_and_ui_architecture.md
    ├── 08_database_schema_and_nosql_modeling.md
    ├── 09_system_workflows_and_lifecycle.md
    ├── 10_scalability_and_network_traffic_model.md
    ├── 11_trust_and_anti_abuse_model.md
    └── 12_agent_architectural_synthesis.md
```

---

## 🎓 Phase 3: Deep-Dive Implementation Logs (Graduation Thesis Codex)

This section contains the comprehensive technical foundation for the graduation thesis, mapping the platform's evolution from a mobile prototype to a production-hardened healthcare system.

| Module | Title | Path | Engineering Domain |
|:---:|:---|:---|:---|
| **01** | **Project Structure Overview** | [01_project_structure_overview.md](codex/01_project_structure_overview.md) | A macro-level X-ray of the Flutter directory hierarchy and architectural boundaries. It identifies the hybrid transition between feature-first UI and repository-backed layers. |
| **02** | **Network Routing Engine** | [02_network_routing_engine.md](codex/02_network_routing_engine.md) | Analysis of the distributed notification pipeline using FCM data-only payloads and edge orchestration. It details how events are routed through a client-side messaging engine to donor nodes. |
| **03** | **Concurrency and Integrity** | [03_concurrency_and_integrity.md](codex/03_concurrency_and_integrity.md) | Examination of Firestore transactions as a distributed coordination primitive for donation registration. It ensures ACID properties across fulfillment counters, medical ledger locks, and audit records. |
| **04** | **Edge Resilience** | [04_edge_resilience.md](codex/04_edge_resilience.md) | Documentation of the offline-first synchronization queue and emergency state shielding. It details how the system preserves user intent and critical routing context during network partitions. |
| **05** | **State Management** | [05_state_management_architecture.md](codex/05_state_management_architecture.md) | Deep dive into the Riverpod-based reactive data flow and feature-scoped command controllers. It separates continuously changing data streams from imperative business orchestration. |
| **06** | **IAM and Domain Logic** | [06_iam_and_domain_logic.md](codex/06_iam_and_domain_logic.md) | Modeling of Role-Based Access Control (RBAC) and deterministic medical rules. It links authenticated identities to tenant-scoped hospital contexts and blood compatibility logic. |
| **07** | **Presentation Layer** | [07_presentation_and_ui_architecture.md](codex/07_presentation_and_ui_architecture.md) | Overview of the Material 3 design system and component-driven UI pattern. It details the centralized theming and ARB-backed localization strategy for multilingual environments. |
| **08** | **NoSQL Data Modeling** | [08_database_schema_and_nosql_modeling.md](codex/08_database_schema_and_nosql_modeling.md) | Mapping of the query-optimized Firestore collection hierarchy and denormalization strategies. It defines the entity relationships and data dictionary for the entire distributed system. |
| **09** | **System Workflows** | [09_system_workflows_and_lifecycle.md](codex/09_system_workflows_and_lifecycle.md) | Synthesis of end-to-end user journeys from request creation to final fulfillment. It connects human actions to technical state transitions across the platform's multi-actor ecosystem. |
| **10** | **Scalability & Traffic** | [10_scalability_and_network_traffic_model.md](codex/10_scalability_and_network_traffic_model.md) | Cloud systems analysis of bandwidth efficiency and Firestore contention bottlenecks. It models the cost and throughput of high-load disaster scenarios and proposes a backend roadmap. |
| **11** | **Trust & Anti-Abuse** | [11_trust_and_anti_abuse_model.md](codex/11_trust_and_anti_abuse_model.md) | Evaluation of the "Zero-Trust Edge" architecture and hospital-centric verification anchors. It details the defensive layers protecting the platform from fake emergencies and medical tampering. |
| **12** | **Architectural Synthesis** | [12_agent_architectural_synthesis.md](codex/12_agent_architectural_synthesis.md) | The final AI-generated evaluation of the system's reality, technical debt, and milestone roadmap. It provides the concluding engineering opinion and hardening recommendations. |
