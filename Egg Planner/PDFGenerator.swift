import SwiftUI

class PDFGenerator {
    static func generateReport(viewModel: AnalyticsViewModel) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Egg Planner",
            kCGPDFContextAuthor: "Egg Planner App"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 595.2
        let pageHeight = 841.8
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)

        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let titleAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)]
            let text = "Egg Planner Report\n\n"
            let title = NSAttributedString(string: text, attributes: titleAttributes)
            title.draw(at: CGPoint(x: 72, y: 72))

            let bodyAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]
            let bodyText = """
            Total eggs collected: \(viewModel.totalEggs)
            Average shelf life: \(String(format: "%.1f", viewModel.avgShelfLife)) days
            Average weight: \(String(format: "%.1f", viewModel.avgWeight)) g
            """
            let body = NSAttributedString(string: bodyText, attributes: bodyAttributes)
            body.draw(at: CGPoint(x: 72, y: 120))
        }
        return data
    }
}
