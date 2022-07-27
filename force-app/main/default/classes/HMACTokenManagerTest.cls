/**
* File :         HMACTokenManagerTest
* Created Date : 2 Sep 2021
* Created By :   RA
* Coverage :     82%
* @decription :  Test class for HMACTokenManager
* 
*/
@isTest
private class HMACTokenManagerTest{
    @TestSetup
    static void makeData(){
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
            List<Lead> lstld =   new List<Lead>();
            Lead ld =   new Lead();
            ld.Company = 'FRIENDSHIP HOSPITAL Test';
            ld.LastName = 'Test Lead';
            ld.Status = 'New';  
            ld.Unique_Chewy_ID__c = '1245631';
            ld.Email = 'test@test.com';
            ld.OwnerId = u2.Id;
            ld.Assign_Based_on_State__c = false;
            lstld.add(ld);
            
            
            system.debug('lstld Owner=>'+ld.OwnerId);
            insert lstld;
        }
    }
    //Method to Test HMACTokenManager.
    @isTest static void testGenerateToken(){
        Lead ld = [
            SELECT  Id, Company, Email, Onboarding_ID__c, Token__c, Unique_Chewy_ID__c FROM Lead WHERE Company = 'FRIENDSHIP HOSPITAL Test'];
        List<Lead> lstld = new List<Lead>{ld};
        Test.startTest();
            HMACTokenManager.generate(lstld);
            HMACTokenManager.generateToken(ld.id);
        Test.stopTest();        
        List<Lead> lstLead = [Select Id,Company,Unique_Chewy_ID__c,Email,token__c from Lead Where Id=:lstld[0].Id];
        system.assert(lstLead.size() > 0);
        system.assert(lstLead[0].token__c != Null, 'Token should be Generate');
    }  
    @isTest static void testTokenUpdate(){
        Map<Id,Contact> oldMap = new Map<Id,Contact>();
        Map<Id,Contact> newMap = new Map<Id,Contact>();
        Account act = new Account(Name='Test Account',Unique_Chewy_ID__c='12345',Onboarding_ID__c='5431');
        insert act;
        Contact con = new Contact(AccountId=act.id,LastName = 'Test', Email = 'testemail@test.com');
        insert con;
        oldMap.put(con.Id, con);
        Test.startTest();
            con.Email = 'testemail1@test.com';
            update con;
            newMap.put(con.Id, con);
        Test.stopTest();
        Contact conTest = [SELECT Id, Onboarding_ID_Formula__c, Email, Unique_Chewy_ID_NEW__c FROM Contact WHERE LastName = 'Test'];
        system.assertEquals('testemail1@test.com', conTest.Email);
        system.assertEquals('5431', conTest.Onboarding_Id_formula__c);
    }
}