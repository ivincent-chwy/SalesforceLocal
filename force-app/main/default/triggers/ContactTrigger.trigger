/**
 * RA , 26/09/2021
 * @description Trigger On Contact for generating Tokens
*/
trigger ContactTrigger on Contact (before update, after update, after insert) {
    List<Contact> tokensToGenerate = new List<Contact>();
    for(Contact cn : Trigger.new) {
        if(Trigger.isBefore && Trigger.isUpdate) {
            if(cn.Onboarding_Token__c != NULL && cn.Onboarding_Token__c != '' && (cn.Email == NULL || cn.Account_Name_for_Pardot__c == NULL || cn.Onboarding_ID_formula__c == NULL || cn.Unique_Chewy_ID_NEW__c == NULL)) {
                cn.Onboarding_Token__c = '';
            }
        }
        if(Trigger.isAfter && Trigger.isInsert) {
            if((cn.Onboarding_Token__c == NULL || cn.Onboarding_Token__c == '') && cn.Account_Name_for_Pardot__c != NULL && cn.Onboarding_ID_formula__c != NULL && cn.Unique_Chewy_ID_NEW__c != NULL && cn.Email != NULL) {
                tokensToGenerate.add(cn);
            }
        }
        if(Trigger.isAfter && Trigger.isUpdate) {
            for(Contact co : Trigger.old) {
                if(co.Onboarding_Token__c != cn.Onboarding_Token__c) {
                    continue;
                }
                if((cn.Account_Name_for_Pardot__c != co.Account_Name_for_Pardot__c && cn.Account_Name_for_Pardot__c != NULL) || (cn.Onboarding_Id_formula__c != co.Onboarding_Id_formula__c && cn.Onboarding_Id_formula__c != NULL) || (cn.Unique_Chewy_ID_NEW__c != co.Unique_Chewy_ID_NEW__c && cn.Unique_Chewy_ID_NEW__c != NULL) || (cn.Email != co.Email && cn.Email != NULL)){
                    tokensToGenerate.add(cn);
                }
            }
        }
    }
    if(!tokensToGenerate.isEmpty()){
        HMACTokenManager.generateTokens(tokensToGenerate);
    }
}