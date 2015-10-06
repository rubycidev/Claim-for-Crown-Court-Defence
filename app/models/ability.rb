class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.nil? || user.persona.nil?

    persona = user.persona

    can [:create, :download_attachment], Message
    can [:index, :update], UserMessageStatus

    if persona.is_a? Advocate
      if persona.admin?
        can [:index, :outstanding, :authorised, :archived, :new, :create], Claim
        can [:show, :edit, :update, :confirmation, :destroy], Claim, chamber_id: persona.chamber_id
        can [:show, :download], Document, chamber_id: persona.chamber_id
        can [:destroy], Document do |document|
          if document.advocate_id.nil?
            document.creator_id == user.id
          else
            document.advocate.chamber_id == persona.chamber_id
          end
        end
        can [:index, :create], Document
        can [:index, :new, :create], Advocate
        can [:show, :change_password, :update_password, :edit, :update, :destroy], Advocate, chamber_id: persona.chamber_id
        can [:show, :create], Certification
      else
        can [:index, :outstanding, :authorised, :archived, :new, :create], Claim
        can [:show, :edit, :update, :confirmation, :destroy], Claim, advocate_id: persona.id
        can [:show, :download], Document, advocate_id: persona.id
        can [:destroy], Document do |document|
          if document.advocate_id.nil?
            document.creator_id == user.id
          else
            document.advocate_id == persona.id
          end
        end
        can [:index, :create], Document
        can [:show, :create], Certification
        can [:show, :change_password, :update_password], Advocate, id: persona.id
      end
    elsif persona.is_a? CaseWorker
      if persona.admin?
        can [:index, :show, :update, :archived], Claim
        can [:show, :download], Document
        can [:index, :new, :create], CaseWorker
        can [:show, :edit, :change_password, :update_password, :allocate, :update, :destroy], CaseWorker
        can [:new, :create], Allocation
      else
        can [:index, :show, :archived], Claim
        can [:update], Claim do |claim|
          claim.case_workers.include?(user.persona)
        end
        can [:show, :download], Document
        can [:show, :change_password, :update_password], CaseWorker, id: persona.id
      end
    end
  end
end
