require "spec_helper"
require_relative  "../../../handlers/message_handler"  
require "diff_solver"                              

RSpec.describe DiffSolver::MessageHandler do
  let(:bot) { double("bot") }
  let(:api) { double("api") }
  let(:chat_id) { 123_456 }
  let(:message) do
    double("message", chat: double("chat", id: chat_id), text: text)
  end

  before do
    allow(bot).to receive(:api).and_return(api)
    allow(api).to receive(:send_message)
  end

  subject(:handler) { described_class.new(bot, message) }

  context "when command is /start" do
    let(:text) { "/start" }

    it "sends a welcome message" do
      expect(api).to receive(:send_message).with(
        chat_id: chat_id,
        text: /Привет! Я бот-дифференциатор/,
        parse_mode: "Markdown"
      )
      handler.handle
    end
  end

  context "when command is /help" do
    let(:text) { "/help" }

    it "sends help text" do
      expect(api).to receive(:send_message).with(
        chat_id: chat_id,
        text: /Справка/,
        parse_mode: "Markdown"
      )
      handler.handle
    end
  end

  context "when command is /diff" do
    let(:text) { "/diff x^2 + 3*x x" }

    it "computes derivative and sends result" do
      expect(api).to receive(:send_message) do |args|
        expect(args[:text]).to match(/d\/dx.*`\(x\^2 \+ 3\*x\)` =\n`2 \* x \+ 3`/)
      end
      handler.handle
    end
  end

  context "when expression is invalid" do
    let(:text) { "/diff invalid!!! x" }

    it "sends error message" do
      expect(api).to receive(:send_message).with(
        chat_id: chat_id,
        text: /Ошибка: parse error/,
        parse_mode: "Markdown"
      )
      handler.handle
    end
  end

 context "when command is /ndiff" do
  let(:text) { "/ndiff 2 x^4 x" }

  it "computes second derivative" do
    expect(api).to receive(:send_message) do |args|
      expect(args[:text]).to include("d^2/dx^2").and include("12 * x^2")
    end
    handler.handle
  end
end

  context "when command is unknown" do
    let(:text) { "/unknown" }

    it "sends unknown command message" do
      expect(api).to receive(:send_message).with(
        chat_id: chat_id,
        text: /Неизвестная команда/,
        parse_mode: "Markdown"
      )
      handler.handle
    end
  end
end