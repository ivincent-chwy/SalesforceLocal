/**
 * CREATED BY ---- DV
 * CREATED DATE -- 2022-04-01 
 * COVERAGE ------ 100%
 * -- APEX CLASSES:
 * -- -- decryptOnboardingToken
 * -- -- regenerateToken
 * -- -- contactControllerExtension
 * -- -- decryptTokenAdminTool
 * -- APEX TRIGGERS:
 * -- -- ContactTrigger
 * -- -- LeadTrigger
 */
@isTest
private class tokenGenExtLeadCon_TEST {
    @TestSetup
    static void makeData(){
        Account a = new Account(
            Name = 'Test AccountTest AccountTest AccountTest AccountTest Account'
            ,Unique_Chewy_ID__c = '23456'
        );
        insert a;
        Contact conWithToken = new Contact(
            AccountId = a.id
            ,FirstName = 'Contact1FN'
            ,LastName = 'Contact1LN'
            ,Email = 'testemail@test.com'
            // must provide a real token
            ,onboarding_token__c = 'MhQ2jMZCTAs/Fd7eGCzwfgNip49/0Tty8BT6Hz3x05JCrpPzcpl/VRUyLZkrS4rw45N61UqaZTRwCgkPK7UMpJty8u8fsjcWCPGOsAjvIXm89f4gqakM98vdpJLZYieiZJqSHhlnphg84YEOWRQUjt9ZWAEdfraJOeWqhxzaTjaMyQfr3su1YJoTrQZnHVI/lSW1CwKcJ9dS/Kji+YN3gsBHjgJ0esqDtg94SEwEC40='
        );
        insert conWithToken;
        Lead leadMissingParams = new Lead(
            Company = 'Test CompanyTest CompanyTest CompanyTest CompanyTest Company'
            ,Assign_Based_on_State__c = FALSE
            ,FirstName = 'Lead1FN'
            ,LastName = 'Lead1LN'
            ,Email = 'testemail2testemail2testemail2testemail2testemail2@test.com'
        );
        insert leadMissingParams;
        leadMissingParams.Unique_Chewy_ID__c = '3456';
        update leadMissingParams;
        leadMissingParams.Unique_Chewy_ID__c = '';
        update leadMissingParams;
        Lead leadWithParams = new Lead(
            Company = 'Test Company2Test Company2Test Company2Test Company2'
            ,Assign_Based_on_State__c = FALSE
            ,FirstName = 'Lead2FN'
            ,LastName = 'Lead2LN'
            ,Email = 'testemail3testemail3testemail3testemail3testemail3@test.com'
            ,Unique_Chewy_ID__c = '4567'
        );
        insert leadWithParams;
        Contact conWithToken2 = new Contact(
            AccountId = a.id
            ,FirstName = 'Contact2FN'
            ,LastName = 'Contact2LN'
            ,Email = 'testemail4testemail4testemail4testemail4testemail4@test.com'
            // must provide a real token
            ,onboarding_token__c = 'rSBHQySH/tAmBNrdWotj3Yrn3E4TSkWgqu5ecnmx+bCNaih0U+3hxb8ZDBabXf4u1T8vqwPIdy9ZC5qQauWBdo8b4FSjd1i2j2lgD6xlhcoJjM2yA0tf6wuKBIq6aAYu+OU2ZPc1foKQGESjiCMEU2Vap0Emv5IYIwXV31LBIRg='
        );
        insert conWithToken2;
        conWithToken2.Email = 'testemail5@test.com';
        update conWithToken2;
        conWithToken2.Email = null;
        update conWithToken2;
        Contact conWithoutToken = new Contact(
            AccountId = a.id
            ,FirstName = 'Contact3FN'
            ,LastName = 'Contact3LN'
        );
        insert conWithoutToken;
        conWithoutToken.LastName = 'Contact4LN';
        update conWithoutToken;
        Contact conWithoutToken2 = new Contact(
            AccountId = a.id
            ,FirstName = 'Contact3FN2'
            ,LastName = 'Contact3LN2'            
        );
        insert conWithoutToken2;
        conWithoutToken.Email = 'testemailtestemailtestemailtestemailtestemail@test.com';
        update conWithoutToken;
    }
    @isTest
    private static void testWithToken() {
        Contact con = [SELECT Id, AccountId, Account.Name, Account_Name_for_Pardot__c, Onboarding_ID_formula__c, Unique_Chewy_ID_NEW__c, onboarding_token__c, Email FROM Contact WHERE LastName = 'Contact1LN' LIMIT 1];
        PageReference pageRef = Page.invitationBuffer;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id',String.valueOf(con.id));
        ApexPages.StandardController sc = new ApexPages.StandardController(con);
        contactControllerExtension testExtension = new contactControllerExtension(sc);
        // test assertions
        System.assertEquals(Integer.valueOf(con.Unique_Chewy_ID_NEW__c), testExtension.getClinicId());
        System.assertEquals(con.Account_Name_for_Pardot__c, testExtension.getClinicName());
        System.assertEquals(con.Email, testExtension.getEmail());
        System.assertEquals(con.Onboarding_ID_formula__c, testExtension.getOnboardingId());
    }
    @isTest
    private static void testInvokeDecrypt() {
        Contact con = [SELECT Id, Account_Name_for_Pardot__c, Onboarding_ID_formula__c, Unique_Chewy_ID_NEW__c, onboarding_token__c, Email FROM Contact WHERE Onboarding_ID_formula__c = '12345' LIMIT 1];
        decryptOnboardingToken.flowInput fi = new decryptOnboardingToken.flowInput();
        fi.currentToken = con.onboarding_token__c;
        fi.onboardingId = con.Onboarding_ID_formula__c;
        fi.clinicName = con.Account_Name_for_Pardot__c;
        fi.email = con.Email;
        fi.clinicId = con.Unique_Chewy_ID_NEW__c;
        List<String> returnedTokenList = decryptOnboardingToken.invokeDecrypt(new List<decryptOnboardingToken.flowInput>{fi});
        decryptOnboardingToken.flowInput fi2 = new decryptOnboardingToken.flowInput();
        fi2.currentToken = con.onboarding_token__c;
        fi2.onboardingId = con.Onboarding_ID_formula__c;
        fi2.clinicName = con.Account_Name_for_Pardot__c;
        fi2.email = 'testgood@test.com';
        fi2.clinicId = con.Unique_Chewy_ID_NEW__c;
        List<String> returnedTokenList2 = decryptOnboardingToken.invokeDecrypt(new List<decryptOnboardingToken.flowInput>{fi2});
        System.assert(!returnedTokenList.isEmpty());
        System.assert(!returnedTokenList2.isEmpty());
    }
    @isTest
    private static void testRegenerateToken() {
        Contact con = [SELECT Id, Account_Name_for_Pardot__c, Onboarding_ID_formula__c, Unique_Chewy_ID_NEW__c, onboarding_token__c, Email FROM Contact WHERE Onboarding_ID_formula__c = '12345' LIMIT 1];
        regenerateToken.flowInput fi = new regenerateToken.flowInput();
        fi.onboardingId = con.Onboarding_ID_formula__c;
        fi.clinicName = con.Account_Name_for_Pardot__c;
        fi.email = con.Email;
        fi.clinicId = con.Unique_Chewy_ID_NEW__c;
        List<String> returnedToken = regenerateToken.generate(new List<regenerateToken.flowInput>{fi});
        System.assert(!returnedToken.isEmpty());
    }
    @isTest
    private static void testAdminDecryptTool() {
        // must provide a real token
        List<String> tokens = new List<String>{'rSBHQySH/tAmBNrdWotj3Yrn3E4TSkWgqu5ecnmx+bCNaih0U+3hxb8ZDBabXf4u1T8vqwPIdy9ZC5qQauWBdo8b4FSjd1i2j2lgD6xlhcoJjM2yA0tf6wuKBIq6aAYu+OU2ZPc1foKQGESjiCMEU2Vap0Emv5IYIwXV31LBIRg='};
        List<String> returnedToken = decryptTokenAdminTool.decryptToken(tokens);
        System.assert(!returnedToken.isEmpty());
    }
}