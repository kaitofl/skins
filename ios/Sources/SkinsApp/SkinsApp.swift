import SwiftUI

@main struct SkinsApp: App {
  @ViewState private var store = AppStore()
  var body: some Scene {
    WindowGroup {
      RootView().environment(store).tint(SkinsStyle.accent).preferredColorScheme(.light)
        #if os(macOS)
          .frame(width: 430, height: 820)
        #endif
    }
    #if os(macOS)
      .windowResizability(.contentSize)
    #endif
  }
}
struct RootView: View {
  @Environment(AppStore.self) private var store
  @ViewState private var showBackup = false
  var body: some View {
    @Bindable var store = store
    TabView {
      NavigationStack { ShelfView() }.tabItem { Label("MyCosme", systemImage: "square.grid.2x2") }
      NavigationStack { AdviceView() }.tabItem { Label("Advice", systemImage: "sparkles") }
      NavigationStack { JournalView() }.tabItem { Label("Records", systemImage: "book.closed") }
    }
    .alert(
      "保存できませんでした",
      isPresented: Binding(get: { store.message != nil }, set: { if !$0 { store.message = nil } })
    ) {
      Button("閉じる", role: .cancel) { store.message = nil }
    } message: {
      Text(store.message ?? "")
    }
    .safeAreaInset(edge: .top, spacing: 0) {
      if store.loadError != nil {
        Button("保存データを復元する") { showBackup = true }.font(.subheadline).frame(maxWidth: .infinity)
          .padding(10).background(.orange.opacity(0.12))
      }
    }
    .sheet(isPresented: $showBackup) { BackupView() }
  }
}
