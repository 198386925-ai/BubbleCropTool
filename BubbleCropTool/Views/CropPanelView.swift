import SwiftUI
import PhotosUI

/// 气泡裁剪面板（底部弹窗）：四个边的裁剪值 + 一键自动 + 改回自动。
/// 只对文字气泡生效（按下态跟着普通态）。
struct CropPanelView: View {
    @ObservedObject var store: BubbleStore
    var onDone: () -> Void
    var onCancel: () -> Void

    @State private var showImporter = false
    @State private var importTarget: BubbleSlot = .leftMiddle
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 0) {
            // 顶栏：取消 / 标题 / 完成
            HStack {
                Button("取消", action: onCancel)
                    .foregroundColor(.blue)
                    .font(.system(size: 17))
                Spacer()
                Text("气泡裁剪")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Button("完成", action: onDone)
                    .foregroundColor(.blue)
                    .font(.system(size: 17, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("填四个边各留多宽不拉伸，长消息只拉中间，角和尾巴不变形。0 = 这一边自动识别。自己的气泡自动左右镜像。")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)

                    // 一键自动
                    Button(action: { store.autoCalculate() }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("一键自动")
                                .font(.system(size: 17, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)

                    Text("用「左单」日间算一遍，填进下面四个数")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)

                    // 四个边
                    VStack(spacing: 0) {
                        InsetRow(
                            title: "上",
                            hint: "自动约 \(store.autoHint.top)",
                            value: store.insets.top,
                            onChange: { store.setInset(\.top, to: $0) }
                        )
                        Divider().padding(.leading, 20)
                        InsetRow(
                            title: "左（尾巴那侧）",
                            hint: "自动约 \(store.autoHint.left)",
                            value: store.insets.left,
                            onChange: { store.setInset(\.left, to: $0) }
                        )
                        Divider().padding(.leading, 20)
                        InsetRow(
                            title: "下",
                            hint: "自动约 \(store.autoHint.bottom)",
                            value: store.insets.bottom,
                            onChange: { store.setInset(\.bottom, to: $0) }
                        )
                        Divider().padding(.leading, 20)
                        InsetRow(
                            title: "右",
                            hint: "自动约 \(store.autoHint.right)",
                            value: store.insets.right,
                            onChange: { store.setInset(\.right, to: $0) }
                        )
                    }
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                    // 改回自动
                    Button("四边全部改回自动") {
                        store.resetAllToAuto()
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)

                    // 导入气泡
                    VStack(alignment: .leading, spacing: 8) {
                        Text("导入自己的气泡")
                            .font(.system(size: 15, weight: .semibold))
                        Text("从相册选一张气泡图，替换到对应位置，预览里立刻就能看到。")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Picker("替换位置", selection: $importTarget) {
                            ForEach(BubbleSlot.allCases, id: \.self) { slot in
                                Text(slotLabel(slot)).tag(slot)
                            }
                        }
                        .pickerStyle(.segmented)
                        Button(action: { showImporter = true }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("从相册导入气泡图")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.primary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal, 20)

                    Text("只对文字气泡生效（按下态跟着普通态）。红包、语音等用微信自己的拉伸方式，图要照微信原图的大小来画。")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
            }
        }
        .background(Color(.systemBackground))
        .photosPicker(isPresented: $showImporter, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    store.importBubble(image, name: "导入的气泡", to: importTarget)
                }
                selectedItem = nil
            }
        }
    }

    private func slotLabel(_ slot: BubbleSlot) -> String {
        switch slot {
        case .leftTop: return "左上"
        case .leftMiddle: return "左单"
        case .leftBottom: return "左下"
        case .rightMiddle: return "右单"
        case .rightLowerMiddle: return "右上"
        case .rightBottom: return "右下"
        }
    }
}

/// 一行裁剪值：标题 + 自动约 + 减号 / 数字 / 加号。
struct InsetRow: View {
    var title: String
    var hint: String
    var value: Int
    var onChange: (Int) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17))
                Text(hint)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: { onChange(value - 1) }) {
                Image(systemName: "minus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(Circle())
            }
            Text("\(value)")
                .font(.system(size: 20, weight: .medium))
                .frame(minWidth: 64)
                .multilineTextAlignment(.center)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Button(action: { onChange(value + 1) }) {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}
