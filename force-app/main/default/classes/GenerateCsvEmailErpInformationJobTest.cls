/*******************************************************************************************
* @Name             GenerateCsvEmailErpInformationJobTest
* @Author           Dominic Vario
* @Date             2022-08-04
* @Group            Test Class
* @Description      Tests the following class(es):
                    -- GenerateCsvEmailErpInformationJob -- Last Tested 2022-08-08 -- 95%
MODIFICATION LOG
* Version           Developer           Date                Description
*-------------------------------------------------------------------------------------------
* 1.0               Dominic Vario       2022-08-04          Initial development.
*******************************************************************************************/
@isTest
private class GenerateCsvEmailErpInformationJobTest {
    @TestSetup
    static void makeData(){
        List<Account> acctsToInsert = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            acctsToInsert.add(new Account(
                Name = 'Test Account ' + i
                ,Unique_Chewy_Id__c = String.valueOf(i)
                ,SupplierName__c = 'Supplier Name ' + String.valueOf(i)
                ,SupplierId__c = String.valueOf(i)
                ,SiteId__c = String.valueOf(i)
                ,OwnerId = UserInfo.getUserId()
            ));
        }
        insert acctsToInsert;
    }
    @IsTest
    static void testGenerateCSV(){        
        Test.startTest();
            System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent');
            //String cronExp = '0 0 0 * * ?';
            //Id jobId = System.schedule('Test GenerateCsvEmailErpInformationJob', cronExp, new GenerateCsvEmailErpInformationJob());
            GenerateCsvEmailErpInformationJob job = new GenerateCsvEmailErpInformationJob();
            job.execute(null);
            System.assertEquals(1, Limits.getEmailInvocations(), 'Email should be sent');
        Test.stopTest();        
    }
}