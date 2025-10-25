import Foundation
import UIKit
import PDFKit
import CoreData

class PDFExportService {
    static let shared = PDFExportService()
    
    private init() {}
    
    // Generate a student progress report
    func generateStudentProgressReport(
        student: Student,
        sessions: [ReadingSession],
        startDate: Date,
        endDate: Date
    ) -> Data? {
        
        let pdfMetaData = [
            kCGPDFContextCreator: AppConstants.appName,
            kCGPDFContextAuthor: "ReadWell Teacher",
            kCGPDFContextTitle: "Student Reading Progress Report"
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
            
            // Student info
            yPosition = drawStudentInfo(student: student, in: pageRect, at: yPosition)
            yPosition += 30
            
            // Date range
            yPosition = drawDateRange(startDate: startDate, endDate: endDate, in: pageRect, at: yPosition)
            yPosition += 30
            
            // Summary stats
            let avgComprehension = sessions.isEmpty ? 0.0 : sessions.map { $0.comprehensionScore }.reduce(0, +) / Double(sessions.count)
            yPosition = drawSummaryStats(
                sessionCount: sessions.count,
                avgComprehension: avgComprehension,
                totalDuration: sessions.reduce(0) { $0 + $1.duration },
                in: pageRect,
                at: yPosition
            )
            yPosition += 30
            
            // Session breakdown
            yPosition = drawSessionBreakdown(sessions: sessions, in: pageRect, at: yPosition)
            
            // Footer
            drawFooter(in: pageRect)
        }
        
        return data
    }
    
    // Generate a reading session report
    func generateReadingSessionReport(session: ReadingSession, student: Student?) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: AppConstants.appName,
            kCGPDFContextAuthor: "ReadWell Teacher",
            kCGPDFContextTitle: "Reading Session Report"
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
            
            // Student name if available
            if let student = student {
                yPosition = drawSection(title: "Student", content: student.name ?? "Unknown", in: pageRect, at: yPosition)
                yPosition += 20
            }
            
            // Session date
            yPosition = drawSessionDate(date: session.startDate, in: pageRect, at: yPosition)
            yPosition += 30
            
            // Text info
            if let text = session.text {
                yPosition = drawSection(title: "Text", content: text.title ?? "Unknown", in: pageRect, at: yPosition)
                yPosition += 20
            }
            
            // Session details
            let duration = String(format: "%.1f minutes", session.duration / 60)
            yPosition = drawSection(title: "Duration", content: duration, in: pageRect, at: yPosition)
            yPosition += 20
            
            // Comprehension score
            if session.comprehensionScore > 0 {
                let scoreText = String(format: "%.1f%%", session.comprehensionScore * 100)
                yPosition = drawSection(title: "Comprehension Score", content: scoreText, in: pageRect, at: yPosition)
                yPosition += 20
            }
            
            // Assistive features used
            var features: [String] = []
            if session.usedTTS { features.append("Text-to-Speech") }
            if session.usedTranslation { features.append("Translation") }
            if !features.isEmpty {
                yPosition = drawSection(title: "Assistive Features Used", content: features.joined(separator: ", "), in: pageRect, at: yPosition)
                yPosition += 20
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
    
    private func drawStudentInfo(student: Student, in rect: CGRect, at yPosition: CGFloat) -> CGFloat {
        let studentInfo = """
        Name: \(student.name ?? "Unknown")
        Grade Level: \(student.gradeLevel)
        Preferred Language: \(student.preferredLanguage ?? "en")
        """
        
        return drawSection(title: "Student Information", content: studentInfo, in: rect, at: yPosition)
    }
    
    private func drawDateRange(startDate: Date, endDate: Date, in rect: CGRect, at yPosition: CGFloat) -> CGFloat {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        let dateText = "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        
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
    
    private func drawSessionDate(date: Date?, in rect: CGRect, at yPosition: CGFloat) -> CGFloat {
        guard let date = date else { return yPosition }
        
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
        sessionCount: Int,
        avgComprehension: Double,
        totalDuration: Double,
        in rect: CGRect,
        at yPosition: CGFloat
    ) -> CGFloat {
        let hours = Int(totalDuration / 3600)
        let minutes = Int((totalDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        let statsText = """
        Sessions Completed: \(sessionCount)
        Average Comprehension: \(String(format: "%.1f%%", avgComprehension * 100))
        Total Reading Time: \(hours)h \(minutes)m
        """
        
        return drawSection(title: "Progress Summary", content: statsText, in: rect, at: yPosition)
    }
    
    private func drawSessionBreakdown(sessions: [ReadingSession], in rect: CGRect, at yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition
        
        // Draw section header
        currentY = drawSectionHeader(title: "Reading Sessions", in: rect, at: currentY)
        currentY += 10
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        for session in sessions.sorted(by: { $0.startDate ?? Date() > $1.startDate ?? Date() }) {
            guard let startDate = session.startDate else { continue }
            
            let dateText = formatter.string(from: startDate)
            let textTitle = session.text?.title ?? "Unknown Text"
            
            var statusParts: [String] = []
            if session.comprehensionScore > 0 {
                statusParts.append(String(format: "%.0f%%", session.comprehensionScore * 100))
            }
            if session.completedReading {
                statusParts.append("✓ Completed")
            }
            
            let statusText = statusParts.isEmpty ? "In Progress" : statusParts.joined(separator: " • ")
            
            currentY = drawSessionEntry(date: dateText, text: textTitle, status: statusText, in: rect, at: currentY)
            currentY += 5
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
    
    private func drawSessionEntry(date: String, text: String, status: String, in rect: CGRect, at yPosition: CGFloat) -> CGFloat {
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray
        ]
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.black
        ]
        
        let statusAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray
        ]
        
        var currentY = yPosition
        
        // Draw date
        let dateRect = CGRect(
            x: AppConstants.PDF.pageMargin + 10,
            y: currentY,
            width: rect.width - 2 * AppConstants.PDF.pageMargin - 10,
            height: 12
        )
        date.draw(in: dateRect, withAttributes: dateAttributes)
        currentY += 12
        
        // Draw text title
        let textRect = CGRect(
            x: AppConstants.PDF.pageMargin + 10,
            y: currentY,
            width: rect.width - 2 * AppConstants.PDF.pageMargin - 10,
            height: 14
        )
        text.draw(in: textRect, withAttributes: textAttributes)
        currentY += 14
        
        // Draw status
        let statusRect = CGRect(
            x: AppConstants.PDF.pageMargin + 10,
            y: currentY,
            width: rect.width - 2 * AppConstants.PDF.pageMargin - 10,
            height: 12
        )
        status.draw(in: statusRect, withAttributes: statusAttributes)
        currentY += 12
        
        return currentY
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
