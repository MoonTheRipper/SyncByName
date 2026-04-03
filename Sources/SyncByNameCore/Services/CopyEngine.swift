import Foundation

public enum CopyEngine {
    public static func copy(
        plan: SyncPlan,
        configuration: CopyConfiguration
    ) throws -> CopyResult {
        let fileManager = FileManager.default
        var copiedDestinations: [URL] = []
        var skippedItems: [SyncPlanItem] = []
        var failures: [CopyFailure] = []

        for item in plan.items {
            let destination = destinationURL(for: item, configuration: configuration)
            let destinationDirectory = destination.deletingLastPathComponent()

            do {
                try fileManager.createDirectory(
                    at: destinationDirectory,
                    withIntermediateDirectories: true
                )

                if fileManager.fileExists(atPath: destination.path) {
                    if configuration.replaceExisting {
                        try fileManager.removeItem(at: destination)
                    } else {
                        skippedItems.append(item)
                        continue
                    }
                }

                try fileManager.copyItem(at: item.sourceURL, to: destination)
                copiedDestinations.append(destination)
            } catch {
                failures.append(
                    CopyFailure(item: item, reason: error.localizedDescription)
                )
            }
        }

        return CopyResult(
            copiedDestinations: copiedDestinations,
            skippedItems: skippedItems,
            failures: failures
        )
    }

    private static func destinationURL(
        for item: SyncPlanItem,
        configuration: CopyConfiguration
    ) -> URL {
        if configuration.preserveSourceFolders {
            return configuration.outputRoot
                .appendingPathComponent(item.sourceRootURL.lastPathComponent, isDirectory: true)
                .appendingPathComponent(item.relativePath)
        }

        return configuration.outputRoot.appendingPathComponent(item.filename)
    }
}
