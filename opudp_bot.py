#!/usr/bin/env python3
# opudp_bot.py - Telegram Bot for OP UDP Panel
import os
import subprocess
import sys
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Application, CommandHandler, CallbackQueryHandler, ContextTypes, MessageHandler, filters

BOT_TOKEN_FILE = "/etc/zivpn/telegram_token"
ADMINS_FILE = "/etc/zivpn/bot_admins.db"
PANEL_CMD = "/usr/local/bin/onepesewa"


def is_admin(chat_id):
    if not os.path.exists(ADMINS_FILE):
        return False
    try:
        with open(ADMINS_FILE) as f:
            admins = [line.strip() for line in f if line.strip()]
    except OSError:
        return False
    return str(chat_id) in admins


def run_panel(*args):
    """Run the panel with --bot-* arguments and return its stdout (plain text)."""
    try:
        result = subprocess.run(
            [PANEL_CMD, *args],
            capture_output=True, text=True, timeout=600,
        )
        out = (result.stdout or "").strip()
        if not out:
            out = (result.stderr or "").strip()
        if not out:
            out = "No output." if result.returncode == 0 else f"Command failed (code {result.returncode})."
        return out
    except FileNotFoundError:
        return f"Panel not found at {PANEL_CMD}."
    except subprocess.TimeoutExpired:
        return "Command timed out."
    except Exception as exc:  # noqa: BLE001 - surface any failure to the admin
        return f"Error: {exc}"


def menu_keyboard():
    return InlineKeyboardMarkup([
        [InlineKeyboardButton("Status", callback_data="status")],
        [InlineKeyboardButton("Add User", callback_data="adduser")],
        [InlineKeyboardButton("Remove User", callback_data="removeuser")],
        [InlineKeyboardButton("Renew User", callback_data="renew")],
        [InlineKeyboardButton("Reset Bandwidth", callback_data="resetbw")],
        [InlineKeyboardButton("User Info", callback_data="userinfo")],
        [InlineKeyboardButton("List Users", callback_data="list")],
        [InlineKeyboardButton("Cleanup Expired", callback_data="cleanup")],
        [InlineKeyboardButton("Trial User", callback_data="trial")],
        [InlineKeyboardButton("Install BBR", callback_data="bbr")],
        [InlineKeyboardButton("Install BadVPN", callback_data="badvpn")],
        [InlineKeyboardButton("Admin Management", callback_data="adminmenu")],
    ])


def admin_keyboard():
    return InlineKeyboardMarkup([
        [InlineKeyboardButton("Add Admin", callback_data="addadmin")],
        [InlineKeyboardButton("Remove Admin", callback_data="removeadmin")],
        [InlineKeyboardButton("List Admins", callback_data="listadmins")],
        [InlineKeyboardButton("Back", callback_data="menu")],
    ])


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat_id = update.effective_chat.id
    if not is_admin(chat_id):
        await update.effective_message.reply_text(
            f"Unauthorized. Your Chat ID is {chat_id}.\n"
            f"Ask the main admin to add this ID using the panel (option 5) "
            f"or the bot's Admin Management menu.\n\n"
            f"Non-admin users can use /mystatus <password> to check their account."
        )
        return
    await update.effective_message.reply_text(
        "OP UDP Panel Bot\n\nUse /menu to see commands.\n"
        "Users can check their own status with /mystatus <your_full_password>"
    )


async def get_id(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat_id = update.effective_chat.id
    await update.effective_message.reply_text(f"Your Chat ID is: {chat_id}")


async def my_status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.args:
        await update.effective_message.reply_text("Usage: /mystatus <your_full_password>")
        return
    password = " ".join(context.args)
    result = subprocess.run(
        [PANEL_CMD, "--bot-userstatus", password],
        capture_output=True, text=True,
    )
    out = (result.stdout or "").strip()
    if result.returncode != 0 or "not found" in out.lower():
        await update.effective_message.reply_text("Password not found or invalid.")
    else:
        await update.effective_message.reply_text(f"Your Account Status\n\n{out}")


async def menu(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat_id = update.effective_chat.id
    if not is_admin(chat_id):
        await update.effective_message.reply_text("Unauthorized. Use /mystatus to check your account.")
        return
    await update.effective_message.reply_text("Choose action:", reply_markup=menu_keyboard())


async def button_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    chat_id = update.effective_chat.id
    if not is_admin(chat_id):
        await query.edit_message_text("Unauthorized.")
        return
    data = query.data

    if data == "status":
        await query.edit_message_text(f"Server Status\n\n{run_panel('--bot-status')}")
    elif data == "adduser":
        context.user_data['awaiting'] = 'adduser_password'
        await query.edit_message_text("Enter the password for the new user:")
    elif data == "removeuser":
        context.user_data['awaiting'] = 'removeuser_password'
        await query.edit_message_text("Enter full password to remove:")
    elif data == "renew":
        context.user_data['awaiting'] = 'renew_password'
        await query.edit_message_text("Enter password to renew:")
    elif data == "resetbw":
        context.user_data['awaiting'] = 'resetbw_password'
        await query.edit_message_text("Enter password to reset bandwidth (or ALL):")
    elif data == "userinfo":
        context.user_data['awaiting'] = 'userinfo_password'
        await query.edit_message_text("Enter password:")
    elif data == "list":
        await query.edit_message_text(f"User List\n\n{run_panel('--bot-list')}")
    elif data == "cleanup":
        await query.edit_message_text(run_panel('--bot-cleanup'))
    elif data == "trial":
        context.user_data['awaiting'] = 'trial_minutes'
        await query.edit_message_text("Enter trial minutes (1-60):")
    elif data == "bbr":
        await query.edit_message_text(run_panel('--bot-bbr'))
    elif data == "badvpn":
        await query.edit_message_text(run_panel('--bot-badvpn'))
    elif data == "adminmenu":
        await query.edit_message_text("Admin Management:", reply_markup=admin_keyboard())
    elif data == "addadmin":
        context.user_data['awaiting'] = 'addadmin_chatid'
        await query.edit_message_text("Send the Telegram Chat ID of the new admin:")
    elif data == "removeadmin":
        context.user_data['awaiting'] = 'removeadmin_chatid'
        await query.edit_message_text("Send the Chat ID to remove:")
    elif data == "listadmins":
        if not os.path.exists(ADMINS_FILE) or not os.path.getsize(ADMINS_FILE):
            await query.edit_message_text("No admins configured.")
            return
        with open(ADMINS_FILE) as f:
            admins = f.read().strip()
        await query.edit_message_text(f"Admins\n\n{admins}")
    elif data == "menu":
        await query.edit_message_text("Choose action:", reply_markup=menu_keyboard())


async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat_id = update.effective_chat.id
    if not is_admin(chat_id):
        await update.effective_message.reply_text("Unauthorized. Use /mystatus to check your account.")
        return
    text = update.message.text.strip()
    state = context.user_data.get('awaiting')
    if not state:
        await update.effective_message.reply_text("Use /menu to start.")
        return
    if state == 'adduser_password':
        context.user_data['adduser_password'] = text
        context.user_data['awaiting'] = 'adduser_days'
        await update.effective_message.reply_text("Enter validity (days):")
    elif state == 'adduser_days':
        context.user_data['adduser_days'] = text
        context.user_data['awaiting'] = 'adduser_quota'
        await update.effective_message.reply_text("Enter quota (e.g., 10GB or 500MB):")
    elif state == 'adduser_quota':
        context.user_data['adduser_quota'] = text
        context.user_data['awaiting'] = 'adduser_hwid'
        await update.effective_message.reply_text("Enter client HWID (from ZIVPN app, or 'any'):")
    elif state == 'adduser_hwid':
        hwid = text
        password = context.user_data.get('adduser_password', '')
        days = context.user_data.get('adduser_days', '')
        quota = context.user_data.get('adduser_quota', '')
        await update.effective_message.reply_text("Creating user...")
        await update.effective_message.reply_text(run_panel('--bot-adduser', password, days, quota, hwid))
        context.user_data['awaiting'] = None
    elif state == 'removeuser_password':
        await update.effective_message.reply_text(run_panel('--bot-removeuser', text))
        context.user_data['awaiting'] = None
    elif state == 'renew_password':
        context.user_data['renew_password'] = text
        context.user_data['awaiting'] = 'renew_days'
        await update.effective_message.reply_text("Enter additional days to add:")
    elif state == 'renew_days':
        password = context.user_data.get('renew_password', '')
        await update.effective_message.reply_text(run_panel('--bot-renew', password, text))
        context.user_data['awaiting'] = None
    elif state == 'resetbw_password':
        await update.effective_message.reply_text(run_panel('--bot-resetbw', text))
        context.user_data['awaiting'] = None
    elif state == 'userinfo_password':
        await update.effective_message.reply_text(run_panel('--bot-userinfo', text))
        context.user_data['awaiting'] = None
    elif state == 'trial_minutes':
        await update.effective_message.reply_text(run_panel('--bot-trial', text))
        context.user_data['awaiting'] = None
    elif state == 'addadmin_chatid':
        chat_id_new = text.strip()
        if not chat_id_new.lstrip('-').isdigit():
            await update.effective_message.reply_text("Invalid Chat ID.")
            return
        os.makedirs(os.path.dirname(ADMINS_FILE), exist_ok=True)
        existing = []
        if os.path.exists(ADMINS_FILE):
            with open(ADMINS_FILE) as f:
                existing = [l.strip() for l in f if l.strip()]
        if chat_id_new in existing:
            await update.effective_message.reply_text(f"Admin {chat_id_new} already exists.")
        else:
            with open(ADMINS_FILE, 'a') as f:
                f.write(f"{chat_id_new}\n")
            await update.effective_message.reply_text(f"Admin {chat_id_new} added.")
        context.user_data['awaiting'] = None
    elif state == 'removeadmin_chatid':
        chat_id_rem = text.strip()
        if not os.path.exists(ADMINS_FILE):
            await update.effective_message.reply_text("No admins file.")
            context.user_data['awaiting'] = None
            return
        with open(ADMINS_FILE) as f:
            lines = f.readlines()
        with open(ADMINS_FILE, 'w') as f:
            for line in lines:
                if line.strip() != chat_id_rem:
                    f.write(line)
        await update.effective_message.reply_text(f"Admin {chat_id_rem} removed.")
        context.user_data['awaiting'] = None
    else:
        await update.effective_message.reply_text("Unknown state. Use /menu.")


def main():
    if not os.path.exists(PANEL_CMD):
        print(f"Panel not found at {PANEL_CMD}. Install the panel first.")
        sys.exit(1)
    if not os.path.exists(BOT_TOKEN_FILE):
        print("Bot token not found. Configure via panel first.")
        sys.exit(1)
    with open(BOT_TOKEN_FILE) as f:
        token = f.read().strip()
    if not token:
        print("Bot token is empty. Configure via panel first.")
        sys.exit(1)
    app = Application.builder().token(token).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("id", get_id))
    app.add_handler(CommandHandler("mystatus", my_status))
    app.add_handler(CommandHandler("menu", menu))
    app.add_handler(CallbackQueryHandler(button_callback))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    print("OP UDP Panel Bot started...")
    app.run_polling()


if __name__ == "__main__":
    main()
