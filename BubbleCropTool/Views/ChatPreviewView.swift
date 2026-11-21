import SwiftUI

/// 实时预览：聊天底上的三左三右气泡排版。
/// 位置照用户定的 1080×1080 排版（间距缩过两次，列内约 13–15px），
/// 按预览区大小等比缩放。气泡用九宫格拉伸，随裁剪值实时变。
struct ChatPreviewView: View {
    @ObservedObject var store: BubbleStore

    /// 日间聊天底 / 夜间聊天底
    private var backgroundColor: Color {
        store.isNight ? Color(red: 0.07, green: 0.07, blue: 0.07) : Color(red: 0.93, green: 0.93, blue: 0.93)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                backgroundColor
                ForEach(BubbleSlot.allCases, id: \.self) { slot in
                    if let bubble = store.bubbles[slot] {
                        let frame = slot.normalizedFrame
                        let rect = CGRect(
                            x: frame.origin.x * geo.size.width,
                            y: frame.origin.y * geo.size.height,
                            width: frame.width * geo.size.width,
                            height: frame.height * geo.size.height
                        )
                        BubbleWithText(
                            image: bubble.image,
                            insets: store.resolvedInsets,
                            text: slot.sampleText,
                            isDarkBubble: store.isNight,
                            fontSize: max(10, geo.size.width * 0.032)
                        )
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                    }
                }
            }
        }
        .aspectRatio(1.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// 预览区顶栏：实时预览 + 设置 + 日间/夜间 + 收起。
struct PreviewHeaderView: View {
    @ObservedObject var store: BubbleStore
    var isCollapsed: Bool
    var onToggleCollapse: () -> Void

    var body: some View {
        HStack {
            Text("实时预览")
                .font(.system(size: 18, weight: .semibold))
            Spacer()
            Button(action: {}) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Circle())
            }
            Picker("", selection: Binding(
                get: { store.isNight ? 1 : 0 },
                set: { store.isNight = ($0 == 1) }
            )) {
                Text("日间").tag(0)
                Text("夜间").tag(1)
            }
            .pickerStyle(.segmented)
            .frame(width: 130)
            Button(action: onToggleCollapse) {
                Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Circle())
            }
        }
    }
}
