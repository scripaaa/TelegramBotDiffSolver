require "dotenv/load"
require "telegram/bot"
require_relative "handlers/message_handler"

TOKEN = ENV.fetch("TELEGRAM_BOT_TOKEN") do
  abort "Ошибка: переменная окружения TELEGRAM_BOT_TOKEN не задана. Создай файл .env"
end

puts "Бот запущен. Нажми Ctrl+C для остановки."

Telegram::Bot::Client.run(TOKEN) do |bot|
  bot.listen do |message|
    next unless message.respond_to?(:text) && message.text

    DiffSolver::MessageHandler.new(bot, message).handle
  rescue StandardError => e
    puts "Ошибка при обработке сообщения: #{e.class}: #{e.message}"
  end
end