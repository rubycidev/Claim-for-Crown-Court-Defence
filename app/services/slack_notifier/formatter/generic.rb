class SlackNotifier
  class Formatter
    class Generic < Formatter
      attr_reader :status

      def attachment(icon: nil, title: nil, message: nil, status: :pass)
        @message_icon = icon
        @status = status

        {
          fallback: message,
          color: message_colour,
          title: title,
          text: message
        }.compact
      end
    end
  end
end
