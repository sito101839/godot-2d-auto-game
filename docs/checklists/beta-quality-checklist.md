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
- [ ] 戦闘後リザルトにMVPが出る。
- [ ] 戦闘統計が記録される。
- [ ] 性格/才能がある。
- [ ] 任務タイプが3種類ある。
- [ ] ギルドランクがある。
- [ ] 年度末リザルトがある。
- [ ] 3年終了リザルトがある。

## 完了前チェック

- [ ] `godot --headless --path . --quit`
- [ ] `.\scripts\tools\run_quality_checks.ps1`
- [ ] `.\scripts\tools\run_quality_checks.ps1 -IncludeBalance`
- [ ] `git diff --check`

チェック項目は、実装と検証が両方終わったときだけ完了にする。
