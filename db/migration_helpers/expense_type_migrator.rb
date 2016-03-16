module MigrationHelpers
  class ExpenseTypeMigrator

    def initialize
      @car = ExpenseType.find_by(name: 'Car travel')
      @train = ExpenseType.find_by(name: 'Train/public transport')
      @parking = ExpenseType.find_by(name: 'Parking')
      @hotel = ExpenseType.find_by(name: 'Hotel accommodation')
      raise "No such expense type: Car travel" if @car.nil?
      raise "No such expense type: Train/public transport" if @train.nil?
      raise "No such expense type: Parking" if @parking.nil?
      raise "No such expense type: Hotel accommodation" if @hotel.nil?
    end

    def run
      expenses = Expense.all
      expenses.each { |ex| migrate_expense(ex) }
    end

  private
    def migrate_expense(ex)
      case ex.expense_type.name.upcase
      when 'CONFERENCE AND VIEW - CAR'
        update_expense(ex, @car)
      
      when 'CONFERENCE AND VIEW - HOTEL STAY'
        update_expense(ex, @hotel)
      
      when 'CONFERENCE AND VIEW - TRAIN'
        update_expense(ex, @train)
      
      when 'CONFERENCE AND VIEW - TRAVEL TIME'
        update_expense(ex, @train)
      
      when 'TRAVEL AND HOTEL - CAR'
        update_expense(ex, @car)
      
      when 'TRAVEL AND HOTEL - CONFERENCE AND VIEW'
        update_expense(ex, @hotel)
      
      when 'TRAVEL AND HOTEL - HOTEL STAY'
        update_expense(ex, @hotel)
      
      when 'TRAVEL AND HOTEL - TRAIN'
        update_expense(ex, @train)
      else
        raise RuntimeError, "Unrecognised expense type name: '#{ex.expense_type.name}'"
      end
      ex.save!
    end

    def update_expense(ex, expense_type)
      original_expense_type_name = ex.expense_type.name
      ex.expense_type = expense_type
      ex.reason_id = 5
      narrative = extract_and_update_date_info(ex)
      ex.reason_text = "Other: Originally #{original_expense_type_name}  #{narrative}".strip
    end

    def extract_and_update_date_info(ex)
      date, narrative = extract_date_and_narrative_from_dates(ex)
      ex.date = date
      narrative
    end

    def extract_date_and_narrative_from_dates(ex)
      return [nil, "no date specified"] if ex.dates_attended.empty?
      if is_single_date?(ex.dates_attended)
        date = ex.dates_attended.first.date
        narrative = ""
      else
        date = ex.dates_attended.first.date
        narrative = extract_date_ranges_as_text(ex)
      end
      [date, narrative]
    end

    def is_single_date?(dates_attended)
      dates_attended.size == 1 && refers_to_one_date?(dates_attended.first)
    end

    def refers_to_one_date?(date_attended)
      date_attended.date_to.nil? || date_attended.date == date_attended.date_to
    end

    def extract_date_ranges_as_text(ex)
      ex.dates_attended.map(&:to_s).join(", ")
    end


  end
end
