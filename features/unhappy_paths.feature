Feature: Unhappy paths
  Background:
    As an advocate saving drafts and submitting claims I want to be sure that error messages are displayed if I do something wrong

  Scenario: Attempt to log in with wrong password
     Given I attempt to log in with an incorrect password
      Then I should be redirected back to the login page
       And I should see an error message

  # Scenario: Attempt to save draft claim as advocate admin without specifying the advocate
  #    Given I am a signed in advocate admin
  #      And I am on the new claim page
  #      And I fill in the claim details omitting the advocate
  #     When I save to drafts
  #     Then I should be redirected back to the new claim page
  #      And I should see an error message
  #
  # Scenario: Attempt to submit claim to LAA without specifying all fields
  #    Given I am a signed in advocate
  #      And I am on the new claim page
  #      And I attempt to submit to LAA without specifying all the details
  #     Then I should be redirected back to the new claim page
  #      And I should see an error message for each of the missing fields
  #

