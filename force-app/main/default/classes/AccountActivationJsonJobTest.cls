/*******************************************************************************************
* @Name           AccountActivationJsonJobTest 
* @Author         Dominic Vario
* @Date           2022-05-31
* @Group          Testing
* @Description    Tests the AccountActivationJsonJob class
MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
* 1.0              Dominic Vario      2022-05-31         Initial creation; Code coverage 100%.
* 1.1              Dominic Vario      2022-05-31         Changed ClinicGoLiveDate__c to ActivationDate__c and set date value to TODAY; Code coverage 100%.
*******************************************************************************************/

@isTest
private class AccountActivationJsonJobTest {
    @TestSetup
    static void makeData() {
        List<User> userList = new List<User>{
            (new User(                
                FirstName = 'Cynthia'
                ,LastName = 'Heard'
                ,Email = 'cynthiaHearn@email.com'
                ,Username = 'cynthiaHearn@email.com'
                ,Alias = 'chearn'
                ,ProfileId = UserInfo.getProfileId()
                ,TimeZoneSidKey = 'America/Los_Angeles'
                ,EmailEncodingKey = 'UTF-8'
                ,LanguageLocaleKey = 'en_US'
                ,LocaleSidKey = 'en_US'
                )
            ),(new User(                
                FirstName = 'Ian'
                ,LastName = 'Vincent'
                ,Email = 'ianVincent@email.com'
                ,Username = 'ianVincent@email.com'
                ,Alias = 'ivince'
                ,ProfileId = UserInfo.getProfileId()
                ,TimeZoneSidKey = 'America/Los_Angeles'
                ,EmailEncodingKey = 'UTF-8'
                ,LanguageLocaleKey = 'en_US'
                ,LocaleSidKey = 'en_US'
                )
            )
        };
        insert userList; // test
        List<Account> accountList = new List<Account>{
            (new Account(
                Name = 'Test Account 1'
                ,Unique_Chewy_ID__c = '12341'
                ,ClinicSchemaName__c = 'test_account_1'
                ,ActivationDate__c = System.today()
                )
            ),(new Account(
                Name = 'Test Account 2'
                ,Unique_Chewy_ID__c = '12342'
                ,ClinicSchemaName__c = 'test_account_2'
                ,ActivationDate__c = System.today()
                )
            ),(new Account(
                Name = 'Test Account 3'
                ,Unique_Chewy_ID__c = '12343'
                ,ClinicSchemaName__c = 'test_account_3'
                ,ActivationDate__c = System.today()
                )
            ),(new Account(
                Name = 'Test Account 4'
                ,Unique_Chewy_ID__c = '12344'
                ,ClinicSchemaName__c = 'test_account_4'
                ,ActivationDate__c = System.today()
                )
            )
        };
        insert accountList;
        List<Contact> contactList = new List<Contact>{
            (new Contact(
                FirstName = 'Test'
                ,LastName = 'Contact1'
                ,Email = 'contact1@test.com'
                ,AccountId = accountList[0].Id
                )
            ),(new Contact(
                FirstName = 'Test'
                ,LastName = 'Contact2'
                ,Email = 'contact2@test.com'
                ,AccountId = accountList[1].Id
                )
            ),(new Contact(
                FirstName = 'Test'
                ,LastName = 'Contact3'
                ,Email = 'contact3@test.com'
                ,AccountId = accountList[2].Id
                )
            ),(new Contact(
                FirstName = 'Test'
                ,LastName = 'Contact4'
                ,Email = 'contact4@test.com'
                ,AccountId = accountList[3].Id
                )
            )
        };
        insert contactList;
        accountList[0].PrimaryContact__c = contactList[0].Id;
        accountList[1].PrimaryContact__c = contactList[1].Id;
        accountList[2].PrimaryContact__c = contactList[2].Id;
        accountList[3].PrimaryContact__c = contactList[3].Id;
        update accountList;
    }
    @isTest 
    static void testAccountActivationJsonJob() {
        Test.startTest();
            AccountActivationJsonJob job = new AccountActivationJsonJob();
            job.execute(null);
        Test.stopTest();
        List<AccountActivation__c> aaList = [
            SELECT  Id 
            FROM    AccountActivation__c
        ];
        List<FeedItem> feedList = [
            SELECT  Id 
            FROM    FeedItem
        ];
        System.assert(aaList.size() == 2);
        System.assert(feedList.size() == 3);
    }
}