import {
  ActionRowBuilder,
  ButtonBuilder,
  ButtonStyle,
  ChannelType,
  Client,
  EmbedBuilder,
  Events,
  GatewayIntentBits,
  Interaction,
  ModalBuilder,
  PermissionFlagsBits,
  REST,
  Routes,
  TextInputBuilder,
  TextInputStyle,
} from "discord.js";
import express from "express";
import { config } from "./config.js";
import { LicenseDatabase } from "./database.js";
import { hasRaccoonStaffAccess } from "./permissions.js";

const db = new LicenseDatabase(config.databasePath);
const client = new Client({ intents: [GatewayIntentBits.Guilds] });
const api = express();
api.use(express.json({ limit: "8kb" }));
api.get("/health", (_request, response) => response.json({ ok: true, service: "raccoon-discord-bot" }));
api.post("/api/v1/license/validate", (request, response) => {
  const { longKey, deviceId } = request.body as { longKey?: unknown; deviceId?: unknown };
  if (typeof longKey !== "string" || typeof deviceId !== "string") return response.status(400).json({ ok: false, reason: "invalid-request" });
  const result = db.validateLongKeyDevice(longKey, deviceId);
  return result.ok ? response.json(result) : response.status(403).json(result);
});
api.post("/api/v1/license/reset", (request, response) => {
  const { longKey } = request.body as { longKey?: unknown };
  if (typeof longKey !== "string") return response.status(400).json({ ok: false, reason: "invalid-request" });
  const result = db.resetDeviceWithLongKey(longKey);
  return result.ok ? response.json(result) : response.status(403).json(result);
});
const apiPort = Number(process.env.PORT ?? 3000);
api.listen(apiPort, "0.0.0.0", () => console.log(`Raccoon license API listening on port ${apiPort}`));

const commandData = [
  {
    name: "raccoon",
    description: "Raccoon 授權與兌換管理",
    options: [
      { name: "setup-channel", description: "在目前頻道發布永久兌換面板", type: 1 },
      { name: "add-keys", description: "新增一次性短購買兌換碼", type: 1, options: [{ name: "amount", description: "新增數量（1 至 50）", type: 4, required: false, min_value: 1, max_value: 50 }] },
      { name: "stats", description: "查看授權統計", type: 1 },
    ],
  },
];

function isStaff(interaction: Interaction): boolean {
  if (!interaction.isChatInputCommand() || !interaction.inGuild()) return false;
  if (interaction.memberPermissions?.has(PermissionFlagsBits.Administrator)) return true;
  if (!config.moderatorRoleId) return false;
  const member = interaction.member;
  const roleIds = Array.isArray(member.roles) ? member.roles : [...member.roles.cache.keys()];
  return hasRaccoonStaffAccess({
    isAdministrator: Boolean(interaction.memberPermissions?.has(PermissionFlagsBits.Administrator)),
    roleIds,
    moderatorRoleId: config.moderatorRoleId,
  });
}

function isConfiguredChannel(interaction: Interaction): boolean {
  if (!interaction.inGuild()) return false;
  return db.getRedemptionChannel(interaction.guildId)?.channelId === interaction.channelId;
}

function panelEmbed(): EmbedBuilder {
  return new EmbedBuilder()
    .setColor(0xd72638)
    .setTitle("RACCOON / LICENSE HUB")
    .setDescription("輸入你購買後取得的短兌換碼。兌換成功後，系統會私密提供你的永久專屬 Key。\n\n每個專屬 Key 同時只能綁定一台設備；已授權玩家每 20 分鐘可以自行重置設備。")
    .addFields(
      { name: "REDEEM", value: "輸入一次性購買碼，取得個人授權。", inline: true },
      { name: "RESET DEVICE", value: "授權玩家每 20 分鐘可重置一次。", inline: true },
    )
    .setFooter({ text: "Raccoon License System · Private responses only" });
}

function panelComponents(): ActionRowBuilder<ButtonBuilder>[] {
  return [new ActionRowBuilder<ButtonBuilder>().addComponents(
    new ButtonBuilder().setCustomId("raccoon_redeem").setLabel("Redeem Key").setStyle(ButtonStyle.Success),
    new ButtonBuilder().setCustomId("raccoon_reset").setLabel("Reset Device").setStyle(ButtonStyle.Secondary),
    new ButtonBuilder().setCustomId("raccoon_status").setLabel("My License").setStyle(ButtonStyle.Secondary),
    new ButtonBuilder().setCustomId("raccoon_bind").setLabel("Bind Device").setStyle(ButtonStyle.Secondary),
  )];
}

function bindDeviceModal(): ModalBuilder {
  return new ModalBuilder().setCustomId("raccoon_bind_modal").setTitle("Raccoon / Bind Device").addComponents(
    new ActionRowBuilder<TextInputBuilder>().addComponents(
      new TextInputBuilder().setCustomId("long_key").setLabel("你的 25 位永久專屬 Key").setPlaceholder("輸入你私密取得的長 Key").setStyle(TextInputStyle.Short).setMinLength(25).setMaxLength(25).setRequired(true),
    ),
    new ActionRowBuilder<TextInputBuilder>().addComponents(
      new TextInputBuilder().setCustomId("device_id").setLabel("設備識別值").setPlaceholder("由你的授權腳本產生的設備識別值").setStyle(TextInputStyle.Short).setMinLength(1).setMaxLength(256).setRequired(true),
    ),
  );
}

function redeemModal(): ModalBuilder {
  return new ModalBuilder().setCustomId("raccoon_redeem_modal").setTitle("Raccoon / Redeem Purchase Code").addComponents(
    new ActionRowBuilder<TextInputBuilder>().addComponents(
      new TextInputBuilder().setCustomId("purchase_code").setLabel("購買兌換碼").setPlaceholder("例如：2C39dZC").setStyle(TextInputStyle.Short).setMinLength(4).setMaxLength(64).setRequired(true),
    ),
  );
}

async function registerCommands(): Promise<void> {
  const rest = new REST({ version: "10" }).setToken(config.token);
  const route = config.guildId ? Routes.applicationGuildCommands(config.clientId, config.guildId) : Routes.applicationCommands(config.clientId);
  await rest.put(route, { body: commandData });
}

async function handleChatCommand(interaction: Extract<Interaction, { isChatInputCommand(): boolean }>): Promise<void> {
  if (!interaction.isChatInputCommand() || !interaction.inGuild()) return;
  const subcommand = interaction.options.getSubcommand();
  if (!isStaff(interaction)) {
    await interaction.reply({ content: "你沒有使用這項管理功能的權限。", ephemeral: true });
    return;
  }

  if (subcommand === "setup-channel") {
    if (!interaction.channel || interaction.channel.type !== ChannelType.GuildText) {
      await interaction.reply({ content: "請在一般文字頻道執行這個指令。", ephemeral: true });
      return;
    }
    const previous = db.getRedemptionChannel(interaction.guildId);
    if (previous?.messageId && previous.channelId !== interaction.channelId) {
      try {
        const oldChannel = await interaction.guild?.channels.fetch(previous.channelId);
        if (oldChannel?.isTextBased()) {
          const oldMessage = await oldChannel.messages.fetch(previous.messageId);
          await oldMessage.delete();
        }
      } catch (error) {
        console.warn("Could not remove previous Raccoon panel", error);
      }
    }
    const message = await interaction.channel.send({ embeds: [panelEmbed()], components: panelComponents() });
    db.setRedemptionChannel(interaction.guildId, interaction.channelId, message.id);
    await interaction.reply({ content: `Raccoon 兌換面板已設定在 <#${interaction.channelId}>，面板訊息已永久保存。`, ephemeral: true });
    return;
  }

  if (subcommand === "add-keys") {
    const amount = interaction.options.getInteger("amount") ?? 1;
    const codes = db.createPurchaseCodes(amount, interaction.user.id);
    await interaction.reply({ content: `已建立 ${codes.length} 組一次性短購買兌換碼（僅你可見）：\n\n${codes.map(code => `\`${code}\``).join("\n")}`, ephemeral: true });
    return;
  }

  if (subcommand === "stats") {
    const stats = db.getStats();
    await interaction.reply({ content: `Raccoon 統計（僅你可見）\n未／已建立短碼總數：${stats.purchaseCodes}\n已兌換短碼：${stats.redeemedCodes}\n永久授權玩家：${stats.licenses}`, ephemeral: true });
  }
}

async function handleInteraction(interaction: Interaction): Promise<void> {
  if (interaction.isChatInputCommand()) {
    await handleChatCommand(interaction);
    return;
  }
  if (interaction.isButton()) {
    if (interaction.inGuild() && !isConfiguredChannel(interaction)) {
      await interaction.reply({ content: "這個兌換面板已停用，請使用目前指定頻道的面板。", ephemeral: true });
      return;
    }
    if (interaction.customId === "raccoon_bind") {
      await interaction.showModal(bindDeviceModal());
      return;
    }
    if (interaction.customId === "raccoon_redeem") {
      await interaction.showModal(redeemModal());
      return;
    }
    if (interaction.customId === "raccoon_reset") {
      const result = db.resetDevice(interaction.user.id);
      if (!result.ok) {
        const content = result.reason === "not-licensed" ? "你尚未兌換有效 Key，不能重置設備。" : `尚未到重置時間，請在 <t:${Math.floor((result.nextResetAt ?? Date.now()) / 1000)}:R> 後再試。`;
        await interaction.reply({ content, ephemeral: true });
      } else {
        await interaction.reply({ content: "設備已重置成功。你現在可以在另一台設備使用專屬 Key 進行綁定。下次可重置時間：" + `<t:${Math.floor(result.nextResetAt / 1000)}:R>`, ephemeral: true });
      }
      return;
    }
    if (interaction.customId === "raccoon_status") {
      const license = db.getLicense(interaction.user.id);
      await interaction.reply({ content: license ? `你已擁有永久 Raccoon 授權。專屬 Key 尾碼：\`****${license.longKeyLast4}\`\n設備狀態：${license.deviceHash ? "已綁定" : "等待設備綁定"}` : "你目前沒有有效授權。", ephemeral: true });
    }
    return;
  }
  if (interaction.isModalSubmit() && interaction.customId === "raccoon_bind_modal") {
    if (interaction.inGuild() && !isConfiguredChannel(interaction)) {
      await interaction.reply({ content: "這個兌換面板已停用，請使用目前指定頻道的面板。", ephemeral: true });
      return;
    }
    const longKey = interaction.fields.getTextInputValue("long_key").trim();
    const deviceId = interaction.fields.getTextInputValue("device_id").trim();
    const result = db.bindDeviceWithLongKey(interaction.user.id, longKey, deviceId);
    if (!result.ok) {
      const messages = { "not-licensed": "你尚未兌換永久授權。", "invalid-key": "專屬 Key 不正確。", "different-device": "這組授權目前已綁定其他設備，請先使用 Reset Device。", "invalid-device": "設備識別值格式不正確。" } as const;
      await interaction.reply({ content: messages[result.reason], ephemeral: true });
      return;
    }
    await interaction.reply({ content: "設備綁定成功。這組永久專屬 Key 現在只能在此設備使用。", ephemeral: true });
    return;
  }
  if (interaction.isModalSubmit() && interaction.customId === "raccoon_redeem_modal") {
    const code = interaction.fields.getTextInputValue("purchase_code").trim();
    const result = db.redeemPurchaseCode(code, interaction.user.id);
    if (!result.ok) {
      const messages = { invalid: "購買兌換碼無效。", "already-redeemed": "這組購買兌換碼已經被兌換。", "already-licensed": "你已經擁有永久授權。" } as const;
      await interaction.reply({ content: messages[result.reason], ephemeral: true });
      return;
    }
    await interaction.reply({ content: `兌換成功。這是你的永久專屬 Key（只對你顯示）：\n\n\`${result.longKey}\`\n\n請妥善保存。這組 Key 同時只能綁定一台設備；設備重置功能每 20 分鐘可使用一次。`, ephemeral: true });
  }
}

client.once(Events.ClientReady, async readyClient => {
  await registerCommands();
  console.log(`Raccoon bot ready as ${readyClient.user.tag}`);
});

client.on(Events.InteractionCreate, interaction => {
  void handleInteraction(interaction).catch(async error => {
    console.error("Interaction error", error);
    if (interaction.isRepliable() && !interaction.replied && !interaction.deferred) await interaction.reply({ content: "系統發生錯誤，請稍後再試。", ephemeral: true });
  });
});

process.once("SIGINT", () => { db.close(); client.destroy(); process.exit(0); });
process.once("SIGTERM", () => { db.close(); client.destroy(); process.exit(0); });

void client.login(config.token);
