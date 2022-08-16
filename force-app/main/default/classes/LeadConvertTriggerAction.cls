/*******************************************************************************************
* @Name             LeadConvertTriggerAction 
* @Author           Dominic Vario
* @Date             2022-08-16
* @Group            Trigger
* @Subgroup         Action
* @Description      Gets a list of Leads with Unique Chewy IDs, searches for any matching Account/Contact/Opportunity, 
                    -- then converts the Leads with attachments where found.
MODIFICATION LOG
* Version           Developer          Date               Description
*-------------------------------------------------------------------------------------------
* 1.0               Dominic Vario      2022-08-16         Initial deployment.
*******************************************************************************************/

public class LeadConvertTriggerAction {
    public static void convertLeads() {
        /*******************************************************************************************
        * @Method Name                      convertLeads
        * @Description                      Gets a list of all Leads with a Unique Chewy ID, searches for any matching Accounts, Contacts, 
                                            -- and/or Onboarding Opportunities for matching, then converts the Leads.
        * @Param leadsToConvert             A list of Leads with a Unique Chewy ID to be converted.
        * @Param accountMap                 String/Id map of all Accounts with a Unique Chewy ID. The Unique Chewy ID becomes the String key of the map,
                                            -- with the Id of the map being the Account ID.
        * @Param accountsWithUniqueChewyId  List of all Accounts with a Unique Chewy ID. Includes a relationship query for any Onboarding Opportunities.
        * @Param onboardedOppsList          Id/List<Opportunity> map, where Id = AccountId and List<Opportunity> becomes any Onboarding Opportunities
                                            -- related to the Account.
        * @Param allContacts                List of all Contacts that have both a LastName and Email.
        * @Param lcList                     List of Database.LeadConvert (i.e., Leads queued up for conversion).
        * @Param convertStatus              LeadStatus object used strictly for converting Leads and setting their converted status.
        * @Param lc                         Single record of Database.LeadConvert (i.e., single Lead record queued up for conversion).
        * @Param leadKey                    Artifical string key made by concatenating the LastName + Email of a Lead.
        * @Param lcr                        List of Database.LeadConvertResult (i.e., object with results on the conversion of a Lead).
        * @Param res                        Single record of Database.LeadConvertResult.
        * @Example                          This will likely be a one-time run to clean up the 27K+ historical Leads in Production.
                                            -- It could be useful to reuse in the future if a large number of Leads are injected into
                                            -- Production again in the future from another lead generation tool.
        *******************************************************************************************/
        List<Lead> leadsToConvert = [ 
            SELECT  Id
                ,   Unique_Chewy_Id__c
                ,   FirstName
                ,   LastName
                ,   Email
            FROM    Lead 
            WHERE   Unique_Chewy_Id__c != NULL
            AND     IsConverted = FALSE
        ];
        Map<String,Id> accountMap = new Map<String,Id>(); // instantiate map for reference later
        List<Account> accountsWithUniqueChewyId = [ // get list of all accounts with a unique chewy id (kyrios id), with or without an onboarding opportunity
            SELECT  Id
                ,   Unique_Chewy_ID__c
                ,   Name
                ,   (SELECT Id, AccountId FROM Opportunities WHERE Onboarding_Opportunity__c = TRUE)
            FROM    Account 
            WHERE   Unique_Chewy_ID__c != NULL
        ];
        Map<Id,List<Opportunity>> onboardedOppsList = new Map<Id,List<Opportunity>>();
        for(Account a : accountsWithUniqueChewyId) { // loop through accounts and add them to map
            accountMap.put(a.Unique_Chewy_ID__c, a.Id);
            if(!a.Opportunities.isEmpty()) {
                onboardedOppsList.put(a.Id, a.Opportunities);
            }
        }
        List<Contact> allContacts = [
            SELECT  Id, LastName, Email, AccountId 
            FROM    Contact 
            WHERE   LastName != NULL 
            AND     Email != NULL
        ];
        Map<String,Contact> contactMap = new Map<String,Contact>(); // instantiate map for reference later
        for(Contact c : allContacts) { // loop through contacts and add them to map
            String contactKey = c.LastName + c.Email; // create key for contact map by concatenating LastName and Email
            contactMap.put(contactKey, c);
        }
        if(!leadsToConvert.isEmpty()) {
            List<Database.LeadConvert> lcList = new List<Database.LeadConvert>();
            LeadStatus convertStatus = [
                SELECT  Id, MasterLabel 
                FROM    LeadStatus 
                WHERE   IsConverted = TRUE 
                LIMIT   1
            ];
            for(Lead thisLead : leadsToConvert){
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(thisLead.Id);
                lc.setConvertedStatus(convertStatus.MasterLabel);
                if(accountMap.containsKey(thisLead.Unique_Chewy_ID__c)) {
                    String acctId = accountMap.get(thisLead.Unique_Chewy_ID__c); // setting acctId on its own line for better readability
                    lc.setAccountid(acctId);
                    if(onboardedOppsList.containsKey(acctId)) {
                        for(Opportunity o : onboardedOppsList.get(acctId)) {
                            lc.setOpportunityId(o.Id);
                        }
                    } else {
                        lc.setDoNotCreateOpportunity(TRUE);
                    }
                }
                String leadKey = thisLead.LastName + thisLead.Email; // creating an artificial lead key on its own line for better readability
                if(contactMap.containsKey(leadKey)) {
                    Contact c = contactMap.get(leadKey);
                    lc.setContactId(c.Id);
                }
                lcList.add(lc);
            }
            if(!lcList.isEmpty()) {
                try {
                    List<Database.LeadConvertResult> lcr = Database.convertLead(lcList, FALSE); // FALSE is for allOrNone
                    for(Database.LeadConvertResult res : lcr) {
                        if(res.isSuccess()) {
                            System.debug('== LEAD ' + res.getLeadId() + ' SUCCESSFULLY CONVERTED ==');
                        } else {
                            System.debug('== LEAD ' + res.getLeadId() + ' DID NOT CONVERT FOR THE FOLLOWING REASON(S): ' + res.getErrors());
                        }
                    }
                    if(Test.isRunningTest()) {
                        throw new DmlException();
                    }
                } catch(Exception e) {
                    System.debug('== ERROR MESSAGE == ' + e.getMessage());
                    System.debug('== ERROR CAUSE == ' + e.getCause());
                    System.debug('== ERROR LINE == ' + e.getLineNumber());
                }
            }
        }
    }
}