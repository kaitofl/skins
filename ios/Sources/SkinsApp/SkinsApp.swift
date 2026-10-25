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
  @ViewState private var tab = 0
  var body: some View {
    @Bindable var store = store
    TabView(selection: $tab) {
      NavigationStack { ShelfView() }.tabItem {
        #if os(iOS)
          Label("ホーム", image: "CosmeticsTab")
        #else
          Label("ホーム", systemImage: "bubbles.and.sparkles")
        #endif
      }
      .tag(0)
      NavigationStack { AdviceView() }.tabItem { Label("アドバイス", systemImage: "sparkles") }
        .tag(1)
      NavigationStack { JournalView() }.tabItem { Label("記録", systemImage: "book.closed") }
        .tag(2)
    }
    .onChange(of: tab) { _, _ in SkinsStyle.feedback() }
    .alert(
      "保存できませんでした",
      isPresented: Binding(get: { store.message != nil }, set: { if !$0 { store.message = nil } })
    ) {
      Button("閉じる", role: .cancel) {
        SkinsStyle.feedback()
        store.message = nil
      }
    } message: {
      Text(store.message ?? "")
    }
    .safeAreaInset(edge: .top, spacing: 0) {
      if store.loadError != nil {
        Button("保存データを復元する") {
          SkinsStyle.feedback()
          showBackup = true
        }.font(.subheadline).frame(maxWidth: .infinity)
          .padding(10).background(.orange.opacity(0.12))
      }
    }
    .sheet(isPresented: $showBackup) { BackupView() }
  }
}
