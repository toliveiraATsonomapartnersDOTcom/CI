@isTest
private class Test_AffiliationsGridController {
    private static final integer personAccountAffiliationsCount = 3;
    @testSetup
    static void makeData(){
        upsert TestUtils.getRecordTypeIdSettings();
        Map<string, Id> recordTypeIdsByDeveloperName = RecordTypeCommon.GetRecordTypeIdsByDeveloperNames(
            'account', new List<string> {AccountRecordTypes.Council, AccountRecordTypes.GSUSA,
            AccountRecordTypes.Troop,PersonAccountRecordTypes.Youth});

        List<Account> accounts = new List<Account>();
        List<Account> councilAccounts = TestUtils.createAccounts(5, 
            recordTypeIdsByDeveloperName.get(AccountRecordTypes.Council));

        List<Individual> individuals = TestUtils.createIndividuals(3);
        List<Account> personAccounts = TestUtils.CreatePersonAccounts(individuals,
            recordTypeIdsByDeveloperName.get(PersonAccountRecordTypes.Youth));
            
        Account nonPersonAccount = TestUtils.createAccounts(1,
            recordTypeIdsByDeveloperName.get(AccountRecordTypes.GSUSA))[0];

        accounts.addAll(councilAccounts);
        accounts.addAll(personAccounts);
        accounts.add(nonPersonAccount);
        insert accounts;
        
        Account troopAccount = TestUtils.createAccounts(1,
            recordTypeIdsByDeveloperName.get(AccountRecordTypes.Troop))[0];
        troopAccount.Council__c = councilAccounts[4].Id;
        troopAccount.ShippingPostalCode = '60195';
        insert troopAccount;
        
        List<Job_Template__c> jobTemplates = TestUtils.createJobTemplates(2,System.today()+1,System.today()+15);
        jobTemplates[0].Troop_or_Council__c = councilAccounts[0].Id;

        jobTemplates[1].Troop_or_Council__c = troopAccount.Id;

        insert jobTemplates;

        List<Affiliation__c> affiliations = new List<Affiliation__c>();
        affiliations.add(TestUtils.createAffiliation(councilAccounts[0], personAccounts[0],'Relationship Owner'));
        
        affiliations.add(TestUtils.createAffiliation(personAccounts[0], councilAccounts[1],'Council'));
        
        affiliations.add(TestUtils.createAffiliation(councilAccounts[2], personAccounts[0],'Area'));
        
        affiliations.add(TestUtils.createAffiliation(nonPersonAccount, councilAccounts[0],'Area'));
        affiliations.add(TestUtils.createAffiliation(councilAccounts[1], nonPersonAccount,'Area'));

        affiliations.add(TestUtils.createAffiliation(personAccounts[2], councilAccounts[3],'Council'));
        
        affiliations.add(TestUtils.createAffiliation(personAccounts[2], councilAccounts[3],'Job Assignment'));
        affiliations[6].Job_Template__c = jobTemplates[0].Id;

        affiliations.add(TestUtils.createAffiliation(troopAccount, personAccounts[2],'Job Assignment'));
        affiliations[7].Job_Template__c = jobTemplates[1].Id;
        insert affiliations;
    }

    @isTest
    private static void Test_AffiliationsGridController_RetrieveTableDataForJobAssignmentPersonAccount() {
        Account account = retrievePersonAccountForJobAssignment();

        testAffiliationsRetrieveTableDataForJobAssignment(account.Id, 2, 'Job Assignment');
    }

     @isTest
    private static void Test_AffiliationsGridController_RetrieveTableDataForJobAssignmentPersonAccount_NoFilter() {
        Account account = retrievePersonAccountForJobAssignment();

        testAffiliationsRetrieveTableDataForJobAssignment_NoIncludeFilter(account.Id, 2, null);
    }

    @isTest
    private static void Test_AffiliationsGridController_RetrieveTableDataForJobAssignmentTroopAccount() {
        Account account = retrieveTroopAccountForJobAssignment();

        testAffiliationsRetrieveTableDataForJobAssignment_TroopAccount(account.Id, 1, 'Job Assignment');
    }


    @isTest
    private static void Test_AffiliationsGridController_RetrieveTableDataPersonAccount() {
        Account account = retrievePersonAccount();

        testAffiliationsRetrieveTableData(account.Id, personAccountAffiliationsCount);
    }

    @isTest
    private static void Test_AffiliationsGridController_RetrieveTableDataPersonAccount_FilteredToOneType() {
        Account account = retrievePersonAccount();
        testAffiliationsRetrieveTableData(account.Id, 1, 'Relationship Owner');
    }

    @isTest
    private static void Test_AffiliationsGridController_RetrieveTableDataPersonAccount_FilteredToTwoTypes() {
        Account account = retrievePersonAccount();
        testAffiliationsRetrieveTableData(account.Id, 2, 'Relationship Owner, Council');
    }

    @isTest
    private static void Test_AffiliationsGridController_RetrieveTableDataPersonAccount_FilteredToThreeTypes() {
        Account account = retrievePersonAccount();
        testAffiliationsRetrieveTableData(account.Id, personAccountAffiliationsCount,
            'Relationship Owner, Council,Area');
    }

    @isTest
    private static void Test_AffiliationsGridController_RetrieveTableDataPersonAccount_FilteredInvalidTypes() {
        Account account = retrievePersonAccount();
        testAffiliationsRetrieveTableData(account.Id, 0, 'abc;Relationship Owner');
    }

    @isTest
    private static void Test_AffiliationsGridController_RetrieveTableDataPersonAccountNoData() {
        Account account = [SELECT Id
                           FROM Account
                           WHERE IsPersonAccount = true
                           AND LastName = 'Test 1'
                           LIMIT 1];

        testAffiliationsRetrieveTableData(account.Id, 0);
    }

    @isTest
    private static void Test_AffiliationsGridController_RetrieveTableDataNonpersonAccount() {
        Account account = [SELECT Id
                           FROM Account
                           WHERE RecordType.DeveloperName =: AccountRecordTypes.GSUSA
                           LIMIT 1];

        testAffiliationsRetrieveTableData(account.Id, 2);
    }

    @isTest
    private static void Test_AffiliationsGridController_RetrieveTableDataCouncilAccountTwoRecords() {
        Account account = [SELECT Id
                           FROM Account
                           WHERE RecordType.DeveloperName =: AccountRecordTypes.Council
                           AND Name = 'Test Account 0'
                           LIMIT 1];

        testAffiliationsRetrieveTableData(account.Id, 2);
    }

    @isTest
    private static void Test_AffiliationsGridController_RetrieveTableDataCouncilAccountTwoRecordsTwo() {
        Account account = [SELECT Id
                           FROM Account
                           WHERE RecordType.DeveloperName =: AccountRecordTypes.Council
                           AND Name = 'Test Account 1'
                           LIMIT 1];

        testAffiliationsRetrieveTableData(account.Id, 2);
    }

    @isTest
    private static void Test_AffiliationsGridController_RetrieveTableDataCouncilAccountOneRecord() {
        Account account = [SELECT Id
                           FROM Account
                           WHERE RecordType.DeveloperName =: AccountRecordTypes.Council
                           AND Name = 'Test Account 2'
                           LIMIT 1];

        testAffiliationsRetrieveTableData(account.Id, 1);
    }

    @isTest
    private static void Test_AffiliationsGridController_IgnoreDuplicateAffiliation() {
        Affiliation__c affiliation = retrieveAffiliationForDuplicateTest();
        
        Affiliation__c duplicateAffilication = TestUtils.createAffiliation(affiliation.Account__c, affiliation.Account2__c);
        duplicateAffilication.Type__c = affiliation.Type__c;
        duplicateAffilication.Active__c = affiliation.Active__c;

        insert duplicateAffilication;

        testAffiliationsRetrieveTableData(affiliation.Account2__c, personAccountAffiliationsCount);
    }

    @isTest
    private static void Test_AffiliationsGridController_IgnoreDuplicateAffiliationReversedLookup() {
        Affiliation__c affiliation = retrieveAffiliationForDuplicateTest();
        
        Affiliation__c duplicateAffilication = TestUtils.createAffiliation(affiliation.Account2__c,
            affiliation.Account__c);
        duplicateAffilication.Type__c = affiliation.Type__c;
        duplicateAffilication.Active__c = affiliation.Active__c;

        insert duplicateAffilication;

        testAffiliationsRetrieveTableData(affiliation.Account2__c, personAccountAffiliationsCount);
    }

    @isTest
    private static void Test_AffiliationsGridController_AllowDuplicateAffiliationInactive() {
        Affiliation__c affiliation = retrieveAffiliationForDuplicateTest();
        
        Affiliation__c duplicateAffilication = TestUtils.createAffiliation(affiliation.Account2__c,
            affiliation.Account__c);
        duplicateAffilication.Type__c = affiliation.Type__c;
        duplicateAffilication.Active__c = !affiliation.Active__c;

        insert duplicateAffilication;

        testAffiliationsRetrieveTableData(affiliation.Account2__c, personAccountAffiliationsCount + 1);
    }

    @isTest
    private static void Test_AffiliationsGridController_AllowDuplicateAffiliationDifferntType() {
        Affiliation__c affiliation = retrieveAffiliationForDuplicateTest();
        
        Affiliation__c duplicateAffilication = TestUtils.createAffiliation(affiliation.Account2__c,
            affiliation.Account__c);
        duplicateAffilication.Type__c = 'Troop';
        duplicateAffilication.Active__c = affiliation.Active__c;

        insert duplicateAffilication;

        testAffiliationsRetrieveTableData(affiliation.Account2__c, personAccountAffiliationsCount + 1);
    }

    @isTest
    private static void Test_AffiliationsGridController_ConvertDataType_Boolean() {
        testConvertDataType(Schema.DisplayType.BOOLEAN, 'boolean');
    }

    @isTest
    private static void Test_AffiliationsGridController_ConvertDataType_Currency() {
        testConvertDataType(Schema.DisplayType.CURRENCY, 'currency');
    }

    @isTest
    private static void Test_AffiliationsGridController_ConvertDataType_Date() {
        testConvertDataType(Schema.DisplayType.DATE, 'date-local');
    }

    @isTest
    private static void Test_AffiliationsGridController_ConvertDataType_Datetime() {
        testConvertDataType(Schema.DisplayType.DATETIME, 'date');
    }

    @isTest
    private static void Test_AffiliationsGridController_ConvertDataType_Email() {
        testConvertDataType(Schema.DisplayType.EMAIL, 'email');
    }

    @isTest
    private static void Test_AffiliationsGridController_ConvertDataType_Double() {
        testConvertDataType(Schema.DisplayType.DOUBLE, 'number');
    }

    @isTest
    private static void Test_AffiliationsGridController_ConvertDataType_Integer() {
        testConvertDataType(Schema.DisplayType.INTEGER, 'number');
    }

    @isTest
    private static void Test_AffiliationsGridController_ConvertDataType_Long() {
        testConvertDataType(Schema.DisplayType.LONG, 'number');
    }

    @isTest
    private static void Test_AffiliationsGridController_ConvertDataType_Percent() {
        testConvertDataType(Schema.DisplayType.PERCENT, 'percent');
    }

    @isTest
    private static void Test_AffiliationsGridController_ConvertDataType_Phone() {
        testConvertDataType(Schema.DisplayType.PHONE, 'phone');
    }

    @isTest
    private static void Test_AffiliationsGridController_ConvertDataType_Reference() {
        testConvertDataType(Schema.DisplayType.REFERENCE, 'url');
    }

    @isTest
    private static void Test_AffiliationsGridController_ConvertDataType_URL() {
        testConvertDataType(Schema.DisplayType.URL, 'url');
    }

    @isTest
    private static void Test_AffiliationsGridController_ConvertDataType_String() {
        testConvertDataType(Schema.DisplayType.STRING, 'text');
    }

    // The tests below use SObjectType with strong references to fields to force tests to be
    // updated if fields are deleted.
    @isTest
    private static void Test_AffiliationsGridController_RetrieveLookupLabel_Account() {
        Schema.DescribeFieldResult accountField = SObjectType.Affiliation__c.fields.Account__c;
        testRetrieveLookupLabel(accountField.getName(), string.format('{0}.Name', 
            new List<string> {accountField.getRelationshipName()})); 
    }
    
    @isTest
    private static void Test_AffiliationsGridController_RetrieveLookupLabel_LookupFieldOnAccountLookup() {
        Schema.DescribeFieldResult accountField = SObjectType.Affiliation__c.fields.Account__c;
        Schema.DescribeFieldResult createdByField = SObjectType.Account.fields.CreatedById;
        string path = string.format('{0}.{1}', new List<string> {accountField.getRelationshipName(),
            createdByField.getName()});

        testRetrieveLookupLabel(path, path);
    }

    @isTest
    private static void Test_AffiliationsGridController_getJsonFieldValue_NonLookup() {
        Affiliation__c affiliation = [SELECT Id, Type__c
                                      FROM AFfiliation__c
                                      WHERE Type__c = 'Relationship Owner'
                                      LIMIT 1];
        
        testAddJsonFieldValue(affiliation, 'Type__c', 'Type', false, 'Type', 'Relationship Owner');
    }

    @isTest
    private static void Test_AffiliationsGridController_getJsonFieldValue_Url() {
        Affiliation__c affiliation = [SELECT Id
                                      FROM AFfiliation__c
                                      LIMIT 1];
        
        testAddJsonFieldValue(affiliation, 'Id', 'Name', true, 'Name',
            string.format('/{0}', new List<object> {affiliation.Id}));
    }

    @isTest
    private static void Test_AffiliationsGridController_getJsonFieldValue_Relationship() {
        Affiliation__c affiliation = [SELECT Id, Account__r.Name
                                      FROM AFfiliation__c
                                      LIMIT 1];
        
        testAddJsonFieldValue(affiliation, 'Account__r.Name', 'Account__rName', false, 
            'Account__rName',affiliation.Account__r.Name);
    }

    @isTest
    private static void Test_AffiliationsGridController_getJsonFieldValue_NullRelationship() {
        Account account = [SELECT Id, Ceo__r.Name
                           FROM Account
                           WHERE Ceo__c = NULL
                           LIMIT 1];
        
        testAddJsonFieldValue(account, 'Ceo__r.Name', 'Ceo__rName', false, 'Ceo__rName', null);
    }

    @isTest
    private static void Test_AffiliationsGridController_getJsonFieldValue_NullValue() {
        Account account = [SELECT Id, Fax
                           FROM Account
                           WHERE Fax = NULL
                           LIMIT 1];
        
        testAddJsonFieldValue(account, 'Fax', 'Fax', false, 'Fax', null);
    }

    @isTest
    private static void Test_AffiliationsGridController_buildParsedAffiliationForAccount() {
        Affiliation__c affiliation = [
            SELECT Id, Name, Type__c, Account__c, Account2__c, Account2__r.Name
            FROM Affiliation__c
            WHERE Name != null
            AND Type__c != null
            AND Account__c != null
            LIMIT 1];

        Set<string> soqlColumns = new Set<string> {'Name', 'Id', 'Type__c', 'Account__c',
            'Account2__c', 'Account2__c.Name'};

        testBuildParsedAffiliation(soqlColumns, affiliation, affiliation.Account__c,
            affiliation.Account2__c, affiliation.Account2__r.Name);
    }

    @isTest
    private static void Test_AffiliationsGridController_buildParsedAffiliationForAccount2() {
        Affiliation__c affiliation = [
            SELECT Id, Name, Type__c, Account2__c, Account__c, Account__r.Name
            FROM Affiliation__c
            WHERE Name != null
            AND Type__c != null
            AND Account__c != null
            LIMIT 1];

        Set<string> soqlColumns = new Set<string> {'Name', 'Id', 'Type__c', 'Account__c',
            'Account__c.Name', 'Account2__c'};

        testBuildParsedAffiliation(soqlColumns, affiliation, affiliation.Account2__c,
            affiliation.Account__c, affiliation.Account__r.Name);
    }

    @isTest
    private static void Test_AffiliationsGridController_buildParsedAffiliationForJobTemplateInParticipationAssignmentUnderPerson() {
        Affiliation__c affiliation = [
            SELECT Id, Name, Type__c, Account2__c, Account__c, Account__r.Name,Job_Template__c,Job_Template__r.Name
            FROM Affiliation__c
            WHERE Name != null
            AND Type__c = 'Job Assignment'
            AND Account2__r.IsPersonAccount = true
            LIMIT 1];
        
        affiliation.Account__c = null;

        update affiliation;

        Set<string> soqlColumns = new Set<string> {'Name', 'Id', 'Type__c', 'Account__c',
            'Account__c.Name', 'Account2__c','Job_Template__c','Job_Template__r.Name'};

        testBuildParsedAffiliation(soqlColumns, affiliation, affiliation.Account2__c,
            affiliation.Account__c, affiliation.Account__r.Name);
    }

    @isTest
    private static void Test_AffiliationsGridController_setupAffiliationTableColumn_NameField() {
        string label = Affiliation__c.fields.Name.getDescribe().getLabel();
        testSetupAffiliationTableColumn(label, 'Name', Schema.DisplayType.STRING,
            new Set<string>{'Id', 'Name'}, 'Id', 'url', 'Id', 'Name', 'Name', 'Name', label);
    }

    @isTest
    private static void Test_AffiliationsGridController_setupAffiliationTableColumn_NonnameOrReference() {
        string label = Affiliation__c.fields.Type__c.getDescribe().getLabel();
        testSetupAffiliationTableColumn(label, 'Type__c', Schema.DisplayType.STRING,
            new Set<string> {'Type__c'}, 'Type__c', 'text', 'Type__c', null, null, null, label);
    }

    @isTest
    private static void Test_AffiliationsGridController_setupAffiliationTableColumn_Account() {
        testSetupAffiliationTableColumn(Affiliation__c.fields.Account__c.getDescribe().getLabel(),
            'Account__c', Schema.DisplayType.REFERENCE, new Set<string> {'Account__c', 'Account__r.Name'},
            AffiliationsGridController.accountColumnName, 'url', AffiliationsGridController.accountColumnName,
            AffiliationsGridController.accountLabelFieldName, 
            AffiliationsGridController.accountLabelFieldName,
            AffiliationsGridController.accountLabelFieldName,
            AffiliationsGridController.accountLabel);
    }

    @isTest
    private static void Test_AffiliationsGridController_setupAffiliationTableColumn_Account2() {
        testSetupAffiliationTableColumn(Affiliation__c.fields.Account2__c.getDescribe().getLabel(),
            'Account2__c', Schema.DisplayType.REFERENCE, 
            new Set<string> {'Account2__c', 'Account2__r.Name'}, 
            AffiliationsGridController.accountColumnName, 'url',
            AffiliationsGridController.accountColumnName,
            AffiliationsGridController.accountLabelFieldName, 
            AffiliationsGridController.accountLabelFieldName,
            AffiliationsGridController.accountLabelFieldName,
            AffiliationsGridController.accountLabel);
    }

    @isTest
    private static void Test_AffiliationsGridController_setupAffiliationTableColumn_Reference() {
        string label = Affiliation__c.fields.CreatedById.getDescribe().getLabel();
        testSetupAffiliationTableColumn(label, 'CreatedById', Schema.DisplayType.REFERENCE,
            new Set<string> {'CreatedById', 'CreatedBy.Name'}, 'CreatedById', 'url',
            'CreatedById', 'CreatedByName', 'CreatedBy.Name', 'CreatedByName', label);
    }

    @isTest
    private static void Test_AffiliationsGridController_AlwaysReturnNecessaryFields() {
        Account account = retrievePersonAccount();

        Test.startTest();
            List<Affiliation__c> affiliations = AffiliationsGridController.retrieveAffiliations(
                account.Id, new Set<string>(), new List<string>());
        Test.stopTest();

        system.assertEquals(personAccountAffiliationsCount, affiliations.size());

        for (Affiliation__c affiliation : affiliations) {
            for (string field : AffiliationsGridController.alwaysQueryFields) {
                if(field == 'Job_Template__r.Name'){
                    continue;
                }
                system.assert(affiliation.isSet(field),
                    string.format('Field {0} was not returned on an Affiliation',
                        new List<string> {field}));
            }
        }
    }

    private static Account retrievePersonAccount() {
        return [SELECT Id
                FROM Account
                WHERE IsPersonAccount = true
                AND LastName = 'Test 0'
                LIMIT 1];
    }

    private static Account retrievePersonAccountForJobAssignment() {
        return [SELECT Id
                FROM Account
                WHERE IsPersonAccount = true
                AND LastName = 'Test 2'
                LIMIT 1];
    }

    private static Account retrieveTroopAccountForJobAssignment() {
        return [SELECT Id
                FROM Account
                WHERE RecordType.DeveloperName =: AccountRecordTypes.Troop
                LIMIT 1];
    }

    private static void testAffiliationsRetrieveTableData(Id accountId, integer expectedRecordCount) {
        testAffiliationsRetrieveTableData(accountId, expectedRecordCount, null,'Affiliations_Lightning_Grid_Columns',null);
    }

    private static void testAffiliationsRetrieveTableData(Id accountId, integer expectedRecordCount,string filteredTypes) {
        testAffiliationsRetrieveTableData(accountId, expectedRecordCount, filteredTypes,'Affiliations_Lightning_Grid_Columns',null);
    }

    private static void testAffiliationsRetrieveTableDataForJobAssignment(Id accountId, integer expectedRecordCount,string filteredTypes) {
        
        testAffiliationsRetrieveTableData(accountId, expectedRecordCount, filteredTypes,'Participation_Assignments_Field_Set',null);
    }

    private static void testAffiliationsRetrieveTableDataForJobAssignment_NoIncludeFilter(Id accountId, integer expectedRecordCount,string filteredTypes) {
        
        testAffiliationsRetrieveTableData(accountId, expectedRecordCount, filteredTypes,'Participation_Assignments_Field_Set','Council');
    }

    private static void testAffiliationsRetrieveTableDataForJobAssignment_TroopAccount(Id accountId, integer expectedRecordCount,string filteredTypes) {
        testAffiliationsRetrieveTableData(accountId, expectedRecordCount, filteredTypes,'Participation_Assignments_for_Troop_FS','Troop');
    }

    private static void testAffiliationsRetrieveTableData(Id accountId, integer expectedRecordCount,
        string filteredTypes,string fieldSet,string excludedTypes ) {
        Test.startTest();
            AffiliationsGridController.AffiliationsTableData data = AffiliationsGridController.retrieveAffiliationsTableData(accountId, filteredTypes,excludedTypes,fieldSet);
        Test.stopTest();

        system.assertNotEquals(null, data, 'AffiliationsTableData is blank.');
        system.assertNotEquals(null, data.Columns, 'Columns is blank.');
        system.assert(string.isNotBlank(data.Affiliations), 'Affiliations is blank');

        List<Map<string, string>> records = (List<Map<string, string>>)JSON.deserialize(data.Affiliations,List<Map<string, string>>.class);
        system.assertEquals(expectedRecordCount, records.size());

        List<Schema.FieldSetMember> fields = Schema.SObjectType.Affiliation__c.fieldSets.getMap().get(fieldSet).getFields();
        
        for (Map<string,string> record : records) {
            for (Schema.FieldSetMember field : fields) {
                string fieldPath = field.getFieldPath();
                if (fieldPath == 'Account__c' || fieldPath == 'Account2__c') {
                    fieldPath = AffiliationsGridController.accountColumnName;
                }

                system.assert(record.containsKey(fieldPath),
                    string.format('Field {0} is not present on the returned Affiliation', new List<string> {fieldPath}));
            }

            system.assert(record.containsKey('HasEditAccess'),
                'HasEditAccess is not present ont he returned Affiliation');

            system.assert(record.containsKey('Id'),
                'Id is not present ont he returned Affiliation');
        }
    }

    private static void testConvertDataType(Schema.DisplayType displayType, string expectedType) {
        Test.startTest();
            string convertedType = AffiliationsGridController.convertDataType(displayType);
        Test.stopTest();

        system.assertEquals(expectedType, convertedType);
    }

    private static void testRetrieveLookupLabel(string path, string expectedPath) {
        Test.startTest();
            string actualPath = AffiliationsGridController.retrieveLookupLabel(path);
        Test.stopTest();

        system.assertEquals(expectedPath, actualPath);
    }

    private static void testAddJsonFieldValue(SObject record, string fieldPath,
        string fieldName, boolean isUrl, string expectedKey, object expectedValue) {
        Map<string, string> parsedRecord = new Map<string, string>();
        Test.startTest();
            AffiliationsGridController.addJsonFieldValue(record, fieldPath, fieldName, isUrl,
                parsedRecord);
        Test.stopTest();

        assertColumnValue(expectedKey, expectedValue, parsedRecord);
    }

    private static AffiliationsGridController.AffiliationsTableColumn buildAffiliationsTableColumn(
        string fieldName, string type) {
        return buildAffiliationsTableColumn(fieldName, type, null, null);
    }

    private static AffiliationsGridController.AffiliationsTableColumn buildAffiliationsTableColumn(
        string fieldName, string type, string labelSoqlFieldName, string labelFieldName) {
        AffiliationsGridController.AffiliationsTableColumn column = new AffiliationsGridController.AffiliationsTableColumn();

        column.fieldName = fieldName;
        column.type = type;

        if (string.isNotBlank(labelFieldName)) {
            column.typeAttributes = new AffiliationsGridController.TypeAttributes();
            column.typeAttributes.label = new AffiliationsGridController.LabelAttribute();
            column.typeAttributes.label.fieldName = labelFieldName;
            column.typeAttributes.label.soqlFieldName = labelSoqlFieldName;
        }

        return column;
    }

    private static void assertColumnValue(string expectedKey,
        Object expectedValue, Map<string, object> parsedRecord) {
        system.assert(parsedRecord.containsKey(expectedKey),
            string.format('Key {0} was not added to the parsed record',
            new List<string> {expectedKey}));

        system.assertEquals(expectedValue, parsedRecord.get(expectedKey));
    }

    private static void testBuildParsedAffiliation(Set<string> soqlColumns, Affiliation__c affiliation, Id currentAccountId,
        Id relatedAccountId, string relatedAccountName) {
        Map<string, AffiliationsGridController.AffiliationsTableColumn> tableColumnsByName = 
            new Map<string, AffiliationsGridController.AffiliationsTableColumn>{
                'Id' => buildAffiliationsTableColumn('Id', 'url', 'Name', 'Name'),
                'Type__c' => buildAffiliationsTableColumn('Type__c', 'text'),
                AffiliationsGridController.accountColumnName => buildAffiliationsTableColumn(
                    AffiliationsGridController.accountColumnName,
                    AffiliationsGridController.accountColumnName,
                    AffiliationsGridController.accountLabelFieldName,
                    AffiliationsGridController.accountLabelFieldName)
            };

        Test.startTest();
            Map<string, Object> processedAffiliation = AffiliationsGridController.buildParsedAffiliation(
                affiliation, soqlColumns, tableColumnsByName, currentAccountId);
        Test.stopTest();
            
        system.assertEquals(5, processedAffiliation.size());
        assertColumnValue('Id', '/' + affiliation.Id, processedAffiliation);
        assertColumnValue('Name', affiliation.Name, processedAffiliation);
        assertColumnValue('Type__c', affiliation.Type__c, processedAffiliation);
        if(relatedAccountId != null){
            assertColumnValue(AffiliationsGridController.accountColumnName,
                '/' + relatedAccountId, processedAffiliation);
            assertColumnValue(AffiliationsGridController.accountLabelFieldName,
                relatedAccountName, processedAffiliation);
        }
        else if(relatedAccountId == null && affiliation.Type__c == 'Job Assignment' &&
             affiliation.Job_Template__c != null){

            assertColumnValue(AffiliationsGridController.accountColumnName,
                '/' + affiliation.Id, processedAffiliation);
            assertColumnValue(AffiliationsGridController.accountLabelFieldName,
            affiliation.Job_Template__r.Name, processedAffiliation);

        }
    }

    private static void testSetupAffiliationTableColumn(string fieldLabel, string fieldPath,
        Schema.DisplayType displayType, Set<string> expectedSoqlColumns, string fieldNameKey,
        string type, string expectedFieldName, string expectedLabelFieldName,
        string expectedSoqlFieldName, string expectedToolTipFieldName, string expectedLabel) {
        Set<string> soqlColumns = new Set<string>();
        Map<string, AffiliationsGridController.AffiliationsTableColumn> columnsByName = new
            Map<string, AffiliationsGridController.AffiliationsTableColumn>();
        
        Test.startTest();
            AffiliationsGridController.setupAffiliationTableColumn(fieldLabel, fieldPath,
                displayType, soqlColumns, columnsByName);
        Test.stopTest();

        system.assertEquals(expectedSoqlColumns.size(), soqlColumns.size());
        for (string soqlColumn : expectedSoqlColumns) {
            system.assert(soqlColumns.contains(soqlColumn), string.format(
                '{0} was not added to the SOQL columns list.',
                new List<string> {soqlColumn}));
        }
        
        system.assert(columnsByName.containsKey(fieldNameKey),
            string.format('{0} was not added to the columns by name list.',
                new List<string> {fieldNameKey}));

        AffiliationsGridController.AffiliationsTableColumn column = columnsByName.get(fieldNameKey);
        system.assertEquals(expectedLabel, column.label);
        system.assertEquals(type, column.type);
        system.assertEquals(expectedFieldName, column.fieldName);
        if (string.isBlank(expectedLabelFieldName)) {
            system.assertEquals(null, column.typeAttributes);
        }
        else {
            system.assertEquals(expectedLabelFieldName, column.typeAttributes.label.fieldName);
            system.assertEquals(expectedSoqlFieldName, column.typeAttributes.label.soqlFieldName);
            system.assertEquals(expectedToolTipFieldName, column.typeAttributes.tooltip.fieldName);
            system.assertEquals('_self', column.typeAttributes.target);
        }
    }

    private static Affiliation__c retrieveAffiliationForDuplicateTest() {
        return [SELECT Id, Account__c, Account2__c, Type__c, Active__c
                FROM Affiliation__c
                WHERE Account2__r.IsPersonAccount = true
                AND Account__r.RecordType.DeveloperName =: AccountRecordTypes.Council
                AND Job_Template__c = null LIMIT 1];
    }
}