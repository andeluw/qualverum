//
//  MockQualverumData.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import Foundation

enum MockQualverumData {

    static func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d)) ?? .now
    }

    // MARK: Shared company evidence (reused across tenders)

    static let sharedEvidence: [Evidence] = [
        Evidence(name: "ISO 27001 Certificate", type: .certification, scope: .shared,
                 organization: "BSI", date: date(2024, 3, 12), expiry: date(2027, 3, 11),
                 status: .valid,
                 facts: [.init(label: "Standard", value: "ISO/IEC 27001:2022"),
                         .init(label: "Scope", value: "Software development & hosting"),
                         .init(label: "Certificate No.", value: "IS-774213")],
                 sourceFileName: "ISO-27001-Certificate.pdf"),
        Evidence(name: "ISO 9001 Certificate", type: .certification, scope: .shared,
                 organization: "BSI", date: date(2023, 11, 2), expiry: date(2026, 10, 30),
                 status: .expiringSoon,
                 facts: [.init(label: "Standard", value: "ISO 9001:2015"),
                         .init(label: "Certificate No.", value: "FS-118902")],
                 sourceFileName: "ISO-9001-Certificate.pdf"),
        Evidence(name: "Audited Financial Statements 2024", type: .financialStatement, scope: .shared,
                 organization: "Meridian Digital Ltd", date: date(2025, 2, 28), expiry: nil,
                 status: .valid,
                 facts: [.init(label: "Turnover", value: "€24.6M"),
                         .init(label: "Net Assets", value: "€9.1M"),
                         .init(label: "Auditor", value: "Grant Thornton")],
                 sourceFileName: "Financials-2024.pdf"),
        Evidence(name: "School-SIS Case Study", type: .caseStudy, scope: .shared,
                 organization: "Nordvik Region", date: date(2024, 6, 15), expiry: nil,
                 status: .valid,
                 facts: [.init(label: "Sector", value: "Education"),
                         .init(label: "Users", value: "42,000 students"),
                         .init(label: "Delivered", value: "2024")],
                 sourceFileName: "School-SIS-Case-Study.pdf", page: 4),
        Evidence(name: "Municipal ERP Project Reference", type: .projectReference, scope: .shared,
                 organization: "City of Aarby", date: date(2023, 9, 1), expiry: nil,
                 status: .needsReview,
                 facts: [.init(label: "Contract Value", value: "€3.2M"),
                         .init(label: "Duration", value: "18 months"),
                         .init(label: "Similarity", value: "Partial, ERP not SIS")],
                 sourceFileName: "Municipal-ERP.pdf", page: 7),
        Evidence(name: "Information Security Policy", type: .securityPolicy, scope: .shared,
                 organization: "Meridian Digital Ltd", date: date(2025, 1, 10), expiry: nil,
                 status: .valid,
                 facts: [.init(label: "Version", value: "4.2"),
                         .init(label: "Approved By", value: "CISO")],
                 sourceFileName: "InfoSec-Policy.pdf"),
        Evidence(name: "Lead Architect CV, J. Okoro", type: .cv, scope: .shared,
                 organization: "Meridian Digital Ltd", date: date(2025, 4, 1), expiry: nil,
                 status: .valid,
                 facts: [.init(label: "Experience", value: "14 years"),
                         .init(label: "Certifications", value: "TOGAF, AWS SA Pro")],
                 sourceFileName: "CV-Okoro.pdf"),
        Evidence(name: "Professional Indemnity Insurance", type: .insurance, scope: .shared,
                 organization: "Zurich", date: date(2025, 1, 1), expiry: date(2025, 12, 31),
                 status: .expiringSoon,
                 facts: [.init(label: "Cover", value: "€5M per claim"),
                         .init(label: "Policy No.", value: "PI-9932144")],
                 sourceFileName: "PI-Insurance.pdf"),
        Evidence(name: "GDPR Data Processing Addendum", type: .corporate, scope: .shared,
                 organization: "Meridian Digital Ltd", date: date(2024, 5, 20), expiry: nil,
                 status: .valid, sourceFileName: "DPA.pdf"),
        Evidence(name: "Cyber Essentials Plus", type: .certification, scope: .shared,
                 organization: "IASME", date: date(2023, 8, 1), expiry: date(2024, 7, 31),
                 status: .expired,
                 facts: [.init(label: "Assessment", value: "Plus")],
                 sourceFileName: "Cyber-Essentials-Plus.pdf"),
        Evidence(name: "Trade License", type: .license, scope: .shared,
                 organization: "Companies House", date: date(2010, 4, 4), expiry: nil,
                 status: .valid, sourceFileName: "Trade-License.pdf"),
        Evidence(name: "Accessibility Conformance Report", type: .corporate, scope: .shared,
                 organization: "Meridian Digital Ltd", date: date(2024, 10, 5), expiry: nil,
                 status: .valid,
                 facts: [.init(label: "Standard", value: "WCAG 2.1 AA")],
                 sourceFileName: "ACR.pdf"),
    ]

    // MARK: Requirements for the primary tender

    static func primaryRequirements(evidence: [Evidence]) -> [Requirement] {
        func ev(_ names: [String]) -> [UUID] {
            evidence.filter { names.contains($0.name) }.map(\.id)
        }
        var list: [Requirement] = []

        list.append(Requirement(
            code: "R01", text: "Bidder must hold a valid ISO/IEC 27001 certification.",
            category: .security, isMandatory: true,
            constraints: [.init(label: "Standard", detail: "ISO/IEC 27001"),
                          .init(label: "Validity", detail: "Current at submission")],
            assessment: .init(status: .supported,
                              rationale: "Valid ISO 27001 certificate on file, expires 2027.",
                              evidenceIDs: ev(["ISO 27001 Certificate"]),
                              validations: [.init(check: "Certificate present", outcome: "Yes", status: .supported),
                                            .init(check: "Not expired", outcome: "Passed", status: .supported)]),
            sourceDocument: "Tender-Specification.pdf", sourcePage: 12))

        list.append(Requirement(
            code: "R02", text: "Bidder must demonstrate ISO 9001 quality management certification.",
            category: .compliance, isMandatory: true,
            constraints: [.init(label: "Standard", detail: "ISO 9001:2015")],
            assessment: .init(status: .needsReview,
                              rationale: "Certificate expires within the delivery window, confirm renewal.",
                              evidenceIDs: ev(["ISO 9001 Certificate"]),
                              validations: [.init(check: "Certificate present", outcome: "Yes", status: .supported),
                                            .init(check: "Valid through delivery", outcome: "Expires 2026-10", status: .needsReview)]),
            sourceDocument: "Tender-Specification.pdf", sourcePage: 12))

        list.append(Requirement(
            code: "R03", text: "Annual turnover of at least €10M in each of the last two financial years.",
            category: .financial, isMandatory: true,
            constraints: [.init(label: "Threshold", detail: "€10M / year"),
                          .init(label: "Period", detail: "Last 2 years")],
            assessment: .init(status: .supported,
                              rationale: "2024 turnover €24.6M exceeds threshold.",
                              evidenceIDs: ev(["Audited Financial Statements 2024"]),
                              validations: [.init(check: "Turnover ≥ €10M (2024)", outcome: "€24.6M", status: .supported),
                                            .init(check: "Turnover ≥ €10M (2023)", outcome: "Not in evidence", status: .needsReview)]),
            sourceDocument: "Tender-Specification.pdf", sourcePage: 18))

        list.append(Requirement(
            code: "R17", text: "Two comparable reference projects completed in the previous three years.",
            category: .experience, isMandatory: true,
            constraints: [.init(label: "Count", detail: "2 projects"),
                          .init(label: "Recency", detail: "Within 3 years"),
                          .init(label: "Similarity", detail: "Comparable scope (SIS)")],
            assessment: .init(status: .needsReview,
                              rationale: "One clearly comparable project; the second is recent but similarity is unproven.",
                              evidenceIDs: ev(["School-SIS Case Study", "Municipal ERP Project Reference"]),
                              validations: [.init(check: "Eligible projects", outcome: "1 / 2", status: .needsReview),
                                            .init(check: "Date window", outcome: "Passed", status: .supported),
                                            .init(check: "Similarity", outcome: "Needs Review", status: .needsReview)]),
            sourceDocument: "Tender-Specification.pdf", sourcePage: 24))

        list.append(Requirement(
            code: "R21", text: "Provide a named lead solution architect with 10+ years experience.",
            category: .experience, isMandatory: false,
            constraints: [.init(label: "Experience", detail: "≥ 10 years")],
            assessment: .init(status: .supported,
                              rationale: "Lead architect CV shows 14 years experience.",
                              evidenceIDs: ev(["Lead Architect CV, J. Okoro"]),
                              validations: [.init(check: "Experience ≥ 10y", outcome: "14y", status: .supported)]),
            sourceDocument: "Tender-Specification.pdf", sourcePage: 29))

        list.append(Requirement(
            code: "R24", text: "Maintain professional indemnity insurance of at least €5M.",
            category: .legal, isMandatory: true,
            constraints: [.init(label: "Cover", detail: "≥ €5M")],
            assessment: .init(status: .needsReview,
                              rationale: "Cover meets threshold but policy expires 2025-12-31.",
                              evidenceIDs: ev(["Professional Indemnity Insurance"]),
                              validations: [.init(check: "Cover ≥ €5M", outcome: "€5M", status: .supported),
                                            .init(check: "Valid at delivery", outcome: "Expires 2025-12", status: .needsReview)]),
            sourceDocument: "Tender-Specification.pdf", sourcePage: 31))

        list.append(Requirement(
            code: "R30", text: "Hold a current Cyber Essentials Plus certification.",
            category: .security, isMandatory: false,
            constraints: [.init(label: "Assessment", detail: "Plus")],
            assessment: .init(status: .missing,
                              rationale: "Certification on file has expired.",
                              evidenceIDs: ev(["Cyber Essentials Plus"]),
                              validations: [.init(check: "Certificate present", outcome: "Yes", status: .supported),
                                            .init(check: "Not expired", outcome: "Expired 2024-07", status: .missing)]),
            sourceDocument: "Tender-Specification.pdf", sourcePage: 33))

        list.append(Requirement(
            code: "R33", text: "Solution must conform to WCAG 2.1 AA accessibility standards.",
            category: .technical, isMandatory: true,
            constraints: [.init(label: "Standard", detail: "WCAG 2.1 AA")],
            assessment: .init(status: .supported,
                              rationale: "Accessibility Conformance Report attests WCAG 2.1 AA.",
                              evidenceIDs: ev(["Accessibility Conformance Report"]),
                              validations: [.init(check: "Conformance statement", outcome: "WCAG 2.1 AA", status: .supported)]),
            sourceDocument: "Tender-Specification.pdf", sourcePage: 41))

        list.append(Requirement(
            code: "R38", text: "Data must be hosted within the European Economic Area.",
            category: .compliance, isMandatory: true,
            assessment: .init(status: .missing,
                              rationale: "No evidence of EEA hosting arrangement provided.",
                              evidenceIDs: [],
                              validations: [.init(check: "Hosting location evidence", outcome: "None", status: .missing)]),
            sourceDocument: "Tender-Specification.pdf", sourcePage: 44))

        list.append(Requirement(
            code: "R42", text: "GDPR-compliant data processing agreement available.",
            category: .legal, isMandatory: true,
            assessment: .init(status: .supported,
                              rationale: "Signed DPA on file.",
                              evidenceIDs: ev(["GDPR Data Processing Addendum"]),
                              validations: [.init(check: "DPA present", outcome: "Yes", status: .supported)]),
            sourceDocument: "Tender-Specification.pdf", sourcePage: 46))

        let extras: [(String, String, RequirementCategory, Bool, AssessmentStatus)] = [
            ("R05", "Registered legal entity with valid trade license.", .eligibility, true, .supported),
            ("R08", "No conflicts of interest declared.", .eligibility, true, .supported),
            ("R11", "Provide a project delivery plan with milestones.", .delivery, true, .supported),
            ("R13", "Named data protection officer.", .legal, false, .supported),
            ("R15", "Support SLA with 99.9% uptime.", .delivery, true, .needsReview),
            ("R19", "Localization into at least three languages.", .technical, false, .supported),
            ("R23", "Single sign-on via SAML 2.0.", .technical, true, .supported),
            ("R26", "Disaster recovery RPO ≤ 4 hours.", .technical, true, .needsReview),
            ("R28", "Penetration test within the last 12 months.", .security, true, .missing),
            ("R35", "Training plan for administrative staff.", .delivery, false, .supported),
            ("R37", "Open data export in standard formats.", .technical, false, .supported),
            ("R40", "Environmental sustainability statement.", .compliance, false, .supported),
            ("R44", "Reference contactable for verification.", .experience, true, .needsReview),
            ("R47", "Escrow arrangement for source code.", .legal, false, .missing),
        ]
        for (code, text, cat, mand, status) in extras {
            list.append(Requirement(
                code: code, text: text, category: cat, isMandatory: mand,
                assessment: .init(status: status,
                                  rationale: status == .missing ? "No supporting evidence located yet." :
                                             status == .needsReview ? "Partial evidence, manual review recommended." :
                                             "Sufficient evidence located.",
                                  evidenceIDs: status == .supported ? ev(["Information Security Policy"]) : [],
                                  validations: []),
                sourceDocument: "Tender-Specification.pdf", sourcePage: Int.random(in: 10...60)))
        }
        return list
    }

    // MARK: Tenders

    static func makeTenders() -> [Tender] {
        let primaryReqs = primaryRequirements(evidence: sharedEvidence)
        let primary = Tender(
            name: "European School SIS 2026",
            buyer: "European Schools Office",
            reference: "ES-SIS-2026-014",
            deadline: date(2026, 11, 30),
            status: .inReview,
            notes: "Student Information System for the European Schools network.",
            created: date(2026, 7, 1), modified: date(2026, 8, 28),
            versions: [
                .init(label: "1.2", date: date(2026, 8, 20), change: "Addendum 2, clarified R17", documentCount: 4),
                .init(label: "1.1", date: date(2026, 7, 30), change: "Addendum 1, added security annex", documentCount: 3),
                .init(label: "1.0", date: date(2026, 7, 1), change: "Initial publication", documentCount: 2),
            ],
            documents: [
                .init(name: "Tender-Specification.pdf", type: "Specification", pages: 64,
                      version: "1.2", imported: date(2026, 8, 20), state: .indexed, sampleResource: nil),
                .init(name: "Security-Annex.pdf", type: "Annex", pages: 18,
                      version: "1.1", imported: date(2026, 7, 30), state: .indexed, sampleResource: nil),
                .init(name: "Pricing-Schedule.pdf", type: "Schedule", pages: 6,
                      version: "1.0", imported: date(2026, 7, 1), state: .parsed, sampleResource: nil),
                .init(name: "Addendum-2.pdf", type: "Addendum", pages: 3,
                      version: "1.2", imported: date(2026, 8, 20), state: .imported, sampleResource: nil),
            ],
            requirements: primaryReqs)

        let portal = Tender(
            name: "National Education Portal",
            buyer: "Ministry of Education",
            reference: "MOE-EP-2026-3",
            deadline: date(2026, 10, 15),
            status: .notAnalyzed,
            created: date(2026, 6, 10), modified: date(2026, 6, 10),
            versions: [.init(label: "1.0", date: date(2026, 6, 10), change: "Initial publication", documentCount: 2)],
            documents: [
                .init(name: "Portal-RFP.pdf", type: "Specification", pages: 48,
                      version: "1.0", imported: date(2026, 6, 10), state: .parsed, sampleResource: nil),
                .init(name: "Portal-Annex-A.pdf", type: "Annex", pages: 22,
                      version: "1.0", imported: date(2026, 6, 10), state: .imported, sampleResource: nil),
            ],
            requirements: [])

        let erp = Tender(
            name: "Municipal ERP Procurement",
            buyer: "City of Aarby",
            reference: "AARBY-ERP-25",
            deadline: date(2026, 9, 20),
            status: .ready,
            created: date(2026, 3, 2), modified: date(2026, 7, 15),
            versions: [.init(label: "2.0", date: date(2026, 7, 15), change: "Final tender", documentCount: 1)],
            documents: [
                .init(name: "ERP-Tender.pdf", type: "Specification", pages: 88,
                      version: "2.0", imported: date(2026, 7, 15), state: .indexed, sampleResource: nil),
            ],
            requirements: Array(primaryReqs.prefix(6)))

        let archived = Tender(
            name: "Regional Health Records 2025",
            buyer: "Regional Health Authority",
            reference: "RHA-EHR-2025",
            deadline: date(2025, 12, 1),
            status: .submitted,
            created: date(2025, 8, 1), modified: date(2025, 11, 20),
            versions: [.init(label: "1.0", date: date(2025, 8, 1), change: "Initial publication", documentCount: 1)],
            documents: [],
            requirements: [])

        return [primary, portal, erp, archived]
    }

    // MARK: Analysis runs

    static func makeRuns(tenders: [Tender]) -> [AnalysisRun] {
        guard let primary = tenders.first else { return [] }
        return [
            .init(date: date(2026, 8, 28), tenderID: primary.id, tenderName: primary.name,
                  tenderVersion: "1.2", evidenceVersion: "2026-08-28", configuration: .init(),
                  supported: primary.supportedCount, review: primary.needsReviewCount,
                  missing: primary.missingCount, duration: 214, status: .completed),
            .init(date: date(2026, 8, 12), tenderID: primary.id, tenderName: primary.name,
                  tenderVersion: "1.1", evidenceVersion: "2026-08-10", configuration: .init(),
                  supported: 11, review: 8, missing: 5, duration: 198, status: .completed),
            .init(date: date(2026, 7, 30), tenderID: primary.id, tenderName: primary.name,
                  tenderVersion: "1.1", evidenceVersion: "2026-07-29", configuration: .init(),
                  supported: 9, review: 9, missing: 6, duration: 205, status: .completed),
            .init(date: date(2026, 7, 22), tenderID: primary.id, tenderName: primary.name,
                  tenderVersion: "1.0", evidenceVersion: "2026-07-20", configuration: .init(),
                  supported: 0, review: 0, missing: 0, duration: 44, status: .cancelled),
            .init(date: date(2026, 7, 18), tenderID: primary.id, tenderName: primary.name,
                  tenderVersion: "1.0", evidenceVersion: "2026-07-18", configuration: .init(),
                  supported: 0, review: 0, missing: 0, duration: 12, status: .failed),
        ]
    }

    // MARK: Chat threads

    static func makeThreads(tenders: [Tender], evidence: [Evidence]) -> [ChatThread] {
        let primary = tenders.first
        let sisCase = evidence.first { $0.name == "School-SIS Case Study" }
        let erpRef = evidence.first { $0.name == "Municipal ERP Project Reference" }
        return [
            ChatThread(title: "Submission readiness", scope: .currentTender, tenderID: primary?.id,
                       messages: [
                        .init(role: .user, text: "Why are we not ready to submit?"),
                        .init(role: .assistant,
                              text: "Three mandatory requirements are not yet Supported. R38 (EEA hosting) has no evidence, R30 (Cyber Essentials Plus) is expired, and R17 (reference projects) needs review. [1][2]",
                              citations: [.init(index: 1, label: "Tender-Specification.pdf · p.44", evidenceID: nil, page: 44),
                                          .init(index: 2, label: "School-SIS-Case-Study.pdf · p.4", evidenceID: sisCase?.id, page: 4)]),
                       ]),
            ChatThread(title: "R17 project requirement", scope: .selectedRequirement, tenderID: primary?.id,
                       messages: [
                        .init(role: .user, text: "Why is R17 Needs Review?"),
                        .init(role: .assistant,
                              text: "The tender requires two comparable projects completed within the previous three years.\n\nProject Alpha qualifies. [1]\n\nProject Beta is recent enough, but the current evidence does not establish sufficient similarity. [2]\n\nResult: Needs Review.",
                              citations: [.init(index: 1, label: "School-SIS-Case-Study.pdf · p.4", evidenceID: sisCase?.id, page: 4),
                                          .init(index: 2, label: "Municipal-ERP.pdf · p.7", evidenceID: erpRef?.id, page: 7)]),
                       ]),
            ChatThread(title: "Security certifications", scope: .companyLibrary, tenderID: nil,
                       messages: [
                        .init(role: .user, text: "Which security certifications do we hold?"),
                        .init(role: .assistant,
                              text: "ISO 27001 is valid through 2027. [1] Cyber Essentials Plus has expired and needs renewal. [2]",
                              citations: [.init(index: 1, label: "ISO-27001-Certificate.pdf · p.1", evidenceID: nil, page: 1),
                                          .init(index: 2, label: "Cyber-Essentials-Plus.pdf · p.1", evidenceID: nil, page: 1)]),
                       ]),
            ChatThread(title: "Financial qualification", scope: .currentTender, tenderID: primary?.id,
                       messages: [
                        .init(role: .user, text: "What supports our financial qualification?"),
                        .init(role: .assistant,
                              text: "The 2024 audited statements show €24.6M turnover, above the €10M threshold. Prior-year turnover is not yet in evidence. [1]",
                              citations: [.init(index: 1, label: "Financials-2024.pdf · p.2", evidenceID: nil, page: 2)]),
                       ]),
            ChatThread(title: "Missing evidence", scope: .allTenders, tenderID: nil,
                       messages: [
                        .init(role: .user, text: "Which evidence expires before submission?"),
                        .init(role: .assistant,
                              text: "Professional Indemnity Insurance expires 2025-12-31 and ISO 9001 expires 2026-10-30, both before or near the submission window. [1][2]",
                              citations: [.init(index: 1, label: "PI-Insurance.pdf · p.1", evidenceID: nil, page: 1),
                                          .init(index: 2, label: "ISO-9001-Certificate.pdf · p.1", evidenceID: nil, page: 1)]),
                       ]),
        ]
    }

    // MARK: Developer debug data

    static let retrievalDebug = RetrievalDebugResult(
        query: "two comparable reference projects completed in the previous three years",
        dense: [
            .init(chunkID: "c-1042", document: "School-SIS-Case-Study.pdf", page: 4, score: 0.812, snippet: "Delivered a student information system for 42,000 students in 2024…"),
            .init(chunkID: "c-2210", document: "Municipal-ERP.pdf", page: 7, score: 0.744, snippet: "18-month ERP rollout for the City of Aarby completed in 2023…"),
            .init(chunkID: "c-0991", document: "Financials-2024.pdf", page: 2, score: 0.401, snippet: "Turnover for the year ended 2024 was €24.6M…"),
        ],
        bm25: [
            .init(chunkID: "c-2210", document: "Municipal-ERP.pdf", page: 7, score: 9.82, snippet: "…comparable project reference, completed 2023…"),
            .init(chunkID: "c-1042", document: "School-SIS-Case-Study.pdf", page: 4, score: 8.14, snippet: "…reference project delivered 2024…"),
        ],
        rrf: [
            .init(chunkID: "c-1042", document: "School-SIS-Case-Study.pdf", page: 4, score: 0.032, snippet: "Delivered a student information system…"),
            .init(chunkID: "c-2210", document: "Municipal-ERP.pdf", page: 7, score: 0.031, snippet: "18-month ERP rollout…"),
        ],
        reranked: [
            .init(chunkID: "c-1042", document: "School-SIS-Case-Study.pdf", page: 4, score: 0.94, snippet: "Delivered a student information system…"),
            .init(chunkID: "c-2210", document: "Municipal-ERP.pdf", page: 7, score: 0.61, snippet: "18-month ERP rollout…"),
        ],
        finalContext: [
            .init(chunkID: "c-1042", document: "School-SIS-Case-Study.pdf", page: 4, score: 0.94, snippet: "Delivered a student information system for 42,000 students in 2024, including migration and training."),
            .init(chunkID: "c-2210", document: "Municipal-ERP.pdf", page: 7, score: 0.61, snippet: "18-month ERP rollout for the City of Aarby, completed 2023; scope differs from a student information system."),
        ])

    static let chunks: [ChunkDebugInfo] = [
        .init(chunkID: "c-1042", parentID: "p-118", document: "School-SIS-Case-Study.pdf",
              page: 4, section: "3. Delivered Outcomes", chunkType: "child", tokenCount: 176,
              originalText: "Meridian delivered a student information system for 42,000 students in 2024, including data migration and staff training across 60 schools.",
              normalizedText: "meridian delivered a student information system for 42000 students in 2024 including data migration and staff training across 60 schools",
              embeddingInput: "passage: Meridian delivered a student information system for 42,000 students in 2024…",
              parentContext: "3. Delivered Outcomes, The Nordvik Region engagement covered a full SIS rollout…",
              metadata: ["source": "case-study", "year": "2024", "sector": "education"]),
        .init(chunkID: "c-2210", parentID: "p-204", document: "Municipal-ERP.pdf",
              page: 7, section: "2. Project Scope", chunkType: "child", tokenCount: 158,
              originalText: "The City of Aarby ERP engagement ran for 18 months and completed in 2023 with a contract value of €3.2M.",
              normalizedText: "the city of aarby erp engagement ran for 18 months and completed in 2023 with a contract value of 3.2m",
              embeddingInput: "passage: The City of Aarby ERP engagement ran for 18 months…",
              parentContext: "2. Project Scope, enterprise resource planning implementation, finance and HR modules…",
              metadata: ["source": "reference", "year": "2023", "sector": "government"]),
    ]

    static let experiments: [ExperimentResult] = [
        .init(name: "V0 Paragraph Baseline", recallAt5: 0.52, recallAt10: 0.64, mrr: 0.41, ndcgAt10: 0.48, p50: 180, p95: 420, memoryMB: 210),
        .init(name: "V1 Structure-Aware", recallAt5: 0.61, recallAt10: 0.72, mrr: 0.49, ndcgAt10: 0.55, p50: 190, p95: 440, memoryMB: 240),
        .init(name: "V2 Parent/Child", recallAt5: 0.68, recallAt10: 0.79, mrr: 0.55, ndcgAt10: 0.62, p50: 205, p95: 470, memoryMB: 260),
        .init(name: "V3 Hybrid RRF", recallAt5: 0.74, recallAt10: 0.85, mrr: 0.60, ndcgAt10: 0.68, p50: 260, p95: 540, memoryMB: 300),
        .init(name: "V4 Hybrid + Reranker", recallAt5: 0.81, recallAt10: 0.89, mrr: 0.67, ndcgAt10: 0.74, p50: 410, p95: 820, memoryMB: 520),
    ]
}
