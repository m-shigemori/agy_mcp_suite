---
name: git-push
description: Gitのコミットとプッシュを自律的に行う
---
## タスク
1. 以下のコマンドで変更内容を解析する：
   - git status
   - git diff

2. 変更を意味のある単位にグループ化する：
   - 同一目的（機能追加、バグ修正、リファクタなど）でまとめる
   - 同一モジュール内の変更は優先的にまとめる
   - 無関係な変更は必ず分離する

3. 適切にステージングする：
   - git add を使用する

4. 各グループごとにコミットを作成する

5. 安全な場合のみ push を行う

## コミットルール
接頭辞：
[ADD], [FIX], [UPD], [RM], [MV], [REN], [REF], [DOC], [TEST], [CHORE]

ルール：
- 命令形で記述する（例: Resolve, Implement, Update）
- 冠詞（a, an, the）は使用しない
- 簡潔に記述する
- 接頭辞と同じ意味の動詞は使用しない（例: "[ADD] Add ..." はNG。"[ADD] Implement ..." や "[ADD] Support ..." とする）

例：
[FIX] Resolve crash in navigation node
[ADD] Implement lidar filter
[UPD] Modify parameter handling
[REF] Clean up redundant setup conditions
[DOC] Update setup instructions in README
[TEST] Add unit tests for merge function

## グループ化ルール
- 1コミットは1つの論理的目的に限定する
- リファクタリングと機能変更は分離する
- 無関係な変更は混在させない

## 除外対象
以下のファイルやディレクトリは含めない：
- build/, install/, log/
- *.log, *.cache
- __pycache__/
