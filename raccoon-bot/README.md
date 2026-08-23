# Raccoon Discord Bot

Raccoon 是一個純 Node.js Discord 授權機器人原始碼專案。它不建立網站，也不把 Discord Token、GitHub 憑證或真實 Key 放進 repository。第一階段提供 Discord 內的購買兌換碼管理、私密兌換、永久專屬 Key、單設備綁定與 20 分鐘自助重置。

## 授權流程

管理員或指定版主使用 `/raccoon add-keys` 建立一次性短購買兌換碼，將短碼交給完成購買的玩家。玩家在指定的 Raccoon 面板按下 `Redeem Key`，輸入短碼後，機器人會以 Discord ephemeral 私密回覆產生一組固定 25 位、英數隨機的永久專屬長 Key。短碼兌換後立即作廢，不能再被其他玩家使用。

每組長 Key 同一時間只能綁定一台設備。已完成兌換的玩家可以按下 `Reset Device`，每次重置後等待 20 分鐘即可再次解除設備綁定，不需要管理員批准。未完成兌換的玩家不能重置，也不能取得授權資訊。腳本入口欄位已預留，但腳本內容與公開 GitHub Raw 保護屬於後續階段，尚未接入。

所有玩家輸入內容、兌換結果、長 Key 與設備狀態都使用 ephemeral 回覆，不會出現在公開頻道。公開頻道只會有兌換面板。

## Discord 設定

1. 在 Discord Developer Portal 建立自己的 Application 與 Bot。
2. 開啟 Bot 的必要權限，至少允許查看指定文字頻道、發送訊息、嵌入連結與使用斜線指令。
3. 將 Bot 邀請到你的伺服器，並記下 Application Client ID。
4. 複製 `.env.example` 為 `.env`，自行填入 `DISCORD_BOT_TOKEN` 與 `DISCORD_CLIENT_ID`。不要把 Token 貼到聊天，也不要提交 `.env`。
5. 若要讓指定版主身分組管理 Key，填入 `RACCOON_MODERATOR_ROLE_ID`。若未填，只有具有 Discord Administrator 權限的人能使用管理指令。
6. 開發時可填入 `DISCORD_GUILD_ID`，斜線指令會立即註冊到該伺服器；留空則註冊為全域指令，Discord 可能需要較久才會同步。

## 執行

```bash
cp .env.example .env
# 編輯 .env，將 XXX 換成你自己的值
pnpm install
pnpm check
pnpm test
pnpm build
pnpm start
```

資料會保存在 `DATABASE_PATH` 指定的 SQLite 檔案，預設為 `./data/raccoon.sqlite`。請把 `data/` 做持久化備份，否則刪除資料庫會遺失短碼、授權與冷卻紀錄。

## Discord 指令

| 指令 | 權限 | 用途 |
|---|---|---|
| `/raccoon setup-channel` | Administrator 或指定版主身分組 | 在目前文字頻道發布並保存 Raccoon 兌換面板 |
| `/raccoon add-keys amount:1` | Administrator 或指定版主身分組 | 私密建立 1 至 50 組短購買兌換碼 |
| `/raccoon stats` | Administrator 或指定版主身分組 | 私密查看短碼與永久授權統計 |
| `Redeem Key` | 所有玩家 | 私密輸入短購買兌換碼並取得長 Key |
| `Reset Device` | 已兌換玩家 | 每 20 分鐘私密重置一次設備綁定 |
| `My License` | 所有玩家 | 私密查看自己的授權狀態，不會顯示完整長 Key |

## 腳本授權 API

Raccoon Bot 也提供給授權腳本使用的 API：`POST /api/v1/license/validate` 接收 `longKey` 與 `deviceId`，成功時首次自動綁定設備，之後只接受同一設備；`POST /api/v1/license/reset` 依永久長 Key 執行 20 分鐘冷卻的設備重置；`GET /health` 用於 Railway 健康檢查。API 只接受由已兌換短碼產生的長 Key，原本 Lua 檔案內嵌的舊 Key 全部失效。正式接入腳本前，應在客戶端避免記錄或公開完整 Key，並透過 Railway 的 HTTPS 網址呼叫 API。

## 部署

GitHub 只用來保存與管理原始碼，不能讓機器人持續在線。請將此專案部署到能持續運行 Node.js 程序的主機，例如自己的電腦、VPS 或其他 Node.js 主機；主機必須持續連線，並持久化 `DATABASE_PATH` 指向的資料夾。使用 systemd、PM2 或平台提供的自動重啟功能，可讓 Bot 在程序中斷後自動恢復。

部署時請在主機的環境設定中填入 Token，而不是寫入 TypeScript 或 GitHub。程式啟動時若仍偵測到 `XXX`，會直接停止並提示需要填入的環境變數。

## 安全邊界

此專案只處理授權與設備綁定，不包含 Roblox 作弊、繞過反作弊、盜取帳號或繞過第三方授權的功能。設備識別值在資料層只應以雜湊形式保存；未來接入腳本時，應讓腳本只提交授權請求，不要把 Bot Token 或資料庫憑證放進腳本。
