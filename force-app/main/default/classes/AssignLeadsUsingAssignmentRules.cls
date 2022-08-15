public class AssignLeadsUsingAssignmentRules {
    @InvocableMethod
    public static void LeadAssign(List<Id> LeadIds)
    {
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule= true;          
            Lead Leads=[SELECT Id 
                          FROM Lead 
                         WHERE Lead.Id IN :LeadIds];
            Leads.setOptions(dmo);
            update Leads;
   }
}