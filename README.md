# godot-2d-auto-game

Godot 4.6 の 2D オートバトル最小プロトタイプです。

## 内容

- 青チームと赤チームが自動で接近して攻撃します。
- Warrior、Archer、Rogue の3種類のユニットを選択できます。
- Nearest、Low HP、High HP の3種類のターゲット方針を選択できます。
- 近距離ユニットは斬撃、遠距離ユニットは弾の攻撃エフェクトでダメージを与えます。
- 準備画面から戦闘を開始し、勝敗後に準備画面へ戻れます。

## 起動

```powershell
godot --path .
```

## 検証

```powershell
godot --headless --path . --quit
godot --headless --path . --script res://scripts/tools/hello_world_smoke_test.gd
godot --headless --path . --script res://scripts/tools/battle_smoke_test.gd
```
