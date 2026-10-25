# Skins — SwiftUI

iPhone向けのネイティブ版。iOS 17以降を対象とし、外部ライブラリへの依存はありません。
Web版と同じ14点の商品・画像を同梱しています。初回の肌プロフィールは混合肌、肌の記録は空の状態から始まります。

## 実装した画面

- **MyCosme**：朝／夜の棚、横スクロール、商品の標準シート、購入日と使用開始日、公式の商品情報、商品追加・編集・削除・使用曜日。
- **Advice**：登録した商品に応じた提案カード、対象商品の詳細、使用日の編集、公式情報へのリンク、肌プロフィールのセルフチェック。
- **Records**：日曜始まりの月カレンダー、肌状態とケア実施状況、日ごとの詳細、右下から記録。
- **記録シート**：日付、肌状態、0.5時間単位の睡眠、ケアの実施状況、顔タップでのニキビ追加・個別状態変更、前回の位置の引き継ぎ、メモ・施術。
- **バックアップ**：JSON書き出し／読み込み。Web版の `skins-demo-v1` と互換のJSONも読み込めます。読み込み前には置き換え確認を表示し、既存ファイルを保持します。

提案は登録商品の内容と公式の商品情報をもとにしたルールで生成します。外部AIサービスとの接続、クラウド同期、通知、TestFlight配布は未実装です。

## Xcodeで起動する

1. MacにXcode本体とiOS Simulatorランタイムをインストールする。
2. `ios/Skins.xcodeproj` を開く。
3. Schemeで **Skins**、実行先でiPhoneシミュレーターを選び、Runを押す。
4. 実機の場合はSigning & CapabilitiesのTeamにAppleアカウントを設定する。

Bundle Identifierは `app.kaitofl.skins`。配布前に利用するApple Developerチームに合わせて確認します。
アイコン・Launch Screen・日本語の開発言語・iPhoneの縦向き表示を設定済みです。

プロジェクトを再生成する場合：

```sh
python3 ios/scripts/generate_project.py
```

## この環境での検証

Xcode 27.1で **iPhone 16e / iOS 26.1 Simulator向けのDebugビルド・インストール・起動を確認済み**です。
棚と提案カードの表示、標準ボトムシート、肌状態・ケア・睡眠・顔タップでのニキビ状態の保存、月カレンダーへの反映、アプリ終了後の再起動でのデータ復元を確認しました。
スクリーンショットの `iphone-*-preview.png` は実際のiOS Simulator画面です。

macOS向けの同じSwiftUIソースでもビルド・動作確認しています。**実機、署名、TestFlight配布は未検証**です。
iOS 17以降を対象にしていますが、操作確認に使ったランタイムはiOS 26.1です。

```sh
swift build --package-path ios
swift run --package-path ios SkinsCoreChecks
```

SDKに付属するテストフレームワークを必要としない検証プログラムで、以下を確認します。

1. 同日の記録更新で重複しないこと
2. 不正日付・未来日・睡眠時間の検証
3. 月初の曜日配置とうるう年
4. ニキビの同じID・位置の引き継ぎと日ごとの状態の独立性
5. 保存と読み込み、および不正な書き込み時の既存ファイル保護
6. Web版のJSON・旧ニキビ記録の互換性
7. 顔のタップ範囲と商品の使用曜日

## 保存と復元

端末のApplication Support/Skins/journal.jsonに、検証済みのJSONをアトミックに保存します。
iOSではファイル保護を指定しています。読み込みに失敗した場合は元ファイルを上書きせず、復元画面を表示します。
`before-import-<UUID>.json` はインポート直前のデータです。
ブラウザのlocalStorageとiOSアプリの保存領域は共有しません。Web版の記録は自動ではコピーされません。

移行はWeb版Records画面右上のダウンロードアイコンでJSONを書き出し、ファイルをiPhoneに送り、iOS版のRecords → バックアップとデータ移行 → バックアップを読み込む、の順で行います。

## 構成

- `Sources/SkinsCore`：Codableモデル、検証、日付・月カレンダー、アトミックな保存
- `Sources/SkinsApp`：SwiftUI画面とアプリ状態
- `Sources/SkinsApp/Content`：14商品、公式情報、画像と表示範囲
- `Tests/SkinsCoreTests`：実行可能な回帰検証
- `Skins.xcodeproj`：依存ライブラリのダウンロードが不要なiOSアプリのプロジェクト
