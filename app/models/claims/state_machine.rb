module Claims
  module StateMachine
    ARCHIVE_VALIDITY  = 180.days
    STANDARD_VALIDITY = 21.days

    EXTERNAL_USER_DASHBOARD_DRAFT_STATES            = %w[draft].freeze
    EXTERNAL_USER_DASHBOARD_REJECTED_STATES         = %w[rejected].freeze
    EXTERNAL_USER_DASHBOARD_SUBMITTED_STATES        = %w[allocated submitted].freeze
    EXTERNAL_USER_DASHBOARD_PART_AUTHORISED_STATES  = %w[part_authorised].freeze
    EXTERNAL_USER_DASHBOARD_COMPLETED_STATES        = %w[refused authorised].freeze
    CASEWORKER_DASHBOARD_COMPLETED_STATES           = %w[authorised part_authorised rejected refused].freeze
    CASEWORKER_DASHBOARD_UNDER_ASSESSMENT_STATES    = %w[allocated].freeze
    CASEWORKER_DASHBOARD_UNALLOCATED_STATES         = %w[submitted redetermination awaiting_written_reasons].freeze
    CASEWORKER_DASHBOARD_ARCHIVED_STATES            = %w[ authorised part_authorised rejected
                                                          refused archived_pending_delete
                                                          archived_pending_review].freeze
    VALID_STATES_FOR_REDETERMINATION                = %w[authorised part_authorised refused rejected].freeze
    VALID_STATES_FOR_ARCHIVAL                       = %w[authorised part_authorised refused rejected].freeze
    VALID_STATES_FOR_ALLOCATION                     = %w[submitted redetermination awaiting_written_reasons].freeze
    VALID_STATES_FOR_DEALLOCATION                   = %w[allocated].freeze
    NON_DRAFT_STATES                                = %w[allocated authorised part_authorised refused rejected
                                                         submitted awaiting_written_reasons redetermination
                                                         archived_pending_delete archived_pending_review].freeze
    NON_VALIDATION_STATES                           = %w[allocated archived_pending_delete archived_pending_review
                                                         authorised awaiting_written_reasons deallocated
                                                         part_authorised redetermination refused rejected].freeze
    AUTHORISED_STATES                               = EXTERNAL_USER_DASHBOARD_PART_AUTHORISED_STATES +
                                                      EXTERNAL_USER_DASHBOARD_COMPLETED_STATES
    PREVIOUSLY_AUTHORISED_STATES                    = %w[authorised part_authorised].freeze

    def self.dashboard_displayable_states
      (
        EXTERNAL_USER_DASHBOARD_DRAFT_STATES +
        EXTERNAL_USER_DASHBOARD_REJECTED_STATES +
        EXTERNAL_USER_DASHBOARD_SUBMITTED_STATES +
        CASEWORKER_DASHBOARD_UNALLOCATED_STATES +
        EXTERNAL_USER_DASHBOARD_PART_AUTHORISED_STATES +
        EXTERNAL_USER_DASHBOARD_COMPLETED_STATES
      ).uniq
    end

    # will return true if there is a constant defined in this class with the same name
    # in upper case as method with the trailing question mark removed
    def self.can_be_in_state?(method)
      return false unless method.to_s.end_with?('?')
      const_defined?("#{method.to_s.chop.upcase}_STATES")
    end

    def self.in_state?(method, claim)
      konstant_name = "Claims::StateMachine::#{method.to_s.chop.upcase}_STATES".constantize
      konstant_name.include?(claim.state)
    rescue NameError
      false
    end

    def self.included(klass)
      klass.state_machine :state, initial: :draft do
        audit_trail class: ClaimStateTransition, context: %i[reason_code reason_text author_id subject_id]

        state :allocated,
              :archived_pending_delete,
              :archived_pending_review,
              :awaiting_written_reasons,
              :draft,
              :authorised,
              :part_authorised,
              :refused,
              :rejected,
              :redetermination,
              :submitted,
              :deallocated

        after_transition on: :submit,                   do: %i[set_last_submission_date! set_original_submission_date!]
        after_transition on: :authorise,                do: [:set_authorised_date!]
        after_transition on: :authorise_part,           do: [:set_authorised_date!]
        after_transition on: :redetermine,              do: %i[remove_case_workers! set_last_submission_date!]
        after_transition on: :await_written_reasons,    do: %i[remove_case_workers! set_last_submission_date!]
        after_transition on: :archive_pending_delete,   do: :valid_until!
        after_transition on: :deallocate,               do: %i[remove_case_workers! reset_state]
        before_transition on: :submit,                  do: :set_allocation_type
        before_transition on: %i[reject refuse], do: :set_amount_assessed_zero!

        around_transition any => NON_VALIDATION_STATES.map(&:to_sym) do |claim, transition, block|
          validation_state = %i[authorise authorise_part].include?(transition.event) ? :only_amount_assessed : :all
          claim.disable_for_state_transition = validation_state
          block.call
          claim.disable_for_state_transition = nil
        end

        event :redetermine do
          transition VALID_STATES_FOR_REDETERMINATION.map(&:to_sym) => :redetermination
        end

        event :await_written_reasons do
          transition VALID_STATES_FOR_REDETERMINATION.map(&:to_sym) => :awaiting_written_reasons
        end

        event :submit do
          transition %i[draft allocated] => :submitted
        end

        event :allocate do
          transition VALID_STATES_FOR_ALLOCATION.map(&:to_sym) => :allocated
        end

        event :deallocate do
          transition VALID_STATES_FOR_DEALLOCATION.map(&:to_sym) => :deallocated
        end

        event :archive_pending_delete do
          transition VALID_STATES_FOR_ARCHIVAL.map(&:to_sym) => :archived_pending_delete, unless: :hardship?
          transition archived_pending_review: :archived_pending_delete, if: :hardship?
        end

        event :archive_pending_review do
          transition VALID_STATES_FOR_ARCHIVAL.map(&:to_sym) => :archived_pending_review, if: :hardship?
        end

        event :authorise_part do
          transition %i[allocated awaiting_written_reasons] => :part_authorised
        end

        event :authorise do
          transition %i[allocated awaiting_written_reasons] => :authorised
        end

        event :refuse do
          transition %i[allocated awaiting_written_reasons] => :refused
        end

        event :reject do
          transition %i[allocated awaiting_written_reasons] => :rejected, :if => :rejectable?
        end

        event :transition_clone_to_draft do
          transition [:rejected] => :draft
        end
      end

      klass.state_machine.states.map(&:name).each do |s|
        klass.scope s, -> { where(state: s) }
      end

      klass.scope :non_archived_pending_delete, -> { where.not(state: :archived_pending_delete) }
      klass.scope :non_draft, -> { where(state: NON_DRAFT_STATES) }
      klass.scope :submitted_or_redetermination_or_awaiting_written_reasons, lambda {
        where(state: CASEWORKER_DASHBOARD_UNALLOCATED_STATES)
      }
      klass.scope :external_user_dashboard_draft, -> { where(state: EXTERNAL_USER_DASHBOARD_DRAFT_STATES) }
      klass.scope :external_user_dashboard_rejected, -> { where(state: EXTERNAL_USER_DASHBOARD_REJECTED_STATES) }
      klass.scope :external_user_dashboard_submitted, lambda {
        where(state: EXTERNAL_USER_DASHBOARD_SUBMITTED_STATES)
      }
      klass.scope :external_user_dashboard_part_authorised, lambda {
        where(state: EXTERNAL_USER_DASHBOARD_PART_AUTHORISED_STATES)
      }
      klass.scope :external_user_dashboard_completed, lambda {
        where(state: EXTERNAL_USER_DASHBOARD_COMPLETED_STATES)
      }
      klass.scope :caseworker_dashboard_completed, -> { where(state: CASEWORKER_DASHBOARD_COMPLETED_STATES) }
      klass.scope :caseworker_dashboard_under_assessment, lambda {
        where(state: CASEWORKER_DASHBOARD_UNDER_ASSESSMENT_STATES)
      }
      klass.scope :caseworker_dashboard_archived, -> { where(state: CASEWORKER_DASHBOARD_ARCHIVED_STATES) }
    end

    def last_decision_transition
      claim_state_transitions.detect { |t| t.to.in?(CASEWORKER_DASHBOARD_COMPLETED_STATES) }
    end

    def last_state_transition
      claim_state_transitions.unscope(:order).order(created_at: :desc, id: :desc).first
    end

    def last_state_transition_reason
      last_state_transition&.reason
    end

    def last_state_transition_time
      last_state_transition&.created_at
    end

    def last_redetermination
      redeterminations.reverse.find(&:valid?)
    end

    def filtered_state_transitions
      claim_state_transitions.where.not(to: %w[allocated deallocated])
    end

    def filtered_last_state_transition
      filtered_state_transitions.first
    end

    private

    def reason_code(transition)
      extract_transition_option!(transition, :reason_code)
    end

    def reason_text(transition)
      extract_transition_option!(transition, :reason_text)
    end

    def author_id(transition)
      extract_transition_option!(transition, :author_id)
    end

    def subject_id(transition)
      extract_transition_option!(transition, :subject_id)
    end

    def extract_transition_option!(transition, option, default = nil)
      args = transition.args
      args&.last.is_a?(Hash) ? args.last.delete(option) { default } : default
    end

    def reset_state
      update(state: state_at_last_submission)
    end

    def state_at_last_submission
      claim_state_transitions.find { |transition| CASEWORKER_DASHBOARD_UNALLOCATED_STATES.include?(transition.to) }.to
    end

    def set_original_submission_date!
      update(original_submission_date: Time.zone.now)
    end

    def set_last_submission_date!
      update(last_submitted_at: Time.zone.now)
    end

    def set_authorised_date!
      update(authorised_at: Time.zone.now)
    end

    def valid_until!(transition)
      validity = transition.to == 'archived_pending_delete' ? ARCHIVE_VALIDITY : STANDARD_VALIDITY
      update(valid_until: Time.zone.now + validity)
    end

    def set_amount_assessed_zero!
      return if previously_authorised?
      assessment.zeroize! if state == 'allocated'
    end

    def previously_authorised?
      claim_state_transitions.map(&:to).any? { |state| PREVIOUSLY_AUTHORISED_STATES.include?(state) }
    end

    def remove_case_workers!
      case_workers.destroy_all
    end
  end
end
