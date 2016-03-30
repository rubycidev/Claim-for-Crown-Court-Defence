

def create_or_update_by_name  (options)
  ct = CaseType.find_by_name(options[:name])
  if ct.nil?
    ct = CaseType.create!(options)
  else
    ct.update(options)
  end
  ct
end

create_or_update_by_name(name: 'Appeal against conviction',
                            is_fixed_fee:             true,
                            requires_cracked_dates:   false,
                            requires_trial_dates:     false,
                            requires_retrial_dates:   false,
                            allow_pcmh_fee_type:      false,
                            requires_maat_reference:  true,
                            roles:                    ['agfs', 'lgfs'],
                            )
create_or_update_by_name(name: 'Appeal against sentence',
                            is_fixed_fee:             true,
                            requires_cracked_dates:   false,
                            requires_trial_dates:     false,
                            requires_retrial_dates:   false,
                            allow_pcmh_fee_type:      false,
                 
                            roles:                    ['agfs', 'lgfs'],
                            )
create_or_update_by_name(name: 'Breach of Crown Court order',
                            is_fixed_fee:             true,
                            requires_cracked_dates:   false,
                            requires_trial_dates:     false,
                            requires_retrial_dates:   false,
                            allow_pcmh_fee_type:      false,
                            requires_maat_reference:  false,
                            roles:                    ['agfs', 'lgfs'],
                            )
create_or_update_by_name(name: 'Committal for Sentence',
                            is_fixed_fee:             true,
                            requires_cracked_dates:   false,
                            requires_trial_dates:     false,
                            requires_retrial_dates:   false,
                            allow_pcmh_fee_type:      false,
                            requires_maat_reference:  true,
                            roles:                    ['agfs', 'lgfs'],
                            )
create_or_update_by_name(name: 'Contempt',
                            is_fixed_fee:             true,
                            requires_cracked_dates:   false,
                            requires_trial_dates:     false,
                            requires_retrial_dates:   false,
                            allow_pcmh_fee_type:      false,
                            requires_maat_reference:  true,
                            roles:                    ['agfs', 'lgfs'],
                            )
create_or_update_by_name(name: 'Cracked Trial',
                            is_fixed_fee:             false,
                            requires_cracked_dates:   true,
                            requires_trial_dates:     false,
                            requires_retrial_dates:   false,
                            allow_pcmh_fee_type:      true,
                            requires_maat_reference:  true,
                            roles:                    ['agfs', 'lgfs'],
                            grad_fee_code:            'GCRAK',
                            )
create_or_update_by_name(name: 'Cracked before retrial',
                            is_fixed_fee:             false,
                            requires_cracked_dates:   true,
                            requires_trial_dates:     false,
                            requires_retrial_dates:   false,
                            allow_pcmh_fee_type:      true,
                            requires_maat_reference:  true,
                            roles:                    ['agfs', 'lgfs'],
                            grad_fee_code:            'GCBR',
                            )
create_or_update_by_name(name: 'Discontinuance',
                            is_fixed_fee:             false,
                            requires_cracked_dates:   false,
                            requires_trial_dates:     false,
                            requires_retrial_dates:   false,
                            allow_pcmh_fee_type:      true,
                            requires_maat_reference:  true,
                            roles:                    ['agfs', 'lgfs'],
                            grad_fee_code:            'GDIS',
                            )
create_or_update_by_name(name: 'Elected cases not proceeded',
                            is_fixed_fee:             true,
                            requires_cracked_dates:   false,
                            requires_trial_dates:     false,
                            requires_retrial_dates:   false,
                            allow_pcmh_fee_type:      false,
                            requires_maat_reference:  true,
                            roles:                    ['agfs', 'lgfs'],
                            )
create_or_update_by_name(name: 'Guilty plea',
                            is_fixed_fee:             false,
                            requires_cracked_dates:   false,
                            requires_trial_dates:     false,
                            requires_retrial_dates:   false,
                            allow_pcmh_fee_type:      true,
                            requires_maat_reference:  true,
                            roles:                    ['agfs', 'lgfs'],
                            grad_fee_code:            'GGLTY',
                            )
create_or_update_by_name(name: 'Retrial',
                            is_fixed_fee:             false,
                            requires_cracked_dates:   false,
                            requires_trial_dates:     true,
                            requires_retrial_dates:   true,
                            allow_pcmh_fee_type:      true,
                            requires_maat_reference:  true,
                            roles:                    ['agfs', 'lgfs'],
                            grad_fee_code:            'GRTR',
                            )
create_or_update_by_name(name: 'Trial',
                            is_fixed_fee:             false,
                            requires_cracked_dates:   false,
                            requires_trial_dates:     true,
                            requires_retrial_dates:   false,
                            allow_pcmh_fee_type:      true,
                            requires_maat_reference:  true,
                            roles:                    ['agfs', 'lgfs'],
                            grad_fee_code:            'GTRL',
                            )

parent = create_or_update_by_name(name: 'Hearing subsequent to sentence',
                            is_fixed_fee:             true,
                            requires_cracked_dates:   false,
                            requires_trial_dates:     false,
                            requires_retrial_dates:   false,
                            allow_pcmh_fee_type:      false,
                            requires_maat_reference:  true,
                            roles:                    ['lgfs'],
                            )

create_or_update_by_name(name: 'Transfer',
                            is_fixed_fee:             false,
                            requires_cracked_dates:   false,
                            requires_trial_dates:     false,
                            requires_retrial_dates:   false,
                            allow_pcmh_fee_type:      false,
                            requires_maat_reference:  true,
                            roles:                    ['lgfs'],
                            )

create_or_update_by_name(name: 'Warrant claim',
                            is_fixed_fee:             false,
                            requires_cracked_dates:   false,
                            requires_trial_dates:     false,
                            requires_retrial_dates:   false,
                            allow_pcmh_fee_type:      false,
                            requires_maat_reference:  true,
                            roles:                    ['lgfs'],
                            )

create_or_update_by_name(name: 'Vary/discharge an ASBO s1c Crime and Disorder Act 1998',
                            is_fixed_fee:             false,
                            requires_cracked_dates:   false,
                            requires_trial_dates:     false,
                            requires_retrial_dates:   false,
                            allow_pcmh_fee_type:      false,
                            requires_maat_reference:  true,
                            roles:                    ['lgfs'],
                            parent:                   parent
                            )

create_or_update_by_name(name: 'Alteration of Crown Court sentence s155 Powers of Criminal Courts (Sentencing Act 2000)',
                            is_fixed_fee:             false,
                            requires_cracked_dates:   false,
                            requires_trial_dates:     false,
                            requires_retrial_dates:   false,
                            allow_pcmh_fee_type:      false,
                            requires_maat_reference:  true,
                            roles:                    ['lgfs'],
                            parent:                   parent
                            )
create_or_update_by_name(name: 'Assistance by defendant: review of sentence s74 Serious Organised Crime and Police Act 2005',
                            is_fixed_fee:             false,
                            requires_cracked_dates:   false,
                            requires_trial_dates:     false,
                            requires_retrial_dates:   false,
                            allow_pcmh_fee_type:      false,
                            requires_maat_reference:  true,
                            roles:                    ['lgfs'],
                            parent:                   parent
                            )
