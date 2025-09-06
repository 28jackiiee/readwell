import Foundation
import UIKit
import PDFKit
import CoreData

class PDFExportService {
    static let shared = PDFExportService()
    
    private init() {}
    
    func generateWeeklyReport(
        sessions: [CheckInSession],
        weekStartDate: Date,
        completionPercentage: Double,
        topThemes: [String]
    ) -> Data? {
        
        let pdfMetaData = [
            kCGPDFContextCreator: AppConstants.appName,
            kCGPDFContextAuthor: "MindTalk User",
            kCGPDFContextTitle: "Weekly MindTalk Report"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = AppConstants.PDF.pageMargin
            
            // Title
            yPosition = drawTitle(in: pageRect, at: yPosition)
            yPosition += 30
            
            // Week period
            yPosition = drawWeekPeriod(weekStartDate: weekStartDate, in: pageRect, at: yPosition)
            yPosition += 30
            
            // Summary stats
            yPosition = drawSummaryStats(
                completionPercentage: completionPercentage,
                sessionCount: sessions.count,
                in: pageRect,
                at: yPosition
            )
            yPosition += 30
            
            // Top themes
            yPosition = drawTopThemes(themes: topThemes, in: pageRect, at: yPosition)
            yPosition += 30
            
            // Daily breakdown
            yPosition = drawDailyBreakdown(sessions: sessions, weekStartDate: weekStartDate, in: pageRect, at: yPosition)
            
            // Footer
            drawFooter(in: pageRect)
        }
        
        return data
    }
    
    func generateSessionReport(session: CheckInSession) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: AppConstants.appName,
            kCGPDFContextAuthor: "MindTalk User",
            kCGPDFContextTitle: "MindTalk Session Report"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = AppConstants.PDF.pageMargin
            
            // Title
            yPosition = drawTitle(in: pageRect, at: yPosition)
            yPosition += 20
            
            // Session date
            yPosition = drawSessionDate(session: session, in: pageRect, at: yPosition)
            yPosition += 30
            
            // Core theme
            if let theme = session.coreTheme, !theme.isEmpty {
                yPosition = drawSection(title: "Core Theme", content: theme, in: pageRect, at: yPosition)
                yPosition += 20
            }
            
            // Summary
            if let summary = session.summary, !summary.isEmpty {
                yPosition = drawSection(title: "Key Points", content: summary, in: pageRect, at: yPosition)
                yPosition += 20
            }
            
            // Emotions
            if let emotions = session.emotions?.allObjects as? [Emotion], !emotions.isEmpty {
                yPosition = drawEmotions(emotions: emotions, in: pageRect, at: yPosition)
                yPosition += 20
            }
            
            // Actions
            if let actions = session.actions?.allObjects as? [Action], !actions.isEmpty {
                yPosition = drawActions(actions: actions, in: pageRect, at: yPosition)
            }
            
            // Footer
            drawFooter(in: pageRect)
        }
        
        return data
    }
    
    // MARK: - Drawing Helper Methods
    
    private func drawTitle(in rect: CGRect, at yPosition: CGFloat) -> CGFloat {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        
        let title = AppConstants.appName
        let titleSize = title.size(withAttributes: titleAttributes)
        let titleRect = CGRect(
            x: (rect.width - titleSize.width) / 2,
            y: yPosition,
            width: titleSize.width,
            height: titleSize.height
        )
        
        title.draw(in: titleRect, withAttributes: titleAttributes)
        return yPosition + titleSize.height
    }
    
    private func drawWeekPeriod(weekStartDate: Date, in rect: CGRect, at yPosition: CGFloat) -> CGFloat {
        let calendar = Calendar.current
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStartDate) ?? weekStartDate
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        let weekText = "Week of \(formatter.string(from: weekStartDate)) - \(formatter.string(from: weekEnd))"
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.gray
        ]
        
        let textSize = weekText.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (rect.width - textSize.width) / 2,
            y: yPosition,
            width: textSize.width,
            height: textSize.height
        )
        
        weekText.draw(in: textRect, withAttributes: attributes)
        return yPosition + textSize.height
    }
    
    private func drawSessionDate(session: CheckInSession, in rect: CGRect, at yPosition: CGFloat) -> CGFloat {
        guard let date = session.date else { return yPosition }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        
        let dateText = formatter.string(from: date)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.gray
        ]
        
        let textSize = dateText.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (rect.width - textSize.width) / 2,
            y: yPosition,
            width: textSize.width,
            height: textSize.height
        )
        
        dateText.draw(in: textRect, withAttributes: attributes)
        return yPosition + textSize.height
    }
    
    private func drawSummaryStats(
        completionPercentage: Double,
        sessionCount: Int,
        in rect: CGRect,
        at yPosition: CGFloat
    ) -> CGFloat {
        let statsText = """
        Sessions Completed: \(sessionCount)
        Action Completion Rate: \(Int(completionPercentage))%
        """
        
        return drawSection(title: "Week Summary", content: statsText, in: rect, at: yPosition)
    }
    
    private func drawTopThemes(themes: [String], in rect: CGRect, at yPosition: CGFloat) -> CGFloat {
        let themesText = themes.isEmpty ? "No themes identified" : themes.joined(separator: "\n• ")
        return drawSection(title: "Top Themes", content: "• " + themesText, in: rect, at: yPosition)
    }
    
    private func drawDailyBreakdown(sessions: [CheckInSession], weekStartDate: Date, in rect: CGRect, at yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition
        
        // Draw section header
        currentY = drawSectionHeader(title: "Daily Breakdown", in: rect, at: currentY)
        currentY += 10
        
        let calendar = Calendar.current
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: weekStartDate) ?? weekStartDate
            let daySession = sessions.first { calendar.isDate($0.date!, inSameDayAs: date) }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            let dayText = formatter.string(from: date)
            
            var statusText = "No check-in"
            if let session = daySession {
                let actionCount = (session.actions?.allObjects as? [Action])?.filter { $0.isCompleted }.count ?? 0
                let totalActions = (session.actions?.allObjects as? [Action])?.count ?? 0
                statusText = "✓ Check-in completed, \(actionCount)/\(totalActions) actions done"
            }
            
            currentY = drawDayEntry(day: dayText, status: statusText, in: rect, at: currentY)
            currentY += 5
        }
        
        return currentY
    }
    
    private func drawEmotions(emotions: [Emotion], in rect: CGRect, at yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition
        
        currentY = drawSectionHeader(title: "Emotions", in: rect, at: currentY)
        currentY += 10
        
        for emotion in emotions.sorted(by: { $0.intensity > $1.intensity }) {
            let emotionText = "\(emotion.name ?? "Unknown") - Intensity: \(String(format: "%.1f", emotion.intensity))/10"
            currentY = drawBulletPoint(text: emotionText, in: rect, at: currentY)
            currentY += 2
        }
        
        return currentY
    }
    
    private func drawActions(actions: [Action], in rect: CGRect, at yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition
        
        currentY = drawSectionHeader(title: "Actions", in: rect, at: currentY)
        currentY += 10
        
        for action in actions {
            let completionStatus = action.isCompleted ? "✓" : "○"
            let actionText = "\(completionStatus) \(action.title ?? "Unknown action")"
            currentY = drawBulletPoint(text: actionText, in: rect, at: currentY)
            currentY += 2
        }
        
        return currentY
    }
    
    private func drawSection(title: String, content: String, in rect: CGRect, at yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition
        
        currentY = drawSectionHeader(title: title, in: rect, at: currentY)
        currentY += 10
        
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        let contentRect = CGRect(
            x: AppConstants.PDF.pageMargin,
            y: currentY,
            width: rect.width - 2 * AppConstants.PDF.pageMargin,
            height: 200 // Will be adjusted by content
        )
        
        let contentSize = content.boundingRect(
            with: CGSize(width: contentRect.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: contentAttributes,
            context: nil
        )
        
        content.draw(in: contentRect, withAttributes: contentAttributes)
        return currentY + contentSize.height
    }
    
    private func drawSectionHeader(title: String, in rect: CGRect, at yPosition: CGFloat) -> CGFloat {
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        
        let headerSize = title.size(withAttributes: headerAttributes)
        let headerRect = CGRect(
            x: AppConstants.PDF.pageMargin,
            y: yPosition,
            width: headerSize.width,
            height: headerSize.height
        )
        
        title.draw(in: headerRect, withAttributes: headerAttributes)
        return yPosition + headerSize.height
    }
    
    private func drawBulletPoint(text: String, in rect: CGRect, at yPosition: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        let textRect = CGRect(
            x: AppConstants.PDF.pageMargin + 20,
            y: yPosition,
            width: rect.width - 2 * AppConstants.PDF.pageMargin - 20,
            height: 50
        )
        
        let textSize = text.boundingRect(
            with: CGSize(width: textRect.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin],
            attributes: attributes,
            context: nil
        )
        
        text.draw(in: textRect, withAttributes: attributes)
        return yPosition + textSize.height
    }
    
    private func drawDayEntry(day: String, status: String, in rect: CGRect, at yPosition: CGFloat) -> CGFloat {
        let dayAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        let statusAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray
        ]
        
        // Draw day
        let dayRect = CGRect(
            x: AppConstants.PDF.pageMargin,
            y: yPosition,
            width: 120,
            height: 15
        )
        day.draw(in: dayRect, withAttributes: dayAttributes)
        
        // Draw status
        let statusRect = CGRect(
            x: AppConstants.PDF.pageMargin + 130,
            y: yPosition,
            width: rect.width - AppConstants.PDF.pageMargin - 130,
            height: 15
        )
        status.draw(in: statusRect, withAttributes: statusAttributes)
        
        return yPosition + 15
    }
    
    private func drawFooter(in rect: CGRect) {
        let footerText = "Generated by \(AppConstants.appName) on \(Date().shortDateString())"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]
        
        let footerSize = footerText.size(withAttributes: footerAttributes)
        let footerRect = CGRect(
            x: (rect.width - footerSize.width) / 2,
            y: rect.height - AppConstants.PDF.pageMargin,
            width: footerSize.width,
            height: footerSize.height
        )
        
        footerText.draw(in: footerRect, withAttributes: footerAttributes)
    }
}
