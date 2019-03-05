# frozen_string_literal: true

require 'test_helper'

class CurrentUserQueryTest < ActiveSupport::TestCase
  USER_QUERY = <<~EOS
    query {
      currentUser {
        email
        address
        username
        displayName
        createdAt
      }
    }
  EOS

  VISIBILITY_QUERY = <<~EOS
    query {
      currentUser {
        isBanned
      }
    }
  EOS

  ROLE_QUERY = <<~EOS
    query {
      currentUser {
        isKycOfficer
        isForumAdmin
      }
    }
  EOS

  test 'current user query should work' do
    user = create(:user)

    result = DaoServerSchema.execute(
      USER_QUERY,
      context: { current_user: user },
      variables: {}
    )

    assert_nil result['errors'],
               'should work and have no errors'

    data = result['data']['currentUser']

    assert_not_empty data,
                     'user type should work'
    assert_equal "user#{user.uid}", data['displayName'],
                 'display name should default'

    new_username = generate(:username)
    ok, updated_user = User.change_username(user, new_username)

    assert_equal :ok, ok,
                 'change username should work'

    result = DaoServerSchema.execute(
      USER_QUERY,
      context: { current_user: updated_user },
      variables: {}
    )

    assert_equal new_username, result['data']['currentUser']['displayName'],
                 'display name should now be the username'
  end

  test 'current user roles should work' do
    officer_result = DaoServerSchema.execute(
      ROLE_QUERY,
      context: { current_user: create(:kyc_officer_user) },
      variables: {}
    )

    assert officer_result['data']['currentUser']['isKycOfficer'],
           'isKycOfficer field should be true'
    refute officer_result['data']['currentUser']['isForumAdmin'],
           'isForumAdmi nfield should be true'

    admin_result = DaoServerSchema.execute(
      ROLE_QUERY,
      context: { current_user: create(:forum_admin_user) },
      variables: {}
    )

    refute admin_result['data']['currentUser']['isKycOfficer'],
           'isKycOfficer field should be true'
    assert admin_result['data']['currentUser']['isForumAdmin'],
           'isForumAdmi nfield should be true'

    normal_result = DaoServerSchema.execute(
      ROLE_QUERY,
      context: { current_user: create(:user) },
      variables: {}
    )

    refute normal_result['data']['currentUser']['isKycOfficer'],
           'isKycOfficer field should be false for normal users'
    refute normal_result['data']['currentUser']['isForumAdmin'],
           'isKycOfficer field should be false for normal users'
  end

  test 'should fail safely' do
    unauthorized_result = DaoServerSchema.execute(
      USER_QUERY,
      context: {},
      variables: {}
    )

    assert_nil unauthorized_result['data']['currentUser'],
               'should be empty without a current user'

    visible_result = DaoServerSchema.execute(
      VISIBILITY_QUERY,
      context: { current_user: create(:user) },
      variables: {}
    )

    assert_not_empty visible_result['errors'],
                     'isBanned should not be visible'
  end

  KYC_QUERY = <<~EOS
    query {
      currentUser {
        kyc {
          id
          status
          expirationDate
          userId
          email
          ethAddress
          isApproved
          firstName
          lastName
          gender
          birthdate
          nationality
          phoneNumber
          employmentStatus
          employmentIndustry
          incomeRange
          identificationProof {
            number
            expirationDate
            type
            image {
              contentType
              filename
              fileSize
              dataUrl
            }
          }
          residenceProof {
            residence {
              address
              addressDetails
              city
              country
              postalCode
              state
            }
            type
            image {
              contentType
              filename
              fileSize
              dataUrl
            }
          }
          identificationPose {
            verificationCode
            image {
              contentType
              filename
              fileSize
              dataUrl
            }
          }
          ipAddresses
          createdAt
          updatedAt
        }
      }
    }
  EOS

  test 'kyc should be visible' do
    kyc = create(:kyc)

    result = DaoServerSchema.execute(
      KYC_QUERY,
      context: { current_user: kyc.user },
      variables: {}
    )

    assert_nil result['errors'],
               'should work and have no errors'

    data = result['data']['currentUser']['kyc']

    assert_not_empty data,
                     'kyc type should work'
    assert_not_empty data['residenceProof']['residence'],
                     'nullable residence proof should be present'
  end

  test 'kyc expired status should work' do
    approved_kyc = create(:approved_kyc, expiration_date: Time.now + 1.day)

    result = DaoServerSchema.execute(
      KYC_QUERY,
      context: { current_user: approved_kyc.user },
      variables: {}
    )

    assert_equal 'APPROVED', result['data']['currentUser']['kyc']['status'],
                 'kyc should be approved'

    expired_kyc = create(:approved_kyc, expiration_date: Time.now)

    expired_result = DaoServerSchema.execute(
      KYC_QUERY,
      context: { current_user: expired_kyc.user },
      variables: {}
    )

    assert_equal 'EXPIRED', expired_result['data']['currentUser']['kyc']['status'],
                 'kyc should be expired'
  end
end
