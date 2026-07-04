# β品質チェックリスト

## 実装サイクル

- [x] 1年サイクル smoke test がある。
- [x] 3年完走 smoke test がある。
- [x] 保存/ロードの復元 smoke test がある。
- [x] UI状態 smoke test がある。
- [x] 任意実行のバランスサンプル smoke test がある。
- [x] 一括 smoke test runner がある。
- [x] 一括 quality check runner がある。

## β版機能

- [x] 1年4ターンで進行する。
- [x] 年末大会がある。
- [x] 年度更新がある。
- [x] 卒業と新人加入がある。
- [x] 保存/ロードがある。
- [x] 戦闘後リザルトにMVPが出る。
- [x] 戦闘統計が記録される。
- [x] 性格/才能がある。
- [x] 任務タイプが3種類ある。
- [x] ギルドランクがある。
- [x] 年度末リザルトがある。
- [x] 3年終了リザルトがある。
- [x] 状態スナップショットと保存処理が分離されている。

## 完了前チェック

- [x] `godot --headless --path . --quit`
- [x] `.\scripts\tools\run_quality_checks.ps1`
- [x] `.\scripts\tools\run_quality_checks.ps1 -IncludeBalance`
- [x] `git diff --check`

チェック項目は、実装と検証が両方終わったときだけ完了にする。
