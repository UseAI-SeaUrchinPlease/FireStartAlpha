## タイル上に配置されるデータの基底クラス。今後 BlockData 以外にも
## 歩行可能な装飾物など「掘れないが移動は塞がない」種類を追加する余地を
## 持たせるため、移動を塞ぐかどうかの判定をここに切り出している (issue #7)。
class_name TileObjectData
extends Resource


func blocks_movement() -> bool:
	return true
