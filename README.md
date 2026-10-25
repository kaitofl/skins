# Skins

自分のスキンケアを、気持ちよく続けるためのコスメエージェントのインタラクティブプロトタイプです。

**公開ページ:** https://kaitofl.github.io/skins/

## できること

- 朝・夜のスキンケアを一覧で確認し、アイテムごとの使用曜日を表示
- 商品の詳細と使用頻度を確認し、コレクション表示を切り替え
- 商品をボトムシートで確認し、購入日・使い始めた日を記録
- 商品の特徴・主な成分・おすすめの目安を確認
- 肌・睡眠・ニキビ・美容施術を記録
- ラインナップに基づく相談・提案の画面を体験

現在は HTML / CSS / JavaScript の静的プロトタイプです。記録や表示設定はブラウザの `localStorage` に保存され、AI 相談はサンプル応答で動作します。

## ローカルで見る

```sh
python3 -m http.server 4175 --directory dist
```

ブラウザで `http://localhost:4175/` を開きます。

## GitHub Pages へ公開

GitHub Pages は `gh-pages` ブランチのルートを配信します。アプリを更新したら、`main` の `dist/` を公開ブランチに反映します。

```sh
git subtree push --prefix=dist origin gh-pages
```

## iOS / SwiftUI 版

iPhone向けのネイティブ実装は [`ios/`](ios/README.md) にあります。
Xcodeでは `ios/Skins.xcodeproj` を開きます。商品画像・棚・提案・月カレンダー・顔タップでの記録を実装しています。
Xcode 27.1でiPhone 16e / iOS 26.1 Simulator向けにビルド・起動し、保存と再起動後の復元まで確認済みです。実機・署名・TestFlightの確認はこれからです。
