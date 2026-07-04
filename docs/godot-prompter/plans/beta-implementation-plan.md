# β版実装計画

## 目標

β版の到達目標は、**3年間のギルド運営を通して、メンバーの成長・大会結果・世代交代を体験できる育成オートバトル**にすること。

現在のプロトタイプは、1年サイクル、訓練、任務、大会、年度更新、保存/ロードまで成立している。β版ではここに「判断材料」「個性」「結果の納得感」を足し、1時間程度遊んで育成の面白さが伝わる状態を目指す。

## β版の完成条件

- 3年間プレイできる。
- 1年は4ターンで、年末に大会がある。
- 初期メンバー6人、新人加入、卒業がある。
- 職業は最低5種類ある。
- 性格/才能が最低6種類ある。
- 任務が最低3種類ある。
- ギルドランクがあり、名声で昇格する。
- 戦闘後リザルトで経験値、レベルアップ、MVPが見える。
- 年度末リザルトで年間成績と卒業/新人加入が見える。
- 3年終了リザルトで通算成績が見える。
- 保存/ロードができる。
- smoke test で3年完走が確認できる。

## β版ではまだ作らないもの

- 凝ったグラフィック。
- 大量の職業やスキル。
- 複雑な装備システム。
- 施設強化の深いツリー。
- オンライン要素。
- 完璧なゲームバランス。

## 推奨アーキテクチャ

当面は既存の `BattleScene` を活かしつつ、肥大化している `BattleManager.gd` から状態管理を段階的に分離する。

```text
BattleScene (Node2D)
├── BattleManager (Node)
│   ├── GuildState          # ギルド年数、名声、所持金、ロスター、成績
│   ├── ProgressionService  # 訓練、経験値、レベルアップ、卒業、新人加入
│   ├── MissionService      # 任務候補、報酬、敵レベル
│   └── SaveService         # JSON保存/ロード
├── Units (Node2D)
├── Effects (Node2D)
└── UI (CanvasLayer)
    ├── GuildHall
    ├── BattleHud
    └── ResultPanel
```

この分離は一度にやり切らず、機能追加で触る部分から切り出す。まずは結果表示と3年完走テストを優先する。

## 実装タスク

- [ ] **Task 1: 戦闘後リザルト強化**
  - 戦闘後に、勝敗、獲得名声、獲得Gold、出撃メンバーの経験値、レベルアップ、MVPを表示する。
  - MVPは与ダメージ、撃破数、生存などの簡易スコアから決める。
  - Skills: `godot-prompter:godot-ui`, `godot-prompter:hud-system`, `godot-prompter:godot-testing`

- [ ] **Task 2: 戦闘統計の収集**
  - `Unit` または `BattleManager` で与ダメージ、被ダメージ、撃破数、生存を集計する。
  - リザルトとMVP判定に使う。
  - Skills: `godot-prompter:component-system`, `godot-prompter:godot-testing`

- [ ] **Task 3: 性格/才能の追加**
  - メンバー生成時に性格/才能を1つ付与する。
  - 最低6種類: `努力家`, `天才肌`, `慎重`, `勝負師`, `俊足`, `虚弱`。
  - 成長率、獲得経験値、移動速度、HPなどに小さな補正を入れる。
  - Skills: `godot-prompter:resource-pattern`, `godot-prompter:component-system`, `godot-prompter:godot-testing`

- [ ] **Task 4: 任務タイプの追加**
  - 任務を最低3種類にする。
  - 例: `討伐任務` は経験値多め、`護衛任務` はGold多め、`遺跡探索` は名声多めで敵が強い。
  - ターンごとに任務を選べるようにする。
  - Skills: `godot-prompter:resource-pattern`, `godot-prompter:godot-ui`, `godot-prompter:godot-testing`

- [ ] **Task 5: ギルドランク**
  - 名声に応じて `E`, `D`, `C`, `B`, `A` に昇格する。
  - ランクで任務報酬、敵レベル、新人候補の基礎能力を変える。
  - Skills: `godot-prompter:resource-pattern`, `godot-prompter:save-load`, `godot-prompter:godot-testing`

- [ ] **Task 6: 年度末リザルト**
  - 年末大会後に年度末レポートを表示する。
  - 年間勝敗、大会結果、成長したメンバー、卒業生、新人加入をまとめる。
  - Skills: `godot-prompter:godot-ui`, `godot-prompter:hud-system`, `godot-prompter:save-load`

- [ ] **Task 7: 3年終了リザルト**
  - 3年終了時に通算レポートを表示する。
  - 通算勝敗、大会優勝数、最高Lv、MVP回数、卒業生数、最終ギルドランクを表示する。
  - その後、続行または新規開始を選べるようにする。
  - Skills: `godot-prompter:godot-ui`, `godot-prompter:hud-system`, `godot-prompter:save-load`

- [x] **Task 8: 3年完走 smoke test**
  - 訓練、任務、大会、年度更新を3年分進める自動テストを追加する。
  - 3年終了、リザルト生成、保存/ロード維持を検証する。
  - Skills: `godot-prompter:godot-testing`, `godot-dev-workflow`

- [ ] **Task 9: 状態管理の分離**
  - `BattleManager.gd` から `GuildState`、進行処理、保存処理を段階的に分ける。
  - 既存 smoke test をすべて通したまま移行する。
  - Skills: `godot-prompter:scene-organization`, `godot-prompter:component-system`, `godot-prompter:save-load`, `godot-prompter:godot-testing`

## 検証方針

各段階で最低限以下を通す。

```powershell
godot --headless --path . --quit
git diff --check
.\scripts\tools\run_quality_checks.ps1
```

β版完了時には、`guild_three_year_smoke_test.gd` で3年完走を `SMOKE_TEST_PASS guild_three_year_cycle` として確認する。戦闘バランスや敵スケールを触った場合は `.\scripts\tools\run_quality_checks.ps1 -IncludeBalance` も通す。

## 実装順の推奨

1. 戦闘統計と戦闘後リザルト。
2. 性格/才能。
3. 任務タイプ。
4. ギルドランク。
5. 年度末/3年終了リザルト。
6. 3年完走 smoke test。
7. `BattleManager.gd` の状態管理分離。

最初に着手するなら、**Task 1 と Task 2**。ここを入れると、育成結果が見えるようになり、β版の手触りが一気に良くなる。
