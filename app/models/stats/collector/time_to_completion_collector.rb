module Stats
  module Collector
    class TimeToCompletionCollector < BaseCollector

      def collect
        total_seconds = 0
        transitions = todays_transitions.where(to: decision_states)
        transitions.each do |transition|
          total_seconds += calculate_submission_to_decision_time(transition)
        end
        Statistic.create_or_update(@date, 'completion_time', 'Claim::BaseClaim', average_in_days(total_seconds, transitions.size), transitions.size)
      end

      private

      def todays_transitions
        ClaimStateTransition.where(created_at: @date.beginning_of_day..@date.end_of_day)
      end

      def decision_states
        Claim::BaseClaim::CASEWORKER_DASHBOARD_COMPLETED_STATES
      end

      def calculate_submission_to_decision_time(transition)
        previous_transitions = ClaimStateTransition.where(claim_id: transition.claim_id).where{ id < transition.id }.order('created_at desc')
        submitted_transition = previous_transitions.detect{ |t| t.to.in? ['submitted', 'redetermination'] }
        transition.created_at - submitted_transition.created_at
      end

      def average_in_days(total_seconds, count)
        if count == 0
          calculate_average
        else
          float = (total_seconds / count.to_f) / SECONDS_IN_DAY
          (float * 100).to_i
        end
      end

      # if there were no claims authorised/part authorised/rejected/refused today,
      # use the average of the previous seven days
      def calculate_average
        values = Statistic.where(report_name: 'completion_time').where(date: @date - 8.days..@date - 1.day).pluck(:value_1)
        values.average
      end

    end
  end
end

