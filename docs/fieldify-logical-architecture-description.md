# Logical Architecture

The Fieldify logical architecture is represented as a UML package diagram and describes the functional organisation of the system independent of any specific technology. It is structured into four layers — Presentation, Application Services, Data, and External Services — each with a distinct responsibility and a defined direction of dependency.

## Presentation layer

The presentation layer contains the two user-facing interfaces of the MVP: the Client UI and the Professional UI. The Client UI handles service request submission, job tracking, messaging, payment visibility, and review submission. The Professional UI handles job discovery and acceptance, status progression, availability configuration, credential submission, and earnings overview. Both interfaces depend downward on the application services layer and have no direct dependency on the data layer — they never query storage or the database directly. An Admin UI is planned for a post-MVP release to support in-platform verification and platform oversight; in the MVP, these operations are handled manually.

## Application services layer

The application services layer contains all domain logic and orchestration. It is the only layer that enforces business rules, and it acts as the intermediary between the presentation layer above and the data and external services layers below.

`User Management` handles account registration, login, session management, and role assignment. It depends on both `Persistence` for storing user records and `Identity` for issuing and validating authentication tokens.

`Job Orchestration` is the most central service, managing the full job lifecycle from submission through completion. It enforces the status state machine, coordinates with `Matching` to identify eligible professionals, triggers `Notification Service` on every status transition, and delegates payment actions to `Payment Processing` at the appropriate lifecycle points.

`Matching` filters incoming job requests against professional availability, trade, and location parameters to determine which professionals should receive a given request. It reads from `Persistence` and is invoked by `Job Orchestration` at the point of submission.

`Payment Processing` manages the full Stripe payment lifecycle: card authorisation when a professional taps "on my way", charge capture on job completion, cancellation fee collection where applicable, and payout scheduling after the 24-hour hold. It depends on `Persistence` for recording payment state and on the `Payment Gateway` external service for all financial operations.

`Messaging` handles job-scoped chat between clients and professionals. It reads and writes message records through `Persistence` and enforces the read-only constraint once a job reaches completed status.

`Notification Service` is responsible for all outbound alerts — push notifications for job status changes, new messages, and payment events, as well as transactional emails for account events. It delegates delivery to the `Push Notifications` and `Email / SMS` external services.

`Verification` manages the professional onboarding workflow: credential document upload and approval or rejection of submissions. It stores file paths in `Persistence` as part of the professional profile and the actual files in `File Storage`. In the MVP, verification decisions are made manually outside the platform; the service layer is structured to support an in-platform admin review workflow post-MVP.

`Review & Rating` handles post-job feedback. It writes reviews to `Persistence`. Professional ratings are not stored as a denormalised field — they are computed on demand via a database view that aggregates across all reviews for a given professional, keeping the data model normalised and eliminating any trigger-based maintenance.

`File Management` is a thin service responsible for coordinating uploads and access to files stored in `File Storage` — job photos, credential documents, and profile pictures.

## Data layer

The data layer is responsible for all persistence concerns. It exposes no business logic — it stores and retrieves data as instructed by the application services layer.

`Persistence` represents the relational database, holding all domain data: users, professional profiles, jobs, messages, payments, reviews, credentials, and photos. Row-level security policies ensure that data access is scoped to the authenticated user at the database level, providing a second enforcement layer beneath the application logic.

`File Storage` holds binary objects — photos, credential documents, and avatars — as references rather than inline data. Access is controlled by policies consistent with those in `Persistence`, using the same authentication context.

`Identity` manages authentication sessions and token issuance. It is the source of the authenticated user context that both `Persistence` and `File Storage` rely on for access control.

## External services

The external services layer contains third-party integrations that the application services layer depends on for capabilities outside the platform's core domain.

The `Payment Gateway` (Stripe) handles all financial operations. It is called exclusively through server-side edge functions — never directly from the client — to ensure that secret credentials are never exposed in the mobile application.

`Push Notifications` (Firebase Cloud Messaging) handles the last-mile delivery of push alerts to mobile devices. Notification dispatch is triggered by edge functions invoked from database events.

`Mapping` (Google Maps Platform) provides geocoding and map rendering. The Maps SDK is initialised client-side in the Flutter application and makes requests directly to the Google Maps API using a publishable key.

`Email / SMS` covers transactional email for account verification and significant platform events, dispatched through the `Notification Service` via an SMTP provider.