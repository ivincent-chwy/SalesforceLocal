/*******************************************************************************************
* @Name           AccountActivationJsonJob
* @Author         Dominic Vario
* @Date           2022-05-25
* @Group          Schedulable
* @Description    Queries for all Clinics (Accounts) that went live in the past week, then prepares two separate JSON list objects to insert as Account Actication records.
MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
* 1.0              Dominic Vario      2022-05-25         Creation and initial deployment.
* 1.1              Dominic Vario      2022-05-25         Changed ClinicGoLiveDate__c to ActivationDate__c and set date range to TODAY.
*******************************************************************************************/

public class AccountActivationJsonJob implements Schedulable{
    public void execute(SchedulableContext sc) {
        Date today = System.today();
        List<Account> accountList = new List<Account>(); // Instantiate list to prevent null list exception
        accountList = [
            SELECT  ClinicSchemaName__c, Unique_Chewy_Id__c, PrimaryContact__r.FirstName, PrimaryContact__r.LastName, PrimaryContact__r.Email, ActivationDate__c
            FROM    Account
            WHERE   ActivationDate__c = :today
        ];
        if(!accountList.isEmpty()){
            List<Object> clinicActivationList = new List<Object>(); // test
            List<Object> clinicAdminList = new List<Object>();
            for(Account acc : accountList){
                // Clinic Activation Context
                clinicActivationList.add(JSON.serialize(
                    new Map<String,Object>{
                        'ClinicId' => acc.Unique_Chewy_Id__c
                        ,'ClinicSchemaName' => acc.ClinicSchemaName__c
                    }
                ));
                // Clinic Admin Context
                clinicAdminList.add(JSON.serialize(
                    new Map<String,Object>{
                        'ClinicSchemaName' => acc.ClinicSchemaName__c
                        ,'firstName' => acc.PrimaryContact__r.FirstName
                        ,'lastName' => acc.PrimaryContact__r.LastName
                        ,'email' => acc.PrimaryContact__r.Email
                    }
                ));
            }
            List<AccountActivation__c> accountActivationList = new List<AccountActivation__c>{
                (new AccountActivation__c( // Clinic Activation Context
                    JSON__c = '[' + clinicActivationList.toString().removeStart('(').removeEnd(')') + ']'
                    ,Type__c = 'Clinic Activation'
                    )
                ),(new AccountActivation__c( // Clinic Admin Context
                    JSON__c = '[' + clinicAdminList.toString().removeStart('(').removeEnd(')') + ']'
                    ,Type__c = 'Clinic Admin'
                    )
                )
            };
            if(!accountActivationList.isEmpty()){ // Checks to see if there are Account Activation records to insert
                Id cynthiaHearn = [
                        SELECT  Id 
                        FROM    User 
                        WHERE   FirstName = 'Cynthia'
                        AND     LastName = 'Hearn'
                        LIMIT   1
                    ].Id;
                try{
                    insert accountActivationList;
                    String chatterBody = 'Account Activation Job completed for date ' + String.valueOf(today) + '.';
                    FeedItem chatterPost = new FeedItem(  // Chatter Post to Cynthia Heard
                        ParentId = cynthiaHearn
                        ,Body = chatterBody
                    );
                    insert chatterPost;
                    if(Test.isRunningTest()){
                        throw new DmlException();
                    }
                }catch(Exception e){
                    Id ianVincent = [
                        SELECT  Id
                        FROM    User 
                        WHERE   FirstName = 'Ian'
                        AND     LastName = 'Vincent'
                        LIMIT   1
                    ].Id;
                    String chatterBody = 'Account Activation Job failed for date ' + String.valueOf(today) + '.';
                    List<FeedItem> chatterPosts = new List<FeedItem>{  // Chatter Post to Cynthia Heard
                        (new FeedItem(
                            ParentId = cynthiaHearn
                            ,Body = chatterBody
                            )
                        ),(new FeedItem(
                            ParentId = ianVincent
                            ,Body = chatterBody
                            )
                        )
                    };
                    insert chatterPosts;
                    System.debug('== ERROR MESSAGE == ' + e.getMessage());
                    System.debug('== ERROR CAUSE == ' + e.getCause());
                    System.debug('== ERROR LINE == ' + e.getLineNumber());
                }
            }
        }
    }
}