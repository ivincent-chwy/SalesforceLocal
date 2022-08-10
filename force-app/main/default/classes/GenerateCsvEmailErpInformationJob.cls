/*******************************************************************************************
* @Name             GenerateCsvEmailErpInformationJob
* @Author           Dominic Vario (source code -- https://www.greytrix.com/blogs/salesforce/2022/02/18/how-to-send-csv-attachment-in-apex-code/)
* @Date             2022-08-04
* @Group            Scheduled Job
* @Description      Bundles context from this report -- https://chewy.lightning.force.com/lightning/r/Report/00O8W000007E0ojUAC/view?queryScope=userFolders
                    -- And sends it as an email attachment to recipients in the ERP Info Recipient Custom Metadata Type every Monday.
                    -- To edit the recipients, create/update records in the ERP Info Recipient Custom Metadata Type.
MODIFICATION LOG
* Version           Developer           Date                Description
*-------------------------------------------------------------------------------------------
* 1.0               Dominic Vario       2022-08-04          Initial development.
* 1.1               Dominic Vario       2022-08-09          Updated WHERE criteria for "accts" Account List.
*******************************************************************************************/

public class GenerateCsvEmailErpInformationJob implements Schedulable {
    public void execute(SchedulableContext SC) {
    /*******************************************************************************************
    * @Method Name      execute (Schedulable Context)
    * @Description      Does a GET on all Accounts meeting criteria, bundles each row into a CSV formatted String, 
                        -- then initializes and sends the email message with attached CSV.
    * @Example          This class will be scheduled to run every Monday morning at 6AM.
    *******************************************************************************************/
        String csv = 'Id,Account Name,Unique Chewy ID,Supplier Name,Supplier ID,Site ID,Account Owner\n';
        for(List<Account> accts : [
            SELECT  Id, Name, Unique_Chewy_Id__c, SupplierName__c, SupplierId__c, SiteId__c, Owner.Name
            FROM    Account
            WHERE   SupplierName__c != NULL
            OR      SupplierId__c != NULL 
            OR      SiteId__c != NULL 
            ]) {
            for(Account acct : accts) {
                csv +=  acct.Id + ',' 
                    +   acct.Name.escapeCsv() + ',' 
                    +   acct.Unique_Chewy_Id__c.escapeCsv() + ',' 
                    +   acct.SupplierName__c.escapeCsv() + ',' 
                    +   acct.SupplierId__c.escapeCsv() + ',' 
                    +   acct.SiteId__c.escapeCsv() + ',' 
                    +   acct.Owner.Name.escapeCsv() 
                    +   '\n';
            }
        }
        System.debug('CsvData == ' + csv); 
        try {
            Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
            Blob csvBlob = blob.valueOf(csv);
            String csvName = 'ERP_Information_Report_' + String.valueOf(System.today()) + '.csv';
            csvAttachment.setFileName(csvName);
            csvAttachment.setBody(csvBlob);
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<String> toAddresses = new List<String>();
            List<String> ccAddresses = new List<String>();
            List<String> bccAddresses = new List<String>();
            List<ErpInfoRecipient__mdt> allRecipients = [
                SELECT  EmailAddress__c, Type__c 
                FROM    ErpInfoRecipient__mdt 
            ];
            for(ErpInfoRecipient__mdt eir : allRecipients) {
                if(eir.Type__c == 'To') {
                    toAddresses.add(eir.EmailAddress__c);
                } else if(eir.Type__c == 'CC') {
                    ccAddresses.add(eir.EmailAddress__c);
                } else if(eir.Type__c == 'BCC') {
                    bccAddresses.add(eir.EmailAddress__c);
                }
            }
            String subject = 'ERP Information Report ' + String.valueOf(System.today());
            email.setSubject(subject);
            email.setToAddresses(toAddresses);
            email.setCcAddresses(ccAddresses);
            email.setBccAddresses(bccAddresses);
            email.setPlainTextBody('Please see the attached ERP Information Report for ' + String.valueOf(System.today()) + '.');
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttachment});
            Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email}); // This line sends the email message.
            for(Messaging.SendEmailResult ser : r) {
                if (ser.success) {
                    System.debug('The email was sent successfully!');
                } else {
                    System.debug('The email failed to send for the following reason(s): ' + ser.getErrors());
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