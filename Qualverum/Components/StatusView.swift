//
//  StatusView.swift
//  Qualverum
//
//  Created by Andrew Wallace on 02/09/26.
//

import SwiftUI

// Show a symbol and text so colour is never the only cue.

struct AssessmentStatusLabel: View {
    let status: AssessmentStatus
    var body: some View {
        Label(status.rawValue, systemImage: status.symbol)
            .foregroundStyle(color)
    }
    var color: Color {
        switch status {
        case .supported: .green
        case .needsReview: .orange
        case .missing: .red
        case .notAssessed: .secondary
        }
    }
}

struct TenderStatusLabel: View {
    let status: TenderStatus
    var body: some View {
        Label(status.rawValue, systemImage: status.symbol)
            .foregroundStyle(status == .ready ? .green : status == .archived ? .secondary : .primary)
    }
}

struct EvidenceStatusLabel: View {
    let status: EvidenceStatus
    var body: some View {
        Label(status.rawValue, systemImage: status.symbol)
            .foregroundStyle(color)
    }
    var color: Color {
        switch status {
        case .valid: .green
        case .expiringSoon: .orange
        case .expired: .red
        case .needsReview: .orange
        }
    }
}

struct ReadinessGauge: View {
    let value: Double
    var body: some View {
        Gauge(value: value) {
            Text("Readiness")
        } currentValueLabel: {
            Text(value, format: .percent.precision(.fractionLength(0)))
        }
        .gaugeStyle(.accessoryLinearCapacity)
        .tint(value >= 0.75 ? .green : value >= 0.4 ? .orange : .red)
    }
}

extension Date {
    var short: String { formatted(date: .abbreviated, time: .omitted) }
}
