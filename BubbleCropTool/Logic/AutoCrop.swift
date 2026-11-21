import UIKit

/// 一键自动：分析气泡图的 alpha 通道，算出四个边的裁剪值。
///
/// 标定：以「左单」（左中:单，171×120）日间图为准，算出来应约为
/// 上 9、左 17、下 11、右 12（工具自动值）。
/// 左单实测内容框：x 16–158，y 3–110。
enum AutoCrop {

    /// 分析一张气泡图，返回四个边的裁剪值。
    /// - Parameter image: 气泡 PNG（带透明通道）。
    /// - Returns: 算出的裁剪值；图读不到时返回参考值。
    static func analyze(_ image: UIImage) -> CropInsets {
        guard let cg = image.cgImage,
              let data = alphaData(of: cg) else {
            return CropInsets.leftSingleReference
        }
        let width = cg.width
        let height = cg.height

        // 内容框：alpha > 10 的像素范围。
        var x0 = width, x1 = -1, y0 = height, y1 = -1
        for y in 0..<height {
            for x in 0..<width {
                if data[y * width + x] > 10 {
                    if x < x0 { x0 = x }
                    if x > x1 { x1 = x }
                    if y < y0 { y0 = y }
                    if y > y1 { y1 = y }
                }
            }
        }
        guard x1 >= x0, y1 >= y0 else {
            return CropInsets.leftSingleReference
        }

        // 四个边的裁剪值（标定到工具自动值）：
        // 上：内容顶 + 6（顶部圆角名义值，左单 3 + 6 = 9）
        // 下：底部留白 + 1（左单 (120 - 110) + 1 = 11）
        // 左（尾巴那侧）：内容左 + 1（左单 16 + 1 = 17，刚好盖住尾巴尖）
        // 右：右边留白 - 1（左单 (171 - 158) - 1 = 12）
        let top = y0 + 6
        let bottom = (height - y1) + 1
        let left = x0 + 1
        let right = max((width - x1) - 1, 0)
        return CropInsets(top: top, left: left, bottom: bottom, right: right)
    }

    /// 同上，但返回每条边的“自动约”数值（面板里显示用）。
    /// 0 的边不显示约数。
    static func autoHint(for image: UIImage) -> CropInsets {
        analyze(image)
    }

    /// 读出 CGImage 的 alpha 通道（每像素一个字节）。
    private static func alphaData(of cg: CGImage) -> [UInt8]? {
        let width = cg.width
        let height = cg.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let raw = context.data else { return nil }
        let buffer = raw.bindMemory(to: UInt8.self, capacity: bytesPerRow * height)
        var alpha = [UInt8](repeating: 0, count: width * height)
        for y in 0..<height {
            for x in 0..<width {
                alpha[y * width + x] = buffer[y * bytesPerRow + x * bytesPerPixel + 3]
            }
        }
        return alpha
    }
}
