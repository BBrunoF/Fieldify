<!-- Template file for README.md for LEIC-ES-2025-26 -->

> [!NOTE] In this file, you will find the structure you should follow to document your mobile app in the README.md file for LEIC-ES-2025-26. It is a single file with guidelines, as comments, only seen in Edit mode, not in Preview mode. You can add more sections, but for assessment reasons and automation, please make sure to include all sections of this template. Your professors will clarify about specificities of your app.

# _Fieldify_ Development Report

Welcome to the documentation of _Fieldify_!

This Software Development Report, tailored for LEIC-ES-2025-26, provides comprehensive details about _Fieldify_, starting from an high-level vision and going into low-level implementation decisions. 

It is organised by the following activities: 

* [Business modeling](#Business-Modelling) 
  * [Product Vision](#Product-Vision)
  * [Features and Assumptions](#Features-and-Assumptions)
* [Requirements](#Requirements)
  * [User stories](#User-stories)
  * [Domain model](#Domain-model)
  * [User interfaces](#User-interfaces)
* [Architecture and Design](#Architecture-And-Design)
  * [Logical architecture](#Logical-Architecture)
  * [Physical architecture](#Physical-Architecture)
  * [Functional prototype](#Functional-Prototype)
* [Project management](#Project-Management)
  * [Sprint 0](#Sprint-0)
  * [Sprint 1](#Sprint-1)
  * [Sprint 2](#Sprint-2)
  * [Sprint 3](#Sprint-3)
  * [Final Release](#Final-Release)
* [Documentation](#documentation)
   * [Sprint Artifacts](#sprint-artifacts)
   * [Development](#development)

Contributions are expected to be made exclusively by the initial team, but we may open them to the community, after the course, in all areas and topics: requirements, technologies, development, experimentation, testing, etc.

Please contact us!

Thank you!

* Bruno Rafael Bessa Freitas : brunofreitas0465@gmail.com
* Tiago Morais Amaral : tmamaral2006@gmail.com
* Tomás Manuel Almeida Ribeiro : tomasribeir2006@gmail.com
* João António Neiva Amaro : up202403344@g.uporto.pt
* José Pedro Rocha da Costa : jprcosta06@gmail.com

---
## Business Modelling

Business modeling in software development involves defining the product's vision, understanding market needs, aligning features with user expectations, and setting the groundwork for strategic planning and execution.

### Product Vision
Fieldify is a mobile app that allows clients to find and request service professionals, while helping freelancers and service companies receive jobs, manage work, and coordinate technicians in one simple and organized system.
<!-- 
Start by defining a clear and concise product vision for your app, to help members of the team, contributors, and users into focusing their often disparate views into a concise, visual, and short textual form. 

The vision should provide a "high concept" of the product for marketers, developers, and managers.

A product vision describes the essential of the product and sets the direction to where a product is headed, and what the product will deliver in the future. 

**We favor a catchy and concise statement, ideally one sentence.**

We suggest you use the product vision template described in the following link:
* [How To Create A Convincing Product Vision To Guide Your Team, by uxstudioteam.com](https://uxstudioteam.com/ux-blog/product-vision/)

To learn more about how to write a good product vision, please read:
* [Vision, by scrumbook.org](http://scrumbook.org/value-stream/vision.html)
* [Product Management: Product Vision, by ProductPlan](https://www.productplan.com/glossary/product-vision/)
* [20 Inspiring Vision Statement Examples (2019 Updated), by lifehack.org](https://www.lifehack.org/articles/work/20-sample-vision-statement-for-the-new-startup.html)
-->


### Features and Assumptions
#### High-Level Features

* Service Request Submission – Clients can submit service requests with description, location, photos, and preferred time window.
* Professional Discovery – Clients can find available freelancers or service companies by category and location.
* Job Assignment & Acceptance – Jobs can be automatically routed or manually assigned and accepted by technicians.
* Job Lifecycle Management – Structured job states from request to completion.
* Scheduling & Availability Management – Calendar view with defined working hours and service areas.
* Technician Management – Company admins can manage multiple technicians and assign roles.
* Client Management – Storage of client information, job history, and internal notes.
* Real-Time Notifications – Alerts for new requests, assignments, status changes, and completion.
* Attachments & Documentation – Photo uploads, notes, and job-related files.
* Ratings & Feedback – Clients can rate completed services.
* Multi-Tenant Workspaces – Separate isolated environments for each freelancer or company.
* Analytics Dashboard – Overview of job volume, completion rates, and performance metrics.


#### Initial Assumptions

* Users have access to smartphones with internet connectivity.
* Location services are available for address validation and service area filtering.
* Push notifications are supported by the device operating system.
* Payment processing (if implemented) will rely on third-party providers.
* The platform initially targets small to medium service providers rather than large enterprises.

<!-- 
Indicate an  initial/tentative list of high-level features - high-level capabilities or desired services of the system that are necessary to deliver benefits to the users.
 - Feature XPTO - a few words to briefly describe the feature
 - Feature ABCD - ...
...

Optionally, indicate an initial/tentative list of assumptions that you are doing about the app and dependencies of the app to other systems.
-->

## Requirements

### User Stories
#### Client Perspective
The client experience focuses on accessibility and service management. Users can register and manage their profiles, submit specific service requests, and track their history through an active and past jobs view. The platform facilitates seamless interaction via a direct messaging system with professionals and an automated payment process. Additionally, clients receive real-time updates through push notifications and can maintain service quality by rating and reviewing completed jobs or cancelling them when necessary.

#### Freelancer Perspective
The freelancer workflow is designed for professional autonomy and efficient job handling. After a verification and approval process, professionals can set their availability, service parameters, and discover new job opportunities. The dashboard provides a comprehensive overview of their activity, allowing them to accept tasks, control job statuses, and manage rescheduling or cancellations. Communication is streamlined through a client messaging system, while profile management ensures their professional presence is always up to date.

<!-- 
In this section you should describe all kinds of requirements for your module: functional and non-functional requirements.
---

For LEIC-ES-2025-26, the requirements will be gathered and documented as user stories. 

Please add in this section a concise summary of all the user stories (not each user story!).

**User stories as GitHub Project Items**
The user stories themselves should be created and described as items in your GitHub Project with the label "user story". 

A user story is a description of a desired functionality told from the perspective of the user or customer. A starting template for the description of a user story is *As a < user role >, I want < goal > so that < reason >.*

Name the item with either the full user story or a shorter name (recommended). In the “comments” field, add relevant notes, mockup images, and acceptance test scenarios, linking to the acceptance tests when available, and finally estimate value and effort.

**INVEST in good user stories**. 
You may add more details after, but the shorter and complete, the better. In order to decide if the user story is good, please follow the [INVEST guidelines](https://xp123.com/articles/invest-in-good-stories-and-smart-tasks/).

**User interface mockups**.
After the user story text, you should add a draft of the corresponding user interfaces, a simple mockup or draft, if applicable.

**Acceptance tests**.
For each user story you should write also the acceptance tests (textually in [Gherkin](https://cucumber.io/docs/gherkin/reference/)), i.e., a description of scenarios (situations) that will help to confirm that the system satisfies the requirements addressed by the user story.

**Value and effort**.
At the end, it is good to add a rough indication of the value of the user story to the customers (e.g. [MoSCoW](https://en.wikipedia.org/wiki/MoSCoW_method) method) and the team should add an estimation of the effort to implement it using points in a kind-of-a Fibonnacci scale (1,2,3,5,8,13,20,40, no idea).

-->

### Domain model


The Fieldify domain model captures the core concepts of the platform and the relationships between them. It is represented as a UML class diagram using entities and associations, reflecting the relational structure of the underlying database.

The central entity is `ServiceRequest`, which represents the full lifecycle of a service request from submission to completion. A single entity is used with a `status` field that progresses through a defined state machine: `pending → accepted → on_my_way → in_progress → completed`, with `cancelled` reachable from most intermediate states. Timestamp fields are populated progressively as the job advances — `pro_id` is null while the request is pending, and `accepted_at`, `on_my_way_at`, `started_at`, and `completed_at` are each set at their respective transitions. This approach keeps the data model compact and avoids joins between a request table and a job table for what is fundamentally the same object at different stages of its life. Client-submitted photos are stored as an array of Supabase Storage paths (`photo_urls`) directly on the `ServiceRequest` row, rather than as a separate entity, as photos are always fetched together with the request and have no independent lifecycle.

`ServiceRequestRejection` is a join entity between `Profile` (professional) and `ServiceRequest` that records which pending jobs a given professional has dismissed from their incoming-jobs feed. The composite primary key of `(pro_id, request_id)` ensures a professional cannot reject the same request twice, and allows the matching logic to cheaply filter rejected rows out of the feed without mutating the underlying request. Unlike a full cancellation, a rejection is a per-professional decision and leaves the `ServiceRequest` visible to other eligible professionals.

All platform users are represented by a single `Profile` entity with a `role` field distinguishing clients, professionals, and admins. The `Profile` row is created automatically via a database trigger on `auth.users` insertion, populated from registration metadata. Professionals have an associated `ProfessionalProfile` entity in a one-to-one optional relationship with `Profile`. This entity holds all professional-specific data: trade, NIF, verification status, service radius, and base location. Clients simply have no corresponding `ProfessionalProfile` row, keeping the base `Profile` table clean.

`Profile` also holds a `stripe_customer_id` field, populated the first time a client adds a payment method. This links the platform user to their corresponding Stripe Customer object and is reused across all subsequent jobs, avoiding the creation of duplicate Stripe customers.

The `Trade` entity is a reference table representing the categories of service available on the platform — plumbing, electrical, carpentry, HVAC, painting, and other. Each trade carries a `standard_rate` that serves as the platform-defined hourly rate for that category. This rate is the source of truth for billing calculations and is referenced by both `ProfessionalProfile` and `ServiceRequest`. The trade list is seeded at deployment and managed by the platform; it is not user-generated.

Professionals submit credential documents during onboarding, stored as an array of Supabase Storage paths (`credential_urls`) on the `ProfessionalProfile` row. Documents vary per professional in both type and quantity, so a flat array is used rather than a separate credentials table. Admin reviewers access the files directly via signed URLs. Verification status is tracked on `ProfessionalProfile` via a `verification_status` field with states `pending`, `approved`, and `rejected`, and a `rejection_reason` field populated only on rejection.

`AvailabilitySchedule` captures the weekly working hours of a professional. One row is stored per day of the week per professional, allowing independent configuration of start and end times for each day. Days on which the professional does not work simply have no row. This is separate from the `is_available` boolean on `ProfessionalProfile`, which is a live toggle controlled by the professional in real time. Matching logic checks both: a professional must be generally available for that day and have their live toggle active.

`PaymentMethod` represents a saved card belonging to a client, backed by a Stripe `PaymentMethod` object. Display fields (`card_brand`, `card_last4`) are stored locally to avoid a Stripe API call on every render. Card validity is confirmed at save time via a Stripe `SetupIntent`. One method may be marked as default per client.

`Payment` is created when a professional taps "on my way", at which point the client's card is authorised via Stripe using the saved `PaymentMethod`. The entity tracks the full payment lifecycle: `authorised`, `captured`, `cancelled`, and `refunded`. The charge is calculated as the greater of the actual duration or a 30-minute minimum, multiplied by the trade's `standard_rate`, plus a 10% platform fee stored explicitly in `platform_fee` for accounting purposes. A 24-hour hold is applied before the professional payout, tracked via `payout_at`.

`Review` is written by the client after job completion. A unique constraint on `request_id` enforces one review per job at the database level. The rating is a required integer between 1 and 5; a text comment is optional. Rather than storing a denormalised average rating on `ProfessionalProfile`, the platform computes ratings via a database view (`pro_ratings`) that aggregates across all `Review` rows for a given professional. This keeps the data model normalised and eliminates the need for triggers to maintain a derived field.

`Message` represents individual chat messages exchanged between a client and a professional, scoped to a `ServiceRequest`. The job identifier serves as the conversation context, eliminating the need for a separate thread or conversation entity. The `sender_id` foreign key references `Profile` directly, covering both directions. The other party is always derivable from the `ServiceRequest` itself. Write access is enforced at the application level once the parent job reaches `completed` status, making the thread read-only.


 <p align="center" justify="center">
  <img width="466" height="406" alt="image" src="https://github.com/user-attachments/assets/02ca9194-afad-49c0-9db5-8de4d2d0cdf1" />
</p>



### User interfaces

#### Authentication and Profile
| Login & Registration | User Profile |
| :---: | :---: |
| <img src="https://github.com/user-attachments/assets/47ddf75d-055b-48c7-97dd-a5cce7b1cabb"  width="400" alt="Auth"> | <img   src="https://github.com/user-attachments/assets/22c831a0-9c87-40a3-9b6f-91ff4bff065c" width="400" alt="Profile"> |

#### Client Portal - Search and Request
| Home and Search | Service Request |
| :---: | :---: |
| <img  src="https://github.com/user-attachments/assets/da8b8384-1bf1-49e8-aebe-8b37c48e5e55" width="400" alt="Home"> | <img src="https://github.com/user-attachments/assets/7d76ea31-00d9-40c9-9a95-707f22332595"  width="400" alt="Request"> |

#### Client Portal - Management
| Jobs List | Job Details |
| :---: | :---: |
| <img  src="https://github.com/user-attachments/assets/bd028ff5-71ea-49c3-975c-4a310c04174c" width="400" alt="Jobs"> | <img src="https://github.com/user-attachments/assets/432954bc-b2a5-4993-96d3-4cb25864da33"  width="400" alt="Detail"> |

#### Professional Portal
| Pro Dashboard | Job Management |
| :---: | :---: |
| <img  src="https://github.com/user-attachments/assets/d70b3522-fea7-4df4-bb2f-8b4d675a838a" width="400" alt="Pro Home"> | <img  src="https://github.com/user-attachments/assets/fdeb5271-e0ff-4725-80bc-a1e2815b39df" width="400" alt="Pro Jobs"> |

#### Communication
| Messaging System | Messaging List |
| :---: | :---: |
| <img  src="https://github.com/user-attachments/assets/6d56a321-da5b-4ff7-981e-f7f680a83770" width="400" alt="Messaging"> | <img   src="https://github.com/user-attachments/assets/0c9344d9-6e8f-4e22-93c8-593c0d977003" width="400" alt="Messaging"> |



## Architecture and Design


<!--
The architecture of a software system encompasses the set of key decisions about its organization. 

A well written architecture document is brief and reduces the amount of time it takes new programmers to a project to understand the code to feel able to make modifications and enhancements.

To document the architecture requires describing the decomposition of the system in their parts (high-level components) and the key behaviors and collaborations between them. 

In this section you should start by briefly describing the components of the project and their interrelations. You should describe how you solved typical problems you may have encountered, pointing to well-known architectural and design patterns, if applicable.
-->


### Logical architecture

The Fieldify logical architecture is represented as a UML package diagram and describes the functional organisation of the system independent of any specific technology. It is structured into four layers — Presentation, Application Services, Data, and External Services — each with a distinct responsibility and a defined direction of dependency.

#### Presentation layer

The presentation layer contains the two user-facing interfaces of the MVP: the Client UI and the Professional UI. The Client UI handles service request submission, job tracking, messaging, payment visibility, and review submission. The Professional UI handles job discovery and acceptance, status progression, availability configuration, credential submission, and earnings overview. Both interfaces depend downward on the application services layer and have no direct dependency on the data layer — they never query storage or the database directly. An Admin UI is planned for a post-MVP release to support in-platform verification and platform oversight; in the MVP, these operations are handled manually.

#### Application services layer

The application services layer contains all domain logic and orchestration. It is the only layer that enforces business rules, and it acts as the intermediary between the presentation layer above and the data and external services layers below.

`User Management` handles account registration, login, session management, and role assignment. It depends on both `Persistence` for storing user records and `Identity` for issuing and validating authentication tokens.

`Job Orchestration` is the most central service, managing the full job lifecycle from submission through completion. It enforces the status state machine, coordinates with `Matching` to identify eligible professionals, triggers `Notification Service` on every status transition, and delegates payment actions to `Payment Processing` at the appropriate lifecycle points.

`Matching` filters incoming job requests against professional availability, trade, and location parameters to determine which professionals should receive a given request. It reads from `Persistence` and is invoked by `Job Orchestration` at the point of submission.

`Payment Processing` manages the full Stripe payment lifecycle: card authorisation when a professional taps "on my way", charge capture on job completion, cancellation fee collection where applicable, and payout scheduling after the 24-hour hold. It depends on `Persistence` for recording payment state and on the `Payment Gateway` external service for all financial operations.

`Messaging` handles job-scoped chat between clients and professionals. It reads and writes message records through `Persistence` and enforces the read-only constraint once a job reaches completed status.

`Notification Service` is responsible for all outbound alerts — push notifications for job status changes, new messages, and payment events, as well as transactional emails for account events. It delegates delivery to the `Push Notifications` and `Email / SMS` external services.

`Verification` manages the professional onboarding workflow: credential document upload and approval or rejection of individual documents. It stores document metadata in `Persistence` and the actual files in `File Storage`. In the MVP, verification decisions are made manually outside the platform; the service layer is structured to support an in-platform admin review workflow post-MVP.

`Review & Rating` handles post-job feedback. It writes reviews to `Persistence` and triggers the update of the denormalised average rating on the professional's profile.

`File Management` is a thin service responsible for coordinating uploads and access to files stored in `File Storage` — job photos, credential documents, and profile pictures.

#### Data layer

The data layer is responsible for all persistence concerns. It exposes no business logic — it stores and retrieves data as instructed by the application services layer.

`Persistence` represents the relational database, holding all domain data: users, professional profiles, jobs, messages, payments, reviews, credentials, and photos. Row-level security policies ensure that data access is scoped to the authenticated user at the database level, providing a second enforcement layer beneath the application logic.

`File Storage` holds binary objects — photos, credential documents, and avatars — as references rather than inline data. Access is controlled by policies consistent with those in `Persistence`, using the same authentication context.

`Identity` manages authentication sessions and token issuance. It is the source of the authenticated user context that both `Persistence` and `File Storage` rely on for access control.

#### External services

The external services layer contains third-party integrations that the application services layer depends on for capabilities outside the platform's core domain.

The `Payment Gateway` (Stripe) handles all financial operations. It is called exclusively through server-side edge functions — never directly from the client — to ensure that secret credentials are never exposed in the mobile application.

`Push Notifications` (Firebase Cloud Messaging) handles the last-mile delivery of push alerts to mobile devices. Notification dispatch is triggered by edge functions invoked from database events.

`Mapping` (Google Maps Platform) provides geocoding and map rendering. The Maps SDK is initialised client-side in the Flutter application and makes requests directly to the Google Maps API using a publishable key.

`Email / SMS` covers transactional email for account verification and significant platform events, dispatched through the `Notification Service` via an SMTP provider.


 <p align="center" justify="center">
  <img width="466" height="216" alt="image" src="https://github.com/user-attachments/assets/0cef3f7e-b7f8-42ca-8383-7f629444afd9" />
</p>



### Physical architecture

The Fieldify physical architecture is represented as a UML deployment diagram and describes the runtime environment of the system — the actual nodes, services, and protocols through which the platform operates. It maps directly onto the technology decisions recorded in the architecture decision document.

#### Mobile device

The client-side runtime is a Flutter application installed on iOS or Android devices. It is the only entry point for both clients and professionals. The Google Maps SDK is initialised within the app and makes requests directly to the Google Maps Platform API using a publishable key, handling map rendering and geocoding entirely client-side without routing through any Fieldify-controlled server.

The Flutter app communicates with the Supabase cloud over two channels: HTTPS for database queries, authentication, file access, and edge function invocations; and a persistent WebSocket connection (WSS) to Supabase Realtime for live job status updates and incoming job notifications. This eliminates the need for polling — the app subscribes to specific rows and receives changes as they happen.

#### Supabase cloud

Supabase is the sole backend platform, consolidating four runtime concerns under a single managed service.

Supabase Auth, built on GoTrue, handles session management and JWT issuance. Every request from the Flutter app carries a JWT as a Bearer token, which Supabase validates before executing any database or storage operation. This token is also the mechanism through which Row-Level Security policies identify the acting user — the `auth.uid()` function is available in every RLS policy, scoping data access without any additional middleware.

The Postgres database stores all domain data: users, professional profiles, jobs, messages, payments, reviews, credentials, and file references. RLS policies enforce access control at the database level, providing a security boundary that is independent of application logic. Database triggers are used to maintain denormalised state — most notably, the `avg_rating` field on `ProfessionalProfile` is updated automatically on every review insert or update, and outbound webhook calls to Edge Functions are fired on job status transitions.

Supabase Realtime listens to Postgres's write-ahead log and broadcasts row-level changes to subscribed clients over WebSocket. Subscriptions are SQL-filtered — a professional's app subscribes only to job requests matching their trade and location, and a client's app subscribes only to status changes on their own jobs. This makes the real-time layer precise and efficient rather than broadcasting all changes to all connected clients.

Supabase Storage holds binary objects — job photos uploaded by clients, credential documents uploaded by professionals, and profile pictures. Files are referenced by storage path in the database and accessed via HTTPS. Access control is enforced through RLS policies that mirror those on the database, using the same `auth.uid()` context.

Edge Functions are server-side TypeScript functions running on Deno, deployed and managed within the Supabase platform. They serve two purposes: handling Stripe payment operations (authorisation, capture, refund, webhook processing) with the Stripe secret key stored as an environment variable; and dispatching push notifications to FCM on job lifecycle events. Critically, the Flutter app never calls the Stripe API directly — all payment operations are proxied through Edge Functions to ensure that secret credentials are never present in the client application.

#### External services

Stripe handles all financial operations. The Flutter app initiates payment flows by calling an Edge Function, which then communicates with the Stripe Payments API server-to-server. Stripe sends webhook events back to a dedicated Edge Function endpoint — for example, to confirm payment capture or flag a failed authorisation — which then updates the corresponding `Payment` row in Postgres.

Firebase Cloud Messaging handles push notification delivery to mobile devices. Edge Functions dispatch notification payloads to the FCM HTTP v1 API, which manages the last-mile delivery to the target device. Each user's FCM device token is captured by the Flutter app on first launch and stored on their `User` row, giving the backend a target for every active device.

The Google Maps Platform provides geocoding and map tile rendering. As noted above, this integration is entirely client-side and does not interact with any Fieldify backend service.

An SMTP provider handles transactional email — account verification messages and significant platform events. Email dispatch is triggered through the Notification Service via Edge Functions.


 <p align="center" justify="center">
  <img width="466" height="310" alt="image" src="https://github.com/user-attachments/assets/f5c76eb2-28b3-4746-b450-46b22988e19f" />
</p>



### Functional prototype
<!--
To help on validating all the architectural, design and technological decisions made, we usually implement a functional prototype, a thin vertical slice of the system integrating as much technologies as we can.

In this subsection please describe which feature, or part of it, you have implemented, and how, together with a snapshot of the user interface, if applicable.

At this phase, instead of a complete user story, you can simply implement a small part of a feature that demonstrates thay you can use the technology, for example, show a screen with the app credits (name and authors).
-->

## Project management
<!--
Software project management is the art and science of planning and leading software projects, in which they are planned, implemented, monitored and controlled.

In the context of ESOF, we recommend each team to adopt a set of project management practices and tools capable of registering tasks, assigning tasks to team members, adding estimations to tasks, monitor tasks progress, and therefore being able to track their projects.

Common practices of managing agile software development with Scrum are: backlog management, release management, estimation, Sprint planning, Sprint development, acceptance tests, and Sprint retrospectives.

You can find below information and references related with the project management: 

* Backlog management: Product backlog and Sprint backlog in a [Github Projects board](https://github.com/orgs/FEUP-LEIC-ES-2023-24/projects/64);
* Release management: [v0](#), v1, v2, v3, ...;
* Sprint planning and retrospectives: 
  * plans: screenshots of Github Projects board at begin and end of each Sprint;
  * retrospectives: meeting notes in a document in the repository, addressing the following questions:
    * Did well: things we did well and should continue;
    * Do differently: things we should do differently and how;
    * Puzzles: things we don’t know yet if they are right or wrong;
    * list of a few improvements to implement next Sprint;

-->

### Sprint 0

### Sprint 1

#### Start

<img width="1914" height="866" alt="image" src="https://github.com/user-attachments/assets/79d5b796-c9fe-4a9c-908d-6d791d06b7ef" />
<img width="1912" height="699" alt="image" src="https://github.com/user-attachments/assets/75b72f43-1de2-4691-ad1b-2c601bef427d" />
<img width="1919" height="734" alt="image" src="https://github.com/user-attachments/assets/a3b57cf9-d8e5-4339-8d2f-4b07b595bc4d" />
<img width="1903" height="732" alt="image" src="https://github.com/user-attachments/assets/86bbc6cd-fdf8-4a6e-b169-62d7c89f99ab" />

#### End

<img width="1858" height="769" alt="image" src="https://github.com/user-attachments/assets/3c9c4cf9-1040-490f-aab8-b2945f1e9344" />
<img width="1806" height="714" alt="image" src="https://github.com/user-attachments/assets/c0dbbd98-ffa4-4d07-a451-7cc50d1e6458" />
<img width="1755" height="707" alt="image" src="https://github.com/user-attachments/assets/bb7fa582-49c3-44d1-becf-0e6b9b7b88da" />
<img width="1776" height="479" alt="image" src="https://github.com/user-attachments/assets/618e9d66-6a0c-4f1d-871e-c6945de11952" />


### Sprint 2

#### Start
<img width="1804" height="768" alt="image" src="https://github.com/user-attachments/assets/63a11ab5-9635-4afa-8981-f8222f382a38" />
<img width="1782" height="697" alt="image" src="https://github.com/user-attachments/assets/7fea234f-f945-46b7-8586-b992bc84b83e" />
<img width="1826" height="710" alt="image" src="https://github.com/user-attachments/assets/3e16ec7d-ce91-4b1b-aba4-da1f9e9a1853" />
<img width="1773" height="225" alt="image" src="https://github.com/user-attachments/assets/171e3aa7-d61a-4877-8906-9b19aaf85296" />




#### End


### Sprint 3

### Sprint 4

### Final Release



## Documentation

### Sprint Artifacts
- [Changelog](docs/CHANGELOG.md)
- [Sprint Retrospective](docs/RETROSPECTIVE_SPRINT.md)
- [Bug Tracking](docs/BUG_TRACKING.md)

### Development
- [Setup Guide](docs/SETUP.md)
- [AI Usage](docs/AI_usage.md)

