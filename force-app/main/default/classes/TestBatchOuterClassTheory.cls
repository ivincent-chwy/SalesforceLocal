public class TestBatchOuterClassTheory implements Database.Batchable<String> {
    // PREPARATION
    public List<String> batchList = new List<String>();
    public Integer batchNum = 1;
    // START
    public Iterable<String> start(Database.BatchableContext bc) {
        while(batchNum <= 5){
            batchList.add('batch' + batchNum);
            ++batchNum;
        }
        return batchList;
    }
    // EXECUTE
    public void execute(Database.BatchableContext bc, List<String> batchList) {
        ChewyRecords chewRecds = new ChewyRecords();
        if (batchList[0] == 'batch2') {
            chewRecds.testVariable = 'One';
        }
        System.debug('== BATCH NUMBER == ' + batchList[0]);
        System.debug('== PRINT TEST VARIABLE == ' + chewRecds.testVariable);
    }
    //FINISH
    public void finish(Database.BatchableContext bc) {
        System.debug('TEST COMPLETE');
    }
    //OUTER CLASS
    public class ChewyRecords {
        public String testVariable {get; set;}
    }
}