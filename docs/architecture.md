# Fieldify — Architecture Decisions

This document records the key backend technology decisions for Fieldify, including the options considered, trade-offs evaluated, and the final choices made.

---

## 1. Real-Time Data Sync

### Context

Fieldify requires real-time data sync in two critical flows:

- **Job request matching** — when a client submits a request, nearby professionals must be notified immediately and the first to accept claims the job.
- **Job lifecycle updates** — state changes (e.g. "On my way", "In progress", "Complete") must push to both the client and the professional in real time.

### Options Considered

#### Firestore (Firebase)

Firestore is Google's NoSQL document database with real-time sync built in from day one. It uses WebSocket-based event listeners and has excellent offline persistence via client-side caching.

**Pros:**
- Real-time sync is deeply integrated and requires minimal setup.
- Offline-first by default — changes are queued and synced when connectivity is restored.
- Well-documented Flutter SDK (`cloud_firestore`).
- Scales automatically with no configuration.

**Cons:**
- NoSQL document model does not match Fieldify's relational data (jobs, users, payments, credentials are naturally relational).
- Complex queries often require denormalization or multiple reads, increasing cost and complexity.
- Querying across collections (e.g. "all open jobs near a location for a given trade") is cumbersome.
- Google vendor lock-in with no self-hosting option.

#### Supabase Realtime

Supabase Realtime is built on PostgreSQL's logical replication (WAL) and broadcasts table-level changes to subscribed clients via WebSockets. Clients subscribe to specific tables or filtered rows.

**Pros:**
- Built on PostgreSQL — Fieldify's relational data model (jobs, professionals, payments) maps directly to tables with joins, foreign keys, and transactions.
- Real-time subscriptions can be filtered using SQL predicates (e.g. subscribe only to job requests for a given trade and location).
- Same platform as auth and file storage — one SDK, one dashboard, one free tier.
- Open-source and self-hostable.
- Free tier supports 200 concurrent connections and 2 million messages/month — sufficient for academic deadline and early business stage.

**Cons:**
- Offline persistence is less mature than Firestore's. No automatic client-side cache and sync-on-reconnect.
- Realtime is built on Postgres replication which has scaling ceilings at very high concurrency (not relevant at this stage).

### Decision: Supabase Realtime ✅

**Rationale:** Fieldify's data is inherently relational — a job has a client, a professional, a payment, a state, and a set of notifications. Forcing this into Firestore's document model would require significant denormalization and make querying fragile. Supabase Realtime gives us precise, SQL-filtered subscriptions which maps directly to the job matching flow: subscribe to new job requests filtered by `trade = 'plumbing'` and `status = 'pending'`, and push to relevant professionals. The lack of mature offline support is an acceptable trade-off — Fieldify is not an offline-first app (a plumber needs connectivity to navigate to a job anyway).

Additionally, using Supabase consolidates auth, database, real-time, and storage into a single platform, reducing integration complexity for the team.

---

## 2. File Storage

### Context

Fieldify needs to store two categories of files:

- **Job photos** — images attached by clients when submitting a job request (e.g. photo of the broken pipe).
- **Credential documents** — uploaded by professionals during verification (e.g. IMPIC certificate, DGEG registration).
- **Profile pictures** — optional, for both clients and professionals.

### Options Considered

#### Firebase Storage

Firebase Storage is backed by Google Cloud Storage, with tight integration into the Firebase ecosystem and its Security Rules system.

**Pros:**
- Battle-tested at scale with Google infrastructure.
- Good Flutter SDK.
- Offline upload resumability out of the box.

**Cons:**
- Adds Firebase as a second vendor if we are already using Supabase for everything else.
- Security rules are written in a separate JavaScript-like syntax, decoupled from the database access rules.
- Pricing can escalate unexpectedly at scale.

#### AWS S3

S3 is the industry standard for object storage, used by most production applications at scale.

**Pros:**
- Extremely reliable, globally distributed, industry standard.
- Fine-grained IAM permissions.

**Cons:**
- Requires a separate AWS account, IAM configuration, bucket policies, and CORS setup.
- Overkill for a project at this stage — significant operational overhead for zero benefit over simpler options.
- No auth integration — access control must be implemented manually.

#### Supabase Storage

Supabase Storage is an S3-compatible object storage layer built into the Supabase platform. Access control is enforced through Row-Level Security (RLS) policies written in SQL — the same system used for database access.

**Pros:**
- Fully integrated with Supabase Auth and database — no separate service or SDK needed.
- Access policies use SQL and reference the same `auth.uid()` used in database RLS.
- Free tier includes 1 GB storage and 50 MB max file upload size — sufficient for a university project and early testing.
- S3-compatible, so migration to a dedicated S3 bucket later is straightforward.

**Cons:**
- 1 GB free tier limit — credential documents and job photos could fill this quickly in production. Upgrade to Pro ($25/month) for 100 GB when needed.
- Not as battle-tested as Firebase Storage or AWS S3 at very large scale.

### Decision: Supabase Storage ✅

**Rationale:** The integration advantage is decisive. With Supabase Storage, a policy like "a professional can only read their own credential documents" is a single SQL rule that references the same auth context as the rest of the system. Adding Firebase Storage or AWS S3 would mean managing a second set of access rules in a completely different syntax, a second SDK, and a second service to monitor. For the current project scope the 1 GB free tier is sufficient, and the migration path to more storage is trivial.

---

## 3. Authentication

### Options Considered

#### Firebase Auth

Firebase Authentication supports email/password, phone OTP, and social OAuth providers, with deep integration into the rest of Firebase's ecosystem.

**Pros:**
- Mature, battle-tested, used at scale by millions of apps.
- Excellent Flutter SDK (`firebase_auth`).
- Strong offline token caching.
- Deep integration with Firestore and Firebase Storage Security Rules.

**Cons:**
- Proprietary — users and sessions are locked into Google's infrastructure with no export path.
- Security rules (which gate data access based on auth state) are written in a separate syntax from the database queries.
- If we are not using Firestore or Firebase Storage, the integration advantage disappears entirely.

#### Supabase Auth

Supabase Auth is built on GoTrue, an open-source auth server. It supports email/password, magic link, phone OTP, and social OAuth. JWTs are issued and verified directly by the Supabase platform.

**Pros:**
- Fully integrated with the Supabase database via RLS — the `auth.uid()` function is available in any SQL policy, so "a user can only read their own profile" is one line of SQL.
- Open-source and self-hostable — no vendor lock-in, user data is owned by the project.
- Good Flutter SDK (`supabase_flutter`).
- Free tier supports 50,000 monthly active users — far beyond current needs.
- Email/password and phone OTP are both supported — relevant for Portuguese tradespeople who may prefer phone-based sign-in.

**Cons:**
- Offline token handling is less sophisticated than Firebase Auth.
- Slightly less mature than Firebase Auth — the ecosystem of tutorials and edge-case documentation is smaller.

### Decision: Supabase Auth ✅

**Rationale:** Since the database and file storage are already on Supabase, using Supabase Auth is the natural choice. The unified RLS system means that authentication state flows directly into all data access rules without any additional configuration. A professional's credentials, jobs, and uploaded documents can all be scoped to `auth.uid()` using the same SQL syntax. Using Firebase Auth alongside Supabase would require bridging two auth systems, duplicating user state, and writing access rules twice in incompatible syntaxes.

---

## Summary

| Concern | Decision | Rationale |
|---|---|---|
| Real-time sync | Supabase Realtime | SQL-filtered subscriptions match Fieldify's relational job-matching flow |
| File storage | Supabase Storage | Unified RLS with database; S3-compatible for future migration |
| Authentication | Supabase Auth | Single auth context across database, storage, and real-time via RLS |

All three concerns are handled by **Supabase** as a single platform. This reduces the number of SDKs, accounts, dashboards, and access control systems the team must manage. The Supabase free tier is sufficient for the academic deadline and early post-launch stage.