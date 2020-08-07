public with sharing class AffiliationsGridController {
    @testVisible
    private static final string accountColumnName = 'AccountId';
	
    @testVisible
    private static final string accountLabelFieldName = 'AccountName';
    @testVisible
    private static final string accountLabel = 'Related Record';

    @testVisible
    private static final string jobTemplateColumnName = 'Id';
    @testVisible
    private static final string jobTemplateLabelFieldName = 'JobTemplateName';
    @testVisible
    private static final string jobTemplateLabel = 'Job Name';

    // Always add these  fields regardless of if they are part of the field set or not.
    // Id is always needed and the other fields are used for uniqueness purposes
    @testvisible
    private static List<string> alwaysQueryFields = new List<string> {
        'Id', 'Account__c', 'Account2__c', 'Type__c', 'Active__c', 'Job_Template__c', 'Job_Template__r.Name'
    };
    
    private static List<string> accessFields = new List<string> {
         'UserRecordAccess.HasEditAccess'
    };

    @AuraEnabled(cacheable=true)
    public static AffiliationsTableData retrieveAffiliationsTableData(Id accountId, string filteredTypes ,string excludedTypes, string fieldSet) {
        List<string> filteredTypeOptions = string.isNotBlank(filteredTypes)
                                           ? filteredTypes.split('\\s*,\\s*')
                                           : new List<string>();
        
        Set<String> filteredTypeOptionsSet = new Set<String>();
        filteredTypeOptionsSet.addAll(filteredTypeOptions);

        List<string> excludedTypeOptions = string.isNotBlank(excludedTypes)
                                           ? excludedTypes.split('\\s*,\\s*')
                                           : new List<string>();
        
        List<string> finalFilteredTypeOptions = new List<String>();

        if(filteredTypeOptionsSet.size()>0 && excludedTypeOptions.size()>0){
            filteredTypeOptionsSet.removeAll(excludedTypeOptions);
            finalFilteredTypeOptions.addAll(filteredTypeOptionsSet);
        }
        else if (filteredTypeOptionsSet.size()==0 && excludedTypeOptions.size()>0){
            Set<String> typePickListValuesSet= new Set<String>();
        
		    List<Schema.PicklistEntry> ple = Affiliation__c.Type__c.getDescribe().getPicklistValues();
		    for( Schema.PicklistEntry pickListVal : ple){
			    typePickListValuesSet.add(pickListVal.getLabel());
		    }
            typePickListValuesSet.removeAll(excludedTypeOptions); 
            finalFilteredTypeOptions.addAll(typePickListValuesSet);
        }
        else{
            finalFilteredTypeOptions.addAll(filteredTypeOptions);    
        }
        
        //Get list of all recordtypes - exculde first - take remaining list 
        SoqlColumnsAndTableColumns columns = retrieveGridFieldSet(fieldSet);
        
        List<Affiliation__c> affiliations = retrieveAffiliations(accountId, columns.soqlColumns, finalFilteredTypeOptions);
        
        if(!columns.tableColumnsByName.containsKey(accountColumnName)){
            columns.soqlColumns.removeAll(new List<String>{'Account2__c','Account__c'});
        }
        
        Map<string, Map<string, Object>> parsedAffiliationsByKey = new Map<string, Map<string, Object>>();
        for (Affiliation__c affiliation: affiliations) {
            
            string key = buildAffiliationKey(affiliation, accountId,columns.soqlColumns);
            
            if (parsedAffiliationsByKey.containsKey(key)) {
                continue;
            }
            
            Map<string, Object> parsedAffiliation = buildParsedAffiliation(affiliation,
                columns.soqlColumns, columns.tableColumnsByName, accountId);

            parsedAffiliationsByKey.put(key, parsedAffiliation);
        }
        
        return new AffiliationsTableData(JSON.serialize(parsedAffiliationsByKey.values()),
            columns.tableColumnsByName.values(), affiliations.size() == Limits.getLimitQueryRows());
    }

    private static SoqlColumnsAndTableColumns retrieveGridFieldSet(String fieldSetPassed) {
        Schema.FieldSet fieldSet = Schema.SObjectType.Affiliation__c.fieldSets.getMap().get(fieldSetPassed);
        Map<string, AffiliationsTableColumn> columnsByName = new Map<string, AffiliationsTableColumn>();
        Set<string> soqlColumns = new Set<String>();

        for (Schema.FieldSetMember field : fieldSet.getFields()) {
            setupAffiliationTableColumn(field.getLabel(), field.getFieldPath(), field.getType(),
                soqlColumns, columnsByName);
        }

        soqlColumns.addAll(accessFields);
        return new SoqlColumnsAndTableColumns(columnsByName, soqlColumns);
    }

    @testVisible
    private static void setupAffiliationTableColumn(string fieldLabel, string fieldPath,
        Schema.DisplayType displayType, Set<string> soqlColumns,
        Map<string, AffiliationsTableColumn> columnsByName) {
        AffiliationsTableColumn column = new AffiliationsTableColumn();
        column.label = fieldLabel;
        
        if (fieldPath == 'Name' || fieldPath == 'Job_Name__c') {
            column.type = 'url';
            column.fieldName = 'Id';
            column.typeAttributes = new TypeAttributes();
            column.typeAttributes.label = new LabelAttribute();
            column.typeAttributes.label.fieldName = fieldPath;
            column.typeAttributes.label.soqlFieldName = fieldPath;
            column.typeAttributes.tooltip = new LabelAttribute();
            column.typeAttributes.tooltip.fieldName = fieldPath;
            soqlColumns.add(fieldPath);
            soqlColumns.add('Id');
            columnsByName.put('Id', column);
        }
        else {
            column.type = convertDataType(displayType);
            boolean isAccountField = fieldPath == 'Account__c' || fieldPath == 'Account2__c';
            if (isAccountField) {
                soqlColumns.add(fieldPath);
                if (columnsByName.containsKey(accountColumnName)) {
                    // Add the lookup label for the second Account lookup
                    string lookupLabel = RetrieveLookupLabel(fieldPath);
                    soqlColumns.add(lookupLabel);

                    return;
                }

                column.Label = accountLabel;
                column.fieldName = accountColumnName;
            }
            else {
                column.fieldName = fieldPath.replace('.', '');
                soqlColumns.add(fieldPath);
            }

            if (displayType == Schema.DisplayType.DATE) {
                column.typeAttributes = new TypeAttributes(); 
                column.typeAttributes.month = '2-digit';
                column.typeAttributes.day =  '2-digit';
                column.typeAttributes.year =  'numeric';
            }

            if (displayType == Schema.DisplayType.REFERENCE) {
                column.typeAttributes = new TypeAttributes();
                column.typeAttributes.label = new LabelAttribute();
                column.typeAttributes.tooltip = new LabelAttribute();
                
                string lookupLabel = RetrieveLookupLabel(fieldPath);
                soqlColumns.add(lookupLabel);

                if (isAccountField) {
                    lookupLabel = accountLabelFieldName;
                }

                column.typeAttributes.label.fieldName = lookupLabel.replace('.', '');
                column.typeAttributes.tooltip.fieldName = lookupLabel.replace('.', '');
                column.typeAttributes.label.soqlFieldName = lookupLabel;
            }
            
            if (isAccountField) {
                columnsByName.put(accountColumnName, column);
            }
            else {
                columnsByName.put(fieldPath, column);
            }
        }
    }

    @testVisible
    private static List<Affiliation__c> retrieveAffiliations(Id accountId, Set<string> columnNames, List<string> allowedTypes) {
        
        columnNames.addAll(alwaysQueryFields);
        return database.query(string.join(new List<string>
        {
            string.format('SELECT {0}', new List<string> {string.join(new List<string>(columnNames), ', ')}),
            'FROM Affiliation__c',
            'WHERE (Account__c =: accountId',
            'OR Account2__c =: accountId)',
            allowedTypes.size() > 0 ? 'AND Type__c in: allowedTypes' : '',
            string.format('Limit {0}', new List<Object> {Limits.getLimitQueryRows()})
        }, '\n'));
    }

    @testVisible
    private static string convertDataType(Schema.DisplayType displayType) {
        // The values in this Switch statement come from the Schema.DisplayType enum
        switch on displayType {
            when BOOLEAN {
                return 'boolean';
            }
            when CURRENCY {
                return 'currency';
            }
            when DATETIME {
                return 'date';
            }
            when DATE {
                return 'date-local';
            }
            when EMAIL {
                return 'email';
            }
            when DOUBLE, INTEGER, LONG {
                return 'number';
            }
            when PERCENT {
                return 'percent';
            }
            when PHONE {
                return 'phone';
            }
            when REFERENCE, URL  {
                return 'url';
            }
            when else {
                return 'text';
            }
        }
    }

    // Summer 2019 adds a new method to a FieldSet Member that would allow us to retrieve
    // the SObject field directly from the FieldSetMember class. Thhis would allow the code to
    // handle lookup fields on related entities. For now, lookup fields on related entities are not
    // handled properly.
    @testVisible
    private static string retrieveLookupLabel(string path) {
        Map<string, Schema.SObjectField> fields = SObjectType.Affiliation__c.fields.getMap();
        if (fields.containsKey(path) == false) {
            return path;
        }

        Schema.DescribeFieldResult field = fields.get(path).getDescribe();
        return string.format('{0}.Name', new List<string> {
            path.replaceFirst(string.format('(\\.|^){0}', new List<string> {path}),
                field.getRelationshipName())
        });
    }

    @testVisible
    
    private static Map<string, object> buildParsedAffiliation(Affiliation__c affiliation,
        Set<string> soqlColumns, Map<string, AffiliationsTableColumn> tableColumnsByName, 
        Id accountId) {
        Map<string, object> parsedAffiliation = new Map<string, object>();
        
        for (string columnName : soqlColumns) {
            
            AffiliationsTableColumn column;
            if (columnName == 'Account__c' || columnName == 'Account2__c') {
                column = tableColumnsByName.get(accountColumnName);
                if (affiliation.get(columnName) == accountId) {
                    continue;
                }

                string labelFieldPath = columnName == 'Account__c'
                                        ? 'Account__r.Name'
                                        : 'Account2__r.Name';

                addJsonFieldValue(affiliation, columnName, accountColumnName, true,
                    parsedAffiliation);
                
                addJsonFieldValue(affiliation, labelFieldPath, accountLabelFieldName, false,
                    parsedAffiliation);
                continue;
            }
            else if (accessFields.contains(columnName)) {
                addJsonFieldValue(affiliation, columnName, columnName.replace('UserRecordAccess.', ''),
                    false, parsedAffiliation);
                continue;
            }

            if (tableColumnsByName.containsKey(columnName) == false) {
                // Always add Id even if it's not part of the fieldset
                if (columnName == 'Id') {
                    addJsonFieldValue(affiliation, columnName, columnName, false,
                        parsedAffiliation);
                }
                continue;
            }

            column = tableColumnsByName.get(columnName);
            
            addJsonFieldValue(affiliation, columnName, column.fieldName, column.type == 'url',
                parsedAffiliation);

            if (column.typeAttributes != null && 
                column.typeAttributes.label != null && 
                column.typeAttributes.label.fieldName != null) {
                    addJsonFieldValue(affiliation,
                        column.typeAttributes.label.soqlFieldName,
                        column.typeAttributes.label.fieldName, false,
                        parsedAffiliation);
            }
        }
        
        if(!soqlColumns.contains('Job_Name__c')){ 
            tableColumnsByName.remove('Job_Template__c');
            if(affiliation.Type__c == 'Job Assignment' &&
                parsedAffiliation.get(accountColumnName) == null){
                
                parsedAffiliation.put(accountColumnName,'/'+affiliation.Id);
                parsedAffiliation.put(accountLabelFieldName, affiliation.Job_Template__r.Name);
                parsedAffiliation.remove('Job_Template__c');
            
            }
        }
        
        return parsedAffiliation;
    }

    @testVisible
    private static void addJsonFieldValue(SObject record, string fieldPath, string fieldName,
        boolean isUrl, Map<string, object> parsedRecord) {

        List<string> fieldPathParts = fieldPath.split('\\.');
        for (integer i = 0; i < fieldPathParts.size() - 1; i++) {
            record = record.getSObject(fieldPathParts[i]);

            if (record == null) {
                break;
            }
        }
        
        Object value;
        if (record != null) {
            value = record.get(fieldPathParts[fieldPathParts.size() - 1]);
            if (value != null && isUrl) {
                value = string.format('{0}{1}', new List<Object> {
                    isUrl ? '/' : '', value});
            }
        }

        parsedRecord.put(fieldName, value);
    }

    private static string buildAffiliationKey(Affiliation__c affiliation, Id accountId,Set<String> soqlColumnsReceived) {
        Id otherAccountId;
        if (accountId == affiliation.Account__c) {
            otherAccountId = affiliation.Account2__c;
        }
        else {
            otherAccountId = affiliation.Account__c;
        }
      
        
        return (!soqlColumnsReceived.contains('Job_Name__c') )
                ? string.format('{0}{1}{2}{3}{4}', new List<object> {
                    accountId, otherAccountId, affiliation.Job_Template__c,affiliation.Type__c,
                    affiliation.Active__c
                }) 
                : string.format('{0}{1}{2}{3}', new List<object> {
                    accountId, otherAccountId, affiliation.Type__c,
                    affiliation.Active__c
                });
        
    }

    public class AffiliationsTableColumn {
        @AuraEnabled public string label {get; set;}
        @AuraEnabled public string fieldName {get; set;}
        @AuraEnabled public string type {get; set;}
        @AuraEnabled public Boolean sortable {get; set;}
        @AuraEnabled public TypeAttributes typeAttributes {get; set;}

        public AffiliationsTableColumn() {
            sortable = true;
        }
    }

    private class SoqlColumnsAndTableColumns {
        public Map<string, AffiliationsTableColumn> tableColumnsByName;
        public Set<string> soqlColumns;

        public SoqlColumnsAndTableColumns(Map<string, AffiliationsTableColumn> tableColumnsByName,
            Set<string> soqlColumns) {
            this.tableColumnsByName = tableColumnsByName;
            this.soqlColumns = soqlColumns;
        }
    }

    public class TypeAttributes {
        @AuraEnabled public LabelAttribute label {get; set;}
        @AuraEnabled public LabelAttribute tooltip {get; set;}
        @AuraEnabled public String month {get; set;}
        @AuraEnabled public String day {get; set;}
        @AuraEnabled public String year {get; set;}

        @AuraEnabled public string target {
            get {
                return '_self';
            }
        }
    }

    public class LabelAttribute {
        @AuraEnabled public string fieldName {get; set;}
        public string soqlFieldName {get; set;}
    }

    public class AffiliationsTableData {
        @AuraEnabled public string Affiliations {get; set;}
        @AuraEnabled public List<AffiliationsTableColumn> Columns {get; set;}
        @AuraEnabled public Boolean MoreRecordsAvailable {get; set;}
        
        public AffiliationsTableData(string affiliations,
            List<AffiliationsTableColumn> columns, boolean moreRecordsAvailable) {
                this.Affiliations = affiliations;
                this.Columns = columns;
                this.MoreRecordsAvailable = moreRecordsAvailable;
        }
    }
}
