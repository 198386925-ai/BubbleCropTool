import Foundation

/// 九宫格裁剪值：四个边各留多宽不拉伸。
/// 长消息只拉中间，角和尾巴不变形。
/// 0 = 这一边自动识别。
struct CropInsets: Equatable, Codable {
    /// 上边不拉伸的宽度（像素，按原图尺寸计）
    var top: Int
    /// 左边（尾巴那侧）不拉伸的宽度
    var left: Int
    /// 下边不拉伸的宽度
    var bottom: Int
    /// 右边不拉伸的宽度
    var right: Int

    /// 全部自动（0 = 自动识别）
    static let auto = CropInsets(top: 0, left: 0, bottom: 0, right: 0)

    /// 工具“一键自动”对「左单」日间算出的参考值。
    /// 左中:单（171×120）实测：上 9、左 17、下 11、右 12。
    static let leftSingleReference = CropInsets(top: 9, left: 17, bottom: 11, right: 12)

    /// 是否全部为自动
    var isAllAuto: Bool { top == 0 && left == 0 && bottom == 0 && right == 0 }

    /// 转成 UIEdgeInsets（给 UIImage.resizableImage 用）。
    /// 0 的边在渲染时按自动值补齐。
    func resolved(with auto: CropInsets) -> CropInsets {
        CropInsets(
            top: top == 0 ? auto.top : top,
            left: left == 0 ? auto.left : left,
            bottom: bottom == 0 ? auto.bottom : bottom,
            right: right == 0 ? auto.right : right
        )
    }
}
