/** �ltal�nos c�l� k�nyelmi met�dusok.
 * @author		mate.safranka@attentioncrm.hu
 * @version		1
 * @created		2014-12-05 (SM)
 * @updated		2015-05-04 (SM)
 */
public with sharing class AUtil {

	public class IllegalArgumentException extends Exception {}
	
	/**
	*A f�ld sugara kil�m�terben. calculateDistance f�ggv�nyhez kell
	*/
	public static final double R = 6371.00;
	
	/** Tetsz�leges String bemenetben felismeri a merge field szintaxist �s behelyettes�ti az �rt�kekekt a megadott objektumokb�l.
	 * A feldolgozand� Stringet a konstruktornak, vagy legk�s�bb a prepare() met�dusnak kell megadni.
	 * Ezut�n a parse() met�dusnak kell �tadni egy String-sObject p�rokb�l �ll� t�bl�t, amelyb�l ki tudja nyerni a sz�ks�ges adatokat.
	 * Egy MergeFieldParser t�bbsz�r is felhaszn�lhat�.
	 * Ha ugyanazt a Stringet szeretn�nk t�bbsz�r, k�l�nb�z� objektumokkal feldolgozni, el�g csak a parse() met�dust �jra megh�vni.
	 * Ha m�sik Stringet szeretn�nk feldolgozni, el�bb meg �jra kell h�vni a perpare() met�dust, azut�n j�het a parse().
	 *
	 * Csak k�zvetlen�l el�rhet� mez�ket tud helyettes�teni (pl. Invoice__c.Name igen, Invoice__c.Travel_Proposal__r.Name nem).
	 * Feldolgoz�skor nem ellen�rzi, hogy a megadott mez�k val�ban l�teznek-e, ez a felhaszn�l� felel�ss�ge.
	 */
	public class MergeFieldParser {
		private final Integer TOKEN_LEFT_BRACE = 123;
		private final Integer TOKEN_RIGHT_BRACE = 125;
		private final Integer TOKEN_EXCLAMATION = 33;
	
		private List<String> pieces;
		private List<Boolean> pieceIsField;
		private Boolean firstPieceIsField;
	
		public MergeFieldParser() {}
		public MergeFieldParser(String source) {
			prepare(source);
		}
		
		public void prepare(String source) {
			pieces = new List<String>();
			pieceIsField = new List<Boolean>();
			firstPieceIsField = false;
			
			Boolean inField = false;
			Integer length = source.length();
			Integer copyFrom = 0;
			Integer copyTo = 0;
			for (Integer i = 0; i < length; i++) {
				if (!inField) {
					if (source.charAt(i) == TOKEN_LEFT_BRACE && i < length-1 && source.charAt(i+1) == TOKEN_EXCLAMATION) {
						pieces.add(source.subString(copyFrom, copyTo));
						pieceIsField.add(false);
						
						copyFrom = i + 2;
						copyTo = copyFrom;
						i++;
						
						inField = true;
						if (i == 0) firstPieceIsField = true;
					}
					else {
						copyTo = i + 1;
					}
				}
				else {
					if (source.charAt(i) == TOKEN_RIGHT_BRACE) {
						pieces.add(source.subString(copyFrom, copyTo));
						pieceIsField.add(true);
						
						copyFrom = i + 1;
						copyTo = copyFrom;
						inField = false;
					}
					else {
						copyTo = i + 1;
					}
				}
			}
			
			if (copyFrom != copyTo) {
				pieces.add(source.subString(copyFrom, copyTo));
				pieceIsField.add(false);
			}
		}
		
		public String parse(Map<String, sObject> objects) {
			List<String> outPieces = pieces.clone();
			
			for (Integer i = 0; i < outPieces.size(); i++) if (pieceIsField[i]) {
				String field = outPieces[i];
				String objectName = field.substringBefore('.');
				String fieldName = field.subStringAfter('.');
				outPieces[i] = String.valueOf(objects.get(objectName).get(fieldName));
			}
			
			return String.join(outPieces, '');
		}
	
	}

	/** Sz�m �talak�t�sa stringg� "sz�pen", ezres tagol�ssal, a megadott sz�m� tizedesjegyre kerek�tve. Null �rt�kre null�t ad vissza.
	 * @param n Az �talak�tand� sz�m
	 * @param accuracy Tizedesjegyek sz�ma az outputban
	 * @param separator A tizedesjegyeket lev�laszt� karakter (pl. pont vagy vessz�)
	 */
    public static String formatNumber(Decimal n, Integer accuracy, String separator) {
        if (n == null) {
			if(accuracy == 0) return '0';
        	String prettyText = '0' + separator;
        	return prettyText.rightPad(accuracy + 2).replace(' ', '0');
        }
        
        n = n.setScale(accuracy, RoundingMode.HALF_UP);
        String base = String.valueOf(Math.abs(n));
        String prettyText = '';
        
        if (accuracy > 0) {
            prettyText = separator + base.substringAfterLast('.');
        }
        base = base.substringBeforeLast('.');
        
        Integer copyTo = base.length();
        Integer copyFrom = copyTo - 3;
        do {
            if (copyFrom < 0) copyFrom = 0;
            if (copyTo != base.length()) prettyText = ' ' + prettyText;
            prettyText = base.substring(copyFrom, copyTo) + prettyText;
            copyFrom -= 3;
            copyTo -= 3;
        } while(copyTo > 0);
        
        if (n < 0) prettyText = '-' + prettyText;
        return prettyText;
    }
    
    public static String formatNumber(Decimal n) {
    	return formatNumber(n, 0, ',');
    }
    
    public static final Integer TOKEN_0 = 48;
    public static final Integer TOKEN_A = 65;
    public static final Integer TOKEN_Am = 97;
    
    /** �tv�lt�s t�zes sz�mrendszerb�l tetsz�leges (max. 36-os) sz�mrendszerbe.
     * @param n Az �tv�ltand� sz�m
     * @param base A c�lsz�mrendszer alapja
     * @return Az �tv�ltott sz�m Stringk�nt. 10-n�l nagyobb alap eset�n sz�mjegyekb�l �s bet�kb�l �ll
     * @throws IllegalArgumentException Ha a base �rt�ke [2, 36]-on k�v�l esik
     */
    public static String toBaseN(Integer n, Integer base) {
    	if (base == null || base < 2 || base > 62) throw new IllegalArgumentException();
    	
    	List<Integer> charCodes = new List<Integer>();
    	while (n > 0) {
    		Integer rawDigit = Math.mod(n, base);
    		if (rawDigit < 10) rawDigit += TOKEN_0;
    		else if (rawDigit < 36) rawDigit = rawDigit - 10 + TOKEN_A;
    		else rawDigit = rawDigit - 36 + TOKEN_Am;
    		charCodes.add(rawDigit);
    		
    		n /= base;
    	}
    	
    	List<Integer> revCodes = new List<Integer>();
    	for (Integer i = charCodes.size() - 1; i >= 0; i--) {
    		revCodes.add(charCodes[i]);
    	}
    	
    	return String.fromCharArray(revCodes);
    }
     
    /** �tv�lt�s tetsz�leges (max. 36-os sz�mrendszerb�l) t�zesbe.
     * @param n Az �tv�ltand� sz�m Stringk�nt
     * @param base Az alapsz�mrendszer
     * @return Az �tv�ltott sz�m
     * @throws IllegalArgumentException Ha n nem a megadott sz�mrendszerbeli sz�m vagy a base �rt�ke [2, 36]-on k�v�l esik
     */
    public static Integer fromBaseN(String n, Integer base) {
    	if (base == null || base < 2 || base > 62) throw new IllegalArgumentException();
    	
    	Integer result = 0;
    	Integer multiplier = 1;
    	Integer[] charCodes = n.getChars();
    	for (Integer i = charCodes.size() - 1; i >= 0; i--) {
    		Integer rawDigit = charCodes[i];
    		if (rawDigit >= TOKEN_Am) rawDigit = 36 + rawDigit - TOKEN_Am;
    		else if (rawDigit >= TOKEN_A) rawDigit = 10 + rawDigit - TOKEN_A;
    		else rawDigit -= TOKEN_0;
    		
    		if (rawDigit > base) throw new IllegalArgumentException();
    		result += multiplier * rawDigit;
    		multiplier *= base;
    	}
    	
    	return result;
    }
    
    /** Egyszer� sz�veges e-mail k�ld�se egyetlen c�mzettnek. Els�sorban debugging c�lokra javasolt.
     * @param address C�mzett e-mail c�me
     * @param subject T�rgy
     * @param body Sz�veg
     */
    
    public static void quickMail(String address, String subj, String body) {
    	Messaging.singleEmailMessage mail = new Messaging.SingleEmailMessage();
    	mail.setToAddresses(new String[] { address });
    	mail.setSubject(subj);
    	mail.setPlainTextBody(body);
    	
    	Messaging.sendEmail(new Messaging.Singleemailmessage[] { mail });
    }

	/** Meg�llap�tja, hogy sandboxban vagyunk-e. */
	public static boolean isSandbox() {
		String sfHost = System.URL.getSalesforceBaseUrl().getHost();
		return Pattern.matches('(.*\\.)?cs[0-9]*(-api)?\\..*force.com', sfHost);
	}
	
	/** Rekordt�psok felismer�se id vagy n�v alapj�n
	 * @author adam.bobor@attentioncrm.hu
	 */
    public static Id recognizeRecordTypeId(string objectNameParam, string recordTypeNameParam) {
        id recordTypeId;
        string OBJECTNAME;
        string RECORDTYPENAME;
        
        OBJECTNAME = objectNameParam;
        RECORDTYPENAME = recordTypeNameParam;
        
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(OBJECTNAME);
        SObject sObj = sObjectType.newSObject();
        Schema.DescribeSObjectResult describeResult = sObj.getSObjectType().getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeMap = describeResult.getRecordTypeInfosByName();
        
        Schema.RecordTypeInfo recordTypeRes;
        
        if(recordTypeMap.containsKey(RECORDTYPENAME)) {
            recordTypeRes = recordTypeMap.get(RECORDTYPENAME);
            recordTypeId = recordTypeRes.getRecordTypeId(); 
        }
        
        return recordTypeId;
    }
    
    public static String recognizeRecordTypeName(string objectNameParam, string recordTypeIdParam) {
        string recordTypeName;
        string OBJECTNAME;
        string RECORDTYPEID;
        
        OBJECTNAME = objectNameParam;
        RECORDTYPEID = recordTypeIdParam;
        
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(OBJECTNAME);
        SObject sObj = sObjectType.newSObject();
        Schema.DescribeSObjectResult describeResult = sObj.getSObjectType().getDescribe();
        Map<Id, Schema.RecordTypeInfo> recordTypeMap = describeResult.getRecordTypeInfosById();
        
        Schema.RecordTypeInfo recordTypeRes;
        
        if(recordTypeMap.containsKey(RECORDTYPEID)) {
            recordTypeRes = recordTypeMap.get(RECORDTYPEID);
            recordTypeName = recordTypeRes.getName();   
        }
        
        return recordTypeName;
    }
}