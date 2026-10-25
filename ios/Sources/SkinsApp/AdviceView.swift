import SkinsCore
import SwiftUI

struct ProductCandidate: Decodable, Identifiable {
  let id: String
  let name: String
  let brand: String
  let size: String
  let kind: String
  let asset: String
  let points: [String]
  let howTo: String
  let source: String
  let checkedAt: String
  var artProduct: Product {
    var p = Product(id: -1, name: name, brand: brand)
    p.asset = asset
    return p
  }
  func matches(_ products: [Product]) -> Bool {
    guard !products.contains(where: { $0.sourceUrl == source || $0.name.contains(name) }) else {
      return false
    }
    if kind == "cleanser" {
      return products.contains { $0.name.contains("ディープクレイ") }
    }
    return products.contains { $0.time == .pm && $0.type == "乳液" }
      && !products.contains { $0.time == .pm && ["クリーム", "バーム"].contains($0.type) }
  }
  func pairing(_ products: [Product]) -> Product? {
    if kind == "cleanser" { return products.first { $0.name.contains("ディープクレイ") } }
    return products.first { $0.time == .pm && $0.type == "乳液" }
  }
  func reason(_ products: [Product]) -> String {
    let paired = pairing(products)
    if kind == "cleanser" { return "\(paired?.brand ?? "今")のクレイ洗顔でつっぱるなら、洗顔を泡タイプに置き換える候補。" }
    if id == "ihada-balm", paired?.name.contains("イハダ") == true {
      return "今使っているイハダ乳液のあとに、乾燥する部分だけ同じブランドのバームを足す候補。"
    }
    return "今の夜ケアは\(paired?.brand ?? "")の乳液まで。乾燥が残る日の、仕上げのクリーム候補。"
  }
}

struct AdviceView: View {
  @Environment(AppStore.self) private var store
  @ViewState private var selected: Product?
  @ViewState private var editing: Product?
  @ViewState private var candidate: ProductCandidate?
  @ViewState private var profile = false
  @ViewState private var expandedExamples: Set<String> = []
  private var proposals: [CareProposal] { CareAdvice.current(store.state) }
  private var candidates: [ProductCandidate] {
    store.candidates.filter { $0.matches(store.state.products) }
  }
  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 22) {
        AppHeader()
        Text("アドバイス").font(.largeTitle.weight(.medium))
        Text("今のアイテムと、最近の肌の記録から。").font(.subheadline).foregroundStyle(SkinsStyle.muted)
        Button {
          SkinsStyle.feedback()
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
          }.padding(18).background(SkinsStyle.surface, in: RoundedRectangle(cornerRadius: 18))
        }.buttonStyle(SkinsPressStyle())
        let contextual = proposals.filter { $0.context != nil }
        if !contextual.isEmpty {
          SectionCaption(title: "最近の記録に合わせて")
          ForEach(contextual) { proposalCard($0) }
        }
        if !candidates.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            SectionCaption(title: "今の棚に合わせた商品候補")
            Text("美容液は充実。足すなら保湿、洗顔は置き換えに。保湿の2点は比較候補です。")
              .font(.subheadline).foregroundStyle(SkinsStyle.muted).lineSpacing(4)
          }.padding(.top, 6)
          ForEach(candidates) { item in candidateCard(item) }
        }
        SectionCaption(title: "今のケアへの提案").padding(.top, 8)
        if proposals.isEmpty {
          ContentUnavailableView(
            "アイテムを登録しましょう", systemImage: "bubbles.and.sparkles",
            description: Text("ホームの棚に登録した商品をもとに提案します。"))
        }
        ForEach(proposals.filter { $0.context == nil }) { proposalCard($0) }
        VStack(alignment: .leading, spacing: 8) {
          SectionCaption(title: "こんな日のケア")
          Text("気になる状態をタップ。記録がある日は、上にも提案が出ます。")
            .font(.subheadline).foregroundStyle(SkinsStyle.muted)
        }.padding(.top, 8)
        ForEach(CareAdvice.examples(store.state)) { example in
          DisclosureGroup(
            isExpanded: Binding(
              get: { expandedExamples.contains(example.id) },
              set: { expanded in
                SkinsStyle.feedback()
                if expanded {
                  expandedExamples.insert(example.id)
                } else {
                  expandedExamples.remove(example.id)
                }
              }
            )
          ) {
            VStack(alignment: .leading, spacing: 16) {
              Text(example.title).font(.headline).padding(.top, 12)
              productLinks(example.productIDs)
              Text(example.body).font(.body).foregroundStyle(SkinsStyle.muted).lineSpacing(5)
              sourceLink(example.source)
            }
          } label: {
            Text(example.kind).font(.body.weight(.medium)).foregroundStyle(SkinsStyle.ink)
          }.padding(18).background(SkinsStyle.surface, in: RoundedRectangle(cornerRadius: 18))
        }
      }.padding(22).padding(.bottom, 24).foregroundStyle(SkinsStyle.ink)
    }.navigationTitle("")
      .sheet(item: $selected) { ProductSheet(product: $0) }
      .sheet(item: $editing) { ProductEditor(product: $0) }
      .sheet(item: $candidate) { CandidateSheet(candidate: $0) }
      .sheet(isPresented: $profile) { ProfileView() }
  }
  private func proposalCard(_ proposal: CareProposal) -> some View {
    VStack(alignment: .leading, spacing: 18) {
      HStack {
        Text(proposal.kind).font(.caption.weight(.medium))
        Spacer()
        if let context = proposal.context { Text(context).font(.caption) }
      }.foregroundStyle(SkinsStyle.muted)
      Text(proposal.title).font(.title3.weight(.semibold)).fixedSize(
        horizontal: false, vertical: true)
      productLinks(proposal.productIDs)
      Text(proposal.body).font(.body).foregroundStyle(SkinsStyle.muted).lineSpacing(6)
      if let id = proposal.editID, let product = store.state.products.first(where: { $0.id == id })
      {
        Button {
          SkinsStyle.feedback()
          editing = product
        } label: {
          HStack {
            Text("使う曜日を見直す")
            Spacer()
            Image(systemName: "arrow.right")
          }.font(.subheadline).padding(14).background(
            SkinsStyle.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(SkinsPressStyle())
      }
      sourceLink(proposal.source)
    }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
      .background(.white, in: RoundedRectangle(cornerRadius: 22))
      .overlay(RoundedRectangle(cornerRadius: 22).stroke(SkinsStyle.line))
  }
  private func productLinks(_ ids: [Int]) -> some View {
    VStack(spacing: 0) {
      ForEach(ids.compactMap { id in store.state.products.first { $0.id == id } }) { p in
        Button {
          SkinsStyle.feedback()
          selected = p
        } label: {
          HStack(spacing: 12) {
            ProductArt(product: p, height: 58).frame(width: 40)
            VStack(alignment: .leading, spacing: 4) {
              Text(p.brand + " · " + p.shelfLabel).font(.subheadline.weight(.medium))
              Text("\(p.time.title) · \(p.daysLabel)").font(.caption).foregroundStyle(
                SkinsStyle.muted)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption)
          }.padding(12)
        }.buttonStyle(SkinsPressStyle())
      }
    }.background(SkinsStyle.surface, in: RoundedRectangle(cornerRadius: 14))
  }
  private func candidateCard(_ item: ProductCandidate) -> some View {
    Button {
      SkinsStyle.feedback()
      candidate = item
    } label: {
      VStack(alignment: .leading, spacing: 16) {
        Text(item.kind == "cleanser" ? "洗顔の置き換え候補" : "乾く日の保湿候補")
          .font(.caption.weight(.medium)).foregroundStyle(SkinsStyle.muted)
        HStack(spacing: 18) {
          ProductArt(product: item.artProduct, height: 132).frame(width: 104)
          VStack(alignment: .leading, spacing: 8) {
            Text(item.brand).font(.caption.weight(.semibold)).tracking(1)
            Text(item.name).font(.headline).fixedSize(horizontal: false, vertical: true)
            Text(item.size).font(.subheadline).foregroundStyle(SkinsStyle.muted)
          }
        }.frame(maxWidth: .infinity, alignment: .leading)
        Text(item.reason(store.state.products)).font(.body).foregroundStyle(SkinsStyle.muted)
          .lineSpacing(5)
        HStack {
          Text("合わせ方と商品を見る")
          Spacer()
          Image(systemName: "arrow.up.right")
        }.font(.subheadline.weight(.medium))
      }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(SkinsStyle.surface, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(SkinsStyle.line))
    }.buttonStyle(SkinsPressStyle())
  }
  @ViewBuilder private func sourceLink(_ source: String?) -> some View {
    if let source, let url = URL(string: source) {
      Link(source.contains("aad.org") ? "皮膚科医によるケアの案内 ↗" : "公式の使い方を見る ↗", destination: url)
        .font(.subheadline).buttonStyle(SkinsPressStyle())
    }
  }
}

private struct CandidateSheet: View {
  @Environment(AppStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  let candidate: ProductCandidate
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          ProductArt(product: candidate.artProduct, height: 210).frame(maxWidth: .infinity)
          Text(candidate.brand).font(.subheadline).foregroundStyle(SkinsStyle.muted)
          Text(candidate.name).font(.title2.weight(.medium))
          Text(candidate.size + " · 医薬部外品").font(.subheadline).foregroundStyle(SkinsStyle.muted)
          Divider()
          SectionCaption(title: "今の棚にすすめる理由")
          Text(candidate.reason(store.state.products)).lineSpacing(5)
          if let paired = candidate.pairing(store.state.products) {
            HStack(spacing: 14) {
              ProductArt(product: paired, height: 70).frame(width: 45)
              VStack(alignment: .leading, spacing: 6) {
                Text(candidate.kind == "cleanser" ? "この洗顔の置き換えに" : "この乳液のあとに").font(.caption)
                  .foregroundStyle(SkinsStyle.muted)
                Text(paired.brand + " · " + paired.shelfLabel).font(.headline)
              }
            }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
              .background(SkinsStyle.surface, in: RoundedRectangle(cornerRadius: 16))
          }
          SectionCaption(title: "取り入れ方")
          Text(candidate.howTo).lineSpacing(5)
          SectionCaption(title: "公式情報で確認したこと")
          ForEach(candidate.points, id: \.self) { Text("・" + $0).font(.subheadline) }
          if let url = URL(string: candidate.source) {
            Link(destination: url) {
              Label("公式の商品情報を見る", systemImage: "arrow.up.right")
                .font(.headline).frame(maxWidth: .infinity, minHeight: 48)
                .background(SkinsStyle.surface, in: RoundedRectangle(cornerRadius: 14))
            }.buttonStyle(SkinsPressStyle())
          }
          Text("商品情報の確認：" + candidate.checkedAt).font(.caption).foregroundStyle(SkinsStyle.muted)
        }.padding(24).foregroundStyle(SkinsStyle.ink)
      }.navigationTitle("商品の提案").navigationBarTitleDisplayModeCompat()
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("閉じる") {
              SkinsStyle.feedback()
              dismiss()
            }
          }
        }
    }.presentationDetents([.large]).presentationDragIndicator(.visible)
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
      }.sensoryFeedback(.selection, trigger: skin)
        .navigationTitle("肌プロフィール").toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("閉じる") {
              SkinsStyle.feedback()
              dismiss()
            }
          }
          ToolbarItem(placement: .confirmationAction) {
            Button("更新") {
              SkinsStyle.feedback()
              if store.commit({ $0.skin = skin }) { dismiss() }
            }
          }
        }.onAppear { skin = store.state.skin }
    }.presentationDetents([.medium, .large])
  }
}
