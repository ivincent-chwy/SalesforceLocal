/**
 * DV -- 03.25.2022
 * @description Trigger On Lead for generating and updating Onboarding Token
 * LOG 7.21.22 -- Deactivated because Onboarding ID and Token generation moved to Account.
*/
trigger LeadTrigger on Lead (after insert, before update, after update) {
    List<Lead> leadList = new List<Lead>();
    for(Lead ln : trigger.new) {
        Boolean triggerActive = Boolean.valueOf(HMACTokenManager.chewySettingsMap.get('Enable_LeadTrigger').Value__c);
        if(Trigger.isBefore) {
            if(Trigger.isUpdate) {
                if(ln.token__c != null && ln.token__c != '' && oneRunTrigger.check && (ln.Onboarding_Id__c == null || ln.Unique_Chewy_ID__c == null || ln.Company == null || ln.Email == null)) {
                    oneRunTrigger.check = false;
                    ln.token__c = '';
                }
            }
        }
        if(Trigger.isAfter) {
            if(Trigger.isInsert) {
                if(oneRunTrigger.check && triggerActive && ln.Onboarding_Id__c != null && ln.Unique_Chewy_ID__c != null && ln.Company != null && ln.Email != null) {
                    oneRunTrigger.check = false;
                    leadList.add(ln);
                }
            }
            if(Trigger.isUpdate) {
                for(Lead lo : trigger.old) {
                    if(oneRunTrigger.check && triggerActive && ((ln.Onboarding_Id__c != lo.Onboarding_Id__c && ln.Onboarding_Id__c != null) || (ln.Unique_Chewy_ID__c != lo.Unique_Chewy_ID__c && ln.Unique_Chewy_ID__c != null) || (ln.Company != lo.Company && ln.Company != null) || (ln.Email != lo.Email && ln.Email != null))) {
                        oneRunTrigger.check = false;
                        leadList.add(ln);
                    }
                }
            }
        }
    }
    if(leadList.size() > 0) {
        oneRunTrigger.check = false;
        HMACTokenManager.generateTokens(leadList);
    }
}