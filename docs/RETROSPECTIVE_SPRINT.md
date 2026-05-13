# Sprint Retrospective - Sprint 1

## What Went Well
- Delivered core Must-have features: Job Discovery, 
Job History & Tracking, Service Request Submission
- Unit and integration tests completed
- User acceptance tests (UAT) completed
- Sprint Review document completed

## What Could Be Improved
- **Time Management:** Struggled with poor time management 
at the beginning of the sprint, leading to an uneven 
distribution of work.
- **Workload Spiking:** The slow start forced the team to 
rush development in the final days, which is not sustainable 
for long-term quality.
- **Initial Estimation:** Underestimated the time required 
for setup and initial architecture, causing a bottleneck 
mid-sprint. As a result, 2 PBIs were not completed:
  - [US09] Automatic Payment Processing
  - [US17] Job Cancellation (Pro)

## Strategy and Verifiable Action Points

### Early Start Policy & Milestone Tracking
Must-have PBIs must start within the first 48 hours of 
the sprint. Verified by auditing commit history timestamps 
during the first week of Sprint 2.

### Mid-Sprint Internal Review
A formal internal progress sync halfway through the sprint 
to assess velocity. Output: a "Status Update" note in 
GitHub Discussions documenting if pace is sufficient.

### Granular PBI Breakdown
Any User Story exceeding 5 story points must be broken 
into sub-tasks completable in 1–3 days. No task in 
"In Progress" should remain stagnant for more than 72 hours.

# Sprint Review - Sprint 2

## Sprint Overview
Sprint 2 took place during May 2026. A defining characteristic of this sprint was the need to carry over and complete a significant number of unfinished items from Sprint 1, in addition to tackling new user stories planned for this iteration. Despite this added pressure, the team successfully delivered 18 story points across 5 user stories.

## Completed User Stories (18 points)
- [US10] Client Profile Management
- [US17] Job Cancellation (Pro) — carried over from Sprint 1
- [US15] Job Status Controller — carried over from Sprint 1
- [US20] Pro Profile & Rates
- [US05] Job History & Tracking — carried over from Sprint 1

## Tasks Completed
- Unit and integration tests
- User acceptance tests (UAT)
- Log, track and verify defects
- Sprint 2 review document
- Happiness Matters document

## Items Not Completed (moved to Sprint 3)
- [US09] Automatic Payment Processing — carried over again from Sprint 1
- [US03] Service Request Submission — carried over from Sprint 1
- [US08] Rate & Review System

## What Went Well
- Successfully closed out the majority of Sprint 1 carry-over items, preventing further technical debt accumulation
- Team applied the Early Start Policy defined in the Sprint 1 retrospective, ensuring critical PBIs began early in the sprint
- The Mid-Sprint Internal Review was conducted, allowing the team to detect pace issues before the final sprint stretch
- Delivered [US20] Pro Profile & Rates as a new planned user story, demonstrating capacity beyond backlog clearance
- All quality assurance tasks (unit tests, integration tests, UAT, defect tracking) completed as planned

## What Could Be Improved
- **Backlog Debt Accumulation:** This sprint was heavily burdened by carry-overs from Sprint 1 (US17, US15, US05, US09, US03), reducing the team's ability to focus on new feature development
- **Persistent Carry-Overs:** [US09] and [US03] were not completed for the second consecutive sprint, indicating consistent underestimation of their complexity
- **Planning Accuracy:** The volume of carry-over work was not fully accounted for when committing to Sprint 2 scope, resulting in [US08] being pushed to the next sprint

## Strategy and Verifiable Action Points
### Carry-Over Prioritisation Policy
Any user story carried over more than once must be treated as the highest priority item at the start of the next sprint, with dedicated ownership assigned before any new stories begin.
### Capacity-Aware Sprint Planning
Before committing to Sprint 3 scope, the team will explicitly account for existing carry-over stories in the velocity calculation. New stories only added if remaining capacity allows.
### Root Cause Analysis for Persistent Blockers
For stories carried over more than once ([US09], [US03]), a brief root cause session will be held at the start of Sprint 3 to identify blockers and define a concrete resolution plan.
