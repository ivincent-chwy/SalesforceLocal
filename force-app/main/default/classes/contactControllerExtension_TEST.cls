@isTest
private class contactControllerExtension_TEST {
    @TestSetup
    static void makeData(){
        Account a = new Account(
            Name = 'Test Account'
            ,Unique_Chewy_ID__c = '23456'
        );
        insert a;
        Contact conWithToken = new Contact(
            AccountId = a.id
            ,FirstName = 'First'
            ,LastName = 'Last'
            ,Email = 'testemail@test.com'
            ,onboarding_token__c = 'zXM0C08T505XPJ1H/zjV5weSfAgR22zp/91ssEVCLutqTfM0esxtjx/DPB7salpvHHPECNpFSa7WgOttvfHIxdigRaWeQ9q0g5AiGds3FcMq9gK9oiOuJgdBep8DpOJFVsu7TngmFBXn7NSwAnSLRdfq7iPBwnyCy6yT/rmtkIw='
        );
        insert conWithToken;
    }
    private static testMethod void testWithToken() {
        Contact con = [SELECT Id, AccountId, Account.Onboarding_ID__c, Account_Name_for_Pardot__c, Onboarding_ID_formula__c, Unique_Chewy_ID_NEW__c, onboarding_token__c, Email FROM Contact WHERE Onboarding_ID_formula__c = '12346' LIMIT 1];
        PageReference pageRef = Page.invitationBuffer;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id',String.valueOf(con.id));
        ApexPages.StandardController sc = new ApexPages.StandardController(con);
        contactControllerExtension testExtension = new contactControllerExtension(sc);
        // test assertions
        System.assertEquals(Integer.valueOf(con.Unique_Chewy_ID_NEW__c), testExtension.getClinicId());
        System.assertEquals(con.Account_Name_for_Pardot__c, testExtension.getClinicName());
        System.assertEquals(con.Email, testExtension.getEmail());
        System.assertEquals(con.Account.Onboarding_ID__c, testExtension.getOnboardingId());
    }
}