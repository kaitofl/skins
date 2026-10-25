import SkinsCore
import SwiftUI

private struct Proposal: Identifiable {
  let id: String
  let kind: String
  let title: String
  let products: [Product]
  let body: String
  var editable: Int?
  var source: URL?
  var sourceLabel: String = "公式の案内を見る"
  var candidate = false
}
struct AdviceView: View {
  @Environment(AppStore.self) private var store
  @ViewState private var selected: Product?
  @ViewState private var editing: Product?
  @ViewState private var profile = false
  private var proposals: [Proposal] {
    let ps = store.state.products
    let night = ps.filter { $0.time == .pm }
    let morning = ps.filter { $0.time == .am }
    var result: [Proposal] = []
    let retinal = night.first { $0.name.contains("レチナール") || $0.name.contains("レチノール") }
    let azelaic = night.first { $0.name.contains("アゼライン酸") }
    if let retinal {
      let products = [retinal] + (azelaic.map { [$0] } ?? [])
      let overlap = azelaic.map { !Set(retinal.days).isDisjoint(with: $0.days) } ?? false
      result.append(
        Proposal(
          id: "schedule", kind: "使う日の見直し", title: overlap ? "夜の美容液を使う日を、分けてみる" : "夜の美容液は、曜日で使い分け",
          products: products,
          body: overlap
            ? "同じ日に使う設定があります。使い心地を比較したいなら、それぞれ別の日に使う設定を検討できます。"
            : "今の使用日を基準に肌の変化を記録し、頻度を変えるときは一方ずつ見直してみましょう。", editable: retinal.id))
    }
    if let emulsion = night.first(where: { $0.name.contains("イハダ") && $0.type == "乳液" }),
      !night.contains(where: { $0.name.contains("ナイトパック") || $0.type == "クリーム" || $0.type == "バーム" }
      )
    {
      result.append(
        Proposal(
          id: "moisture", kind: "アイテムの追加", title: "乳液のあとも乾燥するなら、夜の保湿をひとつ", products: [emulsion],
          body: "今の乳液でうるおいが足りている日は、そのままで。乾燥が残る日の追加候補として、同じイハダの薬用ナイトパックを検討できます。",
          source: URL(
            string:
              "https://www.shiseido.co.jp/sw/products/auth/SWFG070410.seam?online_shohin_ctlg_kbn=2&shohin_pl_c_cd=H05901"
          ), sourceLabel: "イハダ 薬用ナイトパックを確認 ↗", candidate: true))
    }
    if let wash = ps.first(where: { $0.name.contains("ビオレ") && $0.name.contains("ディープクレイ") }) {
      result.append(
        Proposal(
          id: "wash", kind: "使い方の見直し", title: "クレイ洗顔は、30秒を目安に", products: [wash],
          body: "花王の案内では、顔全体になじませる時間の目安は30秒。洗い上がりのつっぱりが気になる日は、まず使い方を確認してみましょう。",
          source: URL(string: "https://www.kao.com/jp/qa/detail/16345/"),
          sourceLabel: "花王の使用方法を確認 ↗"))
    }
    if let pdrn = morning.first(where: { $0.name.uppercased().contains("PDRN") }),
      let vitamin = morning.first(where: { $0.name.contains("ビタミン") })
    {
      result.append(
        Proposal(
          id: "serums", kind: "アイテム構成の見直し", title: "朝の美容液は、使い心地に合わせて", products: [pdrn, vitamin],
          body: "べたつきやメイクのよれが気になるなら、どちらか1本を使う日をつくる選択も。使用日を調整して仕上がりを比べてみましょう。", editable: vitamin.id)
      )
    }
    if result.isEmpty, let p = ps.first {
      result.append(
        Proposal(
          id: "baseline", kind: "使い方の見直し", title: "いつものケアと、肌の変化を見比べる", products: [p],
          body: "使用日と肌の記録を残して、今の使い方を振り返ってみましょう。", editable: p.id))
    }
    return result
  }
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        AppHeader()
        Text("提案").font(.largeTitle.weight(.medium))
        Text("今の\(store.state.products.count)アイテムから、ケアの次の一歩を。").font(.subheadline).foregroundStyle(
          SkinsStyle.muted)
        Button {
          profile = true
        } label: {
          HStack(spacing: 12) {
            Image(systemName: "face.smiling").font(.title2)
            VStack(alignment: .leading, spacing: 5) {
              Text("肌プロフィール").font(.caption)
              Text(store.state.skin).font(.headline)
            }
            Spacer()
            Text("診断しなおす").font(.subheadline)
            Image(systemName: "chevron.right").font(.caption)
          }
          .padding(18).background(SkinsStyle.surface, in: RoundedRectangle(cornerRadius: 18))
        }.buttonStyle(.plain)
        HStack {
          SectionCaption(title: "あなたへの提案")
          Text("\(proposals.count)件").font(.caption).foregroundStyle(SkinsStyle.muted)
        }
        if proposals.isEmpty {
          ContentUnavailableView(
            "アイテムを登録しましょう", systemImage: "square.grid.2x2",
            description: Text("MyCosmeに登録した商品をもとに提案します。"))
        }
        ForEach(Array(proposals.enumerated()), id: \.element.id) { index, proposal in
          VStack(alignment: .leading, spacing: 18) {
            Text(String(format: "%02d", index + 1) + "  " + proposal.kind).font(.caption)
              .foregroundStyle(SkinsStyle.muted)
            Text(proposal.title).font(.title3.weight(.semibold)).fixedSize(
              horizontal: false, vertical: true)
            VStack(spacing: 0) {
              ForEach(proposal.products) { p in
                Button {
                  selected = p
                } label: {
                  HStack(spacing: 12) {
                    ProductArt(product: p, height: 64).frame(width: 44)
                    VStack(alignment: .leading, spacing: 5) {
                      Text(p.brand).font(.caption).foregroundStyle(SkinsStyle.muted)
                      Text(p.displayName).font(.subheadline.weight(.medium))
                      Text("\(p.time.title) · \(p.daysLabel)").font(.caption).foregroundStyle(
                        SkinsStyle.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption)
                  }.padding(12)
                }.buttonStyle(.plain)
              }
            }.background(SkinsStyle.surface, in: RoundedRectangle(cornerRadius: 12))
            Text(proposal.body).font(.body).foregroundStyle(SkinsStyle.muted).lineSpacing(6)
            if let id = proposal.editable,
              let p = store.state.products.first(where: { $0.id == id })
            {
              Button {
                editing = p
              } label: {
                HStack {
                  Text("登録内容を見直す")
                  Spacer()
                  Image(systemName: "arrow.right")
                }.font(.subheadline).padding(14).background(
                  SkinsStyle.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
              }.buttonStyle(.plain)
            }
            if let url = proposal.source {
              Link(proposal.sourceLabel, destination: url).font(.subheadline)
            }
          }.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(
            .white, in: RoundedRectangle(cornerRadius: 20)
          ).overlay(RoundedRectangle(cornerRadius: 20).stroke(SkinsStyle.line))
        }
      }.padding(22).foregroundStyle(SkinsStyle.ink)
    }.navigationTitle("")
      .sheet(item: $selected) { ProductSheet(product: $0) }.sheet(item: $editing) {
        ProductEditor(product: $0)
      }
      .sheet(isPresented: $profile) { ProfileView() }
  }
}
struct ProfileView: View {
  @Environment(AppStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  @ViewState private var skin = "混合肌"
  var body: some View {
    NavigationStack {
      Form {
        Section { Text("洗顔後の肌に、一番近いものは？").font(.headline) }
        Section {
          Picker("肌の状態", selection: $skin) {
            Text("全体的につっぱる").tag("乾燥肌傾向")
            Text("Tゾーンだけ皮脂が出る").tag("混合肌")
            Text("全体的に皮脂が出る").tag("脂性肌傾向")
            Text("気にならない").tag("普通肌傾向")
          }.pickerStyle(.inline)
        }
        Section { Text("回答をもとにしたセルフチェックの目安です。").font(.footnote).foregroundStyle(.secondary) }
      }.navigationTitle("肌プロフィール").toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("閉じる") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) {
          Button("更新") { if store.commit({ $0.skin = skin }) { dismiss() } }
        }
      }.onAppear { skin = store.state.skin }
    }.presentationDetents([.medium, .large])
  }
}
