Feature: Viewing and downloading claim evidence

  Background:
  - As a signed in caseworker, with claims allocated to me, I want to use evidence from the provider to help me process a claim.
  - As an advocate, I want to check evidence that I have provided as part of my claim

  Scenario: Documents available to caseworkers in evidence list
    Given I am signed in and on the case worker dashboard
      And I have been assigned claims with evidence attached
     When I visit the detail link for a claim
     Then I see links to view/download each document submitted with the claim

  Scenario: Caseworker downloads a document
    Given I am signed in and on the case worker dashboard
      And I have been assigned claims with evidence attached
     When I visit the detail link for a claim
      And click on a link to download some evidence
     Then I should get a download with the filename "longer_lorem.pdf"

  Scenario: Caseworker views a document
    Given I am signed in and on the case worker dashboard
      And There are fee schemes in place
      And I have been assigned claims with evidence attached
    When I visit the detail link for a claim
      And click on a link to view some evidence
    Then I see "longer_lorem.pdf" in my browser

  @javascript @webmock_allow_localhost_connect
  Scenario: Caseworker views a document in a new tab
    Given I am signed in and on the case worker dashboard
      And I have been assigned claims with evidence attached
    When I visit the detail link for a claim
      And click on a link to view some evidence
    Then a new tab opens

  Scenario: Documents available to advocates in evidence list
    Given I am a signed in advocate
      And There are fee schemes in place
      And I have claims
    When I view the claim
    Then I see links to view/download each document submitted with the claim

  Scenario: Advocate downloads a document
    Given I am a signed in advocate
      And There are fee schemes in place
      And I have claims
    When I view the claim
      And click on a link to download some evidence
    Then I should get a download with the filename "longer_lorem.pdf"

  Scenario: Caseworker views a document
    Given I am a signed in advocate
      And There are fee schemes in place
      And I have claims
     When I view the claim
      And click on a link to view some evidence
    Then I see "longer_lorem.pdf" in my browser

  Scenario: Advocate views a document
    Given I am a signed in advocate
      And There are fee schemes in place
      And I have claims
     When I view the claim
      And click on a link to view some evidence
     Then I see "longer_lorem.pdf" in my browser
