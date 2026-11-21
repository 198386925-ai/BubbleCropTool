import UIKit

/// 气泡在预览里的位置角色。
/// 左边三个用左尾巴图，右边三个用右尾巴图。
enum BubbleSlot: String, CaseIterable {
    /// 左上：宽
    case leftTop
    /// 左中：单尾巴（“左单”，一键自动的参考图）
    case leftMiddle
    /// 左下：短
    case leftBottom
    /// 右中：短单尾巴
    case rightMiddle
    /// 右下中：中
    case rightLowerMiddle
    /// 右下：宽
    case rightBottom

    /// 是否左边的气泡
    var isLeft: Bool {
        switch self {
        case .leftTop, .leftMiddle, .leftBottom: return true
        case .rightMiddle, .rightLowerMiddle, .rightBottom: return false
        }
    }

    /// 预览里的示例文字（照截图里的五条，左中单那条放星星分隔线）
    var sampleText: String {
        switch self {
        case .leftTop: return "Are you alright, Youyou"
        case .leftMiddle: return "☆ · ------ · ☆"
        case .leftBottom: return "给你挑了最好看的一张"
        case .rightMiddle: return "Good-looking!"
        case .rightLowerMiddle: return "I've received it.✦"
        case .rightBottom: return "收到啦，谢谢你"
        }
    }

    /// 该位置用的内置气泡图文件名（浅色日间 / 深色夜间）。
    /// 左边用左尾巴图，右边用右尾巴图。
    func builtinFileName(isDark: Bool) -> String {
        let prefix = isDark ? "深 " : "浅 "
        switch self {
        case .leftTop: return prefix + "左上.PNG"
        case .leftMiddle: return prefix + "左中:单.PNG"
        case .leftBottom: return prefix + "左下.PNG"
        case .rightMiddle: return prefix + "右中:单.PNG"
        case .rightLowerMiddle: return prefix + "右上.PNG"
        case .rightBottom: return prefix + "右下.PNG"
        }
    }

    /// 在 1080×1080 预览画布上的位置（用户定的三左三右排版，
    /// 间距缩过两次后的版本：列内间距约 13–15px）。
    /// x/y/w/h 都是 0…1 的归一化值。
    var normalizedFrame: CGRect {
        switch self {
        case .leftTop:
            return CGRect(x: 88.0 / 1080, y: 99.0 / 1080, width: 484.0 / 1080, height: 161.0 / 1080)
        case .leftMiddle:
            return CGRect(x: 90.0 / 1080, y: 275.0 / 1080, width: 366.0 / 1080, height: 161.0 / 1080)
        case .leftBottom:
            return CGRect(x: 88.0 / 1080, y: 450.0 / 1080, width: 252.0 / 1080, height: 162.0 / 1080)
        case .rightMiddle:
            return CGRect(x: 674.0 / 1080, y: 397.0 / 1080, width: 252.0 / 1080, height: 165.0 / 1080)
        case .rightLowerMiddle:
            return CGRect(x: 562.0 / 1080, y: 576.0 / 1080, width: 362.0 / 1080, height: 155.0 / 1080)
        case .rightBottom:
            return CGRect(x: 446.0 / 1080, y: 744.0 / 1080, width: 480.0 / 1080, height: 171.0 / 1080)
        }
    }
}

/// 一张气泡图：内置或用户导入的。
struct BubbleImage: Identifiable, Equatable {
    let id = UUID()
    /// 显示名（文件名）
    var name: String
    /// 图片
    var image: UIImage

    static func == (lhs: BubbleImage, rhs: BubbleImage) -> Bool {
        lhs.id == rhs.id
    }
}
