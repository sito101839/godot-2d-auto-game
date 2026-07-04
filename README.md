# godot-2d-auto-game

Godot 4.6 の 2D ギルド育成オートバトルプロトタイプです。

## 内容

- プレイヤーは小さな冒険者ギルドのギルドマスターです。
- ギルドメンバーを育成、編成して任務や大会に送り出します。
- 青チームと赤チームが自動で接近して攻撃します。
- 戦士、弓使い、盗賊、魔術師、神官の5種類の職業があります。
- 近い敵、低HP、高HP の3種類のターゲット方針を選択できます。
- 前衛、後衛、遊撃の3種類の隊列ロールを選択できます。
- 後衛は攻撃参加を優先しつつ、味方前衛の中心位置より前に出すぎないように動きます。
- 近距離ユニットは斬撃、遠距離ユニットは弾の攻撃エフェクトでダメージを与えます。
- 戦闘後に出撃メンバーが経験値を得て、レベルアップで能力が伸びます。
- 戦闘後にMVP、獲得経験値、与ダメージ、被ダメージ、撃破数が表示されます。
- メンバーには性格/才能があり、成長や能力に小さく影響します。
- 討伐任務、護衛任務、遺跡探索の3種類の任務があります。
- 名声に応じてギルドランクが上がり、敵や新人の質に影響します。
- 1年は4ターンで、4ターン目は大会扱いになります。
- 年度が進むと在籍年数が増え、長期的には卒業と新人加入が起きます。
- 年間成績、総戦闘数、大会勝利数を記録します。
- 3年終了時に通算成績レポートが表示されます。
- ギルド画面には「次にやること」「任務選択」「直近の結果」が分かれて表示されます。
- ギルド状況、次行動、任務選択、行動選択はスクロール外の上部エリアに固定されています。
- ギルド画面は `概要`、`編成`、`所属`、`結果` のタブで切り替えます。
- 初回表示では基本の流れを説明し、年度末や3年終了時は節目レポートを表示します。
- 任務は経験値、Gold、名声、難度を比較して選べます。
- 行動選択は主行動、育成メニュー、システム操作に分かれています。
- メンバー一覧では出撃中/控え、職業、才能、役割目安、主要能力、経験/実績を表形式で比較できます。
- 訓練や戦闘の結果は、見出しと詳細行に分けて表示されます。
- `user://guild_save.json` に保存/ロードできます。
- ギルド画面から訓練または戦闘を選び、勝敗後にギルド画面へ戻れます。

## 起動

```powershell
godot --path .
```

## 検証

```powershell
godot --headless --path . --quit
.\scripts\tools\run_quality_checks.ps1
```

個別に確認する場合:

```powershell
godot --headless --path . --script res://scripts/tools/hello_world_smoke_test.gd
godot --headless --path . --script res://scripts/tools/battle_smoke_test.gd
godot --headless --path . --script res://scripts/tools/target_selection_smoke_test.gd
godot --headless --path . --script res://scripts/tools/guild_progression_smoke_test.gd
godot --headless --path . --script res://scripts/tools/guild_year_cycle_smoke_test.gd
godot --headless --path . --script res://scripts/tools/guild_three_year_smoke_test.gd
godot --headless --path . --script res://scripts/tools/ui_state_smoke_test.gd
godot --headless --path . --script res://scripts/tools/ux_flow_smoke_test.gd
godot --headless --path . --script res://scripts/tools/beta_completion_smoke_test.gd
godot --headless --path . --script res://scripts/tools/balance_sample_smoke_test.gd
```

バランス確認を含める場合:

```powershell
.\scripts\tools\run_quality_checks.ps1 -IncludeBalance
```

プロジェクト固有の品質ルールは `.codex/rules/`、Codex向け作業手順は `.codex/skills/godot-auto-battle-quality/` にあります。
