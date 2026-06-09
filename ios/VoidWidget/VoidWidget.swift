import WidgetKit
import SwiftUI

private let appGroupId = "group.dev.lioluna.voidofcourse"

struct VoidWidgetEntry: TimelineEntry {
    let date: Date
    let icon: String
    let title: String
    let times: String
    let moonZodiac: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> VoidWidgetEntry {
        VoidWidgetEntry(date: Date(), icon: "✅", title: "Void of Course", times: "Start : N/A\nEnd : N/A", moonZodiac: "♊︎")
    }

    func getSnapshot(in context: Context, completion: @escaping (VoidWidgetEntry) -> ()) {
        let entry = getEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VoidWidgetEntry>) -> ()) {
        let entry = getEntry()
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
    
    private func getEntry() -> VoidWidgetEntry {
        let userDefaults = UserDefaults(suiteName: appGroupId)
        let icon = userDefaults?.string(forKey: "widget_icon") ?? "✅"
        
        // Title from Dart contains emojis and the zodiac sign (e.g. "🌙 Void of course  ♊︎")
        // We clean it to display custom stylized elements.
        let rawTitle = userDefaults?.string(forKey: "widget_title_text") ?? "Void of course"
        var cleanTitle = rawTitle.replacingOccurrences(of: "🌙 ", with: "")
        let moonZodiac = userDefaults?.string(forKey: "moon_zodiac") ?? ""
        if !moonZodiac.isEmpty {
            cleanTitle = cleanTitle.replacingOccurrences(of: "  \(moonZodiac)", with: "")
        }
        
        let times = userDefaults?.string(forKey: "widget_times_text") ?? "Start : N/A\nEnd : N/A"
        return VoidWidgetEntry(date: Date(), icon: icon, title: cleanTitle, times: times, moonZodiac: moonZodiac)
    }
}

struct VoidWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            if family == .systemSmall {
                // 1단계 (Small Widget): 투박하지 않고 감성적인 콤팩트 레이아웃
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(spacing: 4) {
                            // 상태 아이콘
                            Text(entry.icon)
                                .font(.system(size: 18))
                                .padding(4)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                            
                            // 별자리 사인 (Zodiac Sign) - 크고 굵게(Bold) 표시하여 감성 극대화
                            if !entry.moonZodiac.isEmpty {
                                Text(entry.moonZodiac)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .frame(width: 26, alignment: .center)
                            }
                        }
                        
                        Text("Void of Course")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    Divider()
                        .padding(.vertical, 1)
                    
                    let lines = entry.times.components(separatedBy: "\n")
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(lines, id: \.self) { line in
                            formatTimeLineSmall(line)
                        }
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                // 2단계 (Medium Widget): 좌우 분할식으로 시인성과 디자인 감성을 극대화한 레이아웃
                HStack(spacing: 16) {
                    // 왼쪽 영역: 아이콘 + 별자리 사인(Bold) 배치
                    VStack(spacing: 8) {
                        Text(entry.icon)
                            .font(.system(size: 34))
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                        
                        if !entry.moonZodiac.isEmpty {
                            Text(entry.moonZodiac)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(width: 55)
                    
                    Divider()
                    
                    // 오른쪽 영역: 타이틀 + 세련된 시간 정보 (라벨은 작게, 시간 값은 굵고 크게)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Void of Course")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Spacer()
                            .frame(height: 2)
                        
                        let lines = entry.times.components(separatedBy: "\n")
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(lines, id: \.self) { line in
                                formatTimeLineMedium(line)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
    }
    
    // 1단계(Small) 시간 텍스트 포맷터: "S: 시간", "E: 시간" 형태로 깔끔하게 압축하여 볼드 처리
    private func formatTimeLineSmall(_ line: String) -> some View {
        let parts = line.components(separatedBy: " : ")
        return Group {
            if parts.count == 2 {
                let label = parts[0].trimmingCharacters(in: .whitespaces)
                let shortLabel = label.hasPrefix("Start") ? "S:" : "E:"
                HStack(spacing: 4) {
                    Text(shortLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(parts[1])
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                }
            } else {
                HStack {
                    Text(line)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    // 2단계(Medium) 시간 텍스트 포맷터: "Start : " 라벨은 얇고 회색으로, 실제 시간 값은 크고 두꺼운 검정색으로 매칭
    private func formatTimeLineMedium(_ line: String) -> some View {
        let parts = line.components(separatedBy: " : ")
        return Group {
            if parts.count == 2 {
                HStack(spacing: 8) {
                    Text(parts[0] + " :")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(parts[1])
                        .font(.system(size: 18, weight: .bold, design: .monospaced)) // 시간 값 시인성 강화 (18pt Bold)
                        .foregroundColor(.primary)
                }
            } else {
                HStack {
                    Text(line)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

struct VoidWidget: Widget {
    let kind: String = "VoidWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VoidWidgetEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Void of Course")
        .description("Check Void of Course schedules on your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
