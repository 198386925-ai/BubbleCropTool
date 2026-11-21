import SwiftUI

/// 主界面：顶栏 + 实时预览 + 气泡裁剪面板。
/// 照截图里的「折角-You」工具排版。
struct ContentView: View {
    @StateObject private var store = BubbleStore()
    @State private var previewCollapsed = false
    @State private var showCropPanel = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                    // 顶栏
                    TopBarView(store: store)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    ScrollView {
                        VStack(spacing: 16) {
                            // 实时预览卡片
                            VStack(alignment: .leading, spacing: 12) {
                                PreviewHeaderView(
                                    store: store,
                                    isCollapsed: previewCollapsed,
                                    onToggleCollapse: { previewCollapsed.toggle() }
                                )
                                if !previewCollapsed {
                                    ChatPreviewView(store: store)
                                }
                            }
                            .padding(16)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                            // 打开裁剪面板
                            Button(action: { showCropPanel = true }) {
                                HStack {
                                    Image(systemName: "crop")
                                    Text("气泡裁剪")
                                        .font(.system(size: 17, weight: .medium))
                                    Spacer()
                                    Text("上 \(store.insets.top) · 左 \(store.insets.left) · 下 \(store.insets.bottom) · 右 \(store.insets.right)")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(16)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)

                            Text("上传的气泡按三左三右排版显示，左三个、右三个，间距已缩到最紧。点上面进裁剪，改数字预览立刻跟着变。")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 24)
                        }
                        .padding(.top, 12)
                    }
                }
            }
            .sheet(isPresented: $showCropPanel) {
                CropPanelView(
                    store: store,
                    onDone: { showCropPanel = false },
                    onCancel: { showCropPanel = false }
                )
            }
            .onAppear { store.restoreImported() }
    }
}

/// 顶栏：返回「商品」+ 标题「折角-You」+ 已自动保存 + 撤销/重做。
struct TopBarView: View {
    @ObservedObject var store: BubbleStore

    var body: some View {
        HStack(spacing: 12) {
            // 返回
            Button(action: {}) {
                HStack(spacing: 2) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                    Text("商品")
                        .font(.system(size: 17))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.08))
                .clipShape(Capsule())
            }

            Spacer()

            // 标题 + 已自动保存
            VStack(spacing: 0) {
                HStack(spacing: 2) {
                    Text("折角-You")
                        .font(.system(size: 17, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                Text("已自动保存")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            }

            Spacer()

            // 撤销 / 重做
            HStack(spacing: 0) {
                Button(action: { store.undo() }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 17))
                        .foregroundColor(store.canUndo ? .primary : .secondary.opacity(0.4))
                        .frame(width: 44, height: 36)
                }
                .disabled(!store.canUndo)
                Divider().frame(height: 20)
                Button(action: { store.redo() }) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 17))
                        .foregroundColor(store.canRedo ? .primary : .secondary.opacity(0.4))
                        .frame(width: 44, height: 36)
                }
                .disabled(!store.canRedo)
            }
            .background(Color.primary.opacity(0.08))
            .clipShape(Capsule())
        }
    }
}

#Preview {
    ContentView()
}
