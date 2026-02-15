import Combine
import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("themeMode") var themeModeRaw: String = AppThemeMode.system.rawValue
    @AppStorage("volumeUnit") var volumeUnitRaw: String = VolumeUnit.oz.rawValue
    @AppStorage("enablePacing") var enablePacing: Bool = false
    @AppStorage("enableHydrationReminder") var enableHydrationReminder: Bool = false
    @AppStorage("pacingMinutes") var pacingMinutes: Int = 45

    var themeMode: AppThemeMode {
        get { AppThemeMode(rawValue: themeModeRaw) ?? .system }
        set { themeModeRaw = newValue.rawValue }
    }

    var volumeUnit: VolumeUnit {
        get { VolumeUnit(rawValue: volumeUnitRaw) ?? .oz }
        set { volumeUnitRaw = newValue.rawValue }
    }
}
