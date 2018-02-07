/** Tesztek az AUtil oszt�lyhoz.
 * MINDEN met�dusnak �s oszt�lynak 100% lefedetts�ggel kell rendelkeznie! 
 *
 * @author		Attention CRM <attention@attentioncrm.hu>
 * @created		2014-12-08 (SM)
 * @related		AUtil.cls
 */
@isTest
private class testAUtil {

	@isTest
    static void testNumberFormatWSingleParam() {
    	Decimal n = 21341.1223000;
    	String s = AUtil.formatNumber(n);
    	System.assertEquals('21 341', s);
    }

    static testMethod void testMergeFieldParser() {
    	AUtil.MergeFieldParser parser = new AUtil.MergeFieldParser();
    	
    	// No fields
    	String source1 = 'Hello world';
    	parser.prepare(source1);
    	
    	String result1 = parser.parse(null);
    	System.assertEquals(result1, source1);
    	
    	// Normal use
    	Account acc1 = new Account(
    		Name = 'Gordon Freeman',
    		Phone = '12345679'
    	);
    	Account acc2 = new Account(
    		Name = 'Chell',
    		Phone = '789456123'
    	);
    	
    	String source2 = 'Hello {!account.Name}, your phone number is {!account.Phone}.';
    	parser = new AUtil.MergeFieldParser(source2);
    	
    	String result2 = parser.parse(new Map<String, sObject>{ 'account' => acc1 });
    	System.assertEquals(result2, 'Hello ' + acc1.Name + ', your phone number is ' + acc1.Phone + '.');
    	
    	result2 = parser.parse(new Map<String, sObject>{ 'account' => acc2 });
    	System.assertEquals(result2, 'Hello ' + acc2.Name + ', your phone number is ' + acc2.Phone + '.');
    	
    	// Field first and last
    	String source3 = '{!account.Name}, your phone number is {!account.Phone}';
    	parser.prepare(source3);
    	
    	String result3 = parser.parse(new Map<String, sObject>{ 'account' => acc1 });
    	System.assertEquals(result3, acc1.Name + ', your phone number is ' + acc1.Phone);
    }
    
    static testMethod void testFormatNumber() {
    	String num1 = AUtil.formatNumber(123456.789, 2, ',');
    	System.assertEquals(num1, '123 456,79');
    	
    	String num2 = AUtil.formatNumber(null, 3, ':');
    	System.assertEquals(num2, '0:000');
    }
    
    static testMethod void testBaseN() {
    	String a2 = AUtil.toBaseN(255, 2); system.assertEquals(a2, '11111111');
    	String a16 = AUtil.toBaseN(26, 16); system.assertEquals(a16, '1A');
    	String a50 = AUtil.toBaseN(48, 50); system.assertEquals(a50, 'm');
    	
    	Integer b2 = AUtil.fromBaseN('01001010', 2); system.assertEquals(b2, 74);
    	Integer b16 = AUtil.fromBaseN('4A', 16); system.assertEquals(b16, 74);
    	Integer b50 = AUtil.fromBaseN('1b', 50); system.assertEquals(b50, 87);
    }
    
    static testMethod void testQuickMail() {
    	//AUtil.quickMail('okossag@attentioncrm.hu', 'AttnUtil Test', 'Email test successful.');
    }
    
    static testMethod void testIsSandbox() {
    	AUtil.isSandbox();
    }
    
    @isTest(seeAllData=true)
    static void testRecordTypeRecognizer()  {
    	id recordTypeId;
    	string SOBJECTNAME;
    	string RECORDTYPENAME;
    	string recordTypeName2;
    	List<RecordType> recordTypeList = new List<RecordType>();
    	Map<string, recordType> recordTypeNameMap = new Map<string, recordType>();
    	
    	SOBJECTNAME = 'Account';
    	//RECORDTYPENAME = '�gyf�l';
		RECORDTYPENAME = 'Ügyfél';
    	
    	recordTypeList = [ SELECT Id, Name FROM RecordType WHERE SobjectType = :SOBJECTNAME ];
    	
    	for(RecordType currentRecordType : recordTypeList)
    	{
    		recordTypeNameMap.put(currentRecordType.Name, currentRecordType);
    	}
    	
    	recordTypeId = AUtil.recognizeRecordTypeId(SOBJECTNAME, RECORDTYPENAME);
    	system.assertEquals(recordTypeNameMap.get(RECORDTYPENAME).Id, recordTypeId);
    	
    	recordTypeName2 = AUtil.recognizeRecordTypeName(SOBJECTNAME, recordTypeId);
    	system.assertEquals(RECORDTYPENAME, recordTypeName2);
    }
}