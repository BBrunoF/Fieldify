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

---

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
<!-- 
In this section you should describe all kinds of requirements for your module: functional and non-functional requirements.

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

The central entity is `Job`, which represents the full lifecycle of a service request from submission to completion. Rather than modelling a request and a job as separate entities, a single `Job` entity is used with a status field that progresses through a defined state machine: `pending → accepted → on_my_way → in_progress → completed`, with `cancelled` reachable from most intermediate states. Fields are populated progressively as the job advances — `professional_id` is null while the job is pending, `accepted_at` is set on acceptance, `started_at` when work begins, and `amount_charged` on completion. This approach keeps the data model compact and avoids joins between a request table and a job table for what is fundamentally the same object at different stages of its life.

All platform users are represented by a single `User` entity with a `role` field distinguishing clients and professionals. Rather than creating separate client and professional tables — which would leave many fields empty depending on role — a profile extension pattern is used. Professionals have an associated `ProfessionalProfile` entity in a one-to-one optional relationship with `User`. This entity holds all professional-specific data: trade, hourly rate, location, NIF, verification status, and average rating. Clients simply have no corresponding `ProfessionalProfile` row, keeping the base `User` table clean. An admin role is reserved in the data model for post-MVP implementation but is not surfaced in the MVP interface.

The `ProfessionalProfile` entity holds an `avg_rating` field that is intentionally denormalised. Rather than computing an average across all `Review` rows on every profile load — which would be a frequent and expensive aggregation — the value is maintained by a database trigger that updates it whenever a review is inserted or updated. This is a deliberate performance trade-off documented here to distinguish it from an oversight.

Professionals submit credential documents during the verification process, represented by the `Credential` entity. Each credential belongs to a professional and carries its own approval status, allowing individual documents to be approved or rejected independently. In the MVP, verification approval is handled manually outside the platform; the data model is structured to support an in-platform admin verification workflow post-MVP.

`JobPhoto` captures images attached by the client at submission time. These are stored as file references (storage paths) rather than binary data, with the actual files held in Supabase Storage and access controlled by RLS policies mirroring those on the database.

`Message` represents individual chat messages exchanged between a client and a professional. Messaging is scoped to a `Job` — the job identifier is the conversation context, eliminating the need for a separate thread or conversation entity. Both parties are `User` rows, and the `sender_id` foreign key covers both directions. Write access is enforced at the application level when the parent job reaches `completed` status, making the thread read-only.

`Payment` is generated when a professional taps "on my way", at which point the client's card is authorised via Stripe. The entity tracks the full payment lifecycle: authorisation, capture on job completion, and the 24-hour hold before professional payout. The charge is calculated as the greater of the actual duration or a 30-minute minimum, multiplied by the hourly rate, plus a 10% platform fee.

`Review` is written by the client after job completion and references both the `Job` and the `ProfessionalProfile`. The foreign key to `Job` carries a unique constraint, enforcing one review per job. The foreign key to `ProfessionalProfile` is a deliberate denormalisation — it allows efficient retrieval of all reviews for a given professional without joining through the `Job` table, which would be required on every profile view.

<!-- 
To better understand the context of the software system, it is useful to have a simple UML class diagram with all and only the key concepts (names, attributes) and relationships involved of the problem domain addressed by your app. 
Also provide a short textual description of each concept (domain class). 

Example:
 <p align="center" justify="center">
  <img src="https://github.com/FEUP-LEIC-ES-2022-23/templates/blob/main/images/DomainModel.png"/>
</p>
-->


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

<!--
The purpose of this subsection is to document the high-level logical structure of the code (Logical View), using a UML diagram with logical packages, without the worry of allocating to components, processes or machines.

It can be beneficial to present the system in a horizontal decomposition, defining layers and implementation concepts, such as the user interface, business logic and concepts.

Example of _UML package diagram_ showing a _logical view_ of the Eletronic Ticketing System (to be accompanied by a short description of each package):

![LogicalView](https://user-images.githubusercontent.com/9655877/160585416-b1278ad7-18d7-463c-b8c6-afa4f7ac7639.png)
-->


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

<!--
The goal of this subsection is to document the high-level physical structure of the software system (machines, connections, software components installed, and their dependencies) using UML deployment diagrams (Deployment View) or component diagrams (Implementation View), separate or integrated, showing the physical structure of the system.

It should describe also the technologies considered and justify the selections made. Examples of technologies relevant for ESOF are, for example, frameworks for mobile applications (such as Flutter).

Example of _UML deployment diagram_ showing a _deployment view_ of the Eletronic Ticketing System (please notice that, instead of software components, one should represent their physical/executable manifestations for deployment, called artifacts in UML; the diagram should be accompanied by a short description of each node and artifact):

![DeploymentView](https://user-images.githubusercontent.com/9655877/160592491-20e85af9-0758-4e1e-a704-0db1be3ee65d.png)
-->


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

### Sprint 2

### Sprint 3

### Sprint 4

### Final Release

