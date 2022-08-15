@isTest
public class AssignLeadsUsingAssignmentRulesTest {
    static testMethod void createnewlead() {
    	User userToCreate = [SELECT Id 
                             FROM User 
                             WHERE Profile.Name='System Administrator' 
                             AND IsActive = true
                             LIMIT 1];
      
      	Test.startTest();    
      	Lead leadToCreate = new Lead();
      	List<id> Ids = New List<Id>();
      	leadToCreate.OwnerId = userToCreate.Id;
      	leadToCreate.LastName ='Test123';
      	leadToCreate.Company ='Test456';
      	leadToCreate.LeadSource = 'Landing Page';
      	leadToCreate.Rating = '';
      	leadToCreate.Status = '';
      	insert leadToCreate; 
      
      	Ids.add(leadToCreate.Id);
      	AssignLeadsUsingAssignmentRules.leadAssign(Ids);
      
      	Test.stopTest();
    }
}