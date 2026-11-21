import SwiftUI
import UIKit

/// 九宫格气泡图：角和尾巴不拉伸，只拉中间。
/// 用 UIImage.resizableImage(withCapInsets:resizingMode: .stretch) 实现，
/// 这是 iOS 标准的九宫格（9-patch）等价物。
struct NinePatchImage: UIViewRepresentable {
    /// 气泡原图
    var image: UIImage
    /// 四个边的裁剪值（像素，按原图尺寸计）。
    /// 0 的边由调用方先按自动值补齐。
    var insets: CropInsets

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleToFill
        view.clipsToBounds = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        let cap = UIEdgeInsets(
            top: CGFloat(insets.top),
            left: CGFloat(insets.left),
            bottom: CGFloat(insets.bottom),
            right: CGFloat(insets.right)
        )
        // capInsets 必须小于原图尺寸，否则 resizableImage 会退化。
        let safe = UIEdgeInsets(
            top: min(max(cap.top, 0), CGFloat(image.size.height) / 2 - 1),
            left: min(max(cap.left, 0), CGFloat(image.size.width) / 2 - 1),
            bottom: min(max(cap.bottom, 0), CGFloat(image.size.height) / 2 - 1),
            right: min(max(cap.right, 0), CGFloat(image.size.width) / 2 - 1)
        )
        uiView.image = image.resizableImage(withCapInsets: safe, resizingMode: .stretch)
    }
}

/// 带文字的气泡：九宫格底 + 居中文字。
/// 文字颜色按日间/夜间区分（浅色泡黑字，深色泡白字）。
struct BubbleWithText: View {
    var image: UIImage
    var insets: CropInsets
    var text: String
    var isDarkBubble: Bool
    var fontSize: CGFloat

    var body: some View {
        ZStack {
            NinePatchImage(image: image, insets: insets)
            Text(text)
                .font(.system(size: fontSize))
                .foregroundColor(isDarkBubble ? .white : .black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
    }
}
