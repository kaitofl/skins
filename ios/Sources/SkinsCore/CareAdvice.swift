import Foundation

public struct CareProposal: Identifiable, Equatable, Sendable {
  public let id: String
  public let kind: String
  public let title: String
  public let body: String
  public let productIDs: [Int]
  public var editID: Int? = nil
  public var source: String? = nil
  public var context: String? = nil
}

/// Local, inspectable rules. Examples never masquerade as observations about the user.
public enum CareAdvice {
  private static let retinalSource =
    "https://celimax.us/products/the-vita-a-retinal-shot-tightening-booster"
  private static let acneSource = "https://www.aad.org/public/diseases/acne/skin-care/tips"

  public static func current(_ state: AppState, today: String = DayKey.today) -> [CareProposal] {
    let p = state.products
    let night = p.filter { $0.time == .pm }
    let morning = p.filter { $0.time == .am }
    let retinal = night.first { $0.name.contains("レチナール") || $0.name.contains("レチノール") }
    let azelaic = night.first { $0.name.contains("アゼライン酸") }
    let moisturizer = night.first { ["乳液", "クリーム", "バーム"].contains($0.type) }
    let wash = p.first { $0.type == "洗顔料" }
    let vitamin = morning.first { $0.shelfLabel == "ビタミンC" }
    let pdrn = morning.first { $0.shelfLabel == "PDRN" }
    let uv = morning.first { $0.type == "日焼け止め" }
    var result: [CareProposal] = []
    let recent = DayKey.recentDays(ending: DayKey.date(today) ?? Date())
    let freshKeys = Set(recent.suffix(2))
    if let record = state.records.filter({ freshKeys.contains($0.date) }).max(by: {
      $0.date < $1.date
    }) {
      let spots = record.acneSpots ?? []
      let context = record.date + " の記録から"
      if spots.contains(where: { $0.status == .worse }), let retinal {
        result.append(
          CareProposal(
            id: "worse", kind: "今日のケア", title: "悪化にヒリつきも重なるなら、レチナールはお休み",
            body:
              "ニキビの悪化が記録されています。赤み・ヒリつき・皮むけもあるなら、今夜はレチナールを休み、しみない保湿中心のケアに。ニキビだけで原因や中止の必要性は判断できません。強い痛みや悪化が続く場合は皮膚科へ。処方薬の変更は医師に確認しましょう。",
            productIDs: [retinal.id] + (moisturizer.map { [$0.id] } ?? []), source: retinalSource,
            context: context))
      }
      if record.mood == .dry, let moisturizer {
        result.append(
          CareProposal(
            id: "dry", kind: "今日のケア", title: "乾燥の記録がある日は、保湿を優先",
            body: "今ある乳液を丁寧になじませ、乾燥が残る部分だけクリームやバームを足す選択を。美容液でしみる場合は無理に重ねず、使ったものと肌の変化を残しましょう。",
            productIDs: [moisturizer.id],
            source: "https://www.kao-kirei.com/ja/official/curel/faq/", context: context))
      }
      if spots.contains(where: { $0.status == .better })
        && !spots.contains(where: { $0.status == .worse })
      {
        result.append(
          CareProposal(
            id: "better", kind: "今日のケア", title: "良くなってきたら、まず今のペースをキープ",
            body: "良くなってきた印が記録されています。すぐに美容液の頻度や量を増やさず、同じ場所の変化を追ってみましょう。",
            productIDs: [retinal, azelaic].compactMap { $0?.id }, source: acneSource,
            context: context))
      }
      if record.care == .rest || record.care == .partial {
        result.append(
          CareProposal(
            id: "restart", kind: "今日のケア", title: "お休みの翌日も、いつもの量で再開",
            body: "前日の分をまとめて使う必要はありません。洗顔・保湿・朝のUVから、できる範囲で戻してみましょう。",
            productIDs: [moisturizer, uv].compactMap { $0?.id }, context: context))
      }
    }
    if let retinal {
      let overlap = azelaic.map { !Set(retinal.days).isDisjoint(with: $0.days) } ?? false
      result.append(
        CareProposal(
          id: "schedule", kind: "使う日の提案",
          title: overlap ? "夜の美容液を使う日を、分けてみる" : "レチナールとアゼライン酸は、別の日に",
          body: overlap
            ? "今は同じ日に使う設定があります。刺激が気になるなら別の日に分け、どちらが合うか一方ずつ確かめる選択を。併用を一律に禁止する意味ではありません。"
            : "今は曜日を分けて使う設定です。肌に合っているならそのペースを保ち、増やす場合も一方ずつ。赤みやヒリつきがある日は肌の様子を優先しましょう。",
          productIDs: [retinal.id] + (azelaic.map { [$0.id] } ?? []), editID: retinal.id,
          source: retinalSource))
    }
    if let vitamin, let pdrn {
      result.append(
        CareProposal(
          id: "morning", kind: "朝のケアの提案", title: "よれる日は、朝の美容液を1本に",
          body: "朝はPDRNとビタミンCの2本。ベタつきやメイクのよれが気になるなら、片方だけの日をつくって仕上がりを比べてみましょう。合っている日は変える必要はありません。",
          productIDs: [pdrn.id, vitamin.id], editID: vitamin.id))
    }
    if let wash, wash.name.contains("ディープクレイ") {
      result.append(
        CareProposal(
          id: "wash", kind: "洗い方の提案", title: "クレイ洗顔は、30秒を目安に",
          body: "花王が案内する、顔全体になじませる時間の目安は30秒。長くマッサージするより、こすらず洗い流すことを意識してみましょう。つっぱりが続くなら洗顔料の置き換え候補も。",
          productIDs: [wash.id], source: "https://www.kao.com/jp/qa/detail/16345/"))
    }
    if let retinal, let uv {
      result.append(
        CareProposal(
          id: "uv", kind: "朝のケアの提案", title: "レチナールの翌朝も、UVを忘れずに",
          body:
            "今ある\(uv.brand)のUVを朝の最後に。塗り直しは商品の使い方に沿って、汗やタオルで落ちたときにも。BBやパウダーを重ねても、UVそのものの量は減らさないようにしましょう。",
          productIDs: [retinal.id, uv.id], source: retinalSource))
    }
    return result
  }

  public static func examples(_ state: AppState) -> [CareProposal] {
    let night = state.products.filter { $0.time == .pm }
    let retinal = night.first { $0.shelfLabel == "レチナール" || $0.shelfLabel == "レチノール" }
    let azelaic = night.first { $0.shelfLabel == "アゼライン酸" }
    let moisturizer = night.first { ["乳液", "クリーム", "バーム"].contains($0.type) }
    let vitamin = state.products.first { $0.shelfLabel == "ビタミンC" }
    let wash = state.products.first { $0.type == "洗顔料" }
    var result: [CareProposal] = []
    if let retinal {
      result.append(
        CareProposal(
          id: "example-irritation", kind: "ニキビ悪化＋ヒリつく日", title: "今夜はレチナールをスキップ",
          body:
            "悪化したニキビに加え、赤み・ヒリつき・皮むけもある日は、化粧品のレチナールを休んでしみない保湿中心に。ニキビの悪化だけで原因は断定しません。痛みや悪化が続く場合は皮膚科へ。処方薬は自己判断で変更しないでください。",
          productIDs: [retinal.id] + (moisturizer.map { [$0.id] } ?? []), source: retinalSource))
    }
    if let moisturizer {
      result.append(
        CareProposal(
          id: "example-dry", kind: "頬や口元がカサつく日", title: "乳液のあと、乾く部分だけ保湿を追加",
          body: "Tゾーンはいつもの量、乾く頬や口元だけクリームかバームを少量追加。混合肌の全顔に一律で重ねず、部分ごとの使い心地を見てみましょう。",
          productIDs: [moisturizer.id], source: "https://www.kao-kirei.com/ja/official/curel/faq/"))
    }
    if let vitamin {
      result.append(
        CareProposal(
          id: "example-vitamin", kind: "ビタミンCがしみる日", title: "無理に続けず、いったんお休み",
          body: "刺激を感じる化粧品は無理に重ねず、肌に合う保湿だけに。刺激が続く場合は使用を中止して皮膚科に相談しましょう。落ち着いた後も、一度に複数の商品を戻さず様子を見ます。",
          productIDs: [vitamin.id], source: acneSource))
    }
    result.append(
      CareProposal(
        id: "example-new", kind: "新しくニキビができた日", title: "場所を残して、触らず経過を見る",
        body: "顔マップに「新しくできた」で追加。洗いすぎたり、つぶしたりせず、同じ印を次の記録へ引き継ぎましょう。化粧品を一度に増やすと、何が合うか比べにくくなります。",
        productIDs: [], source: acneSource))
    result.append(
      CareProposal(
        id: "example-existing", kind: "前からあるニキビが変わらない日", title: "「前からある」で、同じ場所を追う",
        body: "新しくできたものと区別して記録。後から良くなった・悪化したに変えれば経過を追えます。長引く・繰り返す・痛みがある場合は、化粧品の追加より皮膚科への相談を。",
        productIDs: [], source: acneSource))
    if let retinal {
      result.append(
        CareProposal(
          id: "example-better", kind: "ニキビが良くなってきた日", title: "調子が良くても、急に頻度を増やさない",
          body: "今の使い方で落ち着いているなら、そのペースを続けて記録。レチナールとアゼライン酸の両方を同時に増やさず、変更は一つずつにしましょう。",
          productIDs: [retinal.id] + (azelaic.map { [$0.id] } ?? []), source: retinalSource))
    }
    if let wash {
      result.append(
        CareProposal(
          id: "example-wash", kind: "洗顔後につっぱる日", title: "洗う時間と、洗顔料を見直す",
          body: "ゴシゴシ洗いや熱いお湯を避け、やさしく洗って保湿を。つっぱりが続くなら、下の泡洗顔を置き換え候補に。今の洗顔に追加して2種類で洗う提案ではありません。",
          productIDs: [wash.id], source: acneSource))
    }
    result.append(
      CareProposal(
        id: "example-rest", kind: "疲れてケアを休んだ翌日", title: "取り戻そうと重ねず、基本のケアへ",
        body: "前日の分を増量せず、洗顔・保湿・朝のUVをいつもの量で。「一部できた」も残して、続けやすい手順を探してみましょう。",
        productIDs: [moisturizer?.id].compactMap { $0 }))
    return result
  }
}
