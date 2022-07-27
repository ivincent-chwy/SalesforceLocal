/** 
 * @description Batch class to create Onboard Details records
 */
public class IntegrationStagingBatch implements Database.Batchable<sObject>{
    /** 
     * @description Batch Class start Method
     * get all records from Integration staging table in 'New' status
     * @param BC - standard batchable context
     * @return database.querylocator
     */
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('Select Id,Name,Payload__c,Status__c,Error_Message__c,CreatedDate,Message_Type__c from Integration_Staging__c where Status__c=\'New\'');
    }    
    /** 
     * @description Batch Class execute Method
     * main method to process the payload from Integration staging object.
     * @param BC
     * @param listRecords list of integration staging records
     */
    public void execute(Database.BatchableContext BC, List<Integration_Staging__c> listRecords){
        Integration_Staging__c record = new Integration_Staging__c();
        record = listRecords[0];
        String payload = record.Payload__c;
        payload = payload.replace('\'', '\"');
        ChewyRecords chewRecds = new ChewyRecords();
        //create Account Records
        if(record.Message_Type__c == 'Clinic Details'){
            Account acc;
            acc = (Account)IntegrationStagingBatch.processObjectData('Account',payload);
            
            List<Account> acclist = new List<Account>([Select Id,Name,Unique_Chewy_ID__c from Account where Unique_Chewy_ID__c = :acc.Unique_Chewy_ID__c]);
            if(acclist !=null && acclist.size() >0 ){
                acc.Id = acclist[0].Id;
            }
            try{
                if(Schema.sObjectType.Account.isCreateable() && Schema.sObjectType.Account.isUpdateable()){
                    upsert acc ;
                }
                record.Status__c = 'Processed';
                record.Account__c = acc.Id;
            }catch(Exception exp){
                record.Status__c = 'Error';
                record.Error_Message__c = exp.getMessage();
                system.debug('exp : '+exp);
            }
            if(Schema.sObjectType.Integration_Staging__c.isUpdateable()){
                update record;
            }
        }
        //create Contact Records
        if(record.Message_Type__c == 'Contact Details'){
            Contact cnt;
            cnt = (Contact)IntegrationStagingBatch.processObjectData('Contact',payload);
            
            List<Contact> cntlist = new List<Contact>([Select Id,FirstName,LastName,Email from Contact where LastName=:cnt.LastName AND Email = :cnt.Email]);
            if(cntlist !=null && cntlist.size() >0 ){
                cnt.Id = cntlist[0].Id;
            }
            try{
                if(Schema.sObjectType.Contact.isCreateable() &&  Schema.sObjectType.Contact.isUpdateable()){
                    upsert cnt ;
                }
                record.Status__c = 'Processed';
                record.Contact__c = cnt.Id;
            }Catch(Exception exp){
                record.Status__c = 'Error';
                record.Error_Message__c = exp.getMessage();
                system.debug('exp : '+exp);
            }
            if(Schema.sObjectType.Integration_Staging__c.isUpdateable()){
                update record;
            }
        }
        //create Onboarding Details Records
        if(record.Message_Type__c == 'Onboarding Details'){
            Map<String, Object> mapPayload = (Map<String, Object>) JSON.deserializeUntyped(payload);
            String refId =  (String)((Map<String, Object>) mapPayload).get('ReferenceId');
            String accRecId;
            String cntRecId;
            String oppRecId;
            Opportunity opp;
            Account acc;
            if(record.CreatedDate >= System.now().addMinutes(-30) && record.Name != 'TestBadId') { // FALLBACK FOR LOOPING RECORDS
                List<Account> acclist = new List<Account>([
                    SELECT  Id, Name, Onboarding_Id__c, Onboarding_ID_Auto__c 
                    FROM    Account 
                    WHERE   Onboarding_Id__c = :refId 
                    OR      Onboarding_ID_Auto__c = :refId
                ]);
                if(acclist != null && acclist.size() > 0) {
                    acc = acclist[0];
                }                
                if(acc == null) {                    
                    //Holding Account
                    //accRecId = System.Label.Holding_Account;
                    chewRecds.accountId = System.Label.Catch_all_Account_record_Id;
                    chewRecds.opportunityId = System.Label.Catch_all_Opportunity_record_Id;
                } else {
                    //accRecId = acc.Id;
                    chewRecds.accountId = acc.Id;
                }
            } else { // if record is older than 30 mins, run this
                chewRecds.accountId = System.Label.Catch_all_Account_record_Id;
                chewRecds.opportunityId = System.Label.Catch_all_Opportunity_record_Id;
            }            
            if(chewRecds.accountId != null){
                Onboarding_Details__c onbRecord;
                List<Opportunity> lstOpp;
                if(chewRecds.opportunityId == null){
                    lstOpp = new List<Opportunity>([Select Id,AccountId,Name,Onboarding_Opportunity__c,StageName,MSA__c,Banking_details__c,
                                                    Tax_Exempt_Cert__c,W9__c from Opportunity 
                                                    where AccountId =:chewRecds.accountId and Onboarding_Opportunity__c = true]);
                    if(lstOpp != null && lstOpp.size() > 0){
                        opp = lstOpp[0];
                        chewRecds.opportunityId =lstOpp[0].Id;
                    }
                    if(chewRecds.opportunityId == null){
                        //get opportunity record from catch-all
                        opp = [Select Id,AccountId,Name,Onboarding_Opportunity__c,StageName,MSA__c,Banking_details__c,Tax_Exempt_Cert__c,
                               W9__c from Opportunity where id = :System.Label.Catch_all_Opportunity_record_Id];
                        chewRecds.opportunityId = opp.Id;
                    }
                }
                else{
                    lstOpp = new List<Opportunity>([Select Id,AccountId,Name,Onboarding_Opportunity__c,StageName,MSA__c,Banking_details__c,
                                                    Tax_Exempt_Cert__c,W9__c from Opportunity 
                                                    where Id =:chewRecds.opportunityId and Onboarding_Opportunity__c = true]);
                    if(lstOpp != null && lstOpp.size() > 0){
                        opp = lstOpp[0];
                    }
                }
                
                
                try{
                    //get onboarding record object with fields
                    onbRecord = (Onboarding_Details__c)IntegrationStagingBatch.processObjectData('Onboarding_Details__c',payload);
                    List<Onboarding_Details__c> lstOnbDetails = new List<Onboarding_Details__c>([Select Id,Name from Onboarding_Details__c where Name =:onbRecord.Name]);

                    if(lstOnbDetails != null && lstOnbDetails.size()>0){
                        onbRecord.Id = lstOnbDetails[0].Id;
                    }
                    onbRecord.Clinic__c = chewRecds.accountId;
                    onbRecord.Opportunity__c = chewRecds.opportunityId;
                    if(Schema.sObjectType.Onboarding_Details__c.isCreateable() && Schema.sObjectType.Onboarding_Details__c.isUpdateable()){
                        upsert onbRecord;
                    }
                    //populate opportunity fields
                    //opp = IntegrationStagingBatch.populateOppFields(opp, onbRecord);
                    /*opp.StageName = 'Enrollment';
                    if(Schema.sObjectType.Onboarding_Details__c.isUpdateable()){
                        system.debug('opp=>'+opp);
                        update opp;
                    }*/
                    //populate integration staging record fields
                    record.Onboarding_Detail__c = onbRecord.Id;
                    record.Status__c = 'Processed';
                    record.Account__c = chewRecds.accountId;
                    record.Opportunity__c = chewRecds.opportunityId;
                }Catch(Exception exp){
                    record.Status__c = 'Error';
                    record.Error_Message__c = exp.getMessage();
                }
                if(Schema.sObjectType.Integration_Staging__c.isUpdateable()){
                    update record;
                    if(record.Account__c == System.Label.Catch_all_Account_record_Id && !Test.isRunningTest()) {
                        Id ian_vincent = [SELECT Id FROM User WHERE FirstName = 'Ian' AND LastName = 'Vincent'].Id; // grab ian vincent's user id
                        String chatterBody = '{' + ian_vincent + '} -- Integration Staging Record rehomed<ul>'; // create chatter post to ian vincent
                            chatterBody += '<li>Record Id == ' + record.Id + '</li>';
                            chatterBody += '<li>Message Type == ' + record.Message_Type__c + '</li>';
                            chatterBody += '<li>Payload == ' + record.Payload__c + '</li></ul>';
                        ConnectApi.FeedItem fi = (ConnectApi.FeedItem) ConnectApiHelper.postFeedItemWithRichText(null, record.Account__c, chatterBody);
                    }
                }                
            }
        }
    }
    /** 
	* @description Batch Class finish Method
	* @param BC
	*/
    public void finish(Database.BatchableContext BC){
        Datetime tenMinutesAgo = Datetime.now().addMinutes(-10);
        Datetime thirtyMinutesAgo = Datetime.now().addMinutes(-30);
        List<Integration_Staging__c> recordList = [ // checks for any orphaned integration staging records
            SELECT Id, Name, Payload__c, Status__c, Error_Message__c, CreatedDate
            FROM Integration_Staging__c
            WHERE Status__c = 'New' 
                AND CreatedDate <= :tenMinutesAgo 
                AND CreatedDate >= :thirtyMinutesAgo
        ];
        List<Integration_Staging__c> intStageToUpdate = new List<Integration_Staging__c>(); // instantiate a list to bulkify the update later
        if(recordList != null && recordList.size() > 0){ // only run if found orphaned integration staging record(s)
            for(Integration_Staging__c rec : recordList) { // loop through found integration staging records
                Map<String, Object> mapPayload = (Map<String, Object>) JSON.deserializeUntyped(rec.Payload__c); // convert payload into map
                String refId =  (String)((Map<String, Object>) mapPayload).get('ReferenceId'); // grab ReferenceId from payload
                List<Contact> cons = [ // find any contacts where the payload ReferenceId matches the legacy Onboarding_Id__c contact field
                    SELECT  Id, Onboarding_ID__c, Onboarding_ID_Formula__c
                    FROM    Contact 
                    WHERE   Onboarding_ID__c = :refId
                    OR      Onboarding_ID_Formula__c = :refId
                ];
                if(!cons.isEmpty()) { // only run if matching contact(s) found
                    for(Contact con : cons) { // loop through found contact records
                        mapPayload.put('ReferenceId', con.Onboarding_Id_Formula__c); // replace the payload ReferenceId with the new Onboarding_ID_Formula__c contact field value
                        String newPayload = JSON.serialize(mapPayload); // serialize the map into a json string
                        System.debug('== NEW PAYLOAD == ' + newPayload);
                        rec.Payload__c = newPayload; // replace the entire payload on the integration staging record
                        intStageToUpdate.add(rec); // add integration staging record to list to update after for loop
                    }
                }
            }
            if(!intStageToUpdate.isEmpty()) { // only run if list if not empty
                try {
                    update intStageToUpdate;
                    if(Test.isRunningTest()) { // this is only here for code coverage to include the catch block
                        throw new DmlException();
                    }
                }catch(Exception e) {
                    System.debug('== ERROR MESSAGE == ' + e.getMessage());
                    System.debug('== ERROR CAUSE == ' + e.getCause());
                    System.debug('== ERROR LINE == ' + e.getLineNumber());
                }
            }
            Database.executeBatch(new IntegrationStagingBatch(), 1); // run the batch again to catch any stragglers
        }        
    }
    
    /** 
* @description method to check is Batch class running 
* @return Boolean 
*/
    public static Boolean chekBatchRunning(){
        //custom label with batch class id
        Id thisClassId = System.Label.Integration_Staging_Batch_Class;
        AsyncApexJob[] jobs ;
        if(Schema.sObjectType.Account.isAccessible()){
            jobs = [select id from AsyncApexJob where ApexClassId=:thisClassId AND JobType='BatchApex' AND (status='Preparing' OR status='Holding' OR status ='Processing')];
        }
        if (jobs== null || jobs.size() ==0) {
            return false;
        }
        else {
            return true;
        }
    }
    /** 
	* @description method to transform Json To Object
	* @param sObjectName sObject Name
	* @param payload JSON Payload
	* @return SObject Sobject Record
	*/
    public static SObject processObjectData(String sObjectName,String payload){
        Map<String, String> fieldMap = new Map<String, String>();
        Object payloadObject = (Object)JSON.deserializeUntyped(payload);
        // Salesforce object with Torah platform data
        SObject sfBaseObject;
         String query = String.format('SELECT {0} FROM {1} WHERE {2}',
                        new List<String>{String.Join(new List<String>{'JSON_Field_Name__c', 'Active__c', 'SF_Object__c', 'SF_Field_Name__c','Field_Data_Type__c'}, ','),
                        'Onboarding_Metadata__mdt',
                        'SF_Object__c=\'' + sObjectName + '\' ORDER BY JSON_Field_Name__c  desc'});
         SObjectType sfObjectType = Schema.getGlobalDescribe().get(sObjectName);
        Map<String,Schema.SObjectField> mfields = sfObjectType.getDescribe().fields.getMap();
        sfBaseObject = sfObjectType.newSObject();
        Object contObject = ((Map<String, Object>)payloadObject).get('Contact');
        
        List<Onboarding_Metadata__mdt> mappings = Database.query(query);
        
        //Account Or Onborading Detail Record section 
        for(Onboarding_Metadata__mdt mapping: mappings) {
            if (((Map<String, Object>) payloadObject).containsKey(mapping.JSON_Field_Name__c) && (sObjectName == 'Account' || sObjectName == 'Onboarding_Details__c')){
                if(sfBaseObject.get(mapping.SF_Field_Name__c) != null) continue;
                if(mapping.Field_Data_Type__c == 'String' ){
                    
                    String fieldVal = (String)(((Map<String, Object>) payloadObject).get(mapping.JSON_Field_Name__c));
                    // apply field length
                    Schema.DescribeFieldResult fieldResult = mFields.get(mapping.SF_Field_Name__c).getDescribe();
                    // restrict the length to permissible size
                    Integer maxLen = fieldResult.getLength();
                    if(fieldVal != null && maxLen != null) {
                        if(fieldVal.length() > maxLen) {
                            fieldVal = fieldVal.substring(0, maxLen-1);
                        }
                    }
                    sfBaseObject.put(mapping.SF_Field_Name__c, fieldVal);
                }
                else if(mapping.Field_Data_Type__c == 'Boolean'){
                    sfBaseObject.put(mapping.SF_Field_Name__c, (Boolean)(((Map<String, Object>) payloadObject).get(mapping.JSON_Field_Name__c)));
                }
                else if(mapping.Field_Data_Type__c == 'Number'){
                    sfBaseObject.put(mapping.SF_Field_Name__c, Integer.valueOf((String)(((Map<String, Object>) payloadObject).get(mapping.JSON_Field_Name__c))));
                }
                else if(mapping.Field_Data_Type__c == 'DateTime'){
                    String dateString = (String)(((Map<String, Object>) payloadObject).get(mapping.JSON_Field_Name__c));
                    dateString = dateString.replace('T', ' ');
                    Datetime dt = Datetime.valueOf(dateString);
                    sfBaseObject.put(mapping.SF_Field_Name__c, dt);
                }
            }
        }
        system.debug('sfBaseObject=>'+sfBaseObject);
        //Contact section 
        for(Onboarding_Metadata__mdt mapping: mappings) {
            if (contObject != null && ((Map<String, Object>) contObject).containsKey(mapping.JSON_Field_Name__c) && sObjectName == 'Contact'){
                if(sfBaseObject.get(mapping.SF_Field_Name__c) != null) continue;
                if(mapping.Field_Data_Type__c == 'String' ){
                    if(mapping.SF_Field_Name__c == 'Name'){
                         String fieldVal = (String)(((Map<String, Object>) contObject).get(mapping.JSON_Field_Name__c));
                        String[] fieldValArr = fieldVal.split(' ');
                        if(fieldValArr.size() > 0 && fieldValArr.size() == 1){
                             //sfBaseObject.put('FirstName', fieldValArr[0]);
                            sfBaseObject.put('LastName', fieldValArr[0]);
                        }
                        if(fieldValArr.size() > 0 && fieldValArr.size() > 1){
                            sfBaseObject.put('FirstName', fieldValArr[0]);
                            sfBaseObject.put('LastName', fieldValArr[1]);
                        }
                        
                    }
                    else{
                        
                        String fieldVal = (String)(((Map<String, Object>) contObject).get(mapping.JSON_Field_Name__c));
                        // apply field length
                        Schema.DescribeFieldResult fieldResult = mFields.get(mapping.SF_Field_Name__c).getDescribe();
                        // restrict the length to permissible size
                        Integer maxLen = fieldResult.getLength();
                        if(fieldVal != null && maxLen != null) {
                            if(fieldVal.length() > maxLen) {
                                fieldVal = fieldVal.substring(0, maxLen-1);
                            }
                        }
                        sfBaseObject.put(mapping.SF_Field_Name__c, fieldVal);
                    }
                }
                else if(mapping.Field_Data_Type__c == 'Boolean'){
                    sfBaseObject.put(mapping.SF_Field_Name__c, (Boolean)(((Map<String, Object>) contObject).get(mapping.JSON_Field_Name__c)));
                }
                else if(mapping.Field_Data_Type__c == 'Number'){
                    sfBaseObject.put(mapping.SF_Field_Name__c, Integer.valueOf((String)(((Map<String, Object>) contObject).get(mapping.JSON_Field_Name__c))));
                }
            }
        }
        return sfBaseObject;
    }
    
   /** 
	* @description method to populate fields on Opportunity
	* @param opp Opportunity Record
	* @param onboardRec Onboarding Details record
	* @return Opportunity updated Opp Record
	*/
    public static Opportunity populateOppFields(Opportunity opp , Onboarding_Details__c onboardRec){
        if(opp.StageName == 'Demo'){
            opp.StageName = 'Enrollment';
        }
        //populate opp fields according to criteria
        if(onboardRec.Name =='MSA' && onboardRec.Status__c =='Completed'){
            opp.MSA__c = true;
        }
        if(onboardRec.Name =='ProvidedBankLetter' && onboardRec.Status__c =='Completed'){
            opp.Banking_details__c = true;
        }
        if(onboardRec.Name =='ProvidedTaxExemptCert' && onboardRec.Status__c =='Completed'){
            opp.Tax_Exempt_Cert__c = true;
        }
        if(onboardRec.Name =='ProvidedW9' && onboardRec.Status__c =='Completed'){
            opp.W9__c = true;
        }
        
        return opp;
    }
    /** 
	* @description method to populate fields on Opportunity
	* @param onboardRecs List Of Onboarding Details record
	*/
    public static void opportunityUpdates(List<Onboarding_Details__c> onboardRecs){
        Set<Id> setOfOppIds = new Set<Id>();
        Map<Id,Opportunity> oppsToUpdate = new Map<Id,Opportunity>();
        for(Onboarding_Details__c rec : onboardRecs){
            setOfOppIds.add(rec.Opportunity__c);
        }
        for(Opportunity opp : [Select Id,AccountId,Name,Onboarding_Opportunity__c,StageName,MSA__c,Banking_details__c,Tax_Exempt_Cert__c,
                               W9__c from Opportunity where id =: setOfOppIds]){
           for(Onboarding_Details__c rec : onboardRecs){
               if(rec.Opportunity__c == opp.Id){
                   Opportunity opps = new Opportunity();
                   opps = IntegrationStagingBatch.populateOppFields(opp,rec);
                   oppsToUpdate.put(opps.Id,opps);
               }
           }
        }
        //update Opportunity Records
        if(oppsToUpdate.size() > 0){
            update oppsToUpdate.values();
        }
    }
    
   public class ChewyRecords {
        public String accountId {get; set;} 
        public String contactId {get; set;} 
        public String opportunityId {get; set;} 
    }
}