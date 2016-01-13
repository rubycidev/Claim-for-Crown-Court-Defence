%w(
  case_types
  certification_types
  offence_classes
  offences
  fee_categories
  fee_types
  expense_types
  locations
  case_workers
  super_admins
  courts
  vat_rates
).
each do |seed|
  puts "Seeding '#{seed}'..."
  load File.join(Rails.root, 'db', 'seeds', "#{seed}.rb")
end
