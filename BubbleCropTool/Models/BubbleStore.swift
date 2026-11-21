import UIKit
import SwiftUI
import PhotosUI

/// 气泡裁剪工具的状态：气泡图、裁剪值、日/夜、撤销/重做、自动保存。
@MainActor
final class BubbleStore: ObservableObject {

    /// 六个位置的气泡图（左三右三）。
    /// key 是位置，value 是该位置当前用的图。
    @Published var bubbles: [BubbleSlot: BubbleImage] = [:]

    /// 当前裁剪值（四个数）。改动即自动保存。
    @Published var insets: CropInsets = .leftSingleReference {
        didSet { scheduleAutosave() }
    }

    /// 日间 / 夜间预览
    @Published var isNight: Bool = false {
        didSet { reloadBuiltinBubbles(); scheduleAutosave() }
    }

    /// 一键自动算出的参考值（面板里“自动约”显示用）
    @Published var autoHint: CropInsets = .leftSingleReference

    /// 已自动保存提示（每次保存后短暂显示）
    @Published var justSaved: Bool = false

    /// 撤销 / 重做
    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false

    private var undoStack: [CropInsets] = []
    private var redoStack: [CropInsets] = []
    private var autosaveTask: Task<Void, Never>?

    private enum Keys {
        static let insets = "zhejiao.insets"
        static let isNight = "zhejiao.isNight"
    }

    init() {
        loadSavedInsets()
        reloadBuiltinBubbles()
        refreshAutoHint()
    }

    // MARK: - 内置气泡

    /// 按当前日/夜装入 12 张内置气泡里对应的 6 张。
    func reloadBuiltinBubbles() {
        for slot in BubbleSlot.allCases {
            let file = slot.builtinFileName(isDark: isNight)
            if let image = BubbleStore.builtinImage(named: file) {
                bubbles[slot] = BubbleImage(name: file, image: image)
            }
        }
    }

    /// 从 App Bundle 的 Bubbles 目录读内置图。
    static func builtinImage(named fileName: String) -> UIImage? {
        // 先按资源名找（放进 Assets 或直接拖进工程的情况）
        if let image = UIImage(named: fileName) { return image }
        // 再按 Bundle 里的 Bubbles 子目录找（Bubbles 是 folder reference）
        if let url = Bundle.main.url(forResource: fileName, withExtension: nil, subdirectory: "Bubbles"),
           let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        if let path = Bundle.main.path(forResource: fileName, ofType: nil, inDirectory: "Bubbles"),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        // 兜底：Bundle 根目录（个别打包方式会把图放根目录）
        if let url = Bundle.main.url(forResource: fileName, withExtension: nil),
           let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        if let path = Bundle.main.path(forResource: fileName, ofType: nil),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        return nil
    }

    // MARK: - 导入

    /// 用户从相册/文件导入一张气泡图，替换到指定位置。
    /// 导入后自动重算一键自动的参考值。
    func importBubble(_ image: UIImage, name: String, to slot: BubbleSlot) {
        bubbles[slot] = BubbleImage(name: name, image: image)
        saveImported(image, name: name, slot: slot)
        refreshAutoHint()
        scheduleAutosave()
    }

    /// 把导入的图存到 Documents，下次打开还在。
    private func saveImported(_ image: UIImage, name: String, slot: BubbleSlot) {
        guard let data = image.pngData() else { return }
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let url = dir?.appendingPathComponent("imported-\(slot.rawValue).png")
        guard let url else { return }
        try? data.write(to: url)
    }

    /// 启动时恢复导入过的图。
    func restoreImported() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        for slot in BubbleSlot.allCases {
            guard let url = dir?.appendingPathComponent("imported-\(slot.rawValue).png"),
                  let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data) else { continue }
            bubbles[slot] = BubbleImage(name: "导入的气泡", image: image)
        }
    }

    // MARK: - 裁剪值

    /// 改一个边的值（记入撤销栈）。
    func setInset(_ keyPath: WritableKeyPath<CropInsets, Int>, to value: Int) {
        pushUndo()
        insets[keyPath: keyPath] = max(0, value)
    }

    /// 一键自动：用「左单」日间图算一遍，填进四个数。
    func autoCalculate() {
        pushUndo()
        // 参考图固定用左中:单的日间内置图（“左单”）。
        let ref = BubbleStore.builtinImage(named: "浅 左中:单.PNG")
            ?? bubbles[.leftMiddle]?.image
        if let ref {
            autoHint = AutoCrop.analyze(ref)
            insets = autoHint
        } else {
            insets = .leftSingleReference
            autoHint = .leftSingleReference
        }
    }

    /// 四边全部改回自动（0）。
    func resetAllToAuto() {
        pushUndo()
        insets = .auto
    }

    /// 当前生效的裁剪值（0 的边用自动值补齐）。
    var resolvedInsets: CropInsets {
        insets.resolved(with: autoHint)
    }

    /// 刷新“自动约”提示（按当前左单图重算）。
    func refreshAutoHint() {
        let ref = bubbles[.leftMiddle]?.image
            ?? BubbleStore.builtinImage(named: "浅 左中:单.PNG")
        if let ref { autoHint = AutoCrop.analyze(ref) }
    }

    // MARK: - 撤销 / 重做

    private func pushUndo() {
        undoStack.append(insets)
        if undoStack.count > 50 { undoStack.removeFirst() }
        redoStack.removeAll()
        refreshUndoRedo()
    }

    func undo() {
        guard let last = undoStack.popLast() else { return }
        redoStack.append(insets)
        insets = last
        refreshUndoRedo()
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(insets)
        insets = next
        refreshUndoRedo()
    }

    private func refreshUndoRedo() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }

    // MARK: - 自动保存

    private func scheduleAutosave() {
        autosaveTask?.cancel()
        autosaveTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            saveInsets()
            justSaved = true
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            justSaved = false
        }
    }

    private func saveInsets() {
        let defaults = UserDefaults.standard
        defaults.set(insets.top, forKey: Keys.insets + ".top")
        defaults.set(insets.left, forKey: Keys.insets + ".left")
        defaults.set(insets.bottom, forKey: Keys.insets + ".bottom")
        defaults.set(insets.right, forKey: Keys.insets + ".right")
        defaults.set(isNight, forKey: Keys.isNight)
    }

    private func loadSavedInsets() {
        let defaults = UserDefaults.standard
        isNight = defaults.bool(forKey: Keys.isNight)
        // 只有存过才恢复，否则用参考值。
        if defaults.object(forKey: Keys.insets + ".top") != nil {
            insets = CropInsets(
                top: defaults.integer(forKey: Keys.insets + ".top"),
                left: defaults.integer(forKey: Keys.insets + ".left"),
                bottom: defaults.integer(forKey: Keys.insets + ".bottom"),
                right: defaults.integer(forKey: Keys.insets + ".right")
            )
        }
    }
}
