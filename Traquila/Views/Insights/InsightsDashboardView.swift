import Charts
import SwiftData
import SwiftUI

struct InsightsDashboardView: View {
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: [SortDescriptor(\Bottle.name)]) private var bottles: [Bottle]
    @Query(sort: [SortDescriptor(\PourEntry.date)]) private var pours: [PourEntry]

    @StateObject private var pacingTimer = PacingTimerService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    summaryGrid
                    trendCard
                    pacingCard
                }
                .padding()
            }
            .navigationTitle("Insights")
            .background(TraquilaTheme.parchment.opacity(0.35))
        }
    }

    private var summary: InsightsSummary {
        InsightsService.summary(bottles: bottles, pours: pours)
    }

    private var summaryGrid: some View {
        let costLabel = summary.estimatedCostPerPour.map {
            TraquilaFormatters.currency.string(from: NSNumber(value: $0)) ?? "$0.00"
        } ?? "-"

        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                metricCard(title: "This Week", value: "\(summary.totalWeek) pours", icon: "calendar")
                metricCard(title: "This Month", value: "\(summary.totalMonth) pours", icon: "calendar.badge.clock")
            }
            HStack(spacing: 10) {
                metricCard(
                    title: "Avg Enjoyment",
                    value: summary.averageEnjoyment.formatted(.number.precision(.fractionLength(1))),
                    icon: "star"
                )
                metricCard(
                    title: "Most Logged",
                    value: summary.mostLoggedBottleName ?? "-",
                    icon: "medal"
                )
            }
            HStack(spacing: 10) {
                metricCard(
                    title: "Total Spend",
                    value: TraquilaFormatters.currency.string(from: NSNumber(value: summary.totalSpend)) ?? "$0.00",
                    icon: "dollarsign.circle"
                )
                metricCard(title: "Est Cost / oz", value: costLabel, icon: "chart.bar")
            }
        }
    }

    private var trendCard: some View {
        let points = InsightsService.enjoymentTrend(pours: pours)

        return TraquilaCard(accent: TraquilaTheme.agaveGreen) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Enjoyment Trend")
                    .font(.headline)
                if points.isEmpty {
                    Text("Add enjoyment scores in your pour log to see trend lines.")
                        .foregroundStyle(.secondary)
                } else {
                    Chart(points) { point in
                        LineMark(
                            x: .value("Day", point.day),
                            y: .value("Avg Enjoyment", point.value)
                        )
                        .foregroundStyle(TraquilaTheme.terracotta)
                        PointMark(
                            x: .value("Day", point.day),
                            y: .value("Avg Enjoyment", point.value)
                        )
                        .foregroundStyle(TraquilaTheme.marigold)
                    }
                    .frame(height: 200)
                    .accessibilityLabel("Average enjoyment over time")
                }
            }
        }
    }

    private var pacingCard: some View {
        TraquilaCard(accent: TraquilaTheme.marigold) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Pacing")
                    .font(.headline)
                Text("Use pacing and hydration reminders to keep your sessions intentional.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if settings.enablePacing {
                    Stepper("Interval: \(settings.pacingMinutes) min", value: $settings.pacingMinutes, in: 10...180, step: 5)
                    Text(timerLabel)
                        .font(.title2.monospacedDigit())
                    HStack {
                        Button(pacingTimer.isRunning ? "Restart" : "Start Timer") {
                            pacingTimer.start(minutes: settings.pacingMinutes)
                        }
                        .buttonStyle(.borderedProminent)

                        if pacingTimer.isRunning {
                            Button("Stop") {
                                pacingTimer.stop()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                } else {
                    Text("Enable pacing timer in Settings.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var timerLabel: String {
        let mins = pacingTimer.remainingSeconds / 60
        let secs = pacingTimer.remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private func metricCard(title: String, value: String, icon: String) -> some View {
        TraquilaCard {
            VStack(alignment: .leading, spacing: 6) {
                Label(title, systemImage: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
