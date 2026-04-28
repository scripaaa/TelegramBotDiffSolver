require "diff_solver"
module DiffSolver
  class MessageHandler
    COMMANDS = {
      "/start"    => :handle_start,
      "/help"     => :handle_help,
      "/diff"     => :handle_diff,
      "/ndiff"    => :handle_ndiff,
    }.freeze

    def initialize(bot, message)
      @bot     = bot
      @message = message
      @chat_id = message.chat.id
    end

    def handle
      text    = @message.text.strip
      command = text.split.first.downcase

      handler = COMMANDS[command]
      if handler
        send(handler, text)
      else
        send_message("Неизвестная команда. Напиши /help чтобы увидеть список команд.")
      end
    end

    private

    def handle_start(_text)
      send_message(<<~MSG)
        👋 Привет! Я бот-дифференциатор.

        Я умею брать производные математических выражений.

        Попробуй:
        `/diff x^2 + 3*x x`
        → производная по x

        Напиши /help для полного списка команд.
      MSG
    end

    # /help
    def handle_help(_text)
      send_message(<<~MSG)
        📖 *Справка*

        *Команды:*

        `/diff <выражение> <переменная>`
        Берёт первую производную выражения по указанной переменной.
        Пример: `/diff x^3 + 2*x x`

        `/ndiff <n> <выражение> <переменная>`
        Берёт n-ю производную.
        Пример: `/ndiff 3 sin(x) x`

        *Поддерживаемые операции:*
        `+  -  *  /  ^`
        `sin(x)  cos(x)  log(x)  exp(x)`

        *Примечание:* Умножение числа на переменную можно писать как `2x` — оно автоматически преобразуется в `2*x`.
      MSG
    end

    def handle_diff(text)
      parts = text.split(" ", 2).last  
      return send_message("Использование: `/diff <выражение> <переменная>`\nПример: `/diff x^2 + 3*x x`") if parts.nil?

      tokens = parts.strip.split(" ")
      return send_message("Использование: `/diff <выражение> <переменная>`") if tokens.size < 2

      var = tokens.last
      expression = tokens[0..-2].join(" ")

      result = differentiate(expression, var)
      return unless result

      send_message("*d/d#{var}* `(#{expression})` =\n`#{result}`")
    end

    def handle_ndiff(text)
      parts = text.split(" ", 2).last
      return send_message("Использование: `/ndiff <n> <выражение> <переменная>`\nПример: `/ndiff 2 x^4 x`") if parts.nil?

      tokens = parts.strip.split(" ")
      return send_message("Использование: `/ndiff <n> <выражение> <переменная>`") if tokens.size < 3

      n_str = tokens.first
      unless n_str =~ /\A\d+\z/ && (n = n_str.to_i) >= 1
        return send_message("*n* должно быть целым числом ≥ 1.")
      end

      var = tokens.last
      expression = tokens[1..-2].join(" ")

      current = expression
      n.times do |i|
        result = differentiate(current, var, step: i + 1)
        return unless result

        current = result
      end

      send_message("*d^#{n}/d#{var}^#{n}* `(#{expression})` =\n`#{current}`")
    end

    def differentiate(expression, var, step: nil)
      expr   = Expression.new(expression)
      result = expr.derivative(var)
      Expression.unparse(result.ast)
    rescue Error => e
      step_info = step ? " (шаг #{step})" : ""
      send_message("Ошибка#{step_info}: #{e.message}")
      nil
    rescue StandardError => e
      send_message("Стандратная ошибка: #{e.message}")
      nil
    end

    def send_message(text)
      @bot.api.send_message(
        chat_id:    @chat_id,
        text:       text,
        parse_mode: "Markdown"
      )
    end
  end
end