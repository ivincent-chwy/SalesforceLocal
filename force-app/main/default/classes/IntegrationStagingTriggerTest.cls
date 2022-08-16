/**
* File :         IntegrationStagingTriggerTest
* Created Date : 26 july 2021
* Created By : 
* Coverage :90%
* @decription :  Test class for IntegrationStagingTrigger
* 
*/
@isTest
public class IntegrationStagingTriggerTest {
    @TestSetup
    static void makeData(){

        Account acc = new Account();
        acc.Name = 'Example Nameson';
        acc.Unique_Chewy_ID__c = '999999';
        insert acc;
        
        Opportunity Opp = new Opportunity();
        opp.Name ='Test Opp';
        opp.AccountId = acc.Id;
        opp.CloseDate = system.today();
        opp.StageName = 'Demo';
        insert opp;

        Integration_Staging__c intStage = new Integration_Staging__c();
        intStage.Account__c = acc.Id;
        intStage.Name = 'old int test';
        intStage.Message_Type__c = 'Onboarding Details';
        intStage.Status__c = 'New';
        intStage.Payload__c='{"ReferenceId": "123457", "Updated": "2021-09-03T20:59:45.898005+00:00", "OnboardingTaskName": "MSA", "Status": "Completed"}';
        insert intStage;
    }
    @isTest
    //Method to test Account record Creation on Integration Staging.
    static void testAccountCreation(){
        
        Integration_Staging__c intStage = new Integration_Staging__c();
        intStage.Name = 'Test';
        intStage.Message_Type__c = 'Clinic Details';
        intStage.Status__c = 'New';
        intStage.Payload__c='{"ClinicName":"Example Nameson","ClinicUniqueChewyID":"999999","ClinicFax":"888-444-4444","ClinicEmail":"example@email.com","ClinicHIN":"1111111","ProvidedPaymentInfo":true,"ProvidedW9":true,"ProvidedTaxExemptCert":true,"ProvidedBankLetter":true,"ClinicPIMSConnection":true,"ClinicPIMSVendor":"Digitail","ClinicPricingType":"Match Chewy Pricing","ClinicMarketingMaterials":true,"Contact":{"ContactName":"Example Nameson","ContactIsPrimary":true,"ContactTitle":"Veterinaria","ContactEmail":"example@email.com","ContactPhone":"888-444-4444 ext 11","ContactIsVeterinary":true,"ContactLicenseState":"CA","ContactLicenseNumber":"V-6546544","ContactAdmin":true}}';
        
        Test.startTest();
        
        insert intStage;
        
        Test.stopTest();
        
        List<Integration_Staging__c> intStageList =[Select Id,Name,Status__c from Integration_Staging__c];
        system.assertEquals(intStageList[0].Status__c, 'Processed','Status should be changed to Processed'); 
        
        List<Account> accList =[Select Id,Name,Unique_Chewy_ID__c from Account];
        system.assertEquals(accList[0].Name, 'Example Nameson','Account record should be created'); 
        system.assertEquals(accList[0].Unique_Chewy_ID__c, '999999','Unique Chewy Id on account as same as on Integration stage');        
        
    }
    @isTest
    //Method to test Contact record Creation Integration Staging.
    static void testContactCreation(){
        
        Integration_Staging__c intStage = new Integration_Staging__c();
        intStage.Name = 'Test';
        intStage.Message_Type__c = 'Contact Details';
        intStage.Status__c = 'New';
        intStage.Payload__c='{"ClinicName":"Example Nameson","ClinicUniqueChewyID":"999999","ClinicFax":"888-444-4444","ClinicEmail":"example@email.com","ClinicHIN":"1111111","ProvidedPaymentInfo":true,"ProvidedW9":true,"ProvidedTaxExemptCert":true,"ProvidedBankLetter":true,"ClinicPIMSConnection":true,"ClinicPIMSVendor":"Provider 3","ClinicPricingType":"Match Chewy Pricing","ClinicMarketingMaterials":true,"Contact":{"ContactName":"Example Nameson","ContactIsPrimary":true,"ContactTitle":"Veterinaria","ContactEmail":"example@email.com","ContactPhone":"888-444-4444 ext 11","ContactIsVeterinary":true,"ContactLicenseState":"CA","ContactLicenseNumber":"V-6546544","ContactAdmin":true}}';
        
        Test.startTest();
        
        insert intStage;
        
        Test.stopTest();
        
        List<Integration_Staging__c> intStageList =[Select Id,Name,Status__c from Integration_Staging__c];
        system.assertEquals(intStageList[0].Status__c, 'Processed','Status should be changed to Processed'); 
        
        List<Contact> conList =[Select Id,Name,Title from Contact];
        system.assertEquals(conList[0].Name, 'Example Nameson','Contact record should be created'); 
        system.assertEquals(conList[0].Title, 'Veterinaria','Title on Contact is as same as on Integration stage');         
    }
    @isTest
    //Method to test Onboarding record Creation Integration Staging.
    static void testOnboardingCreation() {        
        Account acc = [SELECT Id, Name, Onboarding_ID_Auto__c FROM Account WHERE Name = 'Example Nameson'];        
        Opportunity opp = [SELECT Id, Name, AccountId, CloseDate, StageName FROM Opportunity WHERE AccountId = :acc.id];
                 
        Integration_Staging__c intStage = new Integration_Staging__c();
        intStage.Account__c = acc.Id;
        intStage.Name = 'Test';
        intStage.Message_Type__c = 'Onboarding Details';
        intStage.Status__c = 'New';
        intStage.Payload__c='{"ReferenceId": "123456", "Updated": "2021-09-03T20:59:45.898005+00:00", "OnboardingTaskName": "MSA", "Status": "Completed"}';
        
        Test.startTest();        
            insert intStage;
        Test.stopTest(); 
        
        List<Integration_Staging__c> intStageList =[Select Id,Name,Status__c,Onboarding_Detail__c from Integration_Staging__c WHERE Name = 'Test' AND Account__r.Name = 'Example Nameson'];
        Onboarding_Details__c onboard = [Select Id,Name,Opportunity__c,Clinic__c from Onboarding_Details__c WHERE Id = :intStageList[0].Onboarding_Detail__c LIMIT 1];
        Opportunity oppRecord = [Select Id,Name,StageName,MSA__c from Opportunity where id =:onboard.Opportunity__c];
        system.assertEquals(intStageList[0].Status__c, 'Processed','Status should should be completed');
        system.assertEquals(intStageList[0].Onboarding_Detail__c, onboard.Id ,'Oboarding Detail record should be populated');
        system.assertEquals(onboard.Clinic__c, acc.Id ,'Onboarding Id matching Account Should be populated on onboarding detail record');
        system.assertEquals(oppRecord.StageName, 'Enrollment' ,'Opportunity StageName should be updated to Enrollment');
        system.assert(oppRecord.MSA__c,'Opportunity MSA should be true');


    }
    @isTest
    //Method to test Onboarding record Creation Integration Staging.
    static void testOnboardingCreationWithWrongOnboaringId(){        
        Account acc = [SELECT Id, Name, Onboarding_ID_Auto__c FROM Account WHERE Name = 'Example Nameson'];        
        Opportunity opp = [SELECT Id, Name, AccountId, CloseDate, StageName FROM Opportunity WHERE AccountId = :acc.id];                 
        Integration_Staging__c intStage = new Integration_Staging__c();
        intStage.Account__c = acc.Id;
        intStage.Name = 'Test';
        intStage.Message_Type__c = 'Onboarding Details';
        intStage.Status__c = 'New';
        intStage.Payload__c='{"ReferenceId": "123456", "Updated": "2021-09-03T20:59:45.898005+00:00", "OnboardingTaskName": "MSA", "Status": "Completed"}';
        
        Integration_Staging__c int2 = [SELECT Name, CreatedDate FROM Integration_Staging__c WHERE Name = 'old int test'];
        Test.setCreatedDate(int2.id, System.now().addMinutes(-15));

        Test.startTest();
            insert intStage;
        Test.stopTest();  
        
        List<Integration_Staging__c> intStageList =[Select Id,Name,Status__c,Onboarding_Detail__c from Integration_Staging__c WHERE Name = 'Test'];
        Onboarding_Details__c onboard = [Select Id,Name,Opportunity__c,Clinic__c from Onboarding_Details__c WHERE Id = :intStageList[0].Onboarding_Detail__c LIMIT 1];
        Opportunity oppRecord = [Select Id,Name,StageName,MSA__c from Opportunity where id = :onboard.Opportunity__c];
        system.assertEquals(intStageList[0].Status__c, 'Processed','Status should should be completed');
        system.assertEquals(intStageList[0].Onboarding_Detail__c, onboard.Id ,'Oboarding Detail record should be populated');
        system.assertEquals(onboard.Clinic__c, acc.Id ,'Onboarding Id matching Account Should be populated on onboarding detail record');
        system.assertEquals(oppRecord.StageName, 'Enrollment' ,'Opportunity StageName should be updated to Enrollment');
        system.assert(oppRecord.MSA__c,'Opportunity MSA should be true');


    }
     @isTest
    //Method to test Onboarding record Creation Integration Staging.
    static void testOnboardingCreations(){
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        Profile p=[SELECT Id From Profile WHERE Name='System Administrator'];
        User u2 =new User( Alias = 'newUser1' ,
                          Email ='newuser123@testorg.com',
                          EmailEncodingKey = 'UTF-8',
                          FirstName = 'Alexander',
                          LastName = 'Booras',
                          LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', 
                          UserName= uniqueUserName,
                          ProfileId=p.Id,
                          TimeZoneSidKey  = 'America/Los_Angeles');
        insert u2;
        System.runAs(u2){
            Lead ld = new Lead();
            ld.LastName = 'Test';
            ld.Company = 'New';
            ld.Status = 'Working';
            ld.Assign_Based_on_State__c = false;
            insert ld;
            
            
            Integration_Staging__c intStage = new Integration_Staging__c();
            intStage.Name = 'Test';
            intStage.Lead__c = ld.Id;
            intStage.Message_Type__c = 'Onboarding Details';
            intStage.Status__c = 'New';
            intStage.Payload__c='{"ReferenceId": "745821477", "Updated": "2021-09-03T20:59:45.898005+00:00", "OnboardingTaskName": "OnboardRecForAccount", "Status": "Completed"}';
            
            Test.startTest();
            
            insert intStage;
            
            Test.stopTest();  
            
            List<Integration_Staging__c> intStageList =[Select Id,Name,Status__c,Onboarding_Detail__c from Integration_Staging__c WHERE Name = 'Test'];
            system.assertEquals(intStageList[0].Status__c, 'Processed','Status should be changed to Processed'); 
            system.assert(intStageList[0].Onboarding_Detail__c != null ,'Oboarding Detail record should be created');
            List<Onboarding_Details__c> onBoardList = [Select Id,Name,Opportunity__c,Clinic__c from Onboarding_Details__c WHERE Id = :intStageList[0].Onboarding_Detail__c];
            system.assertEquals(System.Label.Catch_all_Account_record_Id,onBoardList[0].Clinic__c, 'Account Should be Populated on Onboarding details record');
            system.assertEquals(System.Label.Catch_all_Opportunity_record_Id,onBoardList[0].Opportunity__c, 'Opportunity Should be Populated on Onboarding details record');       
        } 
    }
     @isTest
    //Method to test Onboarding record Creation Integration Staging.
    static void testOnboardingCreationss(){
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        Profile p=[SELECT Id From Profile WHERE Name='System Administrator'];
        User u2 =new User( Alias = 'newUser1' ,
                          Email ='newuser123@testorg.com',
                          EmailEncodingKey = 'UTF-8',
                          FirstName = 'Alexander',
                          LastName = 'Booras',
                          LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', 
                          UserName= uniqueUserName,
                          ProfileId=p.Id,
                          TimeZoneSidKey  = 'America/Los_Angeles');
        insert u2;
        System.runAs(u2){        
            Lead ld = new Lead();
            ld.LastName = 'Test';
            ld.Company = 'New';
            ld.Status = 'Working';
            ld.Assign_Based_on_State__c = false;
            insert ld;
            
            Lead ldrec = [select Id,Name,Onboarding_Id__c,convertedAccountId,ConvertedOpportunityId from lead where id =: ld.Id];
            
            Integration_Staging__c intStage = new Integration_Staging__c();
            intStage.Name = 'Test';
            intStage.Lead__c = ld.Id;
            intStage.Message_Type__c = 'Onboarding Details';
            intStage.Status__c = 'New';
            intStage.Payload__c='{"ReferenceId": "'+ldrec.Onboarding_Id__c+'", "Updated": "2021-09-03T20:59:45.898005+00:00", "OnboardingTaskName": "MSA", "Status": "Completed"}';
            
            
            Test.startTest();
            
            insert intStage;
            system.debug('intStage=>'+intStage);
            Test.stopTest();  
            
            Lead ldrecs = [select Id,Name,Onboarding_Id__c,convertedAccountId,ConvertedOpportunityId from lead where id =: ld.Id];
            system.debug('ldrec=>'+ldrec);
            List<Integration_Staging__c> intStageList =[Select Id,Name,Status__c,Onboarding_Detail__c from Integration_Staging__c WHERE Name = 'Test'];
            Onboarding_Details__c onboard = [Select Id,Name,Opportunity__c,Clinic__c from Onboarding_Details__c WHERE Id = :intStageList[0].Onboarding_Detail__c LIMIT 1];
            system.assertEquals(intStageList[0].Status__c, 'Processed','Status should should be completed');
            system.assertEquals(intStageList[0].Onboarding_Detail__c, onboard.Id ,'Oboarding Detail record should be populated');
            system.assert(onboard.Clinic__c != null,'Onboarding Id matching Account Should be populated on onboarding detail record');
            system.assert(onboard.Opportunity__c != null,'Opportunity Should be populated');
        }
    }
   
}