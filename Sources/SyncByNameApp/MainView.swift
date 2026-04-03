import SwiftUI
import SyncByNameCore

struct MainView: View {
    @ObservedObject var controller: AppController

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                controls
                summary
                results
            }
            .padding(24)
        }
        .frame(minWidth: 980, minHeight: 760)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Sync by Name", systemImage: "arrow.triangle.branch")
                .font(.system(size: 28, weight: .semibold))
            Text("Compare folders and drives by filename only, preview the missing files, and copy those files into a chosen output folder.")
                .foregroundStyle(.secondary)
            Text(controller.statusMessage)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                folderCard(
                    title: "Source Folders",
                    symbol: "folder.badge.plus",
                    folders: controller.sourceRoots,
                    addAction: controller.addSourceRoots,
                    removeAction: controller.removeSourceRoot
                )

                folderCard(
                    title: "Comparison Folders",
                    symbol: "folder.badge.questionmark",
                    folders: controller.comparisonRoots,
                    addAction: controller.addComparisonRoots,
                    removeAction: controller.removeComparisonRoot
                )
            }

            SettingsCard(title: "Scan Rules", symbol: "line.3.horizontal.decrease.circle") {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Extensions")
                            .font(.headline)
                        TextField(
                            "Leave empty for every file, or enter values like mp4, mov, mxf",
                            text: Binding(
                                get: { controller.allowedExtensionsText },
                                set: { controller.updateAllowedExtensionsText($0) }
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Output Folder")
                            .font(.headline)
                        HStack {
                            Text(controller.outputRoot?.path ?? "No output folder selected")
                                .textSelection(.enabled)
                                .foregroundStyle(controller.outputRoot == nil ? .secondary : .primary)
                            Spacer()
                            Button("Choose Output Folder") {
                                controller.chooseOutputRoot()
                            }
                        }

                        Toggle(
                            "Preserve source-root folders when copying",
                            isOn: Binding(
                                get: { controller.preserveSourceFolders },
                                set: { controller.updatePreserveSourceFolders($0) }
                            )
                        )

                        Toggle(
                            "Match filenames case-sensitively",
                            isOn: Binding(
                                get: { controller.caseSensitiveFilenames },
                                set: { controller.updateCaseSensitiveFilenames($0) }
                            )
                        )

                        Toggle(
                            "Ignore hidden files during scan",
                            isOn: Binding(
                                get: { controller.ignoreHiddenFiles },
                                set: { controller.updateIgnoreHiddenFiles($0) }
                            )
                        )
                    }

                    HStack(spacing: 12) {
                        Button("Scan Missing Filenames") {
                            Task {
                                await controller.scan()
                            }
                        }
                        .disabled(controller.isBusy)

                        Button("Copy Missing Files") {
                            Task {
                                await controller.copyMissingFiles()
                            }
                        }
                        .disabled(controller.isBusy || controller.plan == nil || controller.outputRoot == nil)

                        Button("Clear Scan") {
                            controller.clearPlan()
                        }
                        .disabled(controller.plan == nil)
                    }
                }
            }
        }
    }

    private var summary: some View {
        SettingsCard(title: "Plan Summary", symbol: "checklist") {
            if let plan = controller.plan {
                HStack(spacing: 20) {
                    stat(title: "Source Files", value: "\(plan.summary.sourceFileCount)")
                    stat(title: "Comparison Names", value: "\(plan.summary.comparisonFileCount)")
                    stat(title: "Missing Files", value: "\(plan.summary.missingFileCount)")
                    stat(title: "Duplicate Missing Names", value: "\(plan.summary.duplicateMissingNameCount)")
                }
            } else {
                Text("Run a scan to preview filename-only differences before copying.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var results: some View {
        SettingsCard(title: "Missing Files", symbol: "doc.text.magnifyingglass") {
            if let plan = controller.plan, !plan.items.isEmpty {
                List(plan.items) { item in
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.filename)
                                .font(.headline)
                            Text(item.sourceURL.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                            Text("Relative path: \(item.relativePath)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                            if item.duplicateSourceCount > 1 {
                                Text("\(item.duplicateSourceCount)x in sources")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(minHeight: 320)
            } else {
                Text("No scan results yet.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func folderCard(
        title: String,
        symbol: String,
        folders: [URL],
        addAction: @escaping () -> Void,
        removeAction: @escaping (URL) -> Void
    ) -> some View {
        SettingsCard(title: title, symbol: symbol) {
            if folders.isEmpty {
                Text("No folders selected.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(folders, id: \.path) { folder in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(folder.lastPathComponent)
                                .font(.headline)
                            Text(folder.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        Spacer()
                        Button("Remove") {
                            removeAction(folder)
                        }
                    }
                    Divider()
                }
            }

            Button("Add Folder") {
                addAction()
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func stat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(size: 24, weight: .semibold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: symbol)
                .font(.headline)
            content()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}
